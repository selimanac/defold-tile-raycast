local const = require("examples.scripts.const")

local utils = {}

function utils.screen_to_world(x, y, z, camera_id)
	local projection = camera.get_projection(camera_id)
	local view = camera.get_view(camera_id)
	local w, h = window.get_size()
	-- The window.get_size() function will return the scaled window size,
	-- ie taking into account display scaling (Retina screens on macOS for
	-- instance). We need to adjust for display scaling in our calculation.
	w = w / (w / const.DISPLAY_WIDTH)
	h = h / (h / const.DISPLAY_HEIGHT)

	-- https://defold.com/manuals/camera/#converting-mouse-to-world-coordinates
	local inv = vmath.inv(projection * view)
	x = (2 * x / w) - 1
	y = (2 * y / h) - 1
	z = (2 * z) - 1
	local x1 = x * inv.m00 + y * inv.m01 + z * inv.m02 + inv.m03
	local y1 = x * inv.m10 + y * inv.m11 + z * inv.m12 + inv.m13
	local z1 = x * inv.m20 + y * inv.m21 + z * inv.m22 + inv.m23
	return x1, y1, z1
end

return utils
