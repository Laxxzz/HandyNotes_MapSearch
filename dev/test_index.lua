-- Offline test of the label scan in Index.lua when a label is a secret value (Lua 5.1):
--   lua5.1 dev/test_index.lua [path\to\Index.lua]   (run from the addon root; exit 0 = pass)
-- tests/scenario.lua cannot do this: the harness has no HandyNotes or HereBeDragons, so
-- Index.lua builds nothing there, and a scenario cannot reach the addon's private namespace.
-- Here a fake HandyNotes plugin draws a plain tooltip, a tooltip whose first line is a secret,
-- and returns a secret from GetMapSearchLabel; a secret behaves like retail's: type() says
-- "string", but indexing or comparing it raises.

local indexPath = ... -- optional: another Index.lua to test (e.g. the committed one, to see the old bug)
local errors, failures = {}, 0
local function check(ok, what)
    if not ok then failures = failures + 1; print("FAIL " .. what) end
end

local function NewSecret()
    local s = newproxy(true)
    getmetatable(s).__index = function() error("attempt to index a secret string value", 2) end
    getmetatable(s).__eq = function() error("attempt to compare a secret string value", 2) end
    return s
end
local secrets = {}
local function IsSecret(v) return secrets[v] == true end
_G.issecretvalue = IsSecret
-- type() reports "string" for a real secret string; the stand-in userdata must too.
local realType = type
_G.type = function(v) if secrets[v] then return "string" end return realType(v) end

local function Frame()
    local f = { scripts = {} }
    return setmetatable(f, { __index = function(t, k)
        if k == "SetScript" then return function(self, name, fn) self.scripts[name] = fn end end
        return function() end
    end })
end
_G.CreateFrame = Frame
_G.UIParent = Frame()
_G.debugprofilestop = function() return 0 end
_G.InCombatLockdown = function() return false end
_G.GetTime = function() return 0 end
_G.strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
_G.UnitFactionGroup = function() return "Alliance" end
_G.Enum = { UIMapType = { Zone = 1 } }
_G.C_Map = { GetMapInfo = function() return { name = "Map", mapType = 1 } end }
_G.C_Timer = { After = function() end }
_G.hooksecurefunc = function() end
_G.geterrorhandler = function() return function(err) errors[#errors + 1] = err end end
_G.HandyNotes_MapSearchDB = { blizzardPins = false }

-- A tooltip with one line, set by the plugin's OnEnter.
local tooltip = { lines = 0, text = nil }
_G.GameTooltip = {
    ClearLines = function() tooltip.lines, tooltip.text = 0, nil end,
    NumLines = function() return tooltip.lines end,
    IsShown = function() return false end,
    Hide = function() end,
}
_G.GameTooltipTextLeft1 = { GetText = function() return tooltip.text end }

local COORDS = { 1, 2, 3, 4 } -- 1 plain, 2 secret tooltip line, 3 secret GetMapSearchLabel, 4 plain with colour codes
local secretLine, secretLabel = NewSecret(), NewSecret()
secrets[secretLine], secrets[secretLabel] = true, true
local scans = {}

local handler = {
    GetNodes2 = function()
        local i = 0
        return function() i = i + 1; if COORDS[i] then return COORDS[i], 1, "icon" end end
    end,
    OnEnter = function(_, _, coord)
        scans[coord] = (scans[coord] or 0) + 1
        tooltip.lines = 1
        if coord == 1 then tooltip.text = "Plain"
        elseif coord == 2 then tooltip.text = secretLine
        else tooltip.text = "|cff00ff00Coloured|r" end
    end,
    GetMapSearchLabel = function(self, _, coord)
        if coord == 3 then return secretLabel end
        error("no label")  -- falls through to the tooltip scan
    end,
}
local HN = {
    IsEnabled = function() return true end,
    db = { profile = { enabledPlugins = { P = true } } },
    plugins = { P = handler },
    getXY = function() return 0.5, 0.5 end,
}
local HBD = {
    GetAllMapIDs = function() return { 1 } end,
    GetWorldCoordinatesFromZone = function() return 0, 0, 0 end,
    GetAzerothWorldMapCoordinatesFromWorld = function() return 0, 0 end,
}
_G.LibStub = function(name)
    if name == "HereBeDragons-2.0" then return HBD end
    if name == "AceAddon-3.0" then return { GetAddon = function() return HN end } end
end

-- The driver is the frame Index.lua gives an OnUpdate script.
local drivers = {}
_G.CreateFrame = function()
    local f = Frame()
    drivers[#drivers + 1] = f
    return f
end
local ns = {}
_G.GetLocale = function() return "enUS" end
assert(loadfile("Locale.lua"))("HandyNotes_MapSearch", ns)
assert(loadfile(indexPath or "Index.lua"))("HandyNotes_MapSearch", ns)
local Index = ns.Index
local driver
for _, f in ipairs(drivers) do if f.scripts.OnUpdate then driver = f end end
assert(driver, "Index.lua registered no OnUpdate driver")

Index.Start()
for _ = 1, 50 do
    if not Index.building then break end
    driver.scripts.OnUpdate(driver)
end

check(#errors == 0, "no error from the build: " .. tostring(errors[1]))
check(Index.built and Index.phase == "done", "the build ran to the end (phase " .. tostring(Index.phase) .. ")")
local byCoord = {}
for _, e in ipairs(Index.entries) do byCoord[e.coord] = e end
check(byCoord[1] and byCoord[1].label == "Plain", "plain tooltip is labelled")
check(byCoord[4] and byCoord[4].label == "Coloured", "colour codes stripped")
check(byCoord[2] and byCoord[2].label == nil and byCoord[2].secret, "secret tooltip line is no label")
check(byCoord[3] and byCoord[3].label == nil and byCoord[3].secret, "secret GetMapSearchLabel is no label")
check(Index.labelled == 2 and Index.unlabelled == 2 and Index.secretLabels == 2, "counts: labelled "
    .. Index.labelled .. ", unlabelled " .. Index.unlabelled .. ", secret " .. Index.secretLabels)
check(Index.Status():find("2 of them secret", 1, true) ~= nil, "status reports the secret pins: " .. Index.Status())

-- A secret pin uses up its tries, so rebuilds do not rescan it for ever; the pins after it still get labels.
for _ = 1, 5 do
    Index.dirty = false
    Index.Start()
    for _ = 1, 50 do
        if not Index.building then break end
        driver.scripts.OnUpdate(driver)
    end
end
check(scans[2] == 3, "secret tooltip scanned 3 times in all, not " .. tostring(scans[2]))
check(#errors == 0, "no error after rebuilds: " .. tostring(errors[1]))

if failures > 0 then os.exit(1) end
print("test_index: ok")
