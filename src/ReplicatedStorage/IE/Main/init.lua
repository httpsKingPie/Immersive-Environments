--// Prepped for Package transition

local module = {}

local RunService = game:GetService("RunService")

local AudioHandling: ModuleScript
local RegionHandling: ModuleScript
local PackageHandling: ModuleScript
local SettingsHandling: ModuleScript
local TimeHandling: ModuleScript

local Initialized = false

local function InitializeModules() --// Done so that the Remotes are loaded first and there aren't errors
	AudioHandling = require(script.AudioHandling)
	RegionHandling = require(script.RegionHandling)
	PackageHandling = require(script.PackageHandling)
	SettingsHandling = require(script.SettingsHandling)
	TimeHandling = require(script.TimeHandling)
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
end

--// Below functions just forward it to PackageHandling for easy API use

--// Sets server packages (PackageType is "Audio" or "Lighting")
function module:SetServerPackage(PackageType: string, PackageName: string)
	if not Initialized then
		warn("Initialize IE before setting packages")
		return
	end

	PackageHandling:SetServerPackage(PackageType, PackageName)
	TimeHandling:ReadPackage(PackageType, "Server", PackageName)
end

--// Sets weather packages (PackageType is "Audio" or "Lighting")
function module:SetWeatherPackage(PackageType: string, PackageName: string)
	if not Initialized then
		warn("Initialize IE before setting packages")
		return
	end

	PackageHandling:SetWeatherPackage(PackageType, PackageName)
	TimeHandling:ReadPackage(PackageType, "Weather", PackageName)
end

return module
