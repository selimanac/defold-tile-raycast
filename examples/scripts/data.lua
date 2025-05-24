local data = {}

data.debug = true

data.player = {
	position = vmath.vector3(0.5),
	id = "",
	aabb_id = 0,
	hit_callback = 0,
	speed = 0,
	velocity = vmath.vector3(),
	input = vmath.vector3(),
	direction = vmath.vector3()
}

data.enemies = {}
data.enemy_aabb_ids = {}

data.mouse_position = vmath.vector3(0.9)

data.enemies = {}
data.enemy_aabb_ids = {}


function data.reset()
	data.enemies = {}
	data.enemy_aabb_ids = {}
	data.enemies = {}
	data.enemy_aabb_ids = {}
end

return data
