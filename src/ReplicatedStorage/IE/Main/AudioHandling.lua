local module = {}

local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Main = script.Parent
local IEFolder = Main.Parent

--local RemoteFolder = IEFolder:WaitForChild("RemoteFolder")

--local AudioRemote = RemoteFolder:WaitForChild("AudioRemote")

local Settings = require(IEFolder.Settings)

local InternalSettings = require(Main.InternalSettings)
local InternalVariables = require(Main.InternalVariables)
local PackageHandling = require(Main.PackageHandling)
local RemoteHandling = require(Main.RemoteHandling)
local SettingsHandling = require(Main.SettingsHandling)
local SharedFunctions = require(Main.SharedFunctions)

--// Filled in after
local TimeHandling
local WeatherHandling

local InitialSyncToServer: RemoteEvent = RemoteHandling:GetRemote("Audio", "InitialSyncToServer")

--// SoundService

local ActiveRegionSounds --// Created on the client (ony visible to client)
local ActiveServerSounds --// Created on the server.  However, when client sided - individually clients just put their server sounds in there for easy organization
local SharedSounds --// Created on the client (ony visible to client)

--// Initialize
function module:Initialize() --// Initial run, basically just creating folders
	if InternalVariables["Initialized"]["Audio"] == false then
		InternalVariables["Initialized"]["Audio"] = true

		TimeHandling = require(Main.TimeHandling)
		WeatherHandling = require(Main.WeatherHandling)

		if RunService:IsServer() then
			if not SoundService:FindFirstChild("ActiveServerSounds") then --// We only want/need this created on the server
				ActiveServerSounds = Instance.new("Folder")
				ActiveServerSounds.Name = "ActiveServerSounds"
				ActiveServerSounds.Parent = SoundService
			end

			InitialSyncToServer.OnServerEvent:Connect(function(Player)
				local NumberOfTries = 0

				while not InternalVariables["Initialized"]["Time"] do --// Sometimes (especialy in Studio) where the client is loading in really fast, it will load in before the CurrentLightingPeriod is set
					task.wait(.2)

					NumberOfTries = NumberOfTries + 1

					if NumberOfTries > InternalSettings["RemoteInitializationMaxTries"] then
						warn("Max Tries has been reached for Remote Initialization")
						return
					end
				end

				--// Initial sync to server
				local CurrentScope = PackageHandling:GetCurrentScope("Audio")

				local CurrentPackageName = PackageHandling:GetCurrentPackageName("Audio", "Server")
				local CurrentComponentName = PackageHandling:GetCurrentComponentName("Audio")

				InitialSyncToServer:FireClient(Player, CurrentScope, CurrentPackageName, CurrentComponentName)
			end)
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
		end
	end
end

local function GetTweenInformation(Context: string)
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

	return TweenInformation
end

--// Gets the sound folder for a RegionName and if one does not exist it creates one
local function GetRegionSoundFolder(RegionName: string)
	local RegionSoundFolder = ActiveRegionSounds:FindFirstChild(RegionName)

	if not RegionSoundFolder then
		RegionSoundFolder = Instance.new("Folder")
		RegionSoundFolder.Name = RegionName
		RegionSoundFolder.Parent = ActiveRegionSounds
	end

	local function Disposal()
		task.wait(1)

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

local function Tween(InstanceToTween: any, InstanceSettings: table, ClassName: string, Context: string) --// This is Tween rather than TweenSound, TweenIn, etc. because it also makes changes to the SoundService and is really just used to change any property
	local TweenInformation = GetTweenInformation(Context)

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

local function TweenOut(InstanceToTween: Sound, Context: string) --// Tweens out a single sound
	local TweenInformation = GetTweenInformation(Context)

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
		TweenOut(Sound, "RegionChange")
	end
end

local function TweenOutServerSounds(Context: string)
	for _, Sound in pairs (ActiveServerSounds:GetChildren()) do
		TweenOut(Sound, Context)
	end
end

