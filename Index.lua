-- HandyNotes - MapSearch: the search index.
-- Every map's HandyNotes nodes (and, optionally, the game's flight points and dungeon
-- entrances) are read once into a flat list with world coordinates, spread over frames.
-- HandyNotes' plugin API returns positions and icons but no names, so a node's label is
-- the first line of the tooltip its plugin draws (README: "How labels are found").

local ADDON_NAME, ns = ...

local LibStub = LibStub
local HBD = LibStub and LibStub("HereBeDragons-2.0", true)
local AceAddon = LibStub and LibStub("AceAddon-3.0", true)

local Index = {
    entries = {},   -- array of entries, see NewEntry
    dirty = true,   -- the HandyNotes data changed since the last build
    building = false,
    built = false,
    phase = "idle",
    labelled = 0,
    unlabelled = 0,
}
ns.Index = Index

local BUDGET_MS = 4        -- per-frame work budget while building
local MAX_LABEL_TRIES = 3  -- tooltip scans per node before giving up (item data may still be loading)

local labelCache = {}      -- entry key -> label; survives rebuilds
local labelTries = {}
local mapNames = {}

local function HandyNotesAddon()
    return AceAddon and AceAddon:GetAddon("HandyNotes", true)
end

function ns.MapName(mapID)
    local name = mapNames[mapID]
    if name == nil then
        local info = C_Map.GetMapInfo(mapID)
        name = info and info.name or ""
        mapNames[mapID] = name
    end
    return name
end

-- Strip colour, texture and atlas escapes so labels compare and display as plain text.
local function CleanText(s)
    if type(s) ~= "string" then return nil end
    s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|cn[^:]*:", ""):gsub("|r", "")
    s = s:gsub("|T.-|t", ""):gsub("|A.-|a", ""):gsub("|n", " ")
    s = strtrim(s)
    if s == "" or s == RETRIEVING_ITEM_INFO then return nil end
    return s
end

local function NewEntry(key, mapID, x, y)
    if not HBD then return nil end
    local wx, wy, instance = HBD:GetWorldCoordinatesFromZone(x, y, mapID)
    local ax, ay
    if wx then ax, ay = HBD:GetAzerothWorldMapCoordinatesFromWorld(wx, wy, instance) end
    return {
        key = key, mapID = mapID, x = x, y = y,
        wx = wx, wy = wy, instance = instance, -- yards, comparable within one instance
        ax = ax, ay = ay,                      -- position on the Azeroth world map, across continents
    }
end

local function SetLabel(entry, label)
    entry.label = label
    entry.lower = label and label:lower() or entry.sourceLower
end

-- ------------------------------------------------------------------ tooltip label scan
local scanOwner

local function ScanOwner()
    if not scanOwner then
        -- Plugins anchor the tooltip on the pin and often read its centre, so it needs a position.
        scanOwner = CreateFrame("Frame", nil, UIParent)
        scanOwner:SetSize(12, 12)
        scanOwner:SetPoint("CENTER", UIParent, "CENTER")
        scanOwner:SetAlpha(0)
    end
    return scanOwner
end

local function ScanLabel(entry)
    local HN = HandyNotesAddon()
    local handler = HN and HN.plugins[entry.plugin]
    if not handler then return nil end
    if type(handler.GetMapSearchLabel) == "function" then
        local ok, label = pcall(handler.GetMapSearchLabel, handler, entry.mapID, entry.coord)
        if ok then return CleanText(label) end
    end
    if type(handler.OnEnter) ~= "function" then return nil end

    local owner = ScanOwner()
    owner.pluginName, owner.coord, owner.uiMapID = entry.plugin, entry.coord, entry.mapID
    local label
    if pcall(handler.OnEnter, owner, entry.mapID, entry.coord) and GameTooltip:IsOwned(owner) then
        label = CleanText(GameTooltipTextLeft1:GetText())
    end
    if type(handler.OnLeave) == "function" then
        pcall(handler.OnLeave, owner, entry.mapID, entry.coord)
    end
    if GameTooltip:IsOwned(owner) then GameTooltip:Hide() end
    return label
end

-- A scan borrows GameTooltip, so it waits while the player is looking at a tooltip or fighting.
local function CanScanNow()
    return not InCombatLockdown() and not GameTooltip:IsShown()
end

