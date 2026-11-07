-- HandyNotes - MapSearch: the search box on the world map, its result list and the
-- map highlights. Highlights are pins of our own data provider, so no other addon's
-- pin frame is touched.

local ADDON_NAME, ns = ...

local HBD = LibStub and LibStub("HereBeDragons-2.0", true)
local Locale = ns.Locale
local T = Locale.Text

local UI ={ matches = {}, selectedIndex = 0 }
ns.UI = UI

local PIN_TEMPLATE = "HandyNotesMapSearchPinTemplate"
local MAX_HIGHLIGHTS = 300
local ROW_HEIGHT = 18
local LIST_WIDTH = 380
local LIST_PAD = 6

local box, list, rows = nil, nil, {}
local provider

-- ------------------------------------------------------------------ map pins
HandyNotesMapSearchPinMixin = CreateFromMixins(MapCanvasPinMixin)

function HandyNotesMapSearchPinMixin:OnLoad()
    -- Just under HandyNotes' own pins (PIN_FRAME_LEVEL_AREA_POI), so the glow sits behind the icon.
    self:UseFrameLevelType("PIN_FRAME_LEVEL_DRAGONRIDING_RACE")
    self:SetScalingLimits(1, 1.0, 1.2)
end

function HandyNotesMapSearchPinMixin:OnAcquired(x, y, chosen)
    self:SetPosition(x, y)
    if chosen then
        self:SetSize(46, 46)
        self.Glow:SetVertexColor(0.3, 1, 0.3, 1)
        self.Pulse:Play()
    else
        self:SetSize(30, 30)
        self.Glow:SetVertexColor(1, 0.85, 0.1, 0.9)
        self.Pulse:Stop()
    end
end

function HandyNotesMapSearchPinMixin:OnReleased()
    self.Pulse:Stop()
    MapCanvasPinMixin.OnReleased(self)
end

-- The pin takes no mouse input, so there is nothing to pass through; SetPassThroughButtons
-- is also refused in combat (HandyNotes disables it on its pins for the same reason).
function HandyNotesMapSearchPinMixin:CheckMouseButtonPassthrough() end

local function MapPosition(entry, mapID)
    if entry.mapID == mapID then return entry.x, entry.y end
    if HBD then return HBD:TranslateZoneCoordinates(entry.x, entry.y, entry.mapID, mapID) end
end

local function CreateProvider()
    local p = CreateFromMixins(MapCanvasDataProviderMixin)

    function p:RemoveAllData()
        self:GetMap():RemoveAllPinsByTemplate(PIN_TEMPLATE)
    end

    function p:RefreshAllData()
        self:RemoveAllData()
        local map = self:GetMap()
        local mapID = map:GetMapID()
        if not mapID then return end
        local chosen = UI.chosen
        local shown = 0
        for _, r in ipairs(UI.matches) do
            if shown >= MAX_HIGHLIGHTS then break end
            if r.entry ~= chosen then
                local x, y = MapPosition(r.entry, mapID)
                if x then
                    map:AcquirePin(PIN_TEMPLATE, x, y, false)
                    shown = shown + 1
                end
            end
        end
        if chosen then
            local x, y = MapPosition(chosen, mapID)
            if x then map:AcquirePin(PIN_TEMPLATE, x, y, true) end
        end
    end

    return p
end

local function RefreshPins()
    if provider and WorldMapFrame:IsShown() then provider:RefreshAllData() end
end

-- ------------------------------------------------------------------ result list
local function FormatDistance(r)
    local zone = ns.MapName(r.entry.mapID)
    if r.yards then
        if r.yards >= 1000 then
            return Locale.Format(T["%s  %.1fk yd"], zone, r.yards / 1000)
        end
        return Locale.Format(T["%s  %d yd"], zone, r.yards)
    end
    return zone
end