--// Determines whether a SharedSound is still being used, whether it needs to change, etc. (only occurs when leaving a region)
local function AdjustSharedSounds() 
	--[[
		Format is [SoundInstance] = IndexNumber

		This is used so that the shared sound goes to the region that the player had entered most recently (index number represents this, reference further above in script)
	]]

	local SoundMaxIndexTable = {}
	
	--// This is a table of the CurrentSharedSounds, but this is eventually transformed into a table of sounds that need to be removed.  Sounds that are still active (i.e. within a region that uses that SharedSound) are removed from this table
	local CurrentSharedSounds = SharedSounds:GetChildren()

	for Index, RegionName in ipairs (InternalVariables["Current Regions"]["Audio"]) do --// Looks at all the CurrentAudioRegions (in order of join)
		local PackageForRegion = PackageHandling:GetPackage("Audio", "Region", RegionName)
		local TheoreticallyCurrentComponentSettings = TimeHandling:ReturnTheoreticallyCurrentComponentForPackage(PackageForRegion)

		if TheoreticallyCurrentComponentSettings then --// If RegionSettings exist (some won't because they will be Lighting settings)
			local ComponentSharedSounds = TheoreticallyCurrentComponentSettings["SharedSounds"] --// Looks at the SharedSounds for the region
			
			if ComponentSharedSounds then --// If SharedSounds exist
				for SharedSoundIndex, SharedSound in ipairs (CurrentSharedSounds) do
					local SharedSoundName = SharedSound.Name
					local SharedSoundStillActive = SharedSounds:FindFirstChild(SharedSoundName)

					if SharedSoundStillActive then --// If any of the CurrentSharedSounds match one of the SharedSounds in the Region that is being left
						SoundMaxIndexTable[SharedSound] = Index --// Indicates the highest index that SharedSound was in (within the regions, if the sound has multiple indexes (i.e. regions) the index inserted here will be the highest one because of iteration sequence (ipairs)
						table.remove(CurrentSharedSounds, SharedSoundIndex) --// Removes it from the table, i.e. the sound is still active
					end
				end
			end
		end
	end

	--// This parses through the SoundMaxIndexTable
	for Sound, Index in pairs (SoundMaxIndexTable) do --// Parses through the SoundMaxIndexTable
		local RegionName = InternalVariables["Current Regions"]["Audio"][Index]

		local RegionPackage = PackageHandling:GetPackage("Audio", "Region", RegionName)
		local ComponentSettings = TimeHandling:ReturnTheoreticallyCurrentComponentForPackage(RegionPackage)

		local SoundSettings = ComponentSettings["SharedSounds"][Sound.Name]["Tween"] --// Tweens it to the Settings with the highest index (i.e. the region joined most recently)

		Tween(Sound, SoundSettings, "Sound", "RegionChange")
	end

	--// Tweens out shared sounds that are not being used (reminder: the CurrentSharedSounds table contains all shared sounds, but once shared sounds are confirmed that they still exist in the new region, they are removed)
	for _, Sound in ipairs(CurrentSharedSounds) do
		TweenOut(Sound, "RegionChange")
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

--// Handles property changes for sounds.  TweenOverride is used for SharedSounds, it basically means that regardless of whether the sound exists, it is going to be changed (aka tweened)
local function HandleSound(SoundName: string, SoundSettings: table, SoundFolder: Folder, Context: string, TweenOverride: boolean) 
	local Sound, CreatedSound = CheckForSound(SoundName, SoundFolder, SoundSettings)

	--// This allows for a smooth tween from silence to sound, essentially checking whether the sound is being added for the first time and whether the volume is expected to be tweened to a certain value
	if CreatedSound and SoundSettings["Tween"]["Volume"] then
		Sound.Volume = 0
	end

	if CreatedSound or TweenOverride then
		Set(Sound, SoundSettings["Set"], "Sound")
		Tween(Sound, SoundSettings["Tween"], "Sound", Context)

		if CreatedSound then
			Sound:Play()
		end
	end
end

