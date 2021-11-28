local module = {
    --// The adjustment rate for the regions that start during the day or night period
    ["Adjustment Rate"] = {
        ["Day"] = 0,
        ["Night"] = 0,
    },

    --// Populated by strings, identifies the name of the Adjusted Time Period that the Player is in
    ["Current Adjusted Period"] = {
        ["Audio"] = "",
        ["Lighting"] = "",
    },

    --// Populated by strings, identifies the current component (not necessarily the active one - that depends on the scope)
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

    --// Current index of the Time Period (used for sorted check cycles)
    ["Current Index"] = {
        ["Audio"] = 0,
        ["Lighting"] = 0,
    },

    --// Populated by strings, identifies the current package
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

    --// Populated by strings, identifies the Time Period that the Player is in
    ["Current Period"] = {
        ["Audio"] = "",
        ["Lighting"] = "",
    },

    --// Stores a simple table (numerical indexes) to indicate the order in which the region was joined (high numbers = joined more recently)
    ["Current Regions"] = {
        ["Audio"] = {},
        ["Lighting"] = {},
    },

    --// This is a dictionary that inverts the order of ["Current Regions"] (so that indexes are values, and vice versa) to quickly find the indexes of regions
    ["Current Regions Quick"] = {
        ["Audio"] = {},
        ["Lighting"] = {},
    },

    --// This will be Region, Server, or Weather (defaults to Server until manually changed)
    ["Current Scope"] = {
        ["Audio"] = "Server",
        ["Lighting"] = "Server"
    },

    --// Used to identify the next period to look for in a sorted check cycle
    ["Next Index"] = {
        ["Audio"] = 0,
        ["Lighting"] = 0,
    },

    --// Populated by strings (filled in when weather is added, so that things can quickly resync back)
    ["Non Weather Package"] = {
        ["Audio"] = false,
        ["Lighting"] = false,
    },

    --// Tracks whether these have been initialized
    ["Initialized"] = {
        ["Audio"] = false,
        ["Lighting"] = false,
        ["Packages"] = false,
        ["Time"] = false,
    },

    --// Stores Audio and Lighting Regions
    ["Regions"] = {
        ["Audio"] = {},
        ["Lighting"] = {},
    },

    --// Whether there is currently a weather exemption (based on region)
    ["Weather Exemption"] = {
        ["Audio"] = false,
        ["Lighting"] = false,
    },

    --// Old variables

    --// Audio Variables
    ["CurrentAudioWeather"] = "", --// Identifies which weather setting is currently being used (audio)
    ["AudioWeather"] = false, --// Identifies whether audio weather settings are active

    --// Lighting Variables
    ["CurrentLightingWeather"] = "", --// Identifies which weather setting is currently being used (lighting)
    ["LightingWeather"] = false, --// Identifies whether lighting weather are active

    --// Settings Variables
    ["LightingSettingTablesBuilt"] = false,
    
    ["TotalAudioIndexes"] = 0, --// Used for sorted check cycles to know what index to look for next
    ["TotalLightingIndexes"] = 0, --// Used for sorted check cycles to know what index to look for next
}

return module