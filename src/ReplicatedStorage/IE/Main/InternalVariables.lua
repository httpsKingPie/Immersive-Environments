local module = {
    --// New variables
    
    --// Populated by strings
    ["Current Package"] = {
        ["Audio"] = {
            ["Region"] = false,
            ["Server"] = false,
            ["Weather"] = false,
        },
        ["Lighting"] = {
            ["Region"] = false,
            ["Server"] = false,
            ["Weather"] = false,
        },
    },

    --// Populated by strings
    ["Current Component"] = {
        ["Audio"] = {
            ["Region"] = false,
            ["Server"] = false,
            ["Weather"] = false,
        },
        ["Lighting"] = {
            ["Region"] = false,
            ["Server"] = false,
            ["Weather"] = false,
        },
    },

    --// This will be Region, Server, or Weather (defaults to Server until manually changed)
    ["Current Scope"] = {
        ["Audio"] = "Server",
        ["Lighting"] = "Server"
    },

    --// Populated by strings (filled in when weather is added, so that things can quickly resync back)
    ["Non Weather Package"] = {
        ["Audio"] = false,
        ["Lighting"] = false,
    },

    --// Old variables

    --// Audio Variables
    ["CurrentAudioWeather"] = "", --// Identifies which weather setting is currently being used (audio)
    ["HaltAudioCycle"] = false, --// Halts the audio cycle when a region is entered (this is only used and viewed by the client)
    ["InitializedAudio"] = false, --// Whether the Lighting script has initialized (to prevent Remote event duplication and module infintie reloading)
    ["AudioWeather"] = false, --// Identifies whether audio weather settings are active

    --// Lighting Variables
    ["CurrentLightingWeather"] = "", --// Identifies which weather setting is currently being used (lighting)
    ["HaltLightingCycle"] = false, --// Halts the lighting cycle when a region is entered (this is only used and viewed by the client)
    ["InitializedLighting"] = false, --// Whether the Lighting script has initialized (to prevent Remote event duplication and module infintie reloading)
    ["LightingWeather"] = false, --// Identifies whether lighting weather are active

    --// Settings Variables

    ["AudioSettingTablesBuilt"] = false,
    ["LightingSettingTablesBuilt"] = false,

    --// Time variables
    ["CurrentAudioAdjustedPeriod"] = "", --// Current string name of the AdjustedTimePeriod that the Player is in
    ["CurrentLightingAdjustedPeriod"] = "", --// Current string name of the AdjustedTimePeriod that the Player is in

    ["CurrentAudioIndex"] = 0, --// Current index of the TimePeriod (used for sorted check cycles)
    ["CurrentLightingIndex"] = 0, --// Current index of the TimePeriod (used for sorted check cycles)

    ["CurrentAudioPeriod"] = "", --// Current string name of the TimePeriod that the Player is in
    ["CurrentLightingPeriod"] = "", --// Current string name of the TimePeriod that the Player is in

    ["DayAdjustmentRate"] = 0, --// The adjustment rate for the regions that start during the day-period
    ["NightAdjustmentRate"] = 0, --// The adjustment rate for the regions that start during the night-period

    ["InitializedTime"] = false, --// Whether the Audio script has initialized (to prevent module infinite reloading)

    ["NextAudioIndex"] = 0, --// Used to identify the next period to look for in a sorted check cycle
    ["NextLightingIndex"] = 0, --// Used to identify the next period to look for in a sorted check cycle
    
    ["TotalAudioIndexes"] = 0, --// Used for sorted check cycles to know what index to look for next
    ["TotalLightingIndexes"] = 0, --// Used for sorted check cycles to know what index to look for next

    ["TimeInitialized"] = false, --// Turns to true once TimeHandling has finished initialization

     --// Region Variables
     ["CurrentRegions"] = {}, --// Stores a dictionary with numerical indexes to indicate the order in which the region was joined (high numbers = joined more recently)
     ["CurrentRegionsQuick"] = {}, --// This is a table, not a dictionary, that just stores strings of RegionName so that table.find can be used quickly
    
     ["CurrentAudioRegions"] = 0, --// Number of the amount of audio regions the player is currently in
     ["CurrentLightingRegions"] = 0, --// Number of the amount of lighting regions the player is currently in
     
     ["Regions"] = {}, --// Stores Audio, Lighting, etc. regions 
}

return module