local module = {}

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Main = script.Parent
local IEFolder = Main.Parent

local Settings = require(IEFolder.Settings)

local InternalSettings = require(Main.InternalSettings)
local InternalVariables = require(Main.InternalVariables)
local PackageHandling = require(Main.PackageHandling)
local RemoteHandling = require(Main.RemoteHandling)
local SharedFunctions = require(Main.SharedFunctions)

--// Filled in after
local TimeHandling
local WeatherHandling

local InitialSyncToServer: RemoteEvent = RemoteHandling:GetRemote("Lighting", "InitialSyncToServer")

local InstanceTable = {}
local ComplexInstanceTable = {}

local LitLightTable = {} --// Reference table, only used when Settings["AlwaysCheckInstances"] is true

local function GetSearchCategory()
	if Settings["All Lighting Instances Are Children Of Workspace"] then
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

--[[
	InstanceTables are just a simplfied way of retrieving whether something's lights are on or not
]]

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
			if not Settings["Always Check Instances"] then --// Permission is allowed to skip if it's already there/cached (basically the process has already occurred)
				return
			end
		end
	end

	if InstanceTable[ClassName] == nil then
		InstanceTable[ClassName] = {}
	end

	InstanceTable[ClassName][InstanceName] = {}

	local SearchCategory = GetSearchCategory()

	--// Cleaner rewrite of the below
	for _, SearchedInstance: Instance in pairs (SearchCategory) do
		if SearchedInstance.Name == InstanceName and SearchedInstance:IsA(ClassName) then
			InstanceTable[ClassName][InstanceName][SearchedInstance] = {}

			if not Settings["Always Check Instances"] then
				InstanceTable[ClassName][InstanceName][SearchedInstance]["LightsOn"] = false
			else
				if CheckLitLightTable(SearchedInstance, "Normal", ClassName, InstanceName) then
					InstanceTable[ClassName][InstanceName][SearchedInstance]["LightsOn"] = true
				else
					InstanceTable[ClassName][InstanceName][SearchedInstance]["LightsOn"] = false
				end
			end
		end
	end
end

--[[
	InstanceTables are just a simplfied way of retrieving whether something's lights are on or not
]]

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
								if not Settings["Always Check Instances"] then --// Permission is allowed to skip if it's already there/cached
									return
								end
							end
						end
					end
				end
			end
		end
	end

	if not ComplexInstanceTable[ReferencePartName] then
		ComplexInstanceTable[ReferencePartName] = {}
	end

	local SearchCategory = GetSearchCategory()

	--// Instance Check

	for _, SearchedInstance: Instance in pairs (SearchCategory) do
		if SearchedInstance.Name == ReferencePartName then
			--// Table checks
			local ReferencePart = SearchedInstance

			if not ComplexInstanceTable[ReferencePartName][ReferencePart] then --// Cases where the reference part is not yet indexed
				ComplexInstanceTable[ReferencePartName][ReferencePart] = {}
				ComplexInstanceTable[ReferencePartName][ReferencePart]["LightsOn"] = false
				ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship] = {}
				ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName] = {}
				ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName][InstanceName] = {}

			elseif not ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship] then --// Cases where the reference part is already indexed, but a new relationship is being added
				ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship] = {}
				ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName] = {}
				ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName][InstanceName] = {}

			elseif not ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName] then --// Cases where the relationship is already indexed, but a new class name is being added
				ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName] = {}
				ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName][InstanceName] = {}

			elseif not ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName][InstanceName] then --// Cases where a new instance is being added to an existing class
				ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName][InstanceName] = {}
			end

			--// Evaluates whether the complex instance matches the arguments
			local function CheckAndAddToComplexInstanceTable(InstanceToEvaluate)
				if InstanceToEvaluate.Name == InstanceName and InstanceToEvaluate:IsA(ClassName) then
					table.insert(ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName][InstanceName], InstanceToEvaluate)
				end
			end

			--// Evaluates the instance and processes it accordingly into the complex instance table
			if Relationship == "Child" then
				local Children: table = ReferencePart:GetChildren()

				for _, ChildInstance: Instance in pairs (Children) do
					CheckAndAddToComplexInstanceTable(ChildInstance)
				end

			elseif Relationship == "Descendant" then
				local Descendants: table = ReferencePart:GetDescendants()

				for _, DescendantInstance: Instance in pairs (Descendants) do
					CheckAndAddToComplexInstanceTable(DescendantInstance)
				end

			elseif Relationship == "Parent" then
				local ParentInstance: Instance = SearchedInstance.Parent

				CheckAndAddToComplexInstanceTable(ParentInstance)

			elseif Relationship == "Sibling" then
				local Siblings = ReferencePart.Parent:GetChildren()

				for _, SiblingInstance: Instance in pairs (Siblings) do
					CheckAndAddToComplexInstanceTable(SiblingInstance)
				end

			elseif Relationship == "Self" then
				CheckAndAddToComplexInstanceTable(ReferencePart)
			end
		end
	end
