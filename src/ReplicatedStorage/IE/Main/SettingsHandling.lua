local Main = script.Parent
local IEFolder = Main.Parent

local InternalVariables = require(Main.InternalVariables)

local AudioSettings = IEFolder.AudioSettings
local LightingSettings = IEFolder.LightingSettings

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

function module:GetWeatherSettings(Type: string, SettingName: string)
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
	local Count = 0

	local RegionDesendants = LightingSettings.RegionSettings:GetDescendants()
	local ServerDescendants = LightingSettings.ServerSettings:GetDescendants()
	local WeatherDescendants = LightingSettings.WeatherSettings:GetDescendants()

	for i = 1, #RegionDesendants do
		if RegionDesendants[i]:IsA("ModuleScript") then
			if self["Lighting"]["Region"][RegionDesendants[i].Name] == nil then
				self["Lighting"]["Region"][RegionDesendants[i].Name] = require(RegionDesendants[i])
			else
				warn("Lighting Region Setting already exists for ".. RegionDesendants[i].Name.. ".  Make sure settings with the same name do not exist")
			end
		end
	end

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

	for i = 1, #WeatherDescendants do
		if WeatherDescendants[i]:IsA("ModuleScript") then
			if self["Lighting"]["Weather"][WeatherDescendants[i].Name] == nil then
				self["Lighting"]["Weather"][WeatherDescendants[i].Name] = require(WeatherDescendants[i])
			else
				warn("Weather Setting already exists for ".. WeatherDescendants[i].Name.. ".  Make sure settings with the same name do not exist")
			end
		end
	end

	InternalVariables["TotalLightingIndexes"] = Count
	InternalVariables["LightingSettingTablesBuilt"] = true
end

function module:GenerateAudioSettings()
	local Count = 0
	
	local RegionDescendants = AudioSettings.RegionSettings:GetDescendants()
	local ServerDescendants = AudioSettings.ServerSettings:GetDescendants()
	local WeatherDescendants = AudioSettings.WeatherSettings:GetDescendants()

	for i = 1, #RegionDescendants do
		if RegionDescendants[i]:IsA("ModuleScript") then
			if self["Audio"]["Region"][RegionDescendants[i].Name] == nil then
				self["Audio"]["Region"][RegionDescendants[i].Name] = require(RegionDescendants[i])
			else
				warn("Audio Region Setting already exists for ".. RegionDescendants[i].Name.. ".  Make sure settings with the same name do not exist")
			end
		end
	end

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

	for i = 1, #WeatherDescendants do
		if WeatherDescendants[i]:IsA("ModuleScript") then
			if self["Audio"]["Weather"][WeatherDescendants[i].Name] == nil then
				self["Audio"]["Weather"][WeatherDescendants[i].Name] = require(WeatherDescendants[i])
			else
				warn("Weather Setting already exists for ".. WeatherDescendants[i].Name.. ".  Make sure settings with the same name do not exist")
			end
		end
	end

	InternalVariables["TotalAudioIndexes"] = Count
	InternalVariables["AudioSettingTablesBuilt"] = true
end

function module.WaitForSettings(Type)
	if not InternalVariables[tostring(Type).. "SettingTablesBuilt"] then
		warn(tostring(Type).. " does not have SettingsTables stored in InternalVariables")
		return
	end

	while InternalVariables[tostring(Type).. "SettingTablesBuilt"] == false do
		wait(.1)
	end
end

function module.Run()
    module:GenerateAudioSettings()
    module:GenerateLightingSettings()
end

return module