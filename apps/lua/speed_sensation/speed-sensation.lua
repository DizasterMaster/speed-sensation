-- Script to dynamically adjust the cockpit FOV based on car speed and g-forces in Assetto Corsa
-- Author: dizastermasterr

local SIM = ac.getSim()
local DEFAULT_FOV = SIM.firstPersonCameraFOV

-- Default Settings
local DEFAULT_MIN_FOV = DEFAULT_FOV
local DEFAULT_MAX_FOV = DEFAULT_FOV + 30
local DEFAULT_MAX_SPEED = 300
local DEFAULT_G_FORCE_ENABLED = true
local DEFAULT_G_FORCE_FACTOR_MULTIPLIER = 0.05
local DEFAULT_G_FORCE_CURVE_EXPONENT = 1.5
local DEFAULT_G_FORCE_POSITIVE_FACTOR_Z_AXIS = 0.5
local DEFAULT_G_FORCE_NEGATIVE_FACTOR_Z_AXIS = 5
local DEFAULT_G_FORCE_SMOOTHING_FACTOR = 0.10
local DEFAULT_DECELERATION_OVERSHOOT_FACTOR = 10

-- Game Settings Storage (updated on each change)
-- Init with default settings
local AC_SETTINGS = ac.storage{
    enabled_cockpit = true,
    enabled_drivable = true,
    minFov = DEFAULT_MIN_FOV,
    maxFov = DEFAULT_MAX_FOV,
    maxSpeed = DEFAULT_MAX_SPEED,
    advancedSettings = false,
    gForceEnabled = DEFAULT_G_FORCE_ENABLED,
    gForceFactorMultiplier = DEFAULT_G_FORCE_FACTOR_MULTIPLIER,
    gForceCurveExponent = DEFAULT_G_FORCE_CURVE_EXPONENT,
    gForcePositiveFactor_Z_Axis = DEFAULT_G_FORCE_POSITIVE_FACTOR_Z_AXIS,
    gForceNegativeFactor_Z_Axis = DEFAULT_G_FORCE_NEGATIVE_FACTOR_Z_AXIS,
    gForceSmoothingFactor = DEFAULT_G_FORCE_SMOOTHING_FACTOR,
    decelerationOvershootFactor = DEFAULT_DECELERATION_OVERSHOOT_FACTOR
}

-- Settings in use
-- Separated from storage to improve performance by avoiding unnecessary read calls
local PLAYER_CAR_INDEX = 0
local ENABLED_COCKPIT = AC_SETTINGS.enabled_cockpit
local ENABLED_DRIVABLE = AC_SETTINGS.enabled_drivable
local MIN_FOV = AC_SETTINGS.minFov
local MAX_FOV = AC_SETTINGS.maxFov
local MAX_SPEED = AC_SETTINGS.maxSpeed
local ADVANCED_SETTINGS = AC_SETTINGS.advancedSettings
local G_FORCE_ENABLED = AC_SETTINGS.gForceEnabled
local G_FORCE_FACTOR_MULTIPLIER = AC_SETTINGS.gForceFactorMultiplier
local G_FORCE_CURVE_EXPONENT = AC_SETTINGS.gForceCurveExponent
local G_FORCE_POSITIVE_FACTOR_Z_AXIS = AC_SETTINGS.gForcePositiveFactor_Z_Axis
local G_FORCE_NEGATIVE_FACTOR_Z_AXIS = AC_SETTINGS.gForceNegativeFactor_Z_Axis
local G_FORCE_SMOOTHING_FACTOR = AC_SETTINGS.gForceSmoothingFactor
local DECELERATION_OVERSHOOT_FACTOR = AC_SETTINGS.decelerationOvershootFactor

-- FOV value from the previous frame
local PREVIOUS_FRAME_FOV = DEFAULT_MIN_FOV


-- Lowers the variance in FOV values between frames based on the smoothing factor
local function apply_smoothing(fov)
    if G_FORCE_ENABLED and G_FORCE_SMOOTHING_FACTOR > 0 then
        if math.abs(fov - PREVIOUS_FRAME_FOV) > G_FORCE_SMOOTHING_FACTOR then
            fov = PREVIOUS_FRAME_FOV + math.sign(fov - PREVIOUS_FRAME_FOV) * G_FORCE_SMOOTHING_FACTOR
        end
        -- Update previous frame FOV with the new value
        PREVIOUS_FRAME_FOV = fov
    end

    return fov
end

-- Clamps the FOV so it doesn't go outside of bounds
local function clamp_fov(fov)
    return math.max(MIN_FOV - DECELERATION_OVERSHOOT_FACTOR, math.min(fov, MAX_FOV))
end

