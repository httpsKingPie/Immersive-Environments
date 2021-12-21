--// Note: This is completely client sided and requires the 'Client Sided' setting to be enabled!

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
local PackageHandling = require(Main.PackageHandling)
local RemoteHandling = require(Main.RemoteHandling)
local SharedFunctions = require(Main.SharedFunctions)

local IEFolder = Main.Parent

local ObjectTracker = require(IEFolder["OT&AM"])
local Settings = require(IEFolder.Settings)

local UniqueIdentifiersAssignedRemote: RemoteEvent = RemoteHandling:GetRemote("", "UniqueIdentifiersAssigned")

local ActivelyHandlingRegions: boolean = false --// Prevents HandleRegions from being called too fast on-top of itself
local Initialized: boolean = false

--[[
	Handles the region being entered

	Arguments: PackageType ("Audio" or "Lighting"), RegionName (name of the region)
]]

local function ReturnUniqueIdentifierComponents(UniqueIdentifier: string)
	local SplitUniqueIdentifier: table = string.split(UniqueIdentifier, "-")

	local RegionName: string = SplitUniqueIdentifier[1]
	local RegionInstanceName: string = SplitUniqueIdentifier[2]
	local RegionInstanceIndex: string = SplitUniqueIdentifier[3]

	return RegionName, RegionInstanceName, RegionInstanceIndex
end

local function HandleRegionEnter(PackageType: string, PackageName: string)
	local Package = PackageHandling:GetPackage(PackageType, "Region", PackageName)

	--// Warning already bundled in
	if not Package then
		return
	end

	if PackageType == "Audio" then
		AudioHandling.RegionEnter(PackageName)
	elseif PackageType == "Lighting" then
		LightingHandling.RegionEnter(PackageName)
	end
end

--[[
	Handles the region being left

	Arguments: PackageType ("Audio" or "Lighting"), RegionName (name of the region)
]]

local function HandleRegionLeave(PackageType: string, PackageName: string)
	if PackageType == "Audio" then
		AudioHandling.RegionLeave(PackageName)
	elseif PackageType == "Lighting" then
		LightingHandling.RegionLeave()
	end
end

--// Adds a region for internal tracking when a player enters it (returns true if this is successful)
local function AddRegion(PackageType: string, UniqueIdentifier: string)
	--// Check to make sure we aren't adding duplicate regions
	local RegionAlreadyBeingTracked = table.find(InternalVariables["Current Regions"][PackageType], UniqueIdentifier)

	--// Not a huge deal if this gets tripped, there's plenty of reasons why it might try to duplicate add a region
	if RegionAlreadyBeingTracked then
		return
	end

	table.insert(InternalVariables["Current Regions"][PackageType], UniqueIdentifier)

	return true
end

--// Removes a region for internal tracking when a player leaves it
local function RemoveRegion(PackageType: string, UniqueIdentifier: string)
	local IndexesToRemove = {} --// This is just a more thorough way of preventing any edge cases of duplicate entires, since it will always allow for the possibility of remove more than one indexes (although we expect it to only be one)

	--// Get the index of the region left so that we can sort the dictionary
	for Index, RegionIdentifier in ipairs (InternalVariables["Current Regions"][PackageType]) do
		if RegionIdentifier == UniqueIdentifier then
			table.insert(IndexesToRemove, Index)
		end
	end

	--// Check to see if an actual index is found, if one is not found this is fine because it also means that an region settings were applied to it.  More than likely this means someoene ran really quickly in and out of it.  If they already left before the ValidateRegions function had time to catch they were in there, it's probably fine
	if #IndexesToRemove == 0  then
		warn(UniqueIdentifier..  "was supposed to be removed, but was not found in CurrentRegions")
		return
	end

	--// Remove the indexes
	for _, IndexToRemove: number in ipairs (IndexesToRemove) do
		table.remove(InternalVariables["Current Regions"][PackageType], IndexToRemove)
	end
end

