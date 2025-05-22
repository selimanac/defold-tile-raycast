local collision = require("examples.scripts.collision")
local const = require("examples.scripts.const")
local data = require("examples.scripts.data")
local bullet = require("examples.scripts.bullet")
local debug = require("examples.scripts.debug")
local vision = require("examples.scripts.vision")

local enemy = {}
local ray_intersection = vmath.vector3()

local function enemy_hit(enemy_id)
	print("enemy_hit HIT ID", enemy_id)
	local enemy = data.enemies[enemy_id]
	vision.set_state(enemy, const.VISION.STATE.ALERT)
end

function enemy.add(tile_position_x, tile_position_y)
	local aabb_id = collision.insert_aabb(tile_position_x, tile_position_y, const.TILE_SIZE, const.TILE_SIZE, const.COLLISION_BITS.ENEMY)

	local enemy_position = vmath.vector3(tile_position_x, tile_position_y, 0.5)
	local enemy_id = factory.create("/factories#enemy", enemy_position)

	local temp_enemy = {
		id = enemy_id,
		aabb_id = aabb_id,
		position = enemy_position,
		fire_timer = rnd.double() * const.ENEMY.FIRE_COOLDOWN,
		hit_callback = enemy_hit
	}

	vision.add_to_entity(temp_enemy, {
		fov = 45,
		distance = 120,
		facing_angle = rnd.range(0, 359), --  facing
		peripheral_distance = 20
	})

	table.insert(data.enemies, temp_enemy)
	data.enemy_aabb_ids[aabb_id] = #data.enemies
end

function enemy.vision_update(dt)
	vision.update(dt)

	for i, enemy_item in ipairs(data.enemies) do
		-- Use vision state to determine behavior
		if enemy_item.vision.state == const.VISION.STATE.IDLE then
			-- Patrol behavior
			-- TODO: Add patrol logic
		elseif enemy_item.vision.state == const.VISION.STATE.WARNING then
			if enemy_item.vision.last_seen_position then
				local to_target = enemy_item.vision.last_seen_position - enemy_item.position
				local angle = math.deg(math.atan2(to_target.y, to_target.x))
				vision.set_facing(enemy_item, angle)
			end
		elseif enemy_item.vision.state == const.VISION.STATE.ALERT then
			local to_player = data.player.position - enemy_item.position
			local angle = math.deg(math.atan2(to_player.y, to_player.x))
			vision.set_facing(enemy_item, angle)

			if enemy_item.fire_timer > 0 then
				enemy_item.fire_timer = enemy_item.fire_timer - dt
			end

			local hit = tile_raycast.cast(
				enemy_item.position.x, enemy_item.position.y,
				data.player.position.x, data.player.position.y
			)

			if not hit and enemy_item.fire_timer <= 0 then
				bullet.add(enemy_item.position, data.player.position, const.COLLISION_BITS.PLAYER, const.ENEMY.BULLETS.SINGLE, enemy.hit)
				enemy_item.fire_timer = const.ENEMY.FIRE_COOLDOWN
			end
		end
	end
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
				enemy_item.fire_timer = const.ENEMY.FIRE_COOLDOWN
			end

			debug.draw_line(enemy_item.position, data.player.position, debug.COLOR.GREEN)
		end
	end
end

-- Add a method to adjust fire rate globally if needed
function enemy.set_fire_rate(seconds_between_shots)
	const.ENEMY.FIRE_COOLDOWN = seconds_between_shots
end

return enemy
