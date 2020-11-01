local module = {
	["SoundService"] = {
		["AmbientReverb"] = Enum.ReverbType.UnderWater,
		["DistanceFactor"] = 40,
		["DopplerScale"] = 20,
		["RolloffScale"] = 20,
	},
	
	["SharedSounds"] = {
		["TestSound8"] = {
			["SoundId"] = "946008702",
			
			["Set"] = {
				
			},
			
			["Tween"] = {
				["Volume"] = .5,
			},
		},
	},
	
	["RegionSounds"] = {
		["TestSoundName"] = {
			["SoundId"] = "410408981",

			["Set"] = {

			},

			["Tween"] = {
				["Volume"] = .5,
			},
		},
	},
	
	["RandomSounds"] = { --// These do not tween
		["Gun shot"] = {
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