local function SetRowIcon(texture, entry)
    texture:SetTexCoord(0, 1, 0, 1)
    texture:SetVertexColor(1, 1, 1, 1)
    if entry.atlas and entry.atlas ~= "" then
        texture:SetAtlas(entry.atlas)
        return
    end
    local icon = entry.icon
    if type(icon) == "table" then
        if icon.tCoordLeft then
            texture:SetTexCoord(icon.tCoordLeft, icon.tCoordRight, icon.tCoordTop, icon.tCoordBottom)
        end
        if icon.r then texture:SetVertexColor(icon.r, icon.g, icon.b, icon.a or 1) end
        icon = icon.icon
    end
    texture:SetTexture(icon)
end

local function UpdateSelection()
    for i, row in ipairs(rows) do
        row.Selected:SetShown(i == UI.selectedIndex)
    end
end

local function CreateRow(i)
    local row = CreateFrame("Button", nil, list)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", list, "TOPLEFT", LIST_PAD, -LIST_PAD - (i - 1) * ROW_HEIGHT)
    row:SetPoint("TOPRIGHT", list, "TOPRIGHT", -LIST_PAD, -LIST_PAD - (i - 1) * ROW_HEIGHT)
    row:RegisterForClicks("LeftButtonUp")

    row.Selected = row:CreateTexture(nil, "BACKGROUND")
    row.Selected:SetAllPoints()
    row.Selected:SetColorTexture(1, 1, 1, 0.15)
    row.Selected:Hide()

    row.Icon = row:CreateTexture(nil, "ARTWORK")
    row.Icon:SetSize(14, 14)
    row.Icon:SetPoint("LEFT", row, "LEFT", 2, 0)

    row.Detail = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.Detail:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    row.Detail:SetWidth(150)
    row.Detail:SetJustifyH("RIGHT")
    row.Detail:SetWordWrap(false)

    row.Label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.Label:SetPoint("LEFT", row.Icon, "RIGHT", 4, 0)
    row.Label:SetPoint("RIGHT", row.Detail, "LEFT", -8, 0)
    row.Label:SetJustifyH("LEFT")
    row.Label:SetWordWrap(false)

    row:SetScript("OnEnter", function(self)
        UI.selectedIndex = self.index
        UpdateSelection()
    end)
    row:SetScript("OnClick", function(self) UI.Choose(self.result) end)
    rows[i] = row
    return row
end

local function PlaceList(count)
    local height = LIST_PAD * 2 + count * ROW_HEIGHT
    list:SetHeight(height)
    list:ClearAllPoints()
    -- Under the box when the screen has room, otherwise above it.
    local bottom = box:GetBottom()
    if bottom and (bottom - 4) * box:GetEffectiveScale() >= height * list:GetEffectiveScale() then
        list:SetPoint("TOP", box, "BOTTOM", 0, -4)
    else
        list:SetPoint("BOTTOM", box, "TOP", 0, 4)
    end
end