end

--[[
	The following functions are modified to integrate with CullingSystem
	
	They are variations of the normal functions (CheckInstanceTableExistence, CheckComplexInstanceTableExistence, and Set)
]]

local function CheckInstanceTableExistenceForCullingSystem(InstanceToCheck: Instance, ClassName: string, InstanceName: string)
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

	if not InstanceTable[ClassName] then
		InstanceTable[ClassName] = {}
	end

	if not InstanceTable[ClassName][InstanceName] then
		InstanceTable[ClassName][InstanceName] = {}
	end

	InstanceTable[ClassName][InstanceName][InstanceToCheck] = {}
	InstanceTable[ClassName][InstanceName][InstanceToCheck]["LightsOn"] = false

	local Connection: RBXScriptConnection

	--// When the instance gets destroyed, clear it from memory
	Connection = InstanceToCheck.AncestryChanged:Connect(function()
		InstanceTable[ClassName][InstanceName][InstanceToCheck] = nil
		Connection:Disconnect()
	end)
end

local function CheckComplexInstanceTableExistenceForCullingSystem(ReferencePart: Instance, CurrentComponentSettings: table)
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

	--[[
		So basically, this function consolidates all of the information

		We take the child/descendant/whatever and say
			Alright, based on the component settings, we know that you (as whatever the relationship) should be this class and be named this thing
			We check those arguments/conditions below, and if it's good, it adds it to the complex instance table
	]]

	--// Verifies all the indexes in the ComplexInstance table exist
	local function VerifyComplexInstanceTableInstancesExist(ReferencePartName: string, Relationship: string, ClassName: string, InstanceName: string)
		if not ComplexInstanceTable[ReferencePartName][ReferencePart] then --// Cases where the reference part is not yet indexed
			ComplexInstanceTable[ReferencePartName][ReferencePart] = {}
			ComplexInstanceTable[ReferencePartName][ReferencePart]["LightsOn"] = false
			ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship] = {}
			ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName] = {}
			ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName][InstanceName] = {}

		elseif not ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship] then --// Cases where the reference part is already indexed, but a new relationship is being added
			ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship] = {}
			ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName] = {}
			ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName][InstanceName] = {}

		elseif not ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName] then --// Cases where the relationship is already indexed, but a new class name is being added
			ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName] = {}
			ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName][InstanceName] = {}

		elseif not ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName][InstanceName] then --// Cases where a new instance is being added to an existing class
			ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName][InstanceName] = {}
		end
	end

	--// 
	local function CheckAndAddToComplexInstanceTable(ClassSettings: table, ReferencePart: Instance, Relationship: string, InstanceToEvaluate: string)
		local ReferencePartName: string = ReferencePart.Name

		for ClassName: string, Instances: table in pairs (ClassSettings) do --// Verify that the child fits a designated class
			for InstanceName, _ in pairs(Instances) do --// Verify that the child is named the same thing
				if InstanceToEvaluate.Name == InstanceName and InstanceToEvaluate:IsA(ClassName) then
					VerifyComplexInstanceTableInstancesExist(ReferencePartName, Relationship, ClassName, InstanceName)

					table.insert(ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName][InstanceName], InstanceToEvaluate)
				end
			end
		end 
	end

	local ReferencePartName: string = ReferencePart.Name

	local Relationships = CurrentComponentSettings["ComplexInstances"][ReferencePartName]

	for Relationship: string, ClassSettings: table in pairs (Relationships) do
		if Relationship == "Child" then
			local Children: table = ReferencePart:GetChildren()

			for _, ChildInstance: Instance in pairs (Children) do --// Parse through all the children of the reference part
				CheckAndAddToComplexInstanceTable(ClassSettings, ReferencePart, Relationship, ChildInstance)
			end

		elseif Relationship == "Descendant" then
			local Descendants: table = ReferencePart:GetDescendants()

			for _, DescendantInstance: Instance in pairs (Descendants) do --// Parse through all the children of the reference part
				CheckAndAddToComplexInstanceTable(ClassSettings, ReferencePart, Relationship, DescendantInstance)
			end

		elseif Relationship == "Parent" then
			local ParentInstance: Instance = ReferencePart.Parent

			CheckAndAddToComplexInstanceTable(ClassSettings, ReferencePart, Relationship, ParentInstance)

		elseif Relationship == "Sibling" then
			local Siblings = ReferencePart.Parent:GetChildren()

			for _, SiblingInstance: Instance in pairs (Siblings) do --// Parse through all the children of the reference part
				CheckAndAddToComplexInstanceTable(ClassSettings, ReferencePart, Relationship, SiblingInstance)
			end
		elseif Relationship == "Self" then		
			CheckAndAddToComplexInstanceTable(ClassSettings, ReferencePart, Relationship, ReferencePart)
		end
	end

	local Connection: RBXScriptConnection

	--// When the instance gets destroyed, clear it from memory
	Connection = ReferencePart.AncestryChanged:Connect(function()
		if not ComplexInstanceTable[ReferencePartName] then
			return
		end

		ComplexInstanceTable[ReferencePartName][ReferencePart] = nil
		Connection:Disconnect()
	end)
