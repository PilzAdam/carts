minetest.register_node("carts:switch_left", {
	paramtype2 = "facedir",
	tiles = {"default_wood.png"},
	drop = "carts:switch_middle",
	groups = {bendy=2, snappy=1, dig_immediate=2, not_in_creative_inventory=1},
	on_punch = function(pos, node, puncher)
		node.name = "carts:switch_middle"
		minetest.env:set_node(pos, node)
				local par2 = minetest.env:get_node(pos).param2
		if par2 == 0 then
			pos.z = pos.z-1
		elseif par2 == 1 then
			pos.x = pos.x-1
		elseif par2 == 2 then
			pos.z = pos.z+1
		elseif par2 == 3 then
			pos.x = pos.x+1
		end
		
		for i,rail in ipairs(RAILS) do
			if minetest.env:get_node(pos).name == rail then
				local meta = minetest.env:get_meta(pos)
				meta:set_string("rail_direction", "")
			end
		end
	end,
	on_destruct = function(pos)
		local par2 = minetest.env:get_node(pos).param2
		if par2 == 0 then
			pos.z = pos.z-1
		elseif par2 == 1 then
			pos.x = pos.x-1
		elseif par2 == 2 then
			pos.z = pos.z+1
		elseif par2 == 3 then
			pos.x = pos.x+1
		end
		
		for i,rail in ipairs(RAILS) do
			if minetest.env:get_node(pos).name == rail then
				local meta = minetest.env:get_meta(pos)
				meta:set_string("rail_direction", "")
			end
		end
	end,
	
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {
					-- shaft
					{-0.05, -0.5, -0.45, 0.05, -0.4, -0.4},
					{-0.1, -0.4, -0.45, 0, -0.3, -0.4},
					{-0.15, -0.3, -0.45, -0.05, -0.2, -0.4},
					{-0.2, -0.2, -0.45, -0.1, -0.1, -0.4},
					{-0.25, -0.1, -0.45, -0.15, 0, -0.4},
					{-0.3, 0, -0.45, -0.2, 0.1, -0.4},
					-- head
					{-0.45, 0.1, -0.5, -0.25, 0.3, -0.35},
				},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.35, -0.35},
		}
	},
	walkable = false,
})

minetest.register_node("carts:switch_middle", {
	description = "Switch",
	paramtype2 = "facedir",
	tiles = {"default_wood.png"},
	groups = {bendy=2, snappy=1, dig_immediate=2},
	on_punch = function(pos, node, puncher)
		node.name = "carts:switch_right"
		minetest.env:set_node(pos, node)
				local par2 = minetest.env:get_node(pos).param2
		if par2 == 0 then
			pos.z = pos.z-1
		elseif par2 == 1 then
			pos.x = pos.x-1
		elseif par2 == 2 then
			pos.z = pos.z+1
		elseif par2 == 3 then
			pos.x = pos.x+1
		end
		
		for i,rail in ipairs(RAILS) do
			if minetest.env:get_node(pos).name == rail then
				local meta = minetest.env:get_meta(pos)
				meta:set_string("rail_direction", "right")
			end
		end
	end,
	on_construct = function(pos)
		local par2 = minetest.env:get_node(pos).param2
		if par2 == 0 then
			pos.z = pos.z-1
		elseif par2 == 1 then
			pos.x = pos.x-1
		elseif par2 == 2 then
			pos.z = pos.z+1
		elseif par2 == 3 then
			pos.x = pos.x+1
		end
		
		for i,rail in ipairs(RAILS) do
			if minetest.env:get_node(pos).name == rail then
				local meta = minetest.env:get_meta(pos)
				meta:set_string("rail_direction", "")
			end
		end
	end,
	on_destruct = function(pos)
		local par2 = minetest.env:get_node(pos).param2
		if par2 == 0 then
			pos.z = pos.z-1
		elseif par2 == 1 then
			pos.x = pos.x-1
		elseif par2 == 2 then
			pos.z = pos.z+1
		elseif par2 == 3 then
			pos.x = pos.x+1
		end
		
		for i,rail in ipairs(RAILS) do
			if minetest.env:get_node(pos).name == rail then
				local meta = minetest.env:get_meta(pos)
				meta:set_string("rail_direction", "")
			end
		end
	end,
	
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {
					-- shaft
					{-0.05, -0.5, -0.45, 0.05, 0.15, -0.4},
					-- head
					{-0.1, 0.15, -0.5, 0.1, 0.35, -0.35},
				},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.35, -0.35},
		}
	},
	walkable = false,
})

minetest.register_node("carts:switch_right", {
	paramtype2 = "facedir",
	tiles = {"default_wood.png"},
	groups = {bendy=2,snappy=1, dig_immediate=2, not_in_creative_inventory=1},
	drop = "carts:switch_middle",
	on_punch = function(pos, node, puncher)
		node.name = "carts:switch_left"
		minetest.env:set_node(pos, node)
		local par2 = minetest.env:get_node(pos).param2
		if par2 == 0 then
			pos.z = pos.z-1
		elseif par2 == 1 then
			pos.x = pos.x-1
		elseif par2 == 2 then
			pos.z = pos.z+1
		elseif par2 == 3 then
			pos.x = pos.x+1
		end
		for i,rail in ipairs(RAILS) do
			if minetest.env:get_node(pos).name == rail then
				local meta = minetest.env:get_meta(pos)
				meta:set_string("rail_direction", "left")
			end
		end
	end,
	on_destruct = function(pos)
		local par2 = minetest.env:get_node(pos).param2
		if par2 == 0 then
			pos.z = pos.z-1
		elseif par2 == 1 then
			pos.x = pos.x-1
		elseif par2 == 2 then
			pos.z = pos.z+1
		elseif par2 == 3 then
			pos.x = pos.x+1
		end
		for i,rail in ipairs(RAILS) do
			if minetest.env:get_node(pos).name == rail then
				local meta = minetest.env:get_meta(pos)
				meta:set_string("rail_direction", "")
			end
		end
	end,
	
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {
					-- shaft
					{-0.05, -0.5, -0.45, 0.05, -0.4, -0.4},
					{0, -0.4, -0.45, 0.1, -0.3, -0.4},
					{0.05, -0.3, -0.45, 0.15, -0.2, -0.4},
					{0.1, -0.2, -0.45, 0.2, -0.1, -0.4},
					{0.15, -0.1, -0.45, 0.25, 0, -0.4},
					{0.2, 0, -0.45, 0.3, 0.1, -0.4},
					-- head
					{0.25, 0.1, -0.5, 0.45, 0.3, -0.35},
				},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.35, -0.35},
		}
	},
	walkable = false,
})

minetest.register_alias("carts:switch", "carts:switch_middle")

minetest.register_craft({
	output = '"carts:switch_middle" 1',
	recipe = {
		{'', 'default:rail', ''},
		{'default:rail', '', ''},
		{'', 'default:rail', ''},
	}
})
