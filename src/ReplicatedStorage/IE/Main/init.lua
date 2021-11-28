--// Prepped for Package transition

local module = {}

local RunService = game:GetService("RunService")

local AudioHandling: ModuleScript
local ClientHandling: ModuleScript
local LightingHandling: ModuleScript
local RegionHandling: ModuleScript
local PackageHandling: ModuleScript
local TimeHandling: ModuleScript

local InternalSettings = require(script.InternalSettings)

local Initialized = false

local function InitializeModules() --// Done so that the Remotes are loaded first and there aren't errors
	AudioHandling = require(script.AudioHandling)
	ClientHandling = require(script.ClientHandling)
	LightingHandling = require(script.LightingHandling)
	RegionHandling = require(script.RegionHandling)
	PackageHandling = require(script.PackageHandling)
	TimeHandling = require(script.TimeHandling)
end

local function GenerateRemotes()
	if RunService:IsServer() then
		local RemoteFolder = Instance.new("Folder")
		RemoteFolder.Name = "RemoteFolder"
		RemoteFolder.Parent = script.Parent

		--// Generates Type Separated RemoteEvents
		for _, RemoteName: string in pairs (InternalSettings["Remote Events"]["Type Separated"]) do
			local AudioRemoteEvent = Instance.new("RemoteEvent")
			AudioRemoteEvent.Name = "Audio".. RemoteName
			AudioRemoteEvent.Parent = RemoteFolder

			local LightingRemoteEvent = Instance.new("RemoteEvent")
			LightingRemoteEvent.Name = "Lighting".. RemoteName
			LightingRemoteEvent.Parent = RemoteFolder
		end

		--// Generates fixed RemoteEvents
		for _, RemoteName: string in pairs (InternalSettings["Remote Events"]["Fixed"]) do
			local RemoteEvent = Instance.new("RemoteEvent")
			RemoteEvent.Name = RemoteName
			RemoteEvent.Parent = RemoteFolder
		end
	end
end

--// IMPORTANT

--// Below are the only API functions you should have to use directly

--// !!!!!!!!!

--// Sets server packages (PackageType is "Audio" or "Lighting")
function module:SetServerPackage(PackageType: string, PackageName: string)
	if not Initialized then
		warn("Initialize IE before interacting with API")
		return
	end

		return
	end

	PackageHandling:SetPackage(PackageType, "Weather", PackageName)
	PackageHandling:SetCurrentScope(PackageType, "Weather")

	TimeHandling:ReadPackage(PackageType, "Weather", PackageName, true)
end

--// Clears weather (Type is "Audio" or "Lighting")
function module:ClearWeather(PackageType: string)
	if not Initialized then
		warn("Initialize IE before interacting with API")
		return
	end

	PackageHandling:ClearPackage(PackageType, "Weather")
	PackageHandling:SetCurrentScope(PackageType, "Server")
end

function module:Run()
	if Initialized then
		return
	end

	Initialized = true

	GenerateRemotes()

	InitializeModules()

	PackageHandling:Initialize()

	coroutine.wrap(AudioHandling.Initialize)() --// Sets up the client sound folders, etc.

	coroutine.wrap(LightingHandling.Initialize)()

	coroutine.wrap(TimeHandling.Initialize)() --// Starts day night cycle

	coroutine.wrap(RegionHandling.Initialize)() --// Initializes regions

	coroutine.wrap(RegionHandling.Run)() --// Initializes regions

	coroutine.wrap(ClientHandling.Initialize)() --// Initialize the client if client-sided
end

return module
