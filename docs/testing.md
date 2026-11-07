# In-game checks

Run every row on **WoW: Forever first**, then retail. `/console scriptErrors 1` first.
Each row is PASS or FAIL per client.

Setup: on Forever, HandyNotes_WoWForever and HandyNotes_MapNotes already put pins on the
map (treasures, dungeon entrances, boats and zeppelins). On retail, or for an extra test,
HandyNotes' own notes work: open the map, Alt+right-click a spot, give the note a title
(e.g. "Forge test"), and make two or three more with the same word in different zones
and on the other continent.

| # | Check | Expect |
|---|---|---|
| 1 | `/reload`, wait 15 s, `/mapsearch status` | "ready: N entries (...)", the list names each source with a count, most plugin pins labelled; note the "game pins failed" count |
| 2 | Open the map (M) | A search box with "Search map pins" at the bottom centre of the map area |
| 3 | Click the box, type one letter at a time | Matching pins on the open map glow yellow, updating with every keystroke; clearing the text removes all glows |
| 4 | Type a term with many matches (Forever: "zeppelin", "boat", a dungeon name) | The list shows 5 rows, closest first, named as the pin's tooltip names it; the right side shows the zone and yards for pins on your continent |
| 5 | `/mapsearch results 8`, reopen the map, search again | 8 rows; the options panel slider (`/mapsearch`) shows 8 |
| 6 | Search a term with matches in your zone, another zone of your continent and the other continent | Your zone's pins first, then the rest of your continent by yards, then the other continent (zone name only) |
| 7 | Press Down/Up, then Enter | The highlighted row moves (wrapping), Enter opens that pin's map and its pin pulses green |
| 8 | Click a result with the mouse | Same as 7 |
| 9 | Close the map and reopen it | The box is empty and no glow or green pin remains |
| 10 | With the list open, press Escape | The list closes, the map stays open; a second Escape closes the map |
| 11 | With the list open, click elsewhere on the map | The list closes |
| 12 | Enter combat (mob or target dummy), open the map, search, choose a result, close the map | No error, no "Interface action blocked"; with `/console taintLog 1`, `Logs\taint.log` names nothing of HandyNotes_MapSearch |
| 13 | Search "flight" or a flight master's town | Flight points of your faction appear (if "game pins failed" in row 1 is above 0, say so) |
| 14 | Hover a HandyNotes pin after the index finished | Its tooltip shows normally (the scan left the tooltip alone) |
| 15 | Optional, needs a non-English game language: switch the text language in the launcher, start the game | The box hint, list rows ("No matches", distances), options panel and `/ms help` are in that language; typing a name in lower case finds it written in upper case |
