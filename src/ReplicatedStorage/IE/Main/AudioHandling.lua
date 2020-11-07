local module = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local LocalPlayer --// Filled in if this is run on the client

local Main = script.Parent
local IEFolder = Main.Parent

local InternalSettings = require(Main.InternalSettings)
local InternalVariables = require(Main.InternalVariables)
local SettingsHandling = require(Main.SettingsHandling)
local SharedFunctions = require(Main.SharedFunctions)

local Settings = require(IEFolder.Settings)
local ObjectTracker = require(IEFolder["OT&AM"])

--// SoundService

local ActiveRegionSounds
local ActiveServerSounds
local SharedSounds

--// Functions

function module.Run()
	if not SoundService:FindFirstChild("ActiveServerSounds") and RunService:IsServer() then --// We only want/need this created on the server
		ActiveServerSounds = Instance.new("Folder")
		ActiveServerSounds.Name = "ActiveServerSounds"
		ActiveServerSounds.Parent = SoundService
	end

	if RunService:IsClient() then
		if not SoundService:FindFirstChild("ActiveRegionSounds") then
			ActiveRegionSounds = Instance.new("Folder")
			ActiveRegionSounds.Name = "ActiveRegionSounds"
			ActiveRegionSounds.Parent = SoundService
		end
		
		if not SoundService:FindFirstChild("SharedSounds") then
			SharedSounds = Instance.new("Folder")
			SharedSounds.Name = "SharedSounds"
			SharedSounds.Parent = SoundService
		end

		LocalPlayer = Players.LocalPlayer
	end
end

local function GetRegionSoundFolder(RegionName: string)
	local RegionSoundFolder = ActiveRegionSounds:FindFirstChild(RegionName)

	if not RegionSoundFolder then
		RegionSoundFolder = Instance.new("Folder")
		RegionSoundFolder.Name = RegionName
		RegionSoundFolder.Parent = ActiveRegionSounds
	end

	return RegionSoundFolder
end

local function Set(InstanceToSet: any, InstanceSettings: table, ClassName: string) --// RegionName optional, just in case a manual audio change is wanted
	for SettingName, SettingValue in pairs (InstanceSettings) do
		if SharedFunctions.CheckProperty(InstanceToSet, SettingName) then --// Property exists
			if not table.find(InternalSettings["BlacklistedSettings"], SettingName) and (not InternalSettings["BlacklistedSettingsClass"][ClassName] or not table.find(InternalSettings["BlacklistedSettingsClass"][ClassName], SettingName)) then --// Property isn't blacklisted either blanketly or by class (if class is provided)
				InstanceToSet[SettingName] = SettingValue
			else
				warn(SettingName.. " unable to be modified")
			end
		else
			warn(SettingName.. " is not a valid property.  Check spelling")
		end
	end
end

local function Tween(InstanceToTween: any, InstanceSettings: table, ClassName: string) --// This is Tween rather than TweenSound, TweenIn, etc. because it also makes changes to the SoundService and is really just used to change any property
	local ChangeTable = {}
	local ToSetOnComplete = {}

	for SettingName, SettingValue in pairs (InstanceSettings) do
		if SharedFunctions.CheckProperty(InstanceToTween, SettingName) then --// Property exists
			if not table.find(InternalSettings["BlacklistedSettings"], SettingName) and (not InternalSettings["BlacklistedSettingsClass"][ClassName] or not table.find(InternalSettings["BlacklistedSettingsClass"][ClassName], SettingName)) then --// Property isn't blacklisted either blanketly or by class (if class is provided)
				if table.find(InternalSettings["AlwaysSet"], SettingName) then --// Check to see if property is marked as always one that is set
					table.insert(ToSetOnComplete, SettingName)
				else
					ChangeTable[SettingName] = SettingValue
				end
			else
				warn(SettingName.. " unable to be modified")
			end
		else
			warn(SettingName.. " is not a valid property.  Check spelling")
		end
	end

	local ChangeTween = TweenService:Create(InstanceToTween, Settings["AudioTweenInformation"], ChangeTable)
	ChangeTween:Play()

	ChangeTween.Completed:Connect(function()
		ChangeTween:Destroy()

		local NumberOfIndexes = #ToSetOnComplete

		if NumberOfIndexes ~= 0 then
			for i = 1, NumberOfIndexes do
				InstanceToTween[ToSetOnComplete[i]] = InstanceSettings[ToSetOnComplete[i]]
			end
		end
	end)
