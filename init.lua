
dofile(minetest.get_modpath("carts").."/functions.lua")

--
-- Cart entity
--

local cart = {
	physical = false,
	collisionbox = {-0.5,-0.5,-0.5, 0.5,0.5,0.5},
	visual = "mesh",
	mesh = "cart.x",
	visual_size = {x=1, y=1},
	textures = {"cart.png"},

	driver = nil,
	velocity = {x=0, y=0, z=0},
	old_pos = nil,
	old_velocity = nil,
	pre_stop_dir = nil,
  MAX_V = 8, -- Limit of the velocity --
  TARGET_TOUR_V = 4.5, -- target touring velocity --
  railcount=0, 
  ignorekeypos=nil,
  lockyaw=false,
  yawtarget=nil,
  YAW_STEP=math.pi/12
  --smaller YAW_STEP makes for smoother camera turning.  BUT, takes much longer and can fall behind
}

function cart:on_rightclick(clicker)
	if not clicker or not clicker:is_player() then
		return
	end
	if self.driver and clicker == self.driver then
		self.driver = nil
		clicker:set_detach()
	elseif not self.driver then
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
		end
		if tmp and tmp.pre_stop_dir then
			self.pre_stop_dir = tmp.pre_stop_dir
		end
	end
	self.old_pos = self.object:getpos()
	self.old_velocity = self.velocity
end

function cart:get_staticdata()
	return minetest.serialize({
		velocity = self.velocity,
		pre_stop_dir = self.pre_stop_dir,
	})
end

-- Remove the cart if holding a tool or accelerate it
function cart:on_punch(puncher, time_from_last_punch, tool_capabilities, direction)
	if not puncher or not puncher:is_player() then
		return
	end

	if puncher:get_player_control().sneak then
    print("cart: end pos="..pos_to_string(vector.round(self.object:getpos())).." railcount="..self.railcount) 
		self.object:remove()
		local inv = puncher:get_inventory()
		if minetest.setting_getbool("creative_mode") then
			if not inv:contains_item("main", "carts:cart") then
				inv:add_item("main", "carts:cart")
			end
		else
			inv:add_item("main", "carts:cart")
		end
		return
	end

--	if puncher == self.driver then
  if puncher == self.driver and (math.abs(self.velocity.x)>1 or math.abs(self.velocity.z)>1) then
		return
	end

	local d = cart_func:velocity_to_dir(direction)
 	if d.x==0 and d.z==0 then
		local fd = minetest.dir_to_facedir(puncher:get_look_dir())
		if fd == 0 then
			d.x = 1
		elseif fd == 1 then
			d.z = -1
		elseif fd == 2 then
			d.x = -1
		elseif fd == 3 then
			d.z = 1
		end
	end

	local s = self.velocity
	if time_from_last_punch > tool_capabilities.full_punch_interval then
		time_from_last_punch = tool_capabilities.full_punch_interval
	end
	local f = 4*(time_from_last_punch/tool_capabilities.full_punch_interval)
	local v = {x=s.x+d.x*f, y=s.y, z=s.z+d.z*f}
	if math.abs(v.x) < 6 and math.abs(v.z) < 6 then
		self.velocity = v
	else
		if math.abs(self.velocity.x) < 6 and math.abs(v.x) >= 6 then
			self.velocity.x = 6*cart_func:get_sign(self.velocity.x)
		end
		if math.abs(self.velocity.z) < 6 and math.abs(v.z) >= 6 then
			self.velocity.z = 6*cart_func:get_sign(self.velocity.z)
		end
	end
end 





