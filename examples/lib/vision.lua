local data = require("examples.lib.data")
local const = require("examples.lib.const")

local vision = {}

-- Configuration
local VISION_DEBUG_DRAW = true     -- Draw vision cones for debugging
local VISION_CHECK_FREQUENCY = 0.1 -- How often to perform vision checks (seconds)

-- Vision parameters
local DEFAULT_FOV = 90                 -- Field of view in degrees
local DEFAULT_VISION_DISTANCE = 150    -- How far enemies can see
local DEFAULT_PERIPHERAL_DISTANCE = 50 -- Distance for peripheral vision (outside the cone)

-- Detection states
local STATE_IDLE = 1       -- Normal patrol
local STATE_SUSPICIOUS = 2 -- Saw something, investigating
local STATE_ALERT = 3      -- Target confirmed, attacking

-- Helper function to check if an angle is within a field of view
local function is_angle_in_fov(angle, facing_angle, fov)
    local diff = math.abs((angle - facing_angle + 180) % 360 - 180)
    return diff <= fov / 2
end

-- Add vision component to an entity
function vision.add_to_entity(entity, params)
    params = params or {}

    -- Create vision data
    entity.vision = {
        fov = params.fov or DEFAULT_FOV,
        distance = params.distance or DEFAULT_VISION_DISTANCE,
        peripheral_distance = params.peripheral_distance or DEFAULT_PERIPHERAL_DISTANCE,
        facing_angle = params.facing_angle or 0,
        state = STATE_IDLE,
        timer = 0,
        last_seen_position = nil,
        alert_level = 0,      -- 0-100, increases when seeing target
        detection_time = 0.5, -- Time needed to fully detect a target
        suspicion_timeout = 5 -- How long to stay suspicious
    }

    return entity.vision
end

-- Update the vision system for all entities
function vision.update(dt)
    for i, enemy in ipairs(data.enemies) do
        if enemy.vision then
            -- Only check vision periodically to save performance
            enemy.vision.timer = enemy.vision.timer + dt

            if enemy.vision.timer >= VISION_CHECK_FREQUENCY then
                enemy.vision.timer = 0

                -- Calculate facing direction based on angle
                local facing_rad = math.rad(enemy.vision.facing_angle)
                local facing_dir = vmath.vector3(math.cos(facing_rad), math.sin(facing_rad), 0)

                -- Check if player is in vision cone
                local to_player = data.player.position - enemy.position
                local distance_to_player = vmath.length(to_player)

                if distance_to_player <= enemy.vision.distance then
                    -- Calculate angle to player
                    local angle_to_player = math.deg(math.atan2(to_player.y, to_player.x))

                    -- Check if angle is within FOV
                    local is_in_fov = is_angle_in_fov(angle_to_player, enemy.vision.facing_angle, enemy.vision.fov)
                    local is_in_peripheral = distance_to_player <= enemy.vision.peripheral_distance

                    if is_in_fov or is_in_peripheral then
                        -- Check line of sight using raycast
                        local hit, _, _, _, _, _, _, _ = tile_raycast.cast(
                            enemy.position.x, enemy.position.y,
                            data.player.position.x, data.player.position.y
                        )

                        if not hit then
                            -- Clear line of sight to player!
                            enemy.vision.last_seen_position = vmath.vector3(data.player.position)

                            -- Increase alert level based on distance and whether in direct FOV
                            local detection_speed = 1.0
                            if is_in_peripheral and not is_in_fov then
                                detection_speed = 0.3 -- Slower detection in peripheral vision
                            end

                            -- Distance factor - closer means faster detection
                            local dist_factor = 1 - (distance_to_player / enemy.vision.distance)
                            detection_speed = detection_speed * (0.5 + dist_factor * 0.5)

                            -- Increase alert level
                            enemy.vision.alert_level = math.min(100, enemy.vision.alert_level +
                                (100 / enemy.vision.detection_time) * detection_speed * VISION_CHECK_FREQUENCY)

                            -- Update state based on alert level
                            if enemy.vision.alert_level >= 100 then
                                enemy.vision.state = STATE_ALERT
                            elseif enemy.vision.alert_level >= 50 then
                                enemy.vision.state = STATE_SUSPICIOUS
                            end
                        end
                    end
                end

                -- If target not seen, gradually decrease alert level
                if not enemy.vision.last_seen_position or
                    vmath.length(enemy.vision.last_seen_position - data.player.position) > 5 then
                    -- Decrease alert level
                    if enemy.vision.state == STATE_SUSPICIOUS then
                        enemy.vision.alert_level = math.max(0, enemy.vision.alert_level - 5 * VISION_CHECK_FREQUENCY)
                    elseif enemy.vision.state == STATE_ALERT then
                        enemy.vision.alert_level = math.max(0, enemy.vision.alert_level - 2 * VISION_CHECK_FREQUENCY)
                    end

                    -- Update state based on alert level
                    if enemy.vision.alert_level < 50 and enemy.vision.state == STATE_ALERT then
                        enemy.vision.state = STATE_SUSPICIOUS
                    elseif enemy.vision.alert_level <= 0 then
                        enemy.vision.state = STATE_IDLE
                        enemy.vision.last_seen_position = nil
                    end
                end

                -- Debug visualization
                if VISION_DEBUG_DRAW then
                    vision.draw_cone(enemy)
                end
            end
        end
    end
