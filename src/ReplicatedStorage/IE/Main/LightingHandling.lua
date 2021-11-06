local module = {}

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Main = script.Parent
local IEFolder = Main.Parent

local RemoteFolder = IEFolder:WaitForChild("RemoteFolder")

local LightingRemote = RemoteFolder:WaitForChild("LightingRemote")

--// Note: Make sure these all have connections to them on the client and server
local ClearWeather: RemoteEvent = RemoteFolder:WaitForChild("ClearWeather")
local LightingInitialSyncToServer: RemoteEvent = RemoteFolder:WaitForChild("LightingInitialSyncToServer")
local LightingSyncToServer: RemoteEvent = RemoteFolder:WaitForChild("LightingSyncToServer")
local LightingChangeComponent: RemoteEvent = RemoteFolder:WaitForChild("LightingChangeComponent")

local Settings = require(IEFolder.Settings)

local InternalSettings = require(Main.InternalSettings)
local InternalVariables = require(Main.InternalVariables)
local PackageHandling = require(Main.PackageHandling)
local SettingsHandling = require(Main.SettingsHandling)
local SharedFunctions = require(Main.SharedFunctions)

local InstanceTable = {}
local ComplexInstanceTable = {}

local LitLightTable = {} --// Reference table, only used when Settings["AlwaysCheckInstances"] is true

local function GetSearchCategory()
	if Settings["ChangingInstanceChildrenOfWorkspace"] == true then
		return Workspace:GetChildren()
	else
		return Workspace:GetDescendants()
	end
end

local function BuildLitLightTable(InstanceType, ClassName, InstanceName, SettingTable, ReferencePartName, Relationship) --// Used for when AlwaysCheckInstances is on, so settings of the most recent change are enabled and it's easy to check if a Light is actually on or not
	if InstanceType == "Normal" then
		if LitLightTable[ClassName] == nil then
			LitLightTable[ClassName] = {}
		elseif LitLightTable[ClassName][InstanceName] == nil then
			LitLightTable[ClassName][InstanceName] = {}
		end

		LitLightTable[ClassName][InstanceName] = SettingTable
	elseif InstanceType == "Complex" then
		if LitLightTable[ReferencePartName] == nil then
			LitLightTable[ReferencePartName] = {}
		elseif LitLightTable[ReferencePartName][Relationship] == nil then
			LitLightTable[ReferencePartName][Relationship] = {}
		elseif LitLightTable[ReferencePartName][Relationship][ClassName] == nil then
			LitLightTable[ReferencePartName][Relationship][ClassName] = {}
		elseif LitLightTable[ReferencePartName][Relationship][ClassName][InstanceName] == nil then
			LitLightTable[ReferencePartName][Relationship][ClassName][InstanceName] = {}
		end

		LitLightTable[ReferencePartName][Relationship][ClassName][InstanceName] = SettingTable
	end
end

local function CheckLitLightTable(InstanceToCheck, InstanceType, ClassName, InstanceName, ReferencePartName, Relationship)
	if InstanceType == "Normal" then
		if LitLightTable[ClassName] == nil then
			return false
		elseif LitLightTable[ClassName][InstanceName] == nil then
			return false
		end

		for SettingName, SettingValue in pairs (LitLightTable[ClassName][InstanceName]) do
			if InstanceToCheck[SettingName] ~= SettingValue then
				return false
			end
		end

		return true
	elseif InstanceType == "Complex" then
		if LitLightTable[ReferencePartName] == nil then
			return false
		elseif LitLightTable[ReferencePartName][Relationship] == nil then
			return false
		elseif LitLightTable[ReferencePartName][Relationship][ClassName] == nil then
			return false
		elseif LitLightTable[ReferencePartName][Relationship][ClassName][InstanceName] == nil then
			return false
		end

		for SettingName, SettingValue in pairs (LitLightTable[ReferencePartName][Relationship][ClassName][InstanceName]) do
			if InstanceToCheck[SettingName] ~= SettingValue then
				return false
			end
		end

		return true
	end
end

local function CheckInstanceTableExistence(InstanceName, ClassName) --// Note for future, make this compatible with complex instances
	--[[ Table structure goes like
	
	InstanceTable = {
		[ClassName] = {
			[InstanceName] = {
				[Instance (this is an actual instance)] = {
					["LightsOn"] = a bool value to determine whether it this specific complex instance is "on"
				}
			}
		}
	}
	]]	

	if InstanceTable[ClassName] then --// The ClassName does exist (used for parts that may have the same name of different classes
		if InstanceTable[ClassName][InstanceName] then --// There is a table of reference parts, or at least one has been checked for
			if Settings["AlwaysCheckInstances"] == false then --// Permission is allowed to skip if it's already there/cached
				return
			end
		end
	end

	if InstanceTable[ClassName] == nil then
		InstanceTable[ClassName] = {}
	end

	InstanceTable[ClassName][InstanceName] = {}

	local SearchCategory = GetSearchCategory()

	if #SearchCategory ~= 0 then
		for i = 1, #SearchCategory do
			if SearchCategory[i].Name == InstanceName and SearchCategory[i]:IsA(ClassName) then
				InstanceTable[ClassName][InstanceName][SearchCategory[i]] = {}

				if Settings["AlwaysCheckInstances"] == false then
					InstanceTable[ClassName][InstanceName][SearchCategory[i]]["LightsOn"] = false
				else
					if CheckLitLightTable(SearchCategory[i], "Normal", ClassName, InstanceName) == true then
						InstanceTable[ClassName][InstanceName][SearchCategory[i]]["LightsOn"] = true
					else
						InstanceTable[ClassName][InstanceName][SearchCategory[i]]["LightsOn"] = false
					end
				end
			end
		end
	end
