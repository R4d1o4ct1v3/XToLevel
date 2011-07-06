---
-- Defines all data and functionality related to the configuration and per-char
-- data tables.
-- @file XToLevel.Config.lua
-- @release @project-version@
-- @copyright Atli Þór (atli.j@advefir.com)
---
--module "XToLevel.Config" -- For documentation purposes. Do not uncomment!

-- ----------------------------------------------------------------------------
-- Config GUI Initialization
-- ----------------------------------------------------------------------------
XToLevel.Config = { }
XToLevel.Config.frames = { }

function XToLevel.Config:Initialize()
    LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("XToLevel", XToLevel.Config.GetOptions)

    StaticPopupDialogs['XToLevelConfig_MessageColorsReset'] = {
		text = L["Color Reset Dialog"],
		button1 = L["Yes"],
		button2 = L["No"],
		OnAccept = function()
			XToLevel.db.profile.messages.colors = {
				playerKill = {0.72, 1, 0.71, 1},
				playerQuest = {0.5, 1, 0.7, 1},
				playerBattleground = {1, 0.5, 0.5, 1},
				playerDungeon = {1, 0.75, 0.35, 1},
				playerLevel = {0.35, 1, 0.35, 1},
			};
			XToLevel.Config:Open("Messages")
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}

    StaticPopupDialogs['XToLevelConfig_ResetPlayerKills'] = {
		text = L["Reset Player Kill Dialog"],
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
		text = L["Reset Player Quest Dialog"],
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
		text = L["Reset Battleground Dialog"],
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
	    text = L["Reset Dungeon Dialog"],
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
	    text = L["Reset Timer Dialog"],
	    button1 = L["Yes"],
	    button2 = L["No"],
	    OnAccept = function()
	        XToLevel.db.char.data.timer.start = GetTime()
			XToLevel.db.char.data.timer.total = 0
			XToLevel.Average:UpdateTimer()
			XToLevel.LDB:UpdateTimer()
	    end,
	    timeout = 0,
	    whileDead = true,
	    hideOnEscape = true,
	}
    StaticPopupDialogs['XToLevelConfig_ResetGathering'] = {
	    text = L["Reset Gathering Dialog"],
	    button1 = L["Yes"],
	    button2 = L["No"],
	    OnAccept = function()
	        XToLevel.db.char.data.gathering = { }
			XToLevel.Average:Update()
            XToLevel.LDB:BuildPattern();
			XToLevel.LDB:Update()
	    end,
	    timeout = 0,
	    whileDead = true,
	    hideOnEscape = true,
	}
    StaticPopupDialogs['XToLevelConfig_LdbReload'] = {
	    text = L["LDB Reload Dialog"],
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
                name = L["MainDescription"],
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
                name = "|cFFFFAA00" .. L["License"] .. ":|r |cFFFFFFFF" .. L["All Rights Reserved"] .. " (See LICENSE.txt)",
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
                name = L["Locale Header"],
            },
            localeSelect = {
                order = 1,
                type = "select",
                name = L["Locale Select"],
                desc = L["Locale Select Description"],
                style = "dropdown",
                values = XToLevel.DISPLAY_LOCALES,
                get = "GetLocale",
                set = "SetLocale",
            },
            debugHeader = {
                order = 2,
                type = "header",
                name = L["Misc Header"],
            },
            debugEnabled = {
                order = 3,
                type = "toggle",
                name = L["Show Debug Info"],
                desc = L["Debug Info Description"],
                get = function(info) return XToLevel.db.profile.general.showDebug end,
                set = function(info, value) XToLevel.db.profile.general.showDebug = value end,
            },
            rafEnabled = {
                order = 4,
                type = "toggle",
                name = L["Recruit A Friend"],
                desc = L["RAF Description"],
                get = function(info) return XToLevel.db.profile.general.rafEnabled end,
                set = function(info, value) XToLevel.db.profile.general.rafEnabled = value end,
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
                name = L["Player Messages"],
            },
            playerFloating = {
                order = 1,
                type = "toggle",
                name = L["Show Floating"],
                get = function(info) return XToLevel.db.profile.messages.playerFloating end,
                set = function(info, value) XToLevel.db.profile.messages.playerFloating = value end,
            },
            playerChat = {
                order = 2,
                type = "toggle",
                name = L["Show In Chat"],
                get = function(info) return XToLevel.db.profile.messages.playerChat end,
                set = function(info, value) XToLevel.db.profile.messages.playerChat = value end,
            },
            playerBG = {
                order = 3,
                type = "toggle",
                name =L["Show BG Objectives"],
                get = function(info) return XToLevel.db.profile.messages.bgObjectives end,
                set = function(info, value) XToLevel.db.profile.messages.bgObjectives = value end,
            },
            colorsHeader = {
                order = 4,
                type = "header",
                name = L["Message Colors"],
            },
            colorKills = {
                order = 5,
                type = "color",
                name = L["Player Kills"],
                hasAlpha = true,
                get = function(info) return unpack(XToLevel.db.profile.messages.colors.playerKill) end,
                set = function(info, r, g, b, a) XToLevel.db.profile.messages.colors.playerKill = {r, g, b, a} end,
            },
            colorQuests = {
                order = 6,
                type = "color",
                name = L["Player Quests"],
                hasAlpha = true,
                get = function(info) return unpack(XToLevel.db.profile.messages.colors.playerQuest) end,
                set = function(info, r, g, b, a) XToLevel.db.profile.messages.colors.playerQuest = {r, g, b, a} end,
            },
            colorDungeons = {
                order = 7,
                type = "color",
                name = L["Player Dungeons"],
                hasAlpha = true,
                get = function(info) return unpack(XToLevel.db.profile.messages.colors.playerDungeon) end,
                set = function(info, r, g, b, a) XToLevel.db.profile.messages.colors.playerDungeon = {r, g, b, a} end,
            },
            colorBattles = {
                order = 8,
                type = "color",
                name = L["Player Battles"],
                hasAlpha = true,
                get = function(info) return unpack(XToLevel.db.profile.messages.colors.playerBattleground) end,
                set = function(info, r, g, b, a) XToLevel.db.profile.messages.colors.playerBattleground = {r, g, b, a} end,
            },
            colorLevelup = {
                order = 9,
                type = "color",
                name = L["Player Levelup"],
                hasAlpha = true,
                get = function(info) return unpack(XToLevel.db.profile.messages.colors.playerLevel) end,
                set = function(info, r, g, b, a) XToLevel.db.profile.messages.colors.playerLevel = {r, g, b, a} end,
            },
            colorResetHeader = {
                order = 10,
                type = "header",
                name = "",
            },
            colorResetBtn = {
                order = 11,
                type = "execute",
                name = L["Color Reset"],
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
                desc = L["Active Window Description"],
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
                get = function(info) return XToLevel.db.profile.averageDisplay.scale end,
                set = function(info, value)
                    XToLevel.db.profile.averageDisplay.scale = value
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
                get = function(info) return XToLevel.db.profile.averageDisplay.backdrop end,
                set = function(info, value) 
                    XToLevel.db.profile.averageDisplay.backdrop = value 
                    XToLevel.Average:Update()
                end,
            },
            classicShowHeader = {
                order = 4,
                type = "toggle",
                name = L["Show XToLevel Header"],
                get = function(info) return XToLevel.db.profile.averageDisplay.header end,
                set = function(info, value) 
                    XToLevel.db.profile.averageDisplay.header = value 
                    XToLevel.Average:Update()
                end,
            },
            classicShowVerbose = {
                order = 5,
                type = "toggle",
                name = L["Show Verbose Text"],
                get = function(info) return XToLevel.db.profile.averageDisplay.verbose end,
                set = function(info, value) 
                    XToLevel.db.profile.averageDisplay.verbose = value 
                    XToLevel.Average:Update()
                end,
            },
            classicShowColored = {
                order = 6,
                type = "toggle",
                name = L["Show Colored Text"],
                get = function(info) return XToLevel.db.profile.averageDisplay.colorText end,
                set = function(info, value) 
                    XToLevel.db.profile.averageDisplay.colorText = value 
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
                get = function(info) return XToLevel.db.profile.averageDisplay.orientation == "v" end,
                set = function(info, value) 
                    XToLevel.db.profile.averageDisplay.orientation = value and "v" or "h"
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
                get = function(info) return not XToLevel.db.profile.general.allowDrag end,
                set = function(info, value) 
                    XToLevel.db.profile.general.allowDrag = not value 
                end,
            },
            behaviorAllowClick = {
                order = 11,
                type = "toggle",
                name = L["Allow Average Click"],
                get = function(info) return XToLevel.db.profile.general.allowSettingsClick end,
                set = function(info, value) 
                    XToLevel.db.profile.general.allowSettingsClick = value 
                end,
            },
            behaviorShowTooltip = {
                order = 12,
                type = "toggle",
                name = L["Show Tooltip"],
                get = function(info) return XToLevel.db.profile.averageDisplay.tooltip end,
                set = function(info, value) 
                    XToLevel.db.profile.averageDisplay.tooltip = value 
                end,
            },
            behaviorCombineTooltip = {
                order = 13,
                type = "toggle",
                name = L["Combine Tooltip Data"],
                get = function(info) return XToLevel.db.profile.averageDisplay.combineTooltip end,
                set = function(info, value) 
                    XToLevel.db.profile.averageDisplay.combineTooltip = value 
                end,
            },
            behaviorProgressAsBars = {
                order = 14,
                type = "toggle",
                name = L["Progress As Bars"],
                get = function(info) return XToLevel.db.profile.averageDisplay.progressAsBars end,
                set = function(info, value) 
                    XToLevel.db.profile.averageDisplay.progressAsBars = value 
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
                get = function(info) return XToLevel.db.profile.averageDisplay.playerKills end,
                set = function(info, value) 
                    XToLevel.db.profile.averageDisplay.playerKills = value 
                    XToLevel.Average:Update()   
                end,
            },
            dataQuests = {
                order = 17,
                type = "toggle",
                name = L["Player Quests"],
                get = function(info) return XToLevel.db.profile.averageDisplay.playerQuests end,
                set = function(info, value) 
                    XToLevel.db.profile.averageDisplay.playerQuests = value 
                    XToLevel.Average:Update()   
                end,
            },
            dataDungeons = {
                order = 18,
                type = "toggle",
                name = L["Player Dungeons"],
                get = function(info) return XToLevel.db.profile.averageDisplay.playerDungeons end,
                set = function(info, value) 
                    XToLevel.db.profile.averageDisplay.playerDungeons = value 
                    XToLevel.Average:Update()   
                end,
            },
            dataBattles = {
                order = 19,
                type = "toggle",
                name = L["Player Battles"],
                get = function(info) return XToLevel.db.profile.averageDisplay.playerBGs end,
                set = function(info, value) 
                    XToLevel.db.profile.averageDisplay.playerBGs = value 
                    XToLevel.Average:Update()   
                end,
            },
            dataBattleObjectives = {
                order = 20,
                type = "toggle",
                name = L["Player Objectives"],
                get = function(info) return XToLevel.db.profile.averageDisplay.playerBGOs end,
                set = function(info, value) 
                    XToLevel.db.profile.averageDisplay.playerBGOs = value 
                    XToLevel.Average:Update()   
                end,
            },
            dataProgress = {
                order = 21,
                type = "toggle",
                name = L["Player Progress"],
                get = function(info) return XToLevel.db.profile.averageDisplay.playerProgress end,
                set = function(info, value) 
                    XToLevel.db.profile.averageDisplay.playerProgress = value 
                    XToLevel.Average:Update()   
                end,
            },
            dataTimer = {
                order = 22,
                type = "toggle",
                name = L["Player Timer"],
                get = function(info) return XToLevel.db.profile.averageDisplay.playerTimer end,
                set = function(info, value) 
                    XToLevel.db.profile.averageDisplay.playerTimer = value 
                    XToLevel.Average:Update()   
                end,
            },
            dataGathering = {
                order = 23,
                type = "toggle",
                name = L["Gathering"] or "Gathering",
                get = function(info) return XToLevel.db.profile.averageDisplay.playerGathering end,
                set = function(info, value) 
                    XToLevel.db.profile.averageDisplay.playerGathering = value 
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
                desc = L["LDB Enabled Description"],
                get = function(i) return XToLevel.db.profile.ldb.enabled end,
                set = function(i, v) 
                    XToLevel.db.profile.ldb.enabled = v
                    StaticPopup_Show("XToLevelConfig_LdbReload")
                end
            },

            ldbPresetHeader = {
                order = 1,
                type = "header",
                name = L["LDB Patterns Header"],
            },
            ldbPatternSelect = {
                order = 2,
                type = "select",
                style = "dropdown",
                name = L["LDB Pattern Select"],
                values = XToLevel.LDB_PATTERNS,
                get = "GetLdbPattern",
                set = "SetLdbPattern",
            },
            ldbPatternInput = {
                order = 3,
                type = "input",
                name = L["Custom Pattern Label"],
                desc = L["Custom Pattern Description"],
                width = "full",
                multiline = true,
                get = function(i) return XToLevel.db.char.customPattern end,
                set = function(i,v) 
                    XToLevel.db.char.customPattern = v 
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
                get = function(i) return XToLevel.db.profile.ldb.showText end,
                set = function(i,v) 
                    XToLevel.db.profile.ldb.showText = v
                    XToLevel.LDB:BuildPattern()
                    XToLevel.LDB:Update()
                end,
            },
            ldbShowLabel = {
                order = 6,
                type = "toggle",
                name = L["Show Label"],
                get = function(i) return XToLevel.db.profile.ldb.showLabel end,
                set = function(i,v) 
                    XToLevel.db.profile.ldb.showLabel = v
                    XToLevel.LDB:BuildPattern()
                    XToLevel.LDB:Update()
                end,
            },
            ldbShowIcon = {
                order = 7,
                type = "toggle",
                name = L["Show Icon"],
                get = function(i) return XToLevel.db.profile.ldb.showIcon end,
                set = function(i,v) 
                    XToLevel.db.profile.ldb.showIcon = v
                    XToLevel.LDB:BuildPattern()
                    XToLevel.LDB:Update()
                end,
            },
            ldbColoredText = {
                order = 8,
                type = "toggle",
                name = L["Allow Colored Text"],
                get = function(i) return XToLevel.db.profile.ldb.allowTextColor end,
                set = function(i,v) 
                    XToLevel.db.profile.ldb.allowTextColor = v
                    XToLevel.LDB:BuildPattern()
                    XToLevel.LDB:Update()
                end,
            },
            ldbColorByXp = {
                order = 9,
                type = "toggle",
                name = L["Color By XP"],
                get = function(i) return XToLevel.db.profile.ldb.text.colorValues end,
                set = function(i,v) 
                    XToLevel.db.profile.ldb.text.colorValues = v
                    XToLevel.LDB:BuildPattern()
                    XToLevel.LDB:Update()
                end,
            },
            ldbProgressAsBars = {
                order = 10,
                type = "toggle",
                name = L["Show Progress As Bars"],
                get = function(i) return XToLevel.db.profile.ldb.text.xpAsBars end,
                set = function(i,v) 
                    XToLevel.db.profile.ldb.text.xpAsBars = v
                    XToLevel.LDB:BuildPattern()
                    XToLevel.LDB:Update()
                end,
            },
            ldbShowVerbose = {
                order = 11,
                type = "toggle",
                name = L["Show Verbose"],
                get = function(i) return XToLevel.db.profile.ldb.text.verbose end,
                set = function(i,v) 
                    XToLevel.db.profile.ldb.text.verbose = v
                    XToLevel.LDB:BuildPattern()
                    XToLevel.LDB:Update()
                end,
            },
            ldbShowXpRemaining = {
                order = 12,
                type = "toggle",
                name = L["Show XP remaining"],
                get = function(i) return XToLevel.db.profile.ldb.text.xpCountdown end,
                set = function(i,v) 
                    XToLevel.db.profile.ldb.text.xpCountdown = v
                    XToLevel.LDB:BuildPattern()
                    XToLevel.LDB:Update()
                end,
            },
            ldbShortenXP = {
                order = 13,
                type = "toggle",
                name = L["Shorten XP values"],
                get = function(i) return XToLevel.db.profile.ldb.text.xpnumFormat end,
                set = function(i,v) 
                    XToLevel.db.profile.ldb.text.xpnumFormat = v
                    XToLevel.LDB:BuildPattern()
                    XToLevel.LDB:Update()
                end,
            },

            ldbDataHeader = {
                order = 14,
                type = "header",
                name = L["LDB Player Data Header"],
            },
            ldbDataKills = {
                order = 16,
                type = "toggle",
                name = L["Player Kills"],
                get = function(i) return XToLevel.db.profile.ldb.text.kills end,
                set = function(i,v) 
                    XToLevel.db.profile.ldb.text.kills = v
                    XToLevel.LDB:BuildPattern()
                    XToLevel.LDB:Update()
                end,
            },
            ldbDataQuests = {
                order = 17,
                type = "toggle",
                name = L["Player Quests"],
                get = function(i) return XToLevel.db.profile.ldb.text.quests end,
                set = function(i,v) 
                    XToLevel.db.profile.ldb.text.quests = v
                    XToLevel.LDB:BuildPattern()
                    XToLevel.LDB:Update()
                end,
            },
            ldbDataDungeons = {
                order = 18,
                type = "toggle",
                name = L["Player Dungeons"],
                get = function(i) return XToLevel.db.profile.ldb.text.dungeons end,
                set = function(i,v) 
                    XToLevel.db.profile.ldb.text.dungeons = v
                    XToLevel.LDB:BuildPattern()
                    XToLevel.LDB:Update()
                end,
            },
            ldbDataBattles = {
                order = 19,
                type = "toggle",
                name = L["Player Battles"],
                get = function(i) return XToLevel.db.profile.ldb.text.bgs end,
                set = function(i,v) 
                    XToLevel.db.profile.ldb.text.bgs = v
                    XToLevel.LDB:BuildPattern()
                    XToLevel.LDB:Update()
                end,
            },
            ldbDataObjectives = {
                order = 20,
                type = "toggle",
                name = L["Player Objectives"],
                get = function(i) return XToLevel.db.profile.ldb.text.bgo end,
                set = function(i,v) 
                    XToLevel.db.profile.ldb.text.bgo = v
                    XToLevel.LDB:BuildPattern()
                    XToLevel.LDB:Update()
                end,
            },
            ldbDataProgress = {
                order = 21,
                type = "toggle",
                name = L["Player Progress"],
                get = function(i) return XToLevel.db.profile.ldb.text.xp end,
                set = function(i,v) 
                    XToLevel.db.profile.ldb.text.xp = v
                    XToLevel.LDB:BuildPattern()
                    XToLevel.LDB:Update()
                end,
            },
            ldbDataExperience = {
                order = 22,
                type = "toggle",
                name = L["Player Experience"],
                get = function(i) return XToLevel.db.profile.ldb.text.xpnum end,
                set = function(i,v) 
                    XToLevel.db.profile.ldb.text.xpnum = v
                    XToLevel.LDB:BuildPattern()
                    XToLevel.LDB:Update()
                end,
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
                name = L["Data Range Header"],
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
                get = function() return XToLevel.db.profile.averageDisplay.playerKillListLength end,
                set = function(i,v) XToLevel.Player:SetKillAverageLength(v) end,
            },
            dataRangeQuests = {
                order = 3,
                type = "range",
                name = L["Player Quests"],
                min = 1,
                max = 100,
                step = 1,
                get = function() return XToLevel.db.profile.averageDisplay.playerQuestListLength end,
                set = function(i,v) XToLevel.Player:SetQuestAverageLength(v) end,
            },
            dataRangeBattles = {
                order = 4,
                type = "range",
                name = L["Player Battles"],
                min = 1,
                max = 100,
                step = 1,
                get = function() return XToLevel.db.profile.averageDisplay.playerBGListLength end,
                set = function(i,v) XToLevel.Player:SetBattleAverageLength(v) end,
            },
            dataRangeObjectives = {
                order = 5,
                type = "range",
                name = L["Player Objectives"],
                min = 1,
                max = 100,
                step = 1,
                get = function() return XToLevel.db.profile.averageDisplay.playerBGOListLength end,
                set = function(i,v) XToLevel.Player:SetObjectiveAverageLength(v) end,
            },
            dataRangeDungeons = {
                order = 6,
                type = "range",
                name = L["Player Dungeons"],
                min = 1,
                max = 100,
                step = 1,
                get = function() return XToLevel.db.profile.averageDisplay.playerDungeonListLength end,
                set = function(i,v) XToLevel.Player:SetDungeonAverageLength(v) end,
            },
            dataClearHeader = {
                order = 7,
                type = "header",
                name = L["Clear Data Header"],
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
                get = function(i) return XToLevel.db.profile.ldb.tooltip.showDetails end,
                set = function(i,v) XToLevel.db.profile.ldb.tooltip.showDetails = v end,
            },
            playerExperience = {
                order = 3,
                type = "toggle",
                name = L["Show Player Experience"],
                get = function(i) return XToLevel.db.profile.ldb.tooltip.showExperience end,
                set = function(i,v) XToLevel.db.profile.ldb.tooltip.showExperience = v end,
            },
            battleInfo = {
                order = 4,
                type = "toggle",
                name = L["Show Battleground Info"],
                get = function(i) return XToLevel.db.profile.ldb.tooltip.showBGInfo end,
                set = function(i,v) XToLevel.db.profile.ldb.tooltip.showBGInfo = v end,
            },
            dungeonInfo = {
                order = 5,
                type = "toggle",
                name = L["Show Dungeon Info"],
                get = function(i) return XToLevel.db.profile.ldb.tooltip.showDungeonInfo end,
                set = function(i,v) XToLevel.db.profile.ldb.tooltip.showDungeonInfo = v end,
            },
            gatheringInfo = {
                order = 6,
                type = "toggle",
                name = L["Show Gathering Info"],
                get = function(i) return XToLevel.db.profile.ldb.tooltip.showGatheringInfo end,
                set = function(i,v) XToLevel.db.profile.ldb.tooltip.showGatheringInfo = v end,
            },
            timerDetails = {
                order = 7,
                type = "toggle",
                name = L["Show Timer Details"],
                get = function(i) return XToLevel.db.profile.ldb.tooltip.showTimerInfo end,
                set = function(i,v) XToLevel.db.profile.ldb.tooltip.showTimerInfo = v end,
            },
            miscHeader = {
                order = 8,
                type = "header",
                name = L["Misc Header"],
            },
            npcTooltipData = {
                order = 9,
                type = "toggle",
                name = L["Show kills needed in NPC tooltips"],
                get = function(i) return XToLevel.db.profile.general.showNpcTooltipData end,
                set = function(i,v) XToLevel.db.profile.general.showNpcTooltipData = v end,
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
                name = L["Enable Timer"],
                get = function() return XToLevel.db.profile.timer.enabled end,
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
                desc = L["Timer mode description"],
                get = function() return XToLevel.db.profile.timer.mode end,
                set = function(i,v) XToLevel.db.profile.timer.mode = v end,
            },
            timerReset = {
                order = 3,
                type = "execute",
                name = L["Timer Reset"],
                desc = L["Timer Reset Description"],
                func = function() StaticPopup_Show("XToLevelConfig_ResetTimer") end,
            },
            timeoutHeader = {
                order = 4,
                type = "header",
                name = L["Session Timeout Header"],
            },
            timoutRange = {
                order = 5,
                type = "range",
                name = L["Session Timeout Label"],
                desc = L["Session Timeout Description"],
                min = 0,
                max = 60,
                step = 1,
                get = function() return XToLevel.db.profile.timer.sessionDataTimeout end,
                set = function(i,v) XToLevel.db.profile.timer.sessionDataTimeout = v end,
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
		text = L["Config Language Reload Prompt"],
		button1 = L["Yes"],
		button2 = L["No"],
		OnAccept = function() 
            XToLevel.db.profile.general.displayLocale = value
            ReloadUI()
        end,
		timeout = 30,
		whileDead = true,
		hideOnEscape = true,
	}
	StaticPopup_Show("XToLevelConfig_LocaleReload");
