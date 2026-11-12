# Localisation (SimpleLootCouncil's model)

- Every user-visible string is `T["English"]` (`local T = ns.Locale.Text`) or
  `Locale.Plural{ one = ..., other = ... }` where it is written; the English text is the
  key. A new or changed string gets a translation in all ten `Locale/*.lua` files in the
  same commit; `dev/locale_check.py` fails on a missing, unused or slot-mismatched key.
- Never translated here: `/mapsearch status` (a diagnostic, English like SLC's), besides the
  `wow-addon` skill's list (addon name, slash commands and arguments, setting names, saved
  values).
- Search compares `Locale.Fold` keys, never `string.lower`.
- Translations are machine-made drafts; each file's header names its glossary. Blizzard's own
  term per client (esMX calabozo, itIT spedizione, yards shown as m/км/码).

## Files

- `Locale.lua` loads first: `ns.Locale` (`Text`, `Register`, `Plural`, `Format`, `Fold`), a
  lean port of SLC's `Core/Locale.lua`.
- `Locale/<code>.lua`, one per client locale (deDE esES esMX frFR itIT koKR ptBR ruRU zhCN
  zhTW), each behind `[AllowLoadTextLocale <code>]` in the .toc; enUS is the keys.
- `dev/locale_check.py` is the translation audit; `dev/test_locale.lua` is the offline Lua
  test of every locale.