end

local function CheckComplexInstanceTableExistence(ReferencePartName, Relationship, ClassName, InstanceName)
	--[[ Table structure goes like
	
	ComplexInstanceTable = {
		[ReferencePartName] = {
			[ReferencePart (this is an actual instance)] = {
				["LightsOn"] = a bool value to determine whether it this specific complex instance is "on"
				[Relationship Name ex: Child, Sibling, Parent, Descendant] = {
					[ClassName] = {
						[InstanceName] = {Simple table of instances}
					}
				}
				etc. more relationships may follow
			}
		}
	}
	]]	

	if ComplexInstanceTable[ReferencePartName] then --// There is a table of reference parts, or at least one has been checked for
		for ReferencePart, RefPartRelationship in pairs (ComplexInstanceTable[ReferencePartName]) do 
			if RefPartRelationship == Relationship then --// The relationship does exist
				for ClassNameInRefPart, InstanceNames in pairs (Relationship) do
					if ClassNameInRefPart == ClassName then --// The class does exist
						for _InstanceName, SimpleTableOfInstances in pairs (InstanceNames) do --// Sorry for using such an ugly placeholder value D:
							if _InstanceName == InstanceName then --// The instance does exist, or it's at least been checked for before
								if Settings["AlwaysCheckInstances"] == false then --// Permission is allowed to skip if it's already there/cached
									return
								end
							end
						end
					end
				end
			end
		end
	end

	if ComplexInstanceTable[ReferencePartName] == nil then
		ComplexInstanceTable[ReferencePartName] = {}
	end

	local SearchCategory = GetSearchCategory()
	local NumberOfSearches = #SearchCategory

	--// Instance Check

	if NumberOfSearches ~= 0 then
		for i = 1, NumberOfSearches do
			if SearchCategory[i].Name == ReferencePartName then --// Note: SearchCategory[i] is the reference part

				--// Table checks

				local ReferencePart = SearchCategory[i]

				if ComplexInstanceTable[ReferencePartName][ReferencePart] == nil then --// Cases where the reference part is not yet indexed
					ComplexInstanceTable[ReferencePartName][ReferencePart] = {}
					ComplexInstanceTable[ReferencePartName][ReferencePart]["LightsOn"] = false
					ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship] = {}
					ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName] = {}
					ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName][InstanceName] = {}

				elseif ComplexInstanceTable[ReferencePartName][SearchCategory[i]][Relationship] == nil then --// Cases where the reference part is already indexed, but a new relationship is being added
					ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship] = {}
					ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName] = {}
					ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName][InstanceName] = {}

				elseif ComplexInstanceTable[ReferencePartName][SearchCategory[i]][Relationship][ClassName] == nil then --// Cases where the relationship is already indexed, but a new class name is being added
					ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName] = {}
					ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName][InstanceName] = {}

				elseif ComplexInstanceTable[ReferencePartName][SearchCategory[i]][Relationship][ClassName][InstanceName] == nil then --// Cases where a new instance is being added to an existing class
					ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName][InstanceName] = {}
				end

				if Relationship == "Child" then
					local Children = ReferencePart:GetChildren()
					local NumberOfChildren = #Children

					if NumberOfChildren ~= 0 then
						for n = 1, NumberOfChildren do
							if Children[n].Name == InstanceName and Children[n]:IsA(ClassName) then
								table.insert(ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName][InstanceName], Children[n])
							end
						end
					end

				elseif Relationship == "Descendant" then
					local Descendants = ReferencePart:GetDescendants()
					local NumberOfDescendants = #Descendants

					if NumberOfDescendants ~= 0 then
						for n = 1, NumberOfDescendants do
							if Descendants[n].Name == InstanceName and Descendants[n]:IsA(ClassName) then
								table.insert(ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName][InstanceName], Descendants[n])
							end
						end
					end

				elseif Relationship == "Parent" then
					if SearchCategory[i].Parent.Name == InstanceName and SearchCategory[i]:IsA(ClassName) then
						table.insert(ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName][InstanceName], SearchCategory[i].Parent)
					end

				elseif Relationship == "Sibling" then
					local Siblings = SearchCategory[i].Parent:GetChildren()
					local NumberOfSiblings = #Siblings

					if NumberOfSiblings ~= 0 then
						for n = 1, NumberOfSiblings do
							if Siblings[n].Name == InstanceName and Siblings[n]:IsA(ClassName) then
								table.insert(ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName][InstanceName], Siblings[n])
							end
						end
					end

				elseif Relationship == "Self" then
					if ReferencePart:IsA(ClassName) and ReferencePart.Name == InstanceName then
						table.insert(ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName][ReferencePartName], ReferencePart)
					else
						--warn("Self property set for ".. ReferencePartName.. " but the instance is not a ".. ClassName)
					end
				end
			end
		end
	end
