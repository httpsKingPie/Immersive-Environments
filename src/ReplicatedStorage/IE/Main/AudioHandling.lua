local module = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local LocalPlayer --// Filled in if this is run on the client

local Main = script.Parent
local IEFolder = Main.Parent

local RemoteFolder = IEFolder:WaitForChild("RemoteFolder")

local AudioRemote = RemoteFolder:WaitForChild("AudioRemote")

local InternalSettings = require(Main.InternalSettings)
local InternalVariables = require(Main.InternalVariables)
local SettingsHandling = require(Main.SettingsHandling)
local SharedFunctions = require(Main.SharedFunctions)

local Settings = require(IEFolder.Settings)

--// SoundService

local ActiveRegionSounds --// Created on the client (ony visible to client)
local ActiveServerSounds --// Created on the server.  However, when client sided - individually clients just put their server sounds in there for easy organization
local SharedSounds --// Created on the client (ony visible to client)

--// Functions

function module.Run() --// Initial run, basically just creating folders
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

		ActiveServerSounds = SoundService:WaitForChild("ActiveServerSounds")

		LocalPlayer = Players.LocalPlayer
	end
end

--// Region controls
local function GetTweenInformation(Event: string)
	local TweenInformation

	if Event == "ToRegion" or Event == "ToServer" then
		TweenInformation = Settings["AudioRegionTweenInformation"] --// Region based change
	elseif Event == "TimeChange" then
		TweenInformation = Settings["TimeEffectTweenInformation"] --// Time based change
	elseif Event == "Weather" then
		TweenInformation = Settings["WeatherTweenInformation"] --// Weather based change
	end

	return TweenInformation
end

local function GetRegionSoundFolder(RegionName: string) --// Gets the sound folder for a RegionName and if one does not exist it creates one
	local RegionSoundFolder = ActiveRegionSounds:FindFirstChild(RegionName)

	if not RegionSoundFolder then
		RegionSoundFolder = Instance.new("Folder")
		RegionSoundFolder.Name = RegionName
		RegionSoundFolder.Parent = ActiveRegionSounds
	end

	local function Disposal()
		wait(1)

		if #RegionSoundFolder:GetChildren() == 0 then
			RegionSoundFolder:Destroy()
		end
	end

	coroutine.wrap(Disposal) --// Used to dispose of folders created in case of regions that are never used.  This is a trashy method, but it saves this GetRegionSoundFolder from being called on repeat in multiple loops

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

local function Tween(InstanceToTween: any, InstanceSettings: table, ClassName: string, Event: string) --// This is Tween rather than TweenSound, TweenIn, etc. because it also makes changes to the SoundService and is really just used to change any property
	local TweenInformation = GetTweenInformation(Event)

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

	local ChangeTween = TweenService:Create(InstanceToTween, TweenInformation, ChangeTable)
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

local function TweenOut(InstanceToTween: Sound, Event: string) --// Tweens out a single sound
	local TweenInformation = GetTweenInformation(Event)

	local ChangeTween = TweenService:Create(InstanceToTween, TweenInformation, {Volume = 0})
	ChangeTween:Play()

	ChangeTween.Completed:Connect(function()
		ChangeTween:Destroy()
		InstanceToTween:Destroy()
	end)
end

local function TweenOutRegionSounds(RegionName) --// Tweens out the sounds of this region
	local RegionSoundFolder = GetRegionSoundFolder(RegionName)

	for _, Sound in pairs (RegionSoundFolder:GetChildren()) do
		TweenOut(Sound, "ToRegion")
	end
end

local function TweenOutServerSounds(Event)
	for _, Sound in pairs (ActiveServerSounds:GetChildren()) do
		TweenOut(Sound, Event)
	end
end

