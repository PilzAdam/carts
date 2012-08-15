if minetest.get_modpath("mesecons") ~= nil then
	minetest.after(0, function()
		mesecon:register_on_signal_on(function(pos, node)
			for i,rail in ipairs(RAILS) do
				if node.name == rail then
					local carts = minetest.env:get_objects_inside_radius(pos, 1)
					for i,cart in ipairs(carts) do
						if not cart:is_player() and cart:get_luaentity().name == "carts:cart" and not cart:get_luaentity().fahren then
							local self = cart:get_luaentity()
							-- find out the direction
							local dir_table
							if self.old_dir ~= nil then
								dir_table = {self.old_dir, "x+", "x-", "z+", "z-"}
							else
								dir_table = {"x+", "x-", "z+", "z-"}
							end
							for i,dir in ipairs(dir_table) do
								self.dir = dir
								if self:get_new_direction() == self.dir then
									break
								end
							end
							-- detect items
							local tmp = minetest.env:get_objects_inside_radius(self.object:getpos(), 1)
							for i,item in ipairs(tmp) do
								if not item:is_player() and item:get_luaentity().name ~= "carts:cart" then
									table.insert(self.items, item)
								elseif item:is_player() and TRANSPORT_PLAYER then
									table.insert(self.items, item)
								end
							end
							
							-- start sound
							self:sound("start")
							
							self.fahren = true
						end
					end
				end
			end
			if node.name == "carts:switch_left" then
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
			elseif node.name == "carts:switch_right" then
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
			end
			
			if node.name == "carts:meseconrail_stop_off" then
				node.name = "carts:meseconrail_stop_on"
				minetest.env:set_node(pos, node)
			end
		end)
	
		mesecon:register_on_signal_off(function(pos, node)
			if node.name == "carts:meseconrail_stop_on" then
				node.name = "carts:meseconrail_stop_off"
				minetest.env:set_node(pos, node)
				local carts = minetest.env:get_objects_inside_radius(pos, 1)
				for i,cart in ipairs(carts) do
					if not cart:is_player() and cart:get_luaentity().name == "carts:cart" and not cart:get_luaentity().fahren then
						local self = cart:get_luaentity()
						-- find out the direction
						if self.old_dir ~= nil then
							self.dir = self.old_dir
						else
							for i,dir in ipairs({"x+", "x-", "z+", "z-"}) do
								self.dir = dir
								if self:get_new_direction() == self.dir then
									break
								end
							end
						end
						-- detect items
						local tmp = minetest.env:get_objects_inside_radius(self.object:getpos(), 1)
						for i,item in ipairs(tmp) do
							if not item:is_player() and item:get_luaentity().name ~= "carts:cart" then
								table.insert(self.items, item)
							elseif item:is_player() and TRANSPORT_PLAYER then
								table.insert(self.items, item)
							end
						end
						
						-- start sound
						self:sound("start")
						
						self.fahren = true
					end
				end
			end
		end)
	end)
	
	minetest.register_node("carts:meseconrail_off", {
		description = "Meseconrail",
		drawtype = "raillike",
		tiles = {"carts_meseconrail_off.png", "carts_meseconrail_curved_off.png", "carts_meseconrail_t_junction_off.png", "carts_meseconrail_crossing_off.png",},
		inventory_image = "carts_meseconrail_off.png",
		wield_image = "carts_meseconrail_off.png",
		paramtype = "light",
		walkable = false,
		selection_box = {
			type = "fixed",
			fixed = {-1/2, -1/2, -1/2, 1/2, -1/2+1/16, 1/2},
		},
		groups = {bendy=2,snappy=1,dig_immediate=2},
	})
	
	minetest.register_node("carts:meseconrail_on", {
		drawtype = "raillike",
		tiles = {"carts_meseconrail_on.png", "carts_meseconrail_curved_on.png", "carts_meseconrail_t_junction_on.png", "carts_meseconrail_crossing_on.png",},
		paramtype = "light",
		light_source = LIGHT_MAX-11,
		drop = "carts:meseconrail_off",
		walkable = false,
		selection_box = {
			type = "fixed",
			fixed = {-1/2, -1/2, -1/2, 1/2, -1/2+1/16, 1/2},
		},
		groups = {bendy=2, snappy=1, dig_immediate=2, not_in_creative_inventory=1},
		after_destruct = function(pos, oldnode)
			if mesecon ~= nil then
				mesecon:receptor_off(pos)
			end
		end,
	})
	
	minetest.register_alias("carts:meseconrail", "carts:meseconrail_off")
	
	minetest.after(0, function()
		mesecon:add_receptor_node("carts:meseconrail_on")
		mesecon:add_receptor_node_off("carts:meseconrail_off")
	end)
	
	minetest.register_abm({
		nodenames = {"carts:meseconrail_on"},
		interval = 1.0,
		chance = 1,
		action = function(pos, node)
			local tmp =  minetest.env:get_objects_inside_radius(pos, 1)
			local cart_is_there = false
			for i,cart in ipairs(tmp) do
				if not cart:is_player() and cart:get_luaentity().name == "carts:cart" then
					cart_is_there = true
				end
			end
			if not cart_is_there then
				minetest.env:set_node(pos, {name="carts:meseconrail_off"})
				if mesecon ~= nil then
					mesecon:receptor_off(pos)
				end
			end
		end
	})
	
	minetest.register_craft({
		output = '"carts:meseconrail_off" 1',
		recipe = {
			{'default:rail', 'mesecons:mesecon_off', 'default:rail'},
			{'default:rail', 'mesecons:mesecon_off', 'default:rail'},
			{'default:rail', 'mesecons:mesecon_off', 'default:rail'},
		}
	})
	
	minetest.register_node("carts:meseconrail_stop_off", {
		description = "Meseconrail stop",
		drawtype = "raillike",
		tiles = {"carts_meseconrail_stop_off.png", "carts_meseconrail_stop_curved_off.png", "carts_meseconrail_stop_t_junction_off.png", "carts_meseconrail_stop_crossing_off.png",},
		inventory_image = "carts_meseconrail_stop_off.png",
		wield_image = "carts_meseconrail_stop_off.png",
		paramtype = "light",
		walkable = false,
		selection_box = {
			type = "fixed",
			fixed = {-1/2, -1/2, -1/2, 1/2, -1/2+1/16, 1/2},
		},
		groups = {bendy=2,snappy=1,dig_immediate=2},
		after_destruct = function(pos, oldnode)
			if mesecon ~= nil then
				mesecon:receptor_off(pos)
			end
		end,
	})
	
	minetest.register_node("carts:meseconrail_stop_on", {
		drawtype = "raillike",
		tiles = {"carts_meseconrail_stop_on.png", "carts_meseconrail_stop_curved_on.png", "carts_meseconrail_stop_t_junction_on.png", "carts_meseconrail_stop_crossing_on.png",},
		paramtype = "light",
		light_source = LIGHT_MAX-11,
		drop = "carts:meseconrail_stop_off",
		walkable = false,
		selection_box = {
			type = "fixed",
			fixed = {-1/2, -1/2, -1/2, 1/2, -1/2+1/16, 1/2},
		},
		groups = {bendy=2, snappy=1, dig_immediate=2, not_in_creative_inventory=1},
		after_destruct = function(pos, oldnode)
			if mesecon ~= nil then
				mesecon:receptor_off(pos)
			end
		end,
	})
	
	minetest.register_alias("carts:meseconrail_stop", "carts:meseconrail_stop_off")
	
	minetest.register_craft({
		output = '"carts:meseconrail_stop_off" 1',
		recipe = {
			{'default:rail', 'mesecons:mesecon_off', 'default:rail'},
			{'default:rail', '', 'default:rail'},
			{'default:rail', 'mesecons:mesecon_off', 'default:rail'},
		}
	})
	
end 
