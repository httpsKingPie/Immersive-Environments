local module = {
	["WeatherExemption"] = true, --// This setting is only used for regions - feel free to delete if this is not a region setting.  If you want these settings to apply, even when there is weather, set this to true.  Read the Weather section of the IE documentation site (https://httpskingpie.github.io/Immersive-Environments/) for more info.

	["SoundService"] = {
		["AmbientReverb"] = Enum.ReverbType.NoReverb,
		["DistanceFactor"] = 0,
		["DopplerScale"] = 0,
		["RolloffScale"] = 0,
    },
    
    ["ServerSounds"] = {
        ["ServerSound1"] = {
            ["SoundId"] = "11111111111",

			["Set"] = {

			},

			["Tween"] = {
				["Volume"] = .4,
			},
        },
   },
	
	["SharedSounds"] = {
		["SharedSound1"] = {
			["SoundId"] = "11111111111",
			
			["Set"] = {
				
			},
			
			["Tween"] = {
				["Volume"] = .5,
			},
		},
	},
	
	["RegionSounds"] = {
		["RegionSound1"] = {
			["SoundId"] = "11111111111",

			["Set"] = {

			},

			["Tween"] = {
				["Volume"] = .5,
			},
		},
	},
	
	["RandomSounds"] = { --// These do not tween
		["RandomSoundName"] = {
			["ChanceOfPlay"] = 10,
			["Frequency"] = .1,
			["SoundId"] = "11111111111",
			
			["Set"] = {
				["Volume"] = .25,
			}
		},
	},
}

return module
