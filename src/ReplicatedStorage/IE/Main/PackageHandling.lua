local RunService = game:GetService("RunService")

local Main: ModuleScript = script.Parent
local IEFolder: Folder = Main.Parent
local Packages: Folder = IEFolder:WaitForChild("Packages")

local AudioPackages: Folder = Packages:FindFirstChild("Audio")
local LightingPackages: Folder = Packages:FindFirstChild("Lighting")

--// IE Modules
local Settings = require(IEFolder.Settings)

local InternalVariables = require(Main.InternalVariables)
local RemoteHandling = require(Main.RemoteHandling)

local AudioHandling
local LightingHandling

local ClientSided: boolean = Settings["Client Sided"]
local IsServer = RunService:IsServer()

local NotifyClient = if ClientSided and IsServer then true else false --// Whether IE should notify the client when components, packages, or scope changes

--[[ 'Mega table' which requires all packages in here, for fast reference.  It will look like
    local module = {
        ["Audio"] = { 												PackageType
            ["Region"] = {											PackageScope
                [PackageName] = {									PackageName
                    ["Count"] = number (used for sorted checks),	-
                    ["Components"] = {								-
                        [ComponentName] = module					ComponentName
                        ...
                    },
                },
                ...
            },
            ...
        },
        ...
    }
]]
local module = {
    ["Audio"] = {
        ["Region"] = {},
		["Server"] = {},
		["Weather"] = {},
    },
	
    ["Lighting"] = {
        ["Region"] = {},
		["Server"] = {},
		["Weather"] = {},
    },
}

--[[
    Handles a specific package within a scope (ex: Audio -> Region -> Forest (if that was a region))
    
    Arguments: PackageType: string ("Lighting" or "Audio"), PackageScope: string ("Region", "Server", or "Weather"), PackageName: string, PackageComponents: table (should be of modules)
]]

local function BuildPackage(PackageType: string, PackageScope: string, PackageName: string, PackageComponents: table)
	local Package = {
		["Count"] = 0,
		["Components"] = {},
	}

	local Count = 0 --// Used for sorted checks

	for _, Component: ModuleScript in pairs (PackageComponents) do
		local ComponentName = Component.Name

		if not Package[ComponentName] then
			Count = Count + 1
			Package["Components"][ComponentName] = require(Component)
		else
			warn(PackageType, PackageScope, PackageName, ComponentName, "already exists. Remove duplicate component names of the same package")
		end
	end

	Package["Count"] = Count
	
	--// Place Package in the 'mega table'
	module[PackageType][PackageScope][PackageName] = Package
end

--[[
    Handles all packages for a specific scope (ex: Audio -> Region)

    Arguments: PackageType: string ("Lighting" or "Audio"), PackageScope: string ("Region", "Server", or "Weather"), ScopeFolder: Folder (ex: AudioRegion or AudioServer)
]]

local function HandlePackages(PackageType: string, PackageScope: string, ScopeFolder: Folder)
	if not ScopeFolder then
		return
	end

	local ScopeChildren = ScopeFolder:GetChildren()

    for _, Package: Folder in pairs (ScopeChildren) do
        local PackageName: string = Package.Name

        if not module[PackageType][PackageScope][PackageName] then --// Check to ensure it doesn't already exist
            local PackageComponents: table = Package:GetChildren() --// The component settings that make up a package

            BuildPackage(PackageType, PackageScope, PackageName, PackageComponents)
        else
            warn(PackageType, PackageScope, PackageName, "already exists. Remove duplicate package names of the same type")
        end
    end
end

--// Neater way of getting the current scope.  PackageType = "Audio" or "Lighting"
function module:GetCurrentScope(PackageType: string)
	if not InternalVariables["Current Scope"][PackageType] then
		warn("Invalid PackageType:", PackageType)
		return
	end
	
	return InternalVariables["Current Scope"][PackageType]
end

