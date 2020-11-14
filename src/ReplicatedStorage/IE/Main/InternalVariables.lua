local module = {
    --// Audio Variables
    ["HaltAudioCycle"] = false, --// Halts the audio cycle when a region is entered

    --// Lighting Variables
    ["HaltLightingCycle"] = false, --// Halts the lighting cycle when a region is entered
    ["InitializedLighting"] = false, --// Whether the Lighting script has initialized (to prevent Remote event duplication and module infintie reloading)
    ["Weather"] = false, --// Identifies whether weather is active

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

     --// Region Variables
     ["CurrentRegions"] = {}, --// Stores a dictionary with numerical indexes to indicate the order in which the region was joined (high numbers = joined more recently)
     ["CurrentRegionsQuick"] = {}, --// This is a table, not a dictionary, that just stores strings of RegionName so that table.find can be used quickly
     ["CurrentAudioRegions"] = 0, --// Number of the amount of audio regions the player is currently in
     ["CurrentLightingRegions"] = 0, --// Number of the amount of lighting regions the player is currently in
     ["Regions"] = {}, --// Stores Audio, Lighting, etc. regions 
}

return module