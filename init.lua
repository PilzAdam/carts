
dofile(minetest.get_modpath("carts").."/functions.lua")

--
-- Cart entity
--

local cart = {
	physical = false,
	collisionbox = {-0.5,-0.5,-0.5, 0.5,0.5,0.5},
	visual = "cube",
	visual_size = {x=1, y=1},
	textures = {"cart_top.png", "cart_bottom.png", "cart_side.png", "cart_side.png", "cart_side.png", "cart_side.png"},
	
	driver = nil, -- TODO: Replace this with self.object.child or so
	velocity = {x=0, y=0, z=0},
	MAX_V = 5.5,
}

function cart:on_rightclick(clicker)
	if not clicker or not clicker:is_player() then
		return
	end
	if self.driver and clicker == self.driver then
		self.driver = nil
		clicker:set_detach()
	else
		self.driver = clicker
		clicker:set_attach(self.object, "", {x=0,y=5,z=0}, {x=0,y=0,z=0})
	end
end

function cart:on_activate(staticdata, dtime_s)
	self.object:set_armor_groups({immortal=1})
	if staticdata then
		local tmp = minetest.deserialize(staticdata)
		if tmp then
			self.velocity = tmp.velocity
			self.MAX_V = tmp.MAX_V
		end
	end
end

function cart:get_staticdata()
	return minetest.serialize({
		velocity = self.velocity,
		MAX_V = self.MAX_V,
	})
end

-- Remove the cart if holding a tool or accelerate it
function cart:on_punch(puncher, time_from_last_punch, tool_capabilities, direction)
	if not puncher or not puncher:is_player() then
		return
	end
	
	if puncher:get_wielded_item():get_definition().type == "tool" then
		self.object:remove()
		puncher:get_inventory():add_item("main", "carts:cart")
		return
	end
	
	if puncher == self.driver then
		return
	end
	
	local d = direction
	local s = self.velocity
	if time_from_last_punch > tool_capabilities.full_punch_interval then
		time_from_last_punch = tool_capabilities.full_punch_interval
	end
	local f = 4*(time_from_last_punch/tool_capabilities.full_punch_interval)
	self.velocity = {x=s.x+d.x*f, y=s.y, z=s.z+d.z*f}
end

-- Returns the direction as a unit vector
function cart:get_rail_direction(pos, dir)
	local d = cart_func.v3:copy(dir)
	
	-- Check front
	d.y = 0
	local p = cart_func.v3:add(cart_func.v3:copy(pos), d)
	if cart_func:is_rail(p) then
		return d
	end
	
	-- Check downhill
	d.y = -1
	p = cart_func.v3:add(cart_func.v3:copy(pos), d)
	if cart_func:is_rail(p) then
		return d
	end
	
	-- Check uphill
	d.y = 1
	p = cart_func.v3:add(cart_func.v3:copy(pos), d)
	if cart_func:is_rail(p) then
		return d
	end
	d.y = 0
	
	-- Check left and right
	local view_dir
	local other_dir
	local a
	
	if d.x == 0 and d.z ~= 0 then
		view_dir = "z"
		other_dir = "x"
		if d.z < 0 then
			a = {1, -1}
		else
			a = {-1, 1}
		end
	elseif d.z == 0 and d.x ~= 0 then
		view_dir = "x"
		other_dir = "z"
		if d.x > 0 then
			a = {1, -1}
		else
			a = {-1, 1}
		end
	else
		return {x=0, y=0, z=0}
	end
	
	d[view_dir] = 0
	d[other_dir] = a[1]
	p = cart_func.v3:add(cart_func.v3:copy(pos), d)
	if cart_func:is_rail(p) then
		return d
	end
	d.y = -1
	p = cart_func.v3:add(cart_func.v3:copy(pos), d)
	if cart_func:is_rail(p) then
		return d
	end
	d.y = 0
	d[other_dir] = a[2]
	p = cart_func.v3:add(cart_func.v3:copy(pos), d)
	if cart_func:is_rail(p) then
		return d
	end
	d.y = -1
	p = cart_func.v3:add(cart_func.v3:copy(pos), d)
	if cart_func:is_rail(p) then
		return d
	end
	d.y = 0
	
	return {x=0, y=0, z=0}
end

