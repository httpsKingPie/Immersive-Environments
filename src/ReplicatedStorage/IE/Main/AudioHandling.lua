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

local ActiveSounds

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
	if SoundService:FindFirstChild("ActiveSounds") == nil then
		ActiveSounds = Instance.new("Folder")
		ActiveSounds.Name = "ActiveSounds"
		ActiveSounds.Parent = SoundService
	end
	
	for i, v in pairs (ActiveSounds:GetChildren()) do --// Prevents sound glitching on respawn
		if v.Name == "RegionSound" then
			v:Destroy()
		end
	end
	
	if RunService:IsClient() then
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

--// Resume with these functions

local function HandleSound(SoundName, SoundSettings, RegionName)
	if not ActiveSounds:FindFirstChild(RegionName) then
		local NewFolder = Instance.new("Folder")
		NewFolder.Name = RegionName
		NewFolder.Parent = ActiveSounds
	end
	
	if not ActiveSounds[RegionName]:FindFirstChild(SoundName) then --// Prevents sound duplication (ex: respawning in the same region)
		local Sound = Instance.new("Sound")
		Sound.Name = SoundName
		Sound.SoundId = InternalSettings["AssetPrefix"] ..tostring(SoundSettings.SoundId)
		
		for SettingName, SettingValue in pairs (SoundSettings["Set"]) do
			if SharedFunctions.CheckProperty(Sound, SettingName) then
				--// Start here (just added the blacklisted sound properties, so just work on making them play etc. - might as well just handle tweens here
			end
		end
	end
end

local function TweenIn(InstanceToTween, InstanceSettings)
	local ChangeTable = {}
	local ToSetOnComplete = {}

	for SettingName, SettingValue in pairs (InstanceSettings) do
		if SharedFunctions.CheckProperty(InstanceToTween, SettingName) then
			if table.find(InternalSettings["AlwaysSet"], SettingName) then
				table.insert(ToSetOnComplete, SettingName)
			else
				ChangeTable[SettingName] = SettingValue
			end
		else
			warn(SettingName.. " is not a valid property of SoundService.  Check spelling")
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

local function TweenOut(InstanceToTween, InstanceSettings)

end


local function HandleNewSounds(NewSoundSettings, RegionName)
	for SoundName, SoundSettings in pairs (NewSoundSettings) do
		HandleSound(SoundName, SoundSettings, RegionName)
	end
end

local function HandleChangeSounds(ChangeSoundSettings, RegionName)

end

local function HandleRandomSounds(RandomSoundSettings, RegionName)
	
end

function module.RegionEnter(RegionName) --// Client sided function only (RegionType is either Audio or Lighting, RegionName equivalent to the Setting name)
	if not RegionSettingsCheck(RegionName) then
		return
	end
	
	local RegionSettings = SettingsTable["Region"][RegionName]
	
	for SettingCategory, SpecificSettings in pairs (RegionSettings) do
		if SettingCategory == "SoundService" then
			TweenIn(SoundService, SpecificSettings)
		elseif SettingCategory == "NewSounds" then
			HandleNewSounds(SpecificSettings, RegionName)
		elseif SettingCategory == "ChangeSounds" then
			HandleChangeSounds(SpecificSettings, RegionName)
		elseif SettingCategory == "RandomChanceSounds" then
			HandleRandomSounds(SpecificSettings, RegionName)
		end
	end 
end

function module.RegionLeave(RegionName) --// Client sided function only (RegionType is either Audio or Lighting, RegionName equivalent to the Setting name)
	if not RegionSettingsCheck(RegionName) then
		return
	end
	
	print("Left")
end

function module.Set(AudioName, RegionName) --// RegionName optional, just in case a manual audio change is wanted
	
end

function module.Tween(AudioName, RegionName) --// RegionName optional, just in case a manual audio change is wanted
	
end

return module
