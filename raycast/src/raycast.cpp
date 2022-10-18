
#define LIB_NAME "raycast"
#define MODULE_NAME "raycast"

#include <dmsdk/sdk.h>

//dmVMath::Vector3 *vPlayer;
dmVMath::Vector3 *vMouse;
dmVMath::Vector3 vMouseCell(0, 0, 0);
dmVMath::Vector3 *vRayStart;

dmVMath::Vector3 vMapSize(10, 10, 0);
dmVMath::Vector3 vCellSize(32, 32, 0);

int tile_width = 0;
int tile_height = 0;
int tilemap_width = 0;
int tilemap_height = 0;

dmArray<int> vecMap;
dmArray<int> target_tiles;

static float distance(dmVMath::Vector3 *v1, dmVMath::Vector3 *v2)
{
    return sqrt(pow((v2->getX() - v1->getX()), 2) + pow((v2->getY() - v1->getY()), 2));
}

static int reset(lua_State *L)
{
    vecMap.SetCapacity(0);
    vecMap.SetSize(0);
    return 0;
}

//  raycast.init(tile_width, tile_height, tilemap_width, tilemap_height, tiles, target_tiles, debug_print)
static int init(lua_State *L)
{
    tile_width = luaL_checkinteger(L, 1);  // tile_width
    tile_height = luaL_checkinteger(L, 2); // tile_height

    tilemap_width = luaL_checkinteger(L, 3);  // tilemap_width
    tilemap_height = luaL_checkinteger(L, 4); // tilemap_height

    vMapSize.setX(tilemap_width);
    vMapSize.setY(tilemap_height);

    vCellSize.setX(tile_width);
    vCellSize.setY(tile_height);

    vecMap.SetCapacity((tilemap_width * tilemap_height));

    /* tilemap */
    luaL_checktype(L, 5, LUA_TTABLE);
    lua_pushnil(L);
    while (lua_next(L, 5) != 0)
    {
        if (lua_isnumber(L, -1))
        {
            vecMap.Push(lua_tointeger(L, -1));
        }
        lua_pop(L, 1);
    }

    /* target_tiles */
    luaL_checktype(L, 6, LUA_TTABLE);
    int tiles_count = lua_objlen(L, 6); // Keep this for lua 5.1 - For  5.2  =>   tiles_count = lua_rawlen(L, 6);
    target_tiles.SetCapacity(tiles_count);

    lua_pushnil(L);
    while (lua_next(L, 6) != 0)
    {
        if (lua_isnumber(L, -1))
        {
            target_tiles.Push(lua_tointeger(L, -1));
        }
        lua_pop(L, 1);
    }

    // Optional print output
    if (lua_isboolean(L, 7) && lua_toboolean(L, 7) == true)
    {
        for (int i = 0; i < vecMap.Size(); i++)
        {
            printf("%i, ", vecMap[i]);
            if (i == 9 || i == 19 || i == 29 || i == 39 || i == 49 || i == 59 || i == 69 || i == 79 || i == 89)
            {
                printf("\n---\n");
            }
        }
        printf("\n---\n");
    }

    return 0;
}