end

local function TweenOut(InstanceToTween: any)
	if InstanceToTween:IsA("Sound") then
		local ChangeTween = TweenService:Create(InstanceToTween, Settings["AudioTweenInformation"], {Volume = 0})
		ChangeTween:Play()

		ChangeTween.Completed:Connect(function()
			ChangeTween:Destroy()
			InstanceToTween:Destroy()
		end)
	end
end

local function TweenOutRegionSounds(RegionName)
	local RegionSoundFolder = GetRegionSoundFolder(RegionName)

	for _, Sound in pairs (RegionSoundFolder:GetChildren()) do
		TweenOut(Sound)
	end
end

local function AdjustSharedSounds() --// Determines whether a SharedSound is still being used, whether it needs to change, etc.
	local SoundMaxIndexTable = {} --// Format is [SoundInstance] = IndexNumber
	--// This is used so that the shared sound goes to the region that the player had entered most recently (index number represents this, reference further above in script)
	
	local CurrentSharedSounds = SharedSounds:GetChildren()

	for Index, RegionName in ipairs (InternalVariables["CurrentRegions"]) do
		local RegionSettings = SettingsHandling:GetRegionSettings(RegionName, "Audio")

		if RegionSettings then
			local RegionSharedSounds = RegionSettings["SharedSounds"]
			
			if RegionSharedSounds then
				for i = 1, #CurrentSharedSounds do
					if RegionSharedSounds[CurrentSharedSounds[i].Name] then
						SoundMaxIndexTable[CurrentSharedSounds[i]] = Index
						table.remove(CurrentSharedSounds, i)
					end
				end
			end
		end
	end

	for Sound, Index in pairs (SoundMaxIndexTable) do
		local RegionName = InternalVariables["CurrentRegions"][Index]

		local RegionSettings = SettingsHandling:GetRegionSettings(RegionName, "Audio")

		local SoundSettings = RegionSettings["SharedSounds"][Sound.Name]["Tween"]

		Tween(Sound, SoundSettings, "Sound")
	end

	for i = 1, #CurrentSharedSounds do
		TweenOut(CurrentSharedSounds[i])
	end
end

local function HandleSound(SoundName: string, SoundSettings, SoundFolder: Folder, TweenOverride: boolean) --// TweenOverride is used for SharedSounds
	local Sound = SoundFolder:FindFirstChild(SoundName)

	local CreatedSound = false
	
	if not Sound then --// Prevents sound duplication (ex: respawning in the same region)
		Sound = Instance.new("Sound")
		Sound.Name = SoundName
		Sound.SoundId = InternalSettings["AssetPrefix"] ..tostring(SoundSettings.SoundId)
		Sound.Looped = true
		Sound.Parent = SoundFolder

		CreatedSound = true
	end

	if CreatedSound or TweenOverride then
		Set(Sound, SoundSettings["Set"], "Sound")
		Tween(Sound, SoundSettings["Tween"], "Sound")

		if CreatedSound then
			Sound:Play()
		end
	end
end

local function GenerateRegionSounds(RegionSoundSettings, RegionName)
	local RegionSoundFolder = GetRegionSoundFolder(RegionName)

	for SoundName, SoundSettings in pairs (RegionSoundSettings) do
		HandleSound(SoundName, SoundSettings, RegionSoundFolder)
	end
end

local function HandleSharedSounds(SharedSoundSettings)
	for SoundName, SoundSettings in pairs (SharedSoundSettings) do
		HandleSound(SoundName, SoundSettings, SharedSounds, true)
	end
