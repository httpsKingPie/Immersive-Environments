local module = {
    ["AudioAdjustedTimePeriods"] = {},
    ["AudioTimePeriods"] = {},
   
    ["LightingAdjustedTimePeriods"] = {},
    ["LightingTimePeriods"] = {},
}

local Lighting = game:GetService("Lighting")

local Main = script.Parent

local InternalSettings = require(Main.InternalSettings)
local InternalVariables = require(Main.InternalVariables)
local SettingsHandling = require(Main.SettingsHandling)

local IEFolder = Main.Parent

local Settings = require(IEFolder.Settings)

local function CheckTimePeriod(Type)
    if SettingsHandling[Type] then
        warn("Type: ".. tostring(Type) .. ", not found within SettingsHandling")
        return false
    end

    if not module[Type.."TimePeriods"] then
        warn("Type: ".. tostring(Type) .. ", is not set to have Time Periods")
        return false
    end

    return true
end

local function CheckAdjustedTimePeriod(Type)
    if SettingsHandling[Type] then
        warn("Type: ".. tostring(Type) .. ", not found within SettingsHandling")
        return false
    end

    if not module[Type.."AdjustedTimePeriods"] then
        warn("Type: ".. tostring(Type) .. ", is not set to have Time Periods")
        return false
    end

    return true
end

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

local function PopulateTimes(Type: string) --// Puts the times inot a table so that they can easily be evaluated
   if not CheckTimePeriod(Type) then
       return
   end

    for LightingPeriodName, LightingPeriodSettings in pairs (SettingsHandling[Type]["Server"]) do
		if LightingPeriodSettings["GeneralSettings"]["StartTime"] and LightingPeriodSettings["GeneralSettings"]["EndTime"] then
			module[Type.."TimePeriods"][LightingPeriodName] = {
				["StartTime"] = LightingPeriodSettings["GeneralSettings"]["StartTime"],
				["EndTime"] = LightingPeriodSettings["GeneralSettings"]["EndTime"],
			}
		end
	end
end

local function SortTimes(Type: string)
	local NewTable = {}
	local InitialStart = 0
	local CurrentIndex = 1

	local TotalIndexes = 0
	local TotalIndexesDetermined = false

	local CurrentName
	local CurrentStart
	local CurrentEnd

	local CheckedNames = {}
	local Completed = false

    local function Check()
		local Ticked = false

		for LightingPeriodName, Times in pairs (module[Type.."TimePeriods"]) do
			Ticked = true

			if TotalIndexesDetermined == false then
				TotalIndexes = TotalIndexes + 1
			end

			if CurrentStart == nil and CurrentEnd  == nil and CurrentName == nil and table.find(CheckedNames, LightingPeriodName) == nil then
				CurrentName = LightingPeriodName
				CurrentStart = Times["StartTime"]
				CurrentEnd = Times["EndTime"]
			elseif Times["StartTime"] >= InitialStart and Times["StartTime"] < CurrentStart and table.find(CheckedNames, LightingPeriodName) == nil then
				CurrentName = LightingPeriodName
				CurrentStart = Times["StartTime"]
				CurrentEnd = Times["EndTime"]
			end
		end

		if Ticked == true then
			NewTable[CurrentIndex] = {
				["Name"] = CurrentName,
				["StartTime"] = CurrentStart,
				["EndTime"] = CurrentEnd,
			}

			table.insert(CheckedNames, CurrentName)

			CurrentIndex = CurrentIndex + 1
			InitialStart = CurrentEnd

			module[Type.."TimePeriods"][CurrentName] = nil

			CurrentName = nil
			CurrentStart = nil
			CurrentEnd = nil

			if TotalIndexesDetermined == false then
				TotalIndexesDetermined = true
			end
		else
			return
		end

		if CurrentIndex > TotalIndexes then
			Completed = true
		end
    end
    
    if not CheckTimePeriod(Type) then
        return
    end

	while Completed == false do
		Check()
	end

	module[Type.."TimePeriods"] = NewTable
end

