--// Note: This is completely client sided!

--[[
	Covert current region into some sort of table (since you could be in multiple regions at once (ex: in a forest and then you get in the region near a river and low river sounds are playing)
		Need to figure out how to add and remove regions
		Add a folder into ActiveSounds for each region you enter and put the sounds there for easy management
	Make sure that server sounds still occur even when regions are active (ex: a church bell dinging each hour)

	Regions stored in InternalSettings are stored like {
		[1] = "RegionFirstEntered",
		[2] = "RegionSecondEntered",
		[3] = "RegionThirdEntered",
		etc.
	}

	with the actual region name replacing the "RegionFirstEntered"

	Regions with a higher number (ex: 8) mean that this is the most recent region that the player entered.  Regions with a lower number (ex: 1) mean that was the least recent region the player entered.
]]

local module = {}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer --// Filled in if this is run on the client

local IERegions = Workspace:WaitForChild("IERegions")

local AudioRegions = IERegions:WaitForChild("AudioRegions")
local LightingRegions = IERegions:WaitForChild("LightingRegions")

local Main = script.Parent

local AudioHandling = require(Main.AudioHandling)
local IEMain = require(Main)
local InternalSettings = require(Main.InternalSettings)
local InternalVariables = require(Main.InternalVariables)
local LightingHandling = require(Main.LightingHandling)
local PackageHandling = require(Main.PackageHandling)
local SharedFunctions = require(Main.SharedFunctions)
local TimeHandling = require(Main.TimeHandling)

local IEFolder = Main.Parent

local ObjectTracker = require(IEFolder["OT&AM"])
local Settings = require(IEFolder.Settings)

local Initialized = false

local function SetRegionPackage(PackageType: string, PackageName: string)
	if not Initialized then
		warn("Initialize IE before setting packages")
		return
	end

	PackageHandling:SetServerPackage(PackageType, PackageName)
	TimeHandling:ReadPackage(PackageType, "Region", PackageName)
end

--[[
	Handles the region being entered

	Arguments: PackageType ("Audio" or "Lighting"), RegionName (name of the region)
]]

local function HandleRegionEnter(PackageType: string, RegionName: string)
	local Package = PackageHandling:GetPackage(PackageType, "Region", RegionName)

	--// Warning already bundled in
	if not Package then
		return
	end

	SetRegionPackage(PackageType, RegionName)

	if PackageType == "Audio" then
		AudioHandling.RegionEnter(RegionName)
	elseif PackageType == "Lighting" then
		LightingHandling.RegionEnter(RegionName)
	end

	InternalVariables["Current"..PackageType.."Regions"] = InternalVariables["Current"..PackageType.."Regions"] + 1
end

--[[
	Handles the region being left

	Arguments: PackageType ("Audio" or "Lighting"), RegionName (name of the region)
]]

local function HandleRegionLeave(PackageType: string, RegionName: string)
	if PackageType == "Audio" then
		if InternalVariables["CurrentAudioRegions"] > 0 then
			InternalVariables["CurrentAudioRegions"] = InternalVariables["CurrentAudioRegions"] - 1
		end

		AudioHandling.RegionLeave(RegionName)
	elseif PackageType == "Lighting" then
		if InternalVariables["CurrentLightingRegions"] > 0 then
			InternalVariables["CurrentLightingRegions"] = InternalVariables["CurrentLightingRegions"] - 1
		end

		LightingHandling.RegionLeave(RegionName)
	end
end

--// Adds a region for internal tracking when a player enters it
local function AddRegion(RegionName: string)
	local NewIndex = 0

	for Index, _ in ipairs (InternalVariables["CurrentRegions"]) do
		NewIndex = Index
	end

	NewIndex = NewIndex + 1

	InternalVariables["CurrentRegions"][NewIndex] = RegionName
	table.insert(InternalVariables["CurrentRegionsQuick"], RegionName)
end

--// Removes a region for internal tracking when a player leaves it
local function RemoveRegion(RegionName: string)
	local RegionLeftIndex
	local MaxIndex = 1

	--// Get the index of the region left so that we can sort the dictionary
	for Index, _RegionName in ipairs (InternalVariables["CurrentRegions"]) do
		if _RegionName == RegionName then
			RegionLeftIndex = Index
		end

		if Index > MaxIndex then
			MaxIndex = Index
		end
	end

	--// Check to see if an actual index is found, if one is not found this is fine because it also means that an region settings were applied to it.  More than likely this means someoene ran really quickly in and out of it.  If they already left before the ValidateRegions function had time to catch they were in there, it's probably fine
	if not RegionLeftIndex then
		warn(RegionName..  "was supposed to be removed, but was not found in CurrentRegions")
		return
	end

	for Index, _RegionName in ipairs (InternalVariables["CurrentRegions"]) do
		if Index > RegionLeftIndex then --// If it's an index lower than the number that was left, then it does not need resorting.
			InternalVariables["CurrentRegions"][Index - 1] = _RegionName
		end
	end

	InternalVariables["CurrentRegions"][MaxIndex] = nil
	table.remove(InternalVariables["CurrentRegionsQuick"], table.find(InternalVariables["CurrentRegionsQuick"], RegionName))
end

--// Clears the current regions
local function ClearRegions()
	InternalVariables["CurrentRegions"] = {}
	InternalVariables["CurrentRegionsQuick"] = {}
end

--// Validates regions to make sure that players are actually in them
local function ValidateRegions()
	while true do
		local ReversedCurrentRegions = {}

		for Index, _RegionName in ipairs (InternalVariables["CurrentRegions"]) do
			ReversedCurrentRegions[_RegionName] = Index
		end

		for RegionType, AllRegions in pairs (InternalVariables["Regions"]) do --// (RegionType = "Audio" or "Lighting")
			for RegionName, TrackedRegion in pairs (AllRegions) do
				local Objects = TrackedRegion:getObjects()

				local ActuallyInRegion

				for _, ObjectDetails in ipairs (Objects) do
					local ObjectInRegion = ObjectDetails["Object"]

					if ObjectInRegion then
						if ObjectInRegion.Parent and ObjectInRegion.Parent:FindFirstChildWhichIsA("Humanoid") and Players:GetPlayerFromCharacter(ObjectInRegion.Parent) then
							ActuallyInRegion = true
							break
						end
					end
				end

				local RecordedInRegion = ReversedCurrentRegions[RegionName] --// will be nil if no, and something if true
				
				if ActuallyInRegion and not RecordedInRegion then --// Means the LocalPlayer is actually in the zone, but RegionHandling doesn't think they are
					AddRegion(RegionName)
					HandleRegionEnter(RegionType, RegionName)
				elseif not ActuallyInRegion and RecordedInRegion then --// Means the LocalPlayer is not actually in the zone, but RegionHandling thinks they are
					RemoveRegion(RegionName)
					HandleRegionLeave(RegionType, RegionName)
				end
			end
		end
		
		task.wait(Settings["BackupValidation"])
	end
end

local function CheckRegions(Looping)
	local function BuildTableOfIndexes(TableToModify: table)
		local NewTable = {}
		
		for Index, _ in pairs (TableToModify) do
			table.insert(NewTable, Index)
		end
		
		return NewTable
	end
	
	--[[
		Handles region generated and tracking

		Arguments: Descendants (descendants or AudioRegions or LightingRegions), PackageType is either "Audio" or "Lighting" (used for organization)
	]]

	local function HandleRegion(Descendants: table, PackageType: string)
		if not InternalVariables["Regions"][PackageType] then
			InternalVariables["Regions"][PackageType] = {}
		else
			ObjectTracker.RemoveAreas(BuildTableOfIndexes(InternalVariables["Regions"][PackageType]))
			InternalVariables["Regions"][PackageType] = {}
		end

		local CreatedRegions = {}

		for i = 1, #Descendants do
			local RegionName = Descendants[i].Name
			
			local RegionAlreadyExists = table.find(CreatedRegions, RegionName)
			
			if not RegionAlreadyExists then
				
				local TrackedRegion = ObjectTracker.addArea(RegionName, Descendants[i])
				
				InternalVariables["Regions"][PackageType][RegionName] = TrackedRegion
				
				TrackedRegion.onEnter:Connect(function(Player)
					if Player ~= LocalPlayer then
						return
					end
					
					AddRegion(RegionName)
					HandleRegionEnter(PackageType, RegionName)
				end)
				
				TrackedRegion.onLeave:Connect(function(Player)
					if Player ~= LocalPlayer then
						return
					end
					
					RemoveRegion(RegionName)
					HandleRegionLeave(PackageType, RegionName)
				end)
			else
				warn("Cannot have the regions with the same name and type.  Name: ".. RegionName.. "; PackageType: ".. PackageType)
			end
		end
	end
	
	while true do
		local AudioDescendants = AudioRegions:GetDescendants()
		local LightingDescendants = LightingRegions:GetDescendants()
		
		HandleRegion(AudioDescendants, "Audio")
		HandleRegion(LightingDescendants, "Lighting")

		if Looping ~= nil and Looping == true then
			task.wait(Settings["RegionCheckTime"])
		else
			return
		end
	end
end

--// Region handling is always client sided (possible to have client sided regions with server sided other stuff - to support StreamingEnabled, custom loading systems, etc.)
function module.Initialize()
	if not RunService:IsClient() then
		return
	end

	if Initialized then
		return
	end

	Initialized = true

	LocalPlayer = Players.LocalPlayer
	
	CheckRegions()
	coroutine.wrap(ValidateRegions)()
	
	if Settings["AlwaysCheckInstances"] == true then
		coroutine.wrap(CheckRegions)(true)
	end

	SharedFunctions.CharacterAdded(LocalPlayer, ClearRegions)
end

return module
