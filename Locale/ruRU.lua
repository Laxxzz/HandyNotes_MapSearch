-- Russian draft (machine-made). Plurals use one/few/many; other covers fractions.
-- Glossary: flight point точка полета, dungeon entrance вход в подземелье, yards м.

local ADDON_NAME, ns = ...

ns.Locale.Register("ruRU", {
    ["Results shown"] = "Число результатов",
    ["How many matches the list under the map search box shows."] = "Сколько результатов показывает список под полем поиска на карте.",
    ["Search flight points and dungeon entrances"] = "Искать точки полета и входы в подземелья",
    ["Also list the game's own flight points and dungeon entrances, not only HandyNotes pins."] = "Показывать также точки полета и входы в подземелья из самой игры, а не только метки HandyNotes.",
    ["The list shows %d results."] = {
        one = "Список показывает %d результат.",
        few = "Список показывает %d результата.",
        many = "Список показывает %d результатов.",
        other = "Список показывает %d результата.",
    },
    ["Use /mapsearch results <%d-%d>."] = "Используйте /mapsearch results <%d-%d>.",
    ["Rebuilding the index."] = "Индекс перестраивается.",
    ["In combat: the settings will open when combat ends."] = "В бою: настройки откроются после окончания боя.",
    ["open the options"] = "открыть настройки",
    ["how many matches the list shows"] = "сколько результатов показывает список",
    ["re-read every map's pins"] = "заново прочитать метки всех карт",
    ["index size and progress"] = "размер индекса и ход построения",
    ["Flight point"] = "Точка полета",
    ["Dungeon entrance"] = "Вход в подземелье",
    ["%s  %.1fk yd"] = "%s  %.1f км",
    ["%s  %d yd"] = "%s  %d м",
    ["Indexing map pins..."] = "Индексация меток карты...",
    ["No matches"] = "Нет совпадений",
    ["Search map pins"] = "Поиск меток на карте",
})
