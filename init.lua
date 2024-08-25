-------------- INIT VARIABLES ------------------
local modstorage = minetest.get_mod_storage()
local world_path = minetest.get_worldpath()
local world_name = world_path:match( "([^/]+)$" )
local waypoints = minetest.deserialize(modstorage:get_string(world_name)) or {}

--------------- HELPER FUNCTIONS ---------------
local function save() -- dumps table to modstorage
	modstorage:set_string(world_name, minetest.serialize(waypoints))
end

local function getIndexByName(table, n)
	for k,v in pairs(table) do
		if v.name == n then
			return k
		end
	end
	return nil --Index not found
end

local function getPosByName(table, n)
	for k,v in pairs(table) do
		if v.name == n then
			return v.pos
		end
	end
	return nil -- Position not found
end

local function waypointExists(table, n)
	for k,v in pairs(table) do
	  if v.name == n then
		return "Waypoint exists." 
	  end
	end
	return nil --Waypoint doesn't exist
  end

local function addWaypointHud(table, player)
	local wayName = waypoints[#waypoints].name
	local wayPos = minetest.string_to_pos(waypoints[#waypoints].pos)
	table[#table].hudId = player:hud_add({
		hud_elem_type = "waypoint",
		name = wayName,
		text = "m",
		number = 0xFFFFFF,
		world_pos = wayPos,
	})
end

local function refreshWaypointHud(table, player)
	local wayName = waypoints[selected_idx].name
	local wayPos = minetest.string_to_pos(waypoints[selected_idx].pos)
	table[#table].hudId = player:hud_add({
		hud_elem_type = "waypoint",
		name = wayName,
		text = "m",
		number = 0xFFFFFF,
		world_pos = wayPos,
	})
end

local function loadWaypointsHud(table, player)
	for k,v in pairs(waypoints) do
		player:hud_add({
		hud_elem_type = "waypoint",
		name = v.name,
		text = "m",
		number = 0xFFFFFF,
		world_pos = minetest.string_to_pos(v.pos),
	})
	end
end

--------------- ON JOIN ------------------
local join = minetest.register_on_joinplayer(function(player)
	minetest.after(.5, function()
		loadWaypointsHud(waypoints, player)
	end)
end)

-------------- NODE DEFINITIONS -----------------
local palette = {"blue", "green", "orange", "pink", "purple", "red", "white", "yellow"}

-- BEACON DEFINITION
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

-- BEACON FUNCTIONS
local function placeBeacon(pos, color)
	local random = math.random(1,#palette)
	for i=0,50 do
		local target_node = minetest.get_node({x=pos.x, y=pos.y+i, z=pos.z})
		if target_node.name == "air" then
			if color == nil then
				minetest.add_node({x=pos.x, y=pos.y+i, z=pos.z},
				{name="simple_waypoints:"..palette[random].."_beacon"})
			else
				minetest.add_node({x=pos.x, y=pos.y+i, z=pos.z},
				{name="simple_waypoints:"..color.."_beacon"})
			end
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

		-- Check if the waypoint name is at least 1 character long
		if string.len(params) < 1 then
			return nil, "Waypoint name must be at least 1 character long"
		end

		-- Check if a waypoint with the given name already exists
		if not waypointExists(waypoints, params) == true then
			-- Add the new waypoint to the table
			waypoints[#waypoints+1] = { name = params,
			pos = minetest.pos_to_string(round_pos) }

			-- Add the waypoint to the player's HUD
			addWaypointHud(waypoints, player)

			-- Place a beacon at the waypoint location
			placeBeacon(round_pos)

			-- Save the waypoints to modstorage
			save()

			-- Return success message
			return true, "Waypoint "..params.." created!"
		else
			return nil, "Waypoint with that name already exists"
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
		if (type(targetIndex) == "number") then
			removeBeacon(minetest.string_to_pos(beaconPos))
			player:hud_remove(waypoints[targetIndex].hudId)

			-- Remove the waypoint from the table
			table.remove(waypoints, targetIndex)

			-- Now get the correct index for the hud update
			targetIndex = getIndexByName(waypoints, params)

			-- Update the HUD
			if targetIndex ~= nil then
				player:hud_remove(waypoints[targetIndex].hudId)
			end

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

		-- Iterate through the waypoints table and send each waypoint's details to the player
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

		-- Check if the waypoint exists and has a valid position
		if (type(targetPos) == "string") then
			-- Teleport the player to the waypoint position
			player:set_pos(minetest.string_to_pos(targetPos))
			return true, tostring("Teleported "..p_name.." to "..params..".")
		elseif type(targetPos) ~= "string" then
			return true, tostring("Waypoint "..params.." is invalid or inexistent.")
		end
	end
})

-- SHOW WAYPOINTS FORMSPEC
minetest.register_chatcommand("wf", {
	func = function(name)
		-- Show the waypoints formspec to the player
		minetest.show_formspec(name, "simple_waypoints:waypoints_formspec", waypoints_formspec.get_main())
	end,
})

--------------- FORMSPEC -----------------------
waypoints_formspec = {}

