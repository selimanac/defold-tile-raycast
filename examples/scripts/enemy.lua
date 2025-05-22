local collision = require("examples.scripts.collision")
local const = require("examples.scripts.const")
local data = require("examples.scripts.data")
local bullet = require("examples.scripts.bullet")
local debug = require("examples.scripts.debug")
local vision = require("examples.scripts.vision")

local enemies = {}
local ray_intersection = vmath.vector3()

local function enemy_hit(enemy_id)
	local enemy = data.enemies[enemy_id]
	vision.set_state(enemy, const.VISION.STATE.ALERT)
end

local function set_vision_status_indicator(enemy)
	-- Enable the indicator if it was disabled
	msg.post(enemy.status_indicator, "enable")

	-- Set the appropriate animation based on state
	if enemy.vision.state == const.VISION.STATE.IDLE then
		sprite.play_flipbook(enemy.status_indicator_sprite, const.ENEMY.VISION_STATUS.IDLE)
	elseif enemy.vision.state == const.VISION.STATE.WARNING then
		sprite.play_flipbook(enemy.status_indicator_sprite, const.ENEMY.VISION_STATUS.WARNING)
	elseif enemy.vision.state == const.VISION.STATE.ALERT then
		sprite.play_flipbook(enemy.status_indicator_sprite, const.ENEMY.VISION_STATUS.DANGER)
	end

	-- Store current state as previous state
	enemy.vision.previous_state = enemy.vision.state
end

function enemies.add(tile_position_x, tile_position_y)
	local aabb_id = collision.insert_aabb(tile_position_x, tile_position_y, const.TILE_SIZE, const.TILE_SIZE, const.COLLISION_BITS.ENEMY)

	local enemy_position = vmath.vector3(tile_position_x, tile_position_y, 0.5)
	local enemy_id = factory.create("/factories#enemy", enemy_position)

	local status_indicator_position = vmath.vector3(enemy_position.x, enemy_position.y + 10, 0.9)
	local status_indicator_id = factory.create("/factories#status_indicator", status_indicator_position)

	local status_indicator_sprite = msg.url(status_indicator_id)
	status_indicator_sprite.fragment = "sprite"

	local temp_enemy = {
		id = enemy_id,
		aabb_id = aabb_id,
		position = enemy_position,
		fire_timer = rnd.double() * const.ENEMY.FIRE_COOLDOWN,
		hit_callback = enemy_hit,
		status_indicator = status_indicator_id,
		status_indicator_sprite = status_indicator_sprite,
		status_indicator_position = status_indicator_position
	}


	vision.add_to_entity(temp_enemy, {
		fov = 45,
		distance = 120,
		facing_angle = rnd.range(90, 359), --  facing
		peripheral_distance = 30,

	})

	temp_enemy.vision.previous_state = temp_enemy.vision.state

	set_vision_status_indicator(temp_enemy)

	temp_enemy.idle_behavior = {
		look_timer = rnd.range(2, 5),            -- Random initial timer (seconds)
		look_interval = { min = 2, max = 5 },    -- Range for time between look actions
		look_duration = { min = 0.5, max = 1.5 }, -- How long a look motion takes
		target_angle = temp_enemy.vision.facing_angle, -- Initial target angle
		is_looking = false,                      -- Whether currently performing a look
		look_progress = 0,                       -- Progress of current look (0-1)
		start_angle = temp_enemy.vision.facing_angle -- Starting angle for interpolation
	}

	--msg.post(status_indicator_id, "disable")

	table.insert(data.enemies, temp_enemy)
	data.enemy_aabb_ids[aabb_id] = #data.enemies
end

local function update_idle_looking_behavior(enemy, dt)
	local idle = enemy.idle_behavior

	if idle.is_looking then
		-- Currently performing a look action
		idle.look_progress = idle.look_progress + dt / idle.current_look_duration

		if idle.look_progress >= 1 then
			-- Look action completed
			idle.is_looking = false
			idle.look_progress = 0
			idle.look_timer = rnd.range(idle.look_interval.min, idle.look_interval.max)

			-- Update start angle for next look
			idle.start_angle = enemy.vision.facing_angle
		else
			-- Interpolate between start and target angles
			-- Using smooth step interpolation for natural movement
			local t = idle.look_progress
			local smooth_t = t * t * (3 - 2 * t) -- Smoothstep function

			-- Calculate angle interpolation (handling angle wrapping)
			local angle_diff = (idle.target_angle - idle.start_angle + 180) % 360 - 180
			local current_angle = idle.start_angle + angle_diff * smooth_t

			-- Update the facing direction
			vision.set_facing(enemy, current_angle)
		end
	else
		-- Waiting for next look action
		idle.look_timer = idle.look_timer - dt

		if idle.look_timer <= 0 then
			-- Start a new look action
			idle.is_looking = true
			idle.look_progress = 0
			idle.start_angle = enemy.vision.facing_angle

			-- Determine new target angle
			-- Option 1: Random angle within a range of current angle
			local angle_range = 60 -- Look up to 60 degrees left or right
			local angle_change = rnd.range(-angle_range, angle_range)
			idle.target_angle = idle.start_angle + angle_change

			-- Option 2 (uncomment to use): Completely random direction
			-- idle.target_angle = math.random(0, 359)

			-- Set duration for this look
			idle.current_look_duration = rnd.range(idle.look_duration.min * 100,
				idle.look_duration.max * 100) / 100
		end
	end
end

function enemies.vision_update(dt)
	vision.update(dt)

	for i, enemy in ipairs(data.enemies) do
		-- Use vision state to determine behavior

		if enemy.vision.state ~= enemy.vision.previous_state then
			set_vision_status_indicator(enemy)
		end


		if enemy.vision.state == const.VISION.STATE.IDLE then
			-- Patrol behavior
			update_idle_looking_behavior(enemy, dt)
		elseif enemy.vision.state == const.VISION.STATE.WARNING then
			if enemy.vision.last_seen_position then
				local to_target = enemy.vision.last_seen_position - enemy.position
				local angle = math.deg(math.atan2(to_target.y, to_target.x))
				vision.set_facing(enemy, angle)
			end
		elseif enemy.vision.state == const.VISION.STATE.ALERT then
			local to_player = data.player.position - enemy.position
			local angle = math.deg(math.atan2(to_player.y, to_player.x))
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
function enemies.set_fire_rate(seconds_between_shots)
	const.ENEMY.FIRE_COOLDOWN = seconds_between_shots
end

return enemies
