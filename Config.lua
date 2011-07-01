---
-- Defines all data and functionality related to the configuration and per-char
-- data tables.
-- @file XToLevel.Config.lua
-- @release @project-version@
-- @copyright Atli Þór (atli.j@advefir.com)
---
--module "XToLevel.Config" -- For documentation purposes. Do not uncomment!

-- ----------------------------------------------------------------------------
-- Permanent config and data storage setup.
-- ----------------------------------------------------------------------------

---
-- Per-char configuration table.
-- @class table
sConfig = {
    general = {
		allowDrag = true,
		allowSettingsClick = true,
		displayLocale = nil,
		showDebug = false,
	    rafEnabled = false,
		showNpcTooltipData = true,
	},
    messages = {
		playerFloating = true,
		playerChat = false,
		bgObjectives = true,
		colors = {
			playerKill = {0.72, 1, 0.71, 1},
			playerQuest = {0.5, 1, 0.7, 1},
			playerBattleground = {1, 0.5, 0.5, 1},
			playerDungeon = {1, 0.75, 0.35, 1},
			playerLevel = {0.35, 1, 0.35, 1},
		},
	},
    averageDisplay = {
		visible = true,
		mode = 1, -- 1 = Blocky, 2 = Classic
        scale = 1.0,
		backdrop = true,
		verbose = true,
		colorText = true,
        header = true,
		tooltip = true,
		combineTooltip = false,
		orientation = 'v',
		playerKills = true,
		playerQuests = true,
		playerDungeons = true,
		playerBGs = true,
		playerBGOs = false,
        playerGathering = true,
		playerProgress = true,
		playerTimer = true,
		progress = true, -- Duplicate?
		progressAsBars = false,
		playerKillListLength = 10,
		playerQuestListLength = 10,
		playerBGListLength = 15,
		playerBGOListLength = 15,
		playerDungeonListLength = 15,
        guildProgress = true,
        guildProgressType = 1, -- 1 = Level, 2 = Daily, (3 = Overall... maybe later)
	},
	ldb = {
        enabled = true,
		allowTextColor = true,
		showIcon = true,
		showLabel = false,
		showText = true,
		textPattern = "default",
		text = {
			kills = true,
			quests = true,
			dungeons = true,
			bgs = true,
			bgo = false,
			xp = true,
			xpnum = true,
			xpnumFormat = true,
			xpAsBars = false,
			xpCountdown = false,
			timer = true,
            guildxp = true,
            guilddaily = true,
			colorValues = true,
			verbose = true,
			rested = true,
			restedp = true,
		},
		tooltip = {
			showDetails = true,
			showExperience = true,
			showBGInfo = true,
			showDungeonInfo = true,
			showTimerInfo = true,
            showGatheringInfo = true,
            showGuildInfo = true,
		}
	},
	timer = {
		enabled = true,
		mode = 1, -- 1 = session, 2 = level, 3 = kill range (3 is not implemented yet!)
		allowLevelFallback = true,
        -- The time the session data will remain after the UI is unloaded, in minutes.
        sessionDataTimeout = 5.0, 
	}
}
sData = {
	player = {
        total = {
            startedRecording = time(),
            mobKills = 0,
            dungeonKills = 0,
            pvpKills = 0,
            quests = 0,
            objectives = 0
        },
		killAverage = 0,
		questAverage = 0,
		killList = {},
		questList = {},
		bgList = {},
		dungeonList = {},
		timer = {
			start = nil,
			total = nil,
			xpPerSec = nil,
		},
        gathering = {},
        npcXP = { },
	},
	customPattern = nil,
}

-- ----------------------------------------------------------------------------
-- Config GUI Initialization
-- ----------------------------------------------------------------------------
XToLevel.Config = { }
XToLevel.Config.frames = { }