--// Clears the current regions
local function ClearRegions()
	InternalVariables["Current Regions"]["Audio"] = {}
	InternalVariables["Current Regions"]["Lighting"] = {}
end

--// Validates regions to make sure that players are actually in them
local function ValidateRegions(PackageType: string)
	while true do
		for SpecificPackageType, AllRegions in pairs (InternalVariables["Regions"]) do --// (PackageType = "Audio" or "Lighting")
			if PackageType == SpecificPackageType then
				for UniqueIdentifier: string, TrackedRegion in pairs (AllRegions) do
					--// Break up the region identifier into any relevant information
					local RegionName, RegionInstanceName, RegionInstanceIndex = ReturnUniqueIdentifierComponents(UniqueIdentifier)

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

					local BeingTrackedInRegion = table.find(InternalVariables["Current Regions"][PackageType], UniqueIdentifier)
					
					if ActuallyInRegion and not BeingTrackedInRegion then --// Means the LocalPlayer is actually in the zone, but RegionHandling doesn't think they are
						local SuccessfullyAddedRegion = AddRegion(PackageType, UniqueIdentifier)

						if SuccessfullyAddedRegion then
							HandleRegionEnter(PackageType, RegionName)
						end
					elseif not ActuallyInRegion and BeingTrackedInRegion then --// Means the LocalPlayer is not actually in the zone, but RegionHandling thinks they are
						RemoveRegion(PackageType, UniqueIdentifier)
						HandleRegionLeave(PackageType, RegionName)
					end
				end
			end
		end
		
		task.wait(InternalSettings["Region Backup Validation"])
	end
end

--// Do this by the server, right at the start, because there's going to be too much client weirdness if StreamingEnabled is run at the same time when 'Always Check Instances' is enabled
local function AssignUniqueIdentifiers(Children: table)
	for _, RegionFolder: Folder in pairs (Children) do
		local PackageName: string = RegionFolder.Name

		for Index, Region: Instance in pairs (RegionFolder:GetChildren()) do
			if Region:IsA("BasePart") then
				local RegionName = Region.Name

				local UniqueIdentifier = PackageName.. "-".. RegionName.. "-".. Index

				Region.Name = UniqueIdentifier
			end
		end
	end
end

