--// Do not touch unless you're modifying the script for you're one unique use.  These are not settings the average user should be customizing

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local function ReturnExistence(Location, ClassName)
	if ClassName == nil then
		return Location
	end
	
	local AInstance = Location:FindFirstChildWhichIsA(ClassName)
	
	if AInstance then
		return AInstance
	else
		return false --// False denotes that it is in this category but is not currently found
	end
end

local module = {
	["AlwaysSet"] = {
		"AmbientReverb",
		"Face",
		"EmissionDirection",
		"Material",
		"MoonTextureId",
		"SkyboxBk",
		"SkyboxDn",
		"SkyboxFt",
		"SkyboxLf",
		"SkyboxRt",
		"SkyboxUp",
		"Speed",
		"SunTextureId",
		"Texture",
	},
	
	["AlwaysSetClass"] = {
		["ParticleEmitter"] = {
			"Lifetime",
			"Rotation",
			"RotSpeed",
			"Speed",
		},
	},
	
	["AssetPrefix"] = "rbxassetid://",
	
	["BlacklistedSettings"] = {
		"ClockTime",
		"Decoration",
		"LockedToPart",
		"TimeOfDay",
		"Technology",
	},
	
	["BlacklistedSettingsClass"] = {
		["ParticleEmitter"] = {
			--// Gets angry even when setting to legitimate values (basically it hates ColorSequences and NumberSequences >_<)
			"Color", 
			"Size",
			"Transparency",
		},
		
		["Sound"] = {
			"EmitterSize",
			"IsLoaded",
			"IsPaused",
			"IsPlaying",
			"MaxDistance",
			"PlaybackLoudness",
			"Playing",
			"RollOffMode",
			"TimeLength",
		},
	},
	
	["DayNightCheck"] = 5, --// In seconds, the amount of time the script checks for whether times need to be adjusted (used for when Day and Night in-game time passage occur at different rates)
	
	["DayNightWait"] = 1,

	["RemoteInitializationMaxTries"] = 50, --// Remote checkss every .2 seconds.  100 tries = 20 seconds.
	
	["NonPropertySettings"] = {
		"ChanceOfChange",
		"LightsOn",
	},
	
	["SettingInstanceCorrelations"] = {
		["Atmosphere"] = ReturnExistence(Lighting, "Atmosphere"),
		["BloomEffect"] = ReturnExistence(Lighting, "BloomEffect"),
		["BlurEffect"] = ReturnExistence(Lighting, "BlurEffect"),
		["ColorCorrectionEffect"] = ReturnExistence(Lighting, "ColorCorrectionEffect"),
		["DepthOfFieldEffect"] = ReturnExistence(Lighting, "DepthOfFieldEffect"),
		["LightingService"] = ReturnExistence(Lighting),
		["Sky"] = ReturnExistence(Lighting, "Sky"),
		["SunRaysEffect"] = ReturnExistence(Lighting, "SunRaysEffect"),
		["Terrain"] = ReturnExistence(Workspace, "Terrain")
	},
	
	["Weather"] = false,
}

return module
