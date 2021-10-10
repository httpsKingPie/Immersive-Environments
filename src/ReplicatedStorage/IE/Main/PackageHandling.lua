local Main: ModuleScript = script.Parent
local IEFolder: Folder = Main.Parent
local Packages: Folder = IEFolder:WaitForChild("Packages")

local AudioPackages: Folder = Packages:FindFirstChild("Audio")
local LightingPackages: Folder = Packages:FindFirstChild("Lighting")

--// IE Modules
local Settings = require(IEFolder.Settings)
local InternalVariables = require(Main.InternalVariables)

--[[ 'Mega table' which requires all packages in here, for fast reference.  It will look like
    local module = {
        ["Audio"] = {
            ["Region"] = {
                [PackageName] = {
                    ["Count"] = number (used for sorted checks),
                    ["Components"] = {
                        [Component Name] = module
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
end

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

	InternalVariables["AudioSettingTablesBuilt"] = true
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

	InternalVariables["LightingSettingTablesBuilt"] = true
end

--// Sets server packages (PackageType is "Audio" or "Lighting")
function module:SetServerPackage(PackageType: string, PackageName: string)
	if not module[PackageType] then
		warn("Invalid PackageType", PackageType)
		return
	end

	if not module[PackageType]["Server"][PackageName] then
		warn("Invalid PackageName", PackageName, "for PackageType", PackageType)
		return
	end

	InternalVariables["Current Package"][PackageType]["Server"] = PackageName
end

--// Sets weather packages (PackageType is "Audio" or "Lighting")
function module:SetWeatherPackage(PackageType: string, PackageName: string)
	if not module[PackageType] then
		warn("Invalid PackageType", PackageType)
		return
	end

	if not module[PackageType]["Weather"][PackageName] then
		warn("Invalid PackageName", PackageName, "for PackageType", PackageType)
		return
	end

	InternalVariables["Current Package"][PackageType]["Weather"] = PackageName
end

--// Basic run function
function module:Run()
    module:GenerateAudioPackages()
	module:GenerateLightingPackages()
end

return module