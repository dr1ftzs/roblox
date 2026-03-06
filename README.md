# Roblox Escape (Progressive Rooms)

This repository contains a Roblox Lua prototype for the **Escape** DevForum concept with progressive rooms, scalable puzzles, and monetization hooks.

## Implemented systems

- **Full HUD:** status line, live timer, and room counter.
- **Procedural layout generation:** rooms still progress forward, but each room now gets randomized obstacle layouts.
- **Puzzle modules:**
  - Stage 1 onboarding auto-open.
  - Hold button puzzle.
  - Sequence puzzle.
  - Fake button puzzle.
  - Timed gate/door puzzle.
  - Maze goal puzzle.
- **Leaderboard system:** in-game `leaderstats` for best stage and best run time, with best-stage DataStore persistence.
- **Polished doors:** tweened open/close movement for room exit doors.
- **Modes:** timed and endless mode toggle with `M`.
- **Monetization hooks:** developer products for room skip and time boost.

## File layout

- `src/ReplicatedStorage/EscapeGame/Config.lua`
- `src/ReplicatedStorage/EscapeGame/RoomBuilder.lua`
- `src/ReplicatedStorage/EscapeGame/PuzzleService.lua`
- `src/ServerScriptService/GameController.server.lua`
- `src/StarterPlayer/StarterPlayerScripts/EscapeHud.client.lua`

## Setup in Roblox Studio

1. Open your place.
2. Create folders/services and paste scripts into matching paths:
   - `ReplicatedStorage/EscapeGame` (ModuleScripts from `src/ReplicatedStorage/EscapeGame`)
   - `ServerScriptService` (`GameController.server.lua`)
   - `StarterPlayer/StarterPlayerScripts` (`EscapeHud.client.lua`)
3. Enable Studio API services if you want DataStore persistence for leaderboard best stage.
4. (Optional) Create two Developer Products and set:
   - `Monetization.Products.SkipRoom.ProductId`
   - `Monetization.Products.TimeBoost.ProductId`
5. Press Play.
6. Use **M** to toggle Timed/Endless mode.

## Notes

- Product IDs left as `0` safely disable purchase prompts.
- Timed mode grants bonus time on room clears.
- Endless mode disables the countdown timer but still tracks stage progression.
