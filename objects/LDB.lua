---
-- Contains definitions for the LDB data source.
-- @file XToLevel.Display.lua
-- @release @project-version@
-- @copyright Atli Þór (atli.j@advefir.com)
---
--module "XToLevel.Tooltip" -- For documentation purposes. Do not uncomment!

XToLevel.LDB = 
{
    -- Constants
    textPatterns = {
        default = "{kills}{$seperator: }{color=cfcfdf}{$label}:{/color} {progress}{$value}{/progress}{/kills}{quests}{$seperator: }{color=cfcfdf}{$label}:{/color} {progress}{$value}{/progress}{/quests}{dungeons}{$seperator: }{color=cfcfdf}{$label}:{/color} {progress}{$value}{/progress}{/dungeons}{bgs}{$seperator: }{color=cfcfdf}{$label}:{/color} {progress}{$value}{/progress}{/bgs}{bgo}{$seperator: }{color=cfcfdf}{$label}:{/color} {progress}{$value}{/progress}{/bgo}{xp}{$seperator: }{progress}[{$value}]{/progress}{/xp}",
        minimal = "{kills}{progress}{$value}{/progress}{/kills}{quests}{color=cfcfdf}{$seperator:/}{/color}{progress}{$value}{/progress}{/quests}{dungeons}{color=cfcfdf}{$seperator:/}{/color}{progress}{$value}{/progress}{/dungeons}{bgs}{color=cfcfdf}{$seperator:/}{/color}{progress}{$value}{/progress}{/bgs}{xp}{color=cfcfdf}{$seperator:/}{/color}{progress}{$value}{/progress}{/xp}",
        minimal_dashed = "{kills}{progress}{$value}{/progress}{/kills}{quests}{color=cfcfdf}{$seperator:-}{/color}{progress}{$value}{/progress}{/quests}{dungeons}{color=cfcfdf}{$seperator:-}{/color}{progress}{$value}{/progress}{/dungeons}{bgs}{color=cfcfdf}{$seperator:-}{/color}{progress}{$value}{/progress}{/bgs}{xp}{color=cfcfdf}{$seperator:-}{/color}{progress}{$value}{/progress}{/xp}",
        brackets = "{kills}{progress}[{$value}]{/progress}{/kills}{quests}{progress}[{$value}]{/progress}{/quests}{dungeons}{progress}[{$value}]{/progress}{/dungeons}{bgs}{progress}[{$value}]{/progress}{/bgs}{xp}{progress}[{$value}]{/progress}{/xp}",
		countdown = "{xpnum}{color=cfcfdf}XP:{/color}{$seperator: }{progress}{$value}{/progress}{xp} {color=cfcfdf}({/color}{progress}{$value}{/progress}{color=cfcfdf}){/color}{/xp}{$seperator: }{/xpnum}{rested}{color=cfcfdf}R:{/color}{$seperator: }{progress}{$value}{/progress} {restedp}{color=cfcfdf}({/color}{progress}{$value}{/progress}{color=cfcfdf}){/color}{/restedp}{$seperator: }{/rested}",
    },
    textTags = {
        [1] = { tag = "kills", label = 'init', value = '~', color = nil, },
        [2] = { tag = "quests", label = 'init', value = '~', color = nil, },
        [3] = { tag = "dungeons", label = 'init', value = '~', color = nil, }, 
        [4] = { tag = "bgs", label = 'init', value = '~', color = nil, }, 
        [5] = { tag = "bgo", label = 'init', value = '~', color = nil, }, 
        [6] = { tag = "xp", label = 'init', value = '~', color = nil, },
		[7] = { tag = "restedp", label = 'init', value = '~', color = nil, },
		[8] = { tag = "rested", label = 'init', value = '~', color = nil, },
		[9] = { tag = "xpnum", label = 'init', value = '~', color = nil, },
        [10] = { tag = "guildxp", label = 'init', value = '~', color = nil, },
        [11] = { tag = "guilddaily", label = 'init', value = '~', color = nil },
    },

    -- Members
    dataObject = nil,
    mouseOver = false,
    currentPattern = nil,
	
	-- Timer members
	timerObject = nil,
	timerMouseOver = false,
	timerLabelShown = true,
        
    ---
    -- Constructor
    Initialize = function(self)
        if not XToLevel.db.profile.ldb.enabled or (XToLevel.Player:GetMaxLevel() == XToLevel.Player.level and XToLevel.Player:GetClass() ~= "HUNTER")then
            return;
        end

        self.timerLabelShown = XToLevel.db.profile.ldb.showLabel

        -- Initialize the data object
        local iconName = (UnitFactionGroup("player") == "Alliance") and "INV_Jewelry_TrinketPVP_01" or "INV_Jewelry_TrinketPVP_02"
        local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
        self.dataObject = ldb:NewDataObject("XToLevel", {
            type = "data source",
            icon = "Interface\\Icons\\" .. iconName,
            text = "XToLevel",
            label = XToLevel.db.profile.ldb.showLabel and L["XToLevel"] or nil,
            version = XToLevel.version,
            align = "right",
            ["X-Category"] = "Information"
        });
        ldb = nil;
        
        -- Set data object events
        function self.dataObject:OnEnter()
            XToLevel.LDB.mouseOver = true;
            local a1, f1, a2 = XToLevel.Lib:FindAnchor(self);
            XToLevel.Tooltip:Show(self, a1, f1, a2, L['Click To Configure']);
        end
        function self.dataObject:OnLeave()
            XToLevel.LDB.mouseOver = false;
            XToLevel.Tooltip:Hide()
        end
        function self.dataObject:OnClick(button)
			XToLevel.Config:Open("LDB")
        end
        
        self:BuildPattern();-- /run XToLevel.LDB:BuildPattern(); XToLevel.LDB:Update();
        self:Update();
		
		self:InitializeTimer()
    end,
	
	InitializeTimer = function(self)
        if not XToLevel.db.profile.ldb.enabled or (XToLevel.Player:GetMaxLevel() == XToLevel.Player.level and XToLevel.Player:GetClass() ~= "HUNTER")then
            return;
        end
		-- Initialize the data object
        local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
        self.timerObject = ldb:NewDataObject("TimeToLevel", {
            type = "data source",
            icon = "Interface\\Icons\\inv_misc_pocketwatch_01",
            text = L["Updating..."],
            label = XToLevel.db.profile.ldb.showLabel and L["TimeToLevel"] or nil,
            version = XToLevel.version,
            align = "right",
			["X-Category"] = "Information"
        });
        ldb = nil;
        
        -- Set data object events
        function self.timerObject:OnEnter()
            XToLevel.LDB.timerMouseOver = true;
            local a1, f1, a2 = XToLevel.Lib:FindAnchor(self);
            XToLevel.Tooltip:Show(self, a1, f1, a2, L['Click To Configure'], "timer");
        end
        function self.timerObject:OnLeave()
            XToLevel.LDB.timerMouseOver = false;
            XToLevel.Tooltip:Hide()
        end
        function self.timerObject:OnClick(button)
			XToLevel.Config:Open("Timer")
        end
		
		self:UpdateTimer()
	end,
        
    ---
    -- Creates the text pattern to be used.
    BuildPattern = function(self)
        if XToLevel.Player.level < XToLevel.Player.maxLevel then
            local showPlayer, playerProgress, playerProgressColor;
            local newText, useColors, isFirst, sPos, ePost, value, rest, attributes, out;
        
            showPlayer = XToLevel.Player.isActive and (XToLevel.Player.level < XToLevel.Player.maxLevel)
            
            -- User is leveling, proceed normally.
            if showPlayer then
                playerProgress = XToLevel.Lib:round(XToLevel.Player.currentXP / XToLevel.Player.maxXP * 100, 1)
                playerProgressColor = XToLevel.Lib:GetProgressColor_Soft(playerProgress)
            end
            
            -- Load the appropriate pattern, attempting to find one in the config.
            newText = self.textPatterns.default
            if XToLevel.db.profile.ldb.textPattern ~= nil then
                if XToLevel.db.profile.ldb.textPattern == "custom" then
                    newText = XToLevel.db.char.customPattern or "Please choose a pattern."
                    
                    -- Parse html-like syntax
                    newText = string.gsub(newText, '<(%w+) ?(.-)>', function(tag, attr)
                        attributes = {
                            label = false,
                            post = false,
                            seperator = false,
                        }
                        
                        for key, value in pairs(attributes) do
                            sPos, ePost, value, rest = string.find(attr, key ..'="([^"]-)"')
                            if value ~= nil then
                                attributes[key] = value
                            end
                        end
                        
                        out = "{".. tag .."}"
                        if attributes.seperator then
                            out = out .. "{$seperator:" .. attributes.seperator .."}"
                        end
                        if attributes.label then
                            out = out .. attributes.label ..": "
                        end
                        out = out .. "{progress}{$value}"
                        if attributes.post then
                            out = out .. attributes.post or nil
                        end
                        out = out .. "{/progress}{/" .. tag .."}"
                        return out
                    end)
                else
                    newText = self.textPatterns[XToLevel.db.profile.ldb.textPattern]
                end
            end
            
            -- Replace {color} tags
            if XToLevel.db.profile.ldb.allowTextColor then 
                newText = string.gsub(newText, "{color=([0-9A-Fa-f]+)}(.-){/color}", "|cFF%1%2|r")
            else
                newText = string.gsub(newText, "{color=[0-9A-Fa-f]+}(.-){/color}", "%1")
            end
            
            -- Prepare tags
            useColors = (XToLevel.db.profile.ldb.allowTextColor and XToLevel.db.profile.ldb.text.colorValues)
            self.textTags = {
                [1] = {
                    tag = "kills",
                    label = (XToLevel.db.profile.ldb.text.verbose and L["Kills"] ) or L["Kills Short"],
                    value = (showPlayer and '$$kills$$') or nil,
                    color = (useColors and '$$playercolor$$') or nil,
                },
                [2] = { 
                    tag = "quests",
                    label = (XToLevel.db.profile.ldb.text.verbose and L["Quests"] ) or L["Quests Short"],
                    value = (showPlayer and '$$quests$$') or nil,
                    color = (useColors and '$$playercolor$$') or nil,
                }, 
                [3] = { 
                    tag = "dungeons",
                    label = (XToLevel.db.profile.ldb.text.verbose and L["Dungeons"] ) or L["Dungeons Short"],
                    value = ((showPlayer and UnitLevel("Player") >= 15) and '$$dungeons$$') or nil,
                    color = (useColors and '$$playercolor$$') or nil,
                }, 
                [4] = { 
                    tag = "bgs",
                    label = (XToLevel.db.profile.ldb.text.verbose and L["Battles"] ) or L["Battles Short"],
                    value = ((showPlayer and UnitLevel("Player") >= 10) and '$$bgs$$') or nil,
                    color = (useColors and '$$playercolor$$') or nil,
                }, 
                [5] = { 
                    tag = "bgo",
                    label = (XToLevel.db.profile.ldb.text.verbose and L["Objectives"] ) or L["Objectives Short"],
                    value = ((showPlayer and UnitLevel("Player") >= 10) and '$$bgo$$') or nil,
                    color = (useColors and '$$playercolor$$') or nil,
                }, 
                [6] = { 
                    tag = "xp",
                    label = L["XP"],
                    value = (showPlayer and ('$$xp$$')) or nil,
                    color = (XToLevel.db.profile.ldb.allowTextColor and '$$playercolor$$') or nil,
                },
				[7] = { 
                    tag = "restedp",
                    label =(XToLevel.db.profile.ldb.text.verbose and L["Rested"] ) or L["Rested Short"],
                    value = (showPlayer and '$$restedp$$') or nil,
                    color = (XToLevel.db.profile.ldb.allowTextColor and '$$playercolor$$') or nil,
                },
				[8] = { 
                    tag = "rested",
                    label = (XToLevel.db.profile.ldb.text.verbose and L["Rested"] ) or L["Rested Short"],
                    value = (showPlayer and '$$rested$$') or nil,
                    color = (useColors and '$$playercolor$$') or nil,
                },
				[9] = { 
                    tag = "xpnum",
                    label = (XToLevel.db.profile.ldb.text.verbose and L["XP"] ) or L["XP"],
                    value = (showPlayer and '$$xpnum$$') or nil,
                    color = (useColors and '$$playercolor$$') or nil,
                },
                [10] = { 
                    tag = "guildxp",
                    label = (XToLevel.db.profile.ldb.text.verbose and "Guild XP" ) or "GXP",
                    value = (showPlayer and '$$guildxp$$') or nil,
                    color = (useColors and '$$guildcolor$$') or nil,
                },
                [11] = { 
                    tag = "guilddaily",
                    label = (XToLevel.db.profile.ldb.text.verbose and "Guild Daily" ) or "GDXP",
                    value = (showPlayer and '$$guilddaily$$') or nil,
                    color = (useColors and '$$guilddailycolor$$') or nil,
                },
            }
            
            -- Replace values
            isFirst = true
            for i, object in ipairs(self.textTags) do
                if XToLevel.db.profile.ldb.text[object.tag] and object.value ~= nil then
                    newText = string.gsub(newText, "{".. object.tag .."}(.-){/".. object.tag .."}", function(str)
                        str = string.gsub(str, "{$label}", object.label)
                        str = string.gsub(str, "{$value}", object.value)
                        if object.color ~= nil then
                            str = string.gsub(str, "{progress}(.-){/progress}", "|cFF".. object.color .."%1|r")
                        else
                            str = string.gsub(str, "{progress}(.-){/progress}", "%1")
                        end
                        if isFirst then
                            str = string.gsub(str, "{$seperator(.-)}", "")
                        else
                            str = string.gsub(str, "{$seperator:?(.-)}", "%1")
                        end
                        return str
                    end)
                    isFirst = false
                else
                    newText = string.gsub(newText, "{".. object.tag .."}.-{/".. object.tag .."}", '')
                end
            end
            self.currentPattern = newText
            
            -- Free resources
            showPlayer = nil;
            playerProgress = nil;
            playerProgressColor = nil;
            newText = nil;
            useColors = nil;
            isFirst = nil;
            sPos = nil;
            ePost = nil;
            value = nil;
            rest = nil;
            attributes = nil;
            out = nil;
            
        else
            -- Player is at max level.
            if XToLevel.db.profile.ldb.customColors then
                self.currentPattern = "|cFFaaaaaaInactive|r"
            else
                self.currentPattern = "Inactive"
            end
        end
    end,
        
    ---
    -- Update LDB text
    -- Note, this is a very memory demanding function.
    --  Calling it periodically is not a good idea!
    Update = function(self)
        if self.dataObject == nil then
            return false;
        end
        
        if XToLevel.db.profile.ldb.showLabel then
            self.dataObject.label = L["XToLevel"]
        else
            self.dataObject.label = nil
        end
            
        if XToLevel.db.profile.ldb.showIcon then
            local iconName = (UnitFactionGroup("player") == "Alliance") and "INV_Jewelry_TrinketPVP_01" or "INV_Jewelry_TrinketPVP_02"
            self.dataObject.icon = "Interface\\Icons\\" .. iconName
        else
            self.dataObject.icon = nil
        end
        
        if XToLevel.db.profile.ldb.showText then
            local pattern = self.currentPattern;
            if XToLevel.Player.level < XToLevel.Player:GetMaxLevel() then
                local playerProgress = XToLevel.Player:GetProgressAsPercentage(0)
                local playerProgressColor = XToLevel.Lib:GetProgressColor_Soft(playerProgress)
                
                pattern = string.gsub(pattern, '%$%$playercolor%$%$', playerProgressColor);
                pattern = string.gsub(pattern, '%$%$kills%$%$', (XToLevel.Lib:round(XToLevel.Player:GetAverageKillsRemaining()) or "~"));
                pattern = string.gsub(pattern, '%$%$quests%$%$', (XToLevel.Lib:round(XToLevel.Player:GetAverageQuestsRemaining()) or "~"));
                pattern = string.gsub(pattern, '%$%$dungeons%$%$', (XToLevel.Lib:round(XToLevel.Player:GetAverageDungeonsRemaining()) or "~"));
				
                if XToLevel.db.profile.ldb.text.xpAsBars then
                    pattern = string.gsub(pattern, '%$%$xp%$%$', tostring(XToLevel.Player:GetProgressAsBars()) .. " " .. L['Bars']);
                else
					local progressDisplay = playerProgress
					if XToLevel.db.profile.ldb.text.xpCountdown then
						progressDisplay = 100 - playerProgress
                        if progressDisplay < 1 then
                            progressDisplay = '<1' 
                        end
					end
                    pattern = string.gsub(pattern, '%$%$xp%$%$', progressDisplay .. "%%");
                end
				
				local xpnum = XToLevel.db.profile.ldb.text.xpCountdown and XToLevel.Player:GetXpRemaining() or XToLevel.Player.currentXP
				xpnum = XToLevel.db.profile.ldb.text.xpnumFormat and XToLevel.Lib:ShrinkNumber(xpnum) or XToLevel.Lib:round(xpnum)
				pattern = string.gsub(pattern, '%$%$xpnum%$%$', xpnum);
				
                pattern = string.gsub(pattern, '%$%$bgs%$%$', (XToLevel.Lib:round(XToLevel.Player:GetAverageBGsRemaining()) or "~"));
                pattern = string.gsub(pattern, '%$%$bgo%$%$', (XToLevel.Lib:round(XToLevel.Player:GetAverageBGObjectivesRemaining()) or "~"));
				
				if XToLevel.db.profile.ldb.text.xpnumFormat then
					pattern = string.gsub(pattern, '%$%$rested%$%$', (XToLevel.Lib:ShrinkNumber(XToLevel.Player.restedXP) or "~"));
				else
					pattern = string.gsub(pattern, '%$%$rested%$%$', (XToLevel.Lib:round(XToLevel.Player.restedXP) or "~"));
				end
				if XToLevel.db.profile.ldb.text.xpAsBars then
					local restedbars = XToLevel.Lib:round(XToLevel.Lib:round(XToLevel.Player:GetRestedPercentage()) / 5, 0, false)
					pattern = string.gsub(pattern, '%$%$restedp%$%$', restedbars .. " " .. L['Bars']);
				else
					pattern = string.gsub(pattern, '%$%$restedp%$%$', (XToLevel.Lib:round(XToLevel.Player:GetRestedPercentage(1)) .. "%%" or "~"));
				end
                
                if type(XToLevel.Player.guildXP) == 'number' then
                    local guildProgress = XToLevel.Lib:round(XToLevel.Player.guildXP / XToLevel.Player.guildXPMax * 100, 1)
                    local guildProgressColor = XToLevel.Lib:GetProgressColor_Soft(ceil(guildProgress))
                    
                    pattern = string.gsub(pattern, '%$%$guildcolor%$%$', guildProgressColor);
                    pattern = string.gsub(pattern, '%$%$guildxp%$%$', tostring(guildProgress) .. "%%");
                    
                    local guildDailyProgress = XToLevel.Player:GetGuildDailyProgressAsPercentage(1)
                    local guildDailyColor = XToLevel.Lib:GetProgressColor_Soft(ceil(guildDailyProgress))
                    
                    pattern = string.gsub(pattern, '%$%$guilddailycolor%$%$', guildDailyColor);
                    pattern = string.gsub(pattern, '%$%$guilddaily%$%$', tostring(guildDailyProgress) .. "%%");
                else
                    pattern = string.gsub(pattern, '%$%$guildcolor%$%$', "AAAAAA");
                    pattern = string.gsub(pattern, '%$%$guildxp%$%$', "N/A");
                    pattern = string.gsub(pattern, '%$%$guilddailycolor%$%$', "AAAAAA");
                    pattern = string.gsub(pattern, '%$%$guilddaily%$%$', "N/A");
                end
            else
                pattern = string.gsub(pattern, '%$%$playercolor%$%$', '');
                pattern = string.gsub(pattern, '%$%$kills%$%$', '');
                pattern = string.gsub(pattern, '%$%$quests%$%$', '');
                pattern = string.gsub(pattern, '%$%$dungeons%$%$', '');
                pattern = string.gsub(pattern, '%$%$xp%$%$', '');
				pattern = string.gsub(pattern, '%$%$xpnum%$%$', '');
                pattern = string.gsub(pattern, '%$%$bgs%$%$', '');
                pattern = string.gsub(pattern, '%$%$bgo%$%$', '');
				pattern = string.gsub(pattern, '%$%$rested%$%$', '');
				pattern = string.gsub(pattern, '%$%$restedp%$%$', '');
				pattern = string.gsub(pattern, '%$%$guildxp%$%$', "");
                pattern = string.gsub(pattern, '%$%$guilddaily%$%$', "");
            end
            self.dataObject.text = pattern;
        else
            self.dataObject.text = nil
        end
    end,
	
	UpdateTimer = function(self)
        if self.timerObject == nil then
            return false;
        end
        if XToLevel.db.profile.ldb.showLabel ~= self.timerLabelShown then -- changed
            self.timerObject.label = XToLevel.db.profile.ldb.showLabel and L["XToLevel"] or nil
        end
        if XToLevel.db.profile.timer.enabled and XToLevel.Player.level < XToLevel.Player:GetMaxLevel() then
            local mode, timeToLevel = XToLevel.Player:GetTimerData()
            timeToLevel = XToLevel.Lib:TimeFormat(timeToLevel)
            if timeToLevel == "NaN" then
                timeToLevel = "Waiting for data..."
            end
            self.timerObject.text = timeToLevel;
        else
            if XToLevel.db.profile.ldb.customColors then
                self.timerObject.text = "|cFFFF0000Inactive|r"
            else
                self.timerObject.text = "Inactive"
            end
        end
	end,
}