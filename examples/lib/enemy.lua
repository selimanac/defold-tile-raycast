local collision = require("examples.lib.collision")
local const = require("examples.lib.const")
local data = require("examples.lib.data")
local bullet = require("examples.lib.bullet")
local debug = require("examples.lib.debug")


local enemy = {}
local ray_intersection = vmath.vector3()

local ENEMY_FIRE_COOLDOWN = 2.0 -- Seconds between shots

function enemy.add(tile_position_x, tile_position_y)
	local aabb_id = collision.insert_aabb(tile_position_x, tile_position_y, const.TILE_SIZE, const.TILE_SIZE, const.COLLISION_BITS.ENEMY)

	local enemy_position = vmath.vector3(tile_position_x, tile_position_y, 0.5)
	local enemy_id = factory.create("/factories#enemy", enemy_position)

	local temp_enemy = {
		id = enemy_id,
		aabb_id = aabb_id,
		position = enemy_position,
		fire_timer = rnd.double() * ENEMY_FIRE_COOLDOWN -- Random initial timer to prevent all enemies firing at once
	}

	table.insert(data.enemies, temp_enemy)
end

function enemy.update(dt)
	for i, enemy_item in ipairs(data.enemies) do
		-- Update fire timer
		if enemy_item.fire_timer > 0 then
			enemy_item.fire_timer = enemy_item.fire_timer - dt
		end

		-- Perform raycast to check if player is visible
		local hit, _, _, _, _, intersection_x, intersection_y, _ =
			tile_raycast.cast(enemy_item.position.x, enemy_item.position.y, data.player.position.x, data.player.position.y)

		if hit then
			-- Player not visible - draw debug line showing obstruction
			ray_intersection.x = intersection_x
			ray_intersection.y = intersection_y


			debug.draw_line(ray_intersection, data.player.position, debug.COLOR.RED)
			debug.draw_line(enemy_item.position, ray_intersection, debug.COLOR.GREEN)
		else
			-- Player visible - check if can fire
			if enemy_item.fire_timer <= 0 then
				-- Fire bullet and reset timer
				bullet.add(enemy_item.position, data.player.position, const.COLLISION_BITS.PLAYER, const.ENEMY.BULLETS.SINGLE)
				enemy_item.fire_timer = ENEMY_FIRE_COOLDOWN
			end

			debug.draw_line(enemy_item.position, data.player.position, debug.COLOR.GREEN)
		end
	end
end

-- Add a method to adjust fire rate globally if needed
function enemy.set_fire_rate(seconds_between_shots)
	ENEMY_FIRE_COOLDOWN = seconds_between_shots
end

return enemy
