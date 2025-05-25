#ifndef DDA_H
#define DDA_H

#include "dmsdk/dlib/array.h"

namespace dda
{
    enum Side
    {
        LEFT = 0,
        RIGHT = 1,
        TOP = 2,
        BOTTOM = 3
    };

    typedef struct Vec2
    {
        float x;
        float y;
    } Vec2;

    typedef struct RayResult
    {
        bool     m_TileFound;
        uint16_t m_TileX;
        uint16_t m_TileY;
        uint16_t m_ArrayId;
        uint16_t m_TileId;
        Vec2     m_Intersection;
        Side     m_Side;
    } RayResult;

    inline float DistanceSquared(const Vec2* v1, const Vec2* v2)
    {
        return (v2->x - v1->x) * (v2->x - v1->x) + (v2->y - v1->y) * (v2->y - v1->y);
    }

    void     Init(const uint16_t tile_width, const uint16_t tile_height, const uint16_t map_width, const uint16_t map_height, const dmArray<uint16_t>* tile_map, const dmArray<uint16_t>* target_tiles);
    void     RayCast(const dda::Vec2* ray_start, const dda::Vec2* ray_end, RayResult* ray_result);
    void     Reset();
    bool     SetupCheck();
    void     SetAt(uint16_t tile_x, uint16_t tile_y, uint16_t value);
    uint16_t GetAt(uint16_t tile_x, uint16_t tile_y);

} // namespace dda

#endif