end

-- Draw debug visualization of the vision cone
function vision.draw_cone(enemy)
    local cone_segments = 10
    local angle_step = enemy.vision.fov / cone_segments
    local start_angle = enemy.vision.facing_angle - enemy.vision.fov / 2

    -- Draw vision cone
    for i = 0, cone_segments do
        local angle = start_angle + i * angle_step
        local rad = math.rad(angle)
        local dir = vmath.vector3(math.cos(rad), math.sin(rad), 0)
        local end_pos = enemy.position + dir * enemy.vision.distance

        -- Do raycast to find if this ray hits a wall
        local hit, _, _, _, _, hit_x, hit_y = tile_raycast.cast(
            enemy.position.x, enemy.position.y,
            end_pos.x, end_pos.y
        )

        -- Set ray end position based on raycast hit
        if hit then
            end_pos.x = hit_x
            end_pos.y = hit_y
        end

        -- Color based on state
        local color
        if enemy.vision.state == STATE_IDLE then
            color = vmath.vector4(0, 0.8, 0, 0.5)   -- Green
        elseif enemy.vision.state == STATE_SUSPICIOUS then
            color = vmath.vector4(0.8, 0.8, 0, 0.5) -- Yellow
        else                                        -- STATE_ALERT
            color = vmath.vector4(0.8, 0, 0, 0.5)   -- Red
        end

        -- Draw the ray
        msg.post("@render:", "draw_line", {
            start_point = enemy.position,
            end_point = end_pos,
            color = color
        })
    end

    -- Draw peripheral vision circle if in suspicious or alert state
    if enemy.vision.state > STATE_IDLE then
        -- Draw peripheral vision as a circle of points
        local peripheral_segments = 16
        local prev_point = nil

        for i = 0, peripheral_segments do
            local angle = (i / peripheral_segments) * 360
            local rad = math.rad(angle)
            local dir = vmath.vector3(math.cos(rad), math.sin(rad), 0)
            local point = enemy.position + dir * enemy.vision.peripheral_distance

            if prev_point then
                msg.post("@render:", "draw_line", {
                    start_point = prev_point,
                    end_point = point,
                    color = vmath.vector4(0.5, 0.5, 0.5, 0.3) -- Gray
                })
            end
            prev_point = point
        end
    end

    -- If enemy has seen the player, draw line to last seen position
    if enemy.vision.last_seen_position then
        msg.post("@render:", "draw_line", {
            start_point = enemy.position,
            end_point = enemy.vision.last_seen_position,
            color = vmath.vector4(1, 1, 1, 0.8) -- White
        })
    end
end

-- Set facing direction (in degrees, 0 = right, 90 = up)
function vision.set_facing(entity, angle)
    if entity.vision then
        entity.vision.facing_angle = angle
    end
end

-- Directly set vision state (for triggering alerts from other sources)
function vision.set_state(entity, state)
    if entity.vision then
        entity.vision.state = state
        if state == STATE_ALERT then
            entity.vision.alert_level = 100
        elseif state == STATE_SUSPICIOUS then
            entity.vision.alert_level = 60
        else
            entity.vision.alert_level = 0
        end
    end
end

-- Set last seen position (for scripted situations)
function vision.set_last_seen_position(entity, position)
    if entity.vision then
        entity.vision.last_seen_position = vmath.vector3(position)
    end
end

return vision
