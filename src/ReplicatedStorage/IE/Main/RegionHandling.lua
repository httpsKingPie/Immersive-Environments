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
local InternalSettings = require(Main.InternalSettings)
local InternalVariables = require(Main.InternalVariables)
local LightingHandling = require(Main.LightingHandling)
local SharedFunctions = require(Main.SharedFunctions)

local IEFolder = Main.Parent

local ObjectTracker = require(IEFolder["OT&AM"])
local Settings = require(IEFolder.Settings)

local LeftRegionTime = 0 --// Replaced by os.time() value
local EnteredRegionTime = 0 --// Replaced by os.time() value

local DetectingRegionChange = false

--// Misc

local function HandleRegionEnter(RegionType, RegionName)
	if RegionType == "Audio" then
		AudioHandling.RegionEnter(RegionName)
	end
end

local function HandleRegionLeave(RegionType, RegionName)
	if RegionType == "Audio" then
		AudioHandling.RegionLeave(RegionName)
	end
end

local function PrintRegions()
	local String = "Current Regions are: "

	for _, RegionName in ipairs (InternalVariables["CurrentRegions"]) do
		String = String.. RegionName.. ", "
	end

	if String == "Current Regions are: " then
		print(String.. "none")
	else
		print(string.sub(String, 0, string.len(String) - 2)) --// Removes the last commma and space just for cleanness :-)
	end
end

local function AddRegion(RegionName: string)
	local NewIndex = 0

	for Index, _ in ipairs (InternalVariables["CurrentRegions"]) do
		NewIndex = Index
	end

	NewIndex = NewIndex + 1

	InternalVariables["CurrentRegions"][NewIndex] = RegionName
	table.insert(InternalVariables["CurrentRegionsQuick"], RegionName)
	PrintRegions()
end

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

	PrintRegions()
end

local function ClearRegions()
	InternalVariables["CurrentRegions"] = {}
	InternalVariables["CurrentRegionsQuick"] = {}
end

local function ValidateRegions() --// Validates regions to make sure that players are actually in them
	while true do
		local ReversedCurrentRegions = {}

		for Index, _RegionName in ipairs (InternalVariables["CurrentRegions"]) do
			ReversedCurrentRegions[_RegionName] = Index
		end

		for RegionType, AllRegions in pairs (InternalVariables["Regions"]) do --// (RegionType = "Audio" or "Lighting")
			for RegionName, TrackedRegion in pairs (AllRegions) do
				local Objects = TrackedRegion:getObjects()

				local SimpleObjectTable = {}

				local ActuallyInRegion

				for Index, ObjectDetails in ipairs (Objects) do
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
					print("Character was not recorded as being in ".. RegionName .. " but is actually supposed to be there.  Adding.")
					--table.insert(InternalVariables["CurrentRegions"], RegionName)
					AddRegion(RegionName)
					HandleRegionEnter(RegionType, RegionName)
				elseif not ActuallyInRegion and RecordedInRegion then --// Means the LocalPlayer is not actually in the zone, but RegionHandling thinks they are
					print("Character was recorded as being in ".. RegionName.. " but is not actually supposed to be in there.  Removing.")
					--table.remove(InternalVariables["CurrentRegions"], table.find(InternalVariables["CurrentRegions"], RegionName))
					RemoveRegion(RegionName)
					HandleRegionLeave(RegionType, RegionName)
				end
			end
		end
		
		wait(Settings["BackupValidation"])
	end
end

--[[local function DetectRegionChange(RegionName, Event) --// Used to determine region changes in case onEnter or onLeave fire in the wrong order
	local function DuplicateRegion(RegionName)
		if table.find(InternalVariables["CurrentRegions"], RegionName) then
			return true
		else
			return false
		end
	end
	
	local function EnteredRegion(RegionName)
		if DuplicateRegion(RegionName) then
			DetectingRegionChange = false
			
			return false
		else
			--table.insert(InternalVariables["CurrentRegions"], RegionName) --// String
			AddRegion(RegionName)

			DetectingRegionChange = false

			return true
		end
	end
	
	local function LeftRegion(RegionName)
		--table.remove(InternalVariables["CurrentRegions"], table.find(InternalVariables["CurrentRegions"], RegionName))
		RemoveRegion(RegionName)

		DetectingRegionChange = false

		return true
	end
	
	--
	
	if DetectingRegionChange == true then
		return
	end
	
	DetectingRegionChange = true
	
	wait(Settings["EventBuffer"])
	
	if math.abs(EnteredRegionTime - LeftRegionTime) > Settings["EventDifference"] then --// If the difference between times is sufficiently large, then it's probably correct and doesn't need validation.  Validation is only needed for times that are very similar and could have been the result of events firing in the incorrect order
		if Event == "onEnter" then
			return(EnteredRegion(RegionName))
		elseif Event == "onLeave" then
			return(LeftRegion(RegionName))
		else
			warn("Unexpected input")
		end
	end
	
	if math.abs((EnteredRegionTime - LeftRegionTime)) < Settings["EventBuffer"] or (EnteredRegionTime ~= 0 and LeftRegionTime == 0) then --// Flaw with how this is handled is that it is biased towards assuming that quick changes between events are actually the result of entering a new zone.  This bias is only created because it's usually safer to assume that more lighting and audio settings should be added rather than risk not adding them and ruining player experience
		return(EnteredRegion(RegionName))
	else
		return(LeftRegion(RegionName))
	end
end]]


local function CheckRegions(Looping)
	local function HandleRegion(Descendants, RegionType) --// RegionName is either Audio or Lighting (used for organization)

		InternalSettings["Regions"][RegionType] = {}

		for i = 1, #Descendants do
			local RegionName = Descendants[i].Name
			local TrackedRegion = ObjectTracker.addArea(RegionName, Descendants[i])
			
			InternalSettings["Regions"][RegionType][RegionName] = TrackedRegion
			
			TrackedRegion.onEnter:Connect(function(Player)
				if Player ~= LocalPlayer then
					return
				end
				
				AddRegion(RegionName)
				HandleRegionEnter(RegionType, RegionName)

				--EnteredRegionTime = os.time()
				
				--if DetectRegionChange(RegionName, "onEnter") == true then --// When it returns false that means it tried to add the same region twice
					--HandleRegionEnter(RegionType, RegionName)
				--end
			end)
			
			TrackedRegion.onLeave:Connect(function(Player)
				if Player ~= LocalPlayer then
					return
				end
				
				RemoveRegion(RegionName)
				HandleRegionLeave(RegionType, RegionName)

				--LeftRegionTime = os.time()

				--if DetectRegionChange(RegionName, "onLeave") == true then
					--HandleRegionLeave(RegionType, RegionName)
				--end
			end)
		end
	end
	
	while true do
		InternalSettings["Regions"] = {} --// Clears the previous table

		local AudioDescendants = AudioRegions:GetDescendants()
		local LightingDescendants = LightingRegions:GetDescendants()
		
		HandleRegion(AudioDescendants, "Audio")
		HandleRegion(LightingDescendants, "Lighting")

		if Looping ~= nil and Looping == true then
			wait(Settings["RegionCheckTime"])
		else
			return
		end
	end
end

function module.Run()
	if Settings["ClientSided"] == true and RunService:IsClient() == true then
		LocalPlayer = Players.LocalPlayer
		
		CheckRegions()
		coroutine.wrap(ValidateRegions)()
		
		if Settings["AlwaysCheckInstances"] == true then
			coroutine.wrap(CheckRegions)(true)
		end

		SharedFunctions.CharacterAdded(LocalPlayer, ClearRegions)
	end
end

return module
