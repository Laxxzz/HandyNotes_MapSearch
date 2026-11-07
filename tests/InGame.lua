-- In-game tests for WAAR Probe: /waar test HandyNotes_MapSearch
-- Listed in the TOC between #@do-not-package@ markers, so release builds omit it.

local ADDON_NAME, ns = ...

WAAR_TESTS = WAAR_TESTS or {}

table.insert(WAAR_TESTS, { addon = ADDON_NAME, name = "saved variables initialised", fn = function(t)
    t:Ok(type(HandyNotes_MapSearchDB) == "table", "HandyNotes_MapSearchDB is a table")
    t:Equal(type(HandyNotes_MapSearchDB.maxResults), "number", "maxResults is a number")
    t:Equal(type(HandyNotes_MapSearchDB.blizzardPins), "boolean", "blizzardPins is a boolean")
end })

table.insert(WAAR_TESTS, { addon = ADDON_NAME, name = "options category registered", fn = function(t)
    t:Ok(type(ns.categoryID) == "number", "category ID captured")
end })

table.insert(WAAR_TESTS, { addon = ADDON_NAME, name = "search box exists on the world map", fn = function(t)
    t:Ok(HandyNotesMapSearchBox ~= nil, "HandyNotesMapSearchBox created")
end })