end

local function Set(LightingSettings)
	local AdjustOnlyLightsOn

	if LightingSettings["GeneralSettings"]["AdjustOnlyLightsOn"] ~= nil then
		AdjustOnlyLightsOn = LightingSettings["GeneralSettings"]["AdjustOnlyLightsOn"]
	else
		AdjustOnlyLightsOn = false
	end

	for ClassName, ClassSettings in pairs (LightingSettings) do --// Changing Lighting Service and Children (ChanceOfChange does not apply here)
		if InternalSettings["SettingInstanceCorrelations"][ClassName] ~= nil and InternalSettings["SettingInstanceCorrelations"][ClassName] ~= false then
			local TargetInstance = InternalSettings["SettingInstanceCorrelations"][ClassName]

			for SettingName, SettingValue in pairs (ClassSettings) do --// Determines if settings are able to be used and sets
				if SharedFunctions.CheckProperty(TargetInstance, SettingName) then 
					if table.find(InternalSettings["BlacklistedSettings"], SettingName) == nil and (InternalSettings["BlacklistedSettingsClass"][ClassName] == nil or table.find(InternalSettings["BlacklistedSettingsClass"][ClassName], SettingName) == nil) then
						TargetInstance[SettingName] = SettingValue
					else
						warn(SettingName.. " unable to be modified")
					end
				else
					warn(SettingName.. " is not a valid property of ".. ClassName.. ".  Check spelling or Lighting Technology")
				end
			end
		end
	end

	if LightingSettings["Instances"] then		
		for ClassName, Instances in pairs (LightingSettings["Instances"]) do --// In settings right now
			for InstanceName, SpecificSettings in pairs (Instances) do
				CheckInstanceTableExistence(InstanceName, ClassName)

				local ChangeTable
				local ChanceOfChange = 100 --// Default always changes

				for _Instance, UniqueProperties in pairs (InstanceTable[ClassName][InstanceName]) do --// Switch to the InstanceTable
					if (AdjustOnlyLightsOn == true and LightingSettings["Instances"][ClassName][InstanceName]["IsLight"] == true and UniqueProperties["LightsOn"] == true) or AdjustOnlyLightsOn == false then
						--// Above conditional simplified just means, if the settings says to only adjust the lights on, and the instance is one that does have the LightsOn status, and the instance is "on" then proceed, or if the Setting does not abide to only lights on the proceed


						if ChangeTable == nil then
							ChangeTable = {}

							for SettingName, SettingValue in pairs (SpecificSettings) do --// Determines if settings are able to be used, etc.
								if table.find(InternalSettings["NonPropertySettings"], SettingName) == nil then 
									if SharedFunctions.CheckProperty(_Instance, SettingName) then
										if table.find(InternalSettings["BlacklistedSettings"], SettingName) == nil and (InternalSettings["BlacklistedSettingsClass"][ClassName] == nil or table.find(InternalSettings["BlacklistedSettingsClass"][ClassName], SettingName) == nil) then
											ChangeTable[SettingName] = SettingValue
										else
											warn(SettingName.. " unable to be modified")
										end
									end
								else
									if SettingName == "ChanceOfChange" then
										ChanceOfChange = SettingValue
									end
								end
							end

							BuildLitLightTable("Normal", ClassName, InstanceName, ChangeTable)
						end

						if SharedFunctions.DoesChange(ChanceOfChange) then
							for ApprovedSettingName, ApprovedSettingValue in pairs (ChangeTable) do
								_Instance[ApprovedSettingName] = ApprovedSettingValue
							end

							InstanceTable[ClassName][InstanceName][_Instance]["LightsOn"] = LightingSettings["Instances"][ClassName][InstanceName]["IsLightOn"]
						end
					end
				end
			end
		end
	end

	if LightingSettings["ComplexInstances"] then
		local ListOfLights = {} --// Looks like: index = ReferencePartName; value = true/false, basically just tells whether this is treated as an instance affected by LightsOn or not

		for ReferencePartName, Relationships in pairs (LightingSettings["ComplexInstances"]) do --// This is NOT parsing through the ComplexInstanceTable, this is parsing through the ComplexInstances table in the respective settings

			for Relationship, ClassSettings in pairs (Relationships) do
				if Relationship == "GeneralSettings" then
					if ClassSettings["IsLight"] then
						ListOfLights[ReferencePartName] = ClassSettings["IsLight"]
					else
						ListOfLights[ReferencePartName] = false --// Defaults to not registering a part as a light
					end
				else
					for ClassName, Instances in pairs (ClassSettings) do
						for InstanceName, SpecificSettings in pairs (Instances) do
							CheckComplexInstanceTableExistence(ReferencePartName, Relationship, ClassName, InstanceName)
						end
					end
				end
			end
		end

		for ReferencePartName, _ in pairs (LightingSettings["ComplexInstances"]) do
			local ChanceOfChange = 100 --// Defaults to 100  (i.e. always changes)

			if LightingSettings["ComplexInstances"][ReferencePartName]["GeneralSettings"]["ChanceOfChange"] ~= nil then
				ChanceOfChange = LightingSettings["ComplexInstances"][ReferencePartName]["GeneralSettings"]["ChanceOfChange"]
			end

			for ReferencePart, Relationships in pairs (ComplexInstanceTable[ReferencePartName]) do --// Parsing through all the reference parts
				if (AdjustOnlyLightsOn == true and ListOfLights[ReferencePartName] == true and ComplexInstanceTable[ReferencePartName][ReferencePart]["LightsOn"] == true) or AdjustOnlyLightsOn == false then
					--// Above conditional simplified just means, if the settings says to only adjust the lights on, and the complex instance is one that does have the LightsOn status, and the current instance is "on" then proceed, or if the Setting does not abide to only lights on the proceed
					if ReferencePart.Parent ~= nil then

						if SharedFunctions.DoesChange(ChanceOfChange) then

							for Relationship, ClassNames in pairs (Relationships) do
								if Relationship == "LightsOn" then
									--// Saving space in case any other changes need to be added
								else
									for ClassName, Instances in pairs (ClassNames) do
										for InstanceName, SimpleTableOfInstances in pairs (Instances) do
											local TestInstance = ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName][InstanceName][1]

											if TestInstance ~= nil then --// Ensures that an instance does actually exist
												local ChangeTable

												if ChangeTable == nil then --// Only does settings validation once
													ChangeTable = {}

													for SettingName, SettingValue in pairs (LightingSettings["ComplexInstances"][ReferencePartName][Relationship][ClassName][InstanceName]) do --// Determines if settings are able to be used, etc. CHANGE SETTINGS HERE
														if table.find(InternalSettings["NonPropertySettings"], SettingName) == nil then 
															if SharedFunctions.CheckProperty(TestInstance, SettingName) then
																if table.find(InternalSettings["BlacklistedSettings"], SettingName) == nil and (InternalSettings["BlacklistedSettingsClass"][ClassName] == nil or table.find(InternalSettings["BlacklistedSettingsClass"][ClassName], SettingName) == nil) then
																	ChangeTable[SettingName] = SettingValue
																else
																	warn(SettingName.. " unable to be modified")
																end
															else
																warn(SettingName.. " is not a valid property of ".. InstanceName.. ".  Check spelling")
															end
														end
													end
												end

												for i = 1, #ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName][InstanceName] do --// Changes the settings
													local TargetInstance = ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName][InstanceName][i]

													for ApprovedSettingName, ApprovedSettingValue in pairs (ChangeTable) do
														TargetInstance[ApprovedSettingName] = ApprovedSettingValue
													end

													ComplexInstanceTable[ReferencePartName][ReferencePart]["LightsOn"] = LightingSettings["ComplexInstances"][ReferencePartName]["GeneralSettings"]["IsLightOn"]
												end
											end
										end
									end
								end
							end
						end
					else
						LightingSettings["ComplexInstances"][ReferencePartName][ReferencePart] = nil --// Used for deleting reference parts that no longer exist
					end
				end
			end
		end
	end
