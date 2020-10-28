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

return module
