local const = {}

const.DISPLAY_WIDTH = sys.get_config_int("display.width")
const.DISPLAY_HEIGHT = sys.get_config_int("display.height")
const.TILE_SIZE = 8

const.FACTORY = {
	BULLET = "/factories#bullet",
	BULLET_IMPACT = "/factories#bullet_impact",
	ENEMY = "/factories#enemy",
	ENEMY_STATUS_INDICATOR = "/factories#status_indicator",
	HERO = "/factories#hero"
}

const.CAMERA = "/camera#camera"
const.CURSOR = "/cursor"

const.COLLISION_BITS = {
	PLAYER = 1,
	ENEMY  = 2,
	WALL   = 4,
	BULLET = 8,
	ALL    = bit.bnot(0)
}

const.TRIGGER = {
	UP            = hash("up"),
	DOWN          = hash("down"),
	LEFT          = hash("left"),
	RIGHT         = hash("right"),
	TOUCH         = hash("touch"),
	VISION_CONE   = hash("vision_cone"),
	LINE_OF_SIGHT = hash("line_of_sight"),
	DEBUG         = hash("debug"),
}

const.HERO = {
	BULLETS = {
		SINGLE = {
			PROJECTILE = hash("projectile"),
			IMPACT     = hash("bullet_impact"),
		}
	},
	ACCELERATION = 200,
	MAX_SPEED = 50,
	FRICTION = 0.7,

}

const.ENEMY = {
	BULLETS = {
		SINGLE = {
			PROJECTILE = hash("projectile_enemy"),
			IMPACT     = hash("bullet_enemy_impact"),
		}
	},
	FIRE_COOLDOWN = 1.3,
	VISION_STATUS = {
		IDLE    = hash("enemy_status_idle"),
		WARNING = hash("enemy_status_warning"),
		DANGER  = hash("enemy_status_danger"),
	}

}

-- Defaults for Vision
const.VISION = {
	STATE                           = {
		IDLE    = 1,
		WARNING = 2,
		ALERT   = 3,
	},
	FOV                             = 90,
	DISTANCE                        = 150,
	PERIPHERAL_DISTANCE             = 10,
	CHECK_FREQUENCY                 = 0.1,
	PERIPHERAL_DETECTION_SPEED      = 1.0,
	SLOW_PERIPHERAL_DETECTION_SPEED = 0.4
}

return const
