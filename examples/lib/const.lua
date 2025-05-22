local const = {}

const.DISPLAY_WIDTH = sys.get_config_int("display.width")
const.DISPLAY_HEIGHT = sys.get_config_int("display.height")
const.TILE_SIZE = 8

const.COLLISION_BITS = {
	PLAYER = 1,
	ENEMY  = 2,
	WALL   = 4,
	BULLET = 8,
	ALL    = bit.bnot(0)
}

const.TRIGGER = {
	UP    = hash("up"),
	DOWN  = hash("down"),
	LEFT  = hash("left"),
	RIGHT = hash("right"),
	TOUCH = hash("touch")
}

const.PLAYER = {
	BULLETS = {
		SINGLE = {
			PROJECTILE = hash("projectile"),
			IMPACT = hash("bullet_impact"),
		}
	}

}


const.ENEMY = {
	BULLETS = {
		SINGLE = {
			PROJECTILE = hash("projectile_enemy"),
			IMPACT = hash("bullet_enemy_impact"),
		}
	}

}

return const
