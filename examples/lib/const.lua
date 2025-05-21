local const = {}

const.DISPLAY_WIDTH = sys.get_config_int("display.width")
const.DISPLAY_HEIGHT = sys.get_config_int("display.height")
const.TILE_SIZE = 8

const.COLLISION_BITS = {
	PLAYER = 1,
	ENEMY  = 2,
	WALL   = 4,
	ALL    = bit.bnot(0)
}

return const
