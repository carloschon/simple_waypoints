# Simple Waypoints

------

A minetest 0.4.17+ mod that lets you set waypoints/beacons at current position.

#### How it works


- Just use the following commands
```
/wc "waypoint name" to create a waypoint at current position.
/wd "waypoint name" to delete a waypoint.
/wt "waypoint name" to teleport to a waypoint.
/wl list your waypoints in table format e.g. "1 Home (x,y,z)".
```


#### Installation

Extract zip to the mods folder.

#### TODO

-The color of the beacons is chosem randomly on placement; I may tweak this in the future or remove it altogether.
The HUD element is nice to have, though.

-Implement some kind formspec GUI to make the mod easier to use. This will become more practical if and when the engine
supports custom keybindings.