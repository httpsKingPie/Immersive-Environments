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

--// Neater way of getting the current scope
function module:GetCurrentScope()
	return InternalVariables["Current Scope"]
end

--// Neater way of changing the scope.  NewScope = "Region", "Server", or "Weather"
function module:SetCurrentScope(NewScope: string)
	InternalVariables["Current Scope"] = NewScope
end

--// Gets a package table by name
function module:GetPackage(PackageType: string, PackageName: string)
	local CurrentScope = module:GetCurrentScope()

	if not self[PackageType] then
		warn("Invalid PackageType:", PackageType)
		return
	end

	if not self[PackageType][CurrentScope] then
		warn("Invalid PackageScope:", CurrentScope, "for PackageType", PackageType)
		return
	end

	local Package = self[PackageType][CurrentScope][PackageName]

	if not Package then
		warn("Invalid PackageName:", PackageName, "for PackageType", PackageType, "and PackageScope", CurrentScope)
		return
	end

	return Package
end

--// Gets a component module by name
function module:GetComponent(PackageType: string, PackageName: string, ComponentName: string)
	local CurrentScope = module:GetCurrentScope()
	
	local Package = module:GetPackage(PackageType, PackageName)

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

--// Fast functions

function module:GetCurrentPackage(PackageType: string)
	if not self[PackageType] then
		warn("Invalid PackageType:", PackageType)
		return
	end

	local CurrentScope = module:GetCurrentScope()

	if not self[PackageType][CurrentScope] then
		warn("Invalid PackageScope:", CurrentScope, "for PackageType", PackageType)
		return
	end

	local PackageName: string = InternalVariables["Current Package"][PackageType][CurrentScope]

	local Package = module:GetPackage(PackageType, PackageName)

	if not Package then --// Additional return in here not necessary, since it would be nil regardless
		warn("No package found for PackageScope:", CurrentScope, "for PackageType", PackageType)
	end

	return Package
end

function module:GetCurrentComponent(PackageType: string)
	local CurrentScope = module:GetCurrentScope()

	local Package = module:GetCurrentPackage(PackageType)

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
end

function module:SetComponent

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

--// Basic run function
function module:Run()
    module:GenerateAudioPackages()
	module:GenerateLightingPackages()
end

return module