end

local function Tween(LightingSettings, Event: string)
	local TweenInformation

	if Event == "ToRegion" or Event == "ToServer" then
		TweenInformation = Settings["AudioRegionTweenInformation"] --// Region based change
	elseif Event == "TimeChange" then
		TweenInformation = Settings["TimeEffectTweenInformation"] --// Time based change
	elseif Event == "Weather" or Event == "ClearWeather" then
		TweenInformation = Settings["WeatherTweenInformation"] --// Weather based change
	end

	local AdjustOnlyLightsOn

	if LightingSettings["GeneralSettings"]["AdjustOnlyLightsOn"] then
		AdjustOnlyLightsOn = LightingSettings["GeneralSettings"]["AdjustOnlyLightsOn"]
	else
		AdjustOnlyLightsOn = false
	end

	for ClassName, ClassSettings in pairs (LightingSettings) do --// Changing Lighting Service and Children (ChanceOfChange does not apply here)
		if InternalSettings["SettingInstanceCorrelations"][ClassName] and InternalSettings["SettingInstanceCorrelations"][ClassName] ~= false then
			local TargetInstance = InternalSettings["SettingInstanceCorrelations"][ClassName] --// Instance being changed, also used for determining setting validation

			local ChangeTable = {}
			local ToSetOnComplete = {}

			for SettingName, SettingValue in pairs (ClassSettings) do --// Determines if settings are able to be used, etc.
				if SharedFunctions.CheckProperty(TargetInstance, SettingName) then
					if not table.find(InternalSettings["BlacklistedSettings"], SettingName) and (not InternalSettings["BlacklistedSettingsClass"][ClassName] or not table.find(InternalSettings["BlacklistedSettingsClass"][ClassName], SettingName)) then
						if table.find(InternalSettings["AlwaysSet"], SettingName) or (InternalSettings["AlwaysSetClass"][ClassName] and table.find(InternalSettings["AlwaysSetClass"][ClassName], SettingName)) then
							table.insert(ToSetOnComplete, SettingName)
						else
							ChangeTable[SettingName] = SettingValue
						end
					else
						warn(SettingName.. " unable to be modified")
					end
				else
					warn(SettingName.. " is not a valid property of ".. ClassName.. ".  Check spelling or Lighting Technology")
				end
			end

			--// Changes the settings

			local ChangeTween = TweenService:Create(TargetInstance, TweenInformation, ChangeTable)
			ChangeTween:Play()

			ChangeTween.Completed:Connect(function()
				ChangeTween:Destroy()

				local NumberOfIndexes = #ToSetOnComplete

				if NumberOfIndexes ~= 0 then
					for i = 1, NumberOfIndexes do
						TargetInstance[ToSetOnComplete[i]] = ClassSettings[ToSetOnComplete[i]]
					end
				end
			end)
		end
	end

	if LightingSettings["Instances"] then
		for ClassName, Instances in pairs (LightingSettings["Instances"]) do
			for InstanceName, SpecificSettings in pairs (Instances) do
				CheckInstanceTableExistence(InstanceName, ClassName)

				local ChangeTable

				local ToSetOnComplete = {}

				local ChanceOfChange = 100 --// Default always changes

				for _Instance, UnqiueProperties in pairs (InstanceTable[ClassName][InstanceName]) do
					if (AdjustOnlyLightsOn == true and LightingSettings["Instances"][ClassName][InstanceName]["IsLight"] == true and UnqiueProperties["LightsOn"] == true) or AdjustOnlyLightsOn == false then
						--// Above conditional simplified just means, if the settings says to only adjust the lights on, and the instance is one that does have the LightsOn status, and the instance is "on" then proceed, or if the Setting does not abide to only lights on the proceed

						if ChangeTable == nil then
							ChangeTable = {}

							for SettingName, SettingValue in pairs (SpecificSettings) do --// Determines if settings are able to be used, etc.
								if table.find(InternalSettings["NonPropertySettings"], SettingName) == nil then
									if SharedFunctions.CheckProperty(_Instance, SettingName) then
										if table.find(InternalSettings["BlacklistedSettings"], SettingName) == nil and (InternalSettings["BlacklistedSettingsClass"][ClassName] == nil or table.find(InternalSettings["BlacklistedSettingsClass"][ClassName], SettingName) == nil) then
											if table.find(InternalSettings["AlwaysSet"], SettingName) ~= nil or (InternalSettings["AlwaysSetClass"][ClassName] and table.find(InternalSettings["AlwaysSetClass"][ClassName], SettingName)) then
												table.insert(ToSetOnComplete, SettingName)
											else
												ChangeTable[SettingName] = SettingValue
											end
										else
											warn(SettingName.. " unable to be modified")
										end
									end
								else
									if SettingName == "ChanceOfChange" then
										ChanceOfChange = SettingValue
									end
								end
							end

							BuildLitLightTable("Normal", ClassName, InstanceName, ChangeTable)
						end

						if SharedFunctions.DoesChange(ChanceOfChange) then
							local ChangeTween = TweenService:Create(_Instance, TweenInformation, ChangeTable)
							ChangeTween:Play()

							ChangeTween.Completed:Connect(function()
								ChangeTween:Destroy()

								local NumberOfIndexes = #ToSetOnComplete

								if NumberOfIndexes ~= 0 then
									for i = 1, NumberOfIndexes do
										_Instance[ToSetOnComplete[i]] = SpecificSettings[ToSetOnComplete[i]]
									end
								end
							end)
						end
					end
				end
			end
		end
	end

	if LightingSettings["ComplexInstances"] then
		local ListOfLights = {} --// Looks like: index = ReferencePartName; value = true/false, basically just tells whether this is treated as an instance affected by LightsOn or not 

		for ReferencePartName, Relationships in pairs (LightingSettings["ComplexInstances"]) do --// This is NOT parsing through the ComplexInstanceTable, this is parsing through the ComplexInstances table in the respective settings
			for Relationship, ClassSettings in pairs (Relationships) do
				if Relationship == "GeneralSettings" then
					if ClassSettings["IsLight"] then
						ListOfLights[ReferencePartName] = ClassSettings["IsLight"]
					else
						ListOfLights[ReferencePartName] = false --// Defaults to not registering a part as a light
					end
				else
					for ClassName, Instances in pairs (ClassSettings) do
						for InstanceName, SpecificSettings in pairs (Instances) do
							CheckComplexInstanceTableExistence(ReferencePartName, Relationship, ClassName, InstanceName)
						end
					end
				end
			end
		end

		for ReferencePartName, _ in pairs (LightingSettings["ComplexInstances"]) do
			local ChanceOfChange = 100 --// Defaults to 100 (i.e. always changes)

			if LightingSettings["ComplexInstances"][ReferencePartName]["GeneralSettings"]["ChanceOfChange"] ~= nil then
				ChanceOfChange = LightingSettings["ComplexInstances"][ReferencePartName]["GeneralSettings"]["ChanceOfChange"]
			end

			for ReferencePart, Relationships in pairs (ComplexInstanceTable[ReferencePartName]) do
				if (AdjustOnlyLightsOn == true and ListOfLights[ReferencePartName] == true and ComplexInstanceTable[ReferencePartName][ReferencePart]["LightsOn"] == true) or AdjustOnlyLightsOn == false then
					--// Above conditional simplified just means, if the settings says to only adjust the lights on, and the complex instance is one that does have the LightsOn status, and the current instance is "on" then proceed, or if the Setting does not abide to only lights on the proceed
					if ReferencePart.Parent ~= nil then
						if SharedFunctions.DoesChange(ChanceOfChange) then
							for Relationship, ClassNames in pairs (Relationships) do
								if type(ClassNames) == "table" then --// Catches the LightsOn property in ComplexInstanceTable
									for ClassName, Instances in pairs (ClassNames) do
										for InstanceName, SimpleTableOfInstances in pairs (Instances) do
											local TestInstance = ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName][InstanceName][1]

											if TestInstance ~= nil then
												local ChangeTable
												local ToSetOnComplete = {}

												if ChangeTable == nil then
													ChangeTable = {}

													for SettingName, SettingValue in pairs (LightingSettings["ComplexInstances"][ReferencePartName][Relationship][ClassName][InstanceName]) do --// Determines if settings are able to be used, etc.
														if SharedFunctions.CheckProperty(TestInstance, SettingName) then
															if table.find(InternalSettings["BlacklistedSettings"], SettingName) == nil and (InternalSettings["BlacklistedSettingsClass"][ClassName] == nil or table.find(InternalSettings["BlacklistedSettingsClass"][ClassName], SettingName) == nil) then
																if table.find(InternalSettings["AlwaysSet"], SettingName) ~= nil or (InternalSettings["AlwaysSetClass"][ClassName] and table.find(InternalSettings["AlwaysSetClass"][ClassName], SettingName)) then
																	table.insert(ToSetOnComplete, SettingName)
																else
																	ChangeTable[SettingName] = SettingValue
																end
															else
																warn(SettingName.. " unable to be modified")
															end
														else
															if SettingName ~= "ChanceOfChange" then
																warn(SettingName.. " is not a valid property of ".. InstanceName.. ".  Check spelling")
															else
																ChanceOfChange = SettingValue
															end
														end
													end

													for i = 1, #ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName][InstanceName] do
														local ChangeInstance = ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName][InstanceName][i]
														local ChangeTween = TweenService:Create(ChangeInstance, TweenInformation, ChangeTable)
														ChangeTween:Play()

														ChangeTween.Completed:Connect(function()
															ChangeTween:Destroy()

															local NumberOfIndexes = #ToSetOnComplete

															if NumberOfIndexes ~= 0 then
																for e = 1, NumberOfIndexes do
																	ChangeInstance[ToSetOnComplete[e]] = LightingSettings["ComplexInstances"][ReferencePartName][Relationship][ClassName][InstanceName][ToSetOnComplete[e]]
																end
															end
														end)
													end
												end
											end
										end
									end
								end
							end
						end
					else
						LightingSettings["ComplexInstances"][ReferencePartName][ReferencePart] = nil --// Used for deleting reference parts that no longer exist
					end
				end
			end
		end
	end