end

local function SetForCullingSystem(InstanceToSet: Instance, InstanceType: string, ComponentSettings: table)
	local AdjustOnlyLightsOn

	--// These are component wide settings
	if ComponentSettings["GeneralSettings"]["AdjustOnlyLightsOn"] ~= nil then
		AdjustOnlyLightsOn = ComponentSettings["GeneralSettings"]["AdjustOnlyLightsOn"]
	else
		AdjustOnlyLightsOn = false
	end

	if InstanceType == "Simple" then
		local ClassName: string = InstanceToSet.ClassName
		local InstanceName = InstanceToSet.Name

		local UniqueProperties: table = InstanceTable[ClassName][InstanceName]
		local SpecificSettings: table = ComponentSettings["Instances"][ClassName][InstanceName]

		local ChangeTable = {}
		local ChanceOfChange = 100 --// Default always changes

		--// Conditional checks checks
		local InstanceIsLight: boolean = ComponentSettings["Instances"][ClassName][InstanceName]["IsLight"]
		local InstanceLightIsOn: boolean = UniqueProperties["LightsOn"]

		if (AdjustOnlyLightsOn == true and InstanceIsLight and InstanceLightIsOn) or AdjustOnlyLightsOn == false then
			--// This builds the ChangeTable (which determines which properties are changed)
			for SettingName, SettingValue in pairs (SpecificSettings) do --// Determines if settings are able to be used, etc.
				if table.find(InternalSettings["NonPropertySettings"], SettingName) == nil then 
					if SharedFunctions.CheckProperty(InstanceToSet, SettingName) then
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

		--// Set the properties
		if not SharedFunctions.DoesChange(ChanceOfChange) then
			return
		end
		
		for ApprovedSettingName, ApprovedSettingValue in pairs (ChangeTable) do
			InstanceToSet[ApprovedSettingName] = ApprovedSettingValue
		end

		--// Denotes whether the light is 'on' or 'off'
		InstanceTable[ClassName][InstanceName][InstanceToSet]["LightsOn"] = ComponentSettings["Instances"][ClassName][InstanceName]["IsLightOn"]
	elseif InstanceType == "Complex" then
		local ReferencePart: Instance = InstanceToSet
		local ReferencePartName: string = ReferencePart.Name

		local SpecificSettings: table = ComponentSettings["ComplexInstances"][ReferencePartName]

		--// Conditional checks
		local ComplexInstanceIsLight: boolean --// Filled in below
		local ComplexInstanceLightIsOn: boolean = ComplexInstanceTable[ReferencePartName][ReferencePart]["LightsOn"]
		
		--// Determines whether the ComplexInstance is a light
		if SpecificSettings["GeneralSettings"]["IsLight"] then
			ComplexInstanceIsLight = SpecificSettings["GeneralSettings"]["IsLight"]
		else
			ComplexInstanceIsLight = false --// Defaults to not registering a part as a light
		end

		local ChanceOfChange = 100 --// Defaults to 100  (i.e. always changes)

		if ComponentSettings["ComplexInstances"][ReferencePartName]["GeneralSettings"]["ChanceOfChange"] ~= nil then
			ChanceOfChange = ComponentSettings["ComplexInstances"][ReferencePartName]["GeneralSettings"]["ChanceOfChange"]
		end

		if (AdjustOnlyLightsOn == true and ComplexInstanceIsLight == true and ComplexInstanceLightIsOn == true) or AdjustOnlyLightsOn == false then
			--// Above conditional simplified just means, if the settings says to only adjust the lights on, and the complex instance is one that does have the LightsOn status, and the current instance is "on" then proceed, or if the Setting does not abide to only lights on the proceed
			
			--// Used for deleting reference parts that no longer exist (backup - connection should already take care of this)
			if ReferencePart.Parent == nil then
				return
			end

			--// If it does not change, don't proceed
			if not SharedFunctions.DoesChange(ChanceOfChange) then
				return
			end

			local ComplexInstanceTableRelationships: table = ComplexInstanceTable[ReferencePartName][ReferencePart]

			--// Parse through the relationships
			for Relationship, ClassNames in pairs (ComplexInstanceTableRelationships) do
				if Relationship == "LightsOn" then
					--// Saving space in case any other changes need to be added
				else
					for ClassName, Instances in pairs (ClassNames) do
						for InstanceName, SimpleTableOfInstances in pairs (Instances) do
							local TestInstance = ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName][InstanceName][1]

							if not TestInstance then
								return
							end

							local ChangeTable: table

							if ChangeTable == nil then --// Only does settings validation once
								ChangeTable = {}

								local InstanceSettings: table = ComponentSettings["ComplexInstances"][ReferencePartName][Relationship][ClassName][InstanceName]

								for SettingName, SettingValue in pairs (InstanceSettings) do --// Determines if settings are able to be used, etc. CHANGE SETTINGS HERE
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

							local RelationshipInstances: table = ComplexInstanceTable[ReferencePartName][ReferencePart][Relationship][ClassName][InstanceName]

							--// Set the properties
							for _, TargetInstance in pairs (RelationshipInstances) do
								for ApprovedSettingName, ApprovedSettingValue in pairs (ChangeTable) do
									TargetInstance[ApprovedSettingName] = ApprovedSettingValue
								end
							end

							--// Denotes whether the light is 'on' or 'off'
							ComplexInstanceTable[ReferencePartName][ReferencePart]["LightsOn"] = ComponentSettings["ComplexInstances"][ReferencePartName]["GeneralSettings"]["IsLightOn"]
						end
					end
				end
			end
		end
	end