--// Neater way of changing the scope.  PackageType = "Audio" or "Lighting"; NewScope = "Region", "Server", or "Weather"
function module:SetCurrentScope(PackageType: string, NewScope: string)
	if not InternalVariables["Current Scope"][PackageType] then
		warn("Invalid PackageType:", PackageType)
		return
	end

	InternalVariables["Current Scope"][PackageType] = NewScope

	if NotifyClient then
		local Remote: RemoteEvent = RemoteHandling:GetRemote(PackageType, "ScopeChanged")

		Remote:FireAllClients(NewScope)
	end
end

--// Gets a package table by name
function module:GetPackage(PackageType: string, PackageScope: string, PackageName: string)
	if not self[PackageType] then
		warn("Invalid PackageType:", PackageType)
		return
	end

	if not self[PackageType][PackageScope] then
		warn("Invalid PackageScope:", PackageScope, "for PackageType", PackageType)
		return
	end

	local Package = self[PackageType][PackageScope][PackageName]

	if not Package then
		warn("Invalid PackageName:", PackageName, "for PackageType", PackageType, "and PackageScope", PackageScope)
		return
	end

	return Package
end

--// Gets a component module by name
function module:GetComponent(PackageType: string, PackageName: string, ComponentName: string)
	local CurrentScope = module:GetCurrentScope(PackageType)
	
	local Package = module:GetPackage(PackageType, CurrentScope, PackageName)

	if not Package then
		return --// Error already bundled in
	end

	local Component = Package["Components"][ComponentName]
	
	if not Component then
		warn("Invalid ComponentName:", ComponentName, "for PackageName", PackageName, "for PackageType", PackageType, "and PackageScope", CurrentScope)
		return
	end

	return Component
end

--// Verifies component of current package, PackageType = "Audio" or "Lighting"
function module:VerifyComponentExists(PackageType: string, Scope: string, ComponentName: string)
	local Package = module:GetCurrentPackage(PackageType, Scope)

	if not Package then
		return --// Error already bundled in
	end

	local Component = Package["Components"][ComponentName]
	
	if not Component then
		warn("Invalid ComponentName:", ComponentName, "for current package", PackageType, "and scope", Scope)
		return
	end

	return true
end

--// Fast functions
function module:GetCurrentPackage(PackageType: string, PackageScope: string)
	if not self[PackageType] then
		warn("Invalid PackageType:", PackageType)
		return
	end

	if not self[PackageType][PackageScope] then
		warn("Invalid PackageScope:", PackageScope, "for PackageType", PackageType)
		return
	end

	local PackageName: string = InternalVariables["Current Package"][PackageType][PackageScope]

	local Package = module:GetPackage(PackageType, PackageScope, PackageName)

	if not Package then --// Additional return in here not necessary, since it would be nil regardless
		warn("No package found for PackageScope:", PackageScope, "for PackageType", PackageType)
	end

	return Package
end

function module:GetCurrentPackageName(PackageType: string, PackageScope: string)
	if not self[PackageType] then
		warn("Invalid PackageType:", PackageType)
		return
	end

	if not self[PackageType][PackageScope] then
		warn("Invalid PackageScope:", PackageScope, "for PackageType", PackageType)
		return
	end

	local PackageName: string = InternalVariables["Current Package"][PackageType][PackageScope]

	return PackageName
end

function module:GetCurrentComponent(PackageType: string)
	local CurrentScope = module:GetCurrentScope(PackageType)

	local Package = module:GetCurrentPackage(PackageType, CurrentScope)

	if not Package then --// Warning already bundled in
		return
	end

	local PackageName: string = InternalVariables["Current Package"][PackageType][CurrentScope]
	local ComponentName: string = InternalVariables["Current Component"][PackageType][CurrentScope]

	local Component = Package["Components"][ComponentName]
	
	if not Component then
		warn("Invalid ComponentName:", ComponentName, "for PackageName", PackageName, "for PackageType", PackageType, "and PackageScope", CurrentScope)
		return
	end

	return Component
end

function module:GetCurrentComponentName(PackageType: string, PackageScope: string)
	local Package = module:GetCurrentPackage(PackageType, PackageScope)

	if not Package then --// Warning already bundled in
		return
	end

	local ComponentName: string = InternalVariables["Current Component"][PackageType][PackageScope]

	return ComponentName
end

--// Control functions

