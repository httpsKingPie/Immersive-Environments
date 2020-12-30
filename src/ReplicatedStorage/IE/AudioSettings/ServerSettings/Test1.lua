local module = {
    ["GeneralSettings"] = {
        --// All times in 24 hour notation
       ["StartTime"] = 0,
       ["EndTime"] = 12,
   },

   ["ServerSounds"] = {
        ["Arethusa"] = {
            ["SoundId"] = "188758083",

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