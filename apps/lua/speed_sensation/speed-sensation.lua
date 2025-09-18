-- Script to dynamically adjust the FOV based on car speed and g-forces in Assetto Corsa
-- Author: dizastermasterr

local SIM = ac.getSim()
local DEFAULT_FOV_FP = SIM.firstPersonCameraFOV
local DEFAULT_FOV_TP = SIM.cameraFOV

-- Default Settings
local DEFAULT_MIN_FOV_FP = DEFAULT_FOV_FP
local DEFAULT_MAX_FOV_FP = DEFAULT_FOV_FP + 20
local DEFAULT_MAX_SPEED_FP = 250
local DEFAULT_MIN_FOV_TP = DEFAULT_FOV_TP
local DEFAULT_MAX_FOV_TP = DEFAULT_FOV_TP + 40
local DEFAULT_MAX_SPEED_TP = 250
local DEFAULT_G_FORCE_ENABLED = true
local DEFAULT_ADVANCED_SETTINGS = false
local DEFAULT_SPEED_CURVE_EXPONENT = 1
local DEFAULT_G_FORCE_FACTOR_MULTIPLIER = 0.01

-- Game Settings Storage (updated on each change)
-- Init with default settings
local AC_SETTINGS = ac.storage{
    enabledFp = true,
    minFovFp = DEFAULT_MIN_FOV_FP,
    maxFovFp = DEFAULT_MAX_FOV_FP,
    maxSpeedFp = DEFAULT_MAX_SPEED_FP,
    enabledTp = true,
    minFovTp = DEFAULT_MIN_FOV_TP,
    maxFovTp = DEFAULT_MAX_FOV_TP,
    maxSpeedTp = DEFAULT_MAX_SPEED_TP,
    gForceEnabled = DEFAULT_G_FORCE_ENABLED,
    advancedSettings = false,
    speedCurveExponent = DEFAULT_SPEED_CURVE_EXPONENT,
    gForceFactorMultiplier = DEFAULT_G_FORCE_FACTOR_MULTIPLIER
}

-- Settings in use
-- Separated from storage to improve performance by avoiding unnecessary read calls
local PLAYER_CAR_INDEX = 0
local DECELERATION_OVERSHOOT_FACTOR = 10
local ENABLED_FP = AC_SETTINGS.enabledFp
local MIN_FOV_FP = AC_SETTINGS.minFovFp
local MAX_FOV_FP = AC_SETTINGS.maxFovFp
local MAX_SPEED_FP = AC_SETTINGS.maxSpeedFp
local ENABLED_TP = AC_SETTINGS.enabledTp
local MIN_FOV_TP = AC_SETTINGS.minFovTp
local MAX_FOV_TP = AC_SETTINGS.maxFovTp
local MAX_SPEED_TP = AC_SETTINGS.maxSpeedTp
local G_FORCE_ENABLED = AC_SETTINGS.gForceEnabled
local ADVANCED_SETTINGS = AC_SETTINGS.advancedSettings
local SPEED_CURVE_EXPONENT = AC_SETTINGS.speedCurveExponent
local G_FORCE_FACTOR_MULTIPLIER = AC_SETTINGS.gForceFactorMultiplier

-- Clamps the FOV so it doesn't go outside of bounds
local function clamp_fov(fov, minFov, maxFov)
    return math.max(minFov - DECELERATION_OVERSHOOT_FACTOR, math.min(fov, maxFov))
end

-- Calculate g-force impact on FOV
local function calculate_fov_from_g_forces(fov, car_data)
    if G_FORCE_ENABLED then
        -- Get the acceleration/deceleration g-forces
        local g_forces_z_axis = car_data.acceleration.z
        -- Calculate the g-force factor
        local g_force_factor = 1 + math.abs(g_forces_z_axis) * G_FORCE_FACTOR_MULTIPLIER
        -- Apply the g-force factor for smoother transitions
        fov = fov * g_force_factor
    end

    return fov
end

-- Calculate the base FOV based on speed (as speed increases, FOV increases)
local function calculate_fov_from_speed(speed_kmh, minFov, maxFov, maxSpeed)
    local speedRatio = math.min(speed_kmh / maxSpeed, 1.0)
    local curvedRatio = math.pow(speedRatio, SPEED_CURVE_EXPONENT)
    return minFov + curvedRatio * (maxFov - minFov)
end

