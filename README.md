# Roblox Escape (Progressive Rooms)

This repository contains a Roblox Lua prototype for the **Escape** DevForum concept:

- You begin in a tiny room with one door.
- Each cleared room leads to a slightly bigger room.
- Puzzles grow in complexity as stage increases.
- Includes:
  - **Timed mode** (clock pressure + reset on timeout)
  - **Endless mode** (no timeout, infinite progression)

## What is implemented

- **Stage 1**: Door opens immediately (teaches core loop).
- **Stage 2**: Hold-to-open button puzzle.
- **Stage 3+**: Increasing-length sequence puzzle.
- Procedural room generation with size scaling.
- Runtime HUD and mode switching (`M` key).
- Best-time tracking in timed runs.

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
3. Press Play.
4. Use **M** to toggle Timed/Endless mode.

## Design notes

- The generator currently builds rooms in a line along the Z axis.
- Puzzle logic is intentionally modular for adding more puzzle types (lights, levers, code pads, etc.).
- Timed mode grants bonus time per clear and resets when time expires.