local function AdjustSharedSounds() --// Determines whether a SharedSound is still being used, whether it needs to change, etc.
	local SoundMaxIndexTable = {} --// Format is [SoundInstance] = IndexNumber
	--// This is used so that the shared sound goes to the region that the player had entered most recently (index number represents this, reference further above in script)
	
	local CurrentSharedSounds = SharedSounds:GetChildren() --// This is a table of the CurrentSharedSounds, but this is eventually transformed into a table of sounds that need to be removed.  Sounds that are still active (i.e. within a region that uses that SharedSound) are removed from this table

	for Index, RegionName in ipairs (InternalVariables["CurrentRegions"]) do --// Looks at all the CurrentRegions (in order of join)
		local RegionSettings = SettingsHandling:GetRegionSettings(RegionName, "Audio")

		if RegionSettings then --// If RegionSettings exist (some won't because they will be Lighting settings)
			local RegionSharedSounds = RegionSettings["SharedSounds"] --// Looks at the SharedSounds for the region
			
			if RegionSharedSounds then --// If SharedSounds exist
				for i = 1, #CurrentSharedSounds do --// Parse through all the CurrentSharedSounds
					if RegionSharedSounds[CurrentSharedSounds[i].Name] then --// If any of the CurrentSharedSounds match one of the SharedSounds in the Region that is being left
						SoundMaxIndexTable[CurrentSharedSounds[i]] = Index --// Indicates the highest index that SharedSound was in (because ipairs)
						table.remove(CurrentSharedSounds, i) --// Removes it from the table, i.e. the sound is still active
					end
				end
			end
		end
	end

	for Sound, Index in pairs (SoundMaxIndexTable) do --// Parses through the SoundMaxIndexTable
		local RegionName = InternalVariables["CurrentRegions"][Index]

		local RegionSettings = SettingsHandling:GetRegionSettings(RegionName, "Audio")

		local SoundSettings = RegionSettings["SharedSounds"][Sound.Name]["Tween"] --// Tweens it to the Settings with the highest index (i.e. the region joined most recently)

		Tween(Sound, SoundSettings, "Sound", "ToRegion")
	end

	for i = 1, #CurrentSharedSounds do
		TweenOut(CurrentSharedSounds[i], "ToRegion")
	end
end

local function CheckForSound(SoundName: string, SoundFolder: Folder, SoundSettings: table) --// Checks to see if the sound exists, if it does it returns it.  If not, it creates it
	local Sound = SoundFolder:FindFirstChild(SoundName)

	local CreatedSound = false

	if not Sound then
		Sound = Instance.new("Sound")
		Sound.Name = SoundName
		Sound.SoundId = InternalSettings["AssetPrefix"] ..tostring(SoundSettings.SoundId)
		Sound.Looped = true
		Sound.Parent = SoundFolder

		CreatedSound = true
	end

	return Sound, CreatedSound
end

local function HandleSound(SoundName: string, SoundSettings: table, SoundFolder: Folder, Event: string, TweenOverride: boolean) --// TweenOverride is used for SharedSounds, it basically means that regardless of whether the sound exists, it is going to be changed (aka tweened)
	local Sound, CreatedSound = CheckForSound(SoundName, SoundFolder, SoundSettings)

	if CreatedSound or TweenOverride then
		Set(Sound, SoundSettings["Set"], "Sound")
		Tween(Sound, SoundSettings["Tween"], "Sound", Event)

		if CreatedSound then
			Sound:Play()
		end
	end
end

local function GenerateServerSounds(ServerSoundSettings: table, Event: string)
	local ActiveSounds = {} --// Used to filter out server sounds that are not currently playing anymore

	for SoundName, SoundSettings in pairs (ServerSoundSettings) do
		HandleSound(SoundName, SoundSettings, ActiveServerSounds, Event)
		table.insert(ActiveSounds, SoundName)
	end

	local ActiveServerSoundsChildren = ActiveServerSounds:GetChildren()

	for i = 1, #ActiveServerSoundsChildren do
		local ServerSound = ActiveServerSoundsChildren[i]

		if not table.find(ActiveSounds, ServerSound.Name) then
			TweenOut(ServerSound, Event)
		end
	end
