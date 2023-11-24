local RunService = game:GetService("RunService")

local Main = script.Parent
local IEFolder = Main.Parent
local Settings = require(IEFolder:WaitForChild("Settings"))

local AudioHandling = require(Main:WaitForChild("AudioHandling"))
local InternalSettings = require(Main:WaitForChild("InternalSettings"))
local InternalVariables = require(Main:WaitForChild("InternalVariables"))
local LightingHandling = require(Main:WaitForChild("LightingHandling"))
local PackageHandling = require(Main:WaitForChild("PackageHandling"))
local RemoteHandling = require(Main:WaitForChild("RemoteHandling"))

--// New remotes
local AudioComponentChanged: RemoteEvent = RemoteHandling:GetRemote("Audio", "ComponentChanged")
local AudioInitialSyncToServer: RemoteEvent = RemoteHandling:GetRemote("Audio", "InitialSyncToServer")
local AudioPackageChanged: RemoteEvent = RemoteHandling:GetRemote("Audio", "PackageChanged")
local AudioPackageCleared: RemoteEvent = RemoteHandling:GetRemote("Audio", "PackageCleared")
local AudioScopeChanged: RemoteEvent = RemoteHandling:GetRemote("Audio", "ScopeChanged")

local LightingComponentChanged: RemoteEvent = RemoteHandling:GetRemote("Lighting", "ComponentChanged")
local LightingInitialSyncToServer: RemoteEvent = RemoteHandling:GetRemote("Lighting", "InitialSyncToServer")
local LightingPackageChanged: RemoteEvent = RemoteHandling:GetRemote("Lighting", "PackageChanged")
local LightingPackageCleared: RemoteEvent = RemoteHandling:GetRemote("Lighting", "PackageCleared")
local LightingScopeChanged: RemoteEvent = RemoteHandling:GetRemote("Lighting", "ScopeChanged")

local Initialized = false

local module = {
    ["Initial Set"] = {
        ["Audio"] = false,
        ["Lighting"] = false,
    }
}

--// Waits for the initial set in case of weird server -> client lag
local function WaitForInitialSet(PackageType: string)
    if module["Initial Set"][PackageType] then
        return
    end

    local NumberOfTries: number = 0

    while not module["Initial Set"][PackageType] do
        task.wait(.2)

        NumberOfTries = NumberOfTries + 1

        if NumberOfTries > InternalSettings["InitializationMaxTries"] then
            warn("Max Tries has been reached for waiting for initial set")
            return
        end
    end
end

--// Clears the package on the client
local function ClearClientPackage(PackageType: string, PackageScope: string)
    WaitForInitialSet(PackageType)

    PackageHandling:ClearPackage(PackageType, PackageScope)
end

