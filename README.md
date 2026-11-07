# HandyNotes - MapSearch

A search box at the bottom of the world map for everything HandyNotes and its plugins
put on the map, plus the game's own flight points and dungeon entrances.

- **Live highlights**: as you type, every matching pin on the map you are looking at
  gets a yellow glow, updated with each keystroke.
- **Nearest first**: the list under the box shows the closest matches first, measured
  from where you stand, across every zone and continent, not just the open map.
- **Jump to it**: click a result, or use Up/Down and Enter, to open the map it is on.
  The chosen pin pulses green until you close the map.
- Escape or a click elsewhere closes the list.

Requires [HandyNotes](https://www.curseforge.com/wow/addons/handynotes). Made for
WoW: Forever, and runs on retail (12.1.5) too; one download serves both.

## Settings

`/mapsearch` opens the options (also under Options > AddOns > HandyNotes - MapSearch).

| Command | Effect |
|---|---|
| `/mapsearch results <1-20>` | How many matches the list shows (default 5) |
| `/mapsearch rebuild` | Re-read every map's pins now |
| `/mapsearch status` | How many pins are indexed and labelled |

The options panel also turns the flight point and dungeon entrance results off.

## How ranking works

1. Pins on the continent you are on, by distance in yards.
2. Pins on the other continent (Kalimdor or the Eastern Kingdoms), by distance on the
   Azeroth world map.
3. Anything with no comparable position (instances, and on retail Outland, Draenor,
   Shadowlands and other worlds, or when your own position is unknown, such as inside a
   dungeon), by name.

## How labels are found

HandyNotes' plugin API hands out positions and icons but no names. MapSearch reads every
map's pins in the background a few seconds after login (a few milliseconds per frame) and
takes each pin's name from the first line of the tooltip its plugin shows. The scan
borrows the game tooltip, so it pauses in combat and while you are looking at a tooltip.
A pin whose plugin draws no tooltip can still be found by its plugin's name. A tooltip
listing several places (a MapNotes entrance shared by two dungeons) is found by its
first line.

### For plugin authors

A plugin can name its pins directly, which is faster and exact. Add to your handler:

```lua
function pluginHandler:GetMapSearchLabel(uiMapID, coord)
    return "Forge" -- the text MapSearch should match and show
end
```

Only plugins using `GetNodes2` are indexed; the legacy `GetNodes` API is skipped.
