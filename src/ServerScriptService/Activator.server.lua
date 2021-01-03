local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IEFolder = ReplicatedStorage.IE
local IEMain = require(IEFolder.Main)

IEMain.Run()

local AudioHandling = require(IEFolder.Main.AudioHandling)
local LightingHandling = require(IEFolder.Main.LightingHandling)