--// Sets packages, PackageType is "Lighting" or "Audio", PackageScope is "Region", "Server", or "Weather", PackageName is the name of the Package
function module:SetPackage(PackageType: string, PackageScope: string, PackageName: string)
	if not module[PackageType] then
		warn("Invalid PackageType", PackageType)
		return
	end

	if not module[PackageType][PackageScope] then
		warn("Invalid PackageScope:", PackageScope, "for PackageType", PackageType)
		return
	end

	if not module[PackageType][PackageScope][PackageName] then
		warn("Invalid PackageName", PackageName, "for PackageScope", PackageScope, "for PackageType", PackageType)
		return
	end

	InternalVariables["Current Package"][PackageType][PackageScope] = PackageName

	if NotifyClient then
		local Remote: RemoteEvent = RemoteHandling:GetRemote(PackageType, "PackageChanged")

		Remote:FireAllClients(PackageScope, PackageName)
	end
end

--// Clears packages, PackageType is "Lighting" or "Audio", PackageScope is "Region", "Server", or "Weather"
function module:ClearPackage(PackageType: string, PackageScope: string)
	if not module[PackageType] then
		warn("Invalid PackageType", PackageType)
		return
	end

	if not module[PackageType][PackageScope] then
		warn("Invalid PackageScope:", PackageScope, "for PackageType", PackageType)
		return
	end

	InternalVariables["Current Package"][PackageType][PackageScope] = false

	if NotifyClient then
		local Remote: RemoteEvent = RemoteHandling:GetRemote(PackageType, "PackageCleared")

		Remote:FireAllClients(PackageScope)
	end
end

--// Set the component (Type = "Audio" or "Lighting"), Scope = "Region", "Server", or "Weather"
function module:SetComponent(Type: string, Scope: string, ComponentName: string)
	local ComponentExists = module:VerifyComponentExists(Type, Scope, ComponentName)

	if not ComponentExists then --// Error already bundled in
		return
	end

	InternalVariables["Current Component"][Type][Scope] = ComponentName

	if NotifyClient then
		local Remote: RemoteEvent = RemoteHandling:GetRemote(Type, "ComponentChanged")

		Remote:FireAllClients(Scope, ComponentName)
		
		return
	end

	if Type == "Audio" then
		if Scope == module:GetCurrentScope("Audio") then
			AudioHandling:TweenAudio("Time")
		end
	elseif Type == "Lighting" then
		if Scope == module:GetCurrentScope("Lighting") then
			LightingHandling:AdjustLighting("Time")
		end
	end
end

--// Initialization functions

--// Default setup for audio packages
function module:GenerateAudioPackages()
	if not AudioPackages then
		return
	end
	
	--// It doesn't matter if these don't exist or if the developer deletes these folders, there is a built in check
	local AudioRegion: Folder = AudioPackages:FindFirstChild("Region")
	local AudioServer: Folder = AudioPackages:FindFirstChild("Server")
	local AudioWeather: Folder = AudioPackages:FindFirstChild("Weather")

	HandlePackages("Audio", "Region", AudioRegion)
	HandlePackages("Audio", "Server", AudioServer)
	HandlePackages("Audio", "Weather", AudioWeather)
end

--// Default setup of lighting packages
function module:GenerateLightingPackages()
	if not LightingPackages then
		return
	end

	--// It doesn't matter if these don't exist or if the developer deletes these folders, there is a built in check
	local LightingRegion: Folder = LightingPackages:WaitForChild("Region")
	local LightingServer: Folder = LightingPackages:WaitForChild("Server")
	local LightingWeather: Folder = LightingPackages:WaitForChild("Weather")

	HandlePackages("Lighting", "Region", LightingRegion)
	HandlePackages("Lighting", "Server", LightingServer)
	HandlePackages("Lighting", "Weather", LightingWeather)
end

--// Basic run function
function module:Initialize()
	if InternalVariables["Initialized"]["Packages"] then
		return
	end
	
	AudioHandling = require(Main:WaitForChild(("AudioHandling")))
	LightingHandling = require(Main:WaitForChild(("LightingHandling")))

	InternalVariables["Initialized"]["Packages"] = true

    module:GenerateAudioPackages()
	module:GenerateLightingPackages()
end

return module