end

local function GenerateRegionSounds(RegionSoundSettings: table, RegionSoundFolder: Folder) --// Generates sounds for the region
	for SoundName, SoundSettings in pairs (RegionSoundSettings) do
		HandleSound(SoundName, SoundSettings, RegionSoundFolder, "ToRegion")
	end
end

local function HandleSharedSounds(SharedSoundSettings: table) --// Handles shared sounds for the region's shared sounds (i.e. just adjusting them)
	for SoundName, SoundSettings in pairs (SharedSoundSettings) do
		HandleSound(SoundName, SoundSettings, SharedSounds, "ToRegion", true)
	end
end

local function HandleRandomSound(SoundName: string, SoundSettings: table, SoundFolder: Folder) --// Actual function that handles sounds.  If it doesn't exist, it's created.  If it does exists, it's a shared sound and the properties are adjusted
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

local function GenerateRandomSounds(RandomSoundSettings: table, RegionSoundFolder: Folder) --// These are really a subset of RegionSounds
	for SoundName, SoundSettings in pairs (RandomSoundSettings) do
		coroutine.wrap(HandleRandomSound)(SoundName, SoundSettings, RegionSoundFolder)
	end
end

local function HandleAudioSettings(AudioSettings: table, Event: string, RegionName: string) --// RegionName is optional and only needs to be sent when required.  Stuff like ServerSounds, SharedSounds, and SoundService changes don't require the RegionName, only the settings.
	local RegionSoundFolder

	if RegionName then
		RegionSoundFolder = GetRegionSoundFolder(RegionName)
	end
	
	for SettingCategory, SpecificSettings in pairs (AudioSettings) do
		if SettingCategory == "SoundService" then
			Tween(SoundService, SpecificSettings, "SoundService", Event)
		elseif SettingCategory == "RegionSounds" then
			GenerateRegionSounds(SpecificSettings, RegionSoundFolder)
		elseif SettingCategory == "SharedSounds" then
			HandleSharedSounds(SpecificSettings)
		elseif SettingCategory == "RandomSounds" then
			GenerateRandomSounds(SpecificSettings, RegionSoundFolder)
		elseif SettingCategory == "ServerSounds" then
			GenerateServerSounds(SpecificSettings, Event) --// Weather is the only time where this bool will be false
		end
	end
end

function module.RegionEnter(RegionName: string) --// Client sided function only (RegionType is either Audio or Lighting, RegionName equivalent to the Setting name)
	local RegionSettings = SettingsHandling:GetRegionSettings(RegionName, "Audio")

	if not RegionSettings then --// If there are no settings
		return
	end

	if InternalVariables["AudioWeather"] and not RegionSettings["WeatherExemption"] then --// If weather is active and the region does not have a weather exemption
		return
	end

	InternalVariables["HaltAudioCycle"] = true

	module.TweenAudio("ToRegion", RegionName)
	TweenOutServerSounds("ToRegion")
end

function module.RegionLeave(RegionName: string) --// Client sided function only (RegionName equivalent to the Setting name)
	local RegionSettings = SettingsHandling:GetRegionSettings(RegionName, "Audio")

	if not RegionSettings then
		return
	end

	TweenOutRegionSounds(RegionName)
	AdjustSharedSounds()

	local RegionFolder = ActiveRegionSounds:FindFirstChild(RegionName)

	if RegionFolder then --// Destroys the folder
		--local Waiting = false

		RegionFolder.ChildRemoved:Connect(function()
			--[[if Waiting == false then
				Waiting = true

				wait(.25) --// Waiting for all of the Sounds to be deleted

				if #RegionFolder:GetChildren() == 0 then
					RegionFolder:Destroy()
				end

				Waiting = false
			end]]

			if #RegionFolder:GetChildren() == 0 then
				RegionFolder:Destroy()
			end
		end)
	end

	if InternalVariables["CurrentAudioRegions"]  <= 0 then
		InternalVariables["HaltAudioCycle"] = false

		module.TweenAudio("ToServer")
	end