end
function XToLevel.Config:GetLocale(info)
    return XToLevel.db.profile.general.displayLocale
end

function XToLevel.Config:SetActiveWindow(info, value)
    XToLevel.db.profile.averageDisplay.mode = value
    XToLevel.Average:Update()
end
function XToLevel.Config:GetActiveWindow(info)
    return XToLevel.db.profile.averageDisplay.mode
end

function XToLevel.Config:SetLdbPattern(info, value)
    local thestr = nil
    for i, v in ipairs(XToLevel.LDB_PATTERNS) do
        if i == value then
            thestr = v
        end
    end
    if thestr then
        XToLevel.db.profile.ldb.textPattern = thestr
        XToLevel.LDB:BuildPattern()
        XToLevel.LDB:Update()
    else
        console:log("Could not switch pattern. Pattern not found...")
    end
end
function XToLevel.Config:GetLdbPattern(info)
    for i, v in ipairs(XToLevel.LDB_PATTERNS) do
        if XToLevel.db.profile.ldb.textPattern == v then
            return i
        end
    end
end

function XToLevel.Config:SetTimerEnabled(info, value)
    XToLevel.db.profile.timer.enabled = value
    if XToLevel.db.profile.timer.enabled then
		XToLevel.Player.timerHandler = XToLevel.timer:ScheduleRepeatingTimer(XToLevel.Player.TriggerTimerUpdate, XToLevel.Player.xpPerSecTimeout)
	else
		XToLevel.timer:CancelTimer(XToLevel.Player.timerHandler)
	end
    XToLevel.Average:UpdateTimer(nil)
	XToLevel.LDB:UpdateTimer()
