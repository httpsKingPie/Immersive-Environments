local module = {}

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Settings = require(script.Parent.Settings)
local TableUtilities = require(script.TableUtilities)

local InternalSettings = require(script.InternalSettings)

local LightingSettings = script.Parent.LightingSettings
local WeatherSettings = script.Parent.WeatherSettings

local LightingSettingsTable = {}
local WeatherSettingsTable = {}

local LightingTimePeriods = {}
local AdjustedTimePeriods = {}

local InstanceTable = {}
local ComplexInstanceTable = {}

local LitLightTable = {} --// Reference table, only used when Settings["AlwaysCheckInstances"] is true

local CurrentLightingPeriod --// String

--// Used for sorting
local CurrentLightingIndex --// Number
local NextLightingIndex --// Number

local TweenInformation = Settings["TweenInformation"]

local TDL2Remote = script.Parent.TDL2Remote

local function SetNextLightingIndex()
	if CurrentLightingIndex + 1 <= Settings["TotalIndexes"] then
		NextLightingIndex = CurrentLightingIndex + 1
	else
		NextLightingIndex = 1
	end
end

local function GetSearchCategory()
	if Settings["ChangingInstanceChildrenOfWorkspace"] == true then
		return Workspace:GetChildren()
	else
		return Workspace:GetDescendants()
	end
end

local function CheckProperty(InstanceToCheck, PropertyName)
	local Clone
	
	if InstanceToCheck:IsA("Terrain") == false and InstanceToCheck:IsA("Lighting") == false then
		Clone = InstanceToCheck:Clone()
		Clone:ClearAllChildren()
	else
		Clone = InstanceToCheck
	end
	
	return (pcall(function()
		return Clone[PropertyName]
	end))
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

local function BuildSettingsTables()
	local Count = 0
	
	local LightingDescendants = LightingSettings:GetDescendants()
	local WeatherDescendants = WeatherSettings:GetDescendants()
	
	for i = 1, #LightingDescendants do
		if LightingDescendants[i]:IsA("ModuleScript") then
			LightingSettingsTable[LightingDescendants[i].Name] = require(LightingDescendants[i])
			Count = Count + 1
		end
	end
	
	for i = 1, #WeatherDescendants do
		if WeatherDescendants[i]:IsA("ModuleScript") then
			WeatherSettingsTable[WeatherDescendants[i].Name] = require(WeatherDescendants[i])
		end
	end
	
	Settings["TotalIndexes"] = Count
	InternalSettings["SettingTablesBuilt"] = true
end

local function WaitForSettingsTables()
	while InternalSettings["SettingTablesBuilt"] == false do
		wait(.1)
	end
end

local function DoesChange(ChanceOfChange)
	if ChanceOfChange == nil or ChanceOfChange == 100 then
		return true
	else	
		if math.random(1, 100) <= ChanceOfChange then
			return true
		else
			return false
		end
	end
end