-- Calculate g-force impact on FOV
local function calculate_fov_from_g_forces(fov, car_data)
    if G_FORCE_ENABLED then
        -- Get the acceleration/deceleration g-forces
        local g_forces_z_axis = car_data.acceleration.z
        -- Calculate the g-force factor
        local g_force_factor = 1 + math.abs(g_forces_z_axis) ^ G_FORCE_CURVE_EXPONENT * G_FORCE_FACTOR_MULTIPLIER

        if g_forces_z_axis > 0 then
            -- Increase the FOV based on positive g-forces
            fov = fov + g_forces_z_axis * G_FORCE_POSITIVE_FACTOR_Z_AXIS
        elseif g_forces_z_axis < 0 then
            -- Decrease the FOV based on negative g-forces
            fov = fov - math.abs(g_forces_z_axis) * G_FORCE_NEGATIVE_FACTOR_Z_AXIS
        end

        -- Apply the g-force factor for smoother transitions
        fov = fov * g_force_factor
    end

    return fov
end

-- Calculate the base FOV based on speed (as speed increases, FOV increases)
local function calculate_fov_from_speed(speed_kmh)
    return MIN_FOV + ((speed_kmh / MAX_SPEED) * (MAX_FOV - MIN_FOV))
end

local function adjust_fov(car_data)
    local speed_kmh = car_data.speedKmh

    local current_frame_fov = calculate_fov_from_speed(speed_kmh)
    current_frame_fov = calculate_fov_from_g_forces(current_frame_fov, car_data)
    current_frame_fov = clamp_fov(current_frame_fov)
    current_frame_fov = apply_smoothing(current_frame_fov)

    -- Set the camera FOV
    ac.setFirstPersonCameraFOV(current_frame_fov)
    ac.setCameraFOV(current_frame_fov)
end

local function should_adjust_fov()
    if (ENABLED_COCKPIT and SIM.cameraMode == ac.CameraMode.Cockpit) then
        return true
    elseif (ENABLED_DRIVABLE and SIM.cameraMode == ac.CameraMode.Drivable) then
        return true
    else
        return false
    end
end

-- Core
function script.update()
    local car_data = ac.getCar(PLAYER_CAR_INDEX)
    if (car_data and should_adjust_fov()) then
        adjust_fov(car_data)
    end
end


