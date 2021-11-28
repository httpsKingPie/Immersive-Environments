local module = {
    ["GeneralSettings"] = {
		--// All times in 24 hour notation
	   ["StartTime"] = 0,
	   ["EndTime"] = 0,
	   
	   ["WeatherExemption"] = true,
   },
   
   ["ServerSounds"] = {
        ["Tanjiro"] = {
            ["SoundId"] = "4547798322",

			["Set"] = {

			},

			["Tween"] = {
				["Volume"] = .3,
			},
        },
   },

    ["SoundService"] = {
        ["AmbientReverb"] = Enum.ReverbType.UnderWater,
        ["DistanceFactor"] = 40,
        ["DopplerScale"] = 20,
        ["RolloffScale"] = 20,
    },
}

return module