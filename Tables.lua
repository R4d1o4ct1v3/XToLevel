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
    [5] = "worldboss",
    [6] = "minus",
    [7] = "trivial"
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

-- XP Modifiers for the standard XP forumla. The values listed here cover all levels between
-- the level indicated up until the next level listed. Note that it's not 100% accurate, as
-- the actual value is calculated based on some formula I'm too stupid/lazy to figure out.
-- This is pretty close tho, based on actual recorded values from the game client.
-- Note that this is only neede for lower level mobs. Higher level mobs are always
-- +5% per level at all levels.
XToLevel.XP_MULTIPLIERS = {
    {["level"] = 1, ["modifier"] = 0.27},
    {["level"] = 3, ["modifier"] = 0.23},
    {["level"] = 8, ["modifier"] = 0.19},
    {["level"] = 12, ["modifier"] = 0.16},
    {["level"] = 15, ["modifier"] = 0.15},
    {["level"] = 18, ["modifier"] = 0.14},
    {["level"] = 20, ["modifier"] = 0.13},
    {["level"] = 25, ["modifier"] = 0.12},
    {["level"] = 30, ["modifier"] = 0.11},
    {["level"] = 33, ["modifier"] = 0.10},
    {["level"] = 40, ["modifier"] = 0.095},
    {["level"] = 45, ["modifier"] = 0.09},
    {["level"] = 48, ["modifier"] = 0.085},
    {["level"] = 52, ["modifier"] = 0.08},
    {["level"] = 56, ["modifier"] = 0.075},
    {["level"] = 60, ["modifier"] = 0.07}   -- All mobs above 60 are -7% per level
}