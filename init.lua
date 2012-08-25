--=========
-- Maximum speed of the cart
--=========
local MAX_SPEED = 4.5
--=========
-- Transport the player like a normal item
-- Note: This is extremly laggy <- FIXME
--=========
TRANSPORT_PLAYER = true
--=========
-- The name of the Soundfile
--=========
SOUND_FILES = {
				{"carts_curved_rails", 2},
				{"carts_railway_crossover", 2},
				{"carts_straight_rails", 1},
			  }

--=========
-- The sound gain
SOUND_GAIN = 0.8
--=========

--=========
-- Raillike nodes
--=========
RAILS = {"default:rail", "carts:meseconrail_off", "carts:meseconrail_on", "carts:meseconrail_stop_off", "carts:meseconrail_stop_on", "moreores:copper_rail"}

dofile(minetest.get_modpath("carts").."/box.lua")

local cart = {
	physical = true,
	collisionbox = {-0.425, -0.425, -0.425, 0.425, 0.425, 0.425},
	visual = "wielditem",
	textures = {"carts:cart_box"},
	visual_size = {x=0.85*2/3, y=0.85*2/3},
	--Variables
	fahren = false, -- true when the cart drives
	fallen = false, -- true when the cart drives downhill
	bremsen = false, -- true when the cart brakes
	dir = nil, -- direction of the cart
	old_dir = nil, -- saves the direction when the cart stops
	items = {}, -- list with transported items
	weiche = {x=nil, y=nil, z=nil}, -- saves the position of the railroad switch (to prevent double direction changes)
	sound_handler = nil, -- soundhandler
}

-- Returns the current speed of the cart
function cart:get_speed()
	if self.dir == "x+" then
		return self.object:getvelocity().x
	elseif self.dir == "x-" then
		return -1*self.object:getvelocity().x
	elseif self.dir == "z+" then
		return self.object:getvelocity().z
	elseif self.dir == "z-" then
		return -1*self.object:getvelocity().z
	end
	return 0
end

-- Sets the current speed of the cart
function cart:set_speed(speed)
	local newsp = {x=0, y=0, z=0}
	if self.dir == "x+" then
		newsp.x = speed
	elseif self.dir == "x-" then
		newsp.x = -1*speed
	elseif self.dir == "z+" then
		newsp.z = speed
	elseif self.dir == "z-" then
		newsp.z = -1*speed
	end
	self.object:setvelocity(newsp)
end

-- Sets the acceleration of the cart
function cart:set_acceleration(staerke)
	if self.dir == "x+" then
		self.object:setacceleration({x=staerke, y=-10, z=0})
	elseif self.dir == "x-" then
		self.object:setacceleration({x=-staerke, y=-10, z=0})
	elseif self.dir == "z+" then
		self.object:setacceleration({x=0, y=-10, z=staerke})
	elseif self.dir == "z-" then
		self.object:setacceleration({x=0, y=-10, z=-staerke})
	end
end

-- Stops the cart
function cart:stop()
	self.fahren = false
	self.bremsen = false
	self.items = {}
	self.fallen = false
	self.object:setacceleration({x = 0, y = -10, z = 0})
	self:set_speed(0)
	-- stop sound
	self:sound("stop")
end

