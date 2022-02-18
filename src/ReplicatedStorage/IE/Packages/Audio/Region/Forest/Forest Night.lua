local module = {
	["GeneralSettings"] = {
		--// All times in 24 hour notation
	   ["StartTime"] = 18,
	   ["EndTime"] = 6,
	   
	   ["WeatherExemption"] = true,
   },

	["SoundService"] = {
		["AmbientReverb"] = Enum.ReverbType.UnderWater,
		["DistanceFactor"] = 40,
		["DopplerScale"] = 20,
		["RolloffScale"] = 20,
	},
	
	["SharedSounds"] = {
		["NarutoSound"] = {
			["SoundId"] = "946008702",
			
			["Set"] = {
				
			},
			
			["Tween"] = {
				["Volume"] = .2,
			},
		},
	},
	
	["RegionSounds"] = {
		["ForestAmbience"] = {
			["SoundId"] = "410408981",

			["Set"] = {

			},

			["Tween"] = {
				["Volume"] = .2,
			},
		},
	},
	
	["RandomSounds"] = { --// These do not tween
		["Gun shots"] = {
			["ChanceOfPlay"] = 10,
			["Frequency"] = .1,
			["SoundId"] = "680140087",
			
			["Set"] = {
				["Volume"] = .25,
			}
		},
	},
}

return module
