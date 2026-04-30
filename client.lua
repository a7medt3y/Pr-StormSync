-- ============================================================
--  restart_storm_qb  |  client.lua
--  Handles: camera shake, lightning, smooth ramp-up, fade-out
-- ============================================================

local effectsRunning  = false
local currentMode     = nil
local lightningTimer  = 0.0
local currentAmplitude = 0.0   -- actual amplitude applied this tick (used for ramp-up)

-- ============================================================
--  Start effects  (sent by server on storm start OR join-sync)
--    mode        : the WeatherMode table (shakeType, shakeAmplitude, lightningEvery)
--    rampSeconds : 0 = snap to full, >0 = ramp over N seconds
-- ============================================================

RegisterNetEvent('restart_storm_qb:startEffects', function(mode, rampSeconds)
    currentMode      = mode
    effectsRunning   = true
    lightningTimer   = 0.0
    currentAmplitude = (rampSeconds and rampSeconds > 0) and 0.0 or mode.shakeAmplitude

    -- Apply initial shake so players feel it immediately
    ShakeGameplayCam(mode.shakeType, currentAmplitude)
end)

-- ============================================================
--  Stop effects  (sent by server on cancel-restore)
--    fadeDuration : milliseconds to fade out over
-- ============================================================

RegisterNetEvent('restart_storm_qb:stopEffects', function(fadeDuration)
    if not effectsRunning then return end

    local startAmp  = currentAmplitude
    local steps     = 20
    local interval  = math.floor((fadeDuration or 3000) / steps)

    effectsRunning = false   -- signal main loop to stop

    -- Gradually reduce shake amplitude
    CreateThread(function()
        for i = 1, steps do
            Wait(interval)
            local amp = startAmp * (1.0 - (i / steps))
            if amp > 0 then
                ShakeGameplayCam(currentMode and currentMode.shakeType or 'LARGE_EXPLOSION_SHAKE', amp)
            else
                StopGameplayCamShaking(true)
            end
        end
        StopGameplayCamShaking(true)
        currentMode      = nil
        currentAmplitude = 0.0
    end)
end)

-- ============================================================
--  Main effect loop
-- ============================================================

CreateThread(function()
    while true do
        if not effectsRunning or not currentMode then
            Wait(1000)
        else
            Wait(250)

            local mode       = currentMode
            local targetAmp  = mode.shakeAmplitude

            -- Ramp-up: increase amplitude by a small step each tick until target is reached
            if currentAmplitude < targetAmp then
                -- Each 250ms tick, advance toward target over Config.RampUpSeconds
                local step = targetAmp / math.max(1, Config.RampUpSeconds * 4)
                currentAmplitude = math.min(currentAmplitude + step, targetAmp)
            end

            -- Re-apply shake if needed (GTA can cancel it internally)
            if not IsGameplayCamShaking() then
                ShakeGameplayCam(mode.shakeType, currentAmplitude)
            end

            -- Lightning
            if mode.lightningEvery and mode.lightningEvery > 0 then
                lightningTimer = lightningTimer + 0.25
                if lightningTimer >= mode.lightningEvery then
                    lightningTimer = 0.0
                    ForceLightningFlash()
                end
            end
        end
    end
end)