end

local function HandleRandomSound(SoundName: string, SoundSettings, SoundFolder: Folder)
	local RegionName = SoundFolder.Name

	local Sound = SoundFolder:FindFirstChild(SoundName)
	
	if not Sound then --// Prevents sound duplication (ex: respawning in the same region)
		--// Not these sounds are not looped by default
		Sound = Instance.new("Sound")
		Sound.Name = SoundName
		Sound.SoundId = InternalSettings["AssetPrefix"] ..tostring(SoundSettings.SoundId)

		if Settings["GenerateNewRandomSounds"] == false then
			Sound.Parent = SoundFolder
		end
	end

	Set(Sound, SoundSettings["Set"], "Sound")

	while true do
		wait(SoundSettings["Frequency"])

		if SharedFunctions.DoesChange(SoundSettings["ChanceOfPlay"]) then
			if table.find(InternalVariables["CurrentRegionsQuick"], RegionName) and Sound then --// Validates that the player is still in the region and that the Sound instance still exists
				if Settings["GenerateNewRandomSounds"] == true then
					local SoundClone = Sound:Clone()
					SoundClone.Parent = SoundFolder
					SoundClone:Play()

					if Settings["WaitForRandomSoundToEnd"] == true then --// Generating new sounds + must wait for each sound to finish
						SoundClone.Ended:Wait()
						SoundClone:Destroy()
					else --// Generating new sounds + do not have to wait for each sound to finish
						SoundClone.Ended:Connect(function()
							SoundClone:Destroy()
						end)
					end
				else 
					Sound:Play() --// Just using one sound instance

					if Settings["WaitForRandomSoundToEnd"] == true then --// Just using one sound instance + must wait for the sound to finish
						Sound.Ended:Wait()
					end
				end
			else
				if Settings["GenerateNewRandomSounds"] == true then
					Sound:Destroy() --// Otherwise this instance will just be floating in memory
				end

				return
			end
		end
	end
end

local function GenerateRandomSounds(RandomSoundSettings, RegionName) --// These are really a subset of RegionSounds
	local RegionSoundFolder = GetRegionSoundFolder(RegionName)

	for SoundName, SoundSettings in pairs (RandomSoundSettings) do
		coroutine.wrap(HandleRandomSound)(SoundName, SoundSettings, RegionSoundFolder)
	end
end

function module.RegionEnter(RegionName) --// Client sided function only (RegionType is either Audio or Lighting, RegionName equivalent to the Setting name)
	local RegionSettings = SettingsHandling:GetRegionSettings(RegionName, "Audio")

	if not RegionSettings then
		return
	end
	
	for SettingCategory, SpecificSettings in pairs (RegionSettings) do
		if SettingCategory == "SoundService" then
			Tween(SoundService, SpecificSettings, "SoundService")
		elseif SettingCategory == "RegionSounds" then
			GenerateRegionSounds(SpecificSettings, RegionName)
		elseif SettingCategory == "SharedSounds" then
			HandleSharedSounds(SpecificSettings)
		elseif SettingCategory == "RandomSounds" then
			GenerateRandomSounds(SpecificSettings, RegionName)
		end
	end 
end

function module.RegionLeave(RegionName) --// Client sided function only (RegionType is either Audio or Lighting, RegionName equivalent to the Setting name)
	local RegionSettings = SettingsHandling:GetRegionSettings(RegionName, "Audio")

	if not RegionSettings then
		return
	end

	TweenOutRegionSounds(RegionName)
	AdjustSharedSounds()

	local RegionFolder = ActiveRegionSounds:FindFirstChild(RegionName)

	if RegionFolder then --// Destroys the folder
		local Waiting = false

		RegionFolder.ChildRemoved:Connect(function()
			if Waiting == false then
				Waiting = true

				wait(.25) --// Waiting for all of the Sounds to be deleted

				if #RegionFolder:GetChildren() == 0 then
					RegionFolder:Destroy()
				end

				Waiting = false
			end
		end)
	end
end

return module
