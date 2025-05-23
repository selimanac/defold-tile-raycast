local const       = require("examples.scripts.const")

local game_camera = {}

local zoom        = 0
local window_size = {
	width = 0,
	height = 0
}

function game_camera.set_zoom(size)
	local new_camera_zoom = math.max(size.width / const.DISPLAY_WIDTH, size.height / const.DISPLAY_HEIGHT) * zoom / window.get_display_scale()

	go.set(const.CAMERA, "orthographic_zoom", new_camera_zoom)
end

local function window_event(_, event, size)
	if event == window.WINDOW_EVENT_RESIZED then
		game_camera.set_zoom(size)
	end
end

function game_camera.init()
	zoom = go.get(const.CAMERA, "orthographic_zoom")

	window_size.width, window_size.height = window.get_size()

	game_camera.set_zoom(window_size)

	window.set_listener(window_event)
end

return game_camera
