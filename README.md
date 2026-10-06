# <img src="kelvinlogo.png" width="32" height="32" valign="middle"> Kelvin

A lightweight background tool (around 2 MB of RAM) that launches MSI Afterburner and RTSS only when you play games, and closes them when you're done.

## Features
- **Auto Launch & Close:** Starts Afterburner and RTSS when a target game opens, shuts them down when you exit.
- **No Background Clutter:** Only closes apps if Kelvin opened them first.
- **Auto-Config:** Finds Afterburner and RTSS paths in the Windows Registry automatically.
- **Anti-Cheat Safe:** Automatically shuts down if Riot Client is running to avoid Vanguard flags.

---

## Configuration (`settings.ini`)

Generated automatically on the first run.

### `[Settings]`
- `KillAfterburnerOnStart` (`1`): Close Afterburner on launch if it's already open.
- `CheckInterval` (`5000`): How often to check for running games in ms (5000 = 5s).
- `WaitForRTSSToOpen` (`10`): Seconds to wait for RTSS before force-launching.
- `ForceLaunchRTSS` (`1`): Launch RTSS manually if Afterburner doesn't start it.
- `MaxCloseAttempts` (`6`): Number of close signals sent before giving up on Afterburner.
- `CloseIfRiotClient` (`1`): Instantly exits Kelvin if Riot Client is detected.

### `[Paths]`
Leave these blank. Kelvin auto-detects them via the Registry. Only fill them manually if you use portable installs.

### `[Targets]`
Add your game executables here (one per line):

```ini
[Targets]
1=cs2.exe
2=plutonium.exe
3=javaw.exe
