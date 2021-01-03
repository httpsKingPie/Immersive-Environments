local module = {
    ["AudioAdjustedTimePeriods"] = {},
    ["AudioTimePeriods"] = {},
   
    ["LightingAdjustedTimePeriods"] = {},
    ["LightingTimePeriods"] = {},
}

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local Main = script.Parent

local AudioHandling = require(Main.AudioHandling)
local InternalSettings = require(Main.InternalSettings)
local InternalVariables = require(Main.InternalVariables)
local LightingHandling = require(Main.LightingHandling)
local SettingsHandling = require(Main.SettingsHandling)

local IEFolder = Main.Parent

local Settings = require(IEFolder.Settings)

local function CheckTimePeriod(Type)
    if not SettingsHandling[Type] then
		warn("Type: ".. tostring(Type) .. ", not found within SettingsHandling")
        return false
    end

    if not module[Type.."TimePeriods"] then
        warn("Type: ".. tostring(Type) .. ", is not set to have Time Periods")
        return false
    end

    return true
end

local function CheckAdjustedTimePeriod(Type: string)
    if not SettingsHandling[Type] then
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

    InternalVariables["DayAdjustmentRate"] = DayRatio / (60^2) * Settings["TimeEffectTweenInformation"].Time
    InternalVariables["NightAdjustmentRate"] = NightRatio / (60^2) * Settings["TimeEffectTweenInformation"].Time
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

local function PopulateTimes(Type: string) --// Puts the times into a table so that they can easily be evaluated
   if not CheckTimePeriod(Type) then
       return
   end

    for TimePeriodName, TimePeriodSettings in pairs (SettingsHandling[Type]["Server"]) do
		if TimePeriodSettings["GeneralSettings"]["StartTime"] and TimePeriodSettings["GeneralSettings"]["EndTime"] then
			module[Type.."TimePeriods"][TimePeriodName] = {
				["StartTime"] = TimePeriodSettings["GeneralSettings"]["StartTime"],
				["EndTime"] = TimePeriodSettings["GeneralSettings"]["EndTime"],
			}

			--// Create uniformity and deal with midnight as a 0 time
			if TimePeriodSettings["GeneralSettings"]["StartTime"] == 24 then
				module[Type.."TimePeriods"][TimePeriodName]["StartTime"] = 0
			end

			if TimePeriodSettings["GeneralSettings"]["EndTime"] == 24 then
				module[Type.."TimePeriods"][TimePeriodName]["EndTime"] = 0
			end
		end
	end
end

local function SortTimes(Type: string) --// Sorts the times into a definite sequence, that way the script only needs to look at the next time in line
	local NewTable = {}
	local InitialStart = 0 --// Initial time of 0 (eventually this gets replaced by the end time of the the period that was just determined to be the next in order)
	local CurrentIndex = 1 --// Current index is 1 (the first one)

	local TotalIndexes = 0
	local TotalIndexesDetermined = false

	local CurrentName
	local CurrentStart
	local CurrentEnd

	local CheckedNames = {} --// Prevents duplicates
	local Completed = false

	local function Check()

		--// This loop returns the next period in the sequence, and populates the CurrentName, CurrentStart, and CurrentEnd with the properities of the period
		local function GetNextPeriod()
			local Ticked = false

			for TimePeriodName, Times in pairs (module[Type.."TimePeriods"]) do
				Ticked = true
	
				if TotalIndexesDetermined == false then 
					TotalIndexes = TotalIndexes + 1
				end
	
				if not table.find(CheckedNames, TimePeriodName) then
					if not CurrentStart and not CurrentEnd and not CurrentName then --// Becomes the initial values for CurrentName, CurrentStart, and CurrentEnd (because the first period in line, is by default, the one that gets sorted first until another proves that it starts earlier in the cycle)
						CurrentName = TimePeriodName
						CurrentStart = Times["StartTime"]
						CurrentEnd = Times["EndTime"]
					elseif Times["StartTime"] >= InitialStart and Times["StartTime"] < CurrentStart then --// If the start time is equal or greater than the starting value of 0, or the end time of the previous period and the StartTime is 
						CurrentName = TimePeriodName
						CurrentStart = Times["StartTime"]
						CurrentEnd = Times["EndTime"]
					end
				end
			end

			return Ticked
		end
		
		if GetNextPeriod() then
			NewTable[CurrentIndex] = {
				["Name"] = CurrentName,
				["StartTime"] = CurrentStart,
				["EndTime"] = CurrentEnd,
			}

			table.insert(CheckedNames, CurrentName) --// Ensures that a period already checked is not checked again

			CurrentIndex = CurrentIndex + 1
			InitialStart = CurrentEnd

			module[Type.."TimePeriods"][CurrentName] = nil --// Removes it from the TimePeriods

			--// Clears these variables
			CurrentName = nil
			CurrentStart = nil
			CurrentEnd = nil

			--// Only runs once
			if TotalIndexesDetermined == false then
				TotalIndexesDetermined = true
			end
		else
			return --// Means there are no time periods
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

		Adjustment = RateOfTime * Settings["TimeEffectTweenInformation"].Time --// Adjustment results in a number of seconds for which all all Lighting Periods must have their start times adjusted
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

