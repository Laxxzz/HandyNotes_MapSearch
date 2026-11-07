-- WAAR-SCENARIO (runs in the harness, not the client; the linter skips this file)
-- Test-WowAddonRuntime.ps1 scenario for HandyNotes_MapSearch:
--   Test-WowAddonRuntime.ps1 <path>\HandyNotes_MapSearch -Scenario <path>\HandyNotes_MapSearch\tests\scenario.lua
H.slash("/mapsearch results 8")
H.expect(H.env.HandyNotes_MapSearchDB.maxResults == 8, "/mapsearch results 8 sets 8")
H.slash("/mapsearch results 99")
H.expect(H.env.HandyNotes_MapSearchDB.maxResults == 20, "/mapsearch results clamps to 20")
H.slash("/mapsearch results 0")
H.expect(H.env.HandyNotes_MapSearchDB.maxResults == 1, "/mapsearch results clamps to 1")
H.slash("/mapsearch status")
H.slash("/mapsearch")
