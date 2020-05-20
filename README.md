# Simple Waypoints

------

A minetest 0.4.17+ mod that lets you set waypoints/beacons at current position.

![beacon](img/screenie1.png) ![waypoints GUI](img/screenie2.png)

#### How it works
There's a text interface and a GUI. Use whichever suits you best.


TEXT INTERFACE:

- Just use the following commands
```
/wc "waypoint name" to create a waypoint at current position.
/wd "waypoint name" to delete a waypoint.
/wt "waypoint name" to teleport to a waypoint.
/wl list your waypoints in table format e.g. "1 Home (x,y,z)".
```

GUI:
/wf to bring up the waypoints formspec.

NOTE:
The GUI allows you to select a beacon color (out of 8); the text interface 
selects one at random. 

Works with Minetest 5.2.0

#### Installation

Extract zip to the mods folder.