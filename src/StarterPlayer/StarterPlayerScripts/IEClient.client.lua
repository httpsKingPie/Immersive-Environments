local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IEFolder = ReplicatedStorage:WaitForChild("IE")

local Main = require(IEFolder:WaitForChild("Main"))
local Settings = require(IEFolder:WaitForChild("Settings"))

local AudioHandling = require(IEFolder.Main:WaitForChild("AudioHandling"))
local InternalVariables = require(IEFolder.Main:WaitForChild("InternalVariables"))
local LightingHandling = require(IEFolder.Main:WaitForChild("LightingHandling"))

local RemoteFolder = IEFolder:WaitForChild("RemoteFolder")

local AudioRemote = RemoteFolder:WaitForChild("AudioRemote")
local LightingRemote = RemoteFolder:WaitForChild("LightingRemote")

if Settings["ClientSided"] == true then
	Main.Run()
	
	LightingRemote:FireServer("SyncToServer") --// Sets the Player's lighting to whatever the server's current lighting is
	AudioRemote:FireServer("SyncToServer")

	--// The audio Remote does not feature Type, like Tween and Set, because the audio settings already allow for delineation of which settings to tween and set
	AudioRemote.OnClientEvent:Connect(function(Event:string, SettingName: string, WeatherName: string) --// Only possible Events are "TimeChange", "Weather", and "ToServer" because all region changes happen on the client
		if InternalVariables["HaltAudioCycle"] == false then --// Used to prevent audio changes from occuring while the players is also in a region since regions take precedent.  
			if WeatherName then --// This one is used when the Event is "ToServer", since that indiscriminately fires back the Event == "ToServer", SettingName == CurrentAudioName, and WeatherName == CurrentWeatherName (empty string if none)
				AudioHandling.TweenWeather(WeatherName)
			else
				AudioHandling.TweenAudio(Event, SettingName)
			end
		end
	end)
	
	LightingRemote.OnClientEvent:Connect(function(Event:string, SettingName: string, Type: string, WeatherName: string) --// Only possible Events are "TimeChange", "Weather", and "ToServer" because all region changes happen on the client; Type is "Tween" or "Set"; WeatherName is provided when weather is active (because the cient can't see that)
		if InternalVariables["HaltLightingCycle"] == false then --// Used to prevent lighting changes from occuring while the players is also in a region since regions take precedent.  
			if Type == "Set" or not Settings["Tween"] then
				if WeatherName then
					LightingHandling.SetWeather(WeatherName)
				else
					LightingHandling.SetLighting(Event, SettingName)
				end
			else
				if WeatherName then
					LightingHandling.TweenWeather(WeatherName)
				else
					LightingHandling.TweenLighting(Event, SettingName)
				end
			end
		end
	end)
end