--// Handles the initial sync to server (when a player first joins)
--[[
    Sends an initial sync table, just because it's a lot of variables

    Table indexes and values (all strings):
    ["PackageType"] = Lighting or Audio
    ["CurrentScope"] = Server or Weather (since region is decided by the client)
    ["CurrentPackage"] = PackageName
    ["CurrentComponent"] = ComponentName

    ["CurrentServerPackage"] = PackageName
    ["CurrentServerComponent"] = ComponentName

    Bottom two only go into effect if the CurrentScope is Weather (since then we need to fill them in, otherwise, they won't be sent)
]]

local function HandleInitialSyncToServer(SyncTable: table)
    local PackageType: string = SyncTable["PackageType"]
    local CurrentScope: string = SyncTable["CurrentScope"]
    local CurrentPackage: string = SyncTable["CurrentPackage"]
    local CurrentComponent: string = SyncTable["CurrentComponent"]

    PackageHandling:SetCurrentScope(PackageType, CurrentScope)

    PackageHandling:SetPackage(PackageType, CurrentScope, CurrentPackage)
    PackageHandling:SetComponent(PackageType, CurrentScope, CurrentComponent)

    if CurrentScope == "Weather" then
        local CurrentServerPackage: string = SyncTable["CurrentServerPackage"]
        local CurrentServerComponent: string = SyncTable["CurrentServerComponent"]

        PackageHandling:SetPackage(PackageType, "Server", CurrentServerPackage)
        PackageHandling:SetComponent(PackageType, "Server", CurrentServerComponent)
    end

    module["Initial Set"][PackageType] = true
end

--// Update the component on the client
local function UpdateComponent(PackageType: string, PackageScope: string, ComponentName: string)
    WaitForInitialSet(PackageType)

    local OldComponentName: string = PackageHandling:GetCurrentComponentName(PackageType, PackageScope)

    if OldComponentName == ComponentName then
        return false
    end

    PackageHandling:SetComponent(PackageType, PackageScope, ComponentName)

    return true
end

--// Update the package on the client
local function UpdatePackage(PackageType: string, PackageScope: string, PackageName: string)
    WaitForInitialSet(PackageType)

    PackageHandling:SetPackage(PackageType, PackageScope, PackageName)
end

--// Update the scope (with checks)
local function UpdateScope(PackageType: string, PackageScope: string)
    WaitForInitialSet(PackageType)
    
    local WeatherExemption: boolean = InternalVariables["Weather Exemption"][PackageType]
    local CurrentScope = PackageHandling:GetCurrentScope(PackageType)

    local InRegion: boolean = if #InternalVariables["Current Regions"][PackageType] > 0 then true else false

    --// Handle server (never set to server if there is a region active)
    if PackageScope == "Server" and CurrentScope == "Region" then
        return
    end

    --// Handle weather (never set to weather if there is a weather exemption)
    if PackageScope == "Weather" and WeatherExemption then
        return
    end

    if PackageScope == "Server" and InRegion then
        PackageHandling:SetCurrentScope(PackageType, "Region")
        return
    end

    PackageHandling:SetCurrentScope(PackageType, PackageScope)
end

--// Handles CullingService if it is implemented (only used for things in lighting settings)
local function HandleCullingService()
    local CulledObjects: Folder = workspace:WaitForChild("CulledObjects")

    CulledObjects.DescendantAdded:Connect(function(Descendant: Instance)
        if not Descendant:IsA("Folder") then
            return
        end
        
        LightingHandling:SetCullingRangeFolder(Descendant)
    end)
end

function module.Initialize()
    if Initialized then
        return
    end

    Initialized = true

    if Settings["Client Sided"] and RunService:IsClient() then
        --// Lighting Remotes

        LightingComponentChanged.OnClientEvent:Connect(function(PackageScope: string, ComponentName: string)
            UpdateComponent("Lighting", PackageScope, ComponentName)
        end)

        LightingInitialSyncToServer.OnClientEvent:Connect(function(SyncTable: table)
            HandleInitialSyncToServer(SyncTable)

            LightingHandling:SetLighting()
        end)

        LightingPackageChanged.OnClientEvent:Connect(function(PackageScope: string, PackageName: string)
            UpdatePackage("Lighting", PackageScope, PackageName)
        end)

        LightingPackageCleared.OnClientEvent:Connect(function(PackageScope: string)
            ClearClientPackage("Lighting", PackageScope)
        end)

        LightingScopeChanged.OnClientEvent:Connect(function(PackageScope: string)
            local OldScope: string = PackageHandling:GetCurrentScope("Lighting")

            UpdateScope("Lighting", PackageScope)

            local ComponentForNewScope: string = PackageHandling:GetCurrentComponentName("Lighting", PackageScope)

            if OldScope == "Weather" and ComponentForNewScope then
                LightingHandling:AdjustLighting("Weather")
            end
        end)

        --// Audio Remotes
        
        AudioComponentChanged.OnClientEvent:Connect(function(PackageScope: string, ComponentName: string)
            UpdateComponent("Audio", PackageScope, ComponentName)
        end)

        AudioInitialSyncToServer.OnClientEvent:Connect(function(SyncTable: table)
            HandleInitialSyncToServer(SyncTable)

            AudioHandling:TweenAudio("Time")
        end)

        AudioPackageChanged.OnClientEvent:Connect(function(PackageScope: string, PackageName: string)
            UpdatePackage("Audio", PackageScope, PackageName)
        end)

        AudioPackageCleared.OnClientEvent:Connect(function(PackageScope: string)
            ClearClientPackage("Audio", PackageScope)
        end)

        AudioScopeChanged.OnClientEvent:Connect(function(PackageScope: string)
            local OldScope: string = PackageHandling:GetCurrentScope("Audio")

            UpdateScope("Audio", PackageScope)

            local ComponentForNewScope: string = PackageHandling:GetCurrentComponentName("Audio", PackageScope)

            if OldScope == "Weather" and ComponentForNewScope then
                AudioHandling:TweenAudio("Weather")
            end
        end)

        if Settings["CullingService"] then
            HandleCullingService()
        end

        --// Sets the player's audio and lighting to what is currently playing on the server
        AudioInitialSyncToServer:FireServer()
        LightingInitialSyncToServer:FireServer()
    end
end

return module