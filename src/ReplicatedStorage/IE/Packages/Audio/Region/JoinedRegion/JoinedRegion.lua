local module = {
	["GeneralSettings"] = {
		--// All times in 24 hour notation
	   ["StartTime"] = 0,
	   ["EndTime"] = 0,
	   
	   ["WeatherExemption"] = true,
   },
	
	["SoundService"] = {
		["AmbientReverb"] = Enum.ReverbType.UnderWater,
		["DistanceFactor"] = 40,
		["DopplerScale"] = 20,
		["RolloffScale"] = 20,
	},
	
	["SharedSounds"] = {
		["Glow"] = {
			["SoundId"] = "7028856935",
			
			["Set"] = {
				
			},
			
			["Tween"] = {
				["Volume"] = .5,
			},
		},
	},
	
	["RegionSounds"] = {
		
	},
	
	["RandomSounds"] = { --// These do not tween
		
	},
}

return module
