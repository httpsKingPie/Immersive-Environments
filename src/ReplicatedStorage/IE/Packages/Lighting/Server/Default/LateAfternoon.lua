local module = {
	["GeneralSettings"] = {
		 --// All times in 24 hour notation
		["StartTime"] = 16,
		["EndTime"] = 18,
		
		["AdjustOnlyLightsOn"] = false,
	},
	
	["Instances"] = {
		
	},

	["ComplexInstances"] = {
		
	},
	
	["Terrain"] = {
		["WaterColor"] = Color3.fromRGB(0, 0, 0),
		["WaterReflectance"] = 0,
		["WaterTransparency"] = 0,
		["WaterWaveSize"] = 0,
		["WaterWaveSpeed"] = 0,
	},
	
	--// Settings Related to the actual Lighting service
	["Atmosphere"] = {
		["Density"] = 0,
		["Offset"] = 0,
		
		["Color"] = Color3.fromRGB(0, 0, 0),
		["Decay"] = Color3.fromRGB(0, 0, 0),
		
		["Glare"] = 0,
		["Haze"] = 1,		
	},
	
	["BloomEffect"] = {
		["Enabled"] = true,
		["Intensity"] = 0,
		["Size"] = 0,
		["Threshold"] = 0,
	},
	
	["BlurEffect"] = {
		["Enabled"] = true,
		["Size"] = 12,
	},
	
	["ColorCorrectionEffect"] = {
		["Brightness"] = 0,
		["Contrast"] = 0,
		["Enabled"] = true,
		["Saturation"] = 0,
		["TintColor"] = Color3.fromRGB(195, 25, 110),
	},
	
	["LightingService"] = {
		["Ambient"] = Color3.fromRGB(195, 25, 110),
		["Brightness"] = 0,
		["ColorShift_Bottom"] = Color3.fromRGB(0, 0, 0),
		["ColorShift_Top"] = Color3.fromRGB(0, 0, 0),
		["EnvironmentDiffuseScale"] = 0,
		["EnvironmentSpecularScale"] = 0,
		["GlobalShadows"] = true,
		["OutdoorAmbient"] = Color3.fromRGB(0, 0, 0),
		["ShadowSoftness"] = 0,
		["GeographicLatitude"] = 0,
		
	},
	
	["Sky"] = {
		["MoonAngularSize"] = 0,
		["StarCount"] = 0,
		["SunAngularSize"] = 0,
	},
	
	["SunRaysEffect"] = {
		["Enabled"] = true,
		["Intensity"] = 0,
		["Spread"] = 0,
	},
}

return module