local function ShowList()
    local limit = HandyNotes_MapSearchDB.maxResults
    local count = math.min(limit, #UI.matches)
    local status
    if count == 0 then
        status = ns.Index.building and T["Indexing map pins..."] or T["No matches"]
    end
    local lines = math.max(count, 1)

    for i = 1, lines do
        local row = rows[i] or CreateRow(i)
        local r = UI.matches[i]
        row.index, row.result = i, r
        if r then
            row.Label:SetText(r.entry.label or r.entry.source)
            row.Detail:SetText(FormatDistance(r))
            SetRowIcon(row.Icon, r.entry)
            row.Icon:Show()
            row:Enable()
        else
            row.Label:SetText(status)
            row.Detail:SetText("")
            row.Icon:Hide()
            row:Disable()
        end
        row:Show()
    end
    for i = lines + 1, #rows do rows[i]:Hide() end

    if UI.selectedIndex > count then UI.selectedIndex = count end
    UpdateSelection()
    PlaceList(lines)
    list:Show()
end

local function HideList()
    if list then list:Hide() end
    UI.selectedIndex = 0
end

-- ------------------------------------------------------------------ search
function UI.Refresh()
    if not box then return end
    local text = box:GetText()
    UI.matches = ns.Search.Run(text)
    if strtrim(text) == "" then
        HideList()
    elseif box:HasFocus() or (list and list:IsShown()) then
        ShowList()
    end
    RefreshPins()
end

function UI.OnIndexChanged()
    if box and WorldMapFrame:IsShown() and strtrim(box:GetText()) ~= "" then UI.Refresh() end
end

function UI.Choose(result)
    if not result then return end
    UI.chosen = result.entry
    HideList()
    box:ClearFocus()
    if WorldMapFrame:GetMapID() ~= result.entry.mapID then
        WorldMapFrame:SetMapID(result.entry.mapID) -- the provider redraws on map change
    else
        RefreshPins()
    end
end

local function MoveSelection(delta)
    local count = math.min(HandyNotes_MapSearchDB.maxResults, #UI.matches)
    if count == 0 then return end
    if not list:IsShown() then ShowList() end
    local i = UI.selectedIndex + delta
    if i < 1 then i = count elseif i > count then i = 1 end
    UI.selectedIndex = i
    UpdateSelection()
end

local function Reset()
    UI.chosen = nil
    UI.matches = {}
    HideList()
    if box then
        box:ClearFocus()
        box:SetText("")
    end
end

-- ------------------------------------------------------------------ frames
local function OnGlobalMouseDown()
    if list and list:IsShown() and not list:IsMouseOver() and not box:IsMouseOver() then
        HideList()
    end
end

local function CreateFrames()
    local parent = WorldMapFrame.ScrollContainer
    box = CreateFrame("EditBox", "HandyNotesMapSearchBox", parent, "SearchBoxTemplate")
    box:SetSize(240, 20)
    box:SetPoint("BOTTOM", parent, "BOTTOM", 0, 10)
    box:SetFrameStrata("DIALOG")
    box:SetAutoFocus(false)
    box:SetAltArrowKeyMode(false)
    box:SetMaxLetters(60)
    box.Instructions:SetText(T["Search map pins"])

    box:SetScript("OnTextChanged", function(self)
        SearchBoxTemplate_OnTextChanged(self)
        UI.chosen = nil
        UI.selectedIndex = 0
        UI.Refresh()
    end)
    box:SetScript("OnEditFocusGained", function(self)
        SearchBoxTemplate_OnEditFocusGained(self)
        if strtrim(self:GetText()) ~= "" then ShowList() end
    end)
    box:SetScript("OnArrowPressed", function(_, key)
        if key == "UP" then MoveSelection(-1) elseif key == "DOWN" then MoveSelection(1) end
    end)
    box:SetScript("OnEnterPressed", function(self)
        if list:IsShown() then
            UI.Choose(UI.matches[math.max(UI.selectedIndex, 1)])
        end
        self:ClearFocus()
    end)
    box:SetScript("OnEscapePressed", function(self)
        HideList()
        self:ClearFocus()
    end)

    list = CreateFrame("Frame", nil, box, "TooltipBackdropTemplate")
    list:SetWidth(LIST_WIDTH)
    list:SetFrameStrata("DIALOG")
    list:SetFrameLevel(box:GetFrameLevel() + 5)
    list:Hide()
    list:SetScript("OnShow", function(self) self:RegisterEvent("GLOBAL_MOUSE_DOWN") end)
    list:SetScript("OnHide", function(self) self:UnregisterEvent("GLOBAL_MOUSE_DOWN") end)
    list:SetScript("OnEvent", OnGlobalMouseDown)
end

local function Init()
    if box or not WorldMapFrame then return end
    CreateFrames()
    provider = CreateProvider()
    WorldMapFrame:AddDataProvider(provider)
    EventRegistry:RegisterCallback("WorldMapOnShow", function()
        if ns.Index.dirty and not ns.Index.building then ns.Index.Start() end
    end, UI)
    EventRegistry:RegisterCallback("WorldMapOnHide", Reset, UI)
end

EventUtil.ContinueOnAddOnLoaded("Blizzard_WorldMap", Init)
