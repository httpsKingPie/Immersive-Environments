local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IEFolder = ReplicatedStorage:WaitForChild("IE")
local IEMain = require(IEFolder:WaitForChild("Main"))

IEMain:Run()