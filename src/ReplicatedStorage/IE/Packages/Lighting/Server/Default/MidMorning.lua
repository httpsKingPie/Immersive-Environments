local module = {
	["GeneralSettings"] = {
		 --// All times in 24 hour notation
		["StartTime"] = 8,
		["EndTime"] = 10,
		
		["AdjustOnlyLightsOn"] = true,
	},
	
	["Instances"] = {
		["BasePart"] = {
			["Tester"] = {
				["Material"] = Enum.Material.CorrodedMetal,
				["Color"] = Color3.fromRGB(0, 255, 0),
				["ChanceOfChange"] = 100,
				["IsLight"] = true,
				["IsLightOn"] = true,
			},
		},
		
		["PointLight"] = {
			["Instance1Name"] = {
				["Brightness"] = 0,
				["Color"] = Color3.fromRGB(0, 0, 0),
				["Enabled"] = true,
				["Range"] = 0,
				["ChanceOfChange"] = 100,
				["IsLight"] = true,
				["IsLightOn"] = true,
			},
		},
		
		["SpotLight"] = {
			["Instance1Name"] = {
				["Angle"] = 0,
				["Brightness"] = 0,
				["Color"] = Color3.fromRGB(0, 0, 0),
				["Enabled"] = true,
				["Face"] = Enum.NormalId.Front,
				["Range"] = 0,
				["ChanceOfChange"] = 100,
				["IsLight"] = true,
				["IsLightOn"] = true,
			},
		},
		
		["SurfaceLight"] = {
			["Instance1Name"] = {
				["Angle"] = 0,
				["Brightness"] = 0,
				["Color"] = Color3.fromRGB(0, 0, 0),
				["Enabled"] = true,
				["Face"] = Enum.NormalId.Front,
				["Range"] = 0,
				["ChanceOfChange"] = 100,
				["IsLight"] = true,
				["IsLightOn"] = true,
			},
		},
		
		["Fire"] = {
			["Instance1Name"] = {
				["Color"] = Color3.fromRGB(0, 0, 0),
				["Enabled"] = true,
				["Heat"] = 0,
				["SecondaryColor"] = Color3.fromRGB(0, 0, 0),
				["Size"] = 0,
				["ChanceOfChange"] = 100,
				["IsLight"] = true,
				["IsLightOn"] = true,
			},
		},
		
		["ParticleEmitter"] = {
			["Instance1Name"] = {
				["LightEmission"] = 0,
				["LightInfluence"] = 0,
				["ZOffset"] = 0,
				["Acceleration"] = Vector3.new(0, 0, 0),
				["Drag"] = 0,
				["VelocityInheritance"] = 0,
				["EmissionDirection"] = Enum.NormalId.Top,
				["Enabled"] = true,
				["Lifetime"] = NumberRange.new(0, 10),
				["Rate"] = 0,
				["Rotation"] = NumberRange.new(0, 10),
				["RotSpeed"] = NumberRange.new(0, 10),
				["Speed"] = NumberRange.new(0, 10),
				["SpreadAngle"] = Vector2.new(0, 0),
				["ChanceOfChange"] = 100,
				["IsLight"] = true,
				["IsLightOn"] = true,
			},
		}
	},
	
	["ComplexInstances"] = {
		["RefPart"] = { --// No changes occur to the reference part
			
			["GeneralSettings"] = {
				["ChanceOfChange"] = 100, --// These are not classes, so adjust this
				["IsLight"] = true,
				["IsLightOn"] = true,
			},
			
			["Self"] = {
				["BasePart"] = {
					["Instance1Name"] = {
						["Material"] = Enum.Material.SmoothPlastic,
						["Color"] = Color3.fromRGB(0, 0, 0),
					},
				},
				
				["PointLight"] = {
					["PointTest"] = {
						["Brightness"] = 0,
						["Color"] = Color3.fromRGB(0, 0, 0),
						["Enabled"] = true,
						["Range"] = 0,
					},
				},
				
				["SpotLight"] = {
					["SpotTest"] = {
						["Angle"] = 0,
						["Brightness"] = 0,
						["Color"] = Color3.fromRGB(0, 0, 0),
						["Enabled"] = true,
						["Face"] = Enum.NormalId.Front,
						["Range"] = 0,
					},
				},
				
				["SurfaceLight"] = {
					["SurfTest"] = {
						["Angle"] = 0,
						["Brightness"] = 0,
						["Color"] = Color3.fromRGB(0, 0, 0),
						["Enabled"] = true,
						["Face"] = Enum.NormalId.Front,
						["Range"] = 0,
					},
				},
				
				["Fire"] = {
					["FireTest"] = {
						["Color"] = Color3.fromRGB(0, 0, 0),
						["Enabled"] = true,
						["Heat"] = 0,
						["SecondaryColor"] = Color3.fromRGB(0, 0, 0),
						["Size"] = 0,
					},
				},
				
				["ParticleEmitter"] = {
					["PartTest"] = {
						["LightEmission"] = 0,
						["LightInfluence"] = 0,
						["ZOffset"] = 0,
						["Acceleration"] = Vector3.new(0, 0, 0),
						["Drag"] = 0,
						["VelocityInheritance"] = 0,
						["EmissionDirection"] = Enum.NormalId.Top,
						["Enabled"] = true,
						["Lifetime"] = NumberRange.new(0, 10),
						["Rate"] = 0,
						["Rotation"] = NumberRange.new(0, 10),
						["RotSpeed"] = NumberRange.new(0, 10),
						["Speed"] = NumberRange.new(0, 10),
						["SpreadAngle"] = Vector2.new(0, 0),
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
					["PointTest"] = {
						["Brightness"] = 0,
						["Color"] = Color3.fromRGB(0, 0, 0),
						["Enabled"] = true,
						["Range"] = 0,
					},
				},
				
				["SpotLight"] = {
					["SpotTest"] = {
						["Angle"] = 0,
						["Brightness"] = 0,
						["Color"] = Color3.fromRGB(0, 0, 0),
						["Enabled"] = true,
						["Face"] = Enum.NormalId.Front,
						["Range"] = 0,
					},
				},
				
				["SurfaceLight"] = {
					["SurfTest"] = {
						["Angle"] = 0,
						["Brightness"] = 0,
						["Color"] = Color3.fromRGB(0, 0, 0),
						["Enabled"] = true,
						["Face"] = Enum.NormalId.Front,
						["Range"] = 0,
					},
				},
				
				["Fire"] = {
					["FireTest"] = {
						["Color"] = Color3.fromRGB(0, 0, 0),
						["Enabled"] = true,
						["Heat"] = 0,
						["SecondaryColor"] = Color3.fromRGB(0, 0, 0),
						["Size"] = 0,
					},
				},
				
				["ParticleEmitter"] = {
					["PartTest"] = {
						["LightEmission"] = 0,
						["LightInfluence"] = 0,
						["ZOffset"] = 0,
						["Acceleration"] = Vector3.new(0, 0, 0),
						["Drag"] = 0,
						["VelocityInheritance"] = 0,
						["EmissionDirection"] = Enum.NormalId.Top,
						["Enabled"] = true,
						["Lifetime"] = NumberRange.new(0, 10),
						["Rate"] = 0,
						["Rotation"] = NumberRange.new(0, 10),
						["RotSpeed"] = NumberRange.new(0, 10),
						["Speed"] = NumberRange.new(0, 10),
						["SpreadAngle"] = Vector2.new(0, 0),
					},
				},
			},
			
			["Descendant"] = {
				["BasePart"] = {
					["Instance1Name"] = {
						["Material"] = Enum.Material.SmoothPlastic,
						["Color"] = Color3.fromRGB(0, 0, 0),
					},
				},
				
				["PointLight"] = {
					["PointTest"] = {
						["Brightness"] = 0,
						["Color"] = Color3.fromRGB(0, 0, 0),
						["Enabled"] = true,
						["Range"] = 0,
					},
				},
				
				["SpotLight"] = {
					["SpotTest"] = {
						["Angle"] = 0,
						["Brightness"] = 0,
						["Color"] = Color3.fromRGB(0, 0, 0),
						["Enabled"] = true,
						["Face"] = Enum.NormalId.Front,
						["Range"] = 0,
					},
				},
				
				["SurfaceLight"] = {
					["SurfTest"] = {
						["Angle"] = 0,
						["Brightness"] = 0,
						["Color"] = Color3.fromRGB(0, 0, 0),
						["Enabled"] = true,
						["Face"] = Enum.NormalId.Front,
						["Range"] = 0,
					},
				},
				
				["Fire"] = {
					["FireTest"] = {
						["Color"] = Color3.fromRGB(0, 0, 0),
						["Enabled"] = true,
						["Heat"] = 0,
						["SecondaryColor"] = Color3.fromRGB(0, 0, 0),
						["Size"] = 0,
					},
				},
				
				["ParticleEmitter"] = {
					["PartTest"] = {
						["LightEmission"] = 0,
						["LightInfluence"] = 0,
						["ZOffset"] = 0,
						["Acceleration"] = Vector3.new(0, 0, 0),
						["Drag"] = 0,
						["VelocityInheritance"] = 0,
						["EmissionDirection"] = Enum.NormalId.Top,
						["Enabled"] = true,
						["Lifetime"] = NumberRange.new(0, 10),
						["Rate"] = 0,
						["Rotation"] = NumberRange.new(0, 10),
						["RotSpeed"] = NumberRange.new(0, 10),
						["Speed"] = NumberRange.new(0, 10),
						["SpreadAngle"] = Vector2.new(0, 0),
					},
				},
			},
			
			["Parent"] = {
				["BasePart"] = {
					["Instance1Name"] = {
						["Material"] = Enum.Material.SmoothPlastic,
						["Color"] = Color3.fromRGB(0, 0, 0),
					},
				},
				
				["PointLight"] = {
					["PointTest"] = {
						["Brightness"] = 0,
						["Color"] = Color3.fromRGB(0, 0, 0),
						["Enabled"] = true,
						["Range"] = 0,
					},
				},
				
				["SpotLight"] = {
					["SpotTest"] = {
						["Angle"] = 0,
						["Brightness"] = 0,
						["Color"] = Color3.fromRGB(0, 0, 0),
						["Enabled"] = true,
						["Face"] = Enum.NormalId.Front,
						["Range"] = 0,
					},
				},
				
				["SurfaceLight"] = {
					["SurfTest"] = {
						["Angle"] = 0,
						["Brightness"] = 0,
						["Color"] = Color3.fromRGB(0, 0, 0),
						["Enabled"] = true,
						["Face"] = Enum.NormalId.Front,
						["Range"] = 0,
					},
				},
				
				["Fire"] = {
					["FireTest"] = {
						["Color"] = Color3.fromRGB(0, 0, 0),
						["Enabled"] = true,
						["Heat"] = 0,
						["SecondaryColor"] = Color3.fromRGB(0, 0, 0),
						["Size"] = 0,
					},
				},
				
				["ParticleEmitter"] = {
					["PartTest"] = {
						["LightEmission"] = 0,
						["LightInfluence"] = 0,
						["ZOffset"] = 0,
						["Acceleration"] = Vector3.new(0, 0, 0),
						["Drag"] = 0,
						["VelocityInheritance"] = 0,
						["EmissionDirection"] = Enum.NormalId.Top,
						["Enabled"] = true,
						["Lifetime"] = NumberRange.new(0, 10),
						["Rate"] = 0,
						["Rotation"] = NumberRange.new(0, 10),
						["RotSpeed"] = NumberRange.new(0, 10),
						["Speed"] = NumberRange.new(0, 10),
						["SpreadAngle"] = Vector2.new(0, 0),
					},
				},
			},
			
			["Sibling"] = {
				["BasePart"] = {
					["Instance1Name"] = {
						["Material"] = Enum.Material.SmoothPlastic,
						["Color"] = Color3.fromRGB(0, 0, 0),
					},
				},
				
				["PointLight"] = {
					["PointTest"] = {
						["Brightness"] = 0,
						["Color"] = Color3.fromRGB(0, 0, 0),
						["Enabled"] = true,
						["Range"] = 0,
					},
				},
				
				["SpotLight"] = {
					["SpotTest"] = {
						["Angle"] = 0,
						["Brightness"] = 0,
						["Color"] = Color3.fromRGB(0, 0, 0),
						["Enabled"] = true,
						["Face"] = Enum.NormalId.Front,
						["Range"] = 0,
					},
				},
				
				["SurfaceLight"] = {
					["SurfTest"] = {
						["Angle"] = 0,
						["Brightness"] = 0,
						["Color"] = Color3.fromRGB(0, 0, 0),
						["Enabled"] = true,
						["Face"] = Enum.NormalId.Front,
						["Range"] = 0,
					},
				},
				
				["Fire"] = {
					["FireTest"] = {
						["Color"] = Color3.fromRGB(0, 0, 0),
						["Enabled"] = true,
						["Heat"] = 0,
						["SecondaryColor"] = Color3.fromRGB(0, 0, 0),
						["Size"] = 0,
					},
				},
				
				["ParticleEmitter"] = {
					["PartTest"] = {
						["LightEmission"] = 0,
						["LightInfluence"] = 0,
						["ZOffset"] = 0,
						["Acceleration"] = Vector3.new(0, 0, 0),
						["Drag"] = 0,
						["VelocityInheritance"] = 0,
						["EmissionDirection"] = Enum.NormalId.Top,
						["Enabled"] = true,
						["Lifetime"] = NumberRange.new(0, 10),
						["Rate"] = 0,
						["Rotation"] = NumberRange.new(0, 10),
						["RotSpeed"] = NumberRange.new(0, 10),
						["Speed"] = NumberRange.new(0, 10),
						["SpreadAngle"] = Vector2.new(0, 0),
					},
				},
			},
		},
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
		["Size"] = 20,
	},
	
	["ColorCorrectionEffect"] = {
		["Brightness"] = 0,
		["Contrast"] = 0,
		["Enabled"] = true,
		["Saturation"] = 0,
		["TintColor"] = Color3.fromRGB(8, 233, 165),
	},
	
	["LightingService"] = {
		["Ambient"] = Color3.fromRGB(8, 233, 165),
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
