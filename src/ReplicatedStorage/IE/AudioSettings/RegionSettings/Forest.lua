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
	
	["RandomChanceSounds"] = { --// These do not tween
		["SoundName"] = {
			["ChanceOfPlay"] = 100,
			["Frequency"] = 10,
			["SoundId"] = "410408981",
			
			["Set"] = {
				["Volume"] = .5,
			}
		},
	},
}

return module
