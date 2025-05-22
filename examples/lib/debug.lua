local data = require("examples.lib.data")

local debug = {}

debug.COLOR = {
	RED = vmath.vector4(1, 0, 0, 1),
	GREEN = vmath.vector4(0, 1, 0, 1)
}

function debug.draw_line(start_position, end_position, color)
	if not data.debug then
		return
	end
	msg.post("@render:", "draw_line", { start_point = start_position, end_point = end_position, color = color })
end

return debug
