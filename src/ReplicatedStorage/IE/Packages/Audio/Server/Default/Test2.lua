local module = {
    ["GeneralSettings"] = {
        --// All times in 24 hour notation
       ["StartTime"] = 12,
       ["EndTime"] = 0,
   },

   ["ServerSounds"] = {
        ["Symphony"] = {
            ["SoundId"] = "1843310641",

            ["Set"] = {

			},

			["Tween"] = {
				["Volume"] = .2,
			},
        },
    },

    ["SoundService"] = {
        ["AmbientReverb"] = Enum.ReverbType.ConcertHall,
        ["DistanceFactor"] = 100,
        ["DopplerScale"] = 10,
        ["RolloffScale"] = 10,
    },
}

return module