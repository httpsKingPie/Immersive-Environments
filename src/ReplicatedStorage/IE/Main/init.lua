local module = {}

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ObjectTracker = require(script.Parent["OT&AM"])
local Settings = require(script.Parent.Settings)

local AudioHandling
local LightingHandling
local RegionHandling
local TimeHandling

local TableUtilities = require(script.TableUtilities)

local InternalSettings = require(script.InternalSettings)

local TweenInformation = Settings["TweenInformation"]

local Initialized = false

local function InitializeModules() --// Done so that the Remotes are loaded first and there aren't errors
	AudioHandling = require(script.AudioHandling)
	LightingHandling = require(script.LightingHandling)
	RegionHandling = require(script.RegionHandling)
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
	coroutine.wrap(TimeHandling.Run)()

	coroutine.wrap(RegionHandling.Run)()
	coroutine.wrap(LightingHandling.Run)()
	coroutine.wrap(AudioHandling.Run)()
end

return module
