local data = require("examples.lib.data")
local const = require("examples.lib.const")
local collision = require("examples.lib.collision")


local hero = {}

local velocity = vmath.vector3()
local input = vmath.vector3()
local direction = vmath.vector3()
local acceleration = 60
local max_speed = 50
local friction = 0.85 -- Added friction for smoother movement
local ray_intersection = vmath.vector3()

function hero.add(tile_position_x, tile_position_y)
	data.player.position.x = tile_position_x
	data.player.position.y = tile_position_y



	data.player.id = factory.create("/factories#hero", vmath.vector3(tile_position_x, tile_position_y, 0.5))
	data.player.aabb_id = collision.insert_gameobject(msg.url(data.player.id), const.TILE_SIZE, const.TILE_SIZE, const.COLLISION_BITS.PLAYER)
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
			-- collision offset
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

		msg.post("@render:", "draw_line", { start_point = ray_intersection, end_point = data.mouse_position, color = vmath.vector4(1, 0, 0, 1) })

		msg.post("@render:", "draw_line", { start_point = data.player.position, end_point = ray_intersection, color = vmath.vector4(0, 1, 0, 1) })
	else
		msg.post("@render:", "draw_line", { start_point = data.player.position, end_point = data.mouse_position, color = vmath.vector4(0, 1, 0, 1) })
	end
end

function hero.input(action_id, action)
	-- Accumulate input instead of overriding
	if action_id == hash("up") then
		input.y = 1
	elseif action_id == hash("down") then
		input.y = -1
	elseif action_id == hash("left") then
		input.x = -1
	elseif action_id == hash("right") then
		input.x = 1
	end
end

return hero
