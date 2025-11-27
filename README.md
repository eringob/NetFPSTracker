NetFPSTracker
=============

A tiny World of Warcraft addon that shows:
- FPS
- Home network latency (home)
- World server latency (world)

Features:
- Movable frame (drag with left mouse)
- Saved position across sessions
- Color-coded values: green/yellow/red thresholds
- Slash commands: `/netfps reset | show | hide`

Installation:
1. Copy the `NetFPSTracker` folder into your World of Warcraft `Interface\AddOns` folder.
2. Log into WoW or reload UI with `/reload`.

Usage:
- Drag the frame to move it.
- `/netfps reset` resets the frame to the center.
- `/netfps hide` hides the frame, `/netfps show` shows it again.

Notes:
- If your WoW client requires a different `## Interface:` number in the `.toc`, update the value in `NetFPSTracker.toc`.
- The addon uses `GetNetStats()` and `GetFramerate()` from the WoW API.
