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

XToLevel.QUEST_XP = {
    -- 1-9
    120, 260, 250, 360, 450, 625, 825, 1050, 1300,
    -- 10-19
    1550, 1850, 2150, 2450, 2800, 3150, 3400, 3550, 3700, 3800,
    -- 20-29
    3950, 4100, 4250, 4350, 4500, 4650, 4800, 4900, 5050, 5200,
    -- 30-39
    5300, 5450, 5600, 5750, 5850, 6000, 6150, 6300, 6400, 6550, 
    -- 40-49
    6700, 6850, 6950, 7100, 7250, 7350, 7500, 7650, 7800, 7900, 
    -- 50-59
    8050, 8200, 8350, 8450, 8600, 8750, 8850, 9000, 9150, 9300, 
    -- 60-69
    9450, 9600, 9700, 9850, 10000, 10150, 10250, 10400, 10550, 10700, 
    -- 70-79
    10800, 10950, 11100, 11250, 11350, 11500, 11650, 11750, 11900, 12050, 
    -- 80-89
    12200, 12300, 12450, 12600, 12700, 12850, 13000, 13150, 13300, 13400, 
    -- 90-99
    13700, 13850, 13950, 14100, 14250, 14400, 14500, 14650, 14800, 14950, 
    -- 100-109
    15050, 15200, 15350, 15500, 15600, 15750, 15900, 16050, 16150, 16300, 
    -- 110-119
    16450, 16600, 16750, 16850, 17000, 17150, 17300, 17450, 17550, 17700
}