local function GetCurrentAdjustedPeriod(Type)
	if not CheckAdjustedTimePeriod(Type) then
		return
	end

	local CurrentTime = Lighting.ClockTime
	
	for PeriodName, PeriodSettings in pairs (module[Type.. "AdjustedTimePeriods"]) do
		if PeriodSettings["EndTime"] > PeriodSettings["StartTime"] then
			if CurrentTime >= PeriodSettings["StartTime"] and CurrentTime < PeriodSettings["EndTime"] then
				InternalVariables["Current".. Type.. "AdjustedPeriod"] = PeriodName
				return
			end
		else
			if (CurrentTime < 24 and CurrentTime >= PeriodSettings["StartTime"]) or (CurrentTime < PeriodSettings["EndTime"]) then
				InternalVariables["Current".. Type.. "AdjustedPeriod"] = PeriodName
				return
			end
		end
	end
end

local function GetCurrentPeriod(Type: string)
	if not CheckTimePeriod(Type) then
		return
	end

	local CurrentTime = Lighting.ClockTime
	
	if Settings["EnableSorting"] == true then
		for _, PeriodSettings in ipairs (module[Type.. "TimePeriods"]) do
			local StartTime = PeriodSettings["StartTime"]
			local EndTime = PeriodSettings["EndTime"]
			
			if EndTime > StartTime then --// Most cases (ex: starts at 0200 ends at 0600)
				if CurrentTime >= StartTime and CurrentTime <= EndTime then
					InternalVariables["Current".. Type.. "Period"] = PeriodSettings["Name"]
					return
				end
			else --// Means midnight is crossed (ex: starts at 2200 and ends at 0200)
				if CurrentTime > EndTime then --// Midnight has not yet been crossed (can process sort of like a normal period) 
					if CurrentTime >= StartTime then
						InternalVariables["Current".. Type.. "Period"] = PeriodSettings["Name"]
						return
					end
				else --// Midnight has already been crossed
					if CurrentTime < EndTime then
						InternalVariables["Current".. Type.. "Period"] = PeriodSettings["Name"]
						return
					end
				end
			end
		end
		
		warn(Type.. " periods are not continuous - period not found")
	else
		for _, PeriodSettings in pairs (module[Type.. "TimePeriods"]) do
			if CurrentTime >= PeriodSettings["StartTime"] and CurrentTime <= PeriodSettings["EndTime"] then
				InternalVariables["Current".. Type.. "Period"] = PeriodSettings["Name"]
				return
			end
		end
		
		warn(Type.. "periods are not continuous - period not found")
	end
end

local function Set(Type, PeriodName)
	if type(PeriodName) ~= "string" then
		warn("Non string passed for PeriodName")
		return
	end

	if Type == "Audio" then
		AudioHandling.TweenAudio("TimeChange", PeriodName) --// We use tween, rather than set, because audio settings already delinaeate which properties can be set
	elseif Type == "Lighting" then
		LightingHandling.SetLighting("TimeChange", PeriodName)
	else
		warn("Unexpected input type for Set: ".. tostring(Type))
	end
end

local function Tween(Type, PeriodName)
	if type(PeriodName) ~= "string" then
		warn("Non string passed for PeriodName")
		return
	end

	if Type == "Audio" then
		AudioHandling.TweenAudio("TimeChange", PeriodName)
	elseif Type == "Lighting" then
		LightingHandling.TweenLighting("TimeChange", PeriodName)
	else
		warn("Unexpected input type for Tween: ".. tostring(Type))
	end
end

local function SetNextIndex(Type)
	if not CheckAdjustedTimePeriod(Type) then
		return
	end

	if InternalVariables["Current".. Type.. "Index"] + 1 <= InternalVariables["Total".. Type.. "Indexes"] then --// Not maxed
		InternalVariables["Next".. Type.. "Index"] = InternalVariables["Current".. Type.. "Index"] + 1
	else
		InternalVariables["Next".. Type.. "Index"] = 1 --// Resets to first index in the sort
	end
end

