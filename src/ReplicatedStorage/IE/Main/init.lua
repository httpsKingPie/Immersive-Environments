local module = {}

local Settings = require(script.Parent.Settings)

local AudioHandling
local LightingHandling
local RegionHandling
local SettingsHandling
local TimeHandling

local Initialized = false

local function InitializeModules() --// Done so that the Remotes are loaded first and there aren't errors
	AudioHandling = require(script.AudioHandling)
	LightingHandling = require(script.LightingHandling)
	RegionHandling = require(script.RegionHandling)
	SettingsHandling = require(script.SettingsHandling)
	TimeHandling = require(script.TimeHandling)
end

local function GenerateRemotes()
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

function module.Run()
	GenerateRemotes()
	
	if Initialized == false then
		InitializeModules()
		Initialized = true
	end
	SettingsHandling.Run() --// Not a coroutine, because we want Settings to populate before everything first

	coroutine.wrap(TimeHandling.Run)()

	coroutine.wrap(RegionHandling.Run)()
	coroutine.wrap(LightingHandling.Run)()
	coroutine.wrap(AudioHandling.Run)()
end

return module
