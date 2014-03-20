function cart_func:get_content_voxel(pos)
	local t1 = os.clock()
	local vm = minetest.get_voxel_manip()
	local pos1, pos2 = vm:read_from_map(vector.add(pos, {x=-1,y=-1,z=-1}),vector.add(pos, {x=1,y=1,z=1}))
	local a = VoxelArea:new{
		MinEdge=pos1,
		MaxEdge=pos2,
	}
	 
	local data = vm:get_data()
	local vi = a:indexp(pos)
	local railid = data[vi]
	local real_name = minetest.get_name_from_content_id(railid)
	print(string.format("voxel-ing rail: elapsed time: %.2fms", (os.clock() - t1) * 1000))
	return real_name
end
