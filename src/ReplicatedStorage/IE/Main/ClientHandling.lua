local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local IEFolder = ReplicatedStorage:WaitForChild("IE")

local Main = IEFolder:WaitForChild("Main")
local Settings = require(IEFolder:WaitForChild("Settings"))

local AudioHandling = require(Main:WaitForChild("AudioHandling"))
local InternalSettings = require(Main:WaitForChild("InternalSettings"))
local InternalVariables = require(Main:WaitForChild("InternalVariables"))
local LightingHandling = require(Main:WaitForChild("LightingHandling"))
local PackageHandling = require(Main:WaitForChild("PackageHandling"))
local RemoteHandling = require(Main:WaitForChild("RemoteHandling"))
local TimeHandling = require(Main:WaitForChild("TimeHandling"))

local RemoteFolder = IEFolder:WaitForChild("RemoteFolder")

--local AudioRemote = RemoteFolder:WaitForChild("AudioRemote")
--local LightingRemote = RemoteFolder:WaitForChild("LightingRemote")

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
local function HandleInitialSyncToServer(PackageType: string, CurrentScope: string, CurrentPackage: string, CurrentComponentName: string)
    PackageHandling:SetCurrentScope(PackageType, CurrentScope)

    PackageHandling:SetPackage(PackageType, "Server", CurrentPackage)
    PackageHandling:SetComponent(PackageType, "Server", CurrentComponentName)

    module["Initial Set"][PackageType] = true
end

--// Update the component on the client
local function UpdateComponent(PackageType: string, PackageScope: string, ComponentName: string)
    WaitForInitialSet(PackageType)

    PackageHandling:SetComponent(PackageType, PackageScope, ComponentName)
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

    --// Handle server (never set to server if there is a region active)
    if PackageScope == "Server" and CurrentScope == "Region" then
        return
    end

    --// Handle weather (never set to weather if there is a weather exemption)
    if PackageScope == "Weather" and WeatherExemption then
        return
    end

    PackageHandling:SetCurrentScope(PackageType, PackageScope)
end

--// Handles CullingService if it is implemented (only used for things in lighting settings)
local function HandleCullingService()
    local CulledObjects: Folder = workspace:WaitForChild("CulledObjects")

    CulledObjects.DescendantAdded:Connect(function(Descendant: Instance)
        LightingHandling:SetCullingDescendant(Descendant)
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

            if PackageScope == PackageHandling:GetCurrentScope("Lighting") then
                LightingHandling:AdjustLighting("Time")
            end
        end)

        LightingInitialSyncToServer.OnClientEvent:Connect(function(CurrentScope: string, CurrentPackage: string, CurrentComponentName: string)
            HandleInitialSyncToServer("Lighting", CurrentScope, CurrentPackage, CurrentComponentName)

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

            local ComponentForNewScope: string = PackageHandling:GetCurrentComponentName("Lighting")

            if OldScope == "Weather" and ComponentForNewScope then
                LightingHandling:AdjustLighting("Weather")
            end
        end)
        
        AudioComponentChanged.OnClientEvent:Connect(function(PackageScope: string, ComponentName: string)
            UpdateComponent("Audio", PackageScope, ComponentName)

            if PackageScope == PackageHandling:GetCurrentScope("Audio") then
                AudioHandling:TweenAudio("Time")
            end
        end)

        --// Audio Remotes

        AudioInitialSyncToServer.OnClientEvent:Connect(function(CurrentScope: string, CurrentPackage: string, CurrentComponentName: string)
            HandleInitialSyncToServer("Audio", CurrentScope, CurrentPackage, CurrentComponentName)

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

            local ComponentForNewScope: string = PackageHandling:GetCurrentComponentName("Audio")

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