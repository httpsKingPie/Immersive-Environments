local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local IEFolder = ReplicatedStorage:WaitForChild("IE")

local Main = require(IEFolder:WaitForChild("Main"))
local Settings = require(IEFolder:WaitForChild("Settings"))

local AudioHandling = require(IEFolder.Main:WaitForChild("AudioHandling"))
local InternalVariables = require(IEFolder.Main:WaitForChild("InternalVariables"))
local LightingHandling = require(IEFolder.Main:WaitForChild("LightingHandling"))
local PackageHandling = require(IEFolder.Main:WaitForChild("PackageHandling"))
local RemoteHandling = require(IEFolder.Main:WaitForChild("RemoteHandling"))

local RemoteFolder = IEFolder:WaitForChild("RemoteFolder")

local AudioRemote = RemoteFolder:WaitForChild("AudioRemote")
local LightingRemote = RemoteFolder:WaitForChild("LightingRemote")

--// New remotes
local AudioComponentChanged: RemoteEvent = RemoteHandling:GetRemote("Audio", "ComponentChanged")
local AudioInitialSyncToServer: RemoteEvent = RemoteHandling:GetRemote("Audio", "InitialSyncToServer")
local AudioScopeChanged: RemoteEvent = RemoteHandling:GetRemote("Audio", "ScopeChanged")

local LightingComponentChanged: RemoteEvent = RemoteHandling:GetRemote("Lighting", "ComponentChanged")
local LightingInitialSyncToServer: RemoteEvent = RemoteHandling:GetRemote("Lighting", "InitialSyncToServer")
local LightingScopeChanged: RemoteEvent = RemoteHandling:GetRemote("Lighting", "ScopeChanged")

local Initialized = false

local module = {}

function module.Initialize()
    if Initialized then
        return
    end

    Initialized = true

    if Settings["ClientSided"] == true and RunService:IsClient() then
        --LightingRemote:FireServer("SyncToServer") --// Sets the Player's lighting to whatever the server's current lighting is

        LightingInitialSyncToServer.OnClientEvent:Connect(function(CurrentScope: string, CurrentPackage: string, CurrentComponentName: string)
            PackageHandling:SetCurrentScope("Lighting", CurrentScope)

            PackageHandling:SetPackage("Lighting", "Server", CurrentPackage)
            PackageHandling:SetComponent("Lighting", "Server", CurrentComponentName)

            LightingHandling:SetLighting()
        end)

        --// This needs to be editted to ensure it works properly (arguments currently don't align)
        LightingComponentChanged.OnClientEvent:Connect(function(Scope: string, ComponentName: string)
            print("Lighting component changed", Scope, ComponentName)

            PackageHandling:SetComponent("Lighting", Scope, ComponentName)

            if Scope == PackageHandling:GetCurrentScope("Lighting") then
                LightingHandling:AdjustLighting("Time")
            end
        end)

        --AudioRemote:FireServer("SyncToServer")
        
        AudioInitialSyncToServer.OnClientEvent:Connect(function(CurrentScope: string, CurrentPackage: string, CurrentComponentName: string)
            print("Initial set", CurrentScope, CurrentPackage, CurrentComponentName)
            PackageHandling:SetCurrentScope("Audio", CurrentScope)

            PackageHandling:SetPackage("Audio", "Server", CurrentPackage)
            PackageHandling:SetComponent("Audio", "Server", CurrentComponentName)

            AudioHandling:TweenAudio("Time")
        end)

        AudioComponentChanged.OnClientEvent:Connect(function(Scope: string, ComponentName: string)
            print("Audio component changed", Scope, ComponentName)

            PackageHandling:SetComponent("Audio", Scope, ComponentName)

            if Scope == PackageHandling:GetCurrentScope("Audio") then
                AudioHandling:TweenAudio("Time")
            end
        end)

        --// Sets the player's audio and lighting to what is currently playing on the server
        AudioInitialSyncToServer:FireServer()
        LightingInitialSyncToServer:FireServer()

        --// The audio Remote does not feature Type, like Tween and Set, because the audio settings already allow for delineation of which settings to tween and set
        AudioRemote.OnClientEvent:Connect(function(Event:string, SettingName: string, WeatherName: string) --// Only possible Events are "TimeChange", "Weather", and "ToServer" because all region changes happen on the client
            if InternalVariables["HaltAudioCycle"] == false then --// Used to prevent audio changes from occuring while the players is also in a region since regions take precedent.  
                if WeatherName then --// This one is used when the Event is "ToServer", since that indiscriminately fires back the Event == "ToServer", SettingName == CurrentAudioName, and WeatherName == CurrentWeatherName (empty string if none)
                    AudioHandling.ChangeWeather(WeatherName)
                else
                    AudioHandling:TweenAudio(Event, SettingName)
                end
            end
        end)
        
        LightingRemote.OnClientEvent:Connect(function(Event:string, SettingName: string, Type: string, WeatherName: string) --// Only possible Events are "TimeChange", "Weather", and "ToServer" because all region changes happen on the client; Type is "Tween" or "Set"; WeatherName is provided when weather is active (because the cient can't see that)
            if InternalVariables["HaltLightingCycle"] == false then --// Used to prevent lighting changes from occuring while the players is also in a region since regions take precedent.  
                if Type == "Set" or not Settings["Tween"] then
                    if WeatherName then
                        LightingHandling.SetWeather(WeatherName)
                    else
                        LightingHandling:SetLighting(Event, SettingName)
                    end
                else
                    if WeatherName then
                        LightingHandling.TweenWeather(WeatherName)
                    else
                        LightingHandling:TweenLighting(Event, SettingName)
                    end
                end
            end
        end)
    end
end

return module