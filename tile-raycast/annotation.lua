---@class tile_raycast
tile_raycast = {}

--- Initializes the tile raycast system.
-- @param tile_width uint16_t Width of a single tile.
-- @param tile_height uint16_t Height of a single tile.
-- @param tilemap_width uint16_t Number of tiles horizontally in the tilemap.
-- @param tilemap_height uint16_t Number of tiles vertically in the tilemap.
-- @param tiles table<uint16_t> One-dimensional tile table.
-- @param target_tiles table<uint16_t> IDs of impassable tiles.
function tile_raycast.setup(tile_width, tile_height, tilemap_width, tilemap_height, tiles, target_tiles) end

--- Performs a raycast on the tilemap. Returns only the first successful hit.
-- @param ray_from_x number X coordinate of the ray start.
-- @param ray_from_y number Y coordinate of the ray start.
-- @param ray_to_x number X coordinate of the ray end.
-- @param ray_to_y number Y coordinate of the ray end.
-- @return boolean hit True if a tile was hit.
-- @return uint16_t tile_x X coordinate of the tile.
-- @return uint16_t tile_y Y coordinate of the tile.
-- @return uint16_t array_id Index in the tilemap array.
-- @return uint16_t tile_id ID of the tile from the tilesource.
-- @return number intersection_x X coordinate of the intersection point.
-- @return number intersection_y Y coordinate of the intersection point.
-- @return integer side The side of the tile hit: tile_raycast.LEFT, RIGHT, TOP, or BOTTOM.
function tile_raycast.cast(ray_from_x, ray_from_y, ray_to_x, ray_to_y) end

--- Sets a tile value in the map array at the specified coordinates.
-- @param tile_x uint16_t X coordinate of the tile.
-- @param tile_y uint16_t Y coordinate of the tile.
-- @param tile_id uint16_t ID of the tile to set.
function tile_raycast.set_at(tile_x, tile_y, tile_id) end

--- Returns the tile ID from the map array at the specified coordinates.
-- @param tile_x uint16_t X coordinate of the tile.
-- @param tile_y uint16_t Y coordinate of the tile.
-- @return uint16_t tile_id ID of the tile at the coordinates.
function tile_raycast.get_at(tile_x, tile_y) end

--- Clears all tile and tilemap data.
function tile_raycast.reset() end

--- Side enumeration values for raycast results.
tile_raycast.LEFT = 0
tile_raycast.RIGHT = 1
tile_raycast.TOP = 2
tile_raycast.BOTTOM = 3
