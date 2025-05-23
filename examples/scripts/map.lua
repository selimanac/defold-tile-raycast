local const     = require("examples.scripts.const")
local collision = require("examples.scripts.collision")
local enemy     = require("examples.scripts.enemy")
local hero      = require("examples.scripts.hero")

-- Module
local map       = {}

local TILEMAP   = "/tilemap#line-of-sight"
local LAYERS    = {
	WALLS   = hash("map"),
	HERO    = hash("hero"),
	ENEMIES = hash("enemies"),
	PROPS   = hash("props")
}

function map.init()
	-- Init collision
	collision.init()

	local target_tiles = {}
	local _, _, tilemap_width, tilemap_height = tilemap.get_bounds(TILEMAP)
	local walls = {}
	local tile = 0
	local tile_ids = {}
	local tile_position_x = 0
	local tile_position_y = 0

	-- Set camera to center
	go.set_position(vmath.vector3((tilemap_width * const.TILE_SIZE) / 2, (tilemap_height * const.TILE_SIZE) / 2, 0), "/camera")

	for y = 1, tilemap_height do
		for x = 1, tilemap_width do
			-- Map
			tile = tilemap.get_tile(TILEMAP, LAYERS.WALLS, x, y)
			tile_position_x = (x * const.TILE_SIZE) - const.TILE_SIZE / 2
			tile_position_y = (y * const.TILE_SIZE) - const.TILE_SIZE / 2
			table.insert(walls, tile)
			if tile ~= 0 then
				tile_ids[tile] = tile
				collision.insert_aabb(tile_position_x, tile_position_y, const.TILE_SIZE, const.TILE_SIZE, const.COLLISION_BITS.WALL)
			end

			-- Hero
			local hero_tile = tilemap.get_tile(TILEMAP, LAYERS.HERO, x, y)
			if hero_tile ~= 0 then
				hero.add(tile_position_x, tile_position_y)
			end

			-- Enemy
			local enemy_tile = tilemap.get_tile(TILEMAP, LAYERS.ENEMIES, x, y)
			if enemy_tile ~= 0 then
				enemy.add(tile_position_x, tile_position_y)
			end

			-- props
			local prop_tile = tilemap.get_tile(TILEMAP, LAYERS.PROPS, x, y)
			if prop_tile ~= 0 then
				collision.insert_aabb(tile_position_x, tile_position_y, const.TILE_SIZE, const.TILE_SIZE, const.COLLISION_BITS.WALL)
			end
		end
	end

	for _, v in pairs(tile_ids) do
		table.insert(target_tiles, v)
	end

	-- Init tile_raycast
	tile_raycast.setup(const.TILE_SIZE, const.TILE_SIZE, tilemap_width, tilemap_height, walls, target_tiles)
end

return map
