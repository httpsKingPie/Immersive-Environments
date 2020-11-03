local module = {}

local Lighting = game:GetService("Lighting")

local Main = script.Parent

local InternalSettings = require(Main.InternalSettings)
local InternalVariables = require(Main.InternalVariables)

local IEFolder = Main.Parent

local Settings = require(IEFolder.Settings)

local function DayNightCycle()
    local DayRatio = (12 * 60) / Settings["TimeForDay"] --// Ratio of in-game minutes to real-life minutes
    local NightRatio = (12 * 60) / Settings["TimeForNight"] --// Ratio of in-game minutes to real-life minutes
    --// Note: for above, 12 = the 12 hours for each day/night period (ex: 0600-1800; 1800-0600) and 60 converts it to in-game minutes

    local ActiviationPerMinute = 60 / InternalSettings["DayNightWait"] --// The amount of times the script activates in one minute (real life)

    local MinutesToAddDay = DayRatio / ActiviationPerMinute
    local MinutesToAddNight = NightRatio / ActiviationPerMinute
    --// Note: for above, the ratio tells how many in-game minutes pass per real life minute, and divides it by the amount of activates per real life minute = conversion of in-game minutes per activation

    InternalVariables["DayAdjustmentRate"] = DayRatio / (60^2) * Settings["LightingTweenInformation"].Time
    InternalVariables["NightAdjustmentRate"] = NightRatio / (60^2) * Settings["LightingTweenInformation"].Time
    --// Note: above are measured in in-game hours/real life second

    while true do
        wait(InternalSettings["DayNightWait"]) do
            if Lighting.ClockTime > 18 or Lighting.ClockTime < 6 then --// Night time
                Lighting:SetMinutesAfterMidnight(Lighting:GetMinutesAfterMidnight() + MinutesToAddNight)
            else --// Day time
                Lighting:SetMinutesAfterMidnight(Lighting:GetMinutesAfterMidnight() + MinutesToAddDay)
            end
        end
    end
end

function module.Run()
    if Settings["EnableDayNightTransitions"] == true then
        coroutine.wrap(DayNightCycle)()
    end
end

return module