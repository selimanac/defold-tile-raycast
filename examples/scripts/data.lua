local data = {}

data.debug = true

data.player = {
	position = vmath.vector3(0.5),
	id = "",
	aabb_id = 0,
	hit_callback = 0
}

data.enemies = {}
data.enemy_aabb_ids = {}

data.mouse_position = vmath.vector3(0.9)

data.bullets = {}

return data
