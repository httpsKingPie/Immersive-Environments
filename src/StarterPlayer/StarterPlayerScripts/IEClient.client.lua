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
	
	LightingRemote:FireServer("Entered") --// Sets the Player's lighting to whatever the server's current lighting is
	AudioRemote:FireServer("Entered")

	--// The audio Remote does not feature Type, like Tween and Set, because the audio settings already allow for delineation of which settings to tween and set
	AudioRemote.OnClientEvent:Connect(function(ChangeType, SettingName, TimeChange)
		print("Remote fired ".. tostring(ChangeType).. " ".. tostring(SettingName).. " " .. tostring(TimeChange))
		if ChangeType == "Audio" then
			if InternalVariables["HaltAudioCycle"] == false then --// Used to prevent audio changes from occuring while the players is also in a region since regions take precedent
				AudioHandling.TweenAudio(SettingName, false, false, TimeChange)
			end
		elseif ChangeType == "Weather" then

		end
	end)
	
	LightingRemote.OnClientEvent:Connect(function(ChangeType, SettingName, Type, TimeChange)
		if ChangeType == "Lighting" then
			if Type == "Set" then
				LightingHandling.SetLighting(SettingName)
			elseif Type == "Tween" then
				if InternalVariables["HaltLightingCycle"] == false then --// Used to prevent lighting changes from occuring while the players is also in a region since regions take precedent
					LightingHandling.TweenLighting(SettingName, false, false, TimeChange)
				end
			end
		elseif ChangeType == "Weather" then
			if Type == "Set" then
				LightingHandling.SetWeather(SettingName)
			elseif Type == "Tween" then
				LightingHandling.TweenWeather(SettingName)
			end
		end
	end)
end