local function Set(Settings)
	local AdjustOnlyLightsOn
	
	if Settings["GeneralSettings"]["AdjustOnlyLightsOn"] ~= nil then
		AdjustOnlyLightsOn = Settings["GeneralSettings"]["AdjustOnlyLightsOn"]
	else
		AdjustOnlyLightsOn = false
	end
	
	for ClassName, ClassSettings in pairs (Settings) do --// Changing Lighting Service and Children (ChanceOfChange does not apply here)
		if InternalSettings["SettingInstanceCorrelations"][ClassName] ~= nil and InternalSettings["SettingInstanceCorrelations"][ClassName] ~= false then
			local TargetInstance = InternalSettings["SettingInstanceCorrelations"][ClassName]
			
			for SettingName, SettingValue in pairs (ClassSettings) do --// Determines if settings are able to be used and sets
				if CheckProperty(TargetInstance, SettingName) then 
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
	
	if Settings["Instances"] then		
		for ClassName, Instances in pairs (Settings["Instances"]) do --// In settings right now
			for InstanceName, SpecificSettings in pairs (Instances) do
				CheckInstanceTableExistence(InstanceName, ClassName)
				
				local ChangeTable
				local ChanceOfChange = 100 --// Default always changes
				
				for _Instance, UniqueProperties in pairs (InstanceTable[ClassName][InstanceName]) do --// Switch to the InstanceTable
					if (AdjustOnlyLightsOn == true and Settings["Instances"][ClassName][InstanceName]["IsLight"] == true and UniqueProperties["LightsOn"] == true) or AdjustOnlyLightsOn == false then
						--// Above conditional simplified just means, if the settings says to only adjust the lights on, and the instance is one that does have the LightsOn status, and the instance is "on" then proceed, or if the Setting does not abide to only lights on the proceed
						
						
						if ChangeTable == nil then
							ChangeTable = {}
							
							for SettingName, SettingValue in pairs (SpecificSettings) do --// Determines if settings are able to be used, etc.
								if table.find(InternalSettings["NonPropertySettings"], SettingName) == nil then 
									if CheckProperty(_Instance, SettingName) then
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
						
						if DoesChange(ChanceOfChange) then
							for ApprovedSettingName, ApprovedSettingValue in pairs (ChangeTable) do
								_Instance[ApprovedSettingName] = ApprovedSettingValue
							end
							
							InstanceTable[ClassName][InstanceName][_Instance]["LightsOn"] = Settings["Instances"][ClassName][InstanceName]["IsLightOn"]
						end
					end
				end
			end
		end
	end
	
	if Settings["ComplexInstances"] then
		local ListOfLights = {} --// Looks like: index = ReferencePartName; value = true/false, basically just tells whether this is treated as an instance affected by LightsOn or not
		
		for ReferencePartName, Relationships in pairs (Settings["ComplexInstances"]) do --// This is NOT parsing through the ComplexInstanceTable, this is parsing through the ComplexInstances table in the respective settings
			
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
		
		for ReferencePartName, _ in pairs (Settings["ComplexInstances"]) do
			local ChanceOfChange = 100 --// Defaults to 100  (i.e. always changes)
			
			if Settings["ComplexInstances"][ReferencePartName]["GeneralSettings"]["ChanceOfChange"] ~= nil then
				ChanceOfChange = Settings["ComplexInstances"][ReferencePartName]["GeneralSettings"]["ChanceOfChange"]
			end
			
			for ReferencePart, Relationships in pairs (ComplexInstanceTable[ReferencePartName]) do --// Parsing through all the reference parts
				if (AdjustOnlyLightsOn == true and ListOfLights[ReferencePartName] == true and ComplexInstanceTable[ReferencePartName][ReferencePart]["LightsOn"] == true) or AdjustOnlyLightsOn == false then
					--// Above conditional simplified just means, if the settings says to only adjust the lights on, and the complex instance is one that does have the LightsOn status, and the current instance is "on" then proceed, or if the Setting does not abide to only lights on the proceed
					if ReferencePart.Parent ~= nil then
						
						if DoesChange(ChanceOfChange) then
							
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
													
													for SettingName, SettingValue in pairs (Settings["ComplexInstances"][ReferencePartName][Relationship][ClassName][InstanceName]) do --// Determines if settings are able to be used, etc. CHANGE SETTINGS HERE
														if table.find(InternalSettings["NonPropertySettings"], SettingName) == nil then 
															if CheckProperty(TestInstance, SettingName) then
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
													
													ComplexInstanceTable[ReferencePartName][ReferencePart]["LightsOn"] = Settings["ComplexInstances"][ReferencePartName]["GeneralSettings"]["IsLightOn"]
												end
											end
										end
									end
								end
							end
						end
					else
						Settings["ComplexInstances"][ReferencePartName][ReferencePart] = nil --// Used for deleting reference parts that no longer exist
					end
				end
			end
		end
	end
end

