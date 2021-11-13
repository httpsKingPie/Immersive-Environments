--// Prepped for Package transition

local module = {
	["AudioAdjustedTimePeriods"] = {},
	["AudioTimePeriods"] = {},

	["LightingAdjustedTimePeriods"] = {},
	["LightingTimePeriods"] = {},

	--// Tracks it internally so memory leaks don't occur when new packages are set
	["Current Audio Package"] = {
		["Name"] = "",
		["Scope"] = "",
	},

	["Current Lighting Package"] = {
		["Name"] = "",
		["Scope"] = "",
	},
}

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local Main = script.Parent

local AudioHandling = require(Main.AudioHandling)
local InternalSettings = require(Main.InternalSettings)
local InternalVariables = require(Main.InternalVariables)
local LightingHandling = require(Main.LightingHandling)
local PackageHandling = require(Main.PackageHandling)
local SettingsHandling = require(Main.SettingsHandling)

local IEFolder = Main.Parent

local Settings = require(IEFolder.Settings)

local ClientSided = Settings["ClientSided"]

--// Sanity check function (checks to make sure the package actually exists)
local function CheckTimePeriod(PackageType: string)
	if not PackageHandling[PackageType] then
		warn("PackageType:", PackageType, "not found within PackageHandling")
		return false
	end

	if not module[PackageType.."TimePeriods"] then
		warn("PackageType:", PackageType, "is not set to have Time Periods")
		return false
	end

	return true
end

local function CheckAdjustedTimePeriod(PackageType: string)
	if not PackageHandling[PackageType] then
		warn("PackageType: ".. tostring(PackageType) .. ", not found within PackageHandling")
		return false
	end

	if not module[PackageType.."AdjustedTimePeriods"] then
		warn("PackageType: ".. tostring(PackageType) .. ", is not set to have Time Periods")
		return false
	end

	return true
end

--// Runs a day night cycle
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
		task.wait(InternalSettings["DayNightWait"]) do
			if Lighting.ClockTime > 18 or Lighting.ClockTime < 6 then --// Night time
				Lighting:SetMinutesAfterMidnight(Lighting:GetMinutesAfterMidnight() + MinutesToAddNight)
			else --// Day time
				Lighting:SetMinutesAfterMidnight(Lighting:GetMinutesAfterMidnight() + MinutesToAddDay)
			end
		end
	end
end

--[[
	Puts the times into a table so that they can easily be evaluated

    Arguments: PackageType: string ("Lighting" or "Audio"), PackageScope: string ("Region", "Server", or "Weather")
]]

local function PopulateTimes(PackageType: string, PackageScope: string, PackageName: string)
	if not CheckTimePeriod(PackageType) then
		return
	end

	local PackageComponents = PackageHandling[PackageType][PackageScope][PackageName]["Components"]

	for TimePeriodName, TimePeriodSettings in pairs (PackageComponents) do
		if TimePeriodSettings["GeneralSettings"]["StartTime"] and TimePeriodSettings["GeneralSettings"]["EndTime"] then
			module[PackageType.."TimePeriods"][TimePeriodName] = {
				["StartTime"] = TimePeriodSettings["GeneralSettings"]["StartTime"],
				["EndTime"] = TimePeriodSettings["GeneralSettings"]["EndTime"],
			}

			--// Create uniformity and deal with midnight as a 0 time
			if TimePeriodSettings["GeneralSettings"]["StartTime"] == 24 then
				module[PackageType.."TimePeriods"][TimePeriodName]["StartTime"] = 0
			end

			if TimePeriodSettings["GeneralSettings"]["EndTime"] == 24 then
				module[PackageType.."TimePeriods"][TimePeriodName]["EndTime"] = 0
			end
		end
	end
end

--[[
	Sorts the times into a definite sequence, that IE only needs to look at the next time in line

    Arguments: PackageType: string ("Lighting" or "Audio")
]]

local function SortTimes(PackageType: string)
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

			for TimePeriodName, Times in pairs (module[PackageType.."TimePeriods"]) do
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
			
			if not Ticked then
				Completed = true
				return
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

			module[PackageType.."TimePeriods"][CurrentName] = nil --// Removes it from the TimePeriods

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

	if not CheckTimePeriod(PackageType) then
		return
	end

	while Completed == false do
		Check()
	end

	module[PackageType.."TimePeriods"] = NewTable
end

--[[
	Adjusts start times to be consistent with time-based transitions

    Arguments: PackageType: string ("Lighting" or "Audio")
]]

