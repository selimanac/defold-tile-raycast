local data = require("examples.scripts.data")
local const = require("examples.scripts.const")
local collision = require("examples.scripts.collision")

local bullets = {}

local BULLET_SPEED = 60
local BULLET_LIFETIME = 5
local BULLET_SIZE = 4

local TRAIL_SEGMENTS = 5
local TRAIL_SPACING = 0.03
local TRAIL_FADE_TIME = 0.4

local bullet_list = {}
local to_remove = {}

local function create_trail_segments(position, bullet_type)
	local trail_segments = {}

	for i = 1, TRAIL_SEGMENTS do
		local trail_id = factory.create("/factories#bullet", position)

		go.set_position(position, trail_id)
		go.set_scale(0.8, trail_id)

		local trail_sprite = msg.url(trail_id)
		trail_sprite.fragment = "sprite"
		sprite.play_flipbook(trail_sprite, bullet_type)
		go.set(trail_sprite, "tint", vmath.vector4(1, 1, 1, 0))

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

local function bullet_impact(pos_x, pos_y, impact_type)
	local impact_id = factory.create("/factories#bullet_impact", vmath.vector3(pos_x, pos_y, 0.7))

	local impact_sprite = msg.url(impact_id)
	impact_sprite.fragment = "sprite"
	sprite.play_flipbook(impact_sprite, impact_type, function(self, message_id, message, sender)
		if message_id == hash("animation_done") then
			go.delete(impact_sprite)
		end
	end)
end

function bullets.add(start_pos, aim_pos, collision_bit, bullet_type, hit_callback)
	local bullet_direction = vmath.normalize(aim_pos - start_pos)
	bullet_direction.z = 0

	local bullet_position = vmath.vector3(start_pos.x, start_pos.y, 0.6)
	local bullet_id = factory.create("/factories#bullet", bullet_position)

	local bullet_sprite = msg.url(bullet_id)
	bullet_sprite.fragment = "sprite"
	sprite.play_flipbook(bullet_sprite, bullet_type.PROJECTILE)

	-- Add collision for bullet
	local aabb_id = collision.insert_gameobject(msg.url(bullet_id), BULLET_SIZE, BULLET_SIZE, const.COLLISION_BITS.BULLET)

	pprint(hit_callback)
	-- Store bullet data
	table.insert(bullet_list, {
		id = bullet_id,
		aabb_id = aabb_id,
		position = bullet_position,
		direction = bullet_direction,
		lifetime = BULLET_LIFETIME,
		hit = false,
		collision_bit = collision_bit,
		trail_timer = 0,
		trail_segments = create_trail_segments(bullet_position, bullet_type.PROJECTILE),
		trail_index = 1,
		type = bullet_type,
		hit_callback = hit_callback
	})
end

function bullets.update(dt)
	to_remove = {}

	for i, bullet in ipairs(bullet_list) do
		if not bullet.hit then
			bullet.lifetime = bullet.lifetime - dt

			update_trail(bullet, dt)

			local new_pos = bullet.position + bullet.direction * BULLET_SPEED * dt

			-- Use raycast for wall detection
			local hit, _, _, _, _, hit_x, hit_y, side =
				tile_raycast.cast(bullet.position.x, bullet.position.y, new_pos.x, new_pos.y)

			if hit then
				-- Bullet hit wall

				bullet.position.x = hit_x
				bullet.position.y = hit_y
				bullet.hit = true

				bullet_impact(hit_x, hit_y, bullet.type.IMPACT)
			else
				-- Update position
				bullet.position = new_pos

				-- Check collisions
				--		collision.update_aabb(b.aabb_id, b.position.x, b.position.y, BULLET_SIZE, BULLET_SIZE)

				local results, count = collision.query_id(bullet.aabb_id, bullet.collision_bit, true)
				if results then
					for j = 1, count do
						local enemy_id = data.enemy_aabb_ids[results[j].id]
						if enemy_id then
							data.enemies[enemy_id].hit_callback(enemy_id)
						end

						if data.player.aabb_id == results[j].id then
							data.player.hit_callback(r)
						end

						bullet_impact(results[j].contact_point_x, results[j].contact_point_y, bullet.type.IMPACT)
						bullet.hit = true
						break
					end
				end
			end

			-- Update bullet visual position
			go.set_position(bullet.position, bullet.id)
		end

		-- Mark for removal
		if bullet.hit or bullet.lifetime <= 0 then
			if not bullet.hit then
				bullet_impact(bullet.position.x, bullet.position.y, bullet.type.IMPACT)
				bullet.hit = true
			end
			table.insert(to_remove, i)
		end
	end

	-- Remove bullets
	for i, v in ipairs(to_remove) do
		local bullet = bullet_list[v]

		-- Clean up
		delete_trail_segments(bullet)
		collision.remove(bullet.aabb_id)
		go.delete(bullet.id)
		table.remove(bullet_list, v)
		to_remove[i] = nil
	end
end

--[[function bullets.clear()
	for _, bullet in ipairs(bullet_list) do
		collision.remove(bullet.aabb_id)
		go.delete(bullet.id)
		delete_trail_segments(bullet)
	end
	bullet_list = {}
end]]

return bullets