function cart:on_step(dtime)
	
	local pos = self.object:getpos()
	local dir = cart_func:velocity_to_dir(self.velocity)
	
	-- Stop the cart if the velocity is nearly 0
	-- Only if on a flat railway
	if dir.y == 0 then
		if math.abs(self.velocity.x) < 0.1 and  math.abs(self.velocity.z) < 0.1 then
			self.velocity = {x=0, y=0, z=0}
			self.object:setvelocity(self.velocity)
			return
		end
	end
	
	-- HACK
	-- Move the cart on the rail if above or under it
	if cart_func:is_rail(cart_func.v3:add(cart_func.v3:copy(pos), {x=0, y=1, z=0}))  and
			self.velocity.y >= 0 then
		self.object:setpos(cart_func.v3:add(cart_func.v3:copy(pos), {x=0, y=1, z=0}))
		pos = self.object:getpos()
	end
	if cart_func:is_rail(cart_func.v3:add(cart_func.v3:copy(pos), {x=0, y=-1, z=0})) and
			self.velocity.y <= 0 then
		self.object:setpos(cart_func.v3:add(cart_func.v3:copy(pos), {x=0, y=-1, z=0}))
		pos = self.object:getpos()
	end
	
	-- HACK
	-- Move the cart back on rails if it isnt
	if not cart_func:is_rail(pos) and self.velocity.y == 0 then
		local p = cart_func.v3:round(cart_func.v3:copy(pos))
		if cart_func:is_rail(cart_func.v3:add(p, {x=dir.x*-1, y=0, z=dir.z*-1})) then
			self.object:setpos(cart_func.v3:add(p, {x=dir.x*-1, y=0, z=dir.z*-1}))
			pos = self.object:getpos()
		end
	end
	
	-- Accelerate or decelerate the cart according to the pitch
	if self.velocity.y < 0 then
		self.velocity = {
			x = self.velocity.x + 0.13*cart_func:get_sign(self.velocity.x),
			y = self.velocity.y + 0.13*cart_func:get_sign(self.velocity.y),
			z = self.velocity.z + 0.13*cart_func:get_sign(self.velocity.z),
		}
	elseif self.velocity.y > 0 then
		self.velocity = {
			x = self.velocity.x - 0.1*cart_func:get_sign(self.velocity.x),
			y = self.velocity.y - 0.1*cart_func:get_sign(self.velocity.y),
			z = self.velocity.z - 0.1*cart_func:get_sign(self.velocity.z),
		}
	else
		self.velocity = {
			x = self.velocity.x - 0.03*cart_func:get_sign(self.velocity.x),
			y = self.velocity.y - 0.03*cart_func:get_sign(self.velocity.y),
			z = self.velocity.z - 0.03*cart_func:get_sign(self.velocity.z),
		}
		-- Place the cart exactly on top of the rail
		if cart_func:is_rail(cart_func.v3:round(pos)) then 
			self.object:setpos({x=pos.x, y=math.floor(pos.y+0.5), z=pos.z})
			pos = self.object:getpos()
		end
	end
	
	-- Dont switch moving direction
	-- Only if on flat railway
	if dir.y == 0 then
		if cart_func:get_sign(dir.x) ~= cart_func:get_sign(self.velocity.x) then
			self.velocity.x = 0
		end
		if cart_func:get_sign(dir.y) ~= cart_func:get_sign(self.velocity.y) then
			self.velocity.y = 0
		end
		if cart_func:get_sign(dir.z) ~= cart_func:get_sign(self.velocity.z) then
			self.velocity.z = 0
		end
	end
	
	-- Set the new moving direction
	if cart_func:is_int(pos.x) and cart_func:is_int(pos.z) then
		
		dir = cart_func:velocity_to_dir(self.velocity)
		local dir_old = cart_func.v3:copy(dir)
		
		dir = self:get_rail_direction(cart_func.v3:round(pos), dir)
		
		local v = math.max(math.abs(self.velocity.x), math.abs(self.velocity.z))
		self.velocity = {
			x = v * dir.x,
			y = v * dir.y,
			z = v * dir.z,
		}
		
		if cart_func.v3:equal(self.velocity, {x=0, y=0, z=0}) then
			self.object:setvelocity(self.velocity)
			return
		end
		
		if not cart_func.v3:equal(dir, dir_old) then
			self.object:setpos(cart_func.v3:round(pos))
			pos = self.object:getpos()
		end
		
	end
	
	-- Allow only one moving direction (multiply the other one with 0)
	dir = cart_func:velocity_to_dir(self.velocity)
	self.velocity = {
		x = math.abs(self.velocity.x) * dir.x,
		y = self.velocity.y,
		z = math.abs(self.velocity.z) * dir.z,
	}
	
	-- Move cart exactly on the rail
	if dir.x == 0 and not cart_func:is_int(self.velocity.x) then
		pos.x = math.floor(0.5+pos.x)
		self.object:setpos(pos)
	elseif dir.z == 0 and not cart_func:is_int(self.velocity.z) then
		pos.z = math.floor(0.5+pos.z)
		self.object:setpos(pos)
	end
	
	-- Limit the velocity
	local v_tmp = cart_func.v3:copy(self.velocity)
	if math.abs(self.velocity.x) > self.MAX_V then
		self.velocity.x = self.MAX_V*cart_func:get_sign(self.velocity.x)
	end
	if math.abs(self.velocity.y) > self.MAX_V then
		self.velocity.y = self.MAX_V*cart_func:get_sign(self.velocity.y)
	end
	if math.abs(self.velocity.z) > self.MAX_V then
		self.velocity.z = self.MAX_V*cart_func:get_sign(self.velocity.z)
	end
	
	self.object:setvelocity(self.velocity)
	
	self.velocity = cart_func.v3:copy(v_tmp)
	
end

minetest.register_entity("carts:cart", cart)


minetest.register_craftitem("carts:cart", {
	description = "Minecart",
	inventory_image = minetest.inventorycube("cart_top.png", "cart_side.png", "cart_side.png"),
	wield_image = "cart_side.png",
	
	on_place = function(itemstack, placer, pointed_thing)
		if not pointed_thing.type == "node" then
			return
		end
		if cart_func:is_rail(pointed_thing.under) then
			minetest.env:add_entity(pointed_thing.under, "carts:cart")
			itemstack:take_item()
			return itemstack
		elseif cart_func:is_rail(pointed_thing.above) then
			minetest.env:add_entity(pointed_thing.above, "carts:cart")
			itemstack:take_item()
			return itemstack
		end
	end,
})

minetest.register_craft({
	output = "carts:cart",
	recipe = {
		{"", "", ""},
		{"default:steel_ingot", "", "default:steel_ingot"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
	},
})
