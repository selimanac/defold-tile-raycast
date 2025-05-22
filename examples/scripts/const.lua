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
	},
	FIRE_COOLDOWN = 2.0

}


const.VISION = {
	STATE = {
		IDLE = 1,          -- Normal patrol
		WARNING = 2,       -- Saw something, investigating
		ALERT = 3,         -- Target confirmed, attacking
	},
	FOV = 90,              -- Field of view in degrees
	DISTANCE = 150,        -- How far enemies can see
	PERIPHERAL_DISTANCE = 10, -- Distance for peripheral vision (outside the cone)
	CHECK_FREQUENCY = 0.1
}

return const
