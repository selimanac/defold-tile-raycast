local data = require("examples.lib.data")
local const = require("examples.lib.const")
local collision = require("examples.lib.collision")

local bullet = {}

-- Configuration
local BULLET_SPEED = 60
local BULLET_LIFETIME = 5
local BULLET_SIZE = 4

local TRAIL_SEGMENTS = 5    -- Number of trail segments per bullet
local TRAIL_SPACING = 0.03  -- Time between trail segments (seconds)
local TRAIL_FADE_TIME = 0.4 -- Animation duration for fading

local bullets = {}
local to_remove = {}

-- Create all trail segments for a new bullet
local function create_trail_segments(position)
	local trail_segments = {}

	for i = 1, TRAIL_SEGMENTS do
		local trail_id = factory.create("/factories#bullet", position)

		go.set_position(position, trail_id)
		go.set_scale(0.8, trail_id)

		local trail_sprite = msg.url(trail_id)
		trail_sprite.fragment = "sprite"
		go.set(trail_sprite, "tint", vmath.vector4(1, 1, 1, 0))

		-- Store trail segment info
		table.insert(trail_segments, {
			id = trail_id,
			sprite_url = trail_sprite,
			active = false,
			position = vmath.vector3(position)
		})
	end

	return trail_segments
end


local function activate_trail_segment(bullet)
	local segment = bullet.trail_segments[bullet.trail_index]
	segment.active = true
	segment.position = vmath.vector3(bullet.position)

	go.set_position(segment.position, segment.id)

	--  fade-out
	go.set(segment.sprite_url, "tint", vmath.vector4(1, 1, 1, 0.8))
	go.animate(segment.sprite_url, "tint.w", go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_LINEAR, TRAIL_FADE_TIME)

	-- scale
	go.set_scale(0.8, segment.id)
	go.animate(segment.id, "scale", go.PLAYBACK_ONCE_FORWARD, 0.3, go.EASING_LINEAR, TRAIL_FADE_TIME)

	--next trail segment
	bullet.trail_index = bullet.trail_index % TRAIL_SEGMENTS + 1
end


local function update_trail(bullet, dt)
	bullet.trail_timer = bullet.trail_timer + dt
	if bullet.trail_timer >= TRAIL_SPACING then
		bullet.trail_timer = 0
		activate_trail_segment(bullet)
	end
end


local function delete_trail_segments(bullet)
	for _, segment in ipairs(bullet.trail_segments) do
		go.delete(segment.id)
	end
end

function bullet.add(start_pos, aim_pos, collision_bit)
	local bullet_direction = vmath.normalize(aim_pos - start_pos)
	bullet_direction.z = 0
	local bullet_position = vmath.vector3(start_pos.x, start_pos.y, 0.6)
	local bullet_id = factory.create("/factories#bullet", bullet_position)

	-- Add collision for bullet
	local aabb_id = collision.insert_gameobject(msg.url(bullet_id), BULLET_SIZE, BULLET_SIZE, const.COLLISION_BITS.BULLET)

	-- Store bullet data
	table.insert(bullets, {
		id = bullet_id,
		aabb_id = aabb_id,
		position = bullet_position,
		direction = bullet_direction,
		lifetime = BULLET_LIFETIME,
		hit = false,
		collision_bit = collision_bit,
		trail_timer = 0,
		trail_segments = create_trail_segments(bullet_position),
		trail_index = 1
	})
end

local function bullet_impact(pos_x, pos_y)
	local impact_id = factory.create("/factories#bullet_impact", vmath.vector3(pos_x, pos_y, 0.7))

	local impact_sprite = msg.url(impact_id)
	impact_sprite.fragment = "sprite"
	sprite.play_flipbook(impact_sprite, hash("bullet_impact"), function(self, message_id, message, sender)
		if message_id == hash("animation_done") then
			go.delete(impact_sprite)
		end
	end)
end

function bullet.update(dt)
	to_remove = {}

	for i, b in ipairs(bullets) do
		if not b.hit then
			-- Update lifetime
			b.lifetime = b.lifetime - dt

			-- Update trail system
			update_trail(b, dt)

			-- Calculate new position
			local new_pos = b.position + b.direction * BULLET_SPEED * dt

			-- Use raycast for wall detection
			local hit, hit_tile_x, hit_tile_y, array_id, tile_id, hit_x, hit_y, side =
				tile_raycast.cast(b.position.x, b.position.y, new_pos.x, new_pos.y)

			if hit then
				-- Bullet hit wall

				b.position.x = hit_x
				b.position.y = hit_y
				b.hit = true
				--impact
				--local impact_id = factory.create("/factories#bullet_impact", vmath.vector3(hit_x, hit_y, 0.7))
				bullet_impact(hit_x, hit_y)
			else
				-- Update position
				b.position = new_pos

				-- Check collisions
				--		collision.update_aabb(b.aabb_id, b.position.x, b.position.y, BULLET_SIZE, BULLET_SIZE)

				local results, count = collision.query_id(b.aabb_id, b.collision_bit, true)
				if results then
					for j = 1, count do
						--	factory.create("/factories#bullet_impact", vmath.vector3(results[j].contact_point_x, results[j].contact_point_y, 0.7))

						bullet_impact(results[j].contact_point_x, results[j].contact_point_y)
						b.hit = true
						break
					end
				end
			end

			-- Update bullet visual position
			go.set_position(b.position, b.id)
		end

		-- Mark for removal if needed
		if b.hit or b.lifetime <= 0 then
			if not b.hit then
				--factory.create("/factories#bullet_impact", vmath.vector3(b.position.x, b.position.y, 0.7))

				bullet_impact(b.position.x, b.position.y)
				b.hit = true
			end
			table.insert(to_remove, i)
		end
	end

	-- Remove bullets
	for i = #to_remove, 1, -1 do
		local idx = to_remove[i]
		local b = bullets[idx]

		-- Clean up
		delete_trail_segments(b)
		collision.remove(b.aabb_id)
		go.delete(b.id)
		table.remove(bullets, idx)
	end
end

function bullet.clear()
	for i, b in ipairs(bullets) do
		collision.remove(b.aabb_id)
		go.delete(b.id)
		delete_trail_segments(b)
	end
	bullets = {}
end

return bullet
