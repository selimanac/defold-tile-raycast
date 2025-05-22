local data   = require("examples.scripts.data")
local const  = require("examples.scripts.const")
local debug  = require("examples.scripts.debug")

local vision = {}

local function is_angle_in_fov(angle, facing_angle, fov)
    local diff = math.abs((angle - facing_angle + 180) % 360 - 180)
    return diff <= fov / 2
end

-- Add vision component to an entity
function vision.add_to_entity(entity, params)
    params = params or {}

    -- Create vision data
    entity.vision = {
        fov = params.fov or const.VISION.FOV,
        distance = params.distance or const.VISION.DISTANCE,
        peripheral_distance = params.peripheral_distance or const.VISION.PERIPHERAL_DISTANCE,
        facing_angle = params.facing_angle or 0,
        state = const.VISION.STATE.IDLE,

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

            if enemy.vision.timer >= const.VISION.CHECK_FREQUENCY then
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
                            local detection_speed = const.VISION.PERIPHERAL_DETECTION_SPEED
                            if is_in_peripheral and not is_in_fov then
                                detection_speed = const.VISION.SLOW_PERIPHERAL_DETECTION_SPEED -- Slower detection in peripheral vision
                            end

                            -- Distance factor - closer means faster detection
                            local dist_factor = 1 - (distance_to_player / enemy.vision.distance)
                            detection_speed = detection_speed * (0.5 + dist_factor * 0.5)

                            -- Increase alert level
                            enemy.vision.alert_level = math.min(100, enemy.vision.alert_level +
                                (100 / enemy.vision.detection_time) * detection_speed * const.VISION.CHECK_FREQUENCY)

                            -- Update state based on alert level
                            if enemy.vision.alert_level >= 100 then
                                enemy.vision.state = const.VISION.STATE.ALERT
                            elseif enemy.vision.alert_level >= 50 then
                                enemy.vision.state = const.VISION.STATE.WARNING
                            end
                        end
                    end
                end

                -- If target not seen, gradually decrease alert level
                if not enemy.vision.last_seen_position or
                    vmath.length(enemy.vision.last_seen_position - data.player.position) > 5 then
                    -- Decrease alert level
                    if enemy.vision.state == const.VISION.STATE.WARNING then
                        enemy.vision.alert_level = math.max(0, enemy.vision.alert_level - 15 * const.VISION.CHECK_FREQUENCY)
                    elseif enemy.vision.state == const.VISION.STATE.ALERT then
                        enemy.vision.alert_level = math.max(0, enemy.vision.alert_level - 12 * const.VISION.CHECK_FREQUENCY)
                    end

                    -- Update state based on alert level
                    if enemy.vision.alert_level < 50 and enemy.vision.state == const.VISION.STATE.ALERT then
                        enemy.vision.state = const.VISION.STATE.WARNING
                    elseif enemy.vision.alert_level <= 0 then
                        enemy.vision.state = const.VISION.STATE.IDLE
                        enemy.vision.last_seen_position = nil
                    end
                end
            end
        end
        -- Debug visualization
        if data.debug then
            debug.draw_cone(enemy)
        end
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
        if state == const.VISION.STATE.ALERT then
            entity.vision.alert_level = 100
        elseif state == const.VISION.STATE.WARNING then
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
