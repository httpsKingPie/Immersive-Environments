local module = {
    ["GeneralSettings"] = {
        --// All times in 24 hour notation
       ["StartTime"] = 0,
       ["EndTime"] = 12,
   },

   ["ServerSounds"] = {
        ["Fantasy"] = {
            ["SoundId"] = "1844494894",

			["Set"] = {

			},

			["Tween"] = {
				["Volume"] = .4,
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