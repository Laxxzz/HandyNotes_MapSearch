# Lint warnings a clean run still prints

`Test-WowAddon.ps1 -StrictMethods` exits 0 with these warnings. Each stays for the reason
given; a warning not listed here is new and must be fixed or added.

| Warning | Why it stays |
|---|---|
| `UI.lua` assigns global `HandyNotesMapSearchPinMixin` | `Pins.xml` names it in `mixin=`, which resolves globals only. Prefixed with the addon name. |
| `Index.lua` global `LibStub` not found | Provided by HandyNotes (`## Dependencies: HandyNotes`), which embeds LibStub. |
| `:GetWorldCoordinatesFromZone()`, `:GetAzerothWorldMapCoordinatesFromWorld()`, `:GetAllMapIDs()`, `:GetPlayerWorldPosition()`, `:TranslateZoneCoordinates()` undeclared | HereBeDragons-2.0 methods, from HandyNotes' `Libs\HereBeDragons\HereBeDragons-2.0.lua` (MINOR 35); signatures checked there. |
| `:GetNodes2()`, `:getXY()` undeclared | HandyNotes plugin API and core helper, `HandyNotes.lua` (plugin documentation block, `HandyNotes:getXY`). |
| `MapCanvasPinMixin.OnReleased passed 1 argument(s)` | It is declared `function MapCanvasPinMixin:OnReleased()`; calling the base with `.` passes `self` explicitly. The linter counts `self` as an extra argument. |
