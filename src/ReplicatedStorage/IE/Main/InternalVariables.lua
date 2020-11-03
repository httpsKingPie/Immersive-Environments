local module = {
    ["CurrentRegions"] = {}, --// Stores a dictionary with numerical indexes to indicate the order in which the region was joined (high numbers = joined more recently)
	["CurrentRegionsQuick"] = {}, --// This is a table, not a dictionary, that just stores strings of RegionName so that table.find can be used quickly

    

    ["Regions"] = {}, --// Stores Audio, Lighting, etc. regions

    --// Lighting Variables

    ["InitializedLighting"] = false,
    ["TotalLightingIndexes"] = 0,
    ["Weather"] = false, --// Identifies whether weather is active

    

    --// Settings Variables

    ["LightingSettingTablesBuilt"] = false,

    --// Time variables

    ["DayAdjustmentRate"] = 0, --// The adjustment rate for the regions that start during the day-period
    ["NightAdjustmentRate"] = 0, --// The adjustment rate for the regions that start during the night-period
}

return module