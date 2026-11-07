-- HandyNotes - MapSearch: localisation primitives (a lean port of SimpleLootCouncil's).
-- Keys are the English text; Locale\<code>.lua registers translations for its client
-- locale only, and a translation whose format slots or escapes differ from its key is
-- rejected so a bad entry falls back to English instead of breaking a format call.

local ADDON_NAME, ns = ...

local Locale = {}
ns.Locale = Locale

local clientLocale = "enUS"
if type(GetLocale) == "function" then
    local value = GetLocale()
    if type(value) == "string" then clientLocale = value end
end
Locale.clientLocale = clientLocale

local registered = {}
Locale.rejected = {}

-- T["English"] returns the client locale's text, or the English key when there is none.
Locale.Text = setmetatable({}, {
    __index = function(_, key) return registered[key] or key end,
})

-- ------------------------------------------------------------------ validation
local function Slots(message)
    local slots, position = {}, 1
    while true do
        local start = message:find("%", position, true)
        if not start then return slots end
        if message:sub(start + 1, start + 1) == "%" then
            position = start + 2
        else
            local cursor = start + 1
            local index = message:sub(cursor):match("^(%d+)%$")
            if index then cursor = cursor + #index + 1 end
            cursor = cursor + #(message:sub(cursor):match("^[%-%+ #0]*") or "")
            cursor = cursor + #(message:sub(cursor):match("^%d*") or "")
            if message:sub(cursor, cursor) == "." then
                local precision = message:sub(cursor + 1):match("^%d+")
                if not precision then return nil end
                cursor = cursor + #precision + 1
            end
            local conversion = message:sub(cursor, cursor)
            if not conversion:match("^[cdiouxXeEfgGqs]$") then return nil end
            slots[#slots + 1] = {
                first = start, last = cursor, index = index and tonumber(index), conversion = conversion,
                plain = "%" .. message:sub(start + 1 + (index and #index + 1 or 0), cursor),
            }
            position = cursor + 1
        end
    end
end

local function Escapes(message)
    local tokens, position = {}, 1
    while true do
        local start = message:find("|", position, true)
        if not start then break end
        local tail = message:sub(start)
        local token = tail:match("^|c%x%x%x%x%x%x%x%x") or tail:match("^|[rn]")
            or tail:match("^|T.-|t") or tail:match("^|H.-|h") or tail:match("^||")
        if not token then return nil end
        tokens[#tokens + 1] = token
        position = start + #token
    end
    table.sort(tokens)
    return table.concat(tokens, "\n")
end

local function ValidForm(keySlots, keyEscapes, form, plural)
    if type(form) ~= "string" then return false, "translation is not a string" end
    local slots = Slots(form)
    if not slots then return false, "invalid format slot" end
    if Escapes(form) ~= keyEscapes then return false, "escape mismatch" end
    local positional = false
    for _, slot in ipairs(slots) do
        if slot.index then positional = true end
    end
    if positional then
        for _, slot in ipairs(slots) do
            local original = slot.index and keySlots[slot.index]
            if not original or original.conversion ~= slot.conversion then return false, "slot mismatch" end
        end
    else
        if #slots > #keySlots or (not plural and #slots ~= #keySlots) then return false, "slot mismatch" end
        for i, slot in ipairs(slots) do
            if keySlots[i].conversion ~= slot.conversion then return false, "slot mismatch" end
        end
    end
    return true
end

local PLURAL_FORMS = { one = true, few = true, many = true, other = true }

local function Install(entries)
    for key, value in pairs(entries) do
        local reason
        local keySlots = type(key) == "string" and Slots(key)
        local keyEscapes = type(key) == "string" and Escapes(key)
        if not keySlots or not keyEscapes then
            reason = "invalid key"
        elseif type(value) == "table" then
            if type(value.other) ~= "string" then reason = "plural has no other form" end
            for name, form in pairs(value) do
                if reason then break end
                if not PLURAL_FORMS[name] then
                    reason = "unknown plural form"
                else
                    local ok, why = ValidForm(keySlots, keyEscapes, form, true)
                    if not ok then reason = why end
                end
            end
        else
            local ok, why = ValidForm(keySlots, keyEscapes, value, false)
            if not ok then reason = why end
        end
        if reason then
            Locale.rejected[#Locale.rejected + 1] = reason .. " for " .. tostring(key)
        else
            registered[key] = value
        end
    end
end

function Locale.Register(locale, entries)
    if locale == clientLocale and type(entries) == "table" then Install(entries) end
end

-- ------------------------------------------------------------------ plurals and formatting
-- A plural key is its English `other` form; the registered value is a table of CLDR forms.
function Locale.Plural(forms)
    local translated = registered[forms.other]
    return type(translated) == "table" and translated or forms
end

local function PluralForm(count)
    count = tonumber(count)
    if not count or count ~= count or math.abs(count) == math.huge then return "other" end
    count = math.abs(count)
    if clientLocale == "ruRU" and count == math.floor(count) then
        local mod10, mod100 = count % 10, count % 100
        if mod10 == 1 and mod100 ~= 11 then return "one" end
        if mod10 >= 2 and mod10 <= 4 and (mod100 < 12 or mod100 > 14) then return "few" end
        return "many"
    end
    if (clientLocale == "frFR" or clientLocale == "ptBR") and count < 2 then return "one" end
    if clientLocale == "koKR" or clientLocale == "zhCN" or clientLocale == "zhTW" then return "other" end
    return count == 1 and "one" or "other"
end

local function FormatString(format, ...)
    if not format:find("%%%d+%$") then return format:format(...) end
    local slots = Slots(format)
    if not slots then return format:format(...) end
    local pieces, values, last = {}, {}, 1
    for i, slot in ipairs(slots) do
        pieces[#pieces + 1] = format:sub(last, slot.first - 1)
        pieces[#pieces + 1] = slot.plain
        values[i] = (select(slot.index or i, ...))
        last = slot.last + 1
    end
    pieces[#pieces + 1] = format:sub(last)
    return string.format(table.concat(pieces), unpack(values, 1, #slots))
end

--   Locale.Format(T["Requires %s."], requirement)
--   Locale.Format(Locale.Plural({ one = "%d item", other = "%d items" }), count, count)
function Locale.Format(message, ...)
    if type(message) == "table" then
        message = message[PluralForm((...))] or message.other
        return FormatString(message, select(2, ...))
    end
    return FormatString(message, ...)
end

-- ------------------------------------------------------------------ case folding
-- string.lower folds ASCII only; search must also fold Latin-1/Extended-A and Cyrillic.
local function Decode(text, position)
    local a, b, c, d = text:byte(position, position + 3)
    if a < 0x80 then return a, position + 1 end
    local function cont(v) return v and v >= 0x80 and v <= 0xBF end
    if a >= 0xC2 and a <= 0xDF and cont(b) then return (a - 0xC0) * 64 + b - 0x80, position + 2 end
    if a >= 0xE0 and a <= 0xEF and cont(b) and cont(c) and (a ~= 0xE0 or b >= 0xA0) and (a ~= 0xED or b < 0xA0) then
        return (a - 0xE0) * 4096 + (b - 0x80) * 64 + c - 0x80, position + 3
    end
    if a >= 0xF0 and a <= 0xF4 and cont(b) and cont(c) and cont(d) and (a ~= 0xF0 or b >= 0x90) and (a ~= 0xF4 or b < 0x90) then
        return (a - 0xF0) * 262144 + (b - 0x80) * 4096 + (c - 0x80) * 64 + d - 0x80, position + 4
    end
end

local function Encode(code)
    if code < 0x80 then return string.char(code) end
    if code < 0x800 then return string.char(0xC0 + math.floor(code / 64), 0x80 + code % 64) end
    if code < 0x10000 then
        return string.char(0xE0 + math.floor(code / 4096), 0x80 + math.floor(code / 64) % 64, 0x80 + code % 64)
    end
    return string.char(0xF0 + math.floor(code / 262144), 0x80 + math.floor(code / 4096) % 64,
        0x80 + math.floor(code / 64) % 64, 0x80 + code % 64)
end

local lower = {}
local function Pair(capital, small) lower[capital] = small end
for code = 0xC0, 0xDE do if code ~= 0xD7 then Pair(code, code + 32) end end
for code = 0x100, 0x12E, 2 do Pair(code, code + 1) end
for code = 0x132, 0x136, 2 do Pair(code, code + 1) end
for code = 0x139, 0x147, 2 do Pair(code, code + 1) end
for code = 0x14A, 0x176, 2 do Pair(code, code + 1) end
for code = 0x179, 0x17D, 2 do Pair(code, code + 1) end
Pair(0x178, 0xFF)
for code = 0x400, 0x40F do Pair(code, code + 80) end
for code = 0x410, 0x42F do Pair(code, code + 32) end
lower[0xDF], lower[0x1E9E] = "ss", "ss"

-- Case-insensitive match key: lower case, with German ß folded to "ss". Malformed UTF-8
-- comes back unchanged.
function Locale.Fold(text)
    if type(text) ~= "string" then return text end
    if not text:find("[\128-\255]") then return text:lower() end
    local result, position = {}, 1
    while position <= #text do
        local code, nextPosition = Decode(text, position)
        if not code then return text:lower() end
        local replacement = code < 0x80 and string.lower(string.char(code)) or lower[code]
        result[#result + 1] = type(replacement) == "string" and replacement or Encode(replacement or code)
        position = nextPosition
    end
    return table.concat(result)
end
