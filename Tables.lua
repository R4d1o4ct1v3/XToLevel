local _, addonTable = ...

XToLevel.AVERAGE_WINDOWS =
{
    [0] = "None",
    [1] = "Blocky",
    [2] = "Classic"
}

XToLevel.TIMER_MODES = 
{
    [1] = "Session",
    [2] = "Level"
}

XToLevel.BG_NAMES =
{
    [1] = "Alterac Valley",
    [2] = "Warsong Gulch",
    [3] = "Arathi Basin",
    [4] = "Eye of the Storm",
    [5] = "Strand of the Ancients",
    [6] = "Isle of Conquest"
}

XToLevel.LDB_PATTERNS = 
{
    [1] = "default", 
    [2] = "minimal", 
    [3] = "minimal_dashed", 
    [4] = "brackets", 
    [5] = "countdown", 
    [6] = "custom"
}

XToLevel.DISPLAY_LOCALES = addonTable.GetDisplayLocales()

XToLevel.UNIT_CLASSIFICATIONS = {
    [1] = "normal",
    [2] = "rare",
    [3] = "elite",
    [4] = "rareelite",
    [5] = "worldboss"
}

XToLevel.CATACLYSM_ZONES = {
    [1] = "Mount Hyjal",
    [2] = "Uldum",
    [3] = "Vashj'ir",
    [4] =  "Twilight Highlands"
}

-- A list of zones introduced in cata that are would use the zone ID 5, yet who's
-- XP modifier should be that of normal pre-Cata low-level zones.
XToLevel.CATACLYSM_LOWLEVEL_ZONES = {
    [1] = "Kezan",
    [2] = "The Lost Isles",
    [3] = "Ruins of Gilneas"
}
