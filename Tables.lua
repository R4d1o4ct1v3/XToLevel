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

XToLevel.XP_CLASSIC_ZERO_DIFFERENCE = {
    {["level"] = 1, ["divider"] = 5},
    {["level"] = 8, ["divider"] = 6},
    {["level"] = 10, ["divider"] = 7},
    {["level"] = 12, ["divider"] = 8},
    {["level"] = 16, ["divider"] = 9},
    {["level"] = 20, ["divider"] = 11},
    {["level"] = 30, ["divider"] = 12},
    {["level"] = 40, ["divider"] = 13},
    {["level"] = 45, ["divider"] = 14},
    {["level"] = 50, ["divider"] = 15},
    {["level"] = 55, ["divider"] = 16},
    {["level"] = 60, ["divider"] = 17} -- Future proofing, for if/when TBC is released.
}

XToLevel.QUEST_XP = {
    -- 1-9
    120, 260, 470, 600, 750, 925, 1000, 1150, 1300,
    -- 10-19
    1400, 1550, 1700, 1800, 1950, 2100, 2250, 2350, 2500, 2650,
    -- 20-29
    2750, 2900, 3050, 3150, 3300, 3450, 3600, 3700, 3850, 4000,
    -- 30-39
    4100, 4250, 4400, 4500, 4650, 4800, 4950, 5050, 5200, 5350, 
    -- 40-49
    5450, 5600, 5750, 5850, 6000, 6150, 6300, 6400, 6550, 6700, 
    -- 50-59
    6800, 6950, 6950, 7100, 7200, 7200, 7200, 7200, 7200, 7200
}

XToLevel.GATHERING_XP = {
	-- 1-9
	100, 100, 100, 100, 100, 100, 100, 100, 100,
	-- 10-19
	100, 100, 210, 230, 250, 260, 280, 300, 310, 330, 
	-- 20-29
	350, 370, 380, 400, 420, 430, 450, 470, 480, 500, 
	-- 30-39
	525, 525, 550, 575, 575, 600, 625, 625, 650, 675,
	-- 40-49
	675, 700, 725, 725, 750, 775, 775, 800, 825, 825,
	-- 50-59
	950, 975, 1000, 1050, 1050, 1050, 1100, 1100, 1100, 1150
}

XToLevel.RETAIL_XP_MATRIX = {
    [0]={["-1"]=nil},
    [1]={["-1"]=nil},
    [2]={["-1"]=nil},
    [3]={["-1"]=15},
    [4]={["-1"]=25},
    [5]={["-1"]=29},
    [6]={["-1"]=33},
    [7]={["-1"]=38},
    [8]={["-1"]=43},
    [9]={["-2"]=39, ["-1"]=47},
    [10]={["-1"]=nil},
    [11]={["-1"]=56},
    [12]={["-1"]=nil}, 
    [13]={["-1"]=72},
    [14]={["-1"]=nil},
    [15]={["-1"]=nil},
    [16]={["-1"]=79},
    [17]={["-1"]=83},
    [18]={["-1"]=88},
    [19]={["-1"]=92},
    [20]={["-1"]=89},
    [21]={["-1"]=nil},
    [22]={["-1"]=nil},
    [23]={["-1"]=101},
    [24]={["-1"]=nil},
    [25]={["-1"]=109},
    [26]={["-1"]=113},
    [27]={["-1"]=117},
    [28]={["-1"]=122},
    [29]={["-1"]=126},
    [30]={["-1"]=130},
    [31]={["-1"]=134},
    [32]={["-1"]=138},
    [33]={["-1"]=142},
    [34]={["-1"]=146},
    [35]={["-1"]=150},
    [36]={["-1"]=154},
    [37]={["-1"]=158},
    [38]={["-1"]=162},
    [39]={["-1"]=166},
    [40]={["-1"]=170},
    [41]={["-1"]=174},
    [42]={["-1"]=178},
    [43]={["-1"]=182},
    [44]={["-1"]=186},
    [45]={["-1"]=190},
    [46]={["-1"]=194},
    [47]={["-1"]=198},
    [48]={["-1"]=202},
    [49]={["-1"]=207},
    [50]={["-1"]=211},
    [51]={["-1"]=215},
    [52]={["-1"]=219},
    [53]={["-1"]=223},
    [54]={["-1"]=227},
    [55]={["-1"]=nil},
    [56]={["-1"]=nil},
    [57]={["-1"]=nil},
    [58]={["-1"]=nil},
    [59]={["-1"]=nil}
}