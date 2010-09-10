---
-- Contains definitions for the LDB data source.
-- @file XToLevel.Display.lua
-- @release 3.3.3_14r
-- @copyright Atli Þór (atli@advefir.com)
---
--module "XToLevel.Tooltip" -- For documentation purposes. Do not uncomment!

XToLevel.LDB = 
{
    -- Constants
    textPatterns = {
        default = "{kills}{$seperator: }{color=cfcfdf}{$label}:{/color} {progress}{$value}{/progress}{/kills}{quests}{$seperator: }{color=cfcfdf}{$label}:{/color} {progress}{$value}{/progress}{/quests}{dungeons}{$seperator: }{color=cfcfdf}{$label}:{/color} {progress}{$value}{/progress}{/dungeons}{bgs}{$seperator: }{color=cfcfdf}{$label}:{/color} {progress}{$value}{/progress}{/bgs}{bgo}{$seperator: }{color=cfcfdf}{$label}:{/color} {progress}{$value}{/progress}{/bgo}{xp}{$seperator: }{progress}[{$value}]{/progress}{/xp}{pet}{$seperator: }{color=cfcfdf}{$label}:{/color} {progress}{$value}{/progress}{/pet}{petxp}{$seperator: }{progress}[{$value}]{/progress}{/petxp}",
        minimal = "{kills}{progress}{$value}{/progress}{/kills}{quests}{color=cfcfdf}{$seperator:/}{/color}{progress}{$value}{/progress}{/quests}{dungeons}{color=cfcfdf}{$seperator:/}{/color}{progress}{$value}{/progress}{/dungeons}{bgs}{color=cfcfdf}{$seperator:/}{/color}{progress}{$value}{/progress}{/bgs}{xp}{color=cfcfdf}{$seperator:/}{/color}{progress}{$value}{/progress}{/xp}{pet}{color=cfcfdf}{$seperator:/}{/color}{progress}{$value}{/progress}{/pet}{petxp}{color=cfcfdf}{$seperator:/}{/color}{progress}{$value}{/progress}{/petxp}",
        minimal_dashed = "{kills}{progress}{$value}{/progress}{/kills}{quests}{color=cfcfdf}{$seperator:-}{/color}{progress}{$value}{/progress}{/quests}{dungeons}{color=cfcfdf}{$seperator:-}{/color}{progress}{$value}{/progress}{/dungeons}{bgs}{color=cfcfdf}{$seperator:-}{/color}{progress}{$value}{/progress}{/bgs}{xp}{color=cfcfdf}{$seperator:-}{/color}{progress}{$value}{/progress}{/xp}{pet}{color=cfcfdf}{$seperator:-}{/color}{progress}{$value}{/progress}{/pet}{petxp}{color=cfcfdf}{$seperator:-}{/color}{progress}{$value}{/progress}{/petxp}",
        brackets = "{kills}{progress}[{$value}]{/progress}{/kills}{quests}{progress}[{$value}]{/progress}{/quests}{dungeons}{progress}[{$value}]{/progress}{/dungeons}{bgs}{progress}[{$value}]{/progress}{/bgs}{xp}{progress}[{$value}]{/progress}{/xp}{pet}{$seperator:-}{progress}[{$value}]{/progress}{/pet}{petxp}{progress}[{$value}]{/progress}{/petxp}",
		countdown = "{xpnum}{color=cfcfdf}XP:{/color}{$seperator: }{progress}{$value}{/progress}{xp} {color=cfcfdf}({/color}{progress}{$value}{/progress}{color=cfcfdf}){/color}{/xp}{$seperator: }{/xpnum}{rested}{color=cfcfdf}R:{/color}{$seperator: }{progress}{$value}{/progress} {restedp}{color=cfcfdf}({/color}{progress}{$value}{/progress}{color=cfcfdf}){/color}{/restedp}{$seperator: }{/rested}{petxpnum}{$seperator: }{color=cfcfdf}Pet: {/color}{progress}{$value}{/progress} {petxp}{color=cfcfdf}({/color}{progress}{$value}{/progress}{color=cfcfdf}){/color}{/petxp}{/petxpnum}",
    },
    textTags = {
        [1] = { tag = "kills", label = 'init', value = '~', color = nil, },
        [2] = { tag = "quests", label = 'init', value = '~', color = nil, },
        [3] = { tag = "dungeons", label = 'init', value = '~', color = nil, }, 
        [4] = { tag = "bgs", label = 'init', value = '~', color = nil, }, 
        [5] = { tag = "bgo", label = 'init', value = '~', color = nil, }, 
        [6] = { tag = "xp", label = 'init', value = '~', color = nil, },
        [7] = { tag = "pet", label = 'init', value = '~', color = nil, },
        [8] = { tag = "petxp", label = 'init', value = '~', color = nil, },
		[9] = { tag = "restedp", label = 'init', value = '~', color = nil, },
		[10] = { tag = "rested", label = 'init', value = '~', color = nil, },
		[11] = { tag = "xpnum", label = 'init', value = '~', color = nil, },
		[12] = { tag = "petxpnum", label = 'init', value = '~', color = nil, },
		--[13] = { tag = "timer", label = 'init', value = '~', color = nil, },
    },

    -- Members
    dataObject = nil,
    mouseOver = false,
    currentPattern = nil,
	
	-- Timer members
	timerObject = nil,
	timerMouseOver = false,
	timerLabelShown = sConfig.ldb.showLabel,
        
    ---
    -- Constructor
    Initialize = function(self)
        -- Initialize the data object
        local iconName = (UnitFactionGroup("player") == "Alliance") and "INV_Jewelry_TrinketPVP_01" or "INV_Jewelry_TrinketPVP_02"
        local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
        self.dataObject = ldb:NewDataObject("XToLevel", {
            type = "data source",
            icon = "Interface\\Icons\\" .. iconName,
            text = "XToLevel",
            label = sConfig.ldb.showLabel and L["XToLevel"] or nil,
            version = "3.3.2_14r",
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
			XToLevel.Config:Open("ldb")
        end
        
        self:BuildPattern();-- /run XToLevel.LDB:BuildPattern(); XToLevel.LDB:Update();
        self:Update();
		
		self:InitializeTimer()
    end,
	
	InitializeTimer = function(self)
		-- Initialize the data object
        local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
        self.timerObject = ldb:NewDataObject("TimeToLevel", {
            type = "data source",
            icon = "Interface\\Icons\\inv_misc_pocketwatch_01",
            text = L["Updating..."],
            label = sConfig.ldb.showLabel and L["TimeToLevel"] or nil,
            version = "3.3.2_14r",
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
			XToLevel.Config:Open("timer")
        end
		
		self:UpdateTimer()
	end,
        
    ---
    -- Creates the text pattern to be used.
    BuildPattern = function(self)
        if ((XToLevel.Player.level < XToLevel.Player.maxLevel) or XToLevel.Pet.isActive or XToLevel.Pet.hasBeenActive) then
            local showPlayer, showPet, playerProgress, playerProgressColor, petProgress, petProgressColor;
            local newText, useColors, isFirst, sPos, ePost, value, rest, attributes, out;
        
            showPlayer = XToLevel.Player.isActive and (XToLevel.Player.level < XToLevel.Player.maxLevel)
            showPet = XToLevel.Pet.isActive or XToLevel.Pet.hasBeenActive
            
            -- User is leveling, proceed normally.
            if showPlayer then
                playerProgress = XToLevel.Lib:round(XToLevel.Player.currentXP / XToLevel.Player.maxXP * 100, 1)
                playerProgressColor = XToLevel.Lib:GetProgressColor_Soft(playerProgress)
            end
                
            if showPet then
                petProgress = XToLevel.Lib:round(XToLevel.Pet.xp / XToLevel.Pet.maxXP * 100, 1)
                petProgressColor = XToLevel.Lib:GetProgressColor_Soft(petProgress)
            end
            
            -- Load the appropriate pattern, attempting to find one in the config.
            newText = self.textPatterns.default
            if sConfig.ldb.textPattern ~= nil then
                if sConfig.ldb.textPattern == "custom" then
                    newText = sData.customPattern or "Please choose a pattern."
                    
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
                    newText = self.textPatterns[sConfig.ldb.textPattern]
                end
            end
            
            -- Replace {color} tags
            if sConfig.ldb.allowTextColor then 
                newText = string.gsub(newText, "{color=([0-9A-Fa-f]+)}(.-){/color}", "|cFF%1%2|r")
            else
                newText = string.gsub(newText, "{color=[0-9A-Fa-f]+}(.-){/color}", "%1")
            end
            
            -- Prepare tags
            useColors = (sConfig.ldb.allowTextColor and sConfig.ldb.text.colorValues)
            self.textTags = {
                [1] = {
                    tag = "kills",
                    label = (sConfig.ldb.text.verbose and L["Kills"] ) or L["Kills Short"],
                    value = (showPlayer and '$$kills$$') or nil,
                    color = (useColors and '$$playercolor$$') or nil,
                },
                [2] = { 
                    tag = "quests",
                    label = (sConfig.ldb.text.verbose and L["Quests"] ) or L["Quests Short"],
                    value = (showPlayer and '$$quests$$') or nil,
                    color = (useColors and '$$playercolor$$') or nil,
                }, 
                [3] = { 
                    tag = "dungeons",
                    label = (sConfig.ldb.text.verbose and L["Dungeons"] ) or L["Dungeons Short"],
                    value = ((showPlayer and UnitLevel("Player") >= 15) and '$$dungeons$$') or nil,
                    color = (useColors and '$$playercolor$$') or nil,
                }, 
                [4] = { 
                    tag = "bgs",
                    label = (sConfig.ldb.text.verbose and L["Battles"] ) or L["Battles Short"],
                    value = ((showPlayer and UnitLevel("Player") >= 10) and '$$bgs$$') or nil,
                    color = (useColors and '$$playercolor$$') or nil,
                }, 
                [5] = { 
                    tag = "bgo",
                    label = (sConfig.ldb.text.verbose and L["Objectives"] ) or L["Objectives Short"],
                    value = ((showPlayer and UnitLevel("Player") >= 10) and '$$bgo$$') or nil,
                    color = (useColors and '$$playercolor$$') or nil,
                }, 
                [6] = { 
                    tag = "xp",
                    label = L["XP"],
                    value = (showPlayer and ('$$xp$$')) or nil,
                    color = (sConfig.ldb.allowTextColor and '$$playercolor$$') or nil,
                },
                [7] = { 
                    tag = "pet",
                    label = (sConfig.ldb.text.verbose and L["Pet"] ) or L["Pet Short"],
                    value = (showPet and '$$pet$$') or nil,
                    color = (useColors and '$$petcolor$$') or nil,
                },
                [8] = { 
                    tag = "petxp",
                    label = (sConfig.ldb.text.verbose and L["Pet XP"] ) or L["Pet XP Short"],
                    value = (showPet and '$$petxp$$') or nil,
                    color = (sConfig.ldb.allowTextColor and '$$petcolor$$') or nil,
                },
				[9] = { 
                    tag = "restedp",
                    label =(sConfig.ldb.text.verbose and L["Rested"] ) or L["Rested Short"],
                    value = (showPlayer and '$$restedp$$') or nil,
                    color = (sConfig.ldb.allowTextColor and '$$playercolor$$') or nil,
                },
				[10] = { 
                    tag = "rested",
                    label = (sConfig.ldb.text.verbose and L["Rested"] ) or L["Rested Short"],
                    value = (showPlayer and '$$rested$$') or nil,
                    color = (useColors and '$$playercolor$$') or nil,
                },
				[11] = { 
                    tag = "xpnum",
                    label = (sConfig.ldb.text.verbose and L["XP"] ) or L["XP"],
                    value = (showPlayer and '$$xpnum$$') or nil,
                    color = (useColors and '$$playercolor$$') or nil,
                },
				[12] = { 
                    tag = "petxpnum",
                    label = (sConfig.ldb.text.verbose and L["Pet XP"] ) or L["Pet XP Short"],
                    value = (showPet and '$$petxpnum$$') or nil,
                    color = (useColors and '$$petcolor$$') or nil,
                },
				--[[[13] = { 
                    tag = "timer",
                    label = (sConfig.ldb.text.verbose and L["Timer"] ) or L["Timer Short"],
                    value = (showPlayer and '$$timer$$') or nil,
                    color = (useColors and '$$playercolor$$') or nil,
                },--]]
            }
            
            -- Replace values
            isFirst = true
            for i, object in ipairs(self.textTags) do
                if sConfig.ldb.text[object.tag] and object.value ~= nil then
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
            showPet = nil;
            playerProgress = nil;
            playerProgressColor = nil;
            petProgress = nil;
            petProgressColor = nil;
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
            -- Player is at max level and has no pets.
            if sConfig.ldb.customColors then
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
        
        if sConfig.ldb.showLabel then
            self.dataObject.label = L["XToLevel"]
        else
            self.dataObject.label = nil
        end
            
        if sConfig.ldb.showIcon then
            local iconName = (UnitFactionGroup("player") == "Alliance") and "INV_Jewelry_TrinketPVP_01" or "INV_Jewelry_TrinketPVP_02"
            self.dataObject.icon = "Interface\\Icons\\" .. iconName
        else
            self.dataObject.icon = nil
        end
        
        if sConfig.ldb.showText then
            local pattern = self.currentPattern;
            if (XToLevel.Player.level < XToLevel.Player.maxLevel) then
                local playerProgress = XToLevel.Player:GetProgressAsPercentage(0)
                local playerProgressColor = XToLevel.Lib:GetProgressColor_Soft(playerProgress)
                
                pattern = string.gsub(pattern, '%$%$playercolor%$%$', playerProgressColor);
                pattern = string.gsub(pattern, '%$%$kills%$%$', (XToLevel.Lib:round(XToLevel.Player:GetAverageKillsRemaining()) or "~"));
                pattern = string.gsub(pattern, '%$%$quests%$%$', (XToLevel.Lib:round(XToLevel.Player:GetAverageQuestsRemaining()) or "~"));
                pattern = string.gsub(pattern, '%$%$dungeons%$%$', (XToLevel.Lib:round(XToLevel.Player:GetAverageDungeonsRemaining()) or "~"));
				
                if sConfig.ldb.text.xpAsBars then
                    pattern = string.gsub(pattern, '%$%$xp%$%$', tostring(XToLevel.Player:GetProgressAsBars()) .. " " .. L['Bars']);
                else
					local progressDisplay = playerProgress
					if sConfig.ldb.text.xpCountdown then
						progressDisplay = 100 - playerProgress
					end
                    pattern = string.gsub(pattern, '%$%$xp%$%$', progressDisplay .. "%%");
                end
				
				local xpnum = sConfig.ldb.text.xpCountdown and XToLevel.Player:GetXpRemaining() or XToLevel.Player.currentXP
				xpnum = sConfig.ldb.text.xpnumFormat and XToLevel.Lib:ShrinkNumber(xpnum) or XToLevel.Lib:round(xpnum)
				pattern = string.gsub(pattern, '%$%$xpnum%$%$', xpnum);
				
                pattern = string.gsub(pattern, '%$%$bgs%$%$', (XToLevel.Lib:round(XToLevel.Player:GetAverageBGsRemaining()) or "~"));
                pattern = string.gsub(pattern, '%$%$bgo%$%$', (XToLevel.Lib:round(XToLevel.Player:GetAverageBGObjectivesRemaining()) or "~"));
				
				if sConfig.ldb.text.xpnumFormat then
					pattern = string.gsub(pattern, '%$%$rested%$%$', (XToLevel.Lib:ShrinkNumber(XToLevel.Player.restedXP) or "~"));
				else
					pattern = string.gsub(pattern, '%$%$rested%$%$', (XToLevel.Lib:round(XToLevel.Player.restedXP) or "~"));
				end
				if sConfig.ldb.text.xpAsBars then
					local restedbars = XToLevel.Lib:round(XToLevel.Lib:round(XToLevel.Player:GetRestedPercentage()) / 5, 0, false)
					pattern = string.gsub(pattern, '%$%$restedp%$%$', restedbars .. " " .. L['Bars']);
				else
					pattern = string.gsub(pattern, '%$%$restedp%$%$', (XToLevel.Lib:round(XToLevel.Player:GetRestedPercentage(1)) .. "%%" or "~"));
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
				--pattern = string.gsub(pattern, '%$%$timer%$%$', "");
            end
                
            if XToLevel.Pet.isActive or XToLevel.Pet.hasBeenActive then
                local petProgress, petProgressColor;
                petProgress = XToLevel.Lib:round(XToLevel.Pet.xp / XToLevel.Pet.maxXP * 100, 1)
                petProgressColor = XToLevel.Lib:GetProgressColor_Soft(petProgress)
                
                pattern = string.gsub(pattern, '%$%$petcolor%$%$', petProgressColor);
                pattern = string.gsub(pattern, '%$%$pet%$%$', (XToLevel.Lib:round(XToLevel.Pet:GetAverageKillsRemaining()) or "~"));
                if sConfig.ldb.text.xpAsBars then
                    pattern = string.gsub(pattern, '%$%$petxp%$%$', tostring(XToLevel.Pet:GetProgressAsBars()) .. " " .. L['Bars']);
                else
					local progressDisplay = petProgress
					if sConfig.ldb.text.xpCountdown then
						progressDisplay = 100 - progressDisplay
					end
                    pattern = string.gsub(pattern, '%$%$petxp%$%$', progressDisplay .. "%%");
                end
				
				local xpnum = sConfig.ldb.text.xpCountdown and XToLevel.Pet:GetXpRemaining() or XToLevel.Pet.xp
				xpnum = sConfig.ldb.text.xpnumFormat and XToLevel.Lib:ShrinkNumber(xpnum) or XToLevel.Lib:round(xpnum)
				pattern = string.gsub(pattern, '%$%$petxpnum%$%$', xpnum);
            else
                pattern = string.gsub(pattern, '%$%$petcolor%$%$', '');
                pattern = string.gsub(pattern, '%$%$pet%$%$', '');
                pattern = string.gsub(pattern, '%$%$petxp%$%$', '');
				pattern = string.gsub(pattern, '%$%$petxpnum%$%$', '');
            end
            self.dataObject.text = pattern;
        else
            self.dataObject.text = nil
        end
    end,
	
	UpdateTimer = function(self)
		if sConfig.ldb.showLabel ~= this.timerLabelShown then
			self.timerObject.label = sConfig.ldb.showLabel and L["XToLevel"] or nil
		end
		if sConfig.timer.enabled then
			local mode, timeToLevel = XToLevel.Player:GetTimerData()
			timeToLevel = XToLevel.Lib:TimeFormat(timeToLevel)
			if timeToLevel == "NaN" then
				timeToLevel = "Waiting for data..."
			end
			self.timerObject.text = timeToLevel;
		else
			self.timerObject.text = "|cFFFF0000Disabled|r"
		end
	end,
}