local function GenerateServerSounds(ServerSoundSettings: table, Context: string)
	local ActiveSounds = {} --// Used to filter out server sounds that are not currently playing anymore

	for SoundName, SoundSettings in pairs (ServerSoundSettings) do
		HandleSound(SoundName, SoundSettings, ActiveServerSounds, Context)
		table.insert(ActiveSounds, SoundName)
	end

	local ActiveServerSoundsChildren = ActiveServerSounds:GetChildren()

	for i = 1, #ActiveServerSoundsChildren do
		local ServerSound = ActiveServerSoundsChildren[i]

		if not table.find(ActiveSounds, ServerSound.Name) then
			TweenOut(ServerSound, Context)
		end
	end
end

local function GenerateRegionSounds(RegionSoundSettings: table, RegionSoundFolder: Folder) --// Generates sounds for the region
	for SoundName, SoundSettings in pairs (RegionSoundSettings) do
		HandleSound(SoundName, SoundSettings, RegionSoundFolder, "RegionChange")
	end
end

local function HandleSharedSounds(SharedSoundSettings: table) --// Handles shared sounds for the region's shared sounds (i.e. just adjusting them)
	for SoundName, SoundSettings in pairs (SharedSoundSettings) do
		HandleSound(SoundName, SoundSettings, SharedSounds, "RegionChange", true)
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
		task.wait(SoundSettings["Frequency"])

		if SharedFunctions.DoesChange(SoundSettings["ChanceOfPlay"]) then
			if table.find(InternalVariables["Current Regions Quick"]["Audio"], RegionName) and Sound then --// Validates that the player is still in the region and that the Sound instance still exists
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

--// This looks at the component setting and determines how to read/actualize it
local function GenerateSoundsFromComponent(ComponentSettings: table, Context: string)
	local RegionSoundFolder

	local CurrentScope = PackageHandling:GetCurrentScope("Audio")

	if CurrentScope == "Region" then
		local CurrentRegionName = PackageHandling:GetCurrentPackageName("Audio", "Region")

		RegionSoundFolder = GetRegionSoundFolder(CurrentRegionName)
	end
	
	for SettingCategory, SpecificSettings in pairs (ComponentSettings) do
		if SettingCategory == "SoundService" then
			Tween(SoundService, SpecificSettings, "SoundService", Context)
		elseif SettingCategory == "RegionSounds" then
			GenerateRegionSounds(SpecificSettings, RegionSoundFolder)
		elseif SettingCategory == "SharedSounds" then
			HandleSharedSounds(SpecificSettings)
		elseif SettingCategory == "RandomSounds" then
			GenerateRandomSounds(SpecificSettings, RegionSoundFolder)
		elseif SettingCategory == "ServerSounds" then
			GenerateServerSounds(SpecificSettings, Context) --// Weather is the only time where this bool will be false
		end
	end
end

function module.RegionEnter(RegionName: string) --// Client sided function only (RegionType is either Audio or Lighting, RegionName equivalent to the Setting name)
	local CurrentScope: string = PackageHandling:GetCurrentScope("Audio")
	local CurrentPackageName: string = PackageHandling:GetCurrentPackageName("Audio", "Region")

	local WeatherExemption: boolean = WeatherHandling:CheckForWeatherExemption("Audio", "Region", RegionName)

	--// Applies weather exemption (based on the most recently joined region)
	InternalVariables["Weather Exemption"]["Audio"] = WeatherExemption

	--// If weather is active and there is not a weather exemption
	if WeatherHandling:CheckForActiveWeather("Audio") and not WeatherExemption then
		return
	end

	--// Set the package (if it's a new region or if the current scope is not already region)
	if CurrentPackageName ~= RegionName or CurrentScope ~= "Region" then
		PackageHandling:SetPackage("Audio", "Region", RegionName)
		PackageHandling:SetCurrentScope("Audio", "Region")

		TimeHandling:ReadPackage("Audio", "Region", RegionName, false)

		--// We will do our own initial component change here
		TweenOutServerSounds("RegionChange")
		module:TweenAudio("RegionChange")
	end
