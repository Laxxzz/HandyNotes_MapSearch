-- Offline test of Locale.lua under every client locale (Lua 5.1):
--   lua5.1 dev/test_locale.lua      (run from the addon root; exit 0 = pass)
-- Loads Locale.lua with GetLocale stubbed, then that locale's file, and checks that no
-- translation was rejected, every key translates, plurals pick the right form and
-- Fold matches typed text across case in Latin and Cyrillic.

local LOCALES = { "enUS", "deDE", "esES", "esMX", "frFR", "itIT", "koKR", "ptBR", "ruRU", "zhCN", "zhTW" }
local failures = 0
local function check(ok, what)
    if not ok then failures = failures + 1; print("FAIL " .. what) end
end

for _, code in ipairs(LOCALES) do
    _G.GetLocale = function() return code end
    local ns = {}
    assert(loadfile("Locale.lua"))("HandyNotes_MapSearch", ns)
    if code ~= "enUS" then assert(loadfile("Locale/" .. code .. ".lua"))("HandyNotes_MapSearch", ns) end
    local L, T = ns.Locale, ns.Locale.Text
    check(#L.rejected == 0, code .. " rejected: " .. table.concat(L.rejected, "; "))
    if code ~= "enUS" then
        check(T["No matches"] ~= "No matches", code .. " translates No matches")
    end
    local forms = L.Plural({ one = "The list shows %d result.", other = "The list shows %d results." })
    for _, n in ipairs({ 1, 2, 5, 21 }) do
        local line = L.Format(forms, n, n)
        check(line:find(tostring(n), 1, true) ~= nil, code .. " plural " .. n .. ": " .. line)
    end
    check(L.Format(T["%s  %d yd"], "Zone", 250):find("250", 1, true) ~= nil, code .. " distance")
end

-- ruRU picks one/few/many.
_G.GetLocale = function() return "ruRU" end
local ru = {}
assert(loadfile("Locale.lua"))("HandyNotes_MapSearch", ru)
assert(loadfile("Locale/ruRU.lua"))("HandyNotes_MapSearch", ru)
local f = ru.Locale.Plural({ one = "x %d", other = "The list shows %d results." })
check(ru.Locale.Format(f, 1, 1):find("результат%.$") ~= nil, "ruRU one")
check(ru.Locale.Format(f, 3, 3):find("результата%.$") ~= nil, "ruRU few")
check(ru.Locale.Format(f, 5, 5):find("результатов%.$") ~= nil, "ruRU many")

local Fold = ru.Locale.Fold
check(Fold("ВХОД в Подземелье") == "вход в подземелье", "Fold Cyrillic")
check(Fold("ÉCOLE Straße") == "école strasse", "Fold Latin-1 and sharp s")
check(Fold("Forge") == "forge", "Fold ASCII")
check(Fold("飛行點") == "飛行點", "Fold leaves CJK alone")

print(failures == 0 and "PASS" or (failures .. " failure(s)"))
os.exit(failures == 0 and 0 or 1)
