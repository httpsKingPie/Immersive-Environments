local module = {
    --// Audio Variables
    ["HaltAudioCycle"] = false, --// Halts the audio cycle when a region is entered

    --// Lighting Variables
    ["HaltLightingCycle"] = false, --// Halts the lighting cycle when a region is entered
    ["InitializedLighting"] = false,
    ["TotalLightingIndexes"] = 0,
    ["Weather"] = false, --// Identifies whether weather is active

    --// Settings Variables

    ["LightingSettingTablesBuilt"] = false,

    --// Time variables

    ["DayAdjustmentRate"] = 0, --// The adjustment rate for the regions that start during the day-period
    ["NightAdjustmentRate"] = 0, --// The adjustment rate for the regions that start during the night-period

     --// Region Variables
     ["CurrentRegions"] = {}, --// Stores a dictionary with numerical indexes to indicate the order in which the region was joined (high numbers = joined more recently)
     ["CurrentRegionsQuick"] = {}, --// This is a table, not a dictionary, that just stores strings of RegionName so that table.find can be used quickly
     ["CurrentAudioRegions"] = 0, --// Number of the amount of audio regions the player is currently in
     ["CurrentLightingRegions"] = 0, --// Number of the amount of lighting regions the player is currently in
     ["Regions"] = {}, --// Stores Audio, Lighting, etc. regions 
}

return module