local manager = {}

manager.urls = {platformer_tilemap = msg.url("/tilemap#platform")}

manager.tiles = {}
manager.target_tiles = {}

local function make_unique(t)

    local hash = {}
    local res = {}
    for _, v in ipairs(t) do
        if (not hash[v]) then
            res[#res + 1] = v
            hash[v] = true
        end
    end
    return res
end

local function set_urls()
    manager.urls.platformer_tilemap = msg.url("/tilemap#platform")
end

local function get_target_tiles(tilemap_width, tilemap_height)
    local tiles = {}
    local target_tiles = {}
    local tileno = 0
	local pos_x = 1 -- flip tilemap

    for x = 1, tilemap_width do
        for y = 1, tilemap_height do
            tileno = tilemap.get_tile(manager.urls.platformer_tilemap, "targets", x, y)
            if tileno > 0 then -- Skip blanks 
                -- 195 for platforms
                -- 41 for one-way platform 
                table.insert(target_tiles, tileno)
            end
        end
    end


    for y = tilemap_height, 1, -1 do
        for x = tilemap_width, 1, -1 do
            tileno = tilemap.get_tile(manager.urls.platformer_tilemap, "platforms", pos_x, y)
            table.insert(tiles, tileno)
			pos_x = pos_x + 1
        end
		pos_x = 1
    end

    return tiles, make_unique(target_tiles)
end

function manager.init()

    set_urls()

    tilemap.set_visible(manager.urls.platformer_tilemap, "targets", false)

    local _, _, tilemap_width, tilemap_height = tilemap.get_bounds(manager.urls.platformer_tilemap)
    local tile_width = 16
    local tile_height = 16

    manager.tiles, manager.target_tiles = get_target_tiles(tilemap_width, tilemap_height)

   pprint(manager.tiles)

end

return manager