local function AdjustStartTimes(Type)
    if not CheckAdjustedTimePeriod(Type) then
        return
    end

	local Adjustment
	local DiffernetTimes = false --// Default set to false (indicates whether time passes at different rates in the day vs night)

	if Settings["DetectIndependentTimeChange"] == false then
		if Settings["TimeForDay"] == Settings["TimeForNight"] then
			Adjustment = InternalVariables["DayAdjustmentRate"]
		else
			DiffernetTimes = true
		end
	else
		local ClockTime1 = Lighting.ClockTime

		wait(Settings["AdjustmentTime"])

		local ClockTime2 = Lighting.ClockTime

		local RateOfTime --// A rate of in-game hours per second

		if ClockTime1 == ClockTime2 then
			warn("No day-night script is detected.  No adjustments made to times")
			module[Type.."AdjustedTimePeriods"] = module[Type.."TimePeriods"]
			return
		elseif ClockTime1 < ClockTime2 then
			RateOfTime = (ClockTime2 - ClockTime1)/Settings["AdjustmentTime"]
		else --// Midnight was crossed
			RateOfTime = (24 - ClockTime2 - ClockTime1)/Settings["AdjustmentTime"]
		end

		Adjustment = RateOfTime * Settings["TimeEffectTween"].Time --// Adjustment results in a number of seconds for which all all Lighting Periods must have their start times adjusted
	end

	module[Type.."AdjustedTimePeriods"] = module[Type.."TimePeriods"]

	if DiffernetTimes == true then --// For when day (0600-1800) and night (1800-0600) pass at different rates
		if Settings["EnableSorting"] == true then
			for _, PeriodSettings in ipairs (module[Type.."AdjustedTimePeriods"]) do
				if PeriodSettings["StartTime"] < 18 or PeriodSettings["StartTime"] >= 6 then --// If it starts during the day then
					if PeriodSettings["StartTime"] - InternalVariables["DayAdjustmentRate"] >= 0 then
						PeriodSettings["StartTime"] = PeriodSettings["StartTime"] - InternalVariables["DayAdjustmentRate"]
					else
						PeriodSettings["StartTime"] = 24 + PeriodSettings["StartTime"] - InternalVariables["DayAdjustmentRate"]
					end
				else --// If it starts during night
					if PeriodSettings["StartTime"] - InternalVariables["NightAdjustmentRate"] >= 0 then
						PeriodSettings["StartTime"] = PeriodSettings["StartTime"] - InternalVariables["NightAdjustmentRate"]
					else
						PeriodSettings["StartTime"] = 24 + PeriodSettings["StartTime"] - InternalVariables["NightAdjustmentRate"]
					end
				end

				if PeriodSettings["EndTime"] < 18 or PeriodSettings["EndTime"] >= 6 then --// If it ends during the day then
					if PeriodSettings["EndTime"] - InternalVariables["DayAdjustmentRate"] >= 0 then
						PeriodSettings["EndTime"] = PeriodSettings["EndTime"] - InternalVariables["DayAdjustmentRate"]
					else
						PeriodSettings["EndTime"] = 24 + PeriodSettings["EndTime"] - InternalVariables["DayAdjustmentRate"]
					end
				else
					if PeriodSettings["EndTime"] - InternalVariables["NightAdjustmentRate"] >= 0 then
						PeriodSettings["EndTime"] = PeriodSettings["EndTime"] - InternalVariables["NightAdjustmentRate"]
					else
						PeriodSettings["EndTime"] = 24 + PeriodSettings["EndTime"] - InternalVariables["NightAdjustmentRate"]
					end
				end
			end
		else
			for _, PeriodSettings in pairs (module[Type.."AdjustedTimePeriods"]) do
				if PeriodSettings["StartTime"] < 18 or PeriodSettings["StartTime"] >= 6 then --// If it starts during the day then
					if PeriodSettings["StartTime"] - InternalVariables["DayAdjustmentRate"] >= 0 then
						PeriodSettings["StartTime"] = PeriodSettings["StartTime"] - InternalVariables["DayAdjustmentRate"]
					else
						PeriodSettings["StartTime"] = 24 + PeriodSettings["StartTime"] - InternalVariables["DayAdjustmentRate"]
					end
				else --// If it starts during night
					if PeriodSettings["StartTime"] - InternalVariables["NightAdjustmentRate"] >= 0 then
						PeriodSettings["StartTime"] = PeriodSettings["StartTime"] - InternalVariables["NightAdjustmentRate"]
					else
						PeriodSettings["StartTime"] = 24 + PeriodSettings["StartTime"] - InternalVariables["NightAdjustmentRate"]
					end
				end

				if PeriodSettings["EndTime"] < 18 or PeriodSettings["EndTime"] >= 6 then --// If it ends during the day then
					if PeriodSettings["EndTime"] - InternalVariables["DayAdjustmentRate"] >= 0 then
						PeriodSettings["EndTime"] = PeriodSettings["EndTime"] - InternalVariables["DayAdjustmentRate"]
					else
						PeriodSettings["EndTime"] = 24 + PeriodSettings["EndTime"] - InternalVariables["DayAdjustmentRate"]
					end
				else
					if PeriodSettings["EndTime"] - InternalVariables["NightAdjustmentRate"] >= 0 then
						PeriodSettings["EndTime"] = PeriodSettings["EndTime"] - InternalVariables["NightAdjustmentRate"]
					else
						PeriodSettings["EndTime"] = 24 + PeriodSettings["EndTime"] - InternalVariables["NightAdjustmentRate"]
					end
				end
			end
		end
	else
		if Settings["EnableSorting"] == true then
			for _, PeriodSettings in ipairs (module[Type.."AdjustedTimePeriods"]) do
				if PeriodSettings["StartTime"] - Adjustment >= 0 then
					PeriodSettings["StartTime"] = PeriodSettings["StartTime"] - Adjustment
				else
					PeriodSettings["StartTime"] = 24 + PeriodSettings["StartTime"] - Adjustment
				end

				if PeriodSettings["EndTime"] - Adjustment >= 0 then
					PeriodSettings["EndTime"] = PeriodSettings["EndTime"] - Adjustment
				else
					PeriodSettings["EndTime"] = 24 + PeriodSettings["EndTime"] - Adjustment
				end
			end
		else
			for _, PeriodSettings in pairs (module[Type.."AdjustedTimePeriods"]) do
				if PeriodSettings["StartTime"] - Adjustment >= 0 then
					PeriodSettings["StartTime"] = PeriodSettings["StartTime"] - Adjustment
				else
					PeriodSettings["StartTime"] = 24 + PeriodSettings["StartTime"] - Adjustment
				end

				if PeriodSettings["EndTime"] - Adjustment >= 0 then
					PeriodSettings["EndTime"] = PeriodSettings["EndTime"] - Adjustment
				else
					PeriodSettings["EndTime"] = 24 + PeriodSettings["EndTime"] - Adjustment
				end
			end
		end
	end
end

local function TrackLightingCycles()
    if Settings["EnableSorting"] == true then
        
    end
end

local function TrackAudioCycles()

end

function module.Run()
    if Settings["EnableDayNightTransitions"] == true then
        coroutine.wrap(DayNightCycle)()
    end

    --PopulateTimes("Audio")
    PopulateTimes("Lighting")

    if Settings["EnableSorting"] == true then
       -- SortTimes("Audio")
        SortTimes("Lighting")
    end
end

return module