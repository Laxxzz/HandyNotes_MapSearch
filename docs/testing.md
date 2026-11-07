# In-game checks

Retail client, `/console scriptErrors 1` first. Each row is PASS or FAIL.

Setup: make sure there is something to find. HandyNotes' own notes work: open the map,
Alt+right-click a spot, give the note a title (e.g. "Forge test"), and make two or three
more with the same word in different zones and on another continent. Flight points and
dungeon entrances are searchable without any setup ("flight", a city name, a dungeon name).

| # | Check | Expect |
|---|---|---|
| 1 | `/reload`, wait 10 s, `/mapsearch status` | "ready: N entries ..." with N > 0 |
| 2 | Open the map (M) | A search box with "Search map pins" at the bottom centre of the map area |
| 3 | Click the box, type one letter at a time | Matching pins on the open map glow yellow, updating with every keystroke; clearing the text removes all glows |
| 4 | Type a term with many matches | The list shows 5 rows, closest first; the right side shows the zone and yards for pins on your continent |
| 5 | `/mapsearch results 8`, reopen the map, search again | 8 rows; the options panel slider (`/mapsearch`) shows 8 |
| 6 | Search a term with matches on your zone, another zone of your continent and another continent | Your zone's pins first, then the rest of your continent by yards, then other continents (zone name only) |
| 7 | Press Down/Up, then Enter | The highlighted row moves (wrapping), Enter opens that pin's map and its pin pulses green |
| 8 | Click a result with the mouse | Same as 7 |
| 9 | Close the map and reopen it | The box is empty and no glow or green pin remains |
| 10 | With the list open, press Escape | The list closes, the map stays open; a second Escape closes the map |
| 11 | With the list open, click elsewhere on the map | The list closes |
| 12 | Enter combat (target dummy), open the map, search, choose a result, close the map | No error, no "Interface action blocked"; with `/console taintLog 1`, `Logs\taint.log` names nothing of HandyNotes_MapSearch |
| 13 | Search a HandyNotes plugin pin (once a plugin such as ProfessionStations is installed) | Found by the name its tooltip shows |