end

local function HandleMultiRegions() --// Handles the transition of when a player is in multiple lighting regions by setting their lighting to the most recently joined lighting region
	local MostRecentlyJoinedLightingRegion

	for _, RegionName in ipairs (InternalVariables["CurrentRegions"]) do --// Looks at all the CurrentRegions (in order of join)
		local RegionSettings = SettingsHandling:GetRegionSettings(RegionName, "Lighting")

		if RegionSettings then --// If RegionSettings exist (some won't because they will be audio settings)
			if RegionName ~= nil then
				MostRecentlyJoinedLightingRegion = RegionName --// This is the most recently joined lighting region
			end
		end
	end
	
	if Settings["Tween"] then
		module.TweenLighting("ToRegion", MostRecentlyJoinedLightingRegion)
	else
		module.SetLighting("ToRegion", MostRecentlyJoinedLightingRegion)
	end
end

function module.RegionEnter(RegionName)
	local RegionSettings = SettingsHandling:GetRegionSettings(RegionName, "Lighting")

	if not RegionSettings then --// If there are no settings
		return
	end

	if InternalVariables["AudioLighting"] and not RegionSettings["GeneralSettings"]["WeatherExemption"] then --// If weather is active and the region does not have a weather exemption
		return
	end

	InternalVariables["HaltLightingCycle"] = true

	if Settings["Tween"] then
		module.TweenLighting("ToRegion", RegionName)
	else
		module.SetLighting("ToRegion", RegionName)
	end

	module.TweenLighting("ToRegion", RegionName)
