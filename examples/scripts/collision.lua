local collision = {}

local aabb_group_id = 0

function collision.init()
	aabb_group_id = daabbcc.new_group(daabbcc.UPDATE_PARTIALREBUILD)
end

function collision.insert_aabb(x, y, width, height, collision_bit)
	collision_bit = collision_bit and collision_bit or nil
	return daabbcc.insert_aabb(aabb_group_id, x, y, width, height, collision_bit)
end

function collision.insert_gameobject(go_url, width, height, collision_bit, get_world_position)
	get_world_position = get_world_position and true or false
	collision_bit = collision_bit and collision_bit or nil
	return daabbcc.insert_gameobject(aabb_group_id, go_url, width, height, collision_bit, get_world_position)
end

function collision.query_id(aabb_id, mask_bits, get_manifold)
	mask_bits    = mask_bits and mask_bits or nil
	get_manifold = get_manifold and get_manifold or nil
	return daabbcc.query_id(aabb_group_id, aabb_id, mask_bits, get_manifold)
end

function collision.update_aabb(aabb_id, x, y, width, height)
	daabbcc.update_aabb(aabb_group_id, aabb_id, x, y, width, height)
end

function collision.remove(aabb_id)
	daabbcc.remove(aabb_group_id, aabb_id)
end

function collision.query_aabb(x, y, width, height, mask_bits, get_manifold)
	mask_bits    = mask_bits and mask_bits or nil
	get_manifold = get_manifold and get_manifold or nil
	return daabbcc.query_aabb(aabb_group_id, x, y, width, height, mask_bits, get_manifold)
end

function collision.raycast(ray_start_x, ray_start_y, ray_end_x, ray_end_y, mask_bits, get_manifold)
	mask_bits    = mask_bits and mask_bits or nil
	get_manifold = get_manifold and get_manifold or nil
	return daabbcc.raycast(aabb_group_id, ray_start_x, ray_start_y, ray_end_x, ray_end_y, mask_bits, get_manifold)
end

function collision.raycast_sort(ray_start_x, ray_start_y, ray_end_x, ray_end_y, mask_bits, get_manifold)
	mask_bits    = mask_bits and mask_bits or nil
	get_manifold = get_manifold and get_manifold or nil
	return daabbcc.raycast_sort(aabb_group_id, ray_start_x, ray_start_y, ray_end_x, ray_end_y, mask_bits, get_manifold)
end

function collision.reset()
	daabbcc.reset()
end

function collision.run(state)
	daabbcc.run(state)
end

function collision.final()
	daabbcc.reset()
end

return collision
