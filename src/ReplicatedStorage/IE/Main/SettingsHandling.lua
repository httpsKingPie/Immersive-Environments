local Main = script.Parent
local IEFolder = Main.Parent

local Settings = require(IEFolder.Settings)
local InternalVariables = require(Main.InternalVariables)

local AudioSettings = IEFolder:FindFirstChild("AudioSettings")
local LightingSettings = IEFolder:FindFirstChild("LightingSettings")

local module = {
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
}

function module.ApplyDefaultSettings()
	--// Default settings

	module["AlwaysCheckInstances"] = false
	module["ClientSided"] = true
	module["RegionCheckTime"] = 5
	module["Tween"] = true
	
	--// Audio Settings
	module["GenerateNewRandomSounds"] = false
	module["WaitForRandomSoundToEnd"] = false

	--// Lighting Settings
	module["ChangingInstanceChildrenOfWorkspace"] = false

	--// Region Settings
	module["AudioRegionTweenInformation"] = TweenInfo.new(
		3,
		Enum.EasingStyle.Linear
	)
	module["BackupValidation"] = 5
	module["LightingRegionTweenInformation"] = TweenInfo.new(
		3,
		Enum.EasingStyle.Linear
	)
	--// Time Settings

	module["AutomaticTransitions"] = true
	module["AdjustmentTime"] = 5
	module["CheckTime"] = 1
	module["DetectIndependentTimeChange"] = false
	module["EnableDayNightTransitions"] = true
	module["EnableSorting"] = true
	module["TimeEffectTweenInformation"] = TweenInfo.new(
		20,
		Enum.EasingStyle.Linear
	)
	module["TimeForDay"] = 10
	module["TimeForNight"] = 10

	--// Weather Settings
	module["WeatherTweenInformation"] = TweenInfo.new(
		10,
		Enum.EasingStyle.Linear
	)
end

--// Types are like Audio, Lighting, Weather
function module:GetRegionSettings(RegionName: string, Type: string)
    if not self[Type] then
        warn("Type: ".. tostring(Type) .. ", not found within SettingsHandling")
        return nil
    end

    if not self[Type]["Region"] then
        warn("Current Type: ".. tostring(Type) .. ", is not set to have Regions")
        return nil
    end

	if self[Type]["Region"][RegionName] then
		return self[Type]["Region"][RegionName]
	else
		warn("Region Setting: ".. tostring(RegionName).. ", not found within SettingsHandling for Type: ".. tostring(Type))
		return nil
	end
end

function module:GetServerSettings(SettingName: string, Type: string)
    if not self[Type] then
        warn("Type: ".. tostring(Type) .. ", not found within SettingsHandling")
        return nil
    end

    if not self[Type]["Server"] then
        warn("Current Type: ".. tostring(Type) .. ", is not set to have a Server")
        return nil
    end

	if self[Type]["Server"][SettingName] then
		return self[Type]["Server"][SettingName]
	else
		warn("Server Setting: ".. tostring(SettingName).. ", not found within SettingsHandling for Type: ".. tostring(Type))
		return nil
    end
end

function module:GetWeatherSettings(SettingName: string, Type: string)
	if not self[Type] then
        warn("Type: ".. tostring(Type) .. ", not found within SettingsHandling")
        return nil
	end

	if not self[Type]["Weather"] then
        warn("Current Type: ".. tostring(Type) .. ", is not set to have a Weather")
        return nil
    end
	
	if self[Type]["Weather"][SettingName] then
		return self[Type]["Weather"][SettingName]
	else
		warn("Weather Setting ".. tostring(SettingName).. " not found within ".. tostring(Type))
		return nil
	end
end

