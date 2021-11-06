local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IEFolder = ReplicatedStorage:WaitForChild("IE")

local Main = require(IEFolder:WaitForChild("Main"))

Main:Run()