-- ------------------------------------------------------------------ build
local function CollectNodes(handler, mapID, out)
    local iter, state, value = handler:GetNodes2(mapID, false)
    for coord, nodeMapID, icon in iter, state, value do
        out[#out + 1] = { coord, nodeMapID or mapID, icon }
    end
end

local function SortedMaps()
    local maps = HBD:GetAllMapIDs()
    table.sort(maps)
    return maps
end

local function Build()
    local started = debugprofilestop()
    local function Budget()
        if debugprofilestop() - started > BUDGET_MS then
            coroutine.yield()
            started = debugprofilestop()
        end
    end

    local entries, seen = {}, {}
    Index.entries, Index.labelled, Index.unlabelled = entries, 0, 0
    local maps = SortedMaps()
    local HN = HandyNotesAddon()

    -- HandyNotes plugins: every map, every enabled plugin with the GetNodes2 API.
    Index.phase = "pins"
    if HN and HN:IsEnabled() then
        local enabled = HN.db.profile.enabledPlugins
        for pluginName, handler in pairs(HN.plugins) do
            if enabled[pluginName] and type(handler.GetNodes2) == "function" then
                local sourceLower = tostring(pluginName):lower()
                for _, mapID in ipairs(maps) do
                    local nodes = {}
                    if pcall(CollectNodes, handler, mapID, nodes) then
                        for _, node in ipairs(nodes) do
                            local coord, nodeMapID = node[1], node[2]
                            local key = type(coord) == "number" and type(nodeMapID) == "number"
                                and ("%s:%d:%d"):format(tostring(pluginName), nodeMapID, coord)
                            if key and not seen[key] then
                                seen[key] = true
                                local x, y = HN:getXY(coord)
                                local entry = NewEntry(key, nodeMapID, x, y)
                                if entry then
                                    entry.plugin, entry.coord, entry.icon = pluginName, coord, node[3]
                                    entry.source, entry.sourceLower = pluginName, sourceLower
                                    SetLabel(entry, labelCache[key])
                                    entries[#entries + 1] = entry
                                end
                            end
                        end
                    end
                    Budget()
                end
            end
        end
    end

    -- The game's own flight points and dungeon entrances, read from zone maps only.
    if HandyNotes_MapSearchDB.blizzardPins then
        Index.phase = "game pins"
        local faction = UnitFactionGroup("player")
        local otherFaction = (faction == "Horde" and Enum.FlightPathFaction.Alliance)
            or (faction == "Alliance" and Enum.FlightPathFaction.Horde) or nil
        for _, mapID in ipairs(maps) do
            local info = C_Map.GetMapInfo(mapID)
            if info and info.mapType == Enum.UIMapType.Zone then
                for _, node in ipairs(C_TaxiMap.GetTaxiNodesForMap(mapID) or {}) do
                    local key = "taxi:" .. node.nodeID
                    if not seen[key] and node.faction ~= otherFaction then
                        seen[key] = true
                        local x, y = node.position:GetXY()
                        local entry = NewEntry(key, mapID, x, y)
                        if entry then
                            entry.atlas, entry.source, entry.sourceLower = node.atlasName, "Flight point", "flight point"
                            SetLabel(entry, CleanText(node.name))
                            entries[#entries + 1] = entry
                        end
                    end
                end
                for _, dungeon in ipairs(C_EncounterJournal.GetDungeonEntrancesForMap(mapID) or {}) do
                    local key = "dungeon:" .. dungeon.areaPoiID
                    if not seen[key] then
                        seen[key] = true
                        local x, y = dungeon.position:GetXY()
                        local entry = NewEntry(key, mapID, x, y)
                        if entry then
                            entry.atlas, entry.source, entry.sourceLower = dungeon.atlasName, "Dungeon entrance", "dungeon entrance"
                            SetLabel(entry, CleanText(dungeon.name))
                            entries[#entries + 1] = entry
                        end
                    end
                end
                Budget()
            end
        end
    end
    if ns.UI then ns.UI.OnIndexChanged() end

    -- Labels for plugin nodes, from each plugin's tooltip.
    Index.phase = "labels"
    for _, entry in ipairs(entries) do
        if entry.plugin and not entry.label and (labelTries[entry.key] or 0) < MAX_LABEL_TRIES then
            while not CanScanNow() do
                coroutine.yield()
                started = debugprofilestop()
            end
            labelTries[entry.key] = (labelTries[entry.key] or 0) + 1
            local label = ScanLabel(entry)
            if label then
                labelCache[entry.key] = label
                SetLabel(entry, label)
            end
            Budget()
        end
        if entry.label then
            Index.labelled = Index.labelled + 1
        else
            Index.unlabelled = Index.unlabelled + 1
        end
    end
    Index.phase = "done"
end

-- ------------------------------------------------------------------ driver
local driver = CreateFrame("Frame")
driver:Hide()
local co, lastProgress = nil, 0

driver:SetScript("OnUpdate", function(self)
    if not co then self:Hide() return end
    local ok, err = coroutine.resume(co)
    if not ok then
        co = nil
        Index.building = false
        self:Hide()
        geterrorhandler()(err)
        return
    end
    if coroutine.status(co) == "dead" then
        co = nil
        Index.building, Index.built = false, true
        self:Hide()
        if Index.dirty then
            Index.Start()
        elseif ns.UI then
            ns.UI.OnIndexChanged()
        end
    elseif ns.UI and GetTime() - lastProgress > 0.5 then
        lastProgress = GetTime()
        ns.UI.OnIndexChanged()
    end
end)

function Index.Start()
    if Index.building or not HBD or not HandyNotes_MapSearchDB then return end
    Index.dirty = false
    Index.building = true
    co = coroutine.create(Build)
    driver:Show()
end

-- Rebuilds wait a moment so a burst of plugin updates costs one build.
local pending = false
function Index.MarkDirty()
    Index.dirty = true
    if pending or Index.building then return end
    pending = true
    C_Timer.After(2, function()
        pending = false
        if Index.dirty then Index.Start() end
    end)
end

function Index.Status()
    if not HBD then return "HereBeDragons is missing; HandyNotes did not load." end
    local state = Index.building and ("building (" .. Index.phase .. ")") or (Index.built and "ready" or "not built yet")
    return ("%s: %d entries, %d plugin pins labelled, %d without a label."):format(
        state, #Index.entries, Index.labelled, Index.unlabelled)
end

-- ------------------------------------------------------------------ triggers
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
    local HN = HandyNotesAddon()
    if HN then
        -- Plugins announce changed nodes through UpdatePluginMap; new plugins through RegisterPluginDB.
        hooksecurefunc(HN, "UpdatePluginMap", function() Index.MarkDirty() end)
        hooksecurefunc(HN, "RegisterPluginDB", function() Index.MarkDirty() end)
    end
    C_Timer.After(5, Index.Start)
end)