end
-- ----------------------------------------------------------------------------
-- Default config values.
-- ----------------------------------------------------------------------------

function XToLevel.Config:GetDefaults()
    return {
        profile = {
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
	        },
        },
        char = {
            data = {
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
    }
end

---
-- Verifies that the config and data values are in order.
-- This is mostly used to make sure changes to the permanent storage
-- don't cause regression bugs.
function XToLevel.Config:Verify()

    -- If the old sData and sConfig tables are set, overwrite the current Ace3
    -- DB tables with them, then clear them out.
    if sData and type(sData) == "table" then
        XToLevel.db.char.customPattern = sData.customPattern
        XToLevel.db.char.data = sData.player
        sData = nil
        -- print("|cFF00FFAAXToLevel:|r Character database saved.")
    end
    if sConfig and type(sConfig) == "table" then
        -- NOTE! Simply overwriting the db.profile table doesn't seem to
        -- permanently store the table. The profile keys must be set induvidually.
        XToLevel.db.profile.general = sConfig.general
        XToLevel.db.profile.messages = sConfig.messages
        XToLevel.db.profile.averageDisplay = sConfig.averageDisplay
        XToLevel.db.profile.ldb = sConfig.ldb
        XToLevel.db.profile.timer = sConfig.timer
        sConfig = nil
        -- print("|cFF00FFAAXToLevel:|r Profile settings saved.")
    end

    if type(XToLevel.db.char.data.timer.lastUpdated) ~= "number" or GetTime() - XToLevel.db.char.data.timer.lastUpdated > (XToLevel.db.profile.timer.sessionDataTimeout * 60) or GetTime() - XToLevel.db.char.data.timer.start <= 0 then
        XToLevel.db.char.data.timer.start = GetTime();
        XToLevel.db.char.data.timer.total = 0;
        XToLevel.db.char.data.timer.lastUpdated = GetTime();
    end
    
    -- Dungeon data
    --for index, value in ipairs(XToLevel.db.char.data.dungeonList) do
    for index = 1, # XToLevel.db.char.data.dungeonList, 1 do
    	if not XToLevel.db.char.data.dungeonList[index].rested then
    		XToLevel.db.char.data.dungeonList[index].rested = 0
    	end
    end
end
