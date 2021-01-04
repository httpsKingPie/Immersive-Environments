local Players = game:GetService("Players")

local RemoteCooldown = {}

local module = {}

function module.CheckProperty(InstanceToCheck, PropertyName)
	local Clone

	if InstanceToCheck:IsA("Terrain") == false and InstanceToCheck:IsA("Lighting") == false and InstanceToCheck:IsA("SoundService") == false then
		Clone = InstanceToCheck:Clone()
		Clone:ClearAllChildren()
	else
		Clone = InstanceToCheck
	end

	return (pcall(function()
		return Clone[PropertyName]
	end))
end

function module:RemoteCooldownTimer(RemoteName, PlayerName, Time)
	if RemoteCooldown[RemoteName] == nil then
		RemoteCooldown[RemoteName] = {}
	end
	
	if RemoteCooldown[RemoteName][PlayerName] == nil then
		RemoteCooldown[RemoteName][PlayerName] = tick()
		return true
	else
		if (tick() - RemoteCooldown[RemoteName][PlayerName]) > Time then
			RemoteCooldown[RemoteName][PlayerName] = tick()
			return true
		else
			return false
		end
	end
end

--// Just use regular PlayerRemoving - there's no way to really improve that one (that I know of atm)

function module.CharacterAdded(Player: Player, BoundFunction, ...)
	local Args = {...}
	
	if type(Player) ~= "userdata" or Player:IsA("Player") == false or Player.Parent == nil then
		warn("Invalid player instance provided as first argument")
		return
	end
	
	if type(BoundFunction) ~= "function" then
		warn("Pass a function as the second argument")
		return
	end
	
	if Player.Character then
		BoundFunction(Player.Character, table.unpack(Args))
		
		Player.CharacterAdded:Connect(function(Character)
			BoundFunction(Character, table.unpack(Args))
		end)
	end
	
	Player.CharacterAdded:Connect(function(Character)
		BoundFunction(Character, table.unpack(Args))
	end)
end

function module.DoesChange(ChanceOfChange: number)
	if ChanceOfChange == nil or ChanceOfChange == 100 then
		return true
	else	
		if math.random(1, 100) <= ChanceOfChange then
			return true
		else
			return false
		end
	end
end

math.randomseed(tick())

return module
