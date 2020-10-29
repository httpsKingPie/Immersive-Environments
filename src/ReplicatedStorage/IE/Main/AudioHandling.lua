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

	if not SoundService:FindFirstChild("ActiveRegionSounds") and RunService:IsClient() then --// We only want/need this create on the client
		ActiveRegionSounds = Instance.new("Folder")
		ActiveRegionSounds.Name = "ActiveRegionSounds"
		ActiveRegionSounds.Parent = SoundService
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

local function TweenIn(InstanceToTween: any, InstanceSettings: table, ClassName: string) --// This is TweenIn rather than TweenSound because it also makes changes to the SoundService
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

local function TweenOut(InstanceToTween, InstanceSettings) --// This will TweenOut

end

--// Resume with these functions

local function HandleSound(Type: string, SoundName, SoundSettings, RegionName)
	if Type == "Region" then
		local SoundRegionFolder = ActiveRegionSounds:FindFirstChild(RegionName)

		if not SoundRegionFolder then
			SoundRegionFolder = Instance.new("Folder")
			SoundRegionFolder.Name = RegionName
			SoundRegionFolder.Parent = ActiveRegionSounds
		end

		local Sound = SoundRegionFolder:FindFirstChild(SoundName)
		
		if not Sound then --// Prevents sound duplication (ex: respawning in the same region)
			Sound = Instance.new("Sound")
			Sound.Name = SoundName
			Sound.SoundId = InternalSettings["AssetPrefix"] ..tostring(SoundSettings.SoundId)
			Sound.Parent = SoundRegionFolder
			
			TweenIn(Sound, SoundSettings["Tween"], "Sound")
			
			Sound:Play()
		end
	end
end

local function HandleNewSounds(NewSoundSettings, RegionName)
	for SoundName, SoundSettings in pairs (NewSoundSettings) do
		HandleSound("Region", SoundName, SoundSettings, RegionName)
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
			TweenIn(SoundService, SpecificSettings, "SoundService")
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
