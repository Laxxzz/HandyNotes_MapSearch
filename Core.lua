-- HandyNotes - MapSearch: saved settings, options panel and slash command.

local ADDON_NAME, ns = ...

ns.RESULTS_MIN, ns.RESULTS_MAX = 1, 20

local DEFAULTS = {
    maxResults = 5,
    blizzardPins = true, -- flight points and dungeon entrances
}

local function ApplyDefaults(db, src)
    for k, v in pairs(src) do
        if db[k] == nil then
            db[k] = (type(v) == "table") and CopyTable(v) or v
        elseif type(v) == "table" and type(db[k]) == "table" then
            ApplyDefaults(db[k], v)
        end
    end
    return db
end

local function ClampResults(n)
    n = math.floor(tonumber(n) or DEFAULTS.maxResults)
    return math.max(ns.RESULTS_MIN, math.min(ns.RESULTS_MAX, n))
end

function ns.Print(fmt, ...)
    print("|cff33ff99MapSearch|r: " .. fmt:format(...))
end

-- ------------------------------------------------------------------ options
local settings = {}

local function BuildOptions()
    local db = HandyNotes_MapSearchDB
    local category = Settings.RegisterVerticalLayoutCategory("HandyNotes - MapSearch")

    local results = Settings.RegisterAddOnSetting(category, "HANDYNOTES_MAPSEARCH_RESULTS", "maxResults", db,
        Settings.VarType.Number, "Results shown", DEFAULTS.maxResults)
    local sliderOptions = Settings.CreateSliderOptions(ns.RESULTS_MIN, ns.RESULTS_MAX, 1)
    sliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
    Settings.CreateSlider(category, results, sliderOptions, "How many matches the list under the map search box shows.")
    results:SetValueChangedCallback(function() if ns.UI then ns.UI.Refresh() end end)
    settings.maxResults = results

    local blizzard = Settings.RegisterAddOnSetting(category, "HANDYNOTES_MAPSEARCH_BLIZZARD", "blizzardPins", db,
        Settings.VarType.Boolean, "Search flight points and dungeon entrances", DEFAULTS.blizzardPins)
    Settings.CreateCheckbox(category, blizzard, "Also list the game's own flight points and dungeon entrances, not only HandyNotes pins.")
    blizzard:SetValueChangedCallback(function() ns.Index.MarkDirty() end)
    settings.blizzardPins = blizzard

    Settings.RegisterAddOnCategory(category)
    ns.categoryID = category:GetID()
end

function ns.OpenOptions()
    if ns.categoryID then Settings.OpenToCategory(ns.categoryID) end
end

function ns.SetMaxResults(n)
    n = ClampResults(n)
    if settings.maxResults then
        settings.maxResults:SetValue(n)
    else
        HandyNotes_MapSearchDB.maxResults = n
    end
    return n
end

-- ------------------------------------------------------------------ init
EventUtil.ContinueOnAddOnLoaded(ADDON_NAME, function()
    HandyNotes_MapSearchDB = ApplyDefaults(HandyNotes_MapSearchDB or {}, DEFAULTS)
    HandyNotes_MapSearchDB.maxResults = ClampResults(HandyNotes_MapSearchDB.maxResults)
    BuildOptions()
end)

-- ------------------------------------------------------------------ slash command
local HELP = {
    "/mapsearch / ms - open the options",
    "/mapsearch results <1-20> - how many matches the list shows",
    "/mapsearch rebuild - re-read every map's pins",
    "/mapsearch status - index size and progress",
}

SLASH_HANDYNOTES_MAPSEARCH1 = "/mapsearch"
SLASH_HANDYNOTES_MAPSEARCH2 = "/ms"
SlashCmdList.HANDYNOTES_MAPSEARCH = function(msg)
    local cmd, arg = strtrim(msg or ""):lower():match("^(%S*)%s*(.-)$")
    if cmd == "" then
        ns.OpenOptions()
    elseif cmd == "results" then
        if tonumber(arg) then
            ns.Print("the list shows %d results.", ns.SetMaxResults(arg))
        else
            ns.Print("the list shows %d results. Use /mapsearch results <%d-%d>.",
                HandyNotes_MapSearchDB.maxResults, ns.RESULTS_MIN, ns.RESULTS_MAX)
        end
    elseif cmd == "rebuild" then
        ns.Index.MarkDirty()
        ns.Index.Start()
        ns.Print("rebuilding the index.")
    elseif cmd == "status" then
        ns.Print("%s", ns.Index.Status())
    else
        for _, line in ipairs(HELP) do ns.Print("%s", line) end
    end
end

function HandyNotes_MapSearch_OnCompartmentClick()
    ns.OpenOptions()
end
