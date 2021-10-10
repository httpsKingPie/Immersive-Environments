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

function module.Run()
	GenerateRemotes()
	
	if Initialized == false then
		InitializeModules()
		Initialized = true
	end

	PackageHandling.Run()
	SettingsHandling.Run()

	coroutine.wrap(AudioHandling.Run)() --// Sets up the client sound folders, etc.

	coroutine.wrap(TimeHandling.Run)() --// Generates time cycles, periods, etc.

	coroutine.wrap(RegionHandling.Run)() --// Initializes regions
end

return module