local function AdjustStartTimes(PackageType: string)
	if not CheckAdjustedTimePeriod(PackageType) then
		return
	end

	local Adjustment
	local DifferentTimes = false --// Default set to false (indicates whether time passes at different rates in the day vs night)

	if Settings["DetectIndependentTimeChange"] == false then
		if Settings["TimeForDay"] == Settings["TimeForNight"] then
			Adjustment = InternalVariables["DayAdjustmentRate"]
		else
			DifferentTimes = true
		end
	else
		local ClockTime1 = Lighting.ClockTime

		task.wait(Settings["AdjustmentTime"])

		local ClockTime2 = Lighting.ClockTime

		local RateOfTime --// A rate of in-game hours per second

		if ClockTime1 == ClockTime2 then
			warn("No day-night script is detected.  No adjustments made to times")
			module[PackageType.."AdjustedTimePeriods"] = module[PackageType.."TimePeriods"]
			return
		elseif ClockTime1 < ClockTime2 then
			RateOfTime = (ClockTime2 - ClockTime1)/Settings["AdjustmentTime"]
		else --// Midnight was crossed
			RateOfTime = (24 - ClockTime2 - ClockTime1)/Settings["AdjustmentTime"]
		end

		Adjustment = RateOfTime * Settings["TimeEffectTweenInformation"].Time --// Adjustment results in a number of seconds for which all all Lighting Periods must have their start times adjusted
	end

	module[PackageType.."AdjustedTimePeriods"] = module[PackageType.."TimePeriods"]

	if not Settings["Tween"] then --// This means set is active, so we don't adjust anything.
		return
	end

	if DifferentTimes == true then --// For when day (0600-1800) and night (1800-0600) pass at different rates
		if Settings["EnableSorting"] == true then
			for _, PeriodSettings in ipairs (module[PackageType.."AdjustedTimePeriods"]) do
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
			for _, PeriodSettings in pairs (module[PackageType.."AdjustedTimePeriods"]) do
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
			for _, PeriodSettings in ipairs (module[PackageType.."AdjustedTimePeriods"]) do
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
			for _, PeriodSettings in pairs (module[PackageType.."AdjustedTimePeriods"]) do
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

--// Checks whether the current time is the specified period
local function CheckInPeriod(CurrentTime: number, StartTime: number, EndTime: number) --// Returns name
	if EndTime > StartTime then --// Most cases (ex: starts at 0200 ends at 0600)
		if CurrentTime >= StartTime and CurrentTime <= EndTime then
			return true
		end
	else --// Means midnight is crossed (ex: starts at 2200 and ends at 0200)
		if CurrentTime > EndTime then --// Midnight has not yet been crossed (can process sort of like a normal period) 
			if CurrentTime >= StartTime then
				return true
			end
		else --// Midnight has already been crossed
			if CurrentTime < EndTime then
				return true
			end
		end
	end

	return false
end

--// Returns the current adjusted time period based on PackageType
local function GetCurrentAdjustedPeriod(PackageType: string)
	if not CheckAdjustedTimePeriod(PackageType) then
		return
	end

	local CurrentTime = Lighting.ClockTime

	for PeriodName, PeriodSettings in pairs (module[PackageType.. "AdjustedTimePeriods"]) do
		local StartTime = PeriodSettings["StartTime"]
		local EndTime = PeriodSettings["EndTime"]

		if CheckInPeriod(CurrentTime, StartTime, EndTime) then
			InternalVariables["Current".. PackageType.. "AdjustedPeriod"] = PeriodName
			return PeriodName
		end
	end
end

--// Bad syntax name here lol, doesn't return anything, more so just sets it to the correct version
local function GetCurrentPeriod(PackageType: string)
	if not CheckTimePeriod(PackageType) then
		return
	end

	local CurrentTime = Lighting.ClockTime

	if Settings["EnableSorting"] == true then
		for _, PeriodSettings in ipairs (module[PackageType.. "TimePeriods"]) do
			local StartTime = PeriodSettings["StartTime"]
			local EndTime = PeriodSettings["EndTime"]
			local PeriodName = PeriodSettings["Name"]

			if not InternalVariables["Current".. PackageType.. "Period"] == "" then
				return
			end

			if CheckInPeriod(CurrentTime, StartTime, EndTime) then
				InternalVariables["Current".. PackageType.. "Period"] = PeriodName
			end
		end
	else
		for PeriodName, PeriodSettings in pairs (module[PackageType.. "TimePeriods"]) do
			local StartTime = PeriodSettings["StartTime"]
			local EndTime = PeriodSettings["EndTime"]

			if not InternalVariables["Current".. PackageType.. "Period"] == "" then
				return
			end

			if CheckInPeriod(CurrentTime, StartTime, EndTime) then
				InternalVariables["Current".. PackageType.. "Period"] = PeriodName
			end
		end
	end

	if InternalVariables["Current".. PackageType.. "Period"] == "" then
		warn(PackageType.. " periods are not continuous - period not found")
	end
