local collision = require("examples.lib.collision")
local const = require("examples.lib.const")
local data = require("examples.lib.data")

local enemy = {}
local ray_intersection = vmath.vector3()
function enemy.add(tile_position_x, tile_position_y)
	local aabb_id = collision.insert_aabb(tile_position_x, tile_position_y, const.TILE_SIZE, const.TILE_SIZE, const.COLLISION_BITS.ENEMY)

	local enemy_position = vmath.vector3(tile_position_x, tile_position_y, 0.5)
	local enemy_id = factory.create("/factories#enemy", enemy_position)

	local temp_enemy = {
		id = enemy_id,
		aabb_id = aabb_id,
		position = enemy_position
	}

	table.insert(data.enemies, temp_enemy)
end

function enemy.update(dt)
	for i, enemy in ipairs(data.enemies) do
		local hit, tile_x, tile_y, array_id, tile_id, intersection_x, intersection_y, side = tile_raycast.cast(enemy.position.x, enemy.position.y, data.player.position.x, data.player.position.y)


		if hit then
			ray_intersection.x = intersection_x
			ray_intersection.y = intersection_y

			msg.post("@render:", "draw_line", { start_point = ray_intersection, end_point = data.player.position, color = vmath.vector4(1, 0, 0, 1) })


			msg.post("@render:", "draw_line", { start_point = enemy.position, end_point = ray_intersection, color = vmath.vector4(0, 1, 0, 1) })
		else
			msg.post("@render:", "draw_line", { start_point = enemy.position, end_point = data.player.position, color = vmath.vector4(0, 1, 0, 1) })
		end
	end
end

return enemy
