--[[
Hey Ahlvie!

97% of the module is working as intended, but I'm planning to tighten up a couple of the loose screws and refine the module (eventually open sourcing it all)

The module basically works by allowing you to specify lighting periods (ranges of time) and control what the lighting looks like during that time

You can also control different instances and manipulate them accordingly.  The module is designed to work with Terrain, Lighting Service, children of Lighting Service (Atmosphere, BloomEffect, BlurEffect, ColorCorrectionEffect, Sky), BaseParts, Fire, ParticleEmitters, PointLights, SpotLights, and SurfaceLights
(it can really handle any class though, so feel free to subsitute any of those classes with another and it should work fine)

You can also work with models that might contain more than one part and treat them as one instance, essentially.
Ex: if you had a lantern with a glowing part, a point light, and a particle emitter you could essentially control all of those and assign various properties to them within the lighting period.  I call these complex instances in the script as a way for me to manage it mentally

All instances (except those in Lighting Service, Lighting Service itself, and Terrain) contain a couple custom properties too
ChanceOfChange which is a percentage chance that the light will change - since it would be unrealistic to expect all the lights to turn on at night, you can play with things and create a realistic seeming effect
IsLight which is basically of way of having the script determine whether the instance is a light (more to follow three lines below)
IsLightOn which basically determines whether the script thinks that the light is "on"

The Lighting Period itself also has a property in its GeneralSettings table, at the top, called AdjustOnlyLightsOn
This basically makes it so that, if true, the changes specified in the Lighting Period will only affect instances that the script as determined "are lights" and "are on"
This could enable you to create effects such as fires simmering down as the night draws on, particle changes, tint shifts, lights occasionally turning off as night progresses, light color changing throughout the day for those on

Also within the GeneralSettings area is a field where you can specify the time ranges of each lighting period

--

There's a module called FullSettingsExample that is pretty much as beefy as the settings can be (although you could definitely add more if you liked).  You can include as many or as little properties as you like - I included another module called SmallSettingsExample to show that part too

Since I haven't seen your workspace flow, I wasn't sure how you best organized your work so I tried to make it as all encompassing as possible

Right now it's set up so that you just drop your settings in the folder called LightingSettings or WeatherSettings.  You can also add folders and it won't affect anything like https://i.vgy.me/sTgPNQ.png

LightingSettings and WeatherSettings are pretty much identical except that LightingSettings are triggered by timings and WeatherSettings have to be called manually.  Aside from that, they are almost identical

--

Some other notes:

The time for the cycles to start is automatically calcuated based on the rate of time passing in game.  This way, the lighting periods will actually begin when you specify, and you don't have to manually try times or guesstimate, it also means that day/night scripts can be pretty much anything and it will still work

The script can be client sided, again wasn't sure how you liked your workflow, so I made sure to add that capability.  There's a script in StarterPlayerScript that allows for that.  There is a small change I need to make to this later, but it should work fine for the time being

There's further settings within the Settings module, if you want to tweak the settings any

If there's any issues with the script, please let me know.  I've been doing my best to test as I go along, but there's surely things that I've missed

If there's anything that I overlooked, also let me know and I'll get to adding that
]]