-- MAIN PAGE
function waypoints_formspec.get_main()
	local text = "Waypoints list."
	formspec = {
		"size[11,14]",
		"real_coordinates[true]",
		"label[0.375,0.5;", minetest.formspec_escape(text), "]",
		"button_exit[8.7,0.75;2,1;teleport;Teleport]",
		"button[8.7,1.75;2,1;add;Add]",
		"button[8.7,2.75;2,1;delete;Delete]",
		"button[8.7,3.75;2,1;rename;Rename]",
	}

local f = ""
	f = f..
	"textlist[0.375,0.75;8,13;waylist;"
	for i = 1, #waypoints do
		f = f..i.."  "..minetest.formspec_escape(waypoints[i].name.." "..waypoints[i].pos)..","
	end
	formspec[#formspec+1] = f.."]"
	return table.concat(formspec, " ")
end

function waypoints_formspec.get_add()
	local text = "Add waypoint at current position. Random color if unselected."
	local text2 = "Color:"
	formspec = {
		"size[10,5]",
		"real_coordinates[true]",
		"label[0.375,0.5;", text, "]",
		"label[5.375,1.80;", text2, "]",
		"field[0.375,2;4,0.6;name;Name:;]",
		"dropdown[5.375,2;4,0.6;color;blue,green,orange,pink,purple,red,white,yellow;0]",
		"button[4,3.5;2,1;create;Create]"
	}
	return table.concat(formspec, " ")
end
-- RENAME PAGE
function waypoints_formspec.get_rename()
	local text = "Enter a new name:"
	formspec = {
		"size[4,2.5]",
		"real_coordinates[true]",
		"label[0.58,0.5;", text, "]",
		"field[0.25,0.9;3.5,0.6;new_name;;]",
		"button[1.5,1.75;1,0.5;ok;OK]"
	}
	return table.concat(formspec, " ")
end

function waypoints_formspec.get_exists()
	local text = "A waypoint with that name already exists!"
	local text2 = "Please choose a unique name."
	formspec = {
		"size[7,3]",
		"real_coordinates[true]",
		"label[0.375,0.5;", text, "]",
		"label[1.15,1;"; text2, "]",
		"button[2.5,1.5;2,1;back;Back]"
	}
	return table.concat(formspec, " ")
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local pname = player:get_player_name()
	if formname ~= "simple_waypoints:waypoints_formspec" then return
	elseif fields.waylist then
		local event = minetest.explode_textlist_event(fields.waylist)
		if(event.type == "CHG") then
			selected_idx = event.index
		end
	elseif fields.teleport then
		if waypoints[selected_idx] ~= nil then
			player:set_pos(minetest.string_to_pos(waypoints[selected_idx].pos))
			minetest.chat_send_all(pname .. " Teleported to " .. waypoints[selected_idx].name)
			selected_idx = nil   -- "Teleport" button remembers the last location when you don't select a valid item. This is a reset.
		end
	elseif fields.add then
		minetest.show_formspec(pname, "simple_waypoints:waypoints_formspec", waypoints_formspec.get_add())
	elseif fields.create or fields.key_enter_field then
		if fields.name ~= nil and string.len(fields.name) ~= 0 then
			local player = minetest.get_player_by_name(pname)
			local p_pos = player:get_pos()
			local round_pos = vector.round(p_pos)
			if not waypointExists(waypoints, fields.name) then
				waypoints[#waypoints+1] = { name = fields.name, pos = minetest.pos_to_string(round_pos) }
				addWaypointHud(waypoints, player)
				placeBeacon(round_pos, fields.color)
				save()
				minetest.show_formspec(pname, "simple_waypoints:waypoints_formspec", waypoints_formspec.get_main())
			else minetest.show_formspec(pname, "simple_waypoints:waypoints_formspec", waypoints_formspec.get_exists())
			end
		end
	elseif fields.back then
		minetest.show_formspec(pname, "simple_waypoints:waypoints_formspec", waypoints_formspec.get_add())
	elseif fields.delete then
		if waypoints[selected_idx] ~= nil then
			local beaconPos = getPosByName(waypoints, waypoints[selected_idx].name)
			removeBeacon(minetest.string_to_pos(beaconPos))
			player:hud_remove(waypoints[selected_idx].hudId)
			table.remove(waypoints, selected_idx)
			save()
			minetest.show_formspec(pname, "simple_waypoints:waypoints_formspec", waypoints_formspec.get_main())
		end
	elseif fields.rename then
		if waypoints[selected_idx] ~= nil then
			minetest.show_formspec(pname, "simple_waypoints:waypoints_formspec", waypoints_formspec.get_rename())
		end
	elseif fields.ok or fields.key_enter_field then
		if fields.new_name ~= nil and string.len(fields.new_name) ~= 0 then
		waypoints[selected_idx].name = fields.new_name
		player:hud_remove(waypoints[selected_idx].hudId)
		refreshWaypointHud(waypoints, player)
		minetest.show_formspec(pname, "simple_waypoints:waypoints_formspec", waypoints_formspec.get_main())
		end
	end
end)