function XToLevel.Config:Initialize()
    LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("XToLevel", XToLevel.Config.GetOptions)

    StaticPopupDialogs['XToLevelConfig_ResetPlayerKills'] = {
		text = L['Reset Player Kill Dialog'],
		button1 = L["Yes"],
		button2 = L["No"],
		OnAccept = function()
			XToLevel.Player:ClearKills();
	        XToLevel.Average:Update();
	        XToLevel.LDB:BuildPattern();
	        XToLevel.LDB:Update();
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	StaticPopupDialogs['XToLevelConfig_ResetPlayerQuests'] = {
		text = L['Reset Player Quest Dialog'],
		button1 = L["Yes"],
		button2 = L["No"],
		OnAccept = function()
			XToLevel.Player:ClearQuests();
			XToLevel.Average:Update();
	        XToLevel.LDB:BuildPattern();
	        XToLevel.LDB:Update();
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	StaticPopupDialogs['XToLevelConfig_ResetBattles'] = {
		text = L['Reset Battleground Dialog'],
		button1 = L["Yes"],
		button2 = L["No"],
		OnAccept = function()
			XToLevel.Player:ClearBattlegrounds();
			XToLevel.Average:Update();
	        XToLevel.LDB:BuildPattern();
	        XToLevel.LDB:Update();
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	StaticPopupDialogs['XToLevelConfig_ResetDungeons'] = {
	    text = L['Reset Dungeon Dialog'],
	    button1 = L["Yes"],
	    button2 = L["No"],
	    OnAccept = function()
	        XToLevel.Player:ClearDungeonList();
	        XToLevel.Average:Update();
	        XToLevel.LDB:BuildPattern();
	        XToLevel.LDB:Update();
	    end,
	    timeout = 0,
	    whileDead = true,
	    hideOnEscape = true,
	}
    StaticPopupDialogs['XToLevelConfig_ResetTimer'] = {
	    text = L['Reset Timer Dialog'],
	    button1 = L["Yes"],
	    button2 = L["No"],
	    OnAccept = function()
	        sData.player.timer.start = GetTime()
			sData.player.timer.total = 0
			XToLevel.Average:UpdateTimer()
			XToLevel.LDB:UpdateTimer()
	    end,
	    timeout = 0,
	    whileDead = true,
	    hideOnEscape = true,
	}
    StaticPopupDialogs['XToLevelConfig_ResetGathering'] = {
	    text = L['Reset Gathering Dialog'],
	    button1 = L["Yes"],
	    button2 = L["No"],
	    OnAccept = function()
	        sData.player.gathering = { }
			XToLevel.Average:Update()
            XToLevel.LDB:BuildPattern();
			XToLevel.LDB:Update()
	    end,
	    timeout = 0,
	    whileDead = true,
	    hideOnEscape = true,
	}
    StaticPopupDialogs['XToLevelConfig_LdbReload'] = {
	    text = L['LDB Reload Dialog'],
	    button1 = L["Yes"],
	    button2 = L["No"],
	    OnAccept = function()
	        ReloadUI()
	    end,
	    timeout = 0,
	    whileDead = true,
	    hideOnEscape = true,
	}
    
    local head_frame_str = "XToLevel";
    local A3CFG = LibStub("AceConfigDialog-3.0")
    self.frames.Information = A3CFG:AddToBlizOptions("XToLevel", head_frame_str, nil, "Information")
    self.frames.General = A3CFG:AddToBlizOptions("XToLevel", L["General Tab"], head_frame_str, "General")
    self.frames.Messages = A3CFG:AddToBlizOptions("XToLevel", L["Messages Tab"], head_frame_str, "Messages")
    self.frames.Window = A3CFG:AddToBlizOptions("XToLevel", L["Window Tab"], head_frame_str, "Window")
    self.frames.LDB = A3CFG:AddToBlizOptions("XToLevel", L["LDB Tab"], head_frame_str, "LDB")
    self.frames.Data = A3CFG:AddToBlizOptions("XToLevel", L["Data Tab"], head_frame_str, "Data")
    self.frames.Tooltip = A3CFG:AddToBlizOptions("XToLevel", L["Tooltip"], head_frame_str, "Tooltip")
    self.frames.Timer = A3CFG:AddToBlizOptions("XToLevel", L["Timer"], head_frame_str, "Timer")
end

function XToLevel.Config:Open(frameName)
    if self.frames[frameName] then
        InterfaceOptionsFrame_OpenToCategory(self.frames[frameName]);
    end
end

XToLevel.Config.options = nil
function XToLevel.Config:GetOptions()
    return {

name = "XToLevel",
type = "group",
handler = XToLevel.Config,
args = {
    Information = {
        type = "group",
        name = "General",
        args = {
            addonDescription = {
                order = 0,
                type = "description",
                name = L['MainDescription'],
            },
            infoHeader = {
                order = 1,
                type = "header",
                name = "AddOn Information",
            },
            infoVersion = {
                order = 2,
                type = "description",
                name = "|cFFFFAA00" .. L["Version"] .. ":|r |cFF00FF00" .. tostring(XToLevel.version) .."|r |cFFAAFFAA(" .. tostring(XToLevel.releaseDate) .. ")",
            },
            infoAuthor = {
                order = 3,
                type = "description",
                name = "|cFFFFAA00" .. L["Author"] .. ":|r |cFFE07B02" .. "Atli þór Jónsson",
            },
            infoEmail = {
                order = 4,
                type = "description",
                name = "|cFFFFAA00" .. L["Email"] .. ":|r |cFFFFFFFF" .. "atli.j@advefir.com",
            },
            infoWebsite = {
                order = 5,
                type = "description",
                name = "|cFFFFAA00" .. L["Website"] .. ":|r |cFFFFFFFF" .. "http://wow.curseforge.com/addons/xto-level/",
            },
            infoCategory = {
                order = 6,
                type = "description",
                name = "|cFFFFAA00" .. L["Category"] .. ":|r |cFFFFFFFF" .. "Quests & Leveling, Battlegrounds, Dungeons.",
            },
            infoLicense = {
                order = 7,
                type = "description",
                name = "|cFFFFAA00" .. L["License"] .. ":|r |cFFFFFFFF" .. L['All Rights Reserved'] .. " (See LICENSE.txt)",
            },
        }
    },
    General = {
        type = "group",
        name = "General",
        args = {
            localeHeader = {
                order = 0,
                type = "header",
                name = "Locale",
            },
            localeSelect = {
                order = 1,
                type = "select",
                name = "Display locale",
                style = "dropdown",
                values = XToLevel.DISPLAY_LOCALES,
                get = "GetLocale",
                set = "SetLocale",
            },
            debugHeader = {
                order = 2,
                type = "header",
                name = "Misc",
            },
            debugEnabled = {
                order = 3,
                type = "toggle",
                name = L["Show Debug Info"],
                desc = "If enabled, shows details used during development. Not in any way useful for typical users.",
                get = function(info) return sConfig.general.showDebug end,
                set = function(info, value) sConfig.general.showDebug = value end,
            },
            rafEnabled = {
                order = 4,
                type = "toggle",
                name = L['Recruit A Friend'],
                desc = L["RAF Description"],
                get = function(info) return sConfig.general.rafEnabled end,
                set = function(info, value) sConfig.general.rafEnabled = value end,
            },
        }
    },
    Messages = {
        type = "group",
        name = L["Messages Tab"],
        args = {
            playerHeader = {
                order = 0,
                type = "header",
                name = L['Player Messages'],
            },
            playerFloating = {
                order = 1,
                type = "toggle",
                name = L['Show Floating'],
                get = function(info) return sConfig.messages.playerFloating end,
                set = function(info, value) sConfig.messages.playerFloating = value end,
            },
            playerChat = {
                order = 2,
                type = "toggle",
                name = L['Show In Chat'],
                get = function(info) return sConfig.messages.playerChat end,
                set = function(info, value) sConfig.messages.playerChat = value end,
            },
            playerBG = {
                order = 3,
                type = "toggle",
                name =L['Show BG Objectives'],
                get = function(info) return sConfig.messages.bgObjectives end,
                set = function(info, value) sConfig.messages.bgObjectives = value end,
            },
            colorsHeader = {
                order = 4,
                type = "header",
                name = L['Message Colors'],
            },
            colorKills = {
                order = 5,
                type = "color",
                name = L['Player Kills'],
                hasAlpha = true,
                get = function(info) return unpack(sConfig.messages.colors.playerKill) end,
                set = function(info, r, g, b, a) sConfig.messages.colors.playerKill = {r, g, b, a} end,
            },
            colorQuests = {
                order = 6,
                type = "color",
                name = L['Player Quests'],
                hasAlpha = true,
                get = function(info) return unpack(sConfig.messages.colors.playerQuest) end,
                set = function(info, r, g, b, a) sConfig.messages.colors.playerQuest = {r, g, b, a} end,
            },
            colorDungeons = {
                order = 7,
                type = "color",
                name = L['Player Dungeons'],
                hasAlpha = true,
                get = function(info) return unpack(sConfig.messages.colors.playerDungeon) end,
                set = function(info, r, g, b, a) sConfig.messages.colors.playerDungeon = {r, g, b, a} end,
            },
            colorBattles = {
                order = 8,
                type = "color",
                name = L['Player Battles'],
                hasAlpha = true,
                get = function(info) return unpack(sConfig.messages.colors.playerBattleground) end,
                set = function(info, r, g, b, a) sConfig.messages.colors.playerBattleground = {r, g, b, a} end,
            },
            colorLevelup = {
                order = 9,
                type = "color",
                name = L['Player Levelup'],
                hasAlpha = true,
                get = function(info) return unpack(sConfig.messages.colors.playerLevel) end,
                set = function(info, r, g, b, a) sConfig.messages.colors.playerLevel = {r, g, b, a} end,
            },
            colorResetHeader = {
                order = 10,
                type = "header",
                name = "",
            },
            colorResetBtn = {
                order = 11,
                type = "execute",
                name = L['Color Reset'],
                func = function() StaticPopup_Show("XToLevelConfig_MessageColorsReset") end,
            },
        },
    },
    Window = {
        type = "group",
        name = L["Window Tab"],
        args = {
            windowSelect = {
                order = 0,
                type = "select",
                style = "dropdown",
                name = L["Active Window Header"],
                desc = "Sets the style of the addon window.",
                values = XToLevel.AVERAGE_WINDOWS,
                get = "GetActiveWindow",
                set = "SetActiveWindow",
            },
            windowScale = {
                order = 1,
                type = "range",
                name = L["Window Size"] .. " (%)",
                min = 0.5,
                max = 2.0,
                step = 0.05,
                isPercent = true,
                width = "full",
                get = function(info) return sConfig.averageDisplay.scale end,
                set = function(info, value)
                    sConfig.averageDisplay.scale = value
                    XToLevel.Average:Update()
                end,
            },
            classicHeader = {
                order = 2,
                type = "header",
                name = L["Classic Specific Options"],
            },
            classicShowBackdrop = {
                order = 3,
                type = "toggle",
                name = L["Show Window Frame"],
                get = function(info) return sConfig.averageDisplay.backdrop end,
                set = function(info, value) 
                    sConfig.averageDisplay.backdrop = value 
                    XToLevel.Average:Update()
                end,
            },
            classicShowHeader = {
                order = 4,
                type = "toggle",
                name = L["Show XToLevel Header"],
                get = function(info) return sConfig.averageDisplay.header end,
                set = function(info, value) 
                    sConfig.averageDisplay.header = value 
                    XToLevel.Average:Update()
                end,
            },
            classicShowVerbose = {
                order = 5,
                type = "toggle",
                name = L["Show Verbose Text"],
                get = function(info) return sConfig.averageDisplay.verbose end,
                set = function(info, value) 
                    sConfig.averageDisplay.verbose = value 
                    XToLevel.Average:Update()
                end,
            },
            classicShowColored = {
                order = 6,
                type = "toggle",
                name = L["Show Colored Text"],
                get = function(info) return sConfig.averageDisplay.colorText end,
                set = function(info, value) 
                    sConfig.averageDisplay.colorText = value 
                    XToLevel.Average:Update()
                end,
            },
            blockyHeader = {
                order = 7,
                type = "header",
                name = L["Blocky Specific Options"],
            },
            blockyVerticalAlign = {
                order = 8,
                type = "toggle",
                name = L["Vertical Align"],
                get = function(info) return sConfig.averageDisplay.orientation == "v" end,
                set = function(info, value) 
                    sConfig.averageDisplay.orientation = value and "v" or "h"
                    XToLevel.Average:Update()
                end,
            },
            behaviorHeader = {
                order = 9,
                type = "header",
                name = L["Window Behavior Header"],
            },
            behaviorLocked = {
                order = 10,
                type = "toggle",
                name = L["Lock Avarage Display"],
                get = function(info) return not sConfig.general.allowDrag end,
                set = function(info, value) 
                    sConfig.general.allowDrag = not value 
                end,
            },
            behaviorAllowClick = {
                order = 11,
                type = "toggle",
                name = L["Allow Average Click"],
                get = function(info) return sConfig.general.allowSettingsClick end,
                set = function(info, value) 
                    sConfig.general.allowSettingsClick = value 
                end,
            },
            behaviorShowTooltip = {
                order = 12,
                type = "toggle",
                name = L["Show Tooltip"],
                get = function(info) return sConfig.averageDisplay.tooltip end,
                set = function(info, value) 
                    sConfig.averageDisplay.tooltip = value 
                end,
            },
            behaviorCombineTooltip = {
                order = 13,
                type = "toggle",
                name = L["Combine Tooltip Data"],
                get = function(info) return sConfig.averageDisplay.combineTooltip end,
                set = function(info, value) 
                    sConfig.averageDisplay.combineTooltip = value 
                end,
            },
            behaviorProgressAsBars = {
                order = 14,
                type = "toggle",
                name = L["Progress As Bars"],
                get = function(info) return sConfig.averageDisplay.progressAsBars end,
                set = function(info, value) 
                    sConfig.averageDisplay.progressAsBars = value 
                    XToLevel.Average:Update()
                end,
            },
            dataHeader = {
                order = 15,
                type = "header",
                name = L["LDB Player Data Header"],
            },
            dataKills = {
                order = 16,
                type = "toggle",
                name = L["Kills"],
                get = function(info) return sConfig.averageDisplay.playerKills end,
                set = function(info, value) 
                    sConfig.averageDisplay.playerKills = value 
                    XToLevel.Average:Update()   
                end,
            },
            dataQuests = {
                order = 17,
                type = "toggle",
                name = L["Player Quests"],
                get = function(info) return sConfig.averageDisplay.playerQuests end,
                set = function(info, value) 
                    sConfig.averageDisplay.playerQuests = value 
                    XToLevel.Average:Update()   
                end,
            },
            dataDungeons = {
                order = 18,
                type = "toggle",
                name = L["Player Dungeons"],
                get = function(info) return sConfig.averageDisplay.playerDungeons end,
                set = function(info, value) 
                    sConfig.averageDisplay.playerDungeons = value 
                    XToLevel.Average:Update()   
                end,
            },
            dataBattles = {
                order = 19,
                type = "toggle",
                name = L["Player Battles"],
                get = function(info) return sConfig.averageDisplay.playerBGs end,
                set = function(info, value) 
                    sConfig.averageDisplay.playerBGs = value 
                    XToLevel.Average:Update()   
                end,
            },
            dataBattleObjectives = {
                order = 20,
                type = "toggle",
                name = L["Player Objectives"],
                get = function(info) return sConfig.averageDisplay.playerBGOs end,
                set = function(info, value) 
                    sConfig.averageDisplay.playerBGOs = value 
                    XToLevel.Average:Update()   
                end,
            },
            dataProgress = {
                order = 21,
                type = "toggle",
                name = L["Player Progress"],
                get = function(info) return sConfig.averageDisplay.playerProgress end,
                set = function(info, value) 
                    sConfig.averageDisplay.playerProgress = value 
                    XToLevel.Average:Update()   
                end,
            },
            dataTimer = {
                order = 22,
                type = "toggle",
                name = L["Player Timer"] or "Timer",
                get = function(info) return sConfig.averageDisplay.playerTimer end,
                set = function(info, value) 
                    sConfig.averageDisplay.playerTimer = value 
                    XToLevel.Average:Update()   
                end,
            },
            dataGathering = {
                order = 23,
                type = "toggle",
                name = L["Gathering"] or "Gathering",
                get = function(info) return sConfig.averageDisplay.playerGathering end,
                set = function(info, value) 
                    sConfig.averageDisplay.playerGathering = value 
                    XToLevel.Average:Update()   
                end,
            },
        }
    },
    LDB = {
        type = "group",
        name = L["LDB Tab"],
        args = {
            ldbEnabled = {
                order = 0,
                type = "toggle",
                name = L["LDB Enabled"],
                desc = L['LDB Enabled Description'],
                get = function(i) return sConfig.ldb.enabled end,
                set = function(i, v) 
                    sConfig.ldb.enabled = v
                    StaticPopup_Show("XToLevelConfig_LdbReload")
                end
            },

            ldbPresetHeader = {
                order = 1,
                type = "header",
                name = "LDB Patterns",
            },
            ldbPatternSelect = {
                order = 2,
                type = "select",
                style = "dropdown",
                name = "Style",
                values = XToLevel.LDB_PATTERNS,
                get = "GetLdbPattern",
                set = "SetLdbPattern",
            },
            ldbPatternInput = {
                order = 3,
                type = "input",
                name = "Custom Pattern",
                desc = "See the 'customPatterns.txt' file for more details. Requires that the 'Custom' preset is selected.",
                width = "full",
                multiline = true,
                get = function(i) return sData.customPattern end,
                set = function(i,v) 
                    sData.customPattern = v 
                    XToLevel.LDB:BuildPattern()
                    XToLevel.LDB:Update()
                end,
            },

            ldbAppearenceHeader = {
                order = 4,
                type = "header",
                name = L["LDB Appearence Header"],
            },
            ldbShowText = {
                order = 5,
                type = "toggle",
                name = L["Show Text"],
                get = function(i) return sConfig.ldb.showText end,
                set = function(i,v) sConfig.ldb.showText = v end,
            },
            ldbShowLabel = {
                order = 6,
                type = "toggle",
                name = L["Show Label"],
                get = function(i) return sConfig.ldb.showLabel end,
                set = function(i,v) sConfig.ldb.showLabel = v end,
            },
            ldbShowIcon = {
                order = 7,
                type = "toggle",
                name = L["Show Icon"],
                get = function(i) return sConfig.ldb.showIcon end,
                set = function(i,v) sConfig.ldb.showIcon = v end,
            },
            ldbColoredText = {
                order = 8,
                type = "toggle",
                name = L["Allow Colored Text"],
                get = function(i) return sConfig.ldb.allowTextColor end,
                set = function(i,v) sConfig.ldb.allowTextColor = v end,
            },
            ldbColorByXp = {
                order = 9,
                type = "toggle",
                name = L["Color By XP"],
                get = function(i) return sConfig.ldb.text.colorValues end,
                set = function(i,v) sConfig.ldb.text.colorValues = v end,
            },
            ldbProgressAsBars = {
                order = 10,
                type = "toggle",
                name = L["Show Progress As Bars"],
                get = function(i) return sConfig.ldb.text.xpAsBars end,
                set = function(i,v) sConfig.ldb.text.xpAsBars = v end,
            },
            ldbShowVerbose = {
                order = 11,
                type = "toggle",
                name = L["Show Verbose"],
                get = function(i) return sConfig.ldb.text.verbose end,
                set = function(i,v) sConfig.ldb.text.verbose = v end,
            },
            ldbShowXpRemaining = {
                order = 12,
                type = "toggle",
                name = L["Show XP remaining"],
                get = function(i) return sConfig.ldb.text.xpCountdown end,
                set = function(i,v) sConfig.ldb.text.xpCountdown = v end,
            },
            ldbShortenXP = {
                order = 13,
                type = "toggle",
                name = L["Shorten XP values"],
                get = function(i) return sConfig.ldb.text.xpnumFormat end,
                set = function(i,v) sConfig.ldb.text.xpnumFormat = v end,
            },

            ldbDataHeader = {
                order = 14,
                type = "header",
                name = L['LDB Player Data Header'],
            },
            ldbDataKills = {
                order = 16,
                type = "toggle",
                name = L["Player Kills"],
                get = function(i) return sConfig.ldb.text.kills end,
                set = function(i,v) sConfig.ldb.text.kills = v end,
            },
            ldbDataQuests = {
                order = 17,
                type = "toggle",
                name = L["Player Quests"],
                get = function(i) return sConfig.ldb.text.quests end,
                set = function(i,v) sConfig.ldb.text.quests = v end,
            },
            ldbDataDungeons = {
                order = 18,
                type = "toggle",
                name = L["Player Dungeons"],
                get = function(i) return sConfig.ldb.text.dungeons end,
                set = function(i,v) sConfig.ldb.text.dungeons = v end,
            },
            ldbDataBattles = {
                order = 19,
                type = "toggle",
                name = L["Player Battles"],
                get = function(i) return sConfig.ldb.text.bgs end,
                set = function(i,v) sConfig.ldb.text.bgs = v end,
            },
            ldbDataObjectives = {
                order = 20,
                type = "toggle",
                name = L["Player Objectives"],
                get = function(i) return sConfig.ldb.text.bgo end,
                set = function(i,v) sConfig.ldb.text.bgo = v end,
            },
            ldbDataProgress = {
                order = 21,
                type = "toggle",
                name = L["Player Progress"],
                get = function(i) return sConfig.ldb.text.xp end,
                set = function(i,v) sConfig.ldb.text.xp = v end,
            },
            ldbDataExperience = {
                order = 22,
                type = "toggle",
                name = L["Player Experience"],
                get = function(i) return sConfig.ldb.text.xpnum end,
                set = function(i,v) sConfig.ldb.text.xpnum = v end,
            },
        }
    },
    Data = {
        type = "group",
        name = L["Data Tab"],
        args = {
            dataRangeHeader = {
                order = 0,
                type = "header",
                name = L['Data Range Header'],
            },
            dataRangeDescription = {
                order = 1,
                type = "description",
                name = L["Data Range Subheader"],
            },
            dataRangeKills = {
                order = 2,
                type = "range",
                name = L["Player Kills"],
                min = 1,
                max = 100,
                step = 1,
                get = function() return sConfig.averageDisplay.playerKillListLength end,
                set = function(i,v) sConfig.averageDisplay.playerKillListLength = v end,
            },
            dataRangeQuests = {
                order = 3,
                type = "range",
                name = L["Player Quests"],
                min = 1,
                max = 100,
                step = 1,
                get = function() return sConfig.averageDisplay.playerQuestListLength end,
                set = function(i,v) sConfig.averageDisplay.playerQuestListLength = v end,
            },
            dataRangeBattles = {
                order = 4,
                type = "range",
                name = L["Player Battles"],
                min = 1,
                max = 100,
                step = 1,
                get = function() return sConfig.averageDisplay.playerBGListLength end,
                set = function(i,v) sConfig.averageDisplay.playerBGListLength = v end,
            },
            dataRangeObjectives = {
                order = 5,
                type = "range",
                name = L["Player Objectives"],
                min = 1,
                max = 100,
                step = 1,
                get = function() return sConfig.averageDisplay.playerBGOListLength end,
                set = function(i,v) sConfig.averageDisplay.playerBGOListLength = v end,
            },
            dataRangeDungeons = {
                order = 6,
                type = "range",
                name = L["Player Dungeons"],
                min = 1,
                max = 100,
                step = 1,
                get = function() return sConfig.averageDisplay.playerDungeonListLength end,
                set = function(i,v) sConfig.averageDisplay.playerDungeonListLength = v end,
            },
            dataClearHeader = {
                order = 7,
                type = "header",
                name = L['Clear Data Header'],
            },
            dataClearDescription = {
                order = 8,
                type = "description",
                name = L["Clear Data Subheader"],
            },
            dataClearKills = {
                order = 9,
                type = "execute",
                name = L["Reset Player Kills"],
                func = function() StaticPopup_Show("XToLevelConfig_ResetPlayerKills")  end,
            },
            dataClearQuests = {
                order = 10,
                type = "execute",
                name = L["Reset Player Quests"],
                func = function() StaticPopup_Show("XToLevelConfig_ResetPlayerQuests")  end,
            },
            dataClearDungeons = {
                order = 11,
                type = "execute",
                name = L["Reset Dungeons"],
                func = function() StaticPopup_Show("XToLevelConfig_ResetDungeons")  end,
            },
            dataClearBattles = {
                order = 12,
                type = "execute",
                name = L["Reset Battlegrounds"],
                func = function() StaticPopup_Show("XToLevelConfig_ResetBattles")  end,
            },
            dataClearGathering = {
                order = 13,
                type = "execute",
                name = L["Reset Gathering"],
                func = function() StaticPopup_Show("XToLevelConfig_ResetGathering")  end,
            },
        }
    },
    Tooltip = {
        type = "group",
        name = L["Tooltip"],
        args = {
            sectionsHeader = {
                order = 1,
                type = "header",
                name = L["Tooltip Sections Header"],
            },
            playerDetails = {
                order = 2,
                type = "toggle",
                name = L["Show Player Details"],
                get = function(i) return sConfig.ldb.tooltip.showDetails end,
                set = function(i,v) sConfig.ldb.tooltip.showDetails = v end,
            },
            playerExperience = {
                order = 3,
                type = "toggle",
                name = L["Show Player Experience"],
                get = function(i) return sConfig.ldb.tooltip.showExperience end,
                set = function(i,v) sConfig.ldb.tooltip.showExperience = v end,
            },
            battleInfo = {
                order = 4,
                type = "toggle",
                name = L["Show Battleground Info"],
                get = function(i) return sConfig.ldb.tooltip.showBGInfo end,
                set = function(i,v) sConfig.ldb.tooltip.showBGInfo = v end,
            },
            dungeonInfo = {
                order = 5,
                type = "toggle",
                name = L["Show Dungeon Info"],
                get = function(i) return sConfig.ldb.tooltip.showDungeonInfo end,
                set = function(i,v) sConfig.ldb.tooltip.showDungeonInfo = v end,
            },
            gatheringInfo = {
                order = 6,
                type = "toggle",
                name = L["Show Gathering Info"],
                get = function(i) return sConfig.ldb.tooltip.showGatheringInfo end,
                set = function(i,v) sConfig.ldb.tooltip.showGatheringInfo = v end,
            },
            timerDetails = {
                order = 7,
                type = "toggle",
                name = L["Show Timer Details"],
                get = function(i) return sConfig.ldb.tooltip.showTimerInfo end,
                set = function(i,v) sConfig.ldb.tooltip.showTimerInfo = v end,
            },
            miscHeader = {
                order = 8,
                type = "header",
                name = "Misc",
            },
            npcTooltipData = {
                order = 9,
                type = "toggle",
                name = "Show kills needed in NPC tooltips.",
                get = function(i) return sConfig.general.showNpcTooltipData end,
                set = function(i,v) sConfig.general.showNpcTooltipData = v end,
            },
        }
    },
    Timer = {
        type = "group",
        name = L["Timer"],
        args = {
            enableTimer = {
                order = 0,
                type = "toggle",
                name = L["Enable timer"] or "Timer enabled",
                get = function() return sConfig.timer.enabled end,
                set = "SetTimerEnabled",
            },
            modeHeader = {
                order = 1,
                type = "header",
                name = L["Mode"],
            },
            modeSelect = {
                order = 2,
                type = "select",
                style = "dropdown",
                values = XToLevel.TIMER_MODES,
                name = L["Mode"],
                desc = "The source of the data used for the timer. - \"Session\" uses only the XP gained since the UI was loaded. Ideal as a \"real-time\" estimate while farming. - \"Level\" uses the total time and XP this level. Gives a better long-term estimate for quest and dungeon runners. (Note that the Level mode may be fairly inaccurate during the first few % of a new level.)",
                get = function() return sConfig.timer.mode end,
                set = function(i,v) sConfig.timer.mode = v end,
            },
            timerReset = {
                order = 3,
                type = "execute",
                name = "Reset",
                desc = "Resets the session counter.",
                func = function() StaticPopup_Show("XToLevelConfig_ResetTimer") end,
            },
            timeoutHeader = {
                order = 4,
                type = "header",
                name = "Session Timeout",
            },
            timoutRange = {
                order = 5,
                type = "range",
                name = "Timeout in minutes",
                desc = "Sets how long you can stay logged off before the session data is thrown away. Note that when a session is restored, it will behave as if you never logged of; as if you were simply AFK. The accuracy of the data will therefore degrade more and more the longer you stay away.",
                min = 0,
                max = 60,
                step = 1,
                get = function() return sConfig.timer.sessionDataTimeout end,
                set = function(i,v) sConfig.timer.sessionDataTimeout = v end,
            },
        }
    },
},
    }
end

-- ----------------------------------------------------------------------------
-- Config GUI callbacks
-- ----------------------------------------------------------------------------

function XToLevel.Config:SetLocale(info, value)
    StaticPopupDialogs['XToLevelConfig_LocaleReload'] = {
		text = L['Config Language Reload Prompt'],
		button1 = L["Yes"],
		button2 = L["No"],
		OnAccept = function() 
            sConfig.general.displayLocale = value
            ReloadUI()
        end,
		timeout = 30,
		whileDead = true,
		hideOnEscape = true,
	}
	StaticPopup_Show("XToLevelConfig_LocaleReload");
end
function XToLevel.Config:GetLocale(info)
    return sConfig.general.displayLocale
end

function XToLevel.Config:SetActiveWindow(info, value)
    sConfig.averageDisplay.mode = value
    XToLevel.Average:Update()
end
function XToLevel.Config:GetActiveWindow(info)
    return sConfig.averageDisplay.mode
end

function XToLevel.Config:SetLdbPattern(info, value)
    local thestr = nil
    for i, v in ipairs(XToLevel.LDB_PATTERNS) do
        if i == value then
            thestr = v
        end
    end
    if thestr then
        sConfig.ldb.textPattern = thestr
        XToLevel.LDB:BuildPattern()
        XToLevel.LDB:Update()
    else
        console:log("Could not switch pattern. Pattern not found...")
    end
end
function XToLevel.Config:GetLdbPattern(info)
    for i, v in ipairs(XToLevel.LDB_PATTERNS) do
        if sConfig.ldb.textPattern == v then
            return i
        end
    end
end

function SetTimerEnabled(info, value)
    sConfig.timer.enabled = value
    if sConfig.timer.enabled then
		XToLevel.Player.timerHandler = XToLevel.timer:ScheduleRepeatingTimer(XToLevel.Player.TriggerTimerUpdate, XToLevel.Player.xpPerSecTimeout)
	else
		XToLevel.timer:CancelTimer(XToLevel.Player.timerHandler)
	end
    XToLevel.Average:UpdateTimer(nil)
	XToLevel.LDB:UpdateTimer()
end
-- ----------------------------------------------------------------------------
-- Config table verification
-- ----------------------------------------------------------------------------

---
-- Verifies that all config values have a default value
-- (New values are sometimes not initialized if older versions of saved values exist)
function XToLevel.Config:Verify()
    -- General
    if sConfig.general == nil then sConfig.general = {  } end
    if sConfig.general.allowDrag == nil then sConfig.general.allowDrag = true end
    if sConfig.general.showDebug == nil then sConfig.general.showDebug = false end
    if sConfig.general.allowSettingsClick == nil then sConfig.general.allowSettingsClick = true end
    if sConfig.general.displayLocale == nil then sConfig.general.displayLocale = GetLocale() end
    if sConfig.general.rafEnabled == nil then sConfig.general.rafEnabled = false end
	if sConfig.general.showNpcTooltipData == nil then sConfig.general.showNpcTooltipData = true end
    
    -- Messages
    if sConfig.messages == nil then sConfig.messages = {  } end
    if sConfig.messages.playerFloating == nil then sConfig.messages.playerFloating = true end
    if sConfig.messages.playerChat == nil then sConfig.messages.playerChat = false end
    if sConfig.messages.bgObjectives == nil then sConfig.messages.bgObjectives = true end
    
    -- Message Colors
    if sConfig.messages.colors == nil then sConfig.messages.colors = {} end
    if sConfig.messages.colors.playerKill == nil then sConfig.messages.colors.playerKill = {0.72, 1, 0.71, nil} end
    if sConfig.messages.colors.playerQuest == nil then sConfig.messages.colors.playerQuest = {0.5, 1, 0.7, nil} end
    if sConfig.messages.colors.playerBattleground == nil then sConfig.messages.colors.playerBattleground = {1, 0.5, 0.5, nil} end
    if sConfig.messages.colors.playerDungeon == nil then sConfig.messages.colors.playerDungeon = {1, 0.75, 0.35, nil} end
    if sConfig.messages.colors.playerLevel == nil then sConfig.messages.colors.playerLevel = {0.35, 1, 0.35, nil} end

    if sConfig.messages.colors.playerKill[4] ~= nil then sConfig.messages.colors.playerKill[4] = nil end
    if sConfig.messages.colors.playerQuest[4] ~= nil then sConfig.messages.colors.playerQuest[4] = nil end
    if sConfig.messages.colors.playerBattleground[4] ~= nil then sConfig.messages.colors.playerBattleground[4] = nil end
    if sConfig.messages.colors.playerDungeon[4] ~= nil then sConfig.messages.colors.playerDungeon[4] = nil end
    if sConfig.messages.colors.playerLevel[4] ~= nil then sConfig.messages.colors.playerLevel[4] = nil end

    -- averageDisplay
    if sConfig.averageDisplay == nil then sConfig.averageDisplay = {  } end
    if sConfig.averageDisplay.visible == nil then sConfig.averageDisplay.visible = true end
    if sConfig.averageDisplay.mode == nil then sConfig.averageDisplay.mode = 1 end
    if sConfig.averageDisplay.scale == nil then sConfig.averageDisplay.scale = 1.0 end
    if sConfig.averageDisplay.backdrop == nil then sConfig.averageDisplay.backdrop = true end
    if sConfig.averageDisplay.verbose == nil then sConfig.averageDisplay.verbose = true end
    if sConfig.averageDisplay.tooltip == nil then sConfig.averageDisplay.tooltip = true end
    if sConfig.averageDisplay.combineTooltip == nil then sConfig.averageDisplay.combineTooltip = false end
    if sConfig.averageDisplay.orientation == nil then sConfig.averageDisplay.orientation = 'v' end
    if sConfig.averageDisplay.colorText == nil then sConfig.averageDisplay.colorText = true end
    if sConfig.averageDisplay.header == nil then sConfig.averageDisplay.header = true end
    if sConfig.averageDisplay.playerKills == nil then sConfig.averageDisplay.playerKills = true end
    if sConfig.averageDisplay.playerQuests == nil then sConfig.averageDisplay.playerQuests = true end
    if sConfig.averageDisplay.playerDungeons == nil then sConfig.averageDisplay.playerDungeons = true end
    if sConfig.averageDisplay.playerBGs == nil then sConfig.averageDisplay.playerBGs = true end
    if sConfig.averageDisplay.playerBGOs == nil then sConfig.averageDisplay.playerBGOs = false end
    if sConfig.averageDisplay.playerGathering == nil then sConfig.averageDisplay.playerGathering = true end
    if sConfig.averageDisplay.playerProgress == nil then sConfig.averageDisplay.playerProgress = true end
	if sConfig.averageDisplay.playerTimer == nil then sConfig.averageDisplay.playerTimer = true end
    if sConfig.averageDisplay.progress == nil then sConfig.averageDisplay.progress = true end
    if sConfig.averageDisplay.progressAsBars == nil then sConfig.averageDisplay.progressAsBars = false end
    if sConfig.averageDisplay.playerKillListLength == nil then sConfig.averageDisplay.playerKillListLength = 10 end
    if sConfig.averageDisplay.playerQuestListLength == nil then sConfig.averageDisplay.playerQuestListLength = 10 end
    if sConfig.averageDisplay.playerBGListLength == nil then sConfig.averageDisplay.playerBGListLength = 15 end
    if sConfig.averageDisplay.playerBGOListLength == nil then sConfig.averageDisplay.playerBGOListLength = 15 end
    if sConfig.averageDisplay.playerDungeonListLength == nil then sConfig.averageDisplay.playerDungeonListLength = 15 end
    if sConfig.averageDisplay.guildProgress == nil then sConfig.averageDisplay.guildProgress = true end
    if sConfig.averageDisplay.guildProgressType == nil then sConfig.averageDisplay.guildProgressType = 1 end

    -- LDB
    if sConfig.ldb == nil then sConfig.ldb = {  } end
    if sConfig.ldb.text == nil then sConfig.ldb.text = {  } end
    
    if sConfig.ldb.tooltip == nil then sConfig.ldb.tooltip = {  } end
    if sConfig.ldb.allowTextColor == nil then sConfig.ldb.allowTextColor = true end
    if sConfig.ldb.enabled == nil then sConfig.ldb.enabled = true end
    if sConfig.ldb.showIcon == nil then sConfig.ldb.showIcon = true end
    if sConfig.ldb.showLabel == nil then sConfig.ldb.showLabel = false end
    if sConfig.ldb.showText == nil then sConfig.ldb.showText = true end
    if sConfig.ldb.textPattern == nil then sConfig.ldb.textPattern = "default" end
    if sConfig.ldb.text.kills == nil then sConfig.ldb.text.kills = true end
    if sConfig.ldb.text.quests == nil then sConfig.ldb.text.quests = true end
    if sConfig.ldb.text.dungeons == nil then sConfig.ldb.text.dungeons = true end
    if sConfig.ldb.text.bgs == nil then sConfig.ldb.text.bgs = true end
    if sConfig.ldb.text.bgo == nil then sConfig.ldb.text.bgo = false end
    if sConfig.ldb.text.xp == nil then sConfig.ldb.text.xp = true end
    if sConfig.ldb.text.xpAsBars == nil then sConfig.ldb.text.xpAsBars = false end
	if sConfig.ldb.text.timer == nil then sConfig.ldb.text.timer = true end
    if sConfig.ldb.text.guildxp == nil then sConfig.ldb.text.guildxp = true end
    if sConfig.ldb.text.guilddaily == nil then sConfig.ldb.text.guilddaily = true end
    if sConfig.ldb.text.verbose == nil then sConfig.ldb.text.verbose = true end
    if sConfig.ldb.text.colorValues == nil then sConfig.ldb.text.colorValues = true end
	
	if sConfig.ldb.text.xpCountdown == nil then sConfig.ldb.text.xpCountdown = false end
	if sConfig.ldb.text.rested == nil then sConfig.ldb.text.rested = true end
	if sConfig.ldb.text.restedp == nil then sConfig.ldb.text.restedp = true end
	
	if sConfig.ldb.text.xpnum == nil then sConfig.ldb.text.xpnum = true end
	if sConfig.ldb.text.xpnumFormat == nil then sConfig.ldb.text.xpnumFormat = true end
	
    if sConfig.ldb.tooltip.showDetails == nil then sConfig.ldb.tooltip.showDetails = true end
    if sConfig.ldb.tooltip.showExperience == nil then sConfig.ldb.tooltip.showExperience = true end
    if sConfig.ldb.tooltip.showBGInfo == nil then sConfig.ldb.tooltip.showBGInfo = true end
    if sConfig.ldb.tooltip.showDungeonInfo == nil then sConfig.ldb.tooltip.showDungeonInfo = true end
    if sConfig.ldb.tooltip.showTimerInfo == nil then sConfig.ldb.tooltip.showTimerInfo = true end
    if sConfig.ldb.tooltip.showGuildInfo ~= false then sConfig.ldb.tooltip.showGuildInfo = false end -- TODO: Fix this when the guild stuff actually works.
    if sConfig.ldb.tooltip.showGatheringInfo == nil then sConfig.ldb.tooltip.showGatheringInfo = true end
	
	if sConfig.timer == nil then sConfig.timer = { } end
	if sConfig.timer.enabled == nil then sConfig.timer.enabled = true end
	if sConfig.timer.mode == nil then sConfig.timer.mode = 1 end
	if sConfig.timer.allowLevelFallback == nil then sConfig.timer.allowLevelFallback = 1 end
    if sConfig.timer.sessionDataTimeout == nil then sConfig.timer.sessionDataTimeout = 5.0 end
    
    
    if sData == nil then sData = {} end
    if sData.player == nil then sData.player = {} end
    
    if sData.player.total == nil then sData.player.total = { } end
    if sData.player.total.startedRecording == nil then sData.player.total.startedRecording = time() end
    if sData.player.total.mobKills == nil then sData.player.total.mobKills = 0 end
    if sData.player.total.dungeonKills == nil then sData.player.total.dungeonKills = 0 end
    if sData.player.total.pvpKills == nil then sData.player.total.pvpKills = 0 end
    if sData.player.total.quests == nil then sData.player.total.quests = 0 end
    if sData.player.total.objectives == nil then sData.player.total.objectives = 0 end
    
    if sData.player.killAverage == nil then sData.player.killAverage = 0 end
    if sData.player.questAverage == nil then sData.player.questAverage = 0 end
    if sData.player.killList == nil then sData.player.killList = {} end
    if sData.player.questList == nil then sData.player.questList = {} end
    if sData.player.bgList == nil then sData.player.bgList = {} end
    if sData.player.dungeonList == nil then sData.player.dungeonList = {} end
    if sData.player.gathering == nil then sData.player.gathering = {} end
    if sData.player.npcXP == nil then sData.player.npcXP = {} end
	
    if sData.customPattern == nil then sData.customPattern = 0 end
	
	-- Timer data.
    if sData.player.timer == nil then sData.player.timer = {} end
    if sData.player.timer.start == nil then sData.player.timer.start = GetTime() end
    if sData.player.timer.total == nil then sData.player.timer.total = 0 end
    if sData.player.timer.xpPerSec == nil then sData.player.timer.xpPerSec = 0 end
    -- if sData.player.timer.lastUpdated == nil then sData.player.timer.lastUpdated = 0 end
    
    if type(sData.player.timer.lastUpdated) ~= "number" or GetTime() - sData.player.timer.lastUpdated > (sConfig.timer.sessionDataTimeout * 60) or GetTime() - sData.player.timer.start <= 0 then
        sData.player.timer.start = GetTime();
        sData.player.timer.total = 0;
        sData.player.timer.lastUpdated = GetTime();
    end
	
    
    -- Dungeon data
    --for index, value in ipairs(sData.player.dungeonList) do
    for index = 1, # sData.player.dungeonList, 1 do
    	if not sData.player.dungeonList[index].rested then
    		sData.player.dungeonList[index].rested = 0
    	end
    end
    
end
