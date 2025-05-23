local utils = require("examples.scripts.utils")
local data = require("examples.scripts.data")
local const = require("examples.scripts.const")

local cursor = {}

function cursor.input(action)
	if action.x or action.y then
		data.mouse_position.x, data.mouse_position.y = utils.screen_to_world(action.x, action.y, 0, const.CAMERA)
		go.set_position(data.mouse_position, const.CURSOR)
	end
end

return cursor
