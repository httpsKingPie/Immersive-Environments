local module = {
	
	--// General Settings
	["DefaultSettings"] = false, --// Set to true if you just want to run this with recommend settings
	["AlwaysCheckInstances"] = false, --// Will run a search through workspace to check for instance changes every time if this is set to true.  Recommended to set to false if the number of instances never changes or if StreamingEnabled is not enabled (aka StreamingDisabled - hahahahahahahahhah :]).
	["ClientSided"] = true, --// Set to true if all effects w/ regards to the physical instances (i.e. BaseParts) are run on the client (make sure to add the TDL2Client script to StarterPlayerScripts if true)
	["RegionCheckTime"] = 5, --// The time it checks for the creation of new regions (probably doesn't have to be that low of a number)
	["Tween"] = true, --// Turn this off if you do not want tween changes and want hard changes
	
	--// Audio Settings
	["GenerateNewRandomSounds"] = false, --// Generates new random sounds each time (each Sound is destroyed once it is finished if set to true)
	["WaitForRandomSoundToEnd"] = false, --// Waits for a random sound that is set to play to finish before looping

	--// Lighting Settings
	["ChangingInstanceChildrenOfWorkspace"] = false, --// Allows you to improve the performance of the script if all affected instances are direct children of Workspace

	--// Region Settings
	["AudioRegionTweenInformation"] = TweenInfo.new( --// Tween information for when a player enters an audio region
		3, --// Recommended to only adjust the time variable (default set to 3 seconds)
		Enum.EasingStyle.Linear
	),
	["BackupValidation"] = 5, --// This is the amount of time between when the server does backup validation
	["LightingRegionTweenInformation"] = TweenInfo.new( --// Tween information for when a player enters a lighting region
		3, --// Recommended to only adjust the time variable (default set to 3 seconds)
		Enum.EasingStyle.Linear
	),
	--// Time Settings

	["AutomaticTransitions"] = true, --// Turn this off if you want to manually transition and remove the time based auto transitions
	["AdjustmentTime"] = 5, --// This is the amount of time alloated to the script to detect how fast time passes in your day/night script.  5 seconds is the recommended default.  Note: if DetectIndependentTimeChange is false and IE's native day/night integration is used, the adjustment will be automatically calculated - i.e. no wait and detect
	["CheckTime"] = 1, --// The time in seconds that the script checks for Period changes, if AutomaticTransitions is set to false, you don't need to worry about this
	["DetectIndependentTimeChange"] = false, --// Set to true if you are not using the built-in day/night cycle.  Key notes, please read: this will make the system take longer to initialize, because it will wait for the amount of seconds specified in AdjustmentTime to try to accurately gauage how fast time passes in-game.  If you are using the day/night cycle for IE, set this to true.  If you want the speed enhancement but are using a different day/night cycle, consider switch to the built in one for IE to get the speed boost and more accurate adjusted time periods.
	["EnableDayNightTransitions"] = true, --// Turns on day/night cycle
	["EnableSorting"] = true, --// Setting to true reduces the work done by the script, however, this denies the ability to make changes to ClockTime or TimeOfDay via admin or other controls and have the script automatically follow.  Set to false if you would like to preserve the ability to make changes in admin.
	["TimeEffectTweenInformation"] = TweenInfo.new(
		20, --// Recommended to only adjust the time variable (default set to 20 seconds)
		Enum.EasingStyle.Linear
		),
	["TimeForDay"] = 2, --// The amount of minutes it takes to go from 0600 to 1800
	["TimeForNight"] = 2, --// The amount of minutes it takes to go from 1800 to 0600

	--// Weather Settings
	["WeatherTweenInformation"] = TweenInfo.new(
		10, --// Recommended to only adjust the time variable (default set to 10 seconds)
		Enum.EasingStyle.Linear
	)
}

return module
