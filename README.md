
## Table of Contents

### Summary

Immersive Environments (IE) is the sequel to [Truly Dynamic Lighting](https://devforum.roblox.com/t/truly-dynamic-lighting-module-advanced-lighting-capabilities-and-control/508173) (aka TDL).  Originally named Truly Dynamic Lighting 2, the focus of the project was shifted to overhaul the initial framework and direction of the system, while also meeting all of the current, anticipated, and potential needs of my current project.  IE features all of the same settings as TDL, and also features a host of other new features, settings, and optimizations to expand developer creative control.  The final product is a robust system that allows for time-based and region-based lighting and audio control.  However, this barely scratches the surface of IE.  Please continue reading for a more in-depth explanation of what sets IE apart from TDL.

### A more in-depth explanation

#### Lighting

Immersive Environments uses a class-based conversion system that is tailored towards classes normally placed in the Lighting and Workspace services, as well as the Lighting service itself.  However, it is set up to work with any class of instances 

(Warning - it is expected that IE will be compatible with nearly all class properties, however, using it on untested class properties may result in errors!  With this in mind, please note that any changes regarding classes that are children of the Lighting service are possible to use with classes of other services!)

Create different lighting settings, or profiles, depending on either time or region (more on this in the Time and Regions sub-sections).  Here’s an example of how this might play out

**Time based example**

As the sun begins to set in-game, smoothly tween to new lighting settings by changing depth of field to reduce vision, adjust the color correction to a slightly more blue effect, and “turn on” torches by enabling fire, smoke, and a particle emitter for greater effect.  At midnight, reduce the depth of field again, and make minor changes to lighting effects.  Reduce the fire and smoke of the torch to visibly give the torch a life of its own.  As morning creeps, extinguish the lights, make changes to the game’s sun rays to prepare for a bright and beautiful start to the new day.  

**Region based example**

A player ventures into a local blacksmith’s forge.  As they enter the house, the color correction shifts to become more orange and the blur increases because of the heat.  Various furnaces begin to smoke as well.  Once the player leaves this house, their lighting settings quickly resync to that of the server.  

These are immersive environments.


### Key Features