end

function module.RegionLeave(RegionName)
	local RegionSettings = SettingsHandling:GetRegionSettings(RegionName, "Lighting")

	if not RegionSettings then
		warn("No setting found for ".. tostring(RegionName))
		return
	end

	if InternalVariables["CurrentLightingRegions"] > 0 then
		HandleMultiRegions()
	else
		InternalVariables["HaltLightingCycle"] = false

		--LightingRemote:FireServer("ResyncToServer")
		LightingSyncToServer:FireServer()
	end
end

function module.TweenLighting(Event: string, LightingName: string)
	SettingsHandling.WaitForSettings("Lighting")

	local NewLightingSettings

	if Event == "ToRegion" then
		NewLightingSettings = SettingsHandling:GetRegionSettings(LightingName, "Lighting")
	elseif Event == "TimeChange" then
		NewLightingSettings = SettingsHandling:GetServerSettings(LightingName, "Lighting")
	elseif Event == "ToServer" then
		if not RunService:IsClient() then
			warn("Improperly tried to sync from server while on the server")
			return
		end

		if not LightingName then --// If no lighting name is provided, that means it needs to sync and get that name
			--LightingRemote:FireServer("ResyncToServer") --// This gets called on the client, so we basically do the same thing that we do when the player joins the game - talk to the server, which knows the current lighting period, and sync to it
			LightingSyncToServer:FireServer()
		else --// If a lighting name is provided, that means we've already synced and can make the set now
			NewLightingSettings = SettingsHandling:GetServerSettings(LightingName, "Lighting")

			Tween(NewLightingSettings, Event)
		end

		return

	elseif Event == "Weather" then
		module.TweenWeather(LightingName)
		return
	elseif Event == "ClearWeather" then
		module:ClearWeather(LightingName)
		return
	end

	if Settings["ClientSided"] == false or RunService:IsClient() then
		if Event == "ToRegion" then
			Tween(NewLightingSettings, Event)
		elseif Event == "TimeChange" and InternalVariables["LightingWeather"] == false and InternalVariables["HaltLightingCycle"] == false then
			Tween(NewLightingSettings, Event) --// Does time changes if there is not interrupting weather
		end
	else
		if RunService:IsServer() then
			LightingRemote:FireAllClients(Event, LightingName, "Tween")
		end
	end