end

--// This is used specifically to interface with CullingSystem
function module:SetCullingRangeFolder(RangeFolder: Folder)
	local CurrentComponentSettings = PackageHandling:GetCurrentComponent("Lighting")

	if not CurrentComponentSettings then --// It's possible CullingService instances will load before the lighting/audio package/component is fully loaded
		task.wait(1)

		module:SetCullingRangeFolder(RangeFolder) --// Essentially, yield this function until the component loads

		return
	end

	task.wait(0.25) --// Allow some time for descendants to load

	for _, CullingDescendant in pairs (RangeFolder:GetDescendants()) do
		local ClassName: string = CullingDescendant.ClassName
		local InstanceName: string = CullingDescendant.Name
		
		local InstanceType: string --// This will either be "Simple" or "Complex", depending if it is a normal instance or a simple one - if it remains nil, that means it is not in the component settings
	
		--// This is a simple instance
		if CurrentComponentSettings["Instances"] and CurrentComponentSettings["Instances"][ClassName] and CurrentComponentSettings["Instances"][ClassName][InstanceName] then
			InstanceType = "Simple"
		end
	
		--// This is a complex instances (as in, it is a reference part for a complex instance)
		if CurrentComponentSettings["ComplexInstances"] and CurrentComponentSettings["ComplexInstances"][InstanceName] then
			InstanceType = "Complex"
		end
	
		--// If it is neither, then do nothing
		if not InstanceType then
			continue
		end
	
		--// Note to self, InstanceTables provide two pieces of information (1. a pre-organized search of the workspace so that you don't have to repeat searches and 2. a way of seeing whether the lights are on).  All newly culled instances must be added (since something might be culled in for a while) but they also need to be removed once they are culled out, so just be mindful of that (otherwise memory leak)
	
		if InstanceType == "Simple" then --// Simple instance
			CheckInstanceTableExistenceForCullingSystem(CullingDescendant, ClassName, InstanceName)
		else --// Complex instance reference part
			CheckComplexInstanceTableExistenceForCullingSystem(CullingDescendant, CurrentComponentSettings)
		end
	
		SetForCullingSystem(CullingDescendant, InstanceType, CurrentComponentSettings)
	end
