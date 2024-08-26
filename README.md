# Simple Waypoints

------

A minetest 0.4.17+ mod that lets you set waypoints/beacons at current position.

![beacon](img/screenie1.png) ![waypoints GUI](img/screenie2.png)

#### How it works
This mod offers two ways to manage your waypoints: a text-based interface using chat commands and a graphical user interface (GUI). Choose the method that you find most convenient.


TEXT INTERFACE:

- Just use the following commands
```
**Text Commands:**

- **Create Waypoint:** `/wc <waypoint name>`  - Sets a waypoint at your current location with the given name.
- **Delete Waypoint:** `/wd <waypoint name>` - Removes the waypoint with the specified name.
- **Teleport to Waypoint:** `/wt <waypoint name>` - Teleports you to the location of the named waypoint.
- **List Waypoints:** `/wl` - Displays a list of your waypoints in a user-friendly table format, including coordinates (e.g., "1. Home (x,y,z)").
```

GUI:
/wf to use GUI instead.

NOTE:
The GUI allows you to select a beacon color from 8 available options.  When creating waypoints using the chat commands, a random color will be selected for the beacon. 

Works with Minetest 5.2.0+

#### Installation

Extract zip to the mods folder.