local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedFunctions = require(ReplicatedStorage.IE.Main.SharedFunctions)

SharedFunctions.PlayerAdded(function(Player)
    SharedFunctions.CharacterAdded(Player, function(Character)
        for i, v in pairs (Character:GetDescendants()) do
            if v:IsA("BasePart") and v.Name ~= "UpperTorso" then
                v.Transparency = 1
            elseif v:IsA("Shirt") then
                v:Destroy()
            elseif v:IsA("Pants") then
                v:Destroy()
            elseif v:IsA("Accessory") then
                v:Destroy()
            end
        end
    end)
end)