end

local function Set(ComponentSettings)
	local AdjustOnlyLightsOn

	if ComponentSettings["GeneralSettings"]["AdjustOnlyLightsOn"] ~= nil then
		AdjustOnlyLightsOn = ComponentSettings["GeneralSettings"]["AdjustOnlyLightsOn"]
	else
		AdjustOnlyLightsOn = false
	end

	for ClassName, ClassSettings in pairs (ComponentSettings) do --// Changing Lighting Service and Children (ChanceOfChange does not apply here)
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

	if ComponentSettings["Instances"] then		
		for ClassName, Instances in pairs (ComponentSettings["Instances"]) do --// In settings right now
			for InstanceName, SpecificSettings in pairs (Instances) do
				CheckInstanceTableExistence(InstanceName, ClassName)

				local ChangeTable
				local ChanceOfChange = 100 --// Default always changes

				for _Instance, UniqueProperties in pairs (InstanceTable[ClassName][InstanceName]) do --// Switch to the InstanceTable
					if (AdjustOnlyLightsOn == true and ComponentSettings["Instances"][ClassName][InstanceName]["IsLight"] == true and UniqueProperties["LightsOn"] == true) or AdjustOnlyLightsOn == false then
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

							InstanceTable[ClassName][InstanceName][_Instance]["LightsOn"] = ComponentSettings["Instances"][ClassName][InstanceName]["IsLightOn"]
						end
					end
				end
			end
		end
	end

	if ComponentSettings["ComplexInstances"] then
		local ListOfLights = {} --// Looks like: index = ReferencePartName; value = true/false, basically just tells whether this is treated as an instance affected by LightsOn or not

		for ReferencePartName, Relationships in pairs (ComponentSettings["ComplexInstances"]) do --// This is NOT parsing through the ComplexInstanceTable, this is parsing through the ComplexInstances table in the respective settings
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

		for ReferencePartName, _ in pairs (ComponentSettings["ComplexInstances"]) do
			local ChanceOfChange = 100 --// Defaults to 100  (i.e. always changes)

			if ComponentSettings["ComplexInstances"][ReferencePartName]["GeneralSettings"]["ChanceOfChange"] ~= nil then
				ChanceOfChange = ComponentSettings["ComplexInstances"][ReferencePartName]["GeneralSettings"]["ChanceOfChange"]
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

													for SettingName, SettingValue in pairs (ComponentSettings["ComplexInstances"][ReferencePartName][Relationship][ClassName][InstanceName]) do --// Determines if settings are able to be used, etc. CHANGE SETTINGS HERE
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

													ComplexInstanceTable[ReferencePartName][ReferencePart]["LightsOn"] = ComponentSettings["ComplexInstances"][ReferencePartName]["GeneralSettings"]["IsLightOn"]
												end
											end
										end
									end
								end
							end
						end
					else
						ComponentSettings["ComplexInstances"][ReferencePartName][ReferencePart] = nil --// Used for deleting reference parts that no longer exist
					end
				end
			end
		end
	end
end

