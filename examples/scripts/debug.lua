local data = require("examples.scripts.data")
local const = require("examples.scripts.const")

local debug = {}

debug.COLOR = {
	RED = vmath.vector4(1, 0, 0, 1),
	GREEN = vmath.vector4(0, 1, 0, 1),
	YELLOW = vmath.vector4(0.8, 0.8, 0, 1),
	BLUE = vmath.vector4(0.0, 0.0, 1.0, 1),
	WHITE = vmath.vector4(1, 1, 1, 1)
}

function debug.draw_line(start_position, end_position, color)
	if not data.debug then
		return
	end
	msg.post("@render:", "draw_line", { start_point = start_position, end_point = end_position, color = color })
end

function debug.draw_cone(enemy)
	local cone_segments = 10
	local angle_step = enemy.vision.fov / cone_segments
	local start_angle = enemy.vision.facing_angle - enemy.vision.fov / 2

	-- Draw vision cone
	for i = 0, cone_segments do
		local angle = start_angle + i * angle_step
		local rad = math.rad(angle)
		local dir = vmath.vector3(math.cos(rad), math.sin(rad), 0)
		local end_pos = enemy.position + dir * enemy.vision.distance

		-- Do raycast to find if this ray hits a wall
		local hit, _, _, _, _, hit_x, hit_y = tile_raycast.cast(
			enemy.position.x, enemy.position.y,
			end_pos.x, end_pos.y
		)

		-- Set ray end position based on raycast hit
		if hit then
			end_pos.x = hit_x
			end_pos.y = hit_y
		end

		-- Color based on state
		local color
		if enemy.vision.state == const.VISION.STATE.IDLE then
			color = debug.COLOR.GREEN
		elseif enemy.vision.state == const.VISION.STATE.WARNING then
			color = debug.COLOR.YELLOW
		else -- STATE_ALERT
			color = debug.COLOR.RED
		end

		-- Draw the ray
		msg.post("@render:", "draw_line", {
			start_point = enemy.position,
			end_point = end_pos,
			color = color
		})
	end

	-- Draw peripheral vision circle if in suspicious or alert state
	if enemy.vision.state > const.VISION.STATE.IDLE then
		-- Draw peripheral vision as a circle of points
		local peripheral_segments = 16
		local prev_point = nil

		for i = 0, peripheral_segments do
			local angle = (i / peripheral_segments) * 360
			local rad = math.rad(angle)
			local dir = vmath.vector3(math.cos(rad), math.sin(rad), 0)
			local point = enemy.position + dir * enemy.vision.peripheral_distance

			if prev_point then
				msg.post("@render:", "draw_line", {
					start_point = prev_point,
					end_point = point,
					color = debug.COLOR.BLUE
				})
			end
			prev_point = point
		end
	end

	-- If enemy has seen the player, draw line to last seen position
	if enemy.vision.last_seen_position then
		msg.post("@render:", "draw_line", {
			start_point = enemy.position,
			end_point = enemy.vision.last_seen_position,
			color = debug.COLOR.WHITE
		})
	end
end

return debug
