# Design decisions

Each entry is deliberate. `CLAUDE.md` carries the one-line index; read the full entry here
before changing anything it names.

## 1. Labels come from tooltips

HandyNotes' plugin API returns coord, map and icon only. `Index.lua` calls each plugin's
`OnEnter` with a hidden owner frame, reads `GameTooltipTextLeft1` and hides the tooltip in the
same frame, so nothing renders. It scans only while `GameTooltip` is hidden and out of combat,
and `ClearLines()` first; any line afterwards is the plugin's. Never test `IsOwned(ourFrame)`:
HandyNotes_WoWForever anchors on `WorldMapFrame.ScrollContainer` and MapNotes may return
before `SetOwner`. A plugin may instead define `handler:GetMapSearchLabel(uiMapID, coord)`.

## 2. Flight points and dungeon entrances are optional sources

They are existence-checked and read in `pcall` per map (Forever has no reference); failures
count in `/mapsearch status`.

## 3. No yield inside `pcall`

Plugin iteration and label scans run inside `pcall` and the coroutine yields between them.

## 4. Highlights are our own pins

They come from our own `MapCanvasDataProviderMixin` provider. Never touch HandyNotes' pin
frames. The pin is mouse-disabled and overrides `CheckMouseButtonPassthrough` with a no-op
(HandyNotes does the same on its own pins).

## 5. Glow frame level `PIN_FRAME_LEVEL_DRAGONRIDING_RACE`

The level registered just below HandyNotes' `PIN_FRAME_LEVEL_AREA_POI`, so the glow sits
behind the icon.

## 6. Ranking tiers

Same instance by yards; other Azeroth continents by distance on the Azeroth world map (HBD
`GetAzerothWorldMapCoordinatesFromWorld`); the rest by name. Positions from `UnitPosition` go
through `issecretvalue` before arithmetic.

## 7. Selection lasts until the map closes

`EventRegistry` `WorldMapOnHide` clears the text, matches and chosen pin.

## 8. Rebuild triggers

Rebuilds are triggered by hooks on HandyNotes' `UpdatePluginMap` (what
`HandyNotes_NotifyUpdate` dispatches to) and `RegisterPluginDB`, debounced 2 s; labels are
cached per pin key across rebuilds.