local function calculate_fov(car_data, minFov, maxFov, maxSpeed)
    local speed_kmh = car_data.speedKmh

    local current_frame_fov = calculate_fov_from_speed(speed_kmh, minFov, maxFov, maxSpeed)
    current_frame_fov = calculate_fov_from_g_forces(current_frame_fov, car_data)
    current_frame_fov = clamp_fov(current_frame_fov, minFov, maxFov)

    return current_frame_fov
end

local function is_external_cam()
    return SIM.driveableCameraMode == ac.DrivableCamera.Chase or SIM.driveableCameraMode == ac.DrivableCamera.Chase2
end

local function adjust_drivable_fov(car_data, currentCameraMode)
    local externalCam = is_external_cam()
    if (ENABLED_TP and externalCam) then
        ac.setCameraFOV(calculate_fov(car_data, MIN_FOV_TP, MAX_FOV_TP, MAX_SPEED_TP))
    elseif (ENABLED_FP and not externalCam) then
        ac.setCameraFOV(calculate_fov(car_data, MIN_FOV_FP, MAX_FOV_FP, MAX_SPEED_FP))
    end
end

local function adjust_cockpit_fov(car_data)
    if ENABLED_FP then
        ac.setFirstPersonCameraFOV(calculate_fov(car_data, MIN_FOV_FP, MAX_FOV_FP, MAX_SPEED_FP))
    end
end

local function adjust_all_fov(car_data, currentCameraMode)
    if (currentCameraMode == ac.CameraMode.Cockpit) then
        adjust_cockpit_fov(car_data)
    elseif (currentCameraMode == ac.CameraMode.Drivable) then
        adjust_drivable_fov(car_data, currentCameraMode)
    end
end

-- Core (called for each frame)
function script.update()
    local car_data = ac.getCar(PLAYER_CAR_INDEX)
    if (car_data and SIM) then
        adjust_all_fov(car_data, SIM.cameraMode)
    end
end