local function Tween(ComponentSettings, Context: string)
	local TweenInformation

	if Context == "RegionChange" then
		TweenInformation = Settings["Tween Information"]["Region"]
	elseif Context == "Time" then
		TweenInformation = Settings["Tween Information"]["Time"]
	elseif Context == "Weather" then
		TweenInformation = Settings["Tween Information"]["Weather"]
	else
		warn("Unknown context", Context)
		return
	end

	local AdjustOnlyLightsOn

	if ComponentSettings["GeneralSettings"]["AdjustOnlyLightsOn"] then
		AdjustOnlyLightsOn = ComponentSettings["GeneralSettings"]["AdjustOnlyLightsOn"]
	else
		AdjustOnlyLightsOn = false
	end

	for ClassName, ClassSettings in pairs (ComponentSettings) do --// Changing Lighting Service and Children (ChanceOfChange does not apply here)
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

	if ComponentSettings["Instances"] then
		for ClassName, Instances in pairs (ComponentSettings["Instances"]) do
			for InstanceName, SpecificSettings in pairs (Instances) do
				CheckInstanceTableExistence(InstanceName, ClassName)

				local ChangeTable

				local ToSetOnComplete = {}

				local ChanceOfChange = 100 --// Default always changes

				for _Instance, UnqiueProperties in pairs (InstanceTable[ClassName][InstanceName]) do
					if (AdjustOnlyLightsOn == true and ComponentSettings["Instances"][ClassName][InstanceName]["IsLight"] == true and UnqiueProperties["LightsOn"] == true) or AdjustOnlyLightsOn == false then
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

	if ComponentSettings["ComplexInstances"] then
		local ListOfLights = {} --// Looks like: index = ReferencePartName; value = true/false, basically just tells whether this is treated as an instance affected by LightsOn or not 

		for ReferencePartName, Relationships in pairs (ComponentSettings["ComplexInstances"]) do --// This is NOT parsing through the ComplexInstanceTable, this is parsing through the ComplexInstances table in the respective settings
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

		for ReferencePartName, _ in pairs (ComponentSettings["ComplexInstances"]) do
			local ChanceOfChange = 100 --// Defaults to 100 (i.e. always changes)

			if ComponentSettings["ComplexInstances"][ReferencePartName]["GeneralSettings"]["ChanceOfChange"] ~= nil then
				ChanceOfChange = ComponentSettings["ComplexInstances"][ReferencePartName]["GeneralSettings"]["ChanceOfChange"]
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

													for SettingName, SettingValue in pairs (ComponentSettings["ComplexInstances"][ReferencePartName][Relationship][ClassName][InstanceName]) do --// Determines if settings are able to be used, etc.
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
																	ChangeInstance[ToSetOnComplete[e]] = ComponentSettings["ComplexInstances"][ReferencePartName][Relationship][ClassName][InstanceName][ToSetOnComplete[e]]
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
						ComponentSettings["ComplexInstances"][ReferencePartName][ReferencePart] = nil --// Used for deleting reference parts that no longer exist
					end
				end
			end
		end
	end
end

local function HandleMultiRegions() --// Handles the transition of when a player is in multiple lighting regions by setting their lighting to the most recently joined lighting region
	local TotalRegions = #InternalVariables["Current Regions"]["Lighting"]
	local CurrentRegion = PackageHandling:GetCurrentPackageName("Lighting", "Region")

	local MostRecentlyJoinedLightingRegion = InternalVariables["Current Regions"]["Lighting"][TotalRegions]

	--// Check to ensure we aren't setting the same package twice (ex: someone walks into three regions, but they exit the one they entered first while still remaining in the one they most recently joined)
	if MostRecentlyJoinedLightingRegion == CurrentRegion then
		return
	end

	local PackageNameForRegion = string.split(MostRecentlyJoinedLightingRegion, "-")[1]

	local ActiveWeather: boolean = WeatherHandling:CheckForActiveWeather("Lighting")
	local WeatherExemption: boolean = WeatherHandling:CheckForWeatherExemption("Lighting", "Region", PackageNameForRegion)

	--// If weather is active and there is not a weather exemption, reset back to the weather
	if ActiveWeather and not WeatherExemption then
		PackageHandling:SetCurrentScope("Lighting", "Weather")
		
		module:AdjustLighting("RegionChange")
	end

	--// Basically just treat it as entering a new region!
	module.RegionEnter(PackageNameForRegion)
end

function module.RegionEnter(RegionName)
	local CurrentScope: string = PackageHandling:GetCurrentScope("Lighting")
	local CurrentPackageName: string = PackageHandling:GetCurrentPackageName("Lighting", "Region")

	local ActiveWeather: boolean = WeatherHandling:CheckForActiveWeather("Lighting")
	local WeatherExemption: boolean = WeatherHandling:CheckForWeatherExemption("Lighting", "Region", RegionName)

	--// Applies weather exemption (based on the most recently joined region)
	InternalVariables["Weather Exemption"]["Lighting"] = WeatherExemption

	--// If weather is active and there is not a weather exemption
	if ActiveWeather and not WeatherExemption then
		return
	end

	--// Set the package (if it's a new region or if the current scope is not already region)
	if CurrentPackageName ~= RegionName or CurrentScope ~= "Region" then
		PackageHandling:SetPackage("Lighting", "Region", RegionName)
		PackageHandling:SetCurrentScope("Lighting", "Region")

		TimeHandling:ReadPackage("Lighting", "Region", RegionName, false)

		--// We will do our own initial component change here
		module:AdjustLighting("RegionChange")
	end
