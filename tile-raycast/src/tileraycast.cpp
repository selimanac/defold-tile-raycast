#include "dmsdk/script/script.h"
#include <cstdint>
#define LIB_NAME "TileRaycast"
#define MODULE_NAME "tile_raycast"

#include <dmsdk/sdk.h>
#include <dda.h>

dda::RayResult m_RayResult;

static int     RaycastReset(lua_State* L)
{
    dda::Reset();
    return 0;
}

static int RaycastSetup(lua_State* L)
{
    // Reset
    dda::Reset();

    // SETTINGS
    uint16_t tile_width = luaL_checkinteger(L, 1);
    uint16_t tile_height = luaL_checkinteger(L, 2);
    uint16_t map_width = luaL_checkinteger(L, 3);
    uint16_t map_height = luaL_checkinteger(L, 4);

    //  Tilemap
    dmArray<uint16_t> tile_map;
    tile_map.SetCapacity(map_width * map_height);

    luaL_checktype(L, 5, LUA_TTABLE);
    lua_pushnil(L);
    while (lua_next(L, 5) != 0)
    {
        if (lua_isnumber(L, -1))
        {
            tile_map.Push(lua_tointeger(L, -1));
        }
        lua_pop(L, 1);
    }

    //  Target Tiles
    luaL_checktype(L, 6, LUA_TTABLE);
    uint16_t          tiles_count = lua_objlen(L, 6); // Keep this for lua 5.1 - For  5.2  =>   tiles_count = lua_rawlen(L, 6);

    dmArray<uint16_t> target_tiles;
    target_tiles.SetCapacity(tiles_count);

    lua_pushnil(L);
    while (lua_next(L, 6) != 0)
    {
        if (lua_isnumber(L, -1))
        {
            uint16_t tile_type = lua_tointeger(L, -1);
            target_tiles.Push(tile_type);
        }
        lua_pop(L, 1);
    }

    // Init
    dda::Init(tile_width, tile_height, map_width, map_height, &tile_map, &target_tiles);
    return 0;
}

static int RaycastResult(lua_State* L)
{
    if (!dda::SetupCheck())
    {
        dmLogError("Tilemap and Target Tiles are not set.");
        return 0;
    }

    dda::Vec2 ray_start;
    ray_start.x = luaL_checkinteger(L, 1);
    ray_start.y = luaL_checkinteger(L, 2);

    dda::Vec2 ray_end;
    ray_end.x = luaL_checkinteger(L, 3);
    ray_end.y = luaL_checkinteger(L, 4);

    dda::RayCast(&ray_start, &ray_end, &m_RayResult);

    int lua_position = 1;

    lua_pushboolean(L, m_RayResult.m_TileFound);

    if (m_RayResult.m_TileFound)
    {
        lua_position += 7;                               // +7 if hit
        lua_pushinteger(L, m_RayResult.m_TileX);         // tile_x
        lua_pushinteger(L, m_RayResult.m_TileY);         // tile_y
        lua_pushinteger(L, m_RayResult.m_ArrayId);       // array_id
        lua_pushinteger(L, m_RayResult.m_TileId);        // tile_id
        lua_pushnumber(L, m_RayResult.m_Intersection.x); // intersection_x
        lua_pushnumber(L, m_RayResult.m_Intersection.y); // intersection_y
        lua_pushinteger(L, m_RayResult.m_Side);          // Side
    }

    return lua_position;
}

static int RaycastSetAt(lua_State* L)
{
    uint16_t tile_x = luaL_checkint(L, 1) - 1;
    uint16_t tile_y = luaL_checkint(L, 2) - 1;

    lua_pushinteger(L, dda::GetAt(tile_x, tile_y));
    return 1;
}

static int RaycastGetAt(lua_State* L)
{
    uint16_t tile_x = luaL_checkint(L, 1) - 1;
    uint16_t tile_y = luaL_checkint(L, 2) - 1;
    uint16_t tile = luaL_checkint(L, 3);

    dda::SetAt(tile_x, tile_y, tile);

    return 0;
}

// Functions exposed to Lua
static const luaL_reg Module_methods[] = {
    { "reset", RaycastReset },
    { "cast", RaycastResult },
    { "setup", RaycastSetup },
    { "set_at", RaycastSetAt },
    { "get_at", RaycastGetAt },
    { 0, 0 }
};

static void LuaInit(lua_State* L)
{
    int top = lua_gettop(L);

    // Register lua names
    luaL_register(L, MODULE_NAME, Module_methods);

#define SETCONSTANT(name) \
    lua_pushnumber(L, (lua_Number)dda::name); \
    lua_setfield(L, -2, #name);

    SETCONSTANT(LEFT);
    SETCONSTANT(RIGHT);
    SETCONSTANT(TOP);
    SETCONSTANT(BOTTOM);
#undef SETCONSTANT

    lua_pop(L, 1);
    assert(top == lua_gettop(L));
}

static dmExtension::Result InitializeTileRaycast(dmExtension::Params* params)
{
    // Init Lua
    LuaInit(params->m_L);
    dmLogInfo("Registered %s Extension", MODULE_NAME);
    return dmExtension::RESULT_OK;
}

static dmExtension::Result FinalizeTileRaycast(dmExtension::Params* params)
{
    dda::Reset();
    dmLogInfo("FinalizeTileRaycast");
    return dmExtension::RESULT_OK;
}

DM_DECLARE_EXTENSION(TileRaycast, LIB_NAME, 0, 0, InitializeTileRaycast, 0, 0, FinalizeTileRaycast)
