--// Note: This is completely client sided!

--[[
	Covert current region into some sort of table (since you could be in multiple regions at once (ex: in a forest and then you get in the region near a river and low river sounds are playing)
		Need to figure out how to add and remove regions
		Add a folder into ActiveSounds for each region you enter and put the sounds there for easy management
	Make sure that server sounds still occur even when regions are active (ex: a church bell dinging each hour)
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
local LightingHandling = require(Main.LightingHandling)

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

	for i = 1, #InternalSettings["CurrentRegions"] do
		String = String.. InternalSettings["CurrentRegions"][i].. ", "
	end

	if String == "Current Regions are: " then
		print(String.. "none")
	else
		print(string.sub(String, 0, string.len(String) - 2)) --// Removes the last commma and space just for cleanness :-)
	end
end

local function ValidateRegions() --// Validates regions to make sure that players are actually in them
	while true do	
		for RegionType, AllRegions in pairs (InternalSettings["Regions"]) do --// (RegionType = "Audio" or "Lighting")
			for RegionName, TrackedRegion in pairs (AllRegions) do
				local Objects = TrackedRegion:getObjects()
				
				if table.find(Objects, LocalPlayer) and not table.find(InternalSettings["CurrentRegions"], RegionName) then --// Means the LocalPlayer is actually in the zone, but RegionHandling doesn't think they are
					table.insert(InternalSettings["CurrentRegions"], RegionName)
					print("Validation: adding ".. RegionName)
					PrintRegions()
					HandleRegionEnter(RegionType, RegionName)
				elseif not table.find(Objects, LocalPlayer) and table.find(InternalSettings["CurrentRegions"], RegionName) then --// Means the LocalPlayer is not actually in the zone, but RegionHandling thinks they are
					table.remove(InternalSettings["CurrentRegions"], table.find(InternalSettings["CurrentRegions"], RegionName))
					print("Validation: removing ".. RegionName)
					PrintRegions()
					HandleRegionLeave(RegionType, RegionName)
				end
			end
		end
		
		wait(Settings["BackupValidation"])
	end
end

local function DetectRegionChange(RegionName, Event) --// Used to determine region changes in case onEnter or onLeave fire in the wrong order
	local function DuplicateRegion(RegionName)
		if table.find(InternalSettings["CurrentRegions"], RegionName) then
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
			table.insert(InternalSettings["CurrentRegions"], RegionName) --// String

			DetectingRegionChange = false

			return true
		end
	end
	
	local function LeftRegion(RegionName)
		table.remove(InternalSettings["CurrentRegions"], table.find(InternalSettings["CurrentRegions"], RegionName))

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
end


local function CheckRegions(Looping)
	local function HandleRegion(Descendants, RegionType) --// RegionName is either Audio or Lighting (used for organization)
		for i = 1, #Descendants do
			local RegionName = Descendants[i].Name
			local TrackedRegion = ObjectTracker.addArea(RegionName, Descendants[i])
			
			InternalSettings["Regions"][RegionType] = {}
			
			InternalSettings["Regions"][RegionType][RegionName] = TrackedRegion
			
			TrackedRegion.onEnter:Connect(function(Player)
				if Player ~= LocalPlayer then
					return
				end
				
				EnteredRegionTime = os.time()
				
				if DetectRegionChange(RegionName, "onEnter") == true then --// When it returns false that means it tried to add the same region twice
					HandleRegionEnter(RegionType, RegionName)
				end
			end)
			
			TrackedRegion.onLeave:Connect(function(Player)
				if Player ~= LocalPlayer then
					return
				end
				
				LeftRegionTime = os.time()
				
				if DetectRegionChange(RegionName, "onLeave") == true then
					HandleRegionLeave(RegionType, RegionName)
				end
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
	end
end

return module
