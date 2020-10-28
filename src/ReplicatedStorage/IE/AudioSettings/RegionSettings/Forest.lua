local module = {
	["SoundService"] = {
		["AmbientReverb"] = Enum.ReverbType.UnderWater,
		["DistanceFactor"] = 40,
		["DopplerScale"] = 20,
		["RolloffScale"] = 20,
	},
	
	["ChangeSounds"] = {
		["SoundName"] = {
			["SoundId"] = "410408981",
			
			["Set"] = {
				
			},
			
			["Tween"] = {
				["Volume"] = .5,
			},
		},
	},
	
	["NewSounds"] = {
		["TestSoundName"] = {
			["SoundId"] = "410408981",

			["Set"] = {

			},

			["Tween"] = {
				["Volume"] = .5,
			},
		},
	},
	
	["RandomChanceSounds"] = {
		["SoundName"] = {
			["ChanceOfPlay"] = 100,
			["Frequency"] = 10,
			["SoundId"] = "410408981",
			["Volume"] = .5,
		},
	},
}

return module
