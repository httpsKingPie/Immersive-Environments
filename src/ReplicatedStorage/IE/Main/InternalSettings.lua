--// Do not touch unless you're modifying the script for you're one unique use.  These are not settings the average user should be customizing

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local function ReturnExistence(Location, ClassName)
	if ClassName == nil then
		return Lighting
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
	
	["CurrentRegions"] = {},
	
	["Initialized"] = false,
	
	["LightsActive"] = false,
	
	["NonPropertySettings"] = {
		"ChanceOfChange",
		"LightsOn",
	},
	
	["Regions"] = {}, --// Stores Audio, Lighting, etc. regions
	
	["SettingTablesBuilt"] = true,
	
	["SettingInstanceCorrelations"] = {
		["Atmosphere"] = ReturnExistence(Lighting, "Atmosphere"),
		["BloomEffect"] = ReturnExistence(Lighting, "BloomEffect"),
		["BlurEffect"] = ReturnExistence(Lighting, "BlurEffect"),
		["ColorCorrectionEffect"] = ReturnExistence(Lighting, "ColorCorrectionEffect"),
		["LightingService"] = ReturnExistence(Lighting),
		["Sky"] = ReturnExistence(Lighting, "Sky"),
		["SunRaysEffect"] = ReturnExistence(Lighting, "SunRaysEffect"),
		["Terrain"] = ReturnExistence(Workspace, "Terrain")
	},
	
	["TimeAdjusted"] = false,
	
	["TotalIndexes"] = 0,
	
	["Weather"] = false,
}

return module
