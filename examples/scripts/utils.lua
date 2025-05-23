local const = require("examples.scripts.const")

local utils = {}

-- https://defold.com/manuals/camera/#converting-mouse-to-world-coordinates
function utils.screen_to_world(x, y, z, camera_id)
	local projection = camera.get_projection(camera_id)
	local view = camera.get_view(camera_id)
	local w, h = window.get_size()

	w = w / (w / const.DISPLAY_WIDTH)
	h = h / (h / const.DISPLAY_HEIGHT)

	local inv = vmath.inv(projection * view)
	x = (2 * x / w) - 1
	y = (2 * y / h) - 1
	z = (2 * z) - 1
	local x1 = x * inv.m00 + y * inv.m01 + z * inv.m02 + inv.m03
	local y1 = x * inv.m10 + y * inv.m11 + z * inv.m12 + inv.m13
	local z1 = x * inv.m20 + y * inv.m21 + z * inv.m22 + inv.m23
	return x1, y1, z1
end

-- function utils.angle_diff(angle, facing_angle)
-- 	return math.abs((angle - facing_angle + 180) % 360 - 180)
-- end

-- without abs
function utils.angle_diff(angle, facing_angle)
	local diff = (angle - facing_angle + 180) % 360 - 180
	return diff < 0 and -diff or diff
end

function utils.is_angle_in_fov(angle, facing_angle, fov)
	local diff = utils.angle_diff(angle, facing_angle)
	return diff <= fov / 2
end

function utils.angle(target)
	return math.deg(math.atan2(target.y, target.x))
end

return utils
