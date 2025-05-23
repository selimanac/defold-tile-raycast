local collision        = require("examples.scripts.collision")
local const            = require("examples.scripts.const")
local data             = require("examples.scripts.data")
local bullet           = require("examples.scripts.bullet")
local debug            = require("examples.scripts.debug")
local vision           = require("examples.scripts.vision")
local utils            = require("examples.scripts.utils")

-- Module
local enemies          = {}

local ray_intersection = vmath.vector3()

local function enemy_hit(enemy_id)
	local enemy = data.enemies[enemy_id]
	vision.set_state(enemy, const.VISION.STATE.ALERT)
end

local function set_vision_status_indicator(enemy)
	msg.post(enemy.status_indicator, "enable")

	if enemy.vision.state == const.VISION.STATE.IDLE then
		sprite.play_flipbook(enemy.status_indicator_sprite, const.ENEMY.VISION_STATUS.IDLE)
	elseif enemy.vision.state == const.VISION.STATE.WARNING then
		sprite.play_flipbook(enemy.status_indicator_sprite, const.ENEMY.VISION_STATUS.WARNING)
	elseif enemy.vision.state == const.VISION.STATE.ALERT then
		sprite.play_flipbook(enemy.status_indicator_sprite, const.ENEMY.VISION_STATUS.DANGER)
	end

	enemy.vision.previous_state = enemy.vision.state
end

function enemies.add(tile_position_x, tile_position_y)
	local enemy_position = vmath.vector3(tile_position_x, tile_position_y, 0.5)
	local aabb_id = collision.insert_aabb(enemy_position.x, enemy_position.y, const.TILE_SIZE, const.TILE_SIZE, const.COLLISION_BITS.ENEMY)
	local enemy_id = factory.create(const.FACTORY.ENEMY, enemy_position)

	-- Status
	local status_indicator_position = vmath.vector3(enemy_position.x, enemy_position.y + 10, 0.9)
	local status_indicator_id = factory.create(const.FACTORY.ENEMY_STATUS_INDICATOR, status_indicator_position)
	local status_indicator_sprite = msg.url(status_indicator_id)
	status_indicator_sprite.fragment = "sprite"

	local initial_facing_angle = rnd.range(0, 359) -- for vision

	local temp_enemy = {
		id                        = enemy_id,
		aabb_id                   = aabb_id,
		position                  = enemy_position,
		fire_timer                = rnd.double() * const.ENEMY.FIRE_COOLDOWN,
		hit_callback              = enemy_hit,
		status_indicator          = status_indicator_id,
		status_indicator_sprite   = status_indicator_sprite,
		status_indicator_position = status_indicator_position,
		idle_behavior             = {
			search_timer    = rnd.range(2, 5),
			search_interval = { min = 2, max = 5 },
			search_duration = { min = 0.5, max = 1.5 },
			target_angle    = initial_facing_angle,
			is_searching    = false,
			search_progress = 0,
			start_angle     = initial_facing_angle -- for interpolation
		}
	}

	vision.add_to_entity(temp_enemy, {
		fov                 = 45,
		distance            = 120,
		facing_angle        = initial_facing_angle,
		peripheral_distance = 30,
	})

	temp_enemy.vision.previous_state = temp_enemy.vision.state

	set_vision_status_indicator(temp_enemy)

	table.insert(data.enemies, temp_enemy)
	data.enemy_aabb_ids[aabb_id] = #data.enemies -- for fast lookup
end

