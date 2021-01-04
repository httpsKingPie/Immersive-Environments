local module = {
	["GeneralSettings"] = {
		 --// All times in 24 hour notation
		["StartTime"] = 12,
		["EndTime"] = 16,
		
		["AdjustOnlyLightsOn"] = false,
		["WeatherExemption"] = true, --// This setting is only used for regions - feel free to delete if this is not a region setting.  If you want these settings to apply, even when there is weather, set this to true.  Read the Weather section of the IE documentation site (https://httpskingpie.github.io/Immersive-Environments/) for more info.
	},
	
	["Instances"] = {
		["BasePart"] = {
			["Instance1Name"] = {
				["Material"] = Enum.Material.CorrodedMetal,
				["Color"] = Color3.fromRGB(0, 255, 0),
				["ChanceOfChange"] = 100,
				["IsLight"] = true,
				["IsLightOn"] = true,
			},
		},
	},
	
	["ComplexInstances"] = {
		["RefPart1Name"] = { --// No changes occur to the reference part
			
			["GeneralSettings"] = {
				["ChanceOfChange"] = 100, --// These are not classes, so adjust this
				["IsLight"] = true,
				["IsLightOn"] = true,
			},
			
			["Self"] = {
				["Fire"] = {
					["Instance1Name"] = {
						["Color"] = Color3.fromRGB(0, 0, 0),
						["Size"] = 0,
					},
				},
			},
			
			["Child"] = {
				["BasePart"] = {
					["Instance1Name"] = {
						["Material"] = Enum.Material.SmoothPlastic,
						["Color"] = Color3.fromRGB(0, 0, 0),
					},
				},
				
				["PointLight"] = {
					["Instance1Name"] = {
						["Brightness"] = 0,
						["Color"] = Color3.fromRGB(0, 0, 0),
						["Enabled"] = true,
						["Range"] = 0,
					},
				},
			},
			
			["Descendant"] = {
				["BasePart"] = {
					["Instance1Name"] = {
						["Color"] = Color3.fromRGB(0, 0, 0),
					},
				},
			},
			
			["Parent"] = {
				["SurfaceLight"] = {
					["Instance1Name"] = {
						["Angle"] = 0,
						["Brightness"] = 0,
						["Range"] = 0,
					},
				},
			},
			
			["Sibling"] = {
				["ParticleEmitter"] = {
					["Instance1Name"] = {
						["LightEmission"] = 0,
					},
				},
			},
		},
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
		["TintColor"] = Color3.fromRGB(0, 0, 0),
	},
	
	["LightingService"] = {
		["Ambient"] = Color3.fromRGB(0, 0, 0),
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
