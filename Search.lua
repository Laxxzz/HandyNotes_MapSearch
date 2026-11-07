-- HandyNotes - MapSearch: matching and nearest-first ranking.
-- Tier 1: same instance (continent) as the player, by distance in yards.
-- Tier 2: another continent that sits on the Azeroth world map, by distance on that map.
-- Tier 3: no comparable position (instances, other worlds, player position unknown), by name.

local ADDON_NAME, ns = ...

local HBD = LibStub and LibStub("HereBeDragons-2.0", true)

local Search = {}
ns.Search = Search

local function IsUsable(v)
    return v ~= nil and not (issecretvalue and issecretvalue(v))
end

local function PlayerPosition()
    if not HBD then return end
    local px, py, instance = HBD:GetPlayerWorldPosition()
    if not (IsUsable(px) and IsUsable(py) and IsUsable(instance)) then return end
    local ax, ay = HBD:GetAzerothWorldMapCoordinatesFromWorld(px, py, instance)
    return px, py, instance, ax, ay
end

local function Terms(text)
    local terms = {}
    for word in text:lower():gmatch("%S+") do terms[#terms + 1] = word end
    return terms
end

local function Matches(lower, terms)
    if not lower then return false end
    for i = 1, #terms do
        if not lower:find(terms[i], 1, true) then return false end
    end
    return true
end

local function Compare(a, b)
    if a.tier ~= b.tier then return a.tier < b.tier end
    if a.dist ~= b.dist then return a.dist < b.dist end
    return (a.entry.label or a.entry.source) < (b.entry.label or b.entry.source)
end

-- Returns every match, nearest first: { entry = e, tier = 1|2|3, dist = yards or map units, yards = n|nil }.
-- Pins a plugin lists both on a zone and on its continent collapse to one result.
function Search.Run(text)
    local results = {}
    local terms = Terms(text or "")
    if #terms == 0 then return results end

    local px, py, pInstance, pax, pay = PlayerPosition()
    local seen = {}
    for _, e in ipairs(ns.Index.entries) do
        if Matches(e.lower, terms) then
            local dupKey = e.wx and ("%s|%s|%d|%d"):format(e.source, e.label or "", e.wx / 5, e.wy / 5)
            if not dupKey or not seen[dupKey] then
                if dupKey then seen[dupKey] = true end
                local r = { entry = e, tier = 3, dist = 0 }
                if px and e.wx and e.instance == pInstance then
                    local dx, dy = e.wx - px, e.wy - py
                    r.tier, r.dist = 1, (dx * dx + dy * dy) ^ 0.5
                    r.yards = r.dist
                elseif pax and e.ax then
                    local dx, dy = e.ax - pax, e.ay - pay
                    r.tier, r.dist = 2, (dx * dx + dy * dy) ^ 0.5
                end
                results[#results + 1] = r
            end
        end
    end
    table.sort(results, Compare)
    return results
end