local function Tween(Settings)
	local AdjustOnlyLightsOn
	
	if Settings["GeneralSettings"]["AdjustOnlyLightsOn"] ~= nil then
		AdjustOnlyLightsOn = Settings["GeneralSettings"]["AdjustOnlyLightsOn"]
	else
		AdjustOnlyLightsOn = false
	end
	
	for ClassName, ClassSettings in pairs (Settings) do --// Changing Lighting Service and Children (ChanceOfChange does not apply here)
		if InternalSettings["SettingInstanceCorrelations"][ClassName] ~= nil and InternalSettings["SettingInstanceCorrelations"][ClassName] ~= false then
			local TargetInstance = InternalSettings["SettingInstanceCorrelations"][ClassName] --// Instance being changed, also used for determining setting validation
			
			local ChangeTable = {}
			local ToSetOnComplete = {}
			
			for SettingName, SettingValue in pairs (ClassSettings) do --// Determines if settings are able to be used, etc.
				if CheckProperty(TargetInstance, SettingName) ~= nil then
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
	
	if Settings["Instances"] then
		for ClassName, Instances in pairs (Settings["Instances"]) do
			for InstanceName, SpecificSettings in pairs (Instances) do
				CheckInstanceTableExistence(InstanceName, ClassName)
				
				
				--
				
				local ChangeTable
				
				local ToSetOnComplete = {}
				
				local ChanceOfChange = 100 --// Default always changes
				
				for _Instance, UnqiueProperties in pairs (InstanceTable[ClassName][InstanceName]) do
					if (AdjustOnlyLightsOn == true and Settings["Instances"][ClassName][InstanceName]["IsLight"] == true and UnqiueProperties["LightsOn"] == true) or AdjustOnlyLightsOn == false then
						--// Above conditional simplified just means, if the settings says to only adjust the lights on, and the instance is one that does have the LightsOn status, and the instance is "on" then proceed, or if the Setting does not abide to only lights on the proceed
						
						
						
						if ChangeTable == nil then
							ChangeTable = {}
							
							for SettingName, SettingValue in pairs (SpecificSettings) do --// Determines if settings are able to be used, etc.
								if table.find(InternalSettings["NonPropertySettings"], SettingName) == nil then
									if CheckProperty(_Instance, SettingName) then
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
						
						if DoesChange(ChanceOfChange) then
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
				
				
				--
				
				--[[if #InstanceTable[ClassName][InstanceName] ~= 0 then
					local ChangeTable = {}
					local ToSetOnComplete = {}
					local ChanceOfChange = 100 --// Default always changes
					
					local TestInstance = InstanceTable[ClassName][InstanceName][1] --// Used for determining setting validation
					for SettingName, SettingValue in pairs (SpecificSettings) do --// Determines if settings are able to be used, etc.
						if TestInstance[SettingName] then
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
					
					for i = 1, #InstanceTable[ClassName][InstanceName] do --// Changes the settings
						if DoesChange(ChanceOfChange) then
							local TargetInstance = InstanceTable[ClassName][InstanceName][i]
							local ChangeTween = TweenService:Create(TargetInstance, TweenInformation, ChangeTable)
							ChangeTween:Play()
							
							ChangeTween.Completed:Connect(function()
								ChangeTween:Destroy()
								
								local NumberOfIndexes = #ToSetOnComplete
							
								if NumberOfIndexes ~= 0 then
									for i = 1, NumberOfIndexes do
										--TargetInstance[ToSetOnComplete[i]] --= SpecificSettings[ToSetOnComplete[i]]
									--end
								--end
							--end)
						--end
					--end
				--end]]
			end
		end
	end
	
	if Settings["ComplexInstances"] then
		local ListOfLights = {} --// Looks like: index = ReferencePartName; value = true/false, basically just tells whether this is treated as an instance affected by LightsOn or not 
		
		for ReferencePartName, Relationships in pairs (Settings["ComplexInstances"]) do --// This is NOT parsing through the ComplexInstanceTable, this is parsing through the ComplexInstances table in the respective settings
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
		
		for ReferencePartName, _ in pairs (Settings["ComplexInstances"]) do
			local ChanceOfChange = 100 --// Defaults to 100 (i.e. always changes)
			
			if Settings["ComplexInstances"][ReferencePartName]["GeneralSettings"]["ChanceOfChange"] ~= nil then
				ChanceOfChange = Settings["ComplexInstances"][ReferencePartName]["GeneralSettings"]["ChanceOfChange"]
			end
			
			for ReferencePart, Relationships in pairs (ComplexInstanceTable[ReferencePartName]) do
				if (AdjustOnlyLightsOn == true and ListOfLights[ReferencePartName] == true and ComplexInstanceTable[ReferencePartName][ReferencePart]["LightsOn"] == true) or AdjustOnlyLightsOn == false then
					--// Above conditional simplified just means, if the settings says to only adjust the lights on, and the complex instance is one that does have the LightsOn status, and the current instance is "on" then proceed, or if the Setting does not abide to only lights on the proceed
					if ReferencePart.Parent ~= nil then
						if DoesChange(ChanceOfChange) then
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
													
													for SettingName, SettingValue in pairs (Settings["ComplexInstances"][ReferencePartName][Relationship][ClassName][InstanceName]) do --// Determines if settings are able to be used, etc.
														if CheckProperty(TestInstance, SettingName) then
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
																for i = 1, NumberOfIndexes do
																	ChangeInstance[ToSetOnComplete[i]] = Settings["ComplexInstances"][ReferencePartName][Relationship][ClassName][InstanceName][ToSetOnComplete[i]]
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
						Settings["ComplexInstances"][ReferencePartName][ReferencePart] = nil --// Used for deleting reference parts that no longer exist
					end
				end
			end
		end
	end