static int cast(lua_State *L)
{
    // Return if map or tiles not set.
    if (vecMap.Size() == 0 || target_tiles.Size() == 0)
    {
        dmLogError("Tilemap or Target Tiles are not set.");
        return 0;
    }

    vRayStart = dmScript::CheckVector3(L, 1);
    vMouse = dmScript::CheckVector3(L, 2);

    vMouseCell.setX(vMouse->getX() / (vCellSize.getX() / 2));
    vMouseCell.setY( vMouse->getY() / (vCellSize.getY() / 2));


    dmVMath::Vector3 vRayDir(normalize(*vMouse - *vRayStart));

    dmVMath::Vector3 vRayUnitStepSize(
        abs(1.0f / vRayDir.getX()),
        abs(1.0f / vRayDir.getY()),
        0);

    dmVMath::Vector3 vMapCheck(vRayStart->getX(), vRayStart->getY(), 0);
    dmVMath::Vector3 vRayLength1D(0, 0, 0);
    dmVMath::Vector3 vStep(0, 0, 0);

    // Starting Conditions
    if (vRayDir.getX() < 0)
    {
        vStep.setX(-1);
        vRayLength1D.setX((vRayStart->getX() - (vMapCheck.getX())) * vRayUnitStepSize.getX());
    }
    else
    {
        vStep.setX(1);
        vRayLength1D.setX(((vMapCheck.getX() + 1) - vRayStart->getX()) * vRayUnitStepSize.getX());
    }

    if (vRayDir.getY() < 0)
    {
        vStep.setY(-1);
        vRayLength1D.setY((vRayStart->getY() - (vMapCheck.getY())) * vRayUnitStepSize.getY());
    }
    else
    {
        vStep.setY(1);
        vRayLength1D.setY(((vMapCheck.getY() + 1) - vRayStart->getY()) * vRayUnitStepSize.getY());
    }

    bool bTileFound = false;
    float fMaxDistance = distance(vRayStart, vMouse); // 1000.0f;

    float fDistance = 0.0f;
    int tile = 0;
    int tile_x = 0;
    int tile_y = 0;
    int side;

    while (!bTileFound && fDistance < fMaxDistance)
    {
        if (vRayLength1D.getX() < vRayLength1D.getY())
        {
            vMapCheck.setX(vMapCheck.getX() + vStep.getX());
            fDistance = vRayLength1D.getX();
            vRayLength1D.setX(vRayLength1D.getX() + vRayUnitStepSize.getX());
            side = 0;
        }
        else
        {
            vMapCheck.setY(vMapCheck.getY() + vStep.getY());
            fDistance = vRayLength1D.getY();
            vRayLength1D.setY(vRayLength1D.getY() + vRayUnitStepSize.getY());
            side = 1;
        }

        // Test tile
        if (vMapCheck.getX() >= 0 && vMapCheck.getX() < (vMapSize.getX() * vCellSize.getX()) && vMapCheck.getY() >= 0 && vMapCheck.getY() < (vMapSize.getY() * vCellSize.getY()))
        {

            tile_x = (int)(vMapCheck.getX() / vCellSize.getX());
            tile_y = (int)(vMapCheck.getY() / vCellSize.getY());
            tile = (tilemap_height * tilemap_width) - ((tilemap_height * tile_y) + (tilemap_width - tile_x));

            if (vecMap[tile] == 1)
            {
                dmLogInfo("TYPE %i", vecMap[tile]);
                dmLogInfo("Tile ID %i", tile);
                dmLogInfo("SIDE %i", side);
                bTileFound = true;
            }
        }
    }

    // Calculate intersection location
    dmVMath::Vector3 vIntersection;
    if (bTileFound)
    {
        vIntersection = *vRayStart + vRayDir * fDistance;
        dmLogInfo("vIntersection: %f - %f", vIntersection.getX(), vIntersection.getY());
    }

    int iL = 1;

    lua_pushboolean(L, bTileFound);

    if (bTileFound)
    {
        iL += 6;
        lua_pushinteger(L, tile_x + 1); // +1 for lua table
        lua_pushinteger(L, tile_y + 1); // +1 for lua table
        lua_pushinteger(L, tile + 1);   // +1 for lua table
        lua_pushnumber(L, vIntersection.getX());
        lua_pushnumber(L, vIntersection.getY());
        lua_pushinteger(L, side);
    }

    return iL;
}

// Functions exposed to Lua
static const luaL_reg Module_methods[] =
    {
        {"reset", reset},
        {"cast", cast},
        {"init", init},
        {0, 0}};

static void LuaInit(lua_State *L)
{
    int top = lua_gettop(L);
    luaL_register(L, MODULE_NAME, Module_methods);
    lua_pop(L, 1);
    assert(top == lua_gettop(L));
}

dmExtension::Result Initializeraycast(dmExtension::Params *params)
{
    // Init Lua
    LuaInit(params->m_L);
    dmLogInfo("Registered %s Extension\n", MODULE_NAME);
    return dmExtension::RESULT_OK;
}

dmExtension::Result Finalizeraycast(dmExtension::Params *params)
{
    dmLogInfo("FinalizeMyExtension\n");
    reset(0);
    return dmExtension::RESULT_OK;
}

DM_DECLARE_EXTENSION(raycast, LIB_NAME, 0, 0, Initializeraycast, 0, 0, Finalizeraycast)
