#include "dda.h"
#include "dmsdk/dlib/hashtable.h"
#include "dmsdk/dlib/log.h"
#include <cmath>
#include <cstdint>

namespace dda
{

    dmArray<uint16_t>   m_Tilemap;
    dmHashTable16<bool> m_TargetTiles;
    Settings            m_Settings;
    Vec2                m_RayDirection;
    Vec2                m_RayNormalDirection;
    Vec2                m_UnitStepSize;
    Vec2Int             m_MapCheck;
    Vec2                m_RayLength1D;
    Vec2Int             m_Step;

    bool                m_TileFound;
    float               m_MaxDistance;
    float               m_Distance;
    uint16_t            m_Tile;
    uint16_t            m_TileID;
    uint16_t            m_TileX;
    uint16_t            m_TileY;
    Side                m_Side;
    Vec2                m_Intersection;

    inline float        Distance(const Vec2* v1, const Vec2* v2)
    {
        float dx = v2->x - v1->x;
        float dy = v2->y - v1->y;
        return sqrtf(dx * dx + dy * dy);
        // return sqrt(pow((v2->x - v1->x), 2) + pow((v2->y - v1->y), 2));
        //  return sqrt((v2->x - v1->x) * (v2->x - v1->x) + (v2->y - v1->y) * (v2->y - v1->y));
    }

    inline float DistanceSquared(const Vec2* v1, const Vec2* v2)
    {
        return (v2->x - v1->x) * (v2->x - v1->x) + (v2->y - v1->y) * (v2->y - v1->y);
    }

    inline void Normalize(const Vec2* in, Vec2* out)
    {
        float length = sqrtf(in->x * in->x + in->y * in->y);
        if (length > 0.0f)
        {
            out->x = in->x / length;
            out->y = in->y / length;
        }
        else
        {
            out->x = 0.0f;
            out->y = 0.0f;
        }
    }

