local data = require("examples.scripts.data")
local const = require("examples.scripts.const")
local collision = require("examples.scripts.collision")
local bullet = require("examples.scripts.bullet")
local debug = require("examples.scripts.debug")

local hero = {}

local velocity = vmath.vector3()
local input = vmath.vector3()
local direction = vmath.vector3()
local acceleration = 120
local max_speed = 50
local friction = 0.5 -- Added friction for smoother movement
local ray_intersection = vmath.vector3()


local function hero_hit(enemy_id)
	print("hero_hit HIT ID", enemy_id)
end

function hero.add(tile_position_x, tile_position_y)
	data.player.position.x = tile_position_x
	data.player.position.y = tile_position_y

	data.player.id = factory.create("/factories#hero", vmath.vector3(tile_position_x, tile_position_y, 0.5))
	data.player.aabb_id = collision.insert_gameobject(msg.url(data.player.id), const.TILE_SIZE, const.TILE_SIZE, const.COLLISION_BITS.PLAYER)

	data.player.hit_callback = hero_hit
end

function hero.update(dt)
	if input.x ~= 0 or input.y ~= 0 then
		direction = vmath.normalize(input)

		velocity = velocity + direction * acceleration * dt

		local speed = vmath.length(velocity)
		if speed > max_speed then
			velocity = velocity * (max_speed / speed)
		end
	else
		velocity = velocity * friction
		if vmath.length(velocity) < 0.1 then
			velocity = vmath.vector3()
		end
	end

	data.player.position = data.player.position + velocity * dt

	collision.update_aabb(data.player.aabb_id, data.player.position.x, data.player.position.y, const.TILE_SIZE, const.TILE_SIZE)

	local result, count = collision.query_id(data.player.aabb_id, const.COLLISION_BITS.WALL, true)
	if result then
		for i = 1, count do
			local player_offset_x = result[i].normal_x * result[i].depth
			local player_offset_y = result[i].normal_y * result[i].depth

			data.player.position.x = data.player.position.x + player_offset_x
			data.player.position.y = data.player.position.y + player_offset_y
			if result[i].normal_x ~= 0 then
				velocity.x = 0
			end

			if result[i].normal_y ~= 0 then
				velocity.y = 0
			end
		end
	end

	input = vmath.vector3()
	go.set_position(data.player.position, data.player.id)

	local hit, tile_x, tile_y, array_id, tile_id, intersection_x, intersection_y, side = tile_raycast.cast(data.player.position.x, data.player.position.y, data.mouse_position.x, data.mouse_position.y)


	if hit then
		ray_intersection.x = intersection_x
		ray_intersection.y = intersection_y

		debug.draw_line(ray_intersection, data.mouse_position, debug.COLOR.RED)

		debug.draw_line(data.player.position, ray_intersection, debug.COLOR.GREEN)
	else
		debug.draw_line(data.player.position, data.mouse_position, debug.COLOR.GREEN)
	end
end

function hero.input(action_id, action)
	-- Accumulate input instead of overriding
	if action_id == const.TRIGGER.UP then
		input.y = 1
	elseif action_id == const.TRIGGER.DOWN then
		input.y = -1
	elseif action_id == const.TRIGGER.LEFT then
		input.x = -1
	elseif action_id == const.TRIGGER.RIGHT then
		input.x = 1
	elseif action_id == const.TRIGGER.TOUCH and action.repeated then
		bullet.add(data.player.position, data.mouse_position, const.COLLISION_BITS.ENEMY, const.PLAYER.BULLETS.SINGLE, hero.hit)
	end
end

return hero