local function TrackCycle(Type)  --// New name for the CheckCycle; Type is either "Audio" or "Lighting"
	if not CheckAdjustedTimePeriod(Type) then
		return
	end

	if InternalVariables["Current".. Type.. "AdjustedPeriod"] == "" then
		GetCurrentAdjustedPeriod(Type)
	end

	if InternalVariables["Current".. Type.. "Period"] == "" then
		GetCurrentPeriod(Type) --// This returns a value, but we don't need it
	end

	--// We never pause the loops, even when in regions or during weather, because we always need to go back and find which period we are in.  The loops are extremely low intensity though
	if Settings["EnableSorting"] == true then --// Sorted loop
		--// Get initial index
		for Index, PeriodSettings in ipairs (module[Type.. "TimePeriods"]) do
			if PeriodSettings["Name"] == InternalVariables["Current".. Type.. "Period"] then
				InternalVariables["Current".. Type.. "Index"] = Index
				SetNextIndex(Type)
				break
			end
		end
		
		while wait(Settings["CheckTime"]) do
			--// Function for handling period changes
			local function HandleChange(Type)
				InternalVariables["Current".. Type.. "Index"] = InternalVariables["Next".. Type.. "Index"]
				InternalVariables["Current".. Type.. "Period"] = module[Type.. "TimePeriods"][InternalVariables["Current".. Type.. "Index"]]["Name"]

				SetNextIndex(Type)

				if InternalVariables["Halt".. Type.. "Cycle"] == false then --// Cycle is not halted, changes can occur
					if Settings["Tween"]  == true then
						Tween(Type, InternalVariables["Current".. Type.. "Period"])
					else
						Set(Type, InternalVariables["Current".. Type.. "Period"])
					end
				end
			end

			local CurrentTime = Lighting.ClockTime
			
			local StartTimeForNextPeriod = module[Type.. "AdjustedTimePeriods"][InternalVariables["Next".. Type.. "Index"]]["StartTime"]
			local EndTimeForNextPeriod = module[Type.. "AdjustedTimePeriods"][InternalVariables["Next".. Type.. "Index"]]["EndTime"]

			if EndTimeForNextPeriod > StartTimeForNextPeriod then --// "Normal time change"

				if CurrentTime >= StartTimeForNextPeriod and CurrentTime < EndTimeForNextPeriod then

					HandleChange(Type)
				end
			else --// Means times go over midnight, ex: start at 22 ends at 4

				if (CurrentTime >= StartTimeForNextPeriod) or (CurrentTime < EndTimeForNextPeriod) then

					HandleChange(Type)
				end
			end
		end
	else --// Non sorted loop
		while wait(Settings["CheckTime"]) do
			local CurrentAdjustedPeriod = GetCurrentAdjustedPeriod(Type)

			if CurrentAdjustedPeriod ~= InternalVariables["Current".. Type.. "Period"] then --// If this changes, that means they are entering a new period
				InternalVariables["Current".. Type.. "Period"] = CurrentAdjustedPeriod

				if Settings["Tween"]  == true then
					Tween(Type, InternalVariables["Current".. Type.. "Period"])
				else
					Set(Type, InternalVariables["Current".. Type.. "Period"])
				end
			end
		end
	end
end

function module.Run()
	--// Starts the day/night cycle
    if Settings["EnableDayNightTransitions"] == true then
        coroutine.wrap(DayNightCycle)()
    end

	 --// Puts the differnet periods (in their individual modules) into a readable version for the script
    PopulateTimes("Audio")
    PopulateTimes("Lighting")

	if Settings["AutomaticTransitions"] == true and RunService:IsServer() then
		--// Sorts periods to reduce calculation time (sorting also usually takes a few microseconds)
		if Settings["EnableSorting"] == true then
			SortTimes("Audio")
			SortTimes("Lighting")
		end

		 --// Creates the adjusted start times (takes the longest time)
		AdjustStartTimes("Audio")
		AdjustStartTimes("Lighting")
		
		 --// Starts checking for period changes
		coroutine.wrap(TrackCycle)("Audio")
		coroutine.wrap(TrackCycle)("Lighting")

		--// Sets the server to the current period settings
		if Settings["ClientSided"] == false then
			Set("Lighting", InternalVariables["CurrentLightingPeriod"])
			Tween("Audio", InternalVariables["CurrentAudioPeriod"]) --// Right now it's set to tween vs setting, because audio sounds really bad when it just abrubtly starts - lighting is kind of fine for this
		end

		InternalVariables["TimeInitialized"] = true

		--// Rechecks day and night if the time does not pass at the same rate
		if Settings["TimeForDay"] ~= Settings["TimeForNight"] then
			local Check = coroutine.create(function()
				while true do
					wait(InternalSettings["DayNightWait"])
	
					AdjustStartTimes()
				end
			end)
			
			coroutine.resume(Check)
		end
	end
end

return module