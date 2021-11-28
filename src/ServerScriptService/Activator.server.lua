local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IEFolder = ReplicatedStorage.IE
local IEMain = require(IEFolder.Main)

IEMain:Run()
IEMain:SetServerPackage("Audio", "Default")
IEMain:SetServerPackage("Lighting", "Default")


task.wait(5)

print("Setting weather")
IEMain:SetWeatherPackage("Audio", "TestAudioWeather")
IEMain:SetWeatherPackage("Lighting", "TestLightingWeather")


task.wait(30)

print("Ending weather")
IEMain:ClearWeather("Audio")
IEMain:ClearWeather("Lighting")