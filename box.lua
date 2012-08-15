minetest.register_node("carts:cart_box", {
	tiles = {"carts_cart_top.png", "carts_cart_bottom.png", "carts_cart_side.png", "carts_cart_side.png", "carts_cart_side.png", "carts_cart_side.png"},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.45, -0.5, 0.5, 0.5, -0.5+1/16},
			{-0.5, -0.45, -0.5, -0.5+1/16, 0.5, 0.5},
			{0.5, -0.5, 0.5, -0.5, 0.5, 0.5-1/16},
			{0.5, -0.5, 0.5, 0.5-1/16, 0.5, -0.5},
			
			{-0.5, -0.5, -0.5, 0.5, -0.3, 0.5},
		},
	},
	groups = {oddly_breakable_by_hand=3, not_in_creative_inventory=1},
})