end

local function AdjustStartTimes()
	local ClockTime1 = Lighting.ClockTime
	
	wait(Settings["AdjustmentTime"])
	
	local ClockTime2 = Lighting.ClockTime
	
	local RateOfTime --// A rate of in-game hours per second
	
	if ClockTime1 == ClockTime2 then
		warn("No day-night script is detected.  No adjustments made to times")
		AdjustedTimePeriods = LightingTimePeriods
		return
	elseif ClockTime1 < ClockTime2 then
		RateOfTime = (ClockTime2 - ClockTime1)/Settings["AdjustmentTime"]
	else --// Midnight was crossed
		RateOfTime = (24 - ClockTime2 - ClockTime1)/Settings["AdjustmentTime"]
	end
	
	local Adjustment = RateOfTime * TweenInformation.Time --// Adjustment results in a number of seconds for which all all Lighting Periods must have their start times adjusted
	
	AdjustedTimePeriods = LightingTimePeriods
	if Settings["EnableSorting"] == true then
		for _, PeriodSettings in ipairs (AdjustedTimePeriods) do
			if PeriodSettings["StartTime"] - Adjustment >= 0 then
				PeriodSettings["StartTime"] = PeriodSettings["StartTime"] - Adjustment
			else
				PeriodSettings["StartTime"] = 24 + PeriodSettings["StartTime"] - Adjustment
			end
			
			if PeriodSettings["EndTime"] - Adjustment >= 0 then
				PeriodSettings["EndTime"] = PeriodSettings["EndTime"] - Adjustment
			else
				PeriodSettings["EndTime"] = 24 + PeriodSettings["EndTime"] - Adjustment
			end
		end
	else
		for _, PeriodSettings in pairs (AdjustedTimePeriods) do
			if PeriodSettings["StartTime"] - Adjustment >= 0 then
				PeriodSettings["StartTime"] = PeriodSettings["StartTime"] - Adjustment
			else
				PeriodSettings["StartTime"] = 24 + PeriodSettings["StartTime"] - Adjustment
			end
			
			if PeriodSettings["EndTime"] - Adjustment >= 0 then
				PeriodSettings["EndTime"] = PeriodSettings["EndTime"] - Adjustment
			else
				PeriodSettings["EndTime"] = 24 + PeriodSettings["EndTime"] - Adjustment
			end
		end
	end
end

local function PopulateTimes() --// Creates a general table with i, as lighting period name and the times as content
	for LightingPeriodName, LightingSettings in pairs (LightingSettingsTable) do
		if LightingSettings["GeneralSettings"]["StartTime"] and LightingSettings["GeneralSettings"]["EndTime"] then
			LightingTimePeriods[LightingPeriodName] = {
				["StartTime"] = LightingSettings["GeneralSettings"]["StartTime"],
				["EndTime"] = LightingSettings["GeneralSettings"]["EndTime"],
			}
		end
	end
end

local function SortTimes()
	local NewTable = {}
	local InitialStart = 0
	local CurrentIndex = 1
	
	local TotalIndexes = 0
	local TotalIndexesDetermined = false
	
	local CurrentName
	local CurrentStart
	local CurrentEnd
	
	local CheckedNames = {}
	local Completed = false

	local function Check()
		local Ticked = false
		
		for LightingPeriodName, Times in pairs (LightingTimePeriods) do
			Ticked = true
			
			if TotalIndexesDetermined == false then
				TotalIndexes = TotalIndexes + 1
			end
			
			if CurrentStart == nil and CurrentEnd  == nil and CurrentName == nil and table.find(CheckedNames, LightingPeriodName) == nil then
				CurrentName = LightingPeriodName
				CurrentStart = Times["StartTime"]
				CurrentEnd = Times["EndTime"]
			elseif Times["StartTime"] >= InitialStart and Times["StartTime"] < CurrentStart and table.find(CheckedNames, LightingPeriodName) == nil then
				CurrentName = LightingPeriodName
				CurrentStart = Times["StartTime"]
				CurrentEnd = Times["EndTime"]
			end
		end
		
		if Ticked == true then
			NewTable[CurrentIndex] = {
				["Name"] = CurrentName,
				["StartTime"] = CurrentStart,
				["EndTime"] = CurrentEnd,
			}
			
			table.insert(CheckedNames, CurrentName)
			
			CurrentIndex = CurrentIndex + 1
			InitialStart = CurrentEnd
			
			LightingTimePeriods[CurrentName] = nil
			
			CurrentName = nil
			CurrentStart = nil
			CurrentEnd = nil
			
			if TotalIndexesDetermined == false then
				TotalIndexesDetermined = true
			end
		else
			return
		end
		
		if CurrentIndex > TotalIndexes then
			Completed = true
		end
	end
	
	while Completed == false do
		Check()
	end
	
	LightingTimePeriods = NewTable