end

--// Executes TweenAudio or SetLighting
local function Set(PackageType, PeriodName)
	if type(PeriodName) ~= "string" then
		warn("Non string passed for PeriodName")
		return
	end

	if PackageType == "Audio" then
		AudioHandling.TweenAudio("TimeChange", PeriodName) --// We use tween, rather than set, because audio settings already delinaeate which properties can be set
	elseif PackageType == "Lighting" then
		LightingHandling:SetLighting("TimeChange", PeriodName)
	else
		warn("Unexpected input type for Set: ".. tostring(PackageType))
	end
end

--// Executes TweenAudio or TweenLighting
local function Tween(PackageType: string, PeriodName: string)
	if type(PeriodName) ~= "string" then
		warn("Non string passed for PeriodName")
		return
	end

	if PackageType == "Audio" then
		AudioHandling.TweenAudio("TimeChange", PeriodName)
	elseif PackageType == "Lighting" then
		LightingHandling.TweenLighting("TimeChange", PeriodName)
	else
		warn("Unexpected input type for Tween: ".. tostring(PackageType))
	end
end

--// Moves to the next index
local function SetNextIndex(PackageType: string, PackageScope: string, PackageName: string)
	if not CheckAdjustedTimePeriod(PackageType) then
		return
	end

	local Package = PackageHandling:GetPackage(PackageType, PackageName)

	if not Package then
		return
	end

	local TotalIndexes = Package["Count"]

	if InternalVariables["Current".. PackageType.. "Index"] + 1 <= TotalIndexes then --// Not maxed
		InternalVariables["Next".. PackageType.. "Index"] = InternalVariables["Current".. PackageType.. "Index"] + 1
	else
		InternalVariables["Next".. PackageType.. "Index"] = 1 --// Resets to first index in the sort
	end
end

--[[
	Tracks the cycle and makes changes depending on different component settings and time

    Arguments: PackageType: string ("Lighting" or "Audio")
]]

