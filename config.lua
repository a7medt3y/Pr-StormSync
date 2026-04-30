Config = {}

-- ============================================================
--  TIMING
-- ============================================================

-- How many seconds before the restart the storm begins
Config.StartStormAtSeconds = 300   -- 5 minutes

-- ============================================================
--  WEATHER MODE
-- Set Config.WeatherMode to one of the keys below.
-- Each mode controls weather type, blackout, shake and lightning.
-- ============================================================

Config.WeatherMode = 'THUNDERSTORM'   -- THUNDERSTORM | SANDSTORM | HEAVY_RAIN | APOCALYPSE

Config.WeatherModes = {
    THUNDERSTORM = {
        weather        = 'THUNDER',
        enableBlackout = true,
        shakeType      = 'LARGE_EXPLOSION_SHAKE',
        shakeAmplitude = 0.20,
        lightningEvery = 8,       -- seconds between lightning flashes (0 = disabled)
        windSpeed      = 30.0,
    },
    SANDSTORM = {
        weather        = 'SMOG',
        enableBlackout = false,
        shakeType      = 'SKY_DIVING_SHAKE',
        shakeAmplitude = 0.10,
        lightningEvery = 0,
        windSpeed      = 60.0,
    },
    HEAVY_RAIN = {
        weather        = 'XMAS',   -- heavy rain in qb-weathersync
        enableBlackout = false,
        shakeType      = 'SMALL_EXPLOSION_SHAKE',
        shakeAmplitude = 0.08,
        lightningEvery = 20,
        windSpeed      = 15.0,
    },
    APOCALYPSE = {
        weather        = 'FOGGY',
        enableBlackout = true,
        shakeType      = 'LARGE_EXPLOSION_SHAKE',
        shakeAmplitude = 0.45,
        lightningEvery = 3,
        windSpeed      = 80.0,
    },
}

-- ============================================================
--  CLIENT EFFECTS
-- ============================================================

-- Enable camera shake + lightning on all clients
Config.EnableClientEffects = true

-- How long (ms) the stop-effects fade takes when storm is cancelled
Config.CancelFadeDuration = 3000   -- 3 seconds

-- ============================================================
--  JOIN PROTECTION
-- Players who connect during an active storm receive effects immediately
-- ============================================================

Config.EnableJoinSync = true

-- ============================================================
--  TRANSITION
-- Smooth ramp-up: shake amplitude grows from 0 to full over this many seconds
-- Set to 0 to disable the ramp and snap to full intensity immediately
-- ============================================================

Config.RampUpSeconds = 15