end

local function GetAdjustedPeriod()
	local CurrentTime = Lighting.ClockTime
	
	for LightingPeriodName, PeriodSettings in pairs (AdjustedTimePeriods) do
		if PeriodSettings["EndTime"] > PeriodSettings["StartTime"] then
			if CurrentTime >= PeriodSettings["StartTime"] and CurrentTime < PeriodSettings["EndTime"] then
				return LightingPeriodName
			end
		else
			if (CurrentTime < 24 and CurrentTime >= PeriodSettings["StartTime"]) or (CurrentTime < PeriodSettings["EndTime"]) then
				return LightingPeriodName
			end
		end
	end
end

local function RunSortedCheckCycle()
	
	for Index, PeriodSettings in ipairs (LightingTimePeriods) do
		if PeriodSettings["Name"] == CurrentLightingPeriod then
			CurrentLightingIndex = Index
			SetNextLightingIndex()
			break
		end
	end
	
	local StartTimeForNextPeriod = AdjustedTimePeriods[NextLightingIndex]["StartTime"]
	
	while wait(Settings["CheckTime"]) do
		local CurrentTime = Lighting.ClockTime
		
		local StartTimeForNextPeriod = AdjustedTimePeriods[NextLightingIndex]["StartTime"]
		local EndTimeForNextPeriod = AdjustedTimePeriods[NextLightingIndex]["EndTime"]
		
		if EndTimeForNextPeriod > StartTimeForNextPeriod then
			if CurrentTime >= StartTimeForNextPeriod then
				CurrentLightingIndex = NextLightingIndex
				CurrentLightingPeriod = LightingTimePeriods[CurrentLightingIndex]["Name"]
				SetNextLightingIndex()
				
				if Settings["Tween"]  == true then
					module.TweenLighting(CurrentLightingPeriod)
				else
					module.SetLighting(CurrentLightingPeriod)
				end
			end
		else --// Means times go over midnight, ex: start at 22 ends at 4
			if (CurrentTime < 24 and CurrentTime >= StartTimeForNextPeriod) or (CurrentTime < EndTimeForNextPeriod) then
				CurrentLightingIndex = NextLightingIndex
				CurrentLightingPeriod = LightingTimePeriods[CurrentLightingIndex]["Name"]
				SetNextLightingIndex()
				
				if Settings["Tween"]  == true then
					module.TweenLighting(CurrentLightingPeriod)
				else
					module.SetLighting(CurrentLightingPeriod)
				end
			end
		end
		
	end
end

local function RunCheckCycle()
	local LightingPeriodInLoop = module.GetCurrentLightingPeriod()
	
	while wait(Settings["CheckTime"]) do
		local CurrentTime = Lighting.ClockTime
		local CurrentAdjustedPeriod = GetAdjustedPeriod()
		
		if CurrentAdjustedPeriod ~= module.GetCurrentLightingPeriod() then --// If this changes, that means they are entering a new lighting period
			CurrentLightingPeriod = CurrentAdjustedPeriod
			
			if Settings["Tween"]  == true then
				module.TweenLighting(CurrentLightingPeriod)
			else
				module.SetLighting(CurrentLightingPeriod)
			end
		end
	end
end

function module.Run()
	BuildSettingsTables() --// Puts the settings in a more readable version
	
	if Settings["AutomaticTransitions"] == true and RunService:IsServer() then
		
		PopulateTimes() --// Takes the times in setting modules and converts them into a more readable version
		
		if Settings["EnableSorting"] == true then
			SortTimes()
		end
		
		AdjustStartTimes()
		
		module.GetCurrentLightingPeriod() --// Gets the current lighting period based off of ClockTime
		
		module.SetLighting(CurrentLightingPeriod) --// Changes the lighting to the current lighting period
		
		if Settings["EnableSorting"] == true then
			coroutine.wrap(RunSortedCheckCycle)()
		else
			coroutine.wrap(RunCheckCycle)()
		end
	end
