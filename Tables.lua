XToLevel.AVERAGE_WINDOWS =
{
    [1] = "Blocky",
    [2] = "Classic"
}

XToLevel.MAX_PLAYER_LEVELS =
{
    [0] = 60, -- Classic
    [1] = 70, -- Burning Crusade
    [2] = 80, -- WotLK
    [3] = 85, -- Cataclysm
    [4] = 90, -- ???
}

-- Zero Difference values. Used to calculate mob XP
XToLevel.ZD_Table = 
{ --  {min, max, value}
	{1, 7, 5},
	{8, 9, 6},
	{10, 11, 7},
	{12, 15, 8},
	{16, 19, 9},
	{20, 29, 11},
	{30, 39, 12},
	{40, 44, 13},
	{45, 49, 14},
	{50, 54, 15},
	{55, 59, 16},
	{60, 69, 17},
	{70, 80, 18},
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

XToLevel.DISPLAY_LOCALES =
{
    ["English"] = "enUS",
    ["Deutsch"] = "deDE",
    ["Français"] = "frFR",
    ["Español"] = "esES",
    ["Dansk"] = "dkDK",
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