local function TrackCycle(PackageType: string)
	if not CheckAdjustedTimePeriod(PackageType) then
		return
	end

	local CycleName = module["Current ".. PackageType.. " Package"]["Name"]
	local CycleScope = module["Current ".. PackageType.. " Package"]["Scope"]

	if InternalVariables["Current".. PackageType.. "AdjustedPeriod"] == "" then
		GetCurrentAdjustedPeriod(PackageType)
	end

	if InternalVariables["Current".. PackageType.. "Period"] == "" then
		GetCurrentPeriod(PackageType) --// This returns a value, but we don't need it
	end

	--// Checks if the package has changed in order to terminate the loop
	local function PackageChanged()
		local CurrentCycleName = module["Current ".. PackageType.. " Package"]["Name"]
		local CurrentCycleScope = module["Current ".. PackageType.. " Package"]["Scope"]

		if CycleName ~= CurrentCycleName or CycleScope ~= CurrentCycleScope then
			return true
		end

		return false
	end

	--// We never pause the loops, even when in regions or during weather, because we always need to go back and find which period we are in.  The loops are extremely low intensity though
	if Settings["EnableSorting"] == true then --// Sorted loop
		--// Get initial index
		for Index, PeriodSettings in ipairs (module[PackageType.. "TimePeriods"]) do
			if PeriodSettings["Name"] == InternalVariables["Current".. PackageType.. "Period"] then
				InternalVariables["Current".. PackageType.. "Index"] = Index
				SetNextIndex(PackageType, CycleScope, CycleName)
				break
			end
		end

		local CurrentComponent = module[PackageType.. "TimePeriods"][InternalVariables["Current".. PackageType.. "Index"]]["Name"]
		PackageHandling:SetComponent(PackageType, PackageHandling:GetCurrentScope(PackageType), CurrentComponent)

		while task.wait(Settings["CheckTime"]) do
			if PackageChanged() then
				return
			end

			--// Function for handling period changes
			local function HandleChange(PackageType)
				local NewComponent = module[PackageType.. "TimePeriods"][InternalVariables["Current".. PackageType.. "Index"]]["Name"]

				InternalVariables["Current".. PackageType.. "Index"] = InternalVariables["Next".. PackageType.. "Index"]
				InternalVariables["Current".. PackageType.. "Period"] = NewComponent

				SetNextIndex(PackageType, CycleScope, CycleName)

				if InternalVariables["Halt".. PackageType.. "Cycle"] == false then --// Cycle is not halted, changes can occur
					PackageHandling:SetComponent(PackageType, PackageHandling:GetCurrentScope(PackageType), NewComponent)

					--// If client sided, then all we need to do is set the component and then everything else follows
					if ClientSided then
						return
					end

					if Settings["Tween"]  == true then
						Tween(PackageType)
					else
						Set(PackageType)
					end
				end
			end

			local CurrentTime = Lighting.ClockTime
			local NextIndex = InternalVariables["Next".. PackageType.. "Index"]
			
			if NextIndex == 0 then --// Means there are no times (ex: no audio or lighting settings were created)
				return
			end

			local StartTimeForNextPeriod = module[PackageType.. "AdjustedTimePeriods"][NextIndex]["StartTime"]
			local EndTimeForNextPeriod = module[PackageType.. "AdjustedTimePeriods"][NextIndex]["EndTime"]

			if CheckInPeriod(CurrentTime, StartTimeForNextPeriod, EndTimeForNextPeriod) then
				HandleChange(PackageType)
			end
		end
	else --// Non sorted loop
		local CurrentComponent = GetCurrentAdjustedPeriod(PackageType)
		PackageHandling:SetComponent(PackageType, PackageHandling:GetCurrentScope(PackageType), CurrentComponent)

		while task.wait(Settings["CheckTime"]) do
			if PackageChanged() then
				return
			end

			local CurrentAdjustedPeriod = GetCurrentAdjustedPeriod(PackageType)

			if CurrentAdjustedPeriod ~= InternalVariables["Current".. PackageType.. "Period"] then --// If this changes, that means they are entering a new period
				InternalVariables["Current".. PackageType.. "Period"] = CurrentAdjustedPeriod

				PackageHandling:SetComponent(PackageType, PackageHandling:GetCurrentScope(PackageType), CurrentAdjustedPeriod)

				if Settings["Tween"]  == true then
					Tween(PackageType, InternalVariables["Current".. PackageType.. "Period"])
				else
					Set(PackageType, InternalVariables["Current".. PackageType.. "Period"])
				end
			end
		end
	end
end

--// Reads the new package and loads the cycle in
function module:ReadPackage(PackageType: string, PackageScope: string, PackageName: string)
	--// Records for TimeHandling internal tracking in order to terminate loops when packages change
	module["Current ".. PackageType.. " Package"]["Name"] = PackageName
	module["Current ".. PackageType.. " Package"]["Scope"] = PackageScope

	--// Puts the different periods (in their individual modules) into a readable version for IE
	PopulateTimes(PackageType, PackageScope, PackageName)

	if not Settings["AutomaticTransitions"] == true then 
		return
	end
	
	--// The client can run this now that regions can have time periods
	--[[
	if not RunService:IsServer() then
		return
	end
	]]

	--// Sorts periods to reduce calculation time (sorting also usually takes a few microseconds)
	if Settings["EnableSorting"] == true then
		SortTimes(PackageType)
	end

	--// Creates the adjusted start times (takes the longest time)
	AdjustStartTimes(PackageType)

	--// Starts checking for period changes
	coroutine.wrap(TrackCycle)(PackageType)

	--// Sets the server to the current period settings
	if Settings["ClientSided"] == false then
		Set("Lighting", InternalVariables["CurrentLightingPeriod"])
		Tween("Audio", InternalVariables["CurrentAudioPeriod"]) --// Right now it's set to tween vs setting, because audio sounds really bad when it just abrubtly starts - lighting is kind of fine for this
	end
end

--// Basic initialization
function module.Initialize()
	--// Starts the day/night cycle
	if Settings["EnableDayNightTransitions"] == true then
		coroutine.wrap(DayNightCycle)()
	end

	InternalVariables["TimeInitialized"] = true

	--// Rechecks day and night if the time does not pass at the same rate
	if Settings["TimeForDay"] ~= Settings["TimeForNight"] then
		local Check = coroutine.create(function()
			while true do
				task.wait(InternalSettings["DayNightWait"])

				AdjustStartTimes()
			end
		end)

		coroutine.resume(Check)
	end
end

return module