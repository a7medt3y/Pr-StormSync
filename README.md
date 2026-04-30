# RT-StormSync

A FiveM resource that triggers a dramatic storm effect before a txAdmin-scheduled server restart — and cleanly restores the original weather if the restart is cancelled.

Built for **QBCore** with **qb-weathersync**.

---

## Features

- **4 weather modes** — Thunderstorm, Sandstorm, Heavy Rain, Apocalypse
- **Weather snapshot restore** — captures the server's exact weather, blackout, and wind state before the storm, then restores it precisely if the restart is skipped
- **Cancel detection** — listens to both txAdmin cancel events (`scheduledRestartSkipped` and `skippedNextScheduledRestart`)
- **Smooth ramp-up** — camera shake grows gradually from zero to full intensity
- **Smooth fade-out** — effects fade out over a configurable duration on cancel
- **Join sync** — players who connect mid-storm receive effects immediately
- **Server exports** — other resources can query storm state

---

## Requirements

| Dependency | Notes |
|---|---|
| [qb-weathersync](https://github.com/qbcore-framework/qb-weathersync) | Must expose `getWeather()`, `getBlackout()`, `getWind()` exports |
| [txAdmin](https://github.com/tabarra/txAdmin) | Provides the restart schedule events |
| FiveM server | `fx_version 'cerulean'` or higher |

---

## Installation

1. Drop the `RT-StormSync` folder into your `resources` directory
2. Add to your `server.cfg` — **after** `qb-weathersync`:
   ```
   ensure qb-weathersync
   ensure RT-StormSync 
   ```
3. Edit `config.lua` to choose your weather mode and timing
4. Restart the server or run `refresh` + `ensure RT-StormSync` in the console

---

## Configuration

All settings live in `config.lua`.

### Timing & general

```lua
Config.StartStormAtSeconds = 300   -- storm starts 5 min before restart
Config.WeatherMode         = 'THUNDERSTORM'  -- active mode key
Config.EnableClientEffects = true  -- camera shake + lightning on clients
Config.CancelFadeDuration  = 3000  -- ms to fade effects out on cancel
Config.EnableJoinSync      = true  -- sync storm to players who join late
Config.RampUpSeconds       = 15    -- seconds to ramp shake from 0 to full (0 = instant)
```

### Weather modes

| Mode | Weather | Blackout | Shake | Amplitude | Lightning | Wind |
|---|---|---|---|---|---|---|
| `THUNDERSTORM` | THUNDER | ✅ | LARGE_EXPLOSION | 0.20 | Every 8s | 30.0 |
| `SANDSTORM` | SMOG | ❌ | SKY_DIVING | 0.10 | Off | 60.0 |
| `HEAVY_RAIN` | XMAS | ❌ | SMALL_EXPLOSION | 0.08 | Every 20s | 15.0 |
| `APOCALYPSE` | FOGGY | ✅ | LARGE_EXPLOSION | 0.45 | Every 3s | 80.0 |

Switch mode with one line:
```lua
Config.WeatherMode = 'APOCALYPSE'
```

You can add your own custom mode by adding a new entry to `Config.WeatherModes` — no changes to `server.lua` or `client.lua` needed.

---

## How it works

### Normal restart flow

```
txAdmin: scheduledRestart (secondsRemaining <= 300)
    └── server: captureSnapshot()        -- save current weather/blackout/wind
    └── server: applyWeather()           -- switch to storm mode via qb-weathersync
    └── client: startEffects (all)       -- shake ramps up, lightning starts
Server restarts — effects end naturally
```

### Cancelled restart flow

```
txAdmin: scheduledRestartSkipped  (or skippedNextScheduledRestart)
    └── server: restoreWeather()         -- re-apply the snapshotted weather exactly
    └── client: stopEffects (all)        -- shake fades out over CancelFadeDuration ms
```

### Late join flow

```
playerJoining (during active storm)
    └── server waits 2s for client to load
    └── client: startEffects (that player only, rampSeconds = 0)
```

---

## Weather snapshot restore

Previous versions restored to a hardcoded `CLEAR` weather on cancel, overriding whatever the server was actually running. v2.0.0 fixes this.

Before the storm starts, the server reads three exports from `qb-weathersync`:

```lua
exports['qb-weathersync']:getWeather()   -- e.g. "RAIN"
exports['qb-weathersync']:getBlackout()  -- true/false
exports['qb-weathersync']:getWind()      -- e.g. 12.5
```

These are saved in a local `snapshot` table. On cancel, `restoreWeather()` re-applies the snapshot exactly and then clears it so it cannot fire twice.

Each call is wrapped in `pcall()` — if your version of `qb-weathersync` doesn't expose one of them, the script falls back safely:

| Export | Fallback |
|---|---|
| `getWeather()` | `"CLEAR"` |
| `getBlackout()` | `false` |
| `getWind()` | `0.0` |

---

## Server exports

Other resources can check storm state:

```lua
local active = exports['restart_storm_qb']:isStormActive()  -- boolean
local mode   = exports['restart_storm_qb']:getStormMode()   -- table or nil
```

---

## File structure

```
restart_storm_qb/
├── fxmanifest.lua   -- resource manifest
├── config.lua       -- all settings (shared between server and client)
├── server.lua       -- storm trigger, snapshot, cancel, join-sync, exports
└── client.lua       -- camera shake, lightning loop, ramp-up, fade-out
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Storm never starts | Confirm txAdmin is broadcasting `scheduledRestart`. Add a `print()` inside the handler to verify it fires. |
| Cancel doesn't stop the storm | Check the txAdmin console — you should see `scheduledRestartSkipped` or `skippedNextScheduledRestart`. Both are handled. |
| Weather restores to CLEAR after cancel | Your `qb-weathersync` version doesn't expose `getWeather()`. Add the export manually or check the resource version. |
| Late joiners don't get effects | Set `Config.EnableJoinSync = true`. Some frameworks rename `playerJoining` — check your framework's event name. |
| Camera shake doesn't stop after cancel | Increase `Config.CancelFadeDuration`. Very short values can race with the shake re-apply loop. |

---

## Changelog

### v2.0.0
- **Fix:** Weather restore now snapshots and re-applies the actual server state instead of hardcoding `CLEAR`
- **Fix:** Cancel detection now listens to the correct txAdmin events (`scheduledRestartSkipped`, `skippedNextScheduledRestart`)
- **New:** Four weather modes — Thunderstorm, Sandstorm, Heavy Rain, Apocalypse
- **New:** Smooth shake ramp-up (`Config.RampUpSeconds`) and fade-out (`Config.CancelFadeDuration`)
- **New:** Join sync for players who connect mid-storm
- **New:** `isStormActive()` and `getStormMode()` server exports
- **Improved:** All settings centralised in `config.lua`
- **Improved:** `pcall()` guard on all `qb-weathersync` export calls

### v1.0.0
- Initial release

---

## License

MIT — free to use and modify. Credit appreciated.
