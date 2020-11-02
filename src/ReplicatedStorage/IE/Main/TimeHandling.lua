local module = {}

local Lighting = game:GetService("Lighting")

local Main = script.Parent

local InternalSettings = require(Main.InternalSettings)

local IEFolder = Main.Parent

local Settings = require(IEFolder.Settings)

local function DayNightCycle()
    local DayRatio = (12 * 60) / Settings["TimeForDay"] --// Ratio of in-game minutes to real-life minutes
    local NightRatio = (12 * 60) / Settings["TimeForNight"] --// Ratio of in-game minutes to real-life minutes
    --// Note: for above, 12 = the 12 hours for each day/night period (ex: 0600-1800; 1800-0600) and 60 converts it to in-game minutes

    local TimesPerMin = 60 / InternalSettings["DayNightWait"]

    local MinutesToAddDay = DayRatio / TimesPerMin
    local MinutesToAddNight = NightRatio / TimesPerMin
end

function module.Run()
    if Settings["EnableDayNightTransitions"] == true then
        coroutine.wrap(DayNightCycle)()
    end
end

return module