    void Init(const uint16_t tile_width, const uint16_t tile_height, const uint16_t map_width, const uint16_t map_height, const dmArray<uint16_t>* tile_map, const dmArray<uint16_t>* target_tiles)
    {
        // Settings
        m_Settings.m_TileWidth = tile_width;
        m_Settings.m_TileHeight = tile_height;
        m_Settings.m_Width = map_width;
        m_Settings.m_Height = map_height;

        // Copy Map
        m_Tilemap.SetCapacity(tile_map->Size());
        m_Tilemap.SetSize(tile_map->Size());
        memcpy(m_Tilemap.Begin(), tile_map->Begin(), tile_map->Size() * sizeof(uint16_t));

        // Copy Target Tiles

        m_TargetTiles.SetCapacity(target_tiles->Capacity());

        for (int i = 0; i < target_tiles->Size(); ++i)
        {
            m_TargetTiles.Put((*target_tiles)[i], true);
        }
    }
    void RayCast(const dda::Vec2* ray_start, const dda::Vec2* ray_end, RayResult* ray_result)
    {
        m_RayDirection.x = ray_end->x - ray_start->x;
        m_RayDirection.y = ray_end->y - ray_start->y;

        Normalize(&m_RayDirection, &m_RayNormalDirection);

        m_UnitStepSize.x = fabs(1.0f / m_RayNormalDirection.x);
        m_UnitStepSize.y = fabs(1.0f / m_RayNormalDirection.y);

        m_MapCheck.x = (int)ray_start->x;
        m_MapCheck.y = (int)ray_start->y;

        m_RayLength1D.x = 0;
        m_RayLength1D.y = 0;

        m_Step.x = 0;
        m_Step.y = 0;

        // Starting Conditions
        if (m_RayNormalDirection.x < 0)
        {
            m_Step.x = -1;
            m_RayLength1D.x = (ray_start->x - m_MapCheck.x) * m_UnitStepSize.x;
        }
        else
        {
            m_Step.x = 1;
            m_RayLength1D.x = ((m_MapCheck.x + 1) - ray_start->x) * m_UnitStepSize.x;
        }

        if (m_RayNormalDirection.y < 0)
        {
            m_Step.y = -1;
            m_RayLength1D.y = (ray_start->y - m_MapCheck.y) * m_UnitStepSize.y;
        }
        else
        {
            m_Step.y = 1;
            m_RayLength1D.y = ((m_MapCheck.y + 1) - ray_start->y) * m_UnitStepSize.y;
        }

        // Reset values
        m_TileFound = false;
        m_MaxDistance = Distance(ray_start, ray_end);
        m_Distance = 0.0f;
        m_Tile = 0;
        m_TileX = 0;
        m_TileY = 0;
        m_Side = Side::LEFT;

        while (!m_TileFound && m_Distance < m_MaxDistance)
        {
            if (m_RayLength1D.x < m_RayLength1D.y)
            {
                m_MapCheck.x = m_MapCheck.x + m_Step.x;
                m_Distance = m_RayLength1D.x;
                m_RayLength1D.x = m_RayLength1D.x + m_UnitStepSize.x;

                if (m_Step.x < 0)
                    m_Side = Side::RIGHT;
                else
                    m_Side = Side::LEFT;
            }
            else
            {
                m_MapCheck.y = m_MapCheck.y + m_Step.y;
                m_Distance = m_RayLength1D.y;
                m_RayLength1D.y = m_RayLength1D.y + m_UnitStepSize.y;

                if (m_Step.y < 0)
                    m_Side = Side::TOP;
                else
                    m_Side = Side::BOTTOM;
            }

            // Bound check
            if (m_MapCheck.x >= 0 && m_MapCheck.x < (m_Settings.m_Width * m_Settings.m_TileWidth) &&
                m_MapCheck.y >= 0 && m_MapCheck.y < (m_Settings.m_Height * m_Settings.m_TileHeight))
            {
                m_TileX = m_MapCheck.x / m_Settings.m_TileWidth;
                m_TileY = m_MapCheck.y / m_Settings.m_TileHeight;

                m_Tile = m_TileY * m_Settings.m_Width + m_TileX;

                if (m_TargetTiles.Get(m_Tilemap[m_Tile]))
                {
                    m_TileID = m_Tilemap[m_Tile];
                    m_TileFound = true;
                }
            }
        } // End While

        ray_result->m_TileFound = m_TileFound;
        if (m_TileFound)
        {
            ray_result->m_Intersection.x = ray_start->x + m_RayNormalDirection.x * m_Distance;
            ray_result->m_Intersection.y = ray_start->y + m_RayNormalDirection.y * m_Distance;

            ray_result->m_TileX = m_TileX + 1;
            ray_result->m_TileY = m_TileY + 1;
            ray_result->m_ArrayId = m_Tile + 1;
            ray_result->m_TileId = m_TileID;
            ray_result->m_Side = m_Side;
        }
    }

    void Reset()
    {
        m_Tilemap.SetSize(0);
        m_TargetTiles.Clear();
    }

    bool SetupCheck()
    {
        return (m_Tilemap.Size() > 0 && m_TargetTiles.Size() > 0);
    }

    inline bool BoundCheck(uint16_t tile_x, uint16_t tile_y)
    {
        return tile_x < m_Settings.m_Width && tile_y < m_Settings.m_Height;
    }

    void SetAt(uint16_t tile_x, uint16_t tile_y, uint16_t value)
    {
        if (BoundCheck(tile_x, tile_y))
        {
            uint32_t index = tile_y * m_Settings.m_Width + tile_x;
            m_Tilemap[index] = value;
        }
        else
        {
            dmLogError("Out of tilemap bounds. Tile X: %u -  Tile Y: %u - ", tile_x, tile_y);
        }
    }

    uint16_t GetAt(uint16_t tile_x, uint16_t tile_y)
    {
        if (BoundCheck(tile_x, tile_y))
        {
            uint32_t index = tile_y * m_Settings.m_Width + tile_x;
            return m_Tilemap[index];
        }
        else
        {
            dmLogError("Out of tilemap bounds. Tile X: %u -  Tile Y: %u - ", tile_x, tile_y);
        }

        return 0;
    }
} // namespace dda