function cart:sound(arg)
	if arg == "stop" then
		if self.sound_handler ~= nil then
			minetest.sound_stop(self.sound_handler)
			self.sound_handler = nil
		end
	elseif arg == "continue" then
		if self.sound_handler == nil then
			return
		end
		minetest.sound_stop(self.sound_handler)
		local sound = SOUND_FILES[math.random(1, #SOUND_FILES)]
		self.sound_handler = minetest.sound_play(sound[1], {
			object = self.object,
			gain = SOUND_GAIN,
		})
		minetest.after(sound[2], function()
			self:sound("continue")
		end)
	elseif arg == "start" then
		local sound = SOUND_FILES[math.random(1, #SOUND_FILES)]
		self.sound_handler = minetest.sound_play(sound[1], {
			object = self.object,
			gain = SOUND_GAIN,
		})
		minetest.after(sound[2], function()
			self:sound("continue")
		end)
	end
end

-- Returns the direction the cart has to drive
function cart:get_new_direction(pos)
	if pos == nil then
		pos = self.object:getpos()
	end
	if self.dir == nil then
		return nil
	end
	pos.x = math.floor(0.5+pos.x)
	pos.y = math.floor(0.5+pos.y)
	pos.z = math.floor(0.5+pos.z)
	if self.fallen then
		for i,rail in ipairs(RAILS) do
			if minetest.env:get_node({x=pos.x, y=pos.y-1, z=pos.z}).name == rail then
				return "y-"
			end
		end
	end
	if self.dir == "x+" then
		pos.x = pos.x+1
		for i,rail in ipairs(RAILS) do
			if minetest.env:get_node(pos).name == rail then
				pos.x = pos.x-1
				local meta = minetest.env:get_meta(pos)
				if meta:get_string("rail_direction") == "right" and not pos_equals(pos, self.weiche) then
					pos.z = pos.z+1
					for i,rail1 in ipairs(RAILS) do
						if minetest.env:get_node(pos).name == rail1 then
							self.weiche = {x=pos.x, y=pos.y, z=pos.z-1}
							return "z+"
						end
					end
					pos.z = pos.z-1
				elseif meta:get_string("rail_direction") == "left" and not pos_equals(pos, self.weiche) then
					pos.z = pos.z-1
					for i,rail1 in ipairs(RAILS) do
						if minetest.env:get_node(pos).name == rail1 then
							self.weiche = {x=pos.x, y=pos.y, z=pos.z+1}
							return "z-"
						end
					end
					pos.z = pos.z+1
				end
				
				return "x+"
			end
		end
		pos.y = pos.y-1
		for i,rail in ipairs(RAILS) do
			if minetest.env:get_node(pos).name == rail then
				return "y-"
			end
		end
		pos.y = pos.y+2
		for i,rail in ipairs(RAILS) do
			if minetest.env:get_node(pos).name == rail then
				return "y+"
			end
		end
		pos.y = pos.y-1
		pos.x = pos.x-1
		
		local tmp = minetest.env:get_meta(pos):get_string("rail_direction")
		if tmp == "left" then
			pos.z = pos.z+1
			for i,rail in ipairs(RAILS) do
				if minetest.env:get_node(pos).name == rail then
					return "z+"
				end
			end
			pos.z = pos.z-1
		elseif tmp == "right" then
			pos.z = pos.z-1
			for i,rail in ipairs(RAILS) do
				if minetest.env:get_node(pos).name == rail then
					return "z-"
				end
			end
			pos.z = pos.z+1
		end
		
		pos.z = pos.z-1
		for i,rail in ipairs(RAILS) do
			if minetest.env:get_node(pos).name == rail then
				return "z-"
			end
		end
		pos.z = pos.z+2
		for i,rail in ipairs(RAILS) do
			if minetest.env:get_node(pos).name == rail then
				return "z+"
			end
		end
		pos.z = pos.z-1
	elseif self.dir == "x-" then
		pos.x = pos.x-1
		for i,rail in ipairs(RAILS) do
			if minetest.env:get_node(pos).name == rail then
				pos.x = pos.x+1
				local meta = minetest.env:get_meta(pos)
				if meta:get_string("rail_direction") == "left" and not pos_equals(pos, self.weiche) then
					pos.z = pos.z+1
					for i,rail1 in ipairs(RAILS) do
						if minetest.env:get_node(pos).name == rail1 then
							self.weiche = {x=pos.x, y=pos.y, z=pos.z-1}
							return "z+"
						end
					end
					pos.z = pos.z-1
				elseif meta:get_string("rail_direction") == "right" and not pos_equals(pos, self.weiche) then
					pos.z = pos.z-1
					for i,rail1 in ipairs(RAILS) do
						if minetest.env:get_node(pos).name == rail1 then
							self.weiche = {x=pos.x, y=pos.y, z=pos.z+1}
							return "z-"
						end
					end
					pos.z = pos.z+1
				end
				
				return "x-"
			end
		end
		pos.y = pos.y-1
		for i,rail in ipairs(RAILS) do
			if minetest.env:get_node(pos).name == rail then
				return "y-"
			end
		end
		pos.y = pos.y+2
		for i,rail in ipairs(RAILS) do
			if minetest.env:get_node(pos).name == rail then
				return "y+"
			end
		end
		pos.y = pos.y-1
		pos.x = pos.x+1
		
		local tmp = minetest.env:get_meta(pos):get_string("rail_direction")
		if tmp == "left" then
			pos.z = pos.z-1
			for i,rail in ipairs(RAILS) do
				if minetest.env:get_node(pos).name == rail then
					return "z-"
				end
			end
			pos.z = pos.z+1
		elseif tmp == "right" then
			pos.z = pos.z+1
			for i,rail in ipairs(RAILS) do
				if minetest.env:get_node(pos).name == rail then
					return "z+"
				end
			end
			pos.z = pos.z-1
		end
		
		pos.z = pos.z+1
		for i,rail in ipairs(RAILS) do
			if minetest.env:get_node(pos).name == rail then
				return "z+"
			end
		end
		pos.z = pos.z-2
		for i,rail in ipairs(RAILS) do
			if minetest.env:get_node(pos).name == rail then
				return "z-"
			end
		end
		pos.z = pos.z+1
	elseif self.dir == "z+" then
		pos.z = pos.z+1
		for i,rail in ipairs(RAILS) do
			if minetest.env:get_node(pos).name == rail then
				pos.z = pos.z-1
				local meta = minetest.env:get_meta(pos)
				if meta:get_string("rail_direction") == "left" and not pos_equals(pos, self.weiche) then
					pos.x = pos.x+1
					for i,rail1 in ipairs(RAILS) do
						if minetest.env:get_node(pos).name == rail1 then
							self.weiche = {x=pos.x-1, y=pos.y, z=pos.z}
							return "x+"
						end
					end
					pos.x = pos.x-1
				elseif meta:get_string("rail_direction") == "right" and not pos_equals(pos, self.weiche) then
					pos.x = pos.x-1
					for i,rail1 in ipairs(RAILS) do
						if minetest.env:get_node(pos).name == rail1 then
							self.weiche = {x=pos.x+1, y=pos.y, z=pos.z}
							return "x-"
						end
					end
					pos.x = pos.x+1
				end
				
				return "z+"
			end
		end
		pos.y = pos.y-1
		for i,rail in ipairs(RAILS) do
			if minetest.env:get_node(pos).name == rail then
				return "y-"
			end
		end
		pos.y = pos.y+2
		for i,rail in ipairs(RAILS) do
			if minetest.env:get_node(pos).name == rail then
				return "y+"
			end
		end
		pos.y = pos.y-1
		pos.z = pos.z-1
		
		local tmp = minetest.env:get_meta(pos):get_string("rail_direction")
			if tmp == "left" then
			pos.x = pos.x-1
			for i,rail in ipairs(RAILS) do
				if minetest.env:get_node(pos).name == rail then
					return "x-"
				end
			end
			pos.x = pos.x+1
		elseif tmp == "right" then
			pos.x = pos.x+1
			for i,rail in ipairs(RAILS) do
				if minetest.env:get_node(pos).name == rail then
					return "x+"
				end
			end
			pos.x = pos.x-1
		end
		
		pos.x = pos.x+1
		for i,rail in ipairs(RAILS) do
			if minetest.env:get_node(pos).name == rail then
				return "x+"
			end
		end
		pos.x = pos.x-2
		for i,rail in ipairs(RAILS) do
			if minetest.env:get_node(pos).name == rail then
				return "x-"
			end
		end
		pos.x = pos.x+1
	elseif self.dir == "z-" then
		pos.z = pos.z-1
		for i,rail in ipairs(RAILS) do
			if minetest.env:get_node(pos).name == rail then
				pos.z = pos.z+1
				local meta = minetest.env:get_meta(pos)
				if meta:get_string("rail_direction") == "right" and not pos_equals(pos, self.weiche) then
					pos.x = pos.x+1
					for i,rail1 in ipairs(RAILS) do
						if minetest.env:get_node(pos).name == rail1 then
							self.weiche = {x=pos.x-1, y=pos.y, z=pos.z}
							return "x+"
						end
					end
					pos.x = pos.x-1
				elseif meta:get_string("rail_direction") == "left" and not pos_equals(pos, self.weiche) then
					pos.x = pos.x-1
					for i,rail1 in ipairs(RAILS) do
						if minetest.env:get_node(pos).name == rail1 then
							self.weiche = {x=pos.x+1, y=pos.y, z=pos.z}
							return "x-"
						end
					end
					pos.x = pos.x+1
				end
				
				return "z-"
			end
		end
		pos.y = pos.y-1
		for i,rail in ipairs(RAILS) do
			if minetest.env:get_node(pos).name == rail then
				return "y-"
			end
		end
		pos.y = pos.y+2
		for i,rail in ipairs(RAILS) do
			if minetest.env:get_node(pos).name == rail then
				return "y+"
			end
		end
		pos.y = pos.y-1
		pos.z = pos.z+1
		
		local tmp = minetest.env:get_meta(pos):get_string("rail_direction")
		if tmp == "left" then
			pos.x = pos.x+1
			for i,rail in ipairs(RAILS) do
				if minetest.env:get_node(pos).name == rail then
					return "x+"
				end
			end
			pos.x = pos.x-1
		elseif tmp == "right" then
			pos.x = pos.x-1
			for i,rail in ipairs(RAILS) do
				if minetest.env:get_node(pos).name == rail then
					return "x-"
				end
			end
			pos.x = pos.x+1
		end
		
		pos.x = pos.x-1
		for i,rail in ipairs(RAILS) do
			if minetest.env:get_node(pos).name == rail then
				return "x-"
			end
		end
		pos.x = pos.x+2
		for i,rail in ipairs(RAILS) do
			if minetest.env:get_node(pos).name == rail then
				return "x+"
			end
		end
		pos.x = pos.x-1
	end
	return nil
end

-- This method does several things.
function cart:on_step(dtime)
	-- if the cart dont drives set gravity and return
	if not self.fahren then
		self.object:setacceleration({x=0, y=-10, z=0})
		return
	end
	
	local newdir = self:get_new_direction()
	if newdir == "x+" then
		self.object:setyaw(0)
	elseif newdir == "x-" then
		self.object:setyaw(math.pi)
	elseif newdir == "z+" then
		self.object:setyaw(math.pi/2)
	elseif newdir == "z-" then
		self.object:setyaw(math.pi*3/2)
	end
	if newdir == nil and not self.fallen then
		-- end of rail
		-- chek if the cart derailed
		local pos = self.object:getpos()
		if self.dir == "x+" then
			pos.x = pos.x-1
		elseif self.dir == "x-" then
			pos.x = pos.x+1
		elseif self.dir == "z+" then
			pos.z = pos.z-1
		elseif self.dir == "z-" then
			pos.z = pos.z+1
		end
		local checkdir = self:get_new_direction(pos)
		if checkdir ~= self.dir and checkdir ~= nil then
			self.object:setpos(pos)
			self.dir = checkdir
			self.old_dir = checkdir
			-- change direction
			local speed = self:get_speed()
			self:set_speed(speed)
		else
			-- stop
			self:stop()
			local pos = self.object:getpos()
			pos.x = math.floor(0.5+pos.x)
			pos.z = math.floor(0.5+pos.z)
			self.object:setpos(pos)
		end
	elseif newdir == "y+" then
		-- uphill
		self.fallen = false
		local vel = self.object:getvelocity()
		vel.y = MAX_SPEED
		self.object:setvelocity(vel)
	elseif newdir == "y-" then
		-- downhill
		local vel = self.object:getvelocity()
		vel.y = -2*MAX_SPEED
		self.object:setvelocity(vel)
		self.fallen = true
	elseif newdir ~= self.dir then
		-- curve
		self.fallen = false
		local pos = self.object:getpos()
		-- wait until the cart is nearly on the cornernode
		if equals(pos.x, math.floor(0.5+pos.x)) and equals(pos.y, math.floor(0.5+pos.y)) and equals(pos.z, math.floor(0.5+pos.z)) then
			-- "jump" exacly on the cornernode
			pos.x = math.floor(0.5+pos.x)
			pos.z = math.floor(0.5+pos.z)
			self.object:setpos(pos)
			-- change direction
			local speed = self:get_speed()
			self.dir = newdir
			self.old_dir = newdir
			self:set_speed(speed)
		end
	end
	
	-- control speed and acceleration
	if self.bremsen then
		if not equals(self:get_speed(), 0) then
			-- if the cart is still driving -> brake
			self:set_acceleration(-10)
		else
			-- if the cart stand still -> stop
			self:stop()
		end
	else
		if self.fahren and self:get_speed() < MAX_SPEED then
			-- if the cart is too slow -> accelerate
			self:set_acceleration(10)
		else
			self:set_acceleration(0)
		end
	end
	
	-- move items
	for i,item in ipairs(self.items) do
		if item:is_player() then
			-- if the item is a player move him 0.5 blocks lowlier
			local pos = self.object:getpos()
			pos.y = pos.y-0.5
			item:setpos(pos)
		else
			item:setpos(self.object:getpos())
			if item:get_luaentity() ~= nil then
				item:setvelocity(self.object:getvelocity())
			end
		end
	end
	
	-- if the cart isnt on a railroad switch reset the variable
	local pos_tmp = self.object:getpos()
	pos_tmp.x = math.floor(0.5+pos_tmp.x)
	pos_tmp.y = math.floor(0.5+pos_tmp.y)
	pos_tmp.z = math.floor(0.5+pos_tmp.z)
	if not pos_equals(pos_tmp, self.weiche) then
		self.weiche = {x=nil, y=nil, z=nil}
	end
	
	-- search for chests
	for d=-1,1 do
		local pos = {x=self.object:getpos().x+d, y=self.object:getpos().y, z=self.object:getpos().z}
		local name1 = minetest.env:get_node(pos).name
		pos = {x=self.object:getpos().x, y=self.object:getpos().y, z=self.object:getpos().z+d}
		local name2 = minetest.env:get_node(pos).name
		if name1 == "carts:chest" then
			pos = {x=self.object:getpos().x+d, y=self.object:getpos().y, z=self.object:getpos().z}
		elseif name2 == "carts:chest" then
			pos = {x=self.object:getpos().x, y=self.object:getpos().y, z=self.object:getpos().z+d}
		else
			name1 = nil
		end
		if name1 ~= nil then
			pos.x = math.floor(0.5+pos.x)
			pos.y = math.floor(0.5+pos.y)
			pos.z = math.floor(0.5+pos.z)
			local inv = minetest.env:get_meta(pos):get_inventory()
			-- drop items
			local items_tmp = {}
			local inv = minetest.env:get_meta(pos):get_inventory()
			for i,item in ipairs(self.items) do
				if not item:is_player() and item:get_luaentity().itemstring ~= nil and item:get_luaentity().itemstring ~= "" and inv:room_for_item("in", ItemStack(item:get_luaentity().itemstring)) then
					if item:get_luaentity().pickup == nil or not pos_equals(pos, item:get_luaentity().pickup) then
						inv:add_item("in", ItemStack(item:get_luaentity().itemstring))
					item:remove()
					else
						table.insert(items_tmp, item)
					end
				else
					table.insert(items_tmp, item)
				end
			end
			self.items = items_tmp
			
			--pick up items
			for i=1,inv:get_size("out") do
				local stack = inv:get_stack("out", i)
				if not stack:is_empty() then
					local item =  minetest.env:add_entity(self.object:getpos(), "__builtin:item")
					item:get_luaentity():set_item(stack:get_name().." "..stack:get_count())
					item:get_luaentity().pickup = pos
					table.insert(self.items, item)
					inv:remove_item("out", stack)
				end
			end
		end
	end
	
	-- mesecons functions
	if minetest.get_modpath("mesecons") ~= nil then
		local pos = self.object:getpos()
		pos.x = math.floor(0.5+pos.x)
		pos.y = math.floor(0.5+pos.y)
		pos.z = math.floor(0.5+pos.z)
		local name = minetest.env:get_node(pos).name
		if name == "carts:meseconrail_off" then
			minetest.env:set_node(pos, {name="carts:meseconrail_on"})
			if mesecon ~= nil then
				mesecon:receptor_on(pos)
			end
		end
		
		if name == "carts:meseconrail_stop_on" then
			self:stop()
			local pos = self.object:getpos()
			pos.x = math.floor(0.5+pos.x)
			pos.z = math.floor(0.5+pos.z)
			self.object:setpos(pos)
		end
	end
end

-- rightclick starts/stops the cart
function cart:on_rightclick(clicker)
	if self.fahren then
		self.bremsen = true
	else
		-- find out the direction
		local pos_cart = self.object:getpos()
		local pos_player = clicker:getpos()
		local res = {x=pos_cart.x-pos_player.x, z=pos_cart.z-pos_player.z}
		if math.abs(res.x) > math.abs(res.z) then
			if res.x < 0 then
				self.dir = "x-"
				self.old_dir = "x-"
				if self:get_new_direction() ~= "x-" then
					if res.z < 0 then
						self.dir = "z-"
						self.old_dir = "z-"
					else
						self.dir = "z+"
						self.old_dir = "z+"
					end
					if self:get_new_direction() ~= self.dir then
						self.dir = "x-"
						self.old_dir = "x-"
					end
				end
			else
				self.dir = "x+"
				self.old_dir = "x+"
				if self:get_new_direction() ~= "x+" then
					if res.z < 0 then
						self.dir = "z-"
						self.old_dir = "z-"
					else
						self.dir = "z+"
						self.old_dir = "z+"
					end
					if self:get_new_direction() ~= self.dir then
						self.dir = "x+"
						self.old_dir = "x+"
					end
				end
			end
		else
			if res.z < 0 then
				self.dir = "z-"
				self.old_dir = "z-"
				if self:get_new_direction() ~= "z-" then
					if res.x < 0 then
						self.dir = "x-"
						self.old_dir = "x-"
					else
						self.dir = "x+"
						self.old_dir = "x+"
					end
					if self:get_new_direction() ~= self.dir then
						self.dir = "z-"
						self.old_dir = "z-"
					end
				end
			else
				self.dir = "z+"
				self.old_dir = "z+"
				if self:get_new_direction() ~= "z+" then
					if res.x < 0 then
						self.dir = "x-"
						self.old_dir = "x-"
					else
						self.dir = "x+"
						self.old_dir = "x+"
					end
					if self:get_new_direction() ~= self.dir then
						self.dir = "z+"
						self.old_dir = "z+"
					end
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

-- remove the cart and place it in the inventory
function cart:on_punch(hitter)
	-- stop sound
	self:sound("stop")
	self.object:remove()
	hitter:get_inventory():add_item("main", "carts:cart")
end

-- save the probprties of the cart if unloaded
function cart:get_staticdata()
	--[[local str = tostring(self.fahren)
	str = str..","
	if self.fahren then
		str = str..self.dir
	end
	self.object:setvelocity({x=0, y=0, z=0})]]
	minetest.debug("[cartsDebug] ===get_staticdata()===")
	minetest.debug("[cartsDebug] "..minetest.pos_to_string(self.object:getpos()))
	local table = {
		fahren = self.fahren,
		fallen = self.fallen,
		bremsen = self.bremsen,
		dir = self.dir,
		old_dir = self.old_dir,
		items = self.items,
		weiche = self.weiche,
		sound_handler = self.sound_handler,
	}
	minetest.debug("[cartsDebug] => "..minetest.serialize(table))
	self:sound("stop")
	return minetest.serialize(table)
end

-- set gravity
function cart:on_activate(staticdata)
	self.object:setacceleration({x = 0, y = -10, z = 0})
	self.items = {}
	if staticdata ~= nil then
		minetest.debug("[cartsDebug] ===on_activate()===")
		--[[ if the cart was unloaded
		if string.find(staticdata, ",") ~= nil then
			-- restore the probprties
			if string.sub(staticdata, 1, string.find(staticdata, ",")-1)=="true" then
				self.dir = string.sub(staticdata, string.find(staticdata, ",")+1)
				self.old_dir = dir
				self.fahren = true
			end
		end]]
		local table = minetest.deserialize(staticdata)
		if table ~= nil then
			minetest.debug("[cartsDebug] Fuege tabelle ein")
			self.fahren = table.fahren
			self.fallen = table.fallen
			self.bremsen = table.bremsen
			self.dir = table.dir
			self.old_dir = table.old_dir
			self.items = table.items
			self.weiche = table.weiche
			self.sound_handler = table.sound_handler
			
			if self.fahren then
				self:sound("start")
			end
		end
	end
end

minetest.register_entity("carts:cart", cart)

-- inventoryitem
minetest.register_craftitem("carts:cart", {
	description = "Cart",
	image = minetest.inventorycube("carts_cart_top.png", "carts_cart_side.png", "carts_cart_side.png"),
	wield_image = "carts_cart_top.png",
	stack_max = 1,
	-- replace it with the object
	on_place = function(itemstack, placer, pointed)
		local pos = pointed.under
		local bool = false
		for i,rail in ipairs(RAILS) do
			if minetest.env:get_node(pos).name == rail then
				bool = true
			end
		end
		if not bool then
			pos = pointed.above
		end
		pos = {x = math.floor(0.5+pos.x), y = math.floor(0.5+pos.y), z = math.floor(0.5+pos.z)}
		minetest.env:add_entity(pos, "carts:cart")
		itemstack:take_item(1)
		return itemstack
	end,
})

minetest.register_craft({
	output = '"carts:cart" 1',
	recipe = {
		{'default:steel_ingot', '', 'default:steel_ingot'},
		{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'}
	}
})

dofile(minetest.get_modpath("carts").."/switches.lua")
dofile(minetest.get_modpath("carts").."/mesecons.lua")
dofile(minetest.get_modpath("carts").."/chest.lua")
dofile(minetest.get_modpath("carts").."/functions.lua")
