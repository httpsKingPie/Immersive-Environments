local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IEFolder = ReplicatedStorage.IE
local IEMain = require(IEFolder.Main)

IEMain.Run()

--[[

Example for weather settings

wait(5)

local AudioHandling = require(IEFolder.Main.AudioHandling)
local LightingHandling = require(IEFolder.Main.LightingHandling)

AudioHandling.ChangeWeather("TestWeather")
LightingHandling.ChangeWeather("TestWeather")

wait(12)

AudioHandling.ClearWeather()
LightingHandling.ClearWeather()

]]