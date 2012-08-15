minetest.register_node("carts:chest", {
	description = "Railchest",
	tiles = {"default_chest_top.png", "default_chest_top.png", "default_chest_side.png^default_rail.png", "default_chest_side.png^default_rail.png", "default_chest_side.png^default_rail.png", "default_chest_front.png"},
	paramtype2 = "facedir",
	groups = {snappy=1,choppy=2,oddly_breakable_by_hand=2,flammable=3},
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_string("formspec",
				"invsize[8,8;]"..
				"label[0.5.0,0;In:]"..
				"list[current_name;in;0.5,0.5;3,3;]"..
				"label[4.5.0,0;Out:]"..
				"list[current_name;out;4.5,0.5;3,3;]"..
				"list[current_player;main;0,4;8,4;]")
		meta:set_string("infotext", "Railchest")
		local inv = meta:get_inventory()
		inv:set_size("in", 3*3)
		inv:set_size("out", 3*3)
	end,
	can_dig = function(pos,player)
		local meta = minetest.env:get_meta(pos);
		local inv = meta:get_inventory()
		return (inv:is_empty("in") and inv:is_empty("out"))
	end,
})

minetest.register_abm({
	nodenames = {"carts:pickup_plate"},
	interval = 0,
	chance = 1,
	action = function(pos)
		minetest.env:remove_node(pos)
	end
})

minetest.register_craft({
	output = '"carts:chest" 1',
	recipe = {
		{'default:wood', 'default:wood', 'default:wood'},
		{'default:wood', 'default:rail', 'default:wood'},
		{'default:wood', 'default:wood', 'default:wood'}
	}
})
