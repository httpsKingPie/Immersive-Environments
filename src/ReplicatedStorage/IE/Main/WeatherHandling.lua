local Main: ModuleScript = script.Parent

local AudioHandling = require(Main.AudioHandling)
local InternalVariables = require(Main.InternalVariables)
local LightingHandling = require(Main.LightingHandling)
local PackageHandling = require(Main.PackageHandling)

local module = {}

--// Clears the weather, Type is either "Audio" or "Lighting" (this function should not be manually called)
function module:ClearWeather(PackageType: string)
    if PackageType == "Audio" then
        AudioHandling:ClearWeather()
    elseif PackageType == "Lighting" then
        LightingHandling:ClearWeather()
    end
end

--// Finds whether there is a weather exemption for the package (assumes this is the same across all components)
function module:CheckForWeatherExemption(PackageType: string, PackageScope: string, PackageName: string)
    local WeatherExemption: boolean

    local Package = PackageHandling:GetPackage(PackageType, PackageScope, PackageName)

    for _, ComponentSettings in pairs (Package["Components"]) do
		WeatherExemption = ComponentSettings["GeneralSettings"]["WeatherExemption"]
		break
	end

    return WeatherExemption
end

--// Returns false if there is no weather package and a string (which can be treated essentially as 'true')
function module:CheckForActiveWeather(PackageType: string)
    return InternalVariables["Current Package"][PackageType]["Weather"]
end

return module