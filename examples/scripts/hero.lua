local data = require("examples.scripts.data")
local const = require("examples.scripts.const")
local collision = require("examples.scripts.collision")
local bullet = require("examples.scripts.bullet")
local debug = require("examples.scripts.debug")

-- Module
local hero = {}

local function hero_hit(enemy_id)
	-- TODO: Take hit
end

function hero.add(tile_position_x, tile_position_y)
	data.player.position.x   = tile_position_x
	data.player.position.y   = tile_position_y
	data.player.id           = factory.create(const.FACTORY.HERO, vmath.vector3(tile_position_x, tile_position_y, 0.5))
	data.player.aabb_id      = collision.insert_gameobject(msg.url(data.player.id), const.TILE_SIZE, const.TILE_SIZE, const.COLLISION_BITS.PLAYER)
	data.player.hit_callback = hero_hit
end

function hero.update(dt)
	if data.player.input.x ~= 0 or data.player.input.y ~= 0 then
		data.player.direction = vmath.normalize(data.player.input)
		data.player.velocity  = data.player.velocity + data.player.direction * const.HERO.ACCELERATION * dt
		data.player.speed     = vmath.length(data.player.velocity)

		if data.player.speed > const.HERO.MAX_SPEED then
			data.player.velocity = data.player.velocity * (const.HERO.MAX_SPEED / data.player.speed)
		end
	else
		data.player.velocity = data.player.velocity * const.HERO.FRICTION

		if vmath.length(data.player.velocity) < 0.1 then
			data.player.velocity.x = 0
			data.player.velocity.y = 0
		end
	end

	data.player.position = data.player.position + data.player.velocity * dt

	collision.update_aabb(data.player.aabb_id, data.player.position.x, data.player.position.y, const.TILE_SIZE, const.TILE_SIZE)

	-- Check wall and prop collision
	local result, count = collision.query_id(data.player.aabb_id, const.COLLISION_BITS.WALL, true)
	if result then
		for i = 1, count do
			local player_offset_x = result[i].normal_x * result[i].depth
			local player_offset_y = result[i].normal_y * result[i].depth

			data.player.position.x = data.player.position.x + player_offset_x
			data.player.position.y = data.player.position.y + player_offset_y

			if result[i].normal_x ~= 0 then
				data.player.velocity.x = 0
			elseif result[i].normal_y ~= 0 then
				data.player.velocity.y = 0
			end
		end
	end

	data.player.input.x = 0
	data.player.input.y = 0

	go.set_position(data.player.position, data.player.id)

	--[[	
	-- Just for debug: ray wall hit
	local ray_intersection = vmath.vector3()
	local hit, _, _, _, _, intersection_x, intersection_y, _ = tile_raycast.cast(data.player.position.x, data.player.position.y, data.mouse_position.x, data.mouse_position.y)

	if hit then
		ray_intersection.x = intersection_x
		ray_intersection.y = intersection_y

		debug.draw_line(ray_intersection, data.mouse_position, debug.COLOR.RED)

		debug.draw_line(data.player.position, ray_intersection, debug.COLOR.GREEN)
	else
		debug.draw_line(data.player.position, data.mouse_position, debug.COLOR.GREEN)
	end
	]]
end

function hero.input(action_id, action)
	if action_id == const.TRIGGER.UP then
		data.player.input.y = 1
	elseif action_id == const.TRIGGER.DOWN then
		data.player.input.y = -1
	elseif action_id == const.TRIGGER.LEFT then
		data.player.input.x = -1
	elseif action_id == const.TRIGGER.RIGHT then
		data.player.input.x = 1
	elseif action_id == const.TRIGGER.TOUCH and action.repeated then
		bullet.add(data.player.position, data.mouse_position, const.COLLISION_BITS.ENEMY, const.HERO.BULLETS.SINGLE, hero.hit)
	end
end

return hero
