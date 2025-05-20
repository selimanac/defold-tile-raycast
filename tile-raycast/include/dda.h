#ifndef DDA_H
#define DDA_H

#include "dmsdk/dlib/array.h"
#include <cstdint>

namespace dda
{
    struct Vec2
    {
        float x;
        float y;
    };

    struct Vec2Int
    {
        int x;
        int y;
    };

    enum Side
    {
        LEFT = 0,
        RIGHT = 1,
        TOP = 2,
        BOTTOM = 3
    };

    struct RayResult
    {
        bool     m_TileFound;
        uint16_t m_TileX;
        uint16_t m_TileY;
        uint16_t m_ArrayId;
        uint16_t m_TileId;
        Vec2     m_Intersection;
        Side     m_Side;
    };

    struct Settings
    {
        uint16_t m_TileWidth;
        uint16_t m_TileHeight;
        uint16_t m_Width;
        uint16_t m_Height;
    };

    void Init(const uint16_t tile_width, const uint16_t tile_height, const uint16_t map_width, const uint16_t map_height, const dmArray<uint16_t>* tile_map, const dmArray<uint16_t>* target_tiles);
    void RayCast(const dda::Vec2* ray_start, const dda::Vec2* ray_end, RayResult* ray_result);
    void Reset();

    bool SetupCheck();
} // namespace dda

#endif