-- UI
function script.windowMain(dt)
    -- ENABLED
    if ui.checkbox('Enabled Cockpit', ENABLED_COCKPIT) then
        ENABLED_COCKPIT = not ENABLED_COCKPIT
        AC_SETTINGS.enabled_cockpit = ENABLED_COCKPIT
        if not ENABLED_COCKPIT then
            ac.setFirstPersonCameraFOV(DEFAULT_FOV)
        end
    end

    -- ENABLED DRIVABLE
    if ui.checkbox('Enabled Drivable', ENABLED_DRIVABLE) then
        ENABLED_DRIVABLE = not ENABLED_DRIVABLE
        AC_SETTINGS.enabled_drivable = ENABLED_DRIVABLE
        if not ENABLED_DRIVABLE then
            ac.setFirstPersonCameraFOV(DEFAULT_FOV)
        end
    end

    -- Basic Settings
    -- MIN_FOV
    local updatedMinFov = ui.slider('Minimum FOV', MIN_FOV, 20, 70, "%.0f")
    if ui.itemEdited() then
        MIN_FOV = updatedMinFov
        AC_SETTINGS.minFov = MIN_FOV
    end
    -- MAX_FOV
    local updatedMaxFov = ui.slider('Maximum FOV', MAX_FOV, 30, 120, "%.0f")
    if ui.itemEdited() then
        MAX_FOV = updatedMaxFov
        AC_SETTINGS.maxFov = MAX_FOV
    end
    -- MAX_SPEED
    local updatedMaxSpeed = ui.slider('Maximum Speed', MAX_SPEED, 10, 500, "%.0f")
    if ui.itemEdited() then
        MAX_SPEED = updatedMaxSpeed
        AC_SETTINGS.maxSpeed = MAX_SPEED
    end
    -- G_FORCE_ENABLE
    if ui.checkbox('Enable G-Force Effects', G_FORCE_ENABLED) then
        G_FORCE_ENABLED = not G_FORCE_ENABLED
        AC_SETTINGS.gForceEnabled = G_FORCE_ENABLED
    end
    -- ADVANCED_SETTINGS
    if ui.checkbox('Advanced Settings', ADVANCED_SETTINGS) then
        ADVANCED_SETTINGS = not ADVANCED_SETTINGS
        AC_SETTINGS.advancedSettings = ADVANCED_SETTINGS
    end

    -- Advanced Settings
    if ADVANCED_SETTINGS then
        -- G_FORCE_FACTOR_MULTIPLIER
        local updatedGforceFactorMultiplier = ui.slider('G-Force Factor Multiplier', G_FORCE_FACTOR_MULTIPLIER, 0, 0.1, "%.2f")
        if ui.itemEdited() then
            G_FORCE_FACTOR_MULTIPLIER = updatedGforceFactorMultiplier
            AC_SETTINGS.gForceFactorMultiplier = G_FORCE_FACTOR_MULTIPLIER
        end
        -- G_FORCE_CURVE_EXPONENT
        local updatedGforceCurveExponent = ui.slider('G-Force Curve Exponent', G_FORCE_CURVE_EXPONENT, 1, 2, "%.2f")
        if ui.itemEdited() then
            G_FORCE_CURVE_EXPONENT = updatedGforceCurveExponent
            AC_SETTINGS.gForceCurveExponent = G_FORCE_CURVE_EXPONENT
        end
        -- G_FORCE_POSITIVE_FACTOR_Z_AXIS
        local updatedGforceForwardFactorMultiplier = ui.slider('Acceleration Factor', G_FORCE_POSITIVE_FACTOR_Z_AXIS, 0, 1, "%.2f")
        if ui.itemEdited() then
            G_FORCE_POSITIVE_FACTOR_Z_AXIS = updatedGforceForwardFactorMultiplier
            AC_SETTINGS.gForcePositiveFactor_Z_Axis = G_FORCE_POSITIVE_FACTOR_Z_AXIS
        end
        -- G_FORCE_NEGATIVE_FACTOR_Z_AXIS
        local updatedGforceBackwardFactorMultiplier = ui.slider('Deceleration Factor', G_FORCE_NEGATIVE_FACTOR_Z_AXIS, 0, 10, "%.0f")
        if ui.itemEdited() then
            G_FORCE_NEGATIVE_FACTOR_Z_AXIS = updatedGforceBackwardFactorMultiplier
            AC_SETTINGS.gForceNegativeFactor_Z_Axis = G_FORCE_NEGATIVE_FACTOR_Z_AXIS
        end
        -- G_FORCE_SMOOTHING_FACTOR
        local updatedSmoothingFactor = ui.slider('Smoothing Factor Precision', G_FORCE_SMOOTHING_FACTOR, 0, 0.5, "%.2f")
        if ui.itemEdited() then
            G_FORCE_SMOOTHING_FACTOR = updatedSmoothingFactor
            AC_SETTINGS.gForceSmoothingFactor = G_FORCE_SMOOTHING_FACTOR
        end
        -- DECELERATION_OVERSHOOT_FACTOR
        local updatedDecelerationOvershootFactor = ui.slider('Deceleration Overshoot Factor', DECELERATION_OVERSHOOT_FACTOR, 0, 20, "%.0f")
        if ui.itemEdited() then
            DECELERATION_OVERSHOOT_FACTOR = updatedDecelerationOvershootFactor
            AC_SETTINGS.decelerationOvershootFactor = DECELERATION_OVERSHOOT_FACTOR
        end
    end

    if ui.button("Reset") then
        AC_SETTINGS.enabled_cockpit = true
        AC_SETTINGS.enabled_drivable = true
        AC_SETTINGS.minFov = DEFAULT_MIN_FOV
        AC_SETTINGS.maxFov = DEFAULT_MAX_FOV
        AC_SETTINGS.maxSpeed = DEFAULT_MAX_SPEED
        AC_SETTINGS.gForceEnabled = DEFAULT_G_FORCE_ENABLED
        AC_SETTINGS.gForceFactorMultiplier = DEFAULT_G_FORCE_FACTOR_MULTIPLIER
        AC_SETTINGS.gForcePositiveFactor_Z_Axis = DEFAULT_G_FORCE_POSITIVE_FACTOR_Z_AXIS
        AC_SETTINGS.gForceNegativeFactor_Z_Axis = DEFAULT_G_FORCE_NEGATIVE_FACTOR_Z_AXIS
        AC_SETTINGS.gForceCurveExponent = DEFAULT_G_FORCE_CURVE_EXPONENT
        AC_SETTINGS.gForceSmoothingFactor = DEFAULT_G_FORCE_SMOOTHING_FACTOR
        AC_SETTINGS.decelerationOvershootFactor = DEFAULT_DECELERATION_OVERSHOOT_FACTOR

        ENABLED_COCKPIT = true
        ENABLED_DRIVABLE = true
        MIN_FOV = DEFAULT_MIN_FOV
        MAX_FOV = DEFAULT_MAX_FOV
        MAX_SPEED = DEFAULT_MAX_SPEED
        G_FORCE_ENABLED = DEFAULT_G_FORCE_ENABLED
        G_FORCE_FACTOR_MULTIPLIER = DEFAULT_G_FORCE_FACTOR_MULTIPLIER
        G_FORCE_POSITIVE_FACTOR_Z_AXIS = DEFAULT_G_FORCE_POSITIVE_FACTOR_Z_AXIS
        G_FORCE_NEGATIVE_FACTOR_Z_AXIS = DEFAULT_G_FORCE_NEGATIVE_FACTOR_Z_AXIS
        G_FORCE_CURVE_EXPONENT = DEFAULT_G_FORCE_CURVE_EXPONENT
        G_FORCE_SMOOTHING_FACTOR = DEFAULT_G_FORCE_SMOOTHING_FACTOR
        DECELERATION_OVERSHOOT_FACTOR = DEFAULT_DECELERATION_OVERSHOOT_FACTOR
    end
end