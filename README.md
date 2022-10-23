# Tile Raycast
Ray Casting in tiled worlds using DDA algorithm. It is very effective solution for tile based worlds like platformers or any top-down games.  
This implementation based on https://lodev.org/cgtutor/raycasting.html and https://www.youtube.com/watch?v=NbSee-XM7WA


# Installation
You can use Tiled Ray Cast in your own project by adding this project as a [Defold library dependency](http://www.defold.com/manuals/libraries/). Open your game.project file and in the dependencies field under project add:

https://github.com/selimanac/defold-tile-raycast/archive/refs/heads/master.zip

# Example

https://github.com/selimanac/defold-tile-raycast-platformer

# API

## raycast.init (`tile_width`, `tile_height`, `tilemap_width`, `tilemap_height`, `tiles`, `target_tiles`)

Initial setup for raycast.

**PARAMETERS**
* ```tile_width``` (int) - Single tile width
* ```tile_height``` (int) - Single tile height
* ```tilemap_width``` (int) - Tilemap width
* ```tilemap_height``` (int) - Tilemap height
* ```tiles``` (table) - Single dimensional tiles table generated from your tilemap (or from your source).
* ```target_tiles``` (table) - Not passible tile IDs from your tilesource (walls, grounds etc...).

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

    raycast.init(tile_width, tile_height, tilemap_width, tilemap_height, tiles, target_tiles)
``` 


## raycast.cast (`ray_from`, `ray_to`)
Perform raycast on tilemap. Returns **only first** successful hit.

**PARAMETERS**
* ```ray_from``` (Vector3) - Start position of ray
* ```ray_to``` (Vector3) - End position of ray

**RETURN**
* ```hit``` (boolean) - If hit or not
* ```tile_x``` (int) - ile x position
* ```tile_y``` (int) - Tile y position
* ```array_id``` (int) - ID of the array for Tilemap array
* ```tile_id``` (int) - ID of the tile from tilesource for Tilemap 
* ```intersection_x``` (number) - Ray intersection point x
* ```intersection_y``` (number) - Ray intersection point y
* ```side``` (int) - Which side hit. 0 for LEFT-RIGHT, 1 for TOP-BOTTOM


**EXAMPLE**
```lua
	
    local ray_from = go.get_position(ray_start_url)
    local ray_to = go.get_position(ray_end_url)

    local hit, tile_x, tile_y, array_id, tile_id, intersection_x, intersection_y, side = raycast.cast(ray_from, ray_to)

     if hit then
        print("tile_x: " .. tile_x)
        print("tile_y: " .. tile_y)
        print("array_id " .. array_id)
        print("tile_id " .. tile_id)
        print("intersection_x " .. intersection_x)
        print("intersection_y " .. intersection_y)
        print("Side " .. side) -- 0 for LEFT-RIGHT, 1 for TOP-BOTTOM
    else
        print("No result found")
    end
``` 

## raycast.reset ()
Clear all tile and timemap data.