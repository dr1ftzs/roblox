# Escape Game Room Styling

## Visual Style
Ambient tuning for room look/feel lives in `src/ReplicatedStorage/EscapeGame/Config.lua` under `Config.VisualStyle`.
Adjust wood palettes, warm light color/brightness ranges, prop spawn densities, and optional floor/wall/ceiling texture IDs there.
The defaults are intentionally *inspired by* classic moody hotel-horror interiors without directly copying another game's assets.

## Game Mode Constants
Use `Config.Modes.Timed` / `Config.Modes.Endless` for controller checks (for example: `if mode ~= Config.Modes.Endless then ...`).

## Auto Runtime Bootstrap
`src/ServerScriptService/EscapeGameBootstrap.server.lua` now creates `Workspace.EscapeRuntime` on server start and builds a playable chain of rooms connected by hallways.
Tune stage count with `Config.Defaults.InitialStageCount` and hallway size with `Config.Hallway`.
