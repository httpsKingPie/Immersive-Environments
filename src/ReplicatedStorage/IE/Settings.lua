local module = {
	
	--// General Settings
	
	["DefaultSettings"] = true, --// Set to true if you just want to run this with recommend settings
	["AlwaysCheckInstances"] = false, --// Will run a search through workspace to check for instance changes every time if this is set to true.  Recommended to set to false if the number of instances never changes or if StreamingEnabled is not enabled (aka StreamingDisabled - hahahahahahahahhah :]).
	["ClientSided"] = true, --// Set to true if all effects w/ regards to the physical instances (i.e. BaseParts) are run on the client (make sure to add the TDL2Client script to StarterPlayerScripts if true)
	["RegionCheckTime"] = 5, --// The time it checks for the creation of new regions (probably doesn't have to be that low of a number)
	["Tween"] = true, --// Turn this off if you do not want tween changes and want hard changes
	
	--// Lighting Settings
	
	["AdjustmentTime"] = 5, --// This is the amount of time alloated to the script to detect how fast time passes in your day/night script.  5 seconds is the recommended default
	["AutomaticTransitions"] = true, --// Turn this off if you want to manually transition to different lighting periods
	["ChangingInstanceChildrenOfWorkspace"] = false, --// Allows you to improve the performance of the script if all affected instances are direct children of Workspace
	["CheckTime"] = 1, --// The time in seconds that the script checks for Lighting Period changes, if AutomaticTransitions is set to false, you don't need to worry about this
	["EnableSorting"] = true, --// Setting to true reduces the work done by the script, however, this denies the ability to make changes to ClockTime or TimeOfDay via admin or other controls and have the script automatically follow.  Set to false if you would like to preserve the ability to make changes in admin.
	["LightingTweenInformation"] = TweenInfo.new(
		20, --// Recommended to only adjust the time variable (default set to 20 seconds)
		Enum.EasingStyle.Linear
		),
	
	--// Audio Settings
	
	["AudioTweenInformation"] = TweenInfo.new(
		1.5, --// Recommended to only adjust the time variable (default set to 1.5 seconds)
		Enum.EasingStyle.Linear
	),
	
	--// Region Settings
	
	["BackupValidation"] = 5, --// This is the amount of time between when the server does backup validation
	["EventBuffer"] = .2, --// This is the amount of time that passes for IE to properly validate current regions.  Probably won't have to change this but just in case
	["EventDifference"] = .5, --// This is the amount of time that must separate events to be considered for validation.  If more than this time has passed, then likely only event was fired
}

return module