local function CheckRegions(Looping)
	local function GetListOfUniqueIdentifiers(TableOfRegions: table)
		local NewTable = {}
		
		for UniqueIdentifier, TrackedRegion in pairs (TableOfRegions) do
			table.insert(NewTable, UniqueIdentifier)
		end
		
		return NewTable
	end

	local function ExcludeRegionsPlayerIsCurrentlyIn(Table: table, PackageType: string)
		local CurrentRegions = InternalVariables["Current Regions"][PackageType]

		for _, UniqueIdentifier in ipairs (CurrentRegions) do
			local IndexInTable = table.find(Table, UniqueIdentifier)

			if IndexInTable then
				table.remove(Table, IndexInTable)
			end
		end
		
		return Table
	end
	
	--[[
		Handles region generated and tracking

		Arguments: Descendants (descendants or AudioRegions or LightingRegions), PackageType is either "Audio" or "Lighting" (used for organization)
	]]

	local function HandleRegion(Children: table, PackageType: string)
		--// Prevents this from being called too many times sequentially
		while ActivelyHandlingRegions == true do
			warn("Throttling region handling - consider increasing InternalSettings>'Region Check Time'")
			task.wait(.1)
		end

		ActivelyHandlingRegions = true

		--// Removes regions the player is not in (typically if 'Always Check Instances' is on - prevents duplication glitches)
		local TableOfRegionsToRemove = GetListOfUniqueIdentifiers(InternalVariables["Regions"][PackageType])

		ExcludeRegionsPlayerIsCurrentlyIn(TableOfRegionsToRemove, PackageType)

		ObjectTracker.RemoveAreas(TableOfRegionsToRemove)

		for _, UniqueIdentifier in pairs (TableOfRegionsToRemove) do
			InternalVariables["Regions"][PackageType][UniqueIdentifier] = nil

			local RegionIndex = table.find(InternalVariables["Current Regions"][PackageType], UniqueIdentifier)

			if RegionIndex then
				table.remove(InternalVariables["Current Regions"][PackageType], RegionIndex)
			end
		end

		--// Create regions
		for _, RegionFolder: Folder in pairs (Children) do
			local PackageName: string = RegionFolder.Name

			for Index, Region: Instance in pairs (RegionFolder:GetChildren()) do
				if Region:IsA("BasePart") then
					local UniqueIdentifier = Region.Name

					local RegionAlreadyExists = table.find(InternalVariables["Current Regions"][PackageType], UniqueIdentifier)

					--// Verifies that they are currently in the region
					if not RegionAlreadyExists then
						local TrackedRegion = ObjectTracker.addArea(UniqueIdentifier, Region)
						
						InternalVariables["Regions"][PackageType][UniqueIdentifier] = TrackedRegion
						
						TrackedRegion.onEnter:Connect(function(Player)
							if Player ~= LocalPlayer then
								return
							end

							local SuccessfullyAddedRegion = AddRegion(PackageType, UniqueIdentifier)

							if SuccessfullyAddedRegion then
								HandleRegionEnter(PackageType, PackageName)
							end
						end)
						
						TrackedRegion.onLeave:Connect(function(Player)
							if Player ~= LocalPlayer then
								return
							end

							RemoveRegion(PackageType, UniqueIdentifier)
							HandleRegionLeave(PackageType, PackageName)
						end)
					end
				end
			end
		end

		ActivelyHandlingRegions = false
	end
	
	while true do
		local AudioChildren = AudioRegions:GetChildren()
		local LightingChildren = LightingRegions:GetChildren()
		
		HandleRegion(AudioChildren, "Audio")
		HandleRegion(LightingChildren, "Lighting")

		if Looping == true then
			task.wait(InternalSettings["Region Check Time"])
		else
			return
		end
	end
end

--// Region handling is always client sided (possible to have client sided regions with server sided other stuff - to support StreamingEnabled, custom loading systems, etc.)
function module.Initialize()
	if not RunService:IsClient() then
		local AudioChildren = AudioRegions:GetChildren()
		local LightingChildren = LightingRegions:GetChildren()

		AssignUniqueIdentifiers(AudioChildren)
		AssignUniqueIdentifiers(LightingChildren)
		
		InternalVariables["Initialized"]["Regions"] = true

		--// Fire this to the client when they ask for it
		UniqueIdentifiersAssignedRemote.OnServerEvent:Connect(function(Player: Player)
			UniqueIdentifiersAssignedRemote:FireClient(Player, InternalVariables["Initialized"]["Regions"])
		end)

		--// Fire this to any clients that join early
		UniqueIdentifiersAssignedRemote:FireAllClients(InternalVariables["Initialized"]["Regions"])

		return
	end

	if Initialized then
		return
	end

	Initialized = true

	if not Settings["Client Sided"] then
		return
	end

	local UniqueIdentifiersAssigned: boolean = false

	--// This should always be a positive
	UniqueIdentifiersAssignedRemote.OnClientEvent:Connect(function(StatusOfUniqueIdentifiers)
		UniqueIdentifiersAssigned = StatusOfUniqueIdentifiers
	end)

	UniqueIdentifiersAssignedRemote:FireServer()

	if not UniqueIdentifiersAssigned then
		UniqueIdentifiersAssignedRemote.OnClientEvent:Wait()
	end

	LocalPlayer = Players.LocalPlayer
	
	CheckRegions()

	coroutine.wrap(ValidateRegions)("Audio")

	coroutine.wrap(ValidateRegions)("Lighting")
	
	if Settings["Always Check Instances"] then
		coroutine.wrap(CheckRegions)(true)
	end

	SharedFunctions.CharacterAdded(LocalPlayer, ClearRegions)
end

return module
