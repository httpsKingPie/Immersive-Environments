--// Prepped for Package transition

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local Main = script.Parent

local AudioHandling = require(Main.AudioHandling)
local InternalSettings = require(Main.InternalSettings)
local InternalVariables = require(Main.InternalVariables)
local LightingHandling = require(Main.LightingHandling)
local PackageHandling = require(Main.PackageHandling)

local module = {
	--// The packages being tracked
	["Current Tracked Packages"] = {
		--// Filled in by strings
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

	--// Adjusted time periods
	["Current Adjusted Time Periods"] = {
		["Audio"] = {
			["Region"] = {},
			["Server"] = {},
			["Weather"] = {},
		},
		
		["Lighting"] = {
			["Region"] = {},
			["Server"] = {},
			["Weather"] = {},
		},
	},

	--// These are non-adjusted
	["Current Time Periods"] = {
		["Audio"] = {
			["Region"] = {},
			["Server"] = {},
			["Weather"] = {},
		},
		
		["Lighting"] = {
			["Region"] = {},
			["Server"] = {},
			["Weather"] = {},
		},
	},

	--// Whether either PackageType has had an initial set (i.e. a player just joining or a server just starting)
	["Initial Read"] = {
		["Audio"] = false,
		["Lighting"] = false,
	}
}

local IEFolder = Main.Parent

local Settings = require(IEFolder.Settings)

local ClientSided: boolean = Settings["Client Sided"]
local IsServer: boolean = RunService:IsServer()

--// Checks whether there is only one component, as this eliminates the need to check for time changes
--// Returns a boolean and a string if there is only one component
local function CheckForOnlyOneComponent(PackageType: string, PackageScope: string)
	local CurrentPackage = PackageHandling:GetCurrentPackage(PackageType, PackageScope)

	local LastComponentName: string
	local NumberOfComponents = 0

	for ComponentName, _ in pairs (CurrentPackage["Components"]) do
		NumberOfComponents = NumberOfComponents + 1
		LastComponentName = ComponentName
	end

	if NumberOfComponents == 1 then
		return true, LastComponentName
	else
		return false, nil
	end
end

--// Sanity check function (checks to make sure the package actually exists)
local function CheckTimePeriod(PackageType: string, PackageScope: string)
	if not PackageHandling[PackageType] then
		warn("PackageType:", PackageType, "not found within PackageHandling")
		return false
	end

	if not module["Current Time Periods"][PackageType][PackageScope] then
		warn("PackageType:", PackageType, "is not set to have Time Periods")
		return false
	end

	return true
end

local function CheckAdjustedTimePeriod(PackageType: string, PackageScope: string)
	if not PackageHandling[PackageType] then
		warn("PackageType: ".. tostring(PackageType) .. ", not found within PackageHandling")
		return false
	end

	if not module["Current Adjusted Time Periods"][PackageType][PackageScope] then
		warn("PackageType", PackageType, "PackageScope", PackageScope, "is not set to have Time Periods")
		return false
	end

	return true
end

--// Runs a day night cycle
local function DayNightCycle()
	local DayRatio = (12 * 60) / Settings["Time"]["Day"] --// Ratio of in-game minutes to real-life minutes
	local NightRatio = (12 * 60) / Settings["Time"]["Night"] --// Ratio of in-game minutes to real-life minutes
	--// Note: for above, 12 = the 12 hours for each day/night period (ex: 0600-1800; 1800-0600) and 60 converts it to in-game minutes

	local ActiviationPerMinute = 60 / InternalSettings["DayNightWait"] --// The amount of times the script activates in one minute (real life)

	local MinutesToAddDay = DayRatio / ActiviationPerMinute
	local MinutesToAddNight = NightRatio / ActiviationPerMinute
	--// Note: for above, the ratio tells how many in-game minutes pass per real life minute, and divides it by the amount of activates per real life minute = conversion of in-game minutes per activation

	InternalVariables["Adjustment Rate"]["Day"] = DayRatio / (60^2) * Settings["Tween Information"]["Time"].Time
	InternalVariables["Adjustment Rate"]["Night"] = NightRatio / (60^2) * Settings["Tween Information"]["Time"].Time
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
	if not CheckTimePeriod(PackageType, PackageScope) then
		return
	end

	local PackageComponents = PackageHandling[PackageType][PackageScope][PackageName]["Components"]

	for TimePeriodName, TimePeriodSettings in pairs (PackageComponents) do
		if TimePeriodSettings["GeneralSettings"]["StartTime"] and TimePeriodSettings["GeneralSettings"]["EndTime"] then
			
			module["Current Time Periods"][PackageType][PackageScope][TimePeriodName] = {
				["StartTime"] = TimePeriodSettings["GeneralSettings"]["StartTime"],
				["EndTime"] = TimePeriodSettings["GeneralSettings"]["EndTime"],
			}

			--// Create uniformity and deal with midnight as a 0 time
			if TimePeriodSettings["GeneralSettings"]["StartTime"] == 24 then
				module["Current Time Periods"][PackageType][PackageScope][TimePeriodName]["StartTime"] = 0
			end

			if TimePeriodSettings["GeneralSettings"]["EndTime"] == 24 then
				module["Current Time Periods"][PackageType][PackageScope][TimePeriodName]["EndTime"] = 0
			end
		end
	end
end

--[[
	Sorts the times into a definite sequence, that IE only needs to look at the next time in line

    Arguments: PackageType: string ("Lighting" or "Audio")
]]

local function SortTimes(PackageType: string, PackageScope: string)
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

			for TimePeriodName, Times in pairs (module["Current Time Periods"][PackageType][PackageScope]) do
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

			module["Current Time Periods"][PackageType][PackageScope][CurrentName] = nil --// Removes it from the TimePeriods

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

	if not CheckTimePeriod(PackageType, PackageScope) then
		return
	end

	while Completed == false do
		Check()
	end

	module["Current Time Periods"][PackageType][PackageScope] = NewTable
end

--// Adjusts start times to be consistent with time-based transitions
local function AdjustStartTimes(PackageType: string, PackageScope: string)
	if not CheckAdjustedTimePeriod(PackageType, PackageScope) then
		return
	end

	local Adjustment
	local DifferentTimes = false --// Default set to false (indicates whether time passes at different rates in the day vs night)

	if not Settings["Detect External Day Night Cycle"] then
		if Settings["Time"]["Day"] == Settings["Time"]["Night"] then
			Adjustment = InternalVariables["Adjustment Rate"]["Day"]
		else
			DifferentTimes = true
		end
	else
		local ClockTime1 = Lighting.ClockTime

		task.wait(Settings["Detection Time"])

		local ClockTime2 = Lighting.ClockTime

		local RateOfTime --// A rate of in-game hours per second

		if ClockTime1 == ClockTime2 then
			warn("No day-night script is detected.  No adjustments made to times")
			module["Current Adjusted Time Periods"][PackageType][PackageScope] = module["Current Time Periods"][PackageType][PackageScope]

			return
		elseif ClockTime1 < ClockTime2 then
			RateOfTime = (ClockTime2 - ClockTime1)/Settings["Detection Time"]
		else --// Midnight was crossed
			RateOfTime = (24 - ClockTime2 - ClockTime1)/Settings["Detection Time"]
		end

		Adjustment = RateOfTime * Settings["Tween Information"]["Time"].Time --// Adjustment results in a number of seconds for which all all Lighting Periods must have their start times adjusted
	end

	module["Current Adjusted Time Periods"][PackageType][PackageScope] = module["Current Time Periods"][PackageType][PackageScope]

	if not Settings["Tween"] then --// This means set is active, so we don't adjust anything.
		return
	end

	if DifferentTimes == true then --// For when day (0600-1800) and night (1800-0600) pass at different rates
		if Settings["Sort Time Cycles"] then
			for _, PeriodSettings in ipairs (module["Current Adjusted Time Periods"][PackageType][PackageScope]) do
				if PeriodSettings["StartTime"] < 18 or PeriodSettings["StartTime"] >= 6 then --// If it starts during the day then
					if PeriodSettings["StartTime"] - InternalVariables["Adjustment Rate"]["Day"] >= 0 then
						PeriodSettings["StartTime"] = PeriodSettings["StartTime"] - InternalVariables["Adjustment Rate"]["Day"]
					else
						PeriodSettings["StartTime"] = 24 + PeriodSettings["StartTime"] - InternalVariables["Adjustment Rate"]["Day"]
					end
				else --// If it starts during night
					if PeriodSettings["StartTime"] - InternalVariables["Adjustment Rate"]["Night"] >= 0 then
						PeriodSettings["StartTime"] = PeriodSettings["StartTime"] - InternalVariables["Adjustment Rate"]["Night"]
					else
						PeriodSettings["StartTime"] = 24 + PeriodSettings["StartTime"] - InternalVariables["Adjustment Rate"]["Night"]
					end
				end

				if PeriodSettings["EndTime"] < 18 or PeriodSettings["EndTime"] >= 6 then --// If it ends during the day then
					if PeriodSettings["EndTime"] - InternalVariables["Adjustment Rate"]["Day"] >= 0 then
						PeriodSettings["EndTime"] = PeriodSettings["EndTime"] - InternalVariables["Adjustment Rate"]["Day"]
					else
						PeriodSettings["EndTime"] = 24 + PeriodSettings["EndTime"] - InternalVariables["Adjustment Rate"]["Day"]
					end
				else
					if PeriodSettings["EndTime"] - InternalVariables["Adjustment Rate"]["Night"] >= 0 then
						PeriodSettings["EndTime"] = PeriodSettings["EndTime"] - InternalVariables["Adjustment Rate"]["Night"]
					else
						PeriodSettings["EndTime"] = 24 + PeriodSettings["EndTime"] - InternalVariables["Adjustment Rate"]["Night"]
					end
				end
			end
		else
			for _, PeriodSettings in pairs (module["Current Adjusted Time Periods"][PackageType][PackageScope]) do
				if PeriodSettings["StartTime"] < 18 or PeriodSettings["StartTime"] >= 6 then --// If it starts during the day then
					if PeriodSettings["StartTime"] - InternalVariables["Adjustment Rate"]["Day"] >= 0 then
						PeriodSettings["StartTime"] = PeriodSettings["StartTime"] - InternalVariables["Adjustment Rate"]["Day"]
					else
						PeriodSettings["StartTime"] = 24 + PeriodSettings["StartTime"] - InternalVariables["Adjustment Rate"]["Day"]
					end
				else --// If it starts during night
					if PeriodSettings["StartTime"] - InternalVariables["Adjustment Rate"]["Night"] >= 0 then
						PeriodSettings["StartTime"] = PeriodSettings["StartTime"] - InternalVariables["Adjustment Rate"]["Night"]
					else
						PeriodSettings["StartTime"] = 24 + PeriodSettings["StartTime"] - InternalVariables["Adjustment Rate"]["Night"]
					end
				end

				if PeriodSettings["EndTime"] < 18 or PeriodSettings["EndTime"] >= 6 then --// If it ends during the day then
					if PeriodSettings["EndTime"] - InternalVariables["Adjustment Rate"]["Day"] >= 0 then
						PeriodSettings["EndTime"] = PeriodSettings["EndTime"] - InternalVariables["Adjustment Rate"]["Day"]
					else
						PeriodSettings["EndTime"] = 24 + PeriodSettings["EndTime"] - InternalVariables["Adjustment Rate"]["Day"]
					end
				else
					if PeriodSettings["EndTime"] - InternalVariables["Adjustment Rate"]["Night"] >= 0 then
						PeriodSettings["EndTime"] = PeriodSettings["EndTime"] - InternalVariables["Adjustment Rate"]["Night"]
					else
						PeriodSettings["EndTime"] = 24 + PeriodSettings["EndTime"] - InternalVariables["Adjustment Rate"]["Night"]
					end
				end
			end
		end
	else
		if Settings["Sort Time Cycles"] then
			for _, PeriodSettings in ipairs (module["Current Adjusted Time Periods"][PackageType][PackageScope]) do
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
			for _, PeriodSettings in pairs (module["Current Adjusted Time Periods"][PackageType][PackageScope]) do
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
local function GetCurrentAdjustedPeriod(PackageType: string, PackageScope: string)
	if not CheckAdjustedTimePeriod(PackageType, PackageScope) then
		return
	end

	local CurrentTime = Lighting.ClockTime

	for PeriodName, PeriodSettings in pairs (module["Current Adjusted Time Periods"][PackageType][PackageScope]) do
		local StartTime = PeriodSettings["StartTime"]
		local EndTime = PeriodSettings["EndTime"]

		if CheckInPeriod(CurrentTime, StartTime, EndTime) then
			InternalVariables["Current Adjusted Period"][PackageType] = PeriodName
			return PeriodName
		end
	end
end

--// Bad syntax name here lol, doesn't return anything, more so just sets it to the correct version
local function GetCurrentPeriod(PackageType: string, PackageScope: string)
	if not CheckTimePeriod(PackageType, PackageScope) then
		return
	end

	local CurrentTime = Lighting.ClockTime

	if Settings["Sort Time Cycles"] then
		for _, PeriodSettings in ipairs (module["Current Time Periods"][PackageType][PackageScope]) do
			local StartTime = PeriodSettings["StartTime"]
			local EndTime = PeriodSettings["EndTime"]
			local PeriodName = PeriodSettings["Name"]

			if not InternalVariables["Current Period"][PackageType] == "" then
				return
			end

			if CheckInPeriod(CurrentTime, StartTime, EndTime) then
				InternalVariables["Current Period"][PackageType] = PeriodName
			end
		end
	else
		for PeriodName, PeriodSettings in pairs (module["Current Time Periods"][PackageType][PackageScope]) do
			local StartTime = PeriodSettings["StartTime"]
			local EndTime = PeriodSettings["EndTime"]

			if not InternalVariables["Current Period"][PackageType] == "" then
				return
			end

			if CheckInPeriod(CurrentTime, StartTime, EndTime) then
				InternalVariables["Current Period"][PackageType] = PeriodName
			end
		end
	end

	if InternalVariables["Current Period"][PackageType] == "" then
		warn(PackageType.. " periods are not continuous - period not found")
	end
end

--// Executes TweenAudio or SetLighting
local function Set(PackageType: string)
	if PackageType == "Audio" then
		AudioHandling:TweenAudio("Time") --// We use tween, rather than set, because audio settings already delinaeate which properties can be set
	elseif PackageType == "Lighting" then
		LightingHandling:SetLighting()
	else
		warn("Unknown PackageType", PackageType)
	end
end

--// Executes TweenAudio or TweenLighting
local function Tween(PackageType: string)
	if PackageType == "Audio" then
		AudioHandling:TweenAudio("Time")
	elseif PackageType == "Lighting" then
		LightingHandling:TweenLighting("Time")
	else
		warn("Unknown PackageType", PackageType)
	end
end

--// Moves to the next index
local function SetNextIndex(PackageType: string, PackageScope: string, PackageName: string)
	if not CheckAdjustedTimePeriod(PackageType, PackageScope) then
		return
	end

	--// Get the package so that we can get the package count
	local Package = PackageHandling:GetPackage(PackageType, PackageScope, PackageName)

	if not Package then
		return
	end

	local TotalIndexes = Package["Count"]

	if InternalVariables["Current Index"][PackageType] + 1 <= TotalIndexes then --// Not maxed
		InternalVariables["Next Index"][PackageType] = InternalVariables["Current Index"][PackageType] + 1
	else
		InternalVariables["Next Index"][PackageType] = 1 --// Resets to first index in the sort
	end
end

--// Handles the actual set and tween when tracking via sorted check cycle
local function HandleChangeForSortedCycle(PackageType: string, PackageScope: string, PackageName: string)
	InternalVariables["Current Index"][PackageType] = InternalVariables["Next Index"][PackageType]

	local NewComponentName: string = module["Current Time Periods"][PackageType][PackageScope][InternalVariables["Current Index"][PackageType]]["Name"]

	InternalVariables["Current Period"][PackageType] = NewComponentName

	SetNextIndex(PackageType, PackageScope, PackageName)

	PackageHandling:SetComponent(PackageType, PackageScope, NewComponentName)

	--// If client sided, then all we need to do is set the component and then everything else follows
	if ClientSided then
		return
	end

	--// This handles the server-sided change
	if Settings["Tween"]  == true then
		Tween(PackageType)
	else
		Set(PackageType)
	end
end

--[[
	Tracks the cycle and makes changes depending on different component settings and time

    Arguments: PackageType: string ("Lighting" or "Audio")
]]

local function TrackCycle(PackageType: string, PackageScope: string)
	if not CheckAdjustedTimePeriod(PackageType, PackageScope) then
		return
	end

	local PackageName: string = module["Current Tracked Packages"][PackageType][PackageScope]

	if InternalVariables["Current Adjusted Period"][PackageType] == "" then
		GetCurrentAdjustedPeriod(PackageType, PackageScope)
	end

	--// Sets the current period for the new package
	GetCurrentPeriod(PackageType, PackageScope)

	local OnlyOneComponent: boolean, SoleComponentName: string = CheckForOnlyOneComponent(PackageType, PackageScope)

	--// Handles when there is only one component
	if OnlyOneComponent then
		PackageHandling:SetComponent(PackageType, PackageScope, SoleComponentName)
		return
	end

	--// We never pause the loops, even when in regions or during weather, because we always need to go back and find which period we are in.  The loops are extremely low intensity though
	if Settings["Sort Time Cycles"] then --// Sorted loop
		--// Get initial index
		for Index, PeriodSettings in ipairs (module["Current Time Periods"][PackageType][PackageScope]) do
			if PeriodSettings["Name"] == InternalVariables["Current Period"][PackageType] then
				InternalVariables["Current Index"][PackageType] = Index
				SetNextIndex(PackageType, PackageScope, PackageName)
				break
			end
		end

		local CurrentIndex = InternalVariables["Current Index"][PackageType] --// Defined in the loop above
		local CurrentComponent = module["Current Time Periods"][PackageType][PackageScope][CurrentIndex]["Name"]

		PackageHandling:SetComponent(PackageType, PackageScope, CurrentComponent)

		while task.wait(Settings["Check Time"]) do
			--// Break the loop if the package name for the scope changes.  We have no problem tracking packages when the scope isn't active (ex: player enters a region, we still track the cycle) but once the package for the scope changes (ex: different regions) then we need to stop this (this also plugs a big memory leak)
			if PackageHandling:GetCurrentPackageName(PackageType, PackageScope) ~= PackageName then
				return
			end

			local CurrentTime = Lighting.ClockTime
			local NextIndex = InternalVariables["Next Index"][PackageType]
			
			if NextIndex == 0 then --// Means there are no times (ex: no audio or lighting settings were created)
				return
			end

			local AdjustedTimePeriod = module["Current Adjusted Time Periods"][PackageType][PackageScope]

			local StartTimeForNextPeriod = AdjustedTimePeriod[NextIndex]["StartTime"]
			local EndTimeForNextPeriod = AdjustedTimePeriod[NextIndex]["EndTime"]

			if CheckInPeriod(CurrentTime, StartTimeForNextPeriod, EndTimeForNextPeriod) then
				HandleChangeForSortedCycle(PackageType, PackageScope, PackageName)
			end
		end
	else --// Non sorted loop
		--// If there is only one component, then we don't need to both with checking cycle
		local CurrentComponent = GetCurrentAdjustedPeriod(PackageType, PackageScope)
		PackageHandling:SetComponent(PackageType, PackageScope, CurrentComponent)

		while task.wait(Settings["Check Time"]) do
			--// Break the loop if the package name for the scope changes.  We have no problem tracking packages when the scope isn't active (ex: player enters a region, we still track the cycle) but once the package for the scope changes (ex: different regions) then we need to stop this (this also plugs a big memory leak)
			if PackageHandling:GetCurrentPackageName(PackageType, PackageScope) ~= PackageName then
				return
			end

			--// Current adjusted period is the period we are actually in and is compared to the period that we think are in
			local CurrentAdjustedPeriod: string = GetCurrentAdjustedPeriod(PackageType, PackageScope)

			if CurrentAdjustedPeriod ~= InternalVariables["Current Period"][PackageType] then --// If this changes, that means they are entering a new period
				InternalVariables["Current Period"][PackageType] = CurrentAdjustedPeriod

				PackageHandling:SetComponent(PackageType, PackageScope, CurrentAdjustedPeriod)

				--// Do not make the actual change if client sided
				if not (IsServer and ClientSided) then
					if Settings["Tween"]  == true then
						Tween(PackageType)
					else
						Set(PackageType)
					end
				end
			end
		end
	end
end

--// Reads the new package and loads the cycle in.  ImplementInitialComponent designates whether TimeHandling will implement the component or whether we want to do this manually elsewhere (ex: entering region for the first time)
function module:ReadPackage(PackageType: string, PackageScope: string, PackageName: string, ImplementInitialComponent: boolean)
	--// If this is the initial read, then we want to set the lighting
	local InitialReadComplete: boolean = module["Initial Read"][PackageType]

	--// Records for TimeHandling internal tracking in order to terminate loops when packages change
	module["Current Tracked Packages"][PackageType][PackageScope] = PackageName

	--// Removes old table entries
	module["Current Time Periods"][PackageType][PackageScope] = {}
	module["Current Adjusted Time Periods"][PackageType][PackageScope] = {}

	--// Puts the different periods (in their individual modules) into a readable version for IE
	PopulateTimes(PackageType, PackageScope, PackageName)

	--// Sorts periods to reduce calculation time (sorting also usually takes a few microseconds)
	if Settings["Sort Time Cycles"] then
		SortTimes(PackageType, PackageScope)
	end

	--// Creates the adjusted start times (takes the longest time)
	AdjustStartTimes(PackageType, PackageScope)

	--// Starts checking for period changes
	coroutine.wrap(TrackCycle)(PackageType, PackageScope)

	--// If it is the first package being read, we always tween audio so it sounds better and set the lighting.  We only do this on the server, because this is meant to initialize the entire server
	if not InitialReadComplete and IsServer then
		module["Initial Read"][PackageType] = true

		--// Do not make the actual change if client sided
		if ClientSided then
			return
		end

		if PackageType == "Audio" then
			Tween(PackageType)
		elseif PackageType == "Lighting" then
			Set(PackageType)
		else
			warn("Unexpected PackageType", PackageType)
		end

		return
	end

	--// Whether we do the initial change here, or whether we handle it somewhere else in the code
	if ImplementInitialComponent then
		--// Do not make the actual change if client sided
		if ClientSided and IsServer then
			return
		end

		if PackageType == "Audio" or Settings["Tween"] then
			Tween(PackageType)
		else
			Set(PackageType)
		end
	end
end

--[[
	This returns the component that *theoretically* would be active for a package

	This is basically only used for evaluating shared sounds, but this is essentially saying "Hey, if this package were implemented, what would component would be active *right now*"
]]
function module:ReturnTheoreticallyCurrentComponentForPackage(Package: table)
	--// This is a localized variation of CheckForOnlyOneComponent, compatible with a table of Components as an article, instead of a PackageType and it returns the Component
	local function TheoreticallyCheckForOnlyOneComponent(Components: table)
		local LastComponent: table
		local NumberOfComponents: number = 0
	
		for _, Component in pairs (Components) do
			NumberOfComponents = NumberOfComponents + 1
			LastComponent = Component
		end
	
		if NumberOfComponents == 1 then
			return true, LastComponent
		else
			return false, nil
		end
	end

	--// Localaized variation of GetCurrentPeriod, compatible with a table of Components as an article, instead of a PackageType and it returns the Component
	local function GetTheoreticallyCurrentComponent(Components: table)
		local CurrentTime = Lighting.ClockTime

		for _, Component in pairs (Components) do
			local StartTime = Component["GeneralSettings"]["StartTime"]
			local EndTime = Component["GeneralSettings"]["EndTime"]

			if CheckInPeriod(CurrentTime, StartTime, EndTime) then
				return Component
			end
		end

		warn("Components are not continuous - theoretical component not found")
	end

	local Components: table = Package["Components"]

	local OnlyOneComponent: boolean, SoleComponent: string = TheoreticallyCheckForOnlyOneComponent(Components)

	--// If there is only one component, then we can just return this directly
	if OnlyOneComponent then
		return SoleComponent
	end

	--// Otherwise, there are multiple components and we must instead sort through each
	local TheoreticallyCurrentComponent = GetTheoreticallyCurrentComponent(Components)

	--// Warning bundled in
	if not TheoreticallyCurrentComponent then
		return
	end

	return TheoreticallyCurrentComponent
end

--// Basic initialization
function module.Initialize()
	--// Starts the day/night cycle
	if Settings["Enable Day Night Cycle"] then
		coroutine.wrap(DayNightCycle)()
	end

	InternalVariables["Initialized"]["Time"] = true

	--// Rechecks day and night if the time does not pass at the same rate
	if Settings["Time"]["Day"] ~= Settings["Time"]["Night"] then
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