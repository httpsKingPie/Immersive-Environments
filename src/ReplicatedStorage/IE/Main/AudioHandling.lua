local module = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer --// Filled in if this is run on the client

local Main = script.Parent
local IEFolder = Main.Parent

local InternalSettings = require(Main.InternalSettings)
local SharedFunctions = require(Main.SharedFunctions)

local Settings = require(IEFolder.Settings)
local ObjectTracker = require(IEFolder["OT&AM"])

--// SoundService

local ActiveRegionSounds
local ActiveServerSounds
local SharedSounds

--// Workspace

local IERegions = Workspace:WaitForChild("IERegions")

local AudioRegions = IERegions:WaitForChild("AudioRegions")

--// IE

local AudioSettings = IEFolder.AudioSettings

--// Misc

local CurrentRegionName
local SettingsTable = {}

local TweenInformation = Settings["AudioTweenInformation"]

--// Functions

local function BuildSettingsTables()
	SettingsTable["Region"] = {}
	SettingsTable["Server"] = {}

	local RegionDescendants = AudioSettings.RegionSettings:GetDescendants()
	local ServerDescendants = AudioSettings.ServerSettings:GetDescendants()

	for i = 1, #RegionDescendants do
		if RegionDescendants[i]:IsA("ModuleScript") then
			if SettingsTable["Region"][RegionDescendants[i].Name] == nil then
				SettingsTable["Region"][RegionDescendants[i].Name] = require(RegionDescendants[i])
			else
				warn("Audio Setting already exists for ".. RegionDescendants[i].Name.. ".  Make sure settings with the same name do not exist")
			end
		end
	end

	for i = 1, #ServerDescendants do
		if ServerDescendants[i]:IsA("ModuleScript") then
			if SettingsTable["Region"][ServerDescendants[i].Name] == nil then
				SettingsTable["Region"][ServerDescendants[i].Name] = require(ServerDescendants[i])
			else
				warn("Audio Setting already exists for ".. ServerDescendants[i].Name.. ".  Make sure settings with the same name do not exist")
			end
		end
	end
end

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
	
	BuildSettingsTables()
end

local function RegionSettingsCheck(RegionName)
	if SettingsTable["Region"][RegionName] then
		return true
	else
		warn(tostring(RegionName).. " not found within SettingsTable")
		return false
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

local function GetRegionSoundFolder(RegionName: string)
	local RegionSoundFolder = ActiveRegionSounds:FindFirstChild(RegionName)

	if not RegionSoundFolder then
		RegionSoundFolder = Instance.new("Folder")
		RegionSoundFolder.Name = RegionName
		RegionSoundFolder.Parent = ActiveRegionSounds
	end

	return RegionSoundFolder
end

local function TweenOutRegionSounds(RegionName)
	local RegionSoundFolder = GetRegionSoundFolder(RegionName)

	for _, Sound in pairs (RegionSoundFolder:GetChildren()) do
		TweenOut(Sound)
	end
end

local function TweenOutSharedSounds()
	local CurrentSharedSounds = SharedSounds:GetChildren()

	for Index, RegionName in ipairs (InternalSettings["CurrentRegions"]) do
		if SettingsTable[RegionName] then
			break
		end

		local RegionSharedSounds = SettingsTable[RegionName]["SharedSounds"]

		for i = 1, #CurrentSharedSounds do
			if RegionSharedSounds[CurrentSharedSounds[i]] then
				table.remove(CurrentSharedSounds, i)
			end
		end
	end

	for i = 1, #CurrentSharedSounds do
		TweenOut(CurrentSharedSounds[i])
	end
end

--// Resume with these functions

local function HandleSound(SoundName: string, SoundSettings, SoundFolder: Folder, TweenOverride: boolean) --// TweenOverride is used for SharedSounds
	local Sound = SoundFolder:FindFirstChild(SoundName)

	local CreatedSound = false
	
	if not Sound then --// Prevents sound duplication (ex: respawning in the same region)
		Sound = Instance.new("Sound")
		Sound.Name = SoundName
		Sound.SoundId = InternalSettings["AssetPrefix"] ..tostring(SoundSettings.SoundId)
		Sound.Parent = SoundFolder

		CreatedSound = true
	end

	if CreatedSound or TweenOverride then
		Tween(Sound, SoundSettings["Tween"], "Sound")

		Sound:Play()

		print("Playing sound" .. SoundName)
	end
end

local function GenerateRegionSounds(NewSoundSettings, RegionName)
	print("Generating region sounds")

	local RegionSoundFolder = GetRegionSoundFolder(RegionName)

	for SoundName, SoundSettings in pairs (NewSoundSettings) do
		HandleSound(SoundName, SoundSettings, RegionSoundFolder)
	end
end

local function HandleSharedSounds(SharedSoundSettings, RegionName)
	print("Generating shared sounds")

	for SoundName, SoundSettings in pairs (SharedSoundSettings) do
		HandleSound(SoundName, SoundSettings, SharedSounds, true)
	end
end

local function GenerateRandomSounds(RandomSoundSettings, RegionName) --// These are really a subset of RegionSounds
	print("Generating random sounds")

	local RegionSoundFolder = GetRegionSoundFolder(RegionName)
end

function module.RegionEnter(RegionName) --// Client sided function only (RegionType is either Audio or Lighting, RegionName equivalent to the Setting name)
	if not RegionSettingsCheck(RegionName) then
		return
	end
	
	local RegionSettings = SettingsTable["Region"][RegionName]
	
	for SettingCategory, SpecificSettings in pairs (RegionSettings) do
		if SettingCategory == "SoundService" then
			Tween(SoundService, SpecificSettings, "SoundService")
		elseif SettingCategory == "RegionSounds" then
			GenerateRegionSounds(SpecificSettings, RegionName)
		elseif SettingCategory == "SharedSounds" then
			HandleSharedSounds(SpecificSettings, RegionName)
		elseif SettingCategory == "RandomChanceSounds" then
			GenerateRandomSounds(SpecificSettings, RegionName)
		end
	end 
end

function module.RegionLeave(RegionName) --// Client sided function only (RegionType is either Audio or Lighting, RegionName equivalent to the Setting name)
	if not RegionSettingsCheck(RegionName) then
		return
	end
	
	local RegionSettings = SettingsTable["Region"][RegionName]

	for SettingCategory, SpecificSettings in pairs (RegionSettings) do
		if SettingCategory == "SoundService" then
			
		elseif SettingCategory == "SharedSounds" then

		end
	end

	TweenOutRegionSounds(RegionName)
	TweenOutSharedSounds()
end

function module.Set(AudioName, RegionName) --// RegionName optional, just in case a manual audio change is wanted
	
end

function module.Tween(AudioName, RegionName) --// RegionName optional, just in case a manual audio change is wanted
	
end

return module
