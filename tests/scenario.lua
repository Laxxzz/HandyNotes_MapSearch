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
-- Not covered here: a secret tooltip line in the label scan. The harness has no HandyNotes or
-- HereBeDragons, so Index.lua builds nothing in it, and a scenario cannot reach the addon's
-- namespace. dev/test_index.lua fakes the plugin and the secret instead (see docs/testing.md).
H.slash("/mapsearch")
