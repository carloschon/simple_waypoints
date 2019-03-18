local modstorage = minetest.get_mod_storage()
local world_path = minetest.get_worldpath()
local world_name = world_path:match( "([^/]+)$" )
local waypoints = minetest.deserialize(modstorage:get_string(world_name)) or {}


-- HELPER FUNCTIONS
local function save() -- dumps table to modstorage
  modstorage:set_string(world_name, minetest.serialize(waypoints))
end

local function getIndexByName(table, n)
  for k,v in pairs(table) do
		if v.name == n then
      return k
		else
    end
  end
end

local function getPosByName(table, n)
  for k,v in pairs(table) do
		if v.name == n then
      return v.pos
		else
		end
  end
end

local function waypointExists(table, n)
	for k,v in pairs(table) do
		if v.name == n then
			return true, "Waypoint exists."
		end
	end
end

local function validCommandArgs(args)
	if type(args) ~= "string" then
		invalidInput = "We need a string." return false
  elseif string.match (args, "[%W%s]") ~= nil then
		invalidInput = "Invalid characters detected." return false
  elseif string.len (args) == 0 then
		invalidInput = "Please specify a name." return false
  else return true
  end
end

local function addWaypointHud(player, table)
  local wayName = table[#table].name
  local wayPos = minetest.string_to_pos(table[#table].pos)
  table[#table].hudId = player:hud_add({
    hud_elem_type = "waypoint",
    name = wayName,
    text = "m",
    number = 0xFFFFFF,
    world_pos = wayPos,
  })
end

local function loadWaypointsHud(player, table)
  for k,v in pairs(table) do
    player:hud_add({
    hud_elem_type = "waypoint",
    name = v.name,
    text = "m",
    number = 0xFFFFFF,
    world_pos = minetest.string_to_pos(v.pos),
  })
  end
end

--------------- INIT FUNCTIONS ------------------
local join = minetest.register_on_joinplayer(function(player)
  minetest.after(.5, function()
    loadWaypointsHud(player, waypoints)
  end)
end)

-------------- NODE DEFINITIONS -----------------
local palette = {"blue", "green", "orange", "pink", "purple", "red", "white", "yellow"}

-- BEACONS
for _, color in ipairs(palette) do
  minetest.register_node("simple_waypoints:"..color.."_beacon", {
	visual_scale = 1.0,
	drawtype = "plantlike",
	tiles = {"beacon_"..color..".png"},
	paramtype = "light",
	walkable = false,
	diggable = false,
	light_source = 13,
	groups = {not_in_creative_inventory=1}
})
end

-- CONSTRUCTOR FUNCTIONS
local function placeBeacon(pos)
  local random = math.random(1,#palette)
  for i=0,50 do
    local target_node = minetest.get_node({x=pos.x, y=pos.y+i, z=pos.z})
    if target_node.name == "air" then
      minetest.add_node({x=pos.x, y=pos.y+i, z=pos.z},
        {name="simple_waypoints:"..palette[random].."_beacon"})
    end
  end
end

local function removeBeacon(pos)
  for _,v in ipairs(palette) do
    for i=0,50 do
      local target_node = minetest.get_node({x=pos.x, y=pos.y+i, z=pos.z})
      if target_node.name == "simple_waypoints:"..v.."_beacon" then
        minetest.add_node({x=pos.x, y=pos.y+i, z=pos.z}, {name="air"})
      end
    end
  end
end
--------------- CHAT COMMANDS -------------------

-- CREATE WAYPOINT
minetest.register_chatcommand("wc", {
	params = "<waypoint_name>",
	description = "create a waypoint at current position using a unique name",
	privs = {shout = true},
	func = function (name, params)
		local player = minetest.get_player_by_name(name)
    local p_pos = player:get_pos()
    local round_pos = vector.round(p_pos)
		if waypointExists(waypoints, params) == true then
			return true, tostring("Waypoint "..params.." already exists.")
		elseif validCommandArgs(params) then
      waypoints[#waypoints+1] = { name = params,
				pos = minetest.pos_to_string(round_pos) }
      addWaypointHud(player, waypoints)
      placeBeacon(round_pos)
      save()

    	return true, "Waypoint "..params.." created!"
		else
			return true, invalidInput
    end
  end
})

-- DELETE WAYPOINT
minetest.register_chatcommand("wd", {
  params = "<waypoint_name>",
  description = "Delete a waypoint using its name.",
  privs = {shout = true},
  func = function(name,params)
    local player = minetest.get_player_by_name(name)
    local targetIndex = getIndexByName(waypoints, params)
    local beaconPos = getPosByName(waypoints, params)
    if (validCommandArgs(params) == true and type(targetIndex) == "number") then
      removeBeacon(minetest.string_to_pos(beaconPos))
      player:hud_remove(waypoints[targetIndex].hudId)
      table.remove (waypoints, targetIndex)
			save()
    	return true, "Waypoint deleted."
		elseif type(targetIndex) ~= "number" then
			return false, "Waypoint "..params.." is invalid or inexistent."
    end
  end
})

-- LIST WAYPOINTS
minetest.register_chatcommand("wl", {
  params = "",
  description = "Lists your waypoints.",
  privs = {shout = true},
  func = function(name)
    local player = minetest.get_player_by_name(name)
    local p_name = player:get_player_name()
    for k,v in pairs(waypoints) do
      minetest.chat_send_player(p_name, tostring(k.." "..v.name.." "..v.pos))
      end
  end
})

-- TELEPORT TO WAYPOINT
minetest.register_chatcommand("wt", {
  params = "<waypoint_name>",
  description = "Teleports you to a specified waypoint.",
  privs = {shout = true},
  func = function(name, params)
    local player = minetest.get_player_by_name(name)
		local p_name = player:get_player_name()
		local targetPos = getPosByName(waypoints, params)
		if (validCommandArgs(params) == true and type(targetPos) == "string") then
			player:set_pos(minetest.string_to_pos(targetPos))
			return true, tostring("Teleported "..p_name.." to "..params..".")
		elseif type(targetPos) ~= "string" then
			return true, tostring("Waypoint "..params.." is invalid or inexistent.")
    end
  end
})