end

function module.RegionLeave()
	local ActiveWeather: boolean = WeatherHandling:CheckForActiveWeather("Lighting")
	local CurrentScope: string = PackageHandling:GetCurrentScope("Lighting")

	local WeatherIsActive = false

	if ActiveWeather and CurrentScope ~= "Weather" then
		WeatherIsActive = true
	end

	--// If we are in a multiple regions
	if #InternalVariables["Current Regions"]["Lighting"] >= 1 then
		HandleMultiRegions()

		return
	end

	--// If there is active weather, reset back to the weather
	if WeatherIsActive then
		PackageHandling:SetCurrentScope("Lighting", "Weather")
		
		module:AdjustLighting("RegionChange")
		return
	end

	--// Otherwise we are just resyncing to the server like normal
	PackageHandling:SetCurrentScope("Lighting", "Server")
	
	module:AdjustLighting("RegionChange")
end

--// Context is used to inform tween settings, options are: "RegionChange" (entering and exiting a region), "Time" (time-based change), and "Weather"
function module:TweenLighting(Context: string)
	local ComponentSettings = PackageHandling:GetCurrentComponent("Lighting")

	if not ComponentSettings then
		warn("No lighting component found")
		return
	end

	Tween(ComponentSettings, Context)
end

function module:SetLighting()
	local ComponentSettings = PackageHandling:GetCurrentComponent("Lighting")

	if not ComponentSettings then
		warn("No lighting component found")
		return
	end

	Set(ComponentSettings)
end

--// Handles the actually setting and tweening of the lighting.  Declare the component before this.  Context is optional
function module:AdjustLighting(Context: string)
	local Tween = Settings["Tween"]

	if Tween then
		module:TweenLighting(Context)
	else
		module:SetLighting()
	end
end

function module:Initialize()
	if InternalVariables["Initialized"]["Lighting"] == false then
		InternalVariables["Initialized"]["Lighting"] = true

		TimeHandling = require(Main.TimeHandling)
		WeatherHandling = require(Main.WeatherHandling)

		if RunService:IsServer() then
			--// When the player first joins the game (this will always set the lighting, not tween)
			InitialSyncToServer.OnServerEvent:Connect(function(Player)
				local NumberOfTries = 0

				while not InternalVariables["Initialized"]["Time"] do --// Sometimes (especialy in Studio) where the client is loading in really fast, it will load in before the CurrentLightingPeriod is set
					task.wait(.2)

					NumberOfTries = NumberOfTries + 1

					if NumberOfTries > InternalSettings["InitializationMaxTries"] then
						warn("Max Tries has been reached for Remote Initialization")
						return
					end
				end

				while not TimeHandling["Initial Read"]["Lighting"] do
					task.wait(.2)

					NumberOfTries = NumberOfTries + 1

					if NumberOfTries > InternalSettings["InitializationMaxTries"] then
						warn("Max Tries has been reached for waiting for initial read")
						return
					end
				end

				--// Initial sync to server
				local SyncTable = {}

				local CurrentScope = PackageHandling:GetCurrentScope("Lighting")

				local CurrentPackageName = PackageHandling:GetCurrentPackageName("Lighting", CurrentScope)
				local CurrentComponentName = PackageHandling:GetCurrentComponentName("Lighting", CurrentScope)

				SyncTable["PackageType"] = "Lighting"
				SyncTable["CurrentScope"] = CurrentScope
				SyncTable["CurrentPackage"] = CurrentPackageName
				SyncTable["CurrentComponent"] = CurrentComponentName

				if CurrentScope == "Weather" then
					local CurrentServerPackageName = PackageHandling:GetCurrentPackageName("Lighting", "Server")
					local CurrentServerComponentName = PackageHandling:GetCurrentComponentName("Lighting", "Server")

					SyncTable["CurrentServerPackage"] = CurrentServerPackageName
					SyncTable["CurrentServerComponent"] = CurrentServerComponentName
				end

				InitialSyncToServer:FireClient(Player, SyncTable)
			end)
		end
	end
end

return module
