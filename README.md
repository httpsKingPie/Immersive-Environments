
# Table of Contents

* TOC
{:toc}

# Summary

Immersive Environments (IE) is the successor to [Truly Dynamic Lighting](https://devforum.roblox.com/t/truly-dynamic-lighting-module-advanced-lighting-capabilities-and-control/508173) (aka TDL).  Originally named Truly Dynamic Lighting 2, the focus of the project was shifted to overhaul the initial framework and direction of the system, while also meeting all of the current, anticipated, and potential needs of my current project.  IE features all of the same settings as TDL, and also features a host of other new features, settings, and optimizations to expand developer creative control.  The final product is a robust system that allows for time-based and region-based lighting and audio control.  However, this barely scratches the surface of IE.  Please continue reading for a more in-depth explanation of what sets IE apart from TDL.

# A more in-depth explanation

## Lighting

Immersive Environments uses a class-based manipulation system that is tailored towards classes normally placed in the Lighting and Workspace services, as well as the Lighting service itself.  However, it is set up to work with any class of instances 

(Warning - it is expected that IE will be compatible with nearly all class properties, however, using it on untested class properties may result in errors!  With this in mind, please note that any changes regarding classes that are children of the Lighting service are possible to use with classes of other services!)

Create different lighting settings, or profiles, depending on either time or region (more on this in the Time and Regions sub-sections).  Here’s an example of how this might play out

**Time based example**

As the sun begins to set in-game, smoothly tween to new lighting settings by changing depth of field to reduce vision, adjust the color correction to a slightly more blue effect, and “turn on” torches by enabling fire, smoke, and a particle emitter for greater effect.  At midnight, reduce the depth of field again, and make minor changes to lighting effects.  Reduce the fire and smoke of the torch to visibly give the torch a life of its own.  As morning creeps, extinguish the lights, make changes to the game’s sun rays to prepare for a bright and beautiful start to the new day.  Ambitiously, (since IE is a class based manipulation system) have the doors of shops smoothly open as the business day begins.

**Region based example**

A player ventures into a local blacksmith’s forge.  As they enter the house, the color correction shifts to become more orange and the blur increases because of the heat.  Various furnaces begin to smoke as well.  Once the player leaves this house, their lighting settings quickly resync to that of the server.  

These are immersive environments.

IE also features unique lighting settings and capabilities that set it apart from other similar systems.

### Randomization

In your lighting settings, you can create randomization for each instance affected.  This is great for generating dynamic environments (ex: cities where 80% of the lights turn on at night).  

### Complex Instance Support

One of TDL’s strongest selling points was its ability to control complex instances (previously known/referred to as multi-instances).  If you are not familiar, please imagine a lantern model.  The lantern model might have an actual part (yellow and neon material), a participle emitter for effects, and a point light for providing light effects.  IE allows you to fully control this complex instance by indicating a reference part, indicating the relationships of instances that you want changed (ex: siblings, children, descendants, parents, etc.)

Complex instances also support randomization, so you don’t have to worry about smoke appearing while the rest of the light is not on, or other weird situations.

### Denote lights that are "on"

This is tougher to explain, so please refer to the time-based example above.  Imagining that we have 200 torches (each with a 50% chance of turning on), we will have approximately 100 torches once night falls.  When midnight comes, we only want to reduce the smoke and particle emitter properties of torches that are on.  It would look strange if some suddenly sprang to life, and might ruin the effect.  You can denote these torches as lights that are “on” within the settings of both periods so that lighting changes only affect lights that are “on” or that after a lighting period comes to pass, the lights are considered “on”.  This can be applied creatively to generate unique game environments.  

## Audio

Immersive Environments utilizes a categorical audio definition system.  Audio is split into four different categories: the SoundService, server sounds, region sounds, and shared sounds.  The later two categories are only used for regions.

The SoundService is a built in service, but it is criminally under-used by developers.  The SoundService allows for manipulations to AmbientReverb, which adjusts the ambient sound environment preset used, and other useful settings for controlling 3D sound.  If you are not familiar with it, I highly recommend doing some research on why this service is a great tool.

Server sounds are sounds that the entire server can hear.  An example of this is a nature ambience for a game that takes place in a forest.

Region sounds are sounds native to a region.  An example of this are the sounds of background noise when entering a restaurant.  

Shared sounds are sounds that are native to multiple regions.  An example of this is a three room building, with music playing from a radio in one room.  Using shared sounds, you can precisely tailor how loud the music of the radio or other actives sounds behave in each room.  This is particularly useful while also combining SoundService manipulation (AmbientReverb in most cases).  

While the lighting system is, in a broad sense, a class manipulation system - the audio system is tailored specifically for audio related instances.  Instances in the class of SoundEffect are not currently supported, however, those may be added in at a later point to expand developer creative control.  Audio behaves similarly to lighting, in the sense that you can control for different audio triggers, depending on time or region.  

### Implementing Randomization

The IE audio system also features a special category of random sounds.  These random sounds are native only to regions, but allow for randomized sound generation.  Developers can specify the frequency and chance of playing that a sound has.  An example of this, is the sound of a gun being fired.  By manipulating the frequency in which the sound might play and the probability that the sound actually does play, a truly unique environment such as a battlefield can be easily generated. 

## Weather

Immersive Environments features a weather control system for developers to leverage.  In a sense, the weather system can be thought of as manual triggers/overrides for the current lighting or audio cycles.  IE separates weather into lighting and audio categories.  This allows developers to mix and match weather settings easily.  An example of this is having one lighting profile for a thunderstorm, but three audio profiles for the sound of thunder and lightning, to create variety.  

Weather, by default, halts the cycle of either lighting or audio (depending on whether lighting-based or audio-based weather is active).  Developers can control whether regions supersede active weather.  For example, regions that are outdoors may seem unnatural if they are unaffected by weather.  Regions that are indoors may have their effects ruined if their settings suddenly change, despite not being close to the outdoors at all.  

Because weather mixes both lighting and audio, it is possible to generate custom events that are not inherently weather or climate related.  Through tailored configuration, it is possible to generate fireworks displays, firestorms, sudden ambience changes for an environment like a club, etc.  

### Key Features
