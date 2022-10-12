local module = {
	["GeneralSettings"] = {
		--// All times in 24 hour notation
	   ["StartTime"] = 6,
	   ["EndTime"] = 18,
	   
	   ["WeatherExemption"] = true,
   },

	["SoundService"] = {
		["AmbientReverb"] = Enum.ReverbType.UnderWater,
		["DistanceFactor"] = 40,
		["DopplerScale"] = 20,
		["RolloffScale"] = 20,
	},
	
	["SharedSounds"] = {
		
	},
	
	["RegionSounds"] = {
		["JingleBells"] = {
			["SoundId"] = "1842987882",
			
			["Set"] = {
				
			},
			
			["Tween"] = {
				["Volume"] = .5,
			},
		},
	},
	
	["RandomSounds"] = { --// These do not tween
		["Wow!"] = {
			["ChanceOfPlay"] = 10,
			["Frequency"] = .1,
			["SoundId"] = "4886488247",
			
			["Set"] = {
				["Volume"] = .25,
			}
		},
	},
}

return module