-- Returns the direction as a unit vector
function cart:get_rail_direction(pos, dir)
  --print("get_rail_direction top pos="..pos_to_string(pos).." dir="..pos_to_string(dir))
  local fwd=cart_func.v3:copy(dir)
  fwd.y=0
  local up=cart_func.v3:copy(dir)
  up.y=1
  local down=cart_func.v3:copy(dir)
  down.y=-1
	-- figure out left and right
  local left={x=0,y=0,z=0}
  local right={x=0,y=0,z=0}
  if dir.z ~= 0 and dir.x == 0 then
    left.x=-dir.z  --left is opposite sign from z
    right.x=dir.z  --right is same sign as z
  elseif dir.x ~= 0 and dir.z == 0 then
    left.z=dir.x   --left is same sign as x
    right.z=-dir.x --right is opposite sign from x
  end --left and right
  local leftdown=cart_func.v3:copy(left)
  leftdown.y=-1
  local rightdown=cart_func.v3:copy(right)
  rightdown.y=-1
  --print("  fwd="..pos_to_string(fwd))
  --print("  down="..pos_to_string(down))
  --print("  up="..pos_to_string(up))
  --print("  left="..pos_to_string(left))
  --print("  leftdown="..pos_to_string(leftdown))
  --print("  right="..pos_to_string(right))
  --print("  rightdown="..pos_to_string(rightdown))

  local ignorekeys=false
  --ignorekeypos stores a position where we changed direction because the
  --player was pressing left or right keys.  once we have changed direction,
  --we want to ignore those keys until you have changed to a different rail
  --(otherwise you end up reversing)
  --I use the ignorekeys boolean to make the key logic more readable
  if self.ignorekeypos then --ignorekeypos was set
    if cart_func.v3:equal(self.ignorekeypos,pos) then
      ignorekeys=true --if still at same position, ignore left and right keys
    else 
      self.ignorekeypos=nil --if ignorekeypos was set but pos does not match anymore, clear it
    end
  end
    
  local ctrl=nil    
  if self.driver and not ignorekeys then
    ctrl = self.driver:get_player_control()
  end
    
  if ctrl and ctrl.left then --left key pressed, check left first
    if cart_func:check_rail_in_direction(pos,left) then
      self.ignorekeypos=cart_func.v3:copy(pos) --ignore keys until pos changes
      return left
    elseif cart_func:check_rail_in_direction(pos,leftdown) then
      self.ignorekeypos=cart_func.v3:copy(pos)
      return leftdown
    end
  elseif ctrl and ctrl.right then --right key pressed, check right first
    if cart_func:check_rail_in_direction(pos,right) then
      self.ignorekeypos=cart_func.v3:copy(pos)
      return right
    elseif cart_func:check_rail_in_direction(pos,rightdown) then
      self.ignorekeypos=cart_func.v3:copy(pos)
      return rightdown
    end
  end --ctrl.left  ctrl.right

  --now for normal checks
  if cart_func:check_rail_in_direction(pos,fwd) then
    return fwd
  elseif cart_func:check_rail_in_direction(pos,down) then
    return down
	elseif cart_func:check_rail_in_direction(pos,up) then
    return up
	elseif (not ctrl or not ctrl.left) --only check left if we didnt above
                     and cart_func:check_rail_in_direction(pos,left) then
    return left
  elseif (not ctrl or not ctrl.left)
                     and cart_func:check_rail_in_direction(pos,leftdown) then
    return leftdown
  elseif (not ctrl or not ctrl.right) --only check right if we didnt above
                     and cart_func:check_rail_in_direction(pos,right) then
    return right
  elseif (not ctrl or not ctrl.right)
                     and cart_func:check_rail_in_direction(pos,rightdown) then
    return rightdown
  else
    return {x=0, y=0, z=0}
  end --normal rail checks
end  --get_rail_direction



