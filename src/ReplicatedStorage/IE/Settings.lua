--[[
	Settings overview
	All settings have recommended configurations and a note as to why it is recommended

	--//////////////////////////////////////////////////////////////

	All Lighting Instances Are Children Of Workspace
		Allows you to improve the performance of the script if all affected instances are direct children of Workspace

		RECOMMENDED: Developer-choice
			This depends on your specific project

	Always Check Instances
		Will run a search through workspace to check for instance changes every time if this is set to true.  IE will internally store all the instances otherwise

		RECOMMENDED: false
			(if the number of instances never changes or if StreamingEnabled is disabled)

	Check Time
		The time, in seconds, that IE checks for period changes.  The lower the number, the more accurate.  

		A few notes: 
			If 'Automatic Transitions' is set to false, you do NOT need to worry about this setting (it won't be used)
			If you're wondering 'Why are you running a loop every 'X' seconds, instead of using an event?' here's an answer
				First of all, good question
				Most time periods are large enough that binding a listener to an event (and do IE related logic) would result in a significant performance hit
				If a period lasts several in-game hours, then it makes no sense to perform calculations when a small fraction of an hour passes per few seconds
				You get a performance buff by instead checking every 'X' second versus every single time a change to ClockTime/TimeOfDay occurs - and it makes more sense logically too

		RECOMMENDED: 1
	
	Client Sided
		Whether IE effects should happen on the client versus the server
		IE is still able to be controlled from the server

		RECOMMENDED: true
			More latitude to mess around with lighting settings on the client

	CullingService
		Whether CullingService (https://devforum.roblox.com/t/cullingservice-custom-client-sided-cullingstreaming-module/1343667) is active in your place

		If it is, this makes IE compatible

		RECOMMENDED: Developer-choice
			Only enable if CullingService is being used in your project and has actively been set-up

	Detect External Day Night Cycle
		Enable if you are not using the built-in day/night cycle and are using another one

		If you enable, please read below:
			It is highly recommended to use the day/night cycle include in IE
			Using an external day/night cycle will make IE take longer to initialize
				IE will wait the length of time in 'Detection Time' to attempt to accurately gauge how fast time passes in-game

		RECOMMENDED: Developer-choice
			This depends on the set-up of your project; however, as mentioned it is recommended to use IE's day/night cycle

	Detection Time
		This is the amount of time alloated to the script to detect how fast time passes in your day/night script.  
		5 seconds is the recommended default.
		
		*Note* If Detect External Day Night Cycle is false and IE's built-in day/night cycle is used, the adjustment will be automatically calculated — i.e. no wait and detect

		RECOMMENDED: Developer-choice
			This depends on the set-up of your project; however, as mentioned it is recommended to use IE's day/night cycle

	Enable Day Night Cycle
		Enables the built-in day/night cycle.  Configure the lengths of day and night in the 'Time' setting category

		RECOMMENDED: false
			Using IE's built-in day/night cycle yields a more performant and coherent system.  IE's day/night cycle also allows for differently paced day and night time rates

	Generate Unique Random Sounds Each Iteration
		Specifies whether multiple random sound instances can exist, or if it's just one

		RECOMMENDED: true
			If frequency and sound length are not aligned (or if 'Wait For Random Sounds To End' is set to false) there can be sound overlap
			Overall, it just makes it less complicated to freely generate multiple random sound instances

	Sort Time Cycles
		Internal change with how different lighting and audio cycles are tracked

		Pros: 
			Better performance (have not run specific performance tests, so the scale is unknown)
		Cons: 
			Cannot make changes to ClockTime or TimeOfDay via admin or other controls
			*Note* Day/night cycles scripts (including the one built into IE) are fine

		RECOMMENDED: Developer-choice
			This depends on the set-up and aims of your project

	Time
		The amount of real minutes it takes to go from 0600 to 1800 (day) and 1800 to 0600 (night)

		RECOMMENDED: Developer-choice
			This depends on the vibe you are going for in your project

	Tween
		Turn this off if you do not want tween changes and want hard changes

		RECOMMENDED: true
			More visually pleasing

	Tween Information
		The tween information for audio and lighting changes

		RECOMMENDED: Developer-choice
			This depends on the effects you're going for, the settings of your day/night cycles, where you decide to apply regions, etc.
			It is recommended to only adjust the first number (which is the time of the tween)

	Wait For Random Sounds To End
		Waits for randomly generated sounds to finish before new ones can be generated (frequency is adjusted in relevant component settings for an audio package)

		RECOMMENDED: false
			True randomization doesn't care if the sound is still playing!
		
]]

local module = {
	["All Lighting Instances Are Children Of Workspace"] = false,

	["Always Check Instances"] = true,

	["Check Time"] = 1,
	
	["Client Sided"] = true,

	["CullingService"] = false,

	["Detect External Day Night Cycle"] = false,

	["Detection Time"] = 5,

	["Enable Day Night Cycle"] = true,

	["Generate Unique Random Sounds Each Iteration"] = true,

	["Sort Time Cycles"] = true,

	["Time"] = {
		["Day"] = 2,
		["Night"] = 2,
	},
	
	["Tween"] = true,

	["Tween Information"] = {
		--// Entering a region or 
		["Region"] = TweenInfo.new(
			3,
			Enum.EasingStyle.Linear
		),

		["Time"] = TweenInfo.new(
			20, --// Recommended to only adjust the time variable (default set to 20 seconds)
			Enum.EasingStyle.Linear
		),
		
		["Weather"] = TweenInfo.new(
			10, --// Recommended to only adjust the time variable (default set to 10 seconds)
			Enum.EasingStyle.Linear
		),
	},

	["Wait For Random Sounds To End"] = false,
}

return module
