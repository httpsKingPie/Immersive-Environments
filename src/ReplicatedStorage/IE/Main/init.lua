--// Prepped for Package transition

local module = {}

local RunService = game:GetService("RunService")

local AudioHandling: ModuleScript
local ClientHandling: ModuleScript
local RegionHandling: ModuleScript
local PackageHandling: ModuleScript
local SettingsHandling: ModuleScript
local TimeHandling: ModuleScript
local WeatherHandling: ModuleScript

local Initialized = false

local function InitializeModules() --// Done so that the Remotes are loaded first and there aren't errors
	AudioHandling = require(script.AudioHandling)
	ClientHandling = require(script.ClientHandling)
	RegionHandling = require(script.RegionHandling)
	PackageHandling = require(script.PackageHandling)
	SettingsHandling = require(script.SettingsHandling)
	TimeHandling = require(script.TimeHandling)
	WeatherHandling = require(script.WeatherHandling)
end

local function GenerateRemotes()
	if RunService:IsServer() then
		local RemoteFolder = Instance.new("Folder")
		RemoteFolder.Name = "RemoteFolder"
		RemoteFolder.Parent = script.Parent

		local AudioRemote = Instance.new("RemoteEvent")
		AudioRemote.Name = "AudioRemote"
		AudioRemote.Parent = RemoteFolder

		local LightingRemote = Instance.new("RemoteEvent")
		LightingRemote.Name = "LightingRemote"
		LightingRemote.Parent = RemoteFolder

		--// New Remotes below
		--[[
			SyncToServer = Tween or set to what the server thinks the lighting should be
			InitialSyncToServer = Set to what the server thinks the lighting should be (tween in the case of audio)
			ChangeComponent = Server -> Client communication to switch the compoent
			ChangePackage = Server -> Client communication to switch the current package

			ClearWeather = Server -> Client communication to change the weather
		]]

		local AudioSyncToServer = Instance.new("RemoteEvent")
		AudioSyncToServer.Name = "AudioSyncToServer"
		AudioSyncToServer.Parent = RemoteFolder

		local AudioChangeComponent = Instance.new("RemoteEvent")
		AudioChangeComponent.Name = "AudioChangeComponent"
		AudioChangeComponent.Parent = RemoteFolder

		local AudioInitialSyncToServer = Instance.new("RemoteEvent")
		AudioInitialSyncToServer.Name = "AudioInitialSyncToServer"
		AudioInitialSyncToServer.Parent = RemoteFolder

		local LightingSyncToServer = Instance.new("RemoteEvent")
		LightingSyncToServer.Name = "LightingSyncToServer"
		LightingSyncToServer.Parent = RemoteFolder

		local LightingChangeComponent = Instance.new("RemoteEvent")
		LightingChangeComponent.Name = "LightingChangeComponent"
		LightingChangeComponent.Parent = RemoteFolder

		local LightingInitialSyncToServer = Instance.new("RemoteEvent")
		LightingInitialSyncToServer.Name = "LightingInitialSyncToServer"
		LightingInitialSyncToServer.Parent = RemoteFolder

		local ClearWeather = Instance.new("RemoteEvent")
		ClearWeather.Name = "ClearWeather"
		ClearWeather.Parent = RemoteFolder
	end
end

function module:Run()
	GenerateRemotes()
	
	if not Initialized then
		InitializeModules()
		Initialized = true
	end

	PackageHandling:Run()
	SettingsHandling:Run()

	coroutine.wrap(AudioHandling.Initialize)() --// Sets up the client sound folders, etc.

	coroutine.wrap(TimeHandling.Initialize)() --// Starts day night cycle

	coroutine.wrap(RegionHandling.Initialize)() --// Initializes regions

	coroutine.wrap(ClientHandling.Initialize)() --// Initialize the client if client-sided
end

--// Below functions just forward it to PackageHandling for easy API use

--// Sets server packages (PackageType is "Audio" or "Lighting")
function module:SetServerPackage(PackageType: string, PackageName: string)
	if not Initialized then
		warn("Initialize IE before interacting with API")
		return
	end

	PackageHandling:SetPackage(PackageType, "Server", PackageName)
	TimeHandling:ReadPackage(PackageType, "Server", PackageName)
end

--// Sets weather packages (PackageType is "Audio" or "Lighting")
function module:SetWeatherPackage(PackageType: string, PackageName: string)
	if not Initialized then
		warn("Initialize IE before interacting with API")
		return
	end

	PackageHandling:SetPackage(PackageType, "Weather", PackageName)
	TimeHandling:ReadPackage(PackageType, "Weather", PackageName)
end

--// Clears weather (Type is "Audio" or "Lighting")
function module:ClearWeather(Type: string)
	if not Initialized then
		warn("Initialize IE before interacting with API")
		return
	end

	PackageHandling:ClearPackage(Type, "Weather")
	WeatherHandling:ClearWeather(Type)
end

return module
