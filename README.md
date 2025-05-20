![Tile Raycast](/assets/tile_raycast_2400x666.png)

# Tile Raycast
Raycasting in tiled worlds using the DDA algorithm. It is a very effective solution for tile-based worlds such as platformers or top-down games.    

This implementation is inspired by:  
https://lodev.org/cgtutor/raycasting.html  
https://www.youtube.com/watch?v=NbSee-XM7WA  

# Installation

You can use Tiled Raycast in your own project by adding this project as a [Defold library dependency](http://www.defold.com/manuals/libraries/). Open your `game.project` file and in the `dependencies` field under `project`, add:

https://github.com/selimanac/defold-tile-raycast/archive/refs/heads/master.zip



# API

### tile_raycast.setup(`tile_width`, `tile_heigh`,`tilemap_width`,`tilemap_height`,`tiles`,`target_tiles`)

Initial setup for raycasting.  

**PARAMETERS**
* `tile_width` (uint16_t) – Width of a single tile.
* `tile_height` (uint16_t) – Height of a single tile.
* `tilemap_width` (uint16_t) – Number of tiles horizontally in the tilemap.
* `tilemap_height` (uint16_t) – Number of tiles vertically in the tilemap.
* `tiles` (table - uint16_t ) – One-dimensional tile table generated from your tilemap or source data.
* `target_tiles` (table - uint16_t) – IDs of impassable tiles from your tilesource (e.g., walls, ground, etc.).

**EXAMPLE**
```lua
	
    local tiles = {
		4,2,2,2,0,2,2,2,2,2,
		2,2,2,2,0,2,2,2,2,2,
		2,2,2,2,0,2,2,2,2,2,
		2,2,1,2,2,2,2,2,2,2,
		2,2,2,2,2,2,2,2,2,2,
		1,2,1,2,2,2,1,1,1,1,
		1,1,1,2,2,2,1,1,1,1,
		1,1,1,2,1,2,1,3,1,1,
		1,1,1,1,2,1,1,1,4,1,
		1,1,1,2,2,2,2,1,1,3,
        1,1,1,1,1,1,1,1,1,1  
	}

    local tile_width = 32
    local tile_height = 32
    local target_tiles = {2, 3, 4}
    local tilemap_width = 10
    local tilemap_height = 11

    tile_raycast.setup(tile_width, tile_height, tilemap_width, tilemap_height, tiles, target_tiles)
``` 


### tile_raycast.cast(`ray_from_x`,`ray_from_y`,`ray_to_x`, `ray_to_y`)

Performs a raycast on the tilemap. Returns **only the first** successful hit.

**PARAMETERS**
* `ray_from_x` (float) – Start position of the ray (X).
* `ray_from_y` (float) – Start position of the ray (Y).
* `ray_to_x` (float) – End position of the ray (X).
* `ray_to_y` (float) – End position of the ray (Y).

**RETURN**
* `hit` (boolean) – Whether a tile was hit.
* `tile_x` (uint16_t) – X position of the tile.
* `tile_y` (uint16_t) – Y position of the tile.
* `array_id` (uint16_t) – Index in the tilemap array.
* `tile_id` (uint16_t) – ID of the tile from the tilesource.
* `intersection_x` (float) – X coordinate of the ray intersection point.
* `intersection_y` (float) – Y coordinate of the ray intersection point.
* `side` (enum) – The side of the tile that was hit.

   **tile_raycast.LEFT**   
   **tile_raycast.RIGHT**   
   **tile_raycast.TOP**   
   **tile_raycast.BOTTOM**   



**EXAMPLE**
```lua
	
    local ray_from = go.get_position(ray_start_url)
    local ray_to = go.get_position(ray_end_url)

    local hit, tile_x, tile_y, array_id, tile_id, intersection_x, intersection_y, side = tile_raycast.cast(ray_from.x,ray_from.y, ray_to.x,ray_to.y)

     if hit then
        print("tile_x: " .. tile_x)
        print("tile_y: " .. tile_y)
        print("array_id " .. array_id)
        print("tile_id " .. tile_id)
        print("intersection_x " .. intersection_x)
        print("intersection_y " .. intersection_y)
        print("Side " .. side) 
    else
        print("No result found")
    end
``` 

### tile_raycast.set_at(`tile_x`, `tile_y`, `tile_id`)

Sets a tile value in the map array at the specified coordinates.

**PARAMETERS**
* `tile_x` (uint16_t) – Tile X coordinate.
* `tile_y` (uint16_t) – Tile Y coordinate.
* `tile_id` (uint16_t) – Tile ID to set.


### tile_raycast.get_at(`tile_x`, `tile_y`)

Returns the tile ID from the map array at the specified coordinates.

**PARAMETERS**
* `tile_x` (uint16_t) – Tile X coordinate.
* `tile_y` (uint16_t) – Tile Y coordinate.

**RETURN**
* `tile_id` (uint16_t) – Tile ID at the given coordinates.

### tile_raycast.reset()

Clears all tile and tilemap data.






