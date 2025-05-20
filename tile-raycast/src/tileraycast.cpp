#define LIB_NAME "TileRaycast"
#define MODULE_NAME "tile_raycast"

#include <dmsdk/sdk.h>
#include <dda.h>

dda::RayResult m_RayResult;

static int     Reset(lua_State* L)
{
    dda::Reset();
    return 0;
}

static int Setup(lua_State* L)
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

static int Result(lua_State* L)
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

// Functions exposed to Lua
static const luaL_reg Module_methods[] = {
    { "reset", Reset },
    { "result", Result },
    { "setup", Setup },
    { 0, 0 }
};

static void LuaInit(lua_State* L)
{
    int top = lua_gettop(L);

    // Register lua names
    luaL_register(L, MODULE_NAME, Module_methods);

    lua_pop(L, 1);
    assert(top == lua_gettop(L));
}

static dmExtension::Result AppInitializeTileRaycast(dmExtension::AppParams* params)
{
    dmLogInfo("AppInitializeTileRaycast");
    return dmExtension::RESULT_OK;
}

static dmExtension::Result InitializeTileRaycast(dmExtension::Params* params)
{
    // Init Lua
    LuaInit(params->m_L);
    dmLogInfo("Registered %s Extension", MODULE_NAME);
    return dmExtension::RESULT_OK;
}

static dmExtension::Result AppFinalizeTileRaycast(dmExtension::AppParams* params)
{
    dmLogInfo("AppFinalizeTileRaycast");
    return dmExtension::RESULT_OK;
}

static dmExtension::Result FinalizeTileRaycast(dmExtension::Params* params)
{
    dmLogInfo("FinalizeTileRaycast");
    return dmExtension::RESULT_OK;
}

static dmExtension::Result OnUpdateTileRaycast(dmExtension::Params* params)
{
    //  dmLogInfo("OnUpdateTileRaycast");
    return dmExtension::RESULT_OK;
}

static void OnEventTileRaycast(dmExtension::Params* params, const dmExtension::Event* event)
{
    /* switch (event->m_Event)
     {
         case dmExtension::EVENT_ID_ACTIVATEAPP:
             dmLogInfo("OnEventTileRaycast - EVENT_ID_ACTIVATEAPP");
             break;
         case dmExtension::EVENT_ID_DEACTIVATEAPP:
             dmLogInfo("OnEventTileRaycast - EVENT_ID_DEACTIVATEAPP");
             break;
         case dmExtension::EVENT_ID_ICONIFYAPP:
             dmLogInfo("OnEventTileRaycast - EVENT_ID_ICONIFYAPP");
             break;
         case dmExtension::EVENT_ID_DEICONIFYAPP:
             dmLogInfo("OnEventTileRaycast - EVENT_ID_DEICONIFYAPP");
             break;
         default:
             dmLogWarning("OnEventTileRaycast - Unknown event id");
             break;
     }*/
}

// Defold SDK uses a macro for setting up extension entry points:
//
// DM_DECLARE_EXTENSION(symbol, name, app_init, app_final, init, update, on_event, final)

// TileRaycast is the C++ symbol that holds all relevant extension data.
// It must match the name field in the `ext.manifest`
DM_DECLARE_EXTENSION(TileRaycast, LIB_NAME, AppInitializeTileRaycast, AppFinalizeTileRaycast, InitializeTileRaycast, OnUpdateTileRaycast, OnEventTileRaycast, FinalizeTileRaycast)
