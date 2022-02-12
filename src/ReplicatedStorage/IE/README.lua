local module = {}

--[[
    To use IE, simply require the Main module from the server and the client.  I highly recommend placing this in ReplicatedStorage for easy access
    Call Main:Run() on both
    On the server, set your default "Audio" and "Lighting" package
    That is all it takes to get IE to run

    For more detailed instructions on how to set-up packages, I highly recommend looking (in order) at:
    Example Place: https://www.roblox.com/games/5889648780/Immersive-Environments-Testing
    DevForum post: https://devforum.roblox.com/t/immersive-environments-v2-advanced-package-based-audio-and-lighting-control/962709
    GitHub Pages: https://httpskingpie.github.io/Immersive-Environments/

    The most up-to-date version of IE can always be found on GitHub: https://github.com/httpsKingPie/Immersive-Environments

    Below is example code which gets IE running

    (Server script)

    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local IEFolder = ReplicatedStorage.IE
    local IEMain = require(IEFolder.Main)

    IEMain:Run()
    IEMain:SetServerPackage("Audio", "Default")
    IEMain:SetServerPackage("Lighting", "Default")

    (Local script)

    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local IEFolder = ReplicatedStorage:WaitForChild("IE")
    local IEMain = require(IEFolder:WaitForChild("Main"))

    IEMain:Run()
]]

return module