-- UI
function script.windowMain(dt)
    -- ENABLED FIRST PERSON FLAG
    if ui.checkbox('Enabled First Person', ENABLED_FP) then
        ENABLED_FP = not ENABLED_FP
        AC_SETTINGS.enabled_fp = ENABLED_FP
        if not ENABLED_FP then
            ac.setFirstPersonCameraFOV(DEFAULT_FOV_FP)
            ac.setCameraFOV(DEFAULT_FOV_TP)
        end
    end

    -- FIRST PERSON SETTINGS
    if ENABLED_FP then
        -- MINIMUM FOV
        local updatedMinFovFp = ui.slider('Minimum First Person FOV', MIN_FOV_FP, 20, 70, "%.0f")
        if ui.itemEdited() then
            MIN_FOV_FP = updatedMinFovFp
            AC_SETTINGS.minFovFp = MIN_FOV_FP
        end
        -- MAXIMUM FOV
        local updatedMaxFovFp = ui.slider('Maximum First Person FOV', MAX_FOV_FP, 30, 120, "%.0f")
        if ui.itemEdited() then
            MAX_FOV_FP = updatedMaxFovFp
            AC_SETTINGS.maxFovFp = MAX_FOV_FP
        end
        -- MAXIMUM SPEED
        local updatedMaxSpeedFp = ui.slider('Maximum First Person Speed', MAX_SPEED_FP, 100, 300, "%.0f")
        if ui.itemEdited() then
            MAX_SPEED_FP = updatedMaxSpeedFp
            AC_SETTINGS.maxSpeedFp = MAX_SPEED_FP
        end
    end

    -- ENABLED THIRD PERSON FLAG
    if ui.checkbox('Enabled Third Person', ENABLED_TP) then
        ENABLED_TP = not ENABLED_TP
        AC_SETTINGS.enabled_tp = ENABLED_TP
        if not ENABLED_TP then
            ac.setFirstPersonCameraFOV(DEFAULT_FOV_FP)
            ac.setCameraFOV(DEFAULT_FOV_TP)
        end
    end

    -- THIRD PERSON SETTINGS
    if ENABLED_TP then
        -- MINIMUM FOV
        local updatedMinFovTp = ui.slider('Minimum Third Person FOV', MIN_FOV_TP, 20, 70, "%.0f")
        if ui.itemEdited() then
            MIN_FOV_TP = updatedMinFovTp
            AC_SETTINGS.minFovTp = MIN_FOV_TP
        end
        -- MAXIMUM FOV
        local updatedMaxFovTp = ui.slider('Maximum Third Person FOV', MAX_FOV_TP, 30, 120, "%.0f")
        if ui.itemEdited() then
            MAX_FOV_TP = updatedMaxFovTp
            AC_SETTINGS.maxFovTp = MAX_FOV_TP
        end
        -- MAXIMUM SPEED
        local updatedMaxSpeedTp = ui.slider('Maximum Third Person Speed', MAX_SPEED_TP, 100, 300, "%.0f")
        if ui.itemEdited() then
            MAX_SPEED_TP = updatedMaxSpeedTp
            AC_SETTINGS.maxSpeedTp = MAX_SPEED_TP
        end
    end

    if ENABLED_FP or ENABLED_TP then
        -- G FORCE EFFECTS ENABLE FLAG
        if ui.checkbox('Enable G-Force Effects', G_FORCE_ENABLED) then
            G_FORCE_ENABLED = not G_FORCE_ENABLED
            AC_SETTINGS.gForceEnabled = G_FORCE_ENABLED
        end
        -- ADVANCED SETTINGS ENABLE FLAG
        if ui.checkbox('Advanced Settings', ADVANCED_SETTINGS) then
            ADVANCED_SETTINGS = not ADVANCED_SETTINGS
            AC_SETTINGS.advancedSettings = ADVANCED_SETTINGS
        end

        -- Advanced Settings
        if ADVANCED_SETTINGS then
            -- SPEED_CURVE_EXPONENT
            local updatedSpeedCurveExponent = ui.slider('Speed Curve Exponent', SPEED_CURVE_EXPONENT, 0.5, 1.5, "%.2f")
            if ui.itemEdited() then
                SPEED_CURVE_EXPONENT = updatedSpeedCurveExponent
                AC_SETTINGS.speedCurveExponent = SPEED_CURVE_EXPONENT
            end
            -- G_FORCE_FACTOR_MULTIPLIER
            local updatedGforceFactorMultiplier = ui.slider('G-Force Factor Multiplier', G_FORCE_FACTOR_MULTIPLIER, 0, 0.02, "%.3f")
            if ui.itemEdited() then
                G_FORCE_FACTOR_MULTIPLIER = updatedGforceFactorMultiplier
                AC_SETTINGS.gForceFactorMultiplier = G_FORCE_FACTOR_MULTIPLIER
            end
        end
    end


    if ui.button("Reset") then
        AC_SETTINGS.enabledFp = true
        AC_SETTINGS.minFovFp = DEFAULT_MIN_FOV_FP
        AC_SETTINGS.maxFovFp = DEFAULT_MAX_FOV_FP
        AC_SETTINGS.maxSpeedFp = DEFAULT_MAX_SPEED_FP
        AC_SETTINGS.enabledTp = true
        AC_SETTINGS.minFovTp = DEFAULT_MIN_FOV_TP
        AC_SETTINGS.maxFovTp = DEFAULT_MAX_FOV_TP
        AC_SETTINGS.maxSpeedTp = DEFAULT_MAX_SPEED_TP
        AC_SETTINGS.gForceEnabled = DEFAULT_G_FORCE_ENABLED
        AC_SETTINGS.advancedSettings = false
        AC_SETTINGS.speedCurveExponent = DEFAULT_SPEED_CURVE_EXPONENT
        AC_SETTINGS.gForceFactorMultiplier = DEFAULT_G_FORCE_FACTOR_MULTIPLIER

        ENABLED_FP = true
        MIN_FOV_FP = DEFAULT_MIN_FOV_FP
        MAX_FOV_FP = DEFAULT_MAX_FOV_FP
        MAX_SPEED_FP = DEFAULT_MAX_SPEED_FP
        ENABLED_TP = true
        MIN_FOV_TP = DEFAULT_MIN_FOV_TP
        MAX_FOV_TP = DEFAULT_MAX_FOV_TP
        MAX_SPEED_TP = DEFAULT_MAX_SPEED_TP
        G_FORCE_ENABLED = DEFAULT_G_FORCE_ENABLED
        ADVANCED_SETTINGS = DEFAULT_ADVANCED_SETTINGS
        SPEED_CURVE_EXPONENT = DEFAULT_SPEED_CURVE_EXPONENT
        G_FORCE_FACTOR_MULTIPLIER = DEFAULT_G_FORCE_FACTOR_MULTIPLIER
    end
end