local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IEFolder = ReplicatedStorage.IE
local IEMain = require(IEFolder.Main)

IEMain:Run()
IEMain:SetServerPackage("Audio", "Default")
IEMain:SetServerPackage("Lighting", "Default")

local TestWeather: boolean = false

if not TestWeather then
    return
end

task.wait(5)

print("Setting weather")
IEMain:SetWeatherPackage("Audio", "TestAudioWeather")
IEMain:SetWeatherPackage("Lighting", "TestLightingWeather")


task.wait(60)

print("Ending weather")
IEMain:ClearWeather("Audio")
IEMain:ClearWeather("Lighting")