end

--// Server controls

function module.TweenWeather(WeatherName: string)
	SettingsHandling.WaitForSettings("Audio")

	local NewWeatherSettings = SettingsHandling:GetWeatherSettings("Audio", WeatherName)

	if NewWeatherSettings then
		InternalVariables["AudioWeather"] = true
		InternalVariables["CurrentAudioWeather"] = WeatherName

		if Settings["ClientSided"] == false or RunService:IsClient() then
			HandleAudioSettings(NewWeatherSettings, "Weather")
		else
			if RunService:IsServer() then
				AudioRemote:FireAllClients("Weather", WeatherName)
			end
		end
	end
end

function module.TweenAudio(Event: string, AudioName: string)
	local NewAudioSettings

	if Event == "ToRegion" then
		NewAudioSettings = SettingsHandling:GetRegionSettings(AudioName, "Audio")
	elseif Event == "TimeChange" then
		NewAudioSettings = SettingsHandling:GetServerSettings(AudioName, "Audio")
	elseif Event == "ToServer" then
		if not RunService:IsClient() then
			warn("Improperly tried to sync from server while on the server")
			return
		end

		if not AudioName then --// If no lighting name is provided, that means it needs to sync and get that name
			AudioRemote:FireServer("TweenToServer") --// This gets called on the client, so we basically do the same thing that we do when the player joins the game - talk to the server, which knows the current audio period, and sync to it
		else --// If a lighting name is provided, that means we've already synced and can make the set now
			NewAudioSettings = SettingsHandling:GetServerSettings(AudioName, "Lighting")

			HandleAudioSettings(NewAudioSettings, Event)
		end
		
		return

	elseif Event == "Weather" then
		module.TweenWeather(AudioName)
		return
	end

	if not NewAudioSettings then
		warn("No audio settings found")
		return
	end

	if Settings["ClientSided"] == false or RunService:IsClient() then
		if Event == "ToRegion" then
			HandleAudioSettings(NewAudioSettings, Event, AudioName) --// Makes changes for region sounds
		elseif Event == "TimeChange" and InternalVariables["AudioWeather"] == false then
			HandleAudioSettings(NewAudioSettings, Event) --// Does time changes if there is not interrupting weather
		end
	else
		if RunService:IsServer() then
			AudioRemote:FireAllClients(Event, AudioName)
		end
	end
end

if InternalVariables["InitializedAudio"] == false then
	InternalVariables["InitializedAudio"] = true

	if RunService:IsServer() then
		AudioRemote.OnServerEvent:Connect(function(Player, Status)
			if Status == "SyncToServer" then
				local NumberOfTries = 0

				while InternalVariables["TimeInitialized"] == false do --// Sometimes (especialy in Studio) where the client is loading in really fast, it will load in before the CurrentLightingPeriod is set
					wait(.2)
					NumberOfTries = NumberOfTries + 1

					if NumberOfTries > InternalSettings["RemoteInitializationMaxTries"] then
						warn("Max Tries has been reached for Remote Initialization")
						return
					end
				end

				if InternalVariables["AudioWeather"] then
					AudioRemote:FireClient(Player, "TimeChange", InternalVariables["CurrentAudioPeriod"], InternalVariables["CurrentAudioWeather"])
				else
					AudioRemote:FireClient(Player, "TimeChange", InternalVariables["CurrentAudioPeriod"])
				end
			elseif Status == "TweenToServer" then
				if InternalVariables["AudioWeather"] then
					AudioRemote:FireClient(Player, "ToServer", InternalVariables["CurrentAudioPeriod"], InternalVariables["CurrentAudioWeather"])
				else
					AudioRemote:FireClient(Player, "ToServer", InternalVariables["CurrentAudioPeriod"])
				end
			end
		end)
	end
end

return module