function cart:calc_rail_direction(pos, vel)
	local velocity = cart_func.v3:copy(vel)
	local p = cart_func.v3:copy(pos)
	if cart_func:is_int(p.x) and cart_func:is_int(p.z) then

		local dir = cart_func:velocity_to_dir(velocity)
		local dir_old = cart_func.v3:copy(dir)

		dir = self:get_rail_direction(cart_func.v3:round(p), dir)

		local v = math.max(math.abs(velocity.x), math.abs(velocity.z))
		velocity = {
			x = v * dir.x,
			y = v * dir.y,
			z = v * dir.z,
		}

		if cart_func.v3:equal(velocity, {x=0, y=0, z=0}) then

			-- First try this HACK
			-- Move the cart on the rail if above or under it
			if cart_func:is_rail(cart_func.v3:add(p, {x=0, y=1, z=0})) and vel.y >= 0 then
				p = cart_func.v3:add(p, {x=0, y=1, z=0})
				return self:calc_rail_direction(p, vel)
			end
			if cart_func:is_rail(cart_func.v3:add(p, {x=0, y=-1, z=0})) and vel.y <= 0  then
				p = cart_func.v3:add(p, {x=0, y=-1, z=0})
				return self:calc_rail_direction(p, vel)
			end
			-- Now the HACK gets really dirty
			if cart_func:is_rail(cart_func.v3:add(p, {x=0, y=2, z=0})) and vel.y >= 0 then
				p = cart_func.v3:add(p, {x=0, y=1, z=0})
				return self:calc_rail_direction(p, vel)
			end
			if cart_func:is_rail(cart_func.v3:add(p, {x=0, y=-2, z=0})) and vel.y <= 0 then
				p = cart_func.v3:add(p, {x=0, y=-1, z=0})
				return self:calc_rail_direction(p, vel)
			end

			return {x=0, y=0, z=0}, p
		end

		if not cart_func.v3:equal(dir, dir_old) then       
			return velocity, cart_func.v3:round(p)
		end

	end
	return velocity, p
end



--because built in pos_to_string doesn't handle nil
function pos_to_string(pos)
  if pos==nil then return "(nil)"
  else return minetest.pos_to_string(pos)
  end --poss==nill
end --pos_to_string