end

function module.SetLighting(Event: string, LightingName: string)
	SettingsHandling.WaitForSettings("Lighting")

	local NewLightingSettings

	print("Here")

	if Event == "ToRegion" then
		PackageHandling:SetCurrentScope("Region")
		NewLightingSettings = PackageHandling:GetCurrentComponent("Lighting")
	elseif Event == "TimeChange" then
		NewLightingSettings = PackageHandling:GetCurrentComponent("Lighting")
	elseif Event == "ToServer" then --// If there is no lighting name provided, that means that 
		if not RunService:IsClient() then
			warn("Improperly tried to sync from server while on the server")
			return
		end

		if not LightingName then --// If no lighting name is provided, that means it needs to sync and get that name
			LightingRemote:FireServer("ResyncToServer") --// This gets called on the client, so we basically do the same thing that we do when the player joins the game - talk to the server, which knows the current audio period, and sync to it
			LightingInitialSyncToServer:FireServer()
		else --// If a lighting name is provided, that means we've already synced and can make the set now
			print("before")
			PackageHandling:SetPackage("Lighting", "Server", LightingName)
			print("right after him")
			NewLightingSettings = PackageHandling:GetCurrentComponent("Lighting")

			Set(NewLightingSettings)
		end
		
		return
	elseif Event == "Weather" then
		module.SetWeather(LightingName)
		return
	elseif Event == "ClearWeather" then
		module:ClearWeather(LightingName)
		return
	end

	if not NewLightingSettings then
		warn("No lighting settings found")
		return
	end

	if Settings["ClientSided"] == false or RunService:IsClient() then
		if Event == "ToRegion" then
			Set(NewLightingSettings)
		elseif Event == "TimeChange" and InternalVariables["LightingWeather"] == false and InternalVariables["HaltLightingCycle"] == false then
			Set(NewLightingSettings) --// Does time changes if there is not interrupting weather
		end
	else
		if RunService:IsServer() then
			LightingRemote:FireAllClients(Event, LightingName, "Tween")
		end
	end
end

function module:ClearWeather(CurrentLightingPeriod: string) --// Don't pass this as an argument, trust me.  It will fill in the rest!
	InternalVariables["LightingWeather"] = false
	InternalVariables["CurrentLightingWeather"] = ""

	local TimeLightingSettings

	local OldLightingPackage = InternalVariables["Non Weather Package"]["Lighting"]

	if RunService:IsServer() then
		TimeLightingSettings = SettingsHandling:GetServerSettings(InternalVariables["CurrentLightingPeriod"], "Lighting")
	else
		TimeLightingSettings = SettingsHandling:GetServerSettings(CurrentLightingPeriod, "Lighting")
	end

	if not TimeLightingSettings then
		warn("Unable to clear weather - no lighting period found")
		return
	end

	InternalVariables["LightingWeather"] = false
	InternalVariables["CurrentLightingWeather"] = ""

	if Settings["ClientSided"] == false or RunService:IsClient() then
		if Settings["Tween"] then
			Tween(TimeLightingSettings, "ClearWeather")
		else
			Set(TimeLightingSettings)
		end
	else
		if RunService:IsServer() then
			local Type

			if Settings["Tween"] then
				Type = "Tween"
			else
				Type = "Set"
			end

			LightingRemote:FireAllClients("ClearWeather", InternalVariables["CurrentLightingPeriod"], Type)
			ClearWeather:FireAllClients()
		end
	end
