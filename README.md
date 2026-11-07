<p align="center">
  <a href="https://discord.gg/simplelootcouncil"><img src="https://raw.githubusercontent.com/SimpleLootCouncil/media/main/addon-page/button-discord.png" alt="Discord"></a>
  <a href="https://ko-fi.com/laxxz"><img src="https://raw.githubusercontent.com/SimpleLootCouncil/media/main/addon-page/button-kofi.png" alt="Ko-fi"></a>
  <a href="https://github.com/Laxxzz/HandyNotes_MapSearch/issues"><img src="https://raw.githubusercontent.com/SimpleLootCouncil/media/main/addon-page/button-issue.png" alt="Report an issue"></a>
</p>

**HandyNotes: MapSearch** is a world map search bar for **Retail and WoW: Forever**. Type a name and every matching HandyNotes pin, flight point and dungeon entrance lights up on the map, with the nearest results first.

## Features

- Live yellow highlights as you type
- Nearest results first, across every zone and continent
- Click a result, or use Up, Down and Enter, to open its map
- Your chosen pin pulses until you close the map
- Searches HandyNotes plugin pins, flight points and dungeon entrances
- Adjustable result count

## Languages

Translated into every language World of Warcraft supports: English, German, French, Spanish (Spain and Latin America), Italian, Brazilian Portuguese, Russian, Korean, and Simplified and Traditional Chinese. Search ignores case in all of them, including accented and Cyrillic letters. The translations are machine-made drafts; corrections from native speakers are welcome.

## Getting Started

Requires [HandyNotes](https://www.curseforge.com/wow/addons/handynotes). Install it, then `/reload`. The search box sits at the bottom of the world map. Type `/mapsearch` (or `/ms`) for settings, also found under Options > AddOns > HandyNotes: MapSearch.

| Command | Effect |
|---|---|
| `/mapsearch results <1-20>` | How many matches the list shows (default 5) |
| `/mapsearch rebuild` | Re-read every map's pins now |
| `/mapsearch status` | How many pins are indexed and labelled |

The options panel also turns the flight point and dungeon entrance results off.

## How results are ranked

1. Pins on the continent you are on, by distance in yards.
2. Pins on the other continent, by distance on the Azeroth world map.
3. Anything with no comparable position (instances, other worlds, or when your own position is unknown), by name.

## For plugin authors

HandyNotes hands out positions and icons but no names, so MapSearch reads each pin's name from the first line of its tooltip a few seconds after login. A plugin can name its pins directly, which is faster and exact:

```lua
function pluginHandler:GetMapSearchLabel(uiMapID, coord)
    return "Forge" -- the text MapSearch should match and show
end
```

Only plugins using `GetNodes2` are indexed; the legacy `GetNodes` API is skipped.

## AI Use

Claude was used in the development of this addon with a custom-built addon development tool constructed from Blizzard's API patch notes.

## Support

HandyNotes: MapSearch is free. If it saves you hunting across the map, you can support its development.

<p align="center"><a href="https://ko-fi.com/laxxz"><img src="https://raw.githubusercontent.com/SimpleLootCouncil/media/main/addon-page/button-kofi.png" alt="Support Laxx on Ko-fi"></a></p>

## Licence

See [LICENSE](LICENSE).