function cart:on_step(dtime)

	local pos = self.object:getpos()
	local dir = cart_func:velocity_to_dir(self.velocity)

  --*!*debug
  if self.old_pos then
    local cmp_old=vector.round(self.old_pos)
    local cmp_new=vector.round(pos)
    if cmp_old.x~=cmp_new.x or cmp_old.y~=cmp_new.y or cmp_old.z~=cmp_new.z then
      self.railcount=self.railcount+1
      --local a = tonumber(minetest.env:get_meta(pos):get_string("cart_acceleration"))
      --local railtype=""
      --if a and a>0 then railtype="power" end
      --minetest.chat_send_all("-- cart pos="..pos_to_string(vector.round(pos)).." railcount="..self.railcount.." vel="..pos_to_string(self.velocity).." "..railtype)  --*!*debug
    end
  end
  --*!*debug
  
  local ctrl=nil    
  if self.driver then
    ctrl = self.driver:get_player_control()
    if ctrl and ctrl.jump and not self.lockyaw then
      self.lockyaw=true
      self.yawtarget=self.object:getyaw()
      minetest.chat_send_player(self.driver:get_player_name(),"cart: player view locked to cart, hit SNEAK to unlock")  
    elseif ctrl and ctrl.sneak and self.lockyaw then
      self.lockyaw=false
      minetest.chat_send_player(self.driver:get_player_name(),"cart: player view NOT locked to cart, hit JUMP to lock")        
    end
  end --check lockyaw if self.driver  
     
      

	if not cart_func.v3:equal(self.velocity, {x=0,y=0,z=0}) then
		self.pre_stop_dir = cart_func:velocity_to_dir(self.velocity)
	end

	-- Stop the cart if the velocity is nearly 0
	-- Only if on a flat railway
	if dir.y == 0 then
		if math.abs(self.velocity.x) < 0.1 and  math.abs(self.velocity.z) < 0.1 then
			-- Start the cart if powered from mesecons
			local a = tonumber(minetest.env:get_meta(pos):get_string("cart_acceleration"))
			if a and a ~= 0 then
				if self.pre_stop_dir and cart_func.v3:equal(self:get_rail_direction(self.object:getpos(), self.pre_stop_dir), self.pre_stop_dir) then
					self.velocity = {
						x = self.pre_stop_dir.x * 0.2,
						y = self.pre_stop_dir.y * 0.2,
						z = self.pre_stop_dir.z * 0.2,
					}
					self.old_velocity = self.velocity
					return
				end
				for _,y in ipairs({0,-1,1}) do
					for _,z in ipairs({1,-1}) do
						if cart_func.v3:equal(self:get_rail_direction(self.object:getpos(), {x=0, y=y, z=z}), {x=0, y=y, z=z}) then
							self.velocity = {
								x = 0,
								y = 0.2*y,
								z = 0.2*z,
							}
							self.old_velocity = self.velocity
							return
						end
					end
					for _,x in ipairs({1,-1}) do
						if cart_func.v3:equal(self:get_rail_direction(self.object:getpos(), {x=x, y=y, z=0}), {x=x, y=y, z=0}) then
							self.velocity = {
								x = 0.2*x,
								y = 0.2*y,
								z = 0,
							}
							self.old_velocity = self.velocity
    					return
						end
					end
				end
			end

			self.velocity = {x=0, y=0, z=0}
			self.object:setvelocity(self.velocity)
			self.old_velocity = self.velocity
			self.old_pos = self.object:getpos()
			return
		end
	end

	--
	-- Set the new moving direction
	--

	-- Recalcualte the rails that are passed since the last server step
	local old_dir = cart_func:velocity_to_dir(self.old_velocity)
	if old_dir.x ~= 0 then
		local sign = cart_func:get_sign(pos.x-self.old_pos.x)
		while true do
			if sign ~= cart_func:get_sign(pos.x-self.old_pos.x) or pos.x == self.old_pos.x then
				break
			end
			self.old_pos.x = self.old_pos.x + cart_func:get_sign(pos.x-self.old_pos.x)*0.1
			self.old_pos.y = self.old_pos.y + cart_func:get_sign(pos.x-self.old_pos.x)*0.1*old_dir.y
			self.old_velocity, self.old_pos = self:calc_rail_direction(self.old_pos, self.old_velocity)
			old_dir = cart_func:velocity_to_dir(self.old_velocity)
			if not cart_func.v3:equal(cart_func:velocity_to_dir(self.old_velocity), dir) then
				self.velocity = self.old_velocity
				pos = self.old_pos
				self.object:setpos(self.old_pos)
				break
			end
		end
	elseif old_dir.z ~= 0 then
		local sign = cart_func:get_sign(pos.z-self.old_pos.z)
		while true do
			if sign ~= cart_func:get_sign(pos.z-self.old_pos.z) or pos.z == self.old_pos.z then
				break
			end
			self.old_pos.z = self.old_pos.z + cart_func:get_sign(pos.z-self.old_pos.z)*0.1
			self.old_pos.y = self.old_pos.y + cart_func:get_sign(pos.z-self.old_pos.z)*0.1*old_dir.y
			self.old_velocity, self.old_pos = self:calc_rail_direction(self.old_pos, self.old_velocity)
			old_dir = cart_func:velocity_to_dir(self.old_velocity)
			if not cart_func.v3:equal(cart_func:velocity_to_dir(self.old_velocity), dir) then
				self.velocity = self.old_velocity
				pos = self.old_pos
				self.object:setpos(self.old_pos)
				break
			end
		end
	end

	-- Calculate the new step
	self.velocity, pos = self:calc_rail_direction(pos, self.velocity)
	self.object:setpos(pos)
	dir = cart_func:velocity_to_dir(self.velocity)

	-- Accelerate or decelerate the cart according to the pitch and acceleration of the rail node
  local a = tonumber(minetest.env:get_meta(pos):get_string("cart_acceleration"))
  if not a then
      a = 0
  end
  local t = tonumber(minetest.env:get_meta(pos):get_string("cart_touring_velocity"))
  if not t then t=0 end
  if t>0 then
    local vx=math.abs(self.velocity.x)
    local vy=math.abs(self.velocity.y)
    local vz=math.abs(self.velocity.z)
    -- make v the largest of the 3 velocities
    local v=vx
    if vy>v then v=vy end
    if vz>v then v=vz end
    --
    local diff=0
    local acelordecl=0
    if v>t then
      diff=v-t
      acelordecl=-1
    elseif v<t then
      diff=t-v
      acelordecl=1
    end --v>t
    --print("    on_step t1 v="..v.." t="..t.." diff="..diff.." a="..a.." acelordecl="..acelordecl)
    --adjust for grav
    if self.velocity.y<0 then --going downhill so grav will acel by extra 0.13
      --if we are decel then add an extra 0.13 to how much we need to decel
      --if we are accel then subtract an extra 0.13 from how much we need to acel
      diff=diff-(0.13*acelordecl)
    elseif self.velocity.y>0 then --going uphill grav will decl by extra 0.10
      --if we are decel then subtract 0.1 from how much we need to decel
      --if we are acel then add 0.1 to how much we need to acel
      diff=diff+(0.1*acelordecl)
    end -- self.velocity.y<0
    --so now diff is the difference between cart velocity (after this turns grav)
    --and our target touring velocity
    --print("*!* on_step t2 grav v="..v.." diff="..diff.." a="..a)
    if diff<a then  --we dont want to over acel or decel
      a=diff
    elseif diff>a*4 then
      a=a*2 --if big difference, play catchup fast!
    elseif diff>a*3 then
      a=a*1.5  --if big difference, play catchup fast!
    end --diff<a
    a=a*acelordecl
  end -- if t>0

  --check if down arrow is being pressed (hand break)     
  if self.driver then
    local ctrl = self.driver:get_player_control()
    if ctrl and ctrl.down then
      a=a-0.1 --same as uphill 
      
    end --if hand break  
  end --if self.driver  

	if self.velocity.y < 0 then
		self.velocity = {
			x = self.velocity.x + (a+0.13)*cart_func:get_sign(self.velocity.x),
			y = self.velocity.y + (a+0.13)*cart_func:get_sign(self.velocity.y),
			z = self.velocity.z + (a+0.13)*cart_func:get_sign(self.velocity.z),
		}
	elseif self.velocity.y > 0 then
		self.velocity = {
			x = self.velocity.x + (a-0.1)*cart_func:get_sign(self.velocity.x),
			y = self.velocity.y + (a-0.1)*cart_func:get_sign(self.velocity.y),
			z = self.velocity.z + (a-0.1)*cart_func:get_sign(self.velocity.z),
		}
	else
		self.velocity = {
			x = self.velocity.x + (a-0.03)*cart_func:get_sign(self.velocity.x),
			y = self.velocity.y + (a-0.03)*cart_func:get_sign(self.velocity.y),
			z = self.velocity.z + (a-0.03)*cart_func:get_sign(self.velocity.z),
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

	-- Allow only one moving direction (multiply the other one with 0)
	dir = cart_func:velocity_to_dir(self.velocity)
	self.velocity = {
		x = math.abs(self.velocity.x) * dir.x,
		y = self.velocity.y,
		z = math.abs(self.velocity.z) * dir.z,
	}


	-- Move cart exactly on the rail
	if dir.x ~= 0 and not cart_func:is_int(pos.z) then
		pos.z = math.floor(0.5+pos.z)
		self.object:setpos(pos)
	elseif dir.z ~= 0 and not cart_func:is_int(pos.x) then
		pos.x = math.floor(0.5+pos.x)
		self.object:setpos(pos)
	end

	-- Limit the velocity
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

	self.old_pos = self.object:getpos()
	self.old_velocity = cart_func.v3:copy(self.velocity)

  local oldyaw=self.object:getyaw()
	if dir.x < 0 then
		self.object:setyaw(math.pi/2)
	elseif dir.x > 0 then
		self.object:setyaw(3*math.pi/2)
	elseif dir.z < 0 then
		self.object:setyaw(math.pi)
	elseif dir.z > 0 then
		self.object:setyaw(0)
	end
  
  local newyaw=self.object:getyaw()
  --now if driver and lockyaw, change drivers direction.
  if self.driver and self.lockyaw then
    if oldyaw~=newyaw then
      self.yawtarget=newyaw  --set new target
      --print("--Cart yawtarget set "..self.yawtarget)
    end      
    local playeryaw=self.driver:get_look_yaw()-1.57
    if playeryaw<0 then playeryaw=playeryaw+(math.pi*2) end
    if self.yawtarget and playeryaw ~= self.yawtarget  then
      local diff = self.yawtarget - playeryaw
      if diff>math.pi then
        diff=diff-(2*math.pi)
      elseif diff<(-math.pi) then 
        diff=diff+(2*math.pi)
      end  
      yawdir=cart_func:get_sign(diff)
      local step=self.YAW_STEP
      if math.abs(diff)<=self.YAW_STEP then
      step=diff
        self.yawtarget=nil
      end         
      local setyaw=playeryaw+(step*yawdir)
      self.driver:set_look_yaw(setyaw)
    end --move yaw
  end --lockyaw set  

	if dir.y == -1 then
		self.object:set_animation({x=1, y=1}, 1, 0)
	elseif dir.y == 1 then
		self.object:set_animation({x=2, y=2}, 1, 0)
	else
		self.object:set_animation({x=0, y=0}, 1, 0)
	end

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
			local obj=minetest.env:add_entity(pointed_thing.under, "carts:cart")
      print("cart: begin pos="..pos_to_string(vector.round(obj:getpos())))
      minetest.chat_send_player(placer:get_player_name(),"cart: right click to ride, left click to push, SNEAK-left click to put back in inventory, JUMP to lock view to cart, SNEAK to unlock view from cart, LEFT and RIGHT ARROWS to switch tracks, DOWN ARROW to apply hand break")
			if not minetest.setting_getbool("creative_mode") then
				itemstack:take_item()
			end
			return itemstack
		elseif cart_func:is_rail(pointed_thing.above) then
			minetest.env:add_entity(pointed_thing.above, "carts:cart")
      print("cart: begin pos="..pos_to_string(self.object:getpos()))
			if not minetest.setting_getbool("creative_mode") then
				itemstack:take_item()
			end
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

--
-- Mesecon support
--

minetest.register_node(":default:rail", {
	description = "Rail",
	drawtype = "raillike",
	tiles = {"default_rail.png", "default_rail_curved.png", "default_rail_t_junction.png", "default_rail_crossing.png"},
	inventory_image = "default_rail.png",
	wield_image = "default_rail.png",
	paramtype = "light",
	is_ground_content = true,
	walkable = false,
	selection_box = {
		type = "fixed",
		-- but how to specify the dimensions for curved and sideways rails?
		fixed = {-1/2, -1/2, -1/2, 1/2, -1/2+1/16, 1/2},
	},
	groups = {bendy=2,snappy=1,dig_immediate=2,attached_node=1,rail=1,connect_to_raillike=1},
})

minetest.register_node("carts:powerrail", {
	description = "Powered Rail",
	drawtype = "raillike",
	tiles = {"carts_rail_pwr.png", "carts_rail_curved_pwr.png", "carts_rail_t_junction_pwr.png", "carts_rail_crossing_pwr.png"},
	inventory_image = "carts_rail_pwr.png",
	wield_image = "carts_rail_pwr.png",
	paramtype = "light",
	is_ground_content = true,
	walkable = false,
	selection_box = {
		type = "fixed",
		-- but how to specify the dimensions for curved and sideways rails?
		fixed = {-1/2, -1/2, -1/2, 1/2, -1/2+1/16, 1/2},
	},
	groups = {bendy=2,snappy=1,dig_immediate=2,attached_node=1,rail=1,connect_to_raillike=1},

	after_place_node = function(pos, placer, itemstack)
		if not mesecon then
			minetest.env:get_meta(pos):set_string("cart_acceleration", "0.5")
		end
	end,

	mesecons = {
		effector = {
			action_on = function(pos, node)
				minetest.env:get_meta(pos):set_string("cart_acceleration", "0.5")
			end,

			action_off = function(pos, node)
				minetest.env:get_meta(pos):set_string("cart_acceleration", "0")
			end,
		},
	},
})

minetest.register_node("carts:brakerail", {
	description = "Brake Rail",
	drawtype = "raillike",
	tiles = {"carts_rail_brk.png", "carts_rail_curved_brk.png", "carts_rail_t_junction_brk.png", "carts_rail_crossing_brk.png"},
	inventory_image = "carts_rail_brk.png",
	wield_image = "carts_rail_brk.png",
	paramtype = "light",
	is_ground_content = true,
	walkable = false,
	selection_box = {
		type = "fixed",
		-- but how to specify the dimensions for curved and sideways rails?
		fixed = {-1/2, -1/2, -1/2, 1/2, -1/2+1/16, 1/2},
	},
	groups = {bendy=2,snappy=1,dig_immediate=2,attached_node=1,rail=1,connect_to_raillike=1},

	after_place_node = function(pos, placer, itemstack)
		if not mesecon then
			minetest.env:get_meta(pos):set_string("cart_acceleration", "-0.2")
		end
	end,

	mesecons = {
		effector = {
			action_on = function(pos, node)
				minetest.env:get_meta(pos):set_string("cart_acceleration", "-0.2")
			end,

			action_off = function(pos, node)
				minetest.env:get_meta(pos):set_string("cart_acceleration", "0")
			end,
		},
	},
})


minetest.register_node("carts:touringrail", {
    description = "Touring Rail",
    drawtype = "raillike",
    tiles = {"carts_rail_tour.png", "carts_rail_curved_tour.png", "carts_rail_t_junction_tour.png", "carts_rail_crossing_tour.png"},
    inventory_image = "carts_rail_tour.png",
    wield_image = "carts_rail_tour.png",
    paramtype = "light",
    is_ground_content = true,
    walkable = false,
    selection_box = {
        type = "fixed",
        -- but how to specify the dimensions for curved and sideways rails?
        fixed = {-1/2, -1/2, -1/2, 1/2, -1/2+1/16, 1/2},
    },
    groups = {bendy=2,snappy=1,dig_immediate=2,attached_node=1,rail=1,connect_to_raillike=1},

    after_place_node = function(pos, placer, itemstack)
        if not mesecon then
            minetest.env:get_meta(pos):set_string("cart_acceleration", "0.5")
            minetest.env:get_meta(pos):set_string("cart_touring_velocity", cart.TARGET_TOUR_V)
        end
    end,

    mesecons = {
        effector = {
            action_on = function(pos, node)
                minetest.env:get_meta(pos):set_string("cart_acceleration", "0.5")
            end,

            action_off = function(pos, node)
                minetest.env:get_meta(pos):set_string("cart_acceleration", "0")
            end,
        },
    },
})


minetest.register_craft({
	output = "carts:powerrail 2",
	recipe = {
		{"default:steel_ingot", "default:mese_crystal_fragment", "default:steel_ingot"},
		{"default:steel_ingot", "default:stick", "default:steel_ingot"},
		{"default:steel_ingot", "", "default:steel_ingot"},
	}
})

minetest.register_craft({
	output = "carts:powerrail 2",
	recipe = {
		{"default:steel_ingot", "", "default:steel_ingot"},
		{"default:steel_ingot", "default:stick", "default:steel_ingot"},
		{"default:steel_ingot", "default:mese_crystal_fragment", "default:steel_ingot"},
	}
})

minetest.register_craft({
	output = "carts:brakerail 2",
	recipe = {
		{"default:steel_ingot", "default:coal_lump", "default:steel_ingot"},
		{"default:steel_ingot", "default:stick", "default:steel_ingot"},
		{"default:steel_ingot", "", "default:steel_ingot"},
	}
})

minetest.register_craft({
	output = "carts:brakerail 2",
	recipe = {
		{"default:steel_ingot", "", "default:steel_ingot"},
		{"default:steel_ingot", "default:stick", "default:steel_ingot"},
		{"default:steel_ingot", "default:coal_lump", "default:steel_ingot"},
	}
})


minetest.register_craft({
	output = "carts:touringrail 7",
	recipe = {
		{"default:steel_ingot", "default:coal_lump", "default:steel_ingot"},
		{"default:steel_ingot", "default:stick", "default:steel_ingot"},
		{"default:steel_ingot", "default:mese_crystal_fragment", "default:steel_ingot"},
	}
})


minetest.register_craft({
	output = "carts:touringrail 7",
	recipe = {
		{"default:coal_lump"},
		{"carts:powerrail"},
		{"carts:powerrail"},
	}
})
