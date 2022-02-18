local module = {
	["GeneralSettings"] = {
		 --// All times in 24 hour notation
		["StartTime"] = 6,
		["EndTime"] = 18,
		
		["AdjustOnlyLightsOn"] = true,
		["WeatherExemption"] = true,
	},
	
	
	["Terrain"] = {
		["WaterColor"] = Color3.fromRGB(0, 0, 0),
	},
	
	--// Settings Related to the actual Lighting service
	["Atmosphere"] = {
		["Color"] = Color3.fromRGB(0, 0, 0),
		["Decay"] = Color3.fromRGB(0, 0, 0),	
	},
	
	["BloomEffect"] = {
		["Size"] = 0,
	},
	
	["BlurEffect"] = {
		["Size"] = 0,
	},
	
	["ColorCorrectionEffect"] = {
		["Brightness"] = 0,
		["TintColor"] = Color3.fromRGB(255, 115, 0),
	},
	
	["LightingService"] = {
		["Ambient"] = Color3.fromRGB(138, 138, 138),
		["GlobalShadows"] = true,
		
	},
	
	["Sky"] = {
		["StarCount"] = 0,
	},
	
	["SunRaysEffect"] = {
		["Intensity"] = 0,
	},
}

return module
