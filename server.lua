-- ============================================================
--  restart_storm_qb  |  server.lua
--  Handles: storm start, cancel-restore, join-sync
-- ============================================================

local stormActive  = false   -- true once the storm has been triggered
local stormMode    = nil     -- the WeatherMode table in use

-- Snapshot of server state captured just before the storm starts,
-- so we can restore exactly what was running when cancelled.
local snapshot = {
    weather   = nil,    -- e.g. 'RAIN', 'CLOUDS', 'EXTRASUNNY' …
    blackout  = false,
    windSpeed = 0.0,
}

-- ============================================================
--  Internal helpers
-- ============================================================

local function getMode()
    local mode = Config.WeatherModes[Config.WeatherMode]
    if not mode then
        print('^1[restart_storm_qb] Unknown WeatherMode: ' .. tostring(Config.WeatherMode) .. '. Falling back to THUNDERSTORM.^0')
        mode = Config.WeatherModes['THUNDERSTORM']
    end
    return mode
end

local function applyWeather(mode)
    TriggerEvent('qb-weathersync:server:setWeather', mode.weather)

    if mode.enableBlackout then
        TriggerEvent('qb-weathersync:server:toggleBlackout', true)
    end

    if mode.windSpeed and mode.windSpeed > 0 then
        TriggerEvent('qb-weathersync:server:setWind', mode.windSpeed)
    end
end

-- Reads qb-weathersync exports before we overwrite its state.
-- Call this right before applyWeather().
local function captureSnapshot()
    local ok, weather = pcall(function()
        return exports['qb-weathersync']:getWeather()
    end)
    snapshot.weather = (ok and type(weather) == 'string' and weather ~= '') and weather or 'CLEAR'

    local okB, blackout = pcall(function()
        return exports['qb-weathersync']:getBlackout()
    end)
    snapshot.blackout = (okB and blackout == true)

    local okW, wind = pcall(function()
        return exports['qb-weathersync']:getWind()
    end)
    snapshot.windSpeed = (okW and type(wind) == 'number') and wind or 0.0

    print(string.format(
        '^3[restart_storm_qb] Snapshot captured — weather: %s | blackout: %s | wind: %.1f^0',
        snapshot.weather, tostring(snapshot.blackout), snapshot.windSpeed
    ))
end

local function restoreWeather()
    -- Restore exactly what was running before the storm.
    -- Falls back to CLEAR only if the snapshot was never populated.
    local w = snapshot.weather or 'CLEAR'
    print(string.format(
        '^3[restart_storm_qb] Restoring — weather: %s | blackout: %s | wind: %.1f^0',
        w, tostring(snapshot.blackout), snapshot.windSpeed
    ))

    TriggerEvent('qb-weathersync:server:setWeather', w)
    TriggerEvent('qb-weathersync:server:toggleBlackout', snapshot.blackout)
    TriggerEvent('qb-weathersync:server:setWind', snapshot.windSpeed)

    -- Clear snapshot so a stale state can't be restored twice
    snapshot.weather   = nil
    snapshot.blackout  = false
    snapshot.windSpeed = 0.0
end

-- ============================================================
--  Start storm
-- ============================================================

local function startStorm()
    if stormActive then return end
    stormActive = true
    stormMode   = getMode()

    print('^2[restart_storm_qb] Starting storm — mode: ' .. Config.WeatherMode .. '^0')

    captureSnapshot()   -- save current weather before overwriting it
    applyWeather(stormMode)

    if Config.EnableClientEffects then
        TriggerClientEvent('restart_storm_qb:startEffects', -1, stormMode, Config.RampUpSeconds)
    end
end

-- ============================================================
--  Stop storm  (cancel-restore)
-- ============================================================

local function stopStorm()
    if not stormActive then return end
    stormActive = false

    print('^3[restart_storm_qb] Restart cancelled — restoring weather.^0')

    restoreWeather()

    if Config.EnableClientEffects then
        TriggerClientEvent('restart_storm_qb:stopEffects', -1, Config.CancelFadeDuration)
    end

    stormMode = nil
end

-- ============================================================
--  txAdmin event handlers
-- ============================================================

AddEventHandler('txAdmin:events:scheduledRestart', function(eventData)
    local sec = tonumber(eventData.secondsRemaining or 0)

    -- Start storm at the configured threshold (fire-once guard is inside startStorm)
    if sec > 0 and sec <= Config.StartStormAtSeconds then
        startStorm()
    end
end)

-- txAdmin fires ONE of these two events when a restart is skipped/cancelled.
-- Both are handled because which one fires depends on the txAdmin version
-- and whether it was a 'skip next' or a full cancel from the dashboard.
AddEventHandler('txAdmin:events:scheduledRestartSkipped', function()
    stopStorm()
end)

AddEventHandler('txAdmin:events:skippedNextScheduledRestart', function()
    stopStorm()
end)

AddEventHandler('txAdmin:events:serverShuttingDown', function()
    startStorm()
end)

-- ============================================================
--  Join protection — sync storm to players who connect mid-storm
-- ============================================================

if Config.EnableJoinSync then
    AddEventHandler('playerJoining', function()
        if not stormActive or not stormMode then return end

        -- Wait one tick so the player's client is ready before sending the event
        local src = source
        SetTimeout(2000, function()
            if stormActive then
                TriggerClientEvent('restart_storm_qb:startEffects', src, stormMode, 0)
            end
        end)
    end)
end

-- ============================================================
--  Export: let other resources query storm state if needed
-- ============================================================

exports('isStormActive', function() return stormActive end)
exports('getStormMode',  function() return stormMode   end)