function module:GenerateLightingSettings()
	if not LightingSettings then
		return
	end

	local LightingRegionSettings = LightingSettings:FindFirstChild("RegionSettings")
	local LightingServerSettings = LightingSettings:FindFirstChild("ServerSettings")
	local LightingWeatherSettings = LightingSettings:FindFirstChild("WeatherSettings")

	if LightingRegionSettings then
		local RegionDesendants = LightingSettings.RegionSettings:GetDescendants()

		for i = 1, #RegionDesendants do
			if RegionDesendants[i]:IsA("ModuleScript") then
				if self["Lighting"]["Region"][RegionDesendants[i].Name] == nil then
					self["Lighting"]["Region"][RegionDesendants[i].Name] = require(RegionDesendants[i])
				else
					warn("Lighting Region Setting already exists for ".. RegionDesendants[i].Name.. ".  Make sure settings with the same name do not exist")
				end
			end
		end
	end

	if LightingServerSettings then
		local ServerDescendants = LightingSettings.ServerSettings:GetDescendants()

		local Count = 0

		for i = 1, #ServerDescendants do
			if ServerDescendants[i]:IsA("ModuleScript") then
				if self["Lighting"]["Server"][ServerDescendants[i].Name] == nil then
					self["Lighting"]["Server"][ServerDescendants[i].Name] = require(ServerDescendants[i])
					Count = Count + 1
				else
					warn("Lighting Server Setting already exists for ".. ServerDescendants[i].Name.. ".  Make sure settings with the same name do not exist")
				end
			end
		end

		InternalVariables["TotalLightingIndexes"] = Count
	end

	if LightingWeatherSettings then
		local WeatherDescendants = LightingSettings.WeatherSettings:GetDescendants()

		for i = 1, #WeatherDescendants do
			if WeatherDescendants[i]:IsA("ModuleScript") then
				if self["Lighting"]["Weather"][WeatherDescendants[i].Name] == nil then
					self["Lighting"]["Weather"][WeatherDescendants[i].Name] = require(WeatherDescendants[i])
				else
					warn("Weather Setting already exists for ".. WeatherDescendants[i].Name.. ".  Make sure settings with the same name do not exist")
				end
			end
		end
	end

	InternalVariables["LightingSettingTablesBuilt"] = true
end

function module:GenerateAudioSettings()
	if not AudioSettings then
		return
	end
	
	local AudioRegionSettings = AudioSettings:FindFirstChild("RegionSettings")
	local AudioServerSettings = AudioSettings:FindFirstChild("ServerSettings")
	local AudioWeatherSettings = AudioSettings:FindFirstChild("WeatherSettings")

	if AudioRegionSettings then
		local RegionDescendants = AudioSettings.RegionSettings:GetDescendants()

		for i = 1, #RegionDescendants do
			if RegionDescendants[i]:IsA("ModuleScript") then
				if self["Audio"]["Region"][RegionDescendants[i].Name] == nil then
					self["Audio"]["Region"][RegionDescendants[i].Name] = require(RegionDescendants[i])
				else
					warn("Audio Region Setting already exists for ".. RegionDescendants[i].Name.. ".  Make sure settings with the same name do not exist")
				end
			end
		end
	end

	if AudioServerSettings then
		local ServerDescendants = AudioSettings.ServerSettings:GetDescendants()

		local Count = 0

		for i = 1, #ServerDescendants do
			if ServerDescendants[i]:IsA("ModuleScript") then
				if self["Audio"]["Server"][ServerDescendants[i].Name] == nil then
					self["Audio"]["Server"][ServerDescendants[i].Name] = require(ServerDescendants[i])
					Count = Count + 1
				else
					warn("Audio Server Setting already exists for ".. ServerDescendants[i].Name.. ".  Make sure settings with the same name do not exist")
				end
			end
		end

		InternalVariables["TotalAudioIndexes"] = Count
	end

	if AudioWeatherSettings then
		local WeatherDescendants = AudioSettings.WeatherSettings:GetDescendants()

		for i = 1, #WeatherDescendants do
			if WeatherDescendants[i]:IsA("ModuleScript") then
				if self["Audio"]["Weather"][WeatherDescendants[i].Name] == nil then
					self["Audio"]["Weather"][WeatherDescendants[i].Name] = require(WeatherDescendants[i])
				else
					warn("Weather Setting already exists for ".. WeatherDescendants[i].Name.. ".  Make sure settings with the same name do not exist")
				end
			end
		end
	end

	InternalVariables["AudioSettingTablesBuilt"] = true
end

function module.WaitForSettings(Type)
	if not InternalVariables[tostring(Type).. "SettingTablesBuilt"] then
		warn(tostring(Type).. " does not have SettingsTables stored in InternalVariables")
		return
	end

	while InternalVariables[tostring(Type).. "SettingTablesBuilt"] == false do
		task.wait(.1)
	end
end

function module:Run()
    module:GenerateAudioSettings()
	module:GenerateLightingSettings()

	if Settings["DefaultSettings"] then
		module.ApplyDefaultSettings()
	end
end

return module