local function update_idle_looking_behavior(enemy, dt)
	local idle = enemy.idle_behavior

	if idle.is_searching then
		idle.search_progress = idle.search_progress + dt / idle.current_search_duration

		if idle.search_progress >= 1 then
			-- Search complete
			idle.is_searching = false
			idle.search_progress = 0
			idle.search_timer = rnd.range(idle.search_interval.min, idle.search_interval.max)
			idle.start_angle = enemy.vision.facing_angle
		else
			-- Searching
			local t = idle.search_progress
			local smooth_t = t * t * (3 - 2 * t) -- Smoothstep
			local angle_diff = utils.angle_diff(idle.target_angle, idle.start_angle)
			local current_angle = idle.start_angle + angle_diff * smooth_t

			-- Update the facing direction
			vision.set_facing(enemy, current_angle)
		end
	else
		-- Waiting for next search
		idle.search_timer = idle.search_timer - dt

		if idle.search_timer <= 0 then
			-- New search
			idle.is_searching = true
			idle.search_progress = 0
			idle.start_angle = enemy.vision.facing_angle

			-- New target angle
			-- uncomment to use: Random angle within a range of current angle
			-- local angle_range = 60 -- Look up to 60 degrees left or right
			-- local angle_change = rnd.range(-angle_range, angle_range)
			-- idle.target_angle = idle.start_angle + angle_change

			-- random direction
			idle.target_angle = rnd.range(0, 359)

			-- Set duration for this look
			idle.current_search_duration = rnd.range(idle.search_duration.min * 100,
				idle.search_duration.max * 100) / 100
		end
	end
end

function enemies.vision_update(dt)
	vision.update(dt)

	for _, enemy in ipairs(data.enemies) do
		-- Indicator
		if enemy.vision.state ~= enemy.vision.previous_state then
			set_vision_status_indicator(enemy)
		end

		if enemy.vision.state == const.VISION.STATE.IDLE then
			-- TODO: Patrol behavior, walk, seek
			update_idle_looking_behavior(enemy, dt)
		elseif enemy.vision.state == const.VISION.STATE.WARNING then
			if enemy.vision.last_seen_position then
				local to_target = enemy.vision.last_seen_position - enemy.position
				local angle = utils.angle(to_target)
				vision.set_facing(enemy, angle)
			end
		elseif enemy.vision.state == const.VISION.STATE.ALERT then
			local to_player = data.player.position - enemy.position
			local angle = utils.angle(to_player)
			vision.set_facing(enemy, angle)

			if enemy.fire_timer > 0 then
				enemy.fire_timer = enemy.fire_timer - dt
			end

			local hit = tile_raycast.cast(
				enemy.position.x, enemy.position.y,
				data.player.position.x, data.player.position.y
			)

			if not hit and enemy.fire_timer <= 0 then
				bullet.add(enemy.position, data.player.position, const.COLLISION_BITS.PLAYER, const.ENEMY.BULLETS.SINGLE, enemies.hit)
				enemy.fire_timer = const.ENEMY.FIRE_COOLDOWN
			end
		end
	end
end

function enemies.update(dt)
	for _, enemy_item in ipairs(data.enemies) do
		-- Update fire timer
		if enemy_item.fire_timer > 0 then
			enemy_item.fire_timer = enemy_item.fire_timer - dt
		end

		-- Perform raycast to check if player is visible
		local hit, _, _, _, _, intersection_x, intersection_y, _ =
			tile_raycast.cast(enemy_item.position.x, enemy_item.position.y, data.player.position.x, data.player.position.y)

		if hit then
			-- Player not visible
			ray_intersection.x = intersection_x
			ray_intersection.y = intersection_y

			debug.draw_line(ray_intersection, data.player.position, debug.COLOR.RED)
			debug.draw_line(enemy_item.position, ray_intersection, debug.COLOR.GREEN)
		else
			-- Player visible
			if enemy_item.fire_timer <= 0 then
				-- Fire bullet and reset timer
				bullet.add(enemy_item.position, data.player.position, const.COLLISION_BITS.PLAYER, const.ENEMY.BULLETS.SINGLE)
				enemy_item.fire_timer = const.ENEMY.FIRE_COOLDOWN
			end

			debug.draw_line(enemy_item.position, data.player.position, debug.COLOR.GREEN)
		end
	end
end

return enemies
