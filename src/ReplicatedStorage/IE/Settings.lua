local module = {
	
	--// General Settings
	
	["DefaultSettings"] = true, --// Set to true if you just want to run this with recommend settings
	["AlwaysCheckInstances"] = false, --// Will run a search through workspace to check for instance changes every time if this is set to true.  Recommended to set to false if the number of instances never changes or if StreamingEnabled is not enabled (aka StreamingDisabled - hahahahahahahahhah :]).
	["ClientSided"] = true, --// Set to true if all effects w/ regards to the physical instances (i.e. BaseParts) are run on the client (make sure to add the TDL2Client script to StarterPlayerScripts if true)
	["RegionCheckTime"] = 5, --// The time it checks for the creation of new regions (probably doesn't have to be that low of a number)
	["Tween"] = true, --// Turn this off if you do not want tween changes and want hard changes
	
	--// Lighting Settings
	
	["AdjustmentTime"] = 5, --// This is the amount of time alloated to the script to detect how fast time passes in your day/night script.  5 seconds is the recommended default.  Note: if DetectIndependentTimeChange is false and IE's native day/night integration is used, the adjustment will be automatically calculated - i.e. no wait and detect
	["ChangingInstanceChildrenOfWorkspace"] = false, --// Allows you to improve the performance of the script if all affected instances are direct children of Workspace
	
	--// Audio Settings
	
	["AudioTweenInformation"] = TweenInfo.new(
		3, --// Recommended to only adjust the time variable (default set to 3 seconds)
		Enum.EasingStyle.Linear
	),
	["GenerateNewRandomSounds"] = false, --// Generates new round sounds each time (each Sound is destroyed once it is finished if set to true)
	["WaitForRandomSoundToEnd"] = false, --// Waits for a random sound that is set to play to finish before looping

	--// Region Settings
	
	["BackupValidation"] = 5, --// This is the amount of time between when the server does backup validation
	["DetectIndependentTimeChange"] = true, --// Used when the day/night cycle used is not the native one for IE.  This will delay the amount of time it takes to determine the adjustment (see the AdjustmentTime setting)

	--// Time Settings
	["AutomaticTransitions"] = true, --// Turn this off if you want to manually transition and remove the time based auto transitions
	["CheckTime"] = 1, --// The time in seconds that the script checks for Lighting Period changes, if AutomaticTransitions is set to false, you don't need to worry about this
	["EnableDayNightTransitions"] = true, --// Turns on day/night cycle
	["EnableSorting"] = true, --// Setting to true reduces the work done by the script, however, this denies the ability to make changes to ClockTime or TimeOfDay via admin or other controls and have the script automatically follow.  Set to false if you would like to preserve the ability to make changes in admin.
	["RecheckDayNight"] = false, --// Use this if day/night time passage is not continous (ex: TimeForDay and TimeForNight are different numbers)
	["TimeEffectTween"] = TweenInfo.new(
		20, --// Recommended to only adjust the time variable (default set to 20 seconds)
		Enum.EasingStyle.Linear
		),
	["TimeForDay"] = 12, --// The amount of minutes it takes to go from 0600 to 1800
	["TimeForNight"] = 12, --// The amount of minutes it takes to go from 1800 to 0600
}

return module
