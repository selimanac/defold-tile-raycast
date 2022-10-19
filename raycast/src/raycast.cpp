
#define LIB_NAME "raycast"
#define MODULE_NAME "raycast"

#include <dmsdk/sdk.h>

// dmVMath::Vector3 *vPlayer;
dmVMath::Vector3 *vRayEnd;
dmVMath::Vector3 vRayEndTile(0, 0, 0);
dmVMath::Vector3 *vRayStart;
dmVMath::Vector3 vRayUnitStepSize(0, 0, 0);

dmVMath::Vector3 vTilemapSize(10, 10, 0);
dmVMath::Vector3 vTileSize(32, 32, 0);
dmVMath::Vector3 vMapCheck(0, 0, 0);
dmVMath::Vector3 vRayLength1D(0, 0, 0);
dmVMath::Vector3 vStep(0, 0, 0);
dmVMath::Vector3 vIntersection(0, 0, 0);
dmVMath::Vector3 vRayDir(0, 0, 0);

bool bTileFound = false;
float fMaxDistance = 0.0f;
float fDistance = 0.0f;

int iTileWidth = 0;
int iTileHeight = 0;
int iTilemapWidth = 0;
int iTilemapHeight = 0;
int tile = 0;
int tile_x = 0;
int tile_y = 0;
int side = 0;
int luaPosition = 1;
int tile_type = 0;

dmArray<int> aTilemap;
dmArray<int> aTargetTiles;
// dmArray<int> aCollisionTiles;

static float distance(dmVMath::Vector3 *v1, dmVMath::Vector3 *v2)
{
    return sqrt(pow((v2->getX() - v1->getX()), 2) + pow((v2->getY() - v1->getY()), 2));
}

static int reset(lua_State *L)
{
    aTilemap.SetSize(0);
    aTargetTiles.SetSize(0);
    return 0;
}

static int init(lua_State *L)
{
    iTileWidth = luaL_checkinteger(L, 1);
    iTileHeight = luaL_checkinteger(L, 2);
    iTilemapWidth = luaL_checkinteger(L, 3);
    iTilemapHeight = luaL_checkinteger(L, 4);

    vTilemapSize.setX(iTilemapWidth);
    vTilemapSize.setY(iTilemapHeight);

    vTileSize.setX(iTileWidth);
    vTileSize.setY(iTileHeight);

    aTilemap.SetCapacity((iTilemapWidth * iTilemapHeight));
    // aCollisionTiles.SetCapacity(iTilemapWidth * iTilemapHeight);

    /* Tilemap */
    luaL_checktype(L, 5, LUA_TTABLE);
    lua_pushnil(L);
    while (lua_next(L, 5) != 0)
    {
        if (lua_isnumber(L, -1))
        {
            aTilemap.Push(lua_tointeger(L, -1));
        }
        lua_pop(L, 1);
    }

    /* Target Tiles */
    luaL_checktype(L, 6, LUA_TTABLE);
    int tiles_count = lua_objlen(L, 6); // Keep this for lua 5.1 - For  5.2  =>   tiles_count = lua_rawlen(L, 6);
    aTargetTiles.SetCapacity(tiles_count);

    lua_pushnil(L);
    while (lua_next(L, 6) != 0)
    {
        if (lua_isnumber(L, -1))
        {
            aTargetTiles.Push(lua_tointeger(L, -1));
        }
        lua_pop(L, 1);
    }

    // Optional print output
    if (lua_isboolean(L, 7) && lua_toboolean(L, 7) == true)
    {
        for (int i = 0; i < aTilemap.Size(); i++)
        {
            printf("%i, ", aTilemap[i]);
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
    if (aTilemap.Size() == 0 || aTargetTiles.Size() == 0)
    {
        dmLogError("Tilemap or Target Tiles are not set.");
        return 0;
    }

    vRayStart = dmScript::CheckVector3(L, 1);
    vRayEnd = dmScript::CheckVector3(L, 2);

    vRayEndTile.setX(vRayEnd->getX() / (vTileSize.getX() / 2));
    vRayEndTile.setY(vRayEnd->getY() / (vTileSize.getY() / 2));

    vRayDir = normalize(*vRayEnd - *vRayStart);

    vRayUnitStepSize.setX(abs(1.0f / vRayDir.getX()));
    vRayUnitStepSize.setY(abs(1.0f / vRayDir.getY()));

    vMapCheck = *vRayStart;

    vRayLength1D.setX(0);
    vRayLength1D.setY(0);

    vStep.setX(0);
    vStep.setY(0);

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

    // Reset values
    bTileFound = false;
    fMaxDistance = distance(vRayStart, vRayEnd);
    fDistance = 0.0f;
    tile = 0;
    tile_x = 0;
    tile_y = 0;
    side = 0;

    while (!bTileFound && fDistance < fMaxDistance)
    {
        if (vRayLength1D.getX() < vRayLength1D.getY())
        {
            vMapCheck.setX((int)(vMapCheck.getX() + vStep.getX()));
            fDistance = vRayLength1D.getX();
            vRayLength1D.setX(vRayLength1D.getX() + vRayUnitStepSize.getX());
            side = 0;
        }
        else
        {
            vMapCheck.setY((int)(vMapCheck.getY() + vStep.getY()));
            fDistance = vRayLength1D.getY();
            vRayLength1D.setY(vRayLength1D.getY() + vRayUnitStepSize.getY());
            side = 1;
        }

        // Test tile
        if (vMapCheck.getX() >= 0 && vMapCheck.getX() < (vTilemapSize.getX() * vTileSize.getX()) && vMapCheck.getY() >= 0 && vMapCheck.getY() < (vTilemapSize.getY() * vTileSize.getY()))
        {
            tile_x = (int)(vMapCheck.getX() / vTileSize.getX());
            tile_y = (int)(vMapCheck.getY() / vTileSize.getY());
            tile = (iTilemapHeight * iTilemapWidth) - ((iTilemapHeight * tile_y) + (iTilemapWidth - tile_x));

            tile = tile_y * vTilemapSize.getX() + tile_x;

            for (int i = 0; i < aTargetTiles.Size(); i++)
            {
                if (aTilemap[tile] == aTargetTiles[i])
                {
                    tile_type = aTargetTiles[i];
                    bTileFound = true;

                    /*  if (aCollisionTiles.Full())
                     {
                         aCollisionTiles.SetCapacity(aCollisionTiles.Capacity() + 100);
                     }
                     aCollisionTiles.Push(tile); */
                }
            }
        }
    }

    /*  if (aCollisionTiles.Size() > 0)
     {
         bTileFound = true;
     } */

    /* printf("-------\n");
    for (int i = 0; i < aCollisionTiles.Size(); i++)
    {
        printf("%i \n", aCollisionTiles[i]);
    }
    printf("-------\n");
    aCollisionTiles.SetSize(0); */

    // Calculate intersection location
    if (bTileFound)
    {
        vIntersection = *vRayStart + vRayDir * fDistance;
    }

    luaPosition = 1; // +1 is for hit

    lua_pushboolean(L, bTileFound);

    if (bTileFound)
    {
        luaPosition += 7;               // +7 if hit
        lua_pushinteger(L, tile_x + 1); // +1 for lua table
        lua_pushinteger(L, tile_y + 1); // +1 for lua table
        lua_pushinteger(L, tile + 1);   // +1 for lua table
        lua_pushinteger(L, tile_type);  // +1 for lua table
        lua_pushnumber(L, vIntersection.getX());
        lua_pushnumber(L, vIntersection.getY());
        lua_pushinteger(L, side);
    }

    return luaPosition;
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
