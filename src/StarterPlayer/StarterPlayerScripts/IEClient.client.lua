local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IEFolder = ReplicatedStorage:WaitForChild("IE")

local Main = require(IEFolder:WaitForChild("Main"))
local Settings = require(IEFolder:WaitForChild("Settings"))

local AudioHandling = require(IEFolder.Main:WaitForChild("AudioHandling"))
local LightingHandling = require(IEFolder.Main:WaitForChild("LightingHandling"))

local RemoteFolder = IEFolder:WaitForChild("RemoteFolder")
local LightingRemote = RemoteFolder:WaitForChild("LightingRemote")

if Settings["ClientSided"] == true then
	Main.Run()
	
	LightingRemote:FireServer("Entered") --// Sets the Player's lighting to whatever the server's current lighting is
	
	LightingRemote.OnClientEvent:Connect(function(ChangeType, SettingName, Type)
		if ChangeType == "Lighting" then
			if Type == "Set" then
				LightingHandling.SetLighting(SettingName)
			elseif Type == "Tween" then
				LightingHandling.TweenLighting(SettingName)
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