end

function module.ChangeWeather(WeatherName)
	SettingsHandling.WaitForSettings("Lighting")

	local NewWeatherSettings = SettingsHandling:GetWeatherSettings(WeatherName, "Lighting")

	if not NewWeatherSettings then
		warn("Unable to tween weather - no lighting period found")
		return
	end

	InternalVariables["LightingWeather"] = true
	InternalVariables["CurrentLightingWeather"] = WeatherName

	if Settings["ClientSided"] == false or RunService:IsClient() then
		if Settings["Tween"] then
			Tween(NewWeatherSettings, "Weather")
		else
			Set(NewWeatherSettings)
		end
	else
		if RunService:IsServer() then
			local Type
			
			if Settings["Tween"] then
				Type = "Tween"
			else
				Type = "Set"
			end

			LightingRemote:FireAllClients("Weather", WeatherName, Type)
		end
	end
end

function module.TweenWeather(WeatherName)
	SettingsHandling.WaitForSettings("Lighting")

	local NewWeatherSettings = SettingsHandling:GetWeatherSettings(WeatherName, "Lighting")

	if not NewWeatherSettings then
		warn("Unable to tween weather - no lighting period found")
		return
	end

	InternalVariables["LightingWeather"] = true
	InternalVariables["CurrentLightingWeather"] = WeatherName

	if Settings["ClientSided"] == false or RunService:IsClient() then
		Tween(NewWeatherSettings, "Weather")
	else
		if RunService:IsServer() then
			LightingRemote:FireAllClients("Weather", WeatherName, "Tween")
		end
	end
end

function module.SetWeather(WeatherName)
	SettingsHandling.WaitForSettings("Lighting")

	local NewWeatherSettings = SettingsHandling:GetWeatherSettings(WeatherName, "Lighting")

	if not NewWeatherSettings then
		warn("Unable to set weather - no lighting period found")
		return
	end

	InternalVariables["LightingWeather"] = true
	InternalVariables["CurrentLightingWeather"] = WeatherName

	if Settings["ClientSided"] == false or RunService:IsClient() then
		Set(NewWeatherSettings)
	else
		if RunService:IsServer() then
			LightingRemote:FireAllClients("Weather", WeatherName, "Set")
		end
	end
end

if InternalVariables["InitializedLighting"] == false then
	InternalVariables["InitializedLighting"] = true

	if RunService:IsServer() then
		--// When the player first joins the game (this will always set the lighting, not tween)
		LightingInitialSyncToServer.OnServerEvent:Connect(function(Player)
			local NumberOfTries = 0

			while InternalVariables["TimeInitialized"] == false do --// Sometimes (especialy in Studio) where the client is loading in really fast, it will load in before the CurrentLightingPeriod is set
				task.wait(.2)

				NumberOfTries = NumberOfTries + 1

				if NumberOfTries > InternalSettings["RemoteInitializationMaxTries"] then
					warn("Max Tries has been reached for Remote Initialization")
					return
				end
			end

			local WeatherActive = InternalVariables["Current Package"]["Lighting"]["Weather"]

			if not WeatherActive then
				LightingInitialSyncToServer:FireClient(Player)
			end

			if InternalVariables["LightingWeather"] then
				LightingRemote:FireClient(Player, "ToServer", InternalVariables["CurrentLightingPeriod"], "Set", InternalVariables["CurrentLightingWeather"])
			else
				LightingRemote:FireClient(Player, "ToServer", InternalVariables["CurrentLightingPeriod"], "Set")
			end
		end)

		LightingRemote.OnServerEvent:Connect(function(Player, Status)
			--// Quick denoter to save space for determining if things are being tweened vs set
			local ChangeType

			if Settings["Tween"] then
				ChangeType = "Tween"
			else
				ChangeType = "Set"
			end

			if Status == "SyncToServer" then --// Used when someone first joins the game
				local NumberOfTries = 0

				while InternalVariables["TimeInitialized"] == false do --// Sometimes (especialy in Studio) where the client is loading in really fast, it will load in before the CurrentLightingPeriod is set
					wait(.2)
					NumberOfTries = NumberOfTries + 1

					if NumberOfTries > InternalSettings["RemoteInitializationMaxTries"] then
						warn("Max Tries has been reached for Remote Initialization")
						return
					end
				end

				if InternalVariables["LightingWeather"] then
					LightingRemote:FireClient(Player, "ToServer", InternalVariables["CurrentLightingPeriod"], "Set", InternalVariables["CurrentLightingWeather"])
				else
					LightingRemote:FireClient(Player, "ToServer", InternalVariables["CurrentLightingPeriod"], "Set")
				end

			elseif Status == "ResyncToServer" then
				if InternalVariables["LightingWeather"] then
					LightingRemote:FireClient(Player, "ToServer", InternalVariables["CurrentLightingPeriod"], ChangeType, InternalVariables["CurrentLightingWeather"])
				else
					LightingRemote:FireClient(Player, "ToServer", InternalVariables["CurrentLightingPeriod"], ChangeType)
				end
			end
		end)
	end
end

return module