end

function module.RegionLeave(RegionName: string) --// Client sided function only (RegionName equivalent to the Setting name)
	TweenOutRegionSounds(RegionName)
	AdjustSharedSounds() --// Shared sounds are the equivalent of multi-regions for audio

	--// If there is active weather
	if WeatherHandling:CheckForActiveWeather("Audio") and PackageHandling:GetCurrentScope("Audio") ~= "Weather" then
		local WeatherPackageName: string = PackageHandling:GetCurrentPackage("Audio", "Weather")

		PackageHandling:SetCurrentScope("Audio", "Weather")
		TimeHandling:ReadPackage("Audio", "Weather", WeatherPackageName, true)
		return
	end

	--// Check whether we are in an audio region still
	if #InternalVariables["Current Regions"]["Audio"]  >= 1 then
		return
	end

	--// Otherwise we are just resyncing to the server like normal
	PackageHandling:SetCurrentScope("Audio", "Server")

	module:TweenAudio("RegionChange")
end

--// Server controls

function module.ClearWeather(CurrentAudioPeriod: string) --// Don't pass this as an argument, trust me.  It will fill in the rest!
	SettingsHandling.WaitForSettings("Audio")

	local TimeAudioSettings

	if RunService:IsServer() then
		TimeAudioSettings = SettingsHandling:GetServerSettings(InternalVariables["CurrentAudioPeriod"], "Audio")
	else
		TimeAudioSettings = SettingsHandling:GetServerSettings(CurrentAudioPeriod, "Audio")
	end

	if not TimeAudioSettings then
		warn("Unable to clear weather - no audio period found")
		return
	end

	InternalVariables["AudioWeather"] = false
	InternalVariables["CurrentAudioWeather"] = ""

	if Settings["ClientSided"] == false or RunService:IsClient() then
		GenerateSoundsFromComponent(TimeAudioSettings, "ClearWeather") --// Components have not been set up in this function
	else
		if RunService:IsServer() then
			--AudioRemote:FireAllClients("ClearWeather", InternalVariables["CurrentAudioPeriod"])
		end
	end
end

function module.ChangeWeather(WeatherName: string)
	SettingsHandling.WaitForSettings("Audio")

	local NewWeatherSettings = SettingsHandling:GetWeatherSettings(WeatherName, "Audio")

	if not NewWeatherSettings then
		warn("Unable to tween weather - no weather settings found")
		return
	end

	InternalVariables["AudioWeather"] = true
	InternalVariables["CurrentAudioWeather"] = WeatherName

	if Settings["ClientSided"] == false or RunService:IsClient() then
		GenerateSoundsFromComponent(NewWeatherSettings, "Weather") --// Components have not been set up in this function
	else
		if RunService:IsServer() then
			--AudioRemote:FireAllClients("Weather", WeatherName)
		end
	end
end

function module:TweenAudio(Context: string)
	local ComponentSettings = PackageHandling:GetCurrentComponent("Audio")

	if not ComponentSettings then
		warn("No audio component found")
		return
	end

	GenerateSoundsFromComponent(ComponentSettings, Context)
end

--[[
if InternalVariables["InitializedAudio"] == false then
	InternalVariables["InitializedAudio"] = true

	if RunService:IsServer() then
		AudioRemote.OnServerEvent:Connect(function(Player, Status)
			if Status == "SyncToServer" then
				local NumberOfTries = 0

				while InternalVariables["TimeInitialized"] == false do --// Sometimes (especialy in Studio) where the client is loading in really fast, it will load in before the CurrentAudioPeriod is set
					task.wait(.2)
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
			elseif Status == "ResyncToServer" then
				if InternalVariables["AudioWeather"] then
					AudioRemote:FireClient(Player, "ToServer", InternalVariables["CurrentAudioPeriod"], InternalVariables["CurrentAudioWeather"])
				else
					AudioRemote:FireClient(Player, "ToServer", InternalVariables["CurrentAudioPeriod"])
				end
			end
		end)
	end
end
]]

return module