end

function module.TweenLighting(LightingName, WeatherOverride)
	WaitForSettingsTables()
	
	if LightingSettingsTable[LightingName] then
		local LightingSettings = LightingSettingsTable[LightingName]
		
		if Settings["ClientSided"] == false or RunService:IsClient() then
			if InternalSettings["Weather"] == false or WeatherOverride == true then
				Tween(LightingSettings)
			end
		else
			if RunService:IsServer() then
				TDL2Remote:FireAllClients("Lighting", LightingName, "Tween")
			end
		end
	else
		warn("Settings for ".. tostring(LightingName).. " not found in LightingSettings")
	end
end

function module.TweenWeather(WeatherName)
	WaitForSettingsTables()
	
	if WeatherSettingsTable[WeatherName] then
		local WeatherSettings = WeatherSettingsTable[WeatherName]
		
		if Settings["ClientSided"] == false or RunService:IsClient() then
			InternalSettings["Weather"] = true
			Tween(WeatherSettings)
		else
			if RunService:IsServer() then
				TDL2Remote:FireAllClients("Weather", WeatherName, "Tween")
			end
		end
	else
		warn("Settings for ".. tostring(WeatherName).. " not found in WeatherSettings")
	end
end

function module.ClearWeather(Type)
	if Type == "Set" then
		InternalSettings["Weather"] = false
		
		Set(module.GetCurrentLightingPeriod(true))
	elseif Type == "Tween" then
		InternalSettings["Weather"] = false
		
		Tween(module.GetCurrentLightingPeriod(true))
	end
end

function module.GetCurrentLightingPeriod(IgnoreCached)
	if CurrentLightingPeriod == nil or IgnoreCached == true then
		local CurrentTime = Lighting.ClockTime
		
		if Settings["EnableSorting"] == true then
			for _, PeriodSettings in ipairs (LightingTimePeriods) do
				if CurrentTime >= PeriodSettings["StartTime"] and CurrentTime <= PeriodSettings["EndTime"] then
					CurrentLightingPeriod = PeriodSettings["Name"]
					return CurrentLightingPeriod
				end
			end
			
			warn("Lighting periods are not continuous - lighting period not found")
		else
			for LightingPeriodName, PeriodSettings in pairs (LightingTimePeriods) do
				if CurrentTime >= PeriodSettings["StartTime"] and CurrentTime <= PeriodSettings["EndTime"] then
					CurrentLightingPeriod = LightingPeriodName
					return CurrentLightingPeriod
				end
			end
			
			warn("Lighting periods are not continuous - lighting period not found")
		end
	else
		return CurrentLightingPeriod
	end
end

function module.SetWeather(WeatherName)
	WaitForSettingsTables()
	
	if WeatherSettingsTable[WeatherName] then
		local WeatherSettings = WeatherSettingsTable[WeatherName]
		
		if Settings["ClientSided"] == false or RunService:IsClient() then
			InternalSettings["Weather"] = true
			Set(WeatherSettings)
		else
			if RunService:IsServer() then
				TDL2Remote:FireAllClients("Weather", WeatherName, "Set")
			end
		end
	else
		warn("Settings for ".. tostring(WeatherName).. " not found in WeatherSettings")
	end
end

function module.SetLighting(LightingName, WeatherOverride)
	WaitForSettingsTables()
	
	if LightingSettingsTable[LightingName] then
		local LightingSettings = LightingSettingsTable[LightingName]
		
		if Settings["ClientSided"] == false or RunService:IsClient() then
			if InternalSettings["Weather"] == false or WeatherOverride == true then
				Set(LightingSettings)
			end
		else
			if RunService:IsServer() then
				TDL2Remote:FireAllClients("Lighting", LightingName, "Set")
			end
		end
	else
		warn("Settings for ".. tostring(LightingName).. " not found in LightingSettings")
	end
end

if InternalSettings["Initialized"] == false and RunService:IsServer() then
	InternalSettings["Initialized"] = true
	
	TDL2Remote.OnServerEvent:Connect(function(Player, Status)
		if Status == "Entered" then
			TDL2Remote:FireClient(Player, module.GetCurrentLightingPeriod(), "Set")
		end
	end)
end

return module
