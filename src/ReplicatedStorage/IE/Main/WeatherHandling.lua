local Main: ModuleScript = script.Parent

local AudioHandling = require(Main.AudioHandling)
local LightingHandling = require(Main.LightingHandling)

local module = {}

--// Clears the weather, Type is either "Audio" or "Lighting" (this function should not be manually called)
function module:ClearWeather(Type: string)
    if Type == "Audio" then
        AudioHandling:ClearWeather()
    elseif Type == "Lighting" then
        LightingHandling:ClearWeather()
    end
end

return module