# Quake III Arena — LiveSplit Autosplitter

ASL script (`Q3A_ASLR.asl`) for speedrunning the Quake III Arena single player campaign in [LiveSplit](https://livesplit.org/).

## Features

- **Auto start** — the timer starts as soon as you spawn on the first map.
- **Auto splits** — splits when each next campaign map starts.
- **Finish** — the final split triggers when you reach 10 frags on Q3TOURNEY6 (Xaero).
- **Load removal** — Game Time is paused while a map is loading.
- **Auto reset** — the run resets when you press **RESET** in the Single Player menu (save wipe) or start DM0 again.

## Supported versions

| Version | Status |
|---|---|
| Point Release 1.32 | tested |
| 1.32c | tested |
| Steam | tested |
| Versions older than 1.32 | not supported |
| ioquake3 and other source ports | not supported |

## Installation

1. Download `Q3A_ASLR.asl`.
2. In LiveSplit: right click → **Edit Layout…** → **+** → **Control** → **Scriptable Auto Splitter**.
3. Open the component settings (**Layout Settings** → **Scriptable Auto Splitter** tab) and set **Script Path** to `Q3A_ASLR.asl`.
4. Make sure **Start** and **Split** are checked.

## Splits setup

LiveSplit must have **exactly 26 splits** — one per campaign map. Split names don't matter (`DM6`, `The Camping Grounds`, etc.), only their count and order.

| Tier | Maps |
|---|---|
| 0 | DM0 |
| 1 | DM1, DM2, DM3, T1 |
| 2 | DM4, DM5, DM6, T2 |
| 3 | DM7, DM8, DM9, T3 |
| 4 | DM10, DM11, DM12, T4 |
| 5 | DM13, DM14, DM15, T5 |
| 6 | DM16, DM17, DM18, DM19, T6 |

A split triggers **on entering** the next map, i.e. it marks the end of the previous one. The run starts on DM0, so there is no split for entering it. The last, 26th split triggers on the 10th frag on T6.

### Splitting on some maps only

For example, for tier splits: in **Layout Settings** → **Scriptable Auto Splitter**, uncheck the maps you don't want to split on. The number of splits in LiveSplit should then equal the number of checked maps plus the final split. Start and finish work regardless of the checkboxes.

## Load removal (Game Time)

To exclude loading times, switch LiveSplit to Game Time:

1. Right click LiveSplit → **Compare Against** → **Game Time**.
2. Right click → **Edit Layout…** → **Layout Settings**:
   - **Splits** tab: set every **Timing Method** to **Game Time**;
   - **Timer** tab: set **Timing Method** to **Game Time**.

## Auto reset

The run is reset automatically (including a finished run):

- **Save wipe** — when you press **RESET** in the **Single Player** menu and confirm wiping the save. The save must contain progress (at least one map completed): wiping an already empty save changes nothing in the game and can't be detected. Setting: **Reset when Single Player save is reset**.
- **DM0 restart** — when DM0 is loaded again. This covers quitting DM0 to the menu and starting it over; the new run starts right away. Setting: **Reset when DM0 is loaded again**.

Both can be disabled in the script settings. The LiveSplit **Reset** checkbox doesn't affect them.

## How it works

The script reads from `quake3.exe` memory:

- **current map name** (`q3dm6.bsp`, etc.) — for splits;
- **client connection state**: `1` — menu, `2–7` — connecting and loading, `8` — in game. The timer starts on `8` and is paused on `2–7`;
- **player frag count** — for the final split.

For the reset, the script watches `baseq3\q3config.cfg` in the game folder. It stores the single player campaign progress (`g_spScores1–5`, `g_spAwards`, `g_spVideos`). The RESET button clears these values, the game immediately rewrites the config, and the script detects it.

## Credits

- **Original script** (auto splits, auto start, load removal, memory addresses): **liveth** — [resource on speedrun.com](https://www.speedrun.com/quake_3_arena/resources/644it). All rights to the original code belong to its author.
- **Modification**: auto reset on Single Player save wipe and DM0 restart, README.

## Known limitations

- The timer starts on **any** map load (not only DM0). If you reset the run while on a map, the timer starts again immediately. Go to the menu before resetting.
- Addresses for different game versions are checked simultaneously. On some builds this could theoretically cause false pauses or starts.
- The reset only works if `q3config.cfg` is located in the `baseq3` folder next to `quake3.exe`.
