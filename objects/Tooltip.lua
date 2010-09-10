---
-- Contains definitions for the Tooltip display.
-- @file XToLevel.Display.lua
-- @release 3.3.3_14r
-- @copyright Atli Þór (atli@advefir.com)
---
--module "XToLevel.Tooltip" -- For documentation purposes. Do not uncomment!

XToLevel.Tooltip = 
{
    initialized = false,
	
	OnShow_Before = nil,
	OnShow_XpData = { },

    labelColor = {},
    dataColor = {},
    footerColor = {},
    
    ---
    -- function description
    Initialize = function(self)
        if sConfig.ldb.allowTextColor then
            self.labelColor = { r=0.75, g=0.75, b=0.75 }
            self.dataColor = { r=0.9, g=1, b=0.9 }
            self.footerColor = { r=0.6, g=0.6, b=0.6 }
        end
        self.initialized = true

		GameTooltip:HookScript("OnShow", self.OnShow_HookCallback);
    end,
	
	---
	-- Callback for the GameTooltip:OnShow hook
	-- Adds the number of kills needed to unfriendly NPC tooltips.
	OnShow_HookCallback = function(self, ...)
		if sConfig.general.showNpcTooltipData then
			local name, unit = GameTooltip:GetUnit()
			if unit and not UnitIsPlayer(unit) and not UnitIsFriend("player", unit) and UnitLevel(unit) > 0 then
				local level = UnitLevel(unit)
				if XToLevel.Tooltip.OnShow_XpData[level] == nil then
					XToLevel.Tooltip.OnShow_XpData[level] = XToLevel.Lib:MobXP(UnitLevel("player"), UnitLevel(unit))
				end
				if XToLevel.Tooltip.OnShow_XpData[level] > 0 then
					local color
					local diff = XToLevel.Player.level - level
					local percent = 50 + (diff * 10)
					if percent <= 100 then
						if percent < 0 then
							percent = 0
						end
						color = XToLevel.Lib:GetProgressColor(percent)
					else
						color = "888888"
					end
					GameTooltip:AddLine("|cFFAAAAAA" .. L['Kills to level'] ..": |r |cFF" .. color .. XToLevel.Player:GetKillsRequired(XToLevel.Tooltip.OnShow_XpData[level]) .. "|r", 0.75, 0.75, 0.75)
					GameTooltip:Show()
				end
			end
		end
	end,
    
    ---
    -- Shows the given message when the given frame is rolled over by the mouse.
    -- This is tailored to config option error details, such as the low level
    -- warning for battleground options, and is displayed in red at the mouse.
    -- @param frame The frame that should trigger the message tooltip
    -- @param text The text to show in the tooltip.
    SetConfigInfo = function(self, frame, text)
        frame:SetScript("OnEnter", function()
            XToLevel.Tooltip:ShowConfigDescription(text)
        end)
        frame:SetScript("OnLeave", function()
            XToLevel.Tooltip:HideConfigDescription()
        end)
    end,
    
    ---
    -- The callback for when a config option, set by the SetConfigInfo() function
    -- is rolled over by the mouse. Shows the given text at the mosue posistion.
    -- The text is displayed in red, at 75% the normal size.
    -- NOTE! Use the HideConfigDescription method to hide this tooltip, or you 
    -- risk that the scale bleeds over to the next tooltip that is shown.
    -- @param text The text to show.
    ShowConfigDescription = function(self, text)
        GameTooltip:SetOwner(XToLevel.frame, "ANCHOR_CURSOR")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(text, 1, 0.25, 0.25, true)
        GameTooltip:Show()
    end,
    
    ---
    -- Hides the tooltip, setting hte scale back to normal.
    HideConfigDescription = function(self)
        GameTooltip:Hide();
    end,

    ---
    -- Shows the tooltip for the Average and LDB windows. When given, the
    -- mode parameter sets what exactly should be shown. If no valid mode
    -- is give, all the info is shown. The user config is taken into account
    -- and unchecned Tooltip options will be hidden.
    -- @param frame The parent frame, if any. This will be the anchor frame
    --        for the tooltip. If none is given, the default position is used.
    -- @param anchorPoint The point of the tooltip that should be anchored to
    --        the relative fram.
    -- @param relativeFrame The frame to which the tooltip should be attached.
    -- @param relativePoint The point of the relative frame that the tooltip
    --        should be anchored to.
    -- @param footerText The text to display at the foot of the tooltip.
    -- @param mode A string to indicate what info should be shown in the tooltip.
    --        This is one of: "bg", "kills", "quests", "dungeons", "experience",
    --        "pet", "pet xp" or "all". ("all" is the default, if an invalid mode
    --        is passed.)
    Show = function(self, frame, anchorPont, relativeFrame, relativePoint, footerText, mode)
        -- Initialize
        if not self.initialized then
            self:Initialize()
        end
        if frame ~= nil then
            GameTooltip:SetOwner(frame, "ANCHOR_NONE")
        else
            GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
        end
        if anchorPont ~= nil or relativeFrame ~= nil or relativePoint ~= nil then
            GameTooltip:SetPoint(anchorPont, relativeFrame, relativePoint)
        end
        GameTooltip:ClearLines()
        
        if mode == "bg" then
            GameTooltip:AddLine(L["Battlegrounds"])
            self:AddBattlegroundInfo()
            GameTooltip:AddLine(" ")
            self:AddBattles()
            GameTooltip:AddLine(" ")
        elseif mode == "kills" then
            GameTooltip:AddLine(L['Kills'])
            self:AddKillRange()
            GameTooltip:AddLine(" ")
        elseif mode == "quests" then
            GameTooltip:AddLine(L['Quests'])
            self:AddQuestRange()
            GameTooltip:AddLine(" ")
        elseif mode == "dungeons" then
            GameTooltip:AddLine(L['Dungeons'])
            self:AddDungeonInfo()
            GameTooltip:AddLine(" ")
            self:AddDungeons()
            GameTooltip:AddLine(" ")
        elseif mode == "experience" then
            GameTooltip:AddLine(L['Experience'])
            self:AddExperience()
            GameTooltip:AddLine(" ")
        elseif mode == "pet" then
            GameTooltip:AddLine(L['Pet'])
            self:AddPet()
            GameTooltip:AddLine(" ")
        elseif mode == "pet xp" then
            GameTooltip:AddLine(L['Pet Experience'])
            self:AddPetExperience()
            GameTooltip:AddLine(" ")
		elseif mode == "timer" then
			GameTooltip:AddLine("Time to level")
            self:AddTimerDetailes(false)
            GameTooltip:AddLine(" ")
        else
            -- The old "overall" tootip
            GameTooltip:AddLine(L["XToLevel"])
            
            if XToLevel.Player.level < XToLevel.Player.maxLevel then
                if sConfig.ldb.tooltip.showDetails then
                    self:AddKills()
                    self:AddQuests()
                end
                if XToLevel.Lib:ShowDungeonData() then -- Overall Dungeon Info
                    self:AddDungeonInfo()
                end
                if XToLevel.Lib:ShowBattlegroundData() then -- Overall BG Info
                    self:AddBattlegroundInfo()
                end
                GameTooltip:AddLine(" ")
                
                if sConfig.ldb.tooltip.showExperience then
                    GameTooltip:AddLine(L["Experience"] .. ": ")
                    self:AddExperience()
                    GameTooltip:AddLine(" ")
                end
            end
            
            if (XToLevel.Pet.isActive or XToLevel.Pet.hasBeenActive) and sConfig.ldb.tooltip.showPetInfo then
                GameTooltip:AddLine(L["Pet"] .. ":")
                self:AddPet()
                self:AddPetExperience()
                GameTooltip:AddLine(" ")
            end
            
            if XToLevel.Lib:ShowDungeonData() then
                self:AddDungeons()
                GameTooltip:AddLine(" ")
            end
                
            if XToLevel.Lib:ShowBattlegroundData() then
                self:AddBattles()
                GameTooltip:AddLine(" ")
            end
			
			if sConfig.timer.enabled and sConfig.ldb.tooltip.showTimerInfo then
				GameTooltip:AddLine(L["Timer"] .. ":")
				self:AddTimerDetailes(true)
				GameTooltip:AddLine(" ")
			end
        end -- END "Overall" tooltip creation
        
        if footerText ~= nil then
            GameTooltip:AddLine(tostring(footerText), self.footerColor.r, self.footerColor.g, self.footerColor.b)
        end
        
        GameTooltip:Show()
    end,
    
    ---
    -- Wrapper function to hide the frame.
    Hide = function(self)
        GameTooltip:Hide();
    end,
    
    --
    -- Add functions
    -- Used by the Show function to assemble the requsted tooltip
    --
    ---
    -- function description
    AddKills = function(self)
        GameTooltip:AddDoubleLine(" " .. L["Kills"] .. ":" , XToLevel.Lib:NumberFormat(XToLevel.Player:GetAverageKillsRemaining()) .." @ ".. XToLevel.Lib:NumberFormat(XToLevel.Lib:round(XToLevel.Player:GetAverageKillXP(), 0)) .." xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
    end,
    ---
    -- function description
    AddKillRange = function(self)
        local range = XToLevel.Player:GetKillXpRange();
        GameTooltip:AddDoubleLine(" " .. L["Average"] .. ":" , XToLevel.Lib:NumberFormat(XToLevel.Player:GetKillsRequired(range.average)) .." @ ".. XToLevel.Lib:NumberFormat(XToLevel.Lib:round(range.average, 0)) .." xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
        GameTooltip:AddDoubleLine(" " .. L["Min"] .. ":" , XToLevel.Lib:NumberFormat(XToLevel.Player:GetKillsRequired(range.high)) .." @ ".. XToLevel.Lib:NumberFormat(XToLevel.Lib:round(range.high, 0)) .." xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
        GameTooltip:AddDoubleLine(" " .. L["Max"] .. ":" , XToLevel.Lib:NumberFormat(XToLevel.Player:GetKillsRequired(range.low)) .." @ ".. XToLevel.Lib:NumberFormat(XToLevel.Lib:round(range.low, 0)) .." xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
        GameTooltip:AddDoubleLine(" " , " ", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
        GameTooltip:AddDoubleLine(" " .. L["XP Rested"] .. ": " , XToLevel.Lib:NumberFormat(XToLevel.Player:IsRested() or 0) .. " xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
    end,
    
    ---
    -- function description
    AddQuests = function(self)
        GameTooltip:AddDoubleLine(" " .. L["Quests"] .. ":" , XToLevel.Lib:NumberFormat(XToLevel.Player:GetAverageQuestsRemaining()) .." @ ".. XToLevel.Lib:NumberFormat(XToLevel.Lib:round(XToLevel.Player:GetAverageQuestXP(), 0)) .." xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
    end,
    ---
    -- function description
    AddQuestRange = function(self)
        local range = XToLevel.Player:GetQuestXpRange();
        GameTooltip:AddDoubleLine(" " .. L["Average"] .. ":" , XToLevel.Lib:NumberFormat(XToLevel.Player:GetQuestsRequired(range.average)) .." @ ".. XToLevel.Lib:NumberFormat(XToLevel.Lib:round(range.average, 0)) .." xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
        GameTooltip:AddDoubleLine(" " .. L["Min"] .. ":" , XToLevel.Lib:NumberFormat(XToLevel.Player:GetQuestsRequired(range.high)) .." @ ".. XToLevel.Lib:NumberFormat(XToLevel.Lib:round(range.high, 0)) .." xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
        GameTooltip:AddDoubleLine(" " .. L["Max"] .. ":" , XToLevel.Lib:NumberFormat(XToLevel.Player:GetQuestsRequired(range.low)) .." @ ".. XToLevel.Lib:NumberFormat(XToLevel.Lib:round(range.low, 0)) .." xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
    end,
    
    ---
    -- function description
    AddDungeonInfo = function(self)
        GameTooltip:AddDoubleLine(" " .. L['Dungeons'] .. ":" , XToLevel.Lib:NumberFormat(XToLevel.Player:GetAverageDungeonsRemaining()) .." @ ".. XToLevel.Lib:NumberFormat(XToLevel.Lib:round(XToLevel.Player:GetAverageDungeonXP(), 0)) .." xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
    end,
    
    ---
    -- function description
    AddDungeons = function(self)
        if (# sData.player.dungeonList) > 0 then
            local dungeons, latestData, averageRaw, averageFormatted, needed;
            
            dungeons = XToLevel.Player:GetDungeonsListed()
            latestData = XToLevel.Player:GetLatestDungeonDetails();
            
            if dungeons ~= nil then
                GameTooltip:AddLine(L['Dungeons Required'] .. ":")
                for name, count in pairs(dungeons) do
                    if name == false then
                        name = "Unknown"
                    end
                    averageRaw = XToLevel.Player:GetDungeonAverage(name)
                    if averageRaw > 0 then
                        averageFormatted = XToLevel.Lib:NumberFormat(XToLevel.Lib:round(averageRaw, 0))
                        needed = XToLevel.Player:GetKillsRequired(tonumber(averageRaw))
                        GameTooltip:AddDoubleLine(" ".. name .. ": " , needed .. " @ ".. averageFormatted .. " xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
                    end
                end
                GameTooltip:AddLine(" ")
            end
            
            if sData.player.dungeonList[1].inProgress then
                GameTooltip:AddLine(L['Current Dungeon'] .. ":")
            else
                GameTooltip:AddLine(L['Last Dungeon'] .. ":")
            end
            
            local dungeonName = nil
            if type(sData.player.dungeonList[1].name) ~= "string" then
            	if GetRealZoneText() ~= nil then
            		sData.player.dungeonList[1].name = GetRealZoneText()
            		dungeonName = sData.player.dungeonList[1].name
        		else
        			dungeonName = "Unknown"
            	end
        	else
        		dungeonName = sData.player.dungeonList[1].name
            end
            
            GameTooltip:AddDoubleLine(" ".. L['Name'] ..": " , dungeonName, self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
            GameTooltip:AddDoubleLine(" ".. L['Kills'] ..": " , XToLevel.Lib:NumberFormat(latestData.killCount) .." @ ".. XToLevel.Lib:NumberFormat(latestData.xpPerKill) .." xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
            
            if latestData.rested > 0 then
            	local total = latestData.totalXP + latestData.rested
            	GameTooltip:AddDoubleLine(" ".. L['Total XP'] ..": " , XToLevel.Lib:NumberFormat(total) .. " (" .. XToLevel.Lib:NumberFormat(latestData.rested) .. " " .. L['XP Rested'] ..")", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
            else
            	GameTooltip:AddDoubleLine(" ".. L['Total XP'] ..": " , XToLevel.Lib:NumberFormat(latestData.totalXP), self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
            end
            dungeons = nil 
            latestData = nil 
            averageRaw = nil 
            averageFormatted = nil 
            needed = nil
        else
            GameTooltip:AddLine(L['Dungeons Required'] .. ":")
            GameTooltip:AddLine(" " .. L['No Dungeons Completed'], self.labelColor.r, self.labelColor.g, self.labelColor.b)
        end
    end,
    
    ---
    -- function description
    AddExperience = function(self)
        local xpProgress = XToLevel.Player:GetProgressAsPercentage()
        local xpProgressBars = XToLevel.Player:GetProgressAsBars()
        local xpNeededTotal = XToLevel.Player.maxXP - XToLevel.Player.currentXP
        local xpNeededActual = XToLevel.Player:GetKillsRequired(1) or "~"
        
        --GameTooltip:AddLine(L["Experience"] .. ": ")
        GameTooltip:AddDoubleLine(" " .. L["XP Progress"] .. ": " , XToLevel.Lib:ShrinkNumber(UnitXP("player")) .. " / " .. XToLevel.Lib:ShrinkNumber(UnitXPMax("player")) .. " [" .. tostring(xpProgress) .. "%" .. "]", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
        GameTooltip:AddDoubleLine(" " .. L["XP Bars Remaining"] .. ": " , xpProgressBars .. " bars", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
        GameTooltip:AddDoubleLine(" " .. L["XP Rested"] .. ": " , XToLevel.Lib:ShrinkNumber(XToLevel.Player:IsRested() or 0) .. " [" .. XToLevel.Lib:round(XToLevel.Player:GetRestedPercentage(1)) .. "%]", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
        GameTooltip:AddDoubleLine(" " .. L["Quest XP Required"] .. ": " , XToLevel.Lib:NumberFormat(xpNeededTotal) .. " xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
        GameTooltip:AddDoubleLine(" " .. L["Kill XP Required"] .. ": " , XToLevel.Lib:NumberFormat(xpNeededActual) .. " xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
    
        xpProgress = nil
        xpNeededTotal = nil
        xpNeededActual = nil
    end,
    
    ---
    -- function description
    AddBattlegroundInfo = function(self)
        GameTooltip:AddDoubleLine(" " .. L["Battles"] .. ":" , XToLevel.Lib:NumberFormat(XToLevel.Player:GetAverageBGsRemaining() or 0) .." @ ".. XToLevel.Lib:NumberFormat(XToLevel.Lib:round(XToLevel.Player:GetAverageBGXP(), 0)) .." xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
        GameTooltip:AddDoubleLine(" " .. L["Objectives"] .. ":" , XToLevel.Lib:NumberFormat(XToLevel.Player:GetAverageBGObjectivesRemaining() or 0) .." @ ".. XToLevel.Lib:NumberFormat(XToLevel.Lib:round(XToLevel.Player:GetAverageBGObjectiveXP(), 0)) .." xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
    end,
    
    ---
    -- function description
    AddBattles = function(self)
    	local bgs = XToLevel.Player:GetBattlegroundsListed()
        if bgs ~= nil and (# sData.player.bgList) > 0 then
            local latestData, averageRaw, averageFormatted, needed;
            latestData = XToLevel.Player:GetLatestBattlegroundDetails();
            
            GameTooltip:AddLine(L['Battlegrounds Required'] .. ":")
                for name, count in pairs(bgs) do
                    if name == false then
                        name = "Unknown"
                    end
                    averageRaw = XToLevel.Player:GetBattlegroundAverage(name)
                    if averageRaw == 0 then
                        averageRaw = latestData.totalXP
                    end
                    averageFormatted = XToLevel.Lib:NumberFormat(XToLevel.Lib:round(averageRaw, 0))
                    needed = XToLevel.Player:GetQuestsRequired(tonumber(averageRaw))
                    GameTooltip:AddDoubleLine(" ".. name .. ": " , needed .. " @ ".. averageFormatted .. " xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
                end
            GameTooltip:AddLine(" ")
            
           	if latestData ~= nil then
	            if sData.player.bgList[1].inProgress then
	                GameTooltip:AddLine(L['Current Battleground'] .. ":")
	            else
	                GameTooltip:AddLine(L['Last Battleground'] .. ":")
	                if sData.player.bgList[1].name ~= false then
	                    GameTooltip:AddDoubleLine(" ".. L['Name'] ..": " , sData.player.bgList[1].name, self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
	                end
	            end
	            
	            GameTooltip:AddDoubleLine(" ".. L['Total XP'] ..": " , XToLevel.Lib:NumberFormat(latestData.totalXP), self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
	            GameTooltip:AddDoubleLine(" ".. L['Objectives'] ..": " , XToLevel.Lib:NumberFormat(latestData.objCount) .." @ ".. XToLevel.Lib:NumberFormat(latestData.xpPerObj) .." xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
	            GameTooltip:AddDoubleLine(" ".. L['NPC Kills'] ..": " , XToLevel.Lib:NumberFormat(latestData.killCount) .." @ ".. XToLevel.Lib:NumberFormat(latestData.xpPerKill) .." xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
            end
            bgs = nil 
            latestData = nil 
            averageRaw = nil 
            averageFormatted = nil 
            needed = nil
        else
            GameTooltip:AddLine(L['Battlegrounds Required'] .. ":")
            GameTooltip:AddLine(" " .. L['No Battles Fought'], self.labelColor.r, self.labelColor.g, self.labelColor.b)
        end
    end,
    
    ---
    -- function description
    AddPet = function(self)
        GameTooltip:AddDoubleLine(" " .. L["Kills"] .. ":" , XToLevel.Lib:NumberFormat(XToLevel.Pet:GetAverageKillsRemaining()).." @ "..XToLevel.Lib:NumberFormat(XToLevel.Lib:round(XToLevel.Pet:GetAverageKillXP(), 0)).." xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)     
    end,
    
    ---
    -- function description
    AddPetExperience = function(self)
        local xpProgress = XToLevel.Pet:GetProgressAsPercentage(1) --XToLevel.Pet.xp / XToLevel.Pet.maxXP * 100
        local xpBars = XToLevel.Pet:GetProgressAsBars()
        --GameTooltip:AddLine(L["Pet"] .. ":")
        GameTooltip:AddDoubleLine(" " .. L["XP Progress"] .. ":" , XToLevel.Lib:NumberFormat(XToLevel.Lib:round((XToLevel.Pet.xp or 0))).." / "..XToLevel.Lib:NumberFormat(XToLevel.Lib:round((XToLevel.Pet.maxXP or 0))).." [".. tostring(xpProgress) .."%]", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
        GameTooltip:AddDoubleLine(" " .. L["XP Bars Remaining"] .. ": " , tostring(xpBars) .. " bars", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
        GameTooltip:AddDoubleLine(" " .. L["Kill XP Required"] .. ":" , XToLevel.Lib:NumberFormat(XToLevel.Lib:round((XToLevel.Pet.maxXP or 0) - (XToLevel.Pet.xp or 0))) .. " xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
        xpProgress = nil
    end,
	
	--- Detailed timer info.
	AddTimerDetailes = function(self, mininmal)
		if sConfig.timer.enabled then
			-- Gather data.
			local mode, timeToLevel, timePlayed, xpPerHour, totalXP = XToLevel.Player:GetTimerData()
			local showWarning = mode ~= nil and mode ~= sConfig.timer.mode
			
			if mode == nil then
				mode = L["Updating..."]
				timeToLevel = 0
				timePlayed = 0
				xpPerHour = "N/A"
				totalXP = "N/A"
			else
				mode = mode == 1 and L["Session"] or L["Level"]
			end
			-- Display data.
			timeToLevel = XToLevel.Lib:TimeFormat(timeToLevel)
			if timeToLevel == "NaN" then
				timeToLevel = "Waiting for data..."
			end
            if showWarning then
                GameTooltip:AddDoubleLine(" " .. L["Data"] .. ": ", mode, self.labelColor.r, self.labelColor.g, self.labelColor.b, 1.0, 0.0, 0.0);
            else
                GameTooltip:AddDoubleLine(" " .. L["Data"] .. ": ", mode, self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b);
            end
			GameTooltip:AddDoubleLine(" " .. L["Time to level"] .. ": ", timeToLevel, self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b);
			if not mininmal then
				GameTooltip:AddLine(" ")
			end
			GameTooltip:AddDoubleLine(" " ..L["Time elapsed"].. ": ", XToLevel.Lib:TimeFormat(timePlayed), self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b);
			GameTooltip:AddDoubleLine(" " ..L["Total XP"] .. ": ", XToLevel.Lib:NumberFormat(totalXP), self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b);
			GameTooltip:AddDoubleLine(" " ..L["XP per hour"] .. ": ", XToLevel.Lib:NumberFormat(xpPerHour), self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b);
			GameTooltip:AddDoubleLine(" " ..L["XP Needed"] .. ": ", XToLevel.Lib:NumberFormat(XToLevel.Player.maxXP - XToLevel.Player.currentXP), self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b);
			
			if showWarning and not mininmal then
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(L["No Kills Recorded"], 1.0, 0.0, 0.0, true)
			end
		else
			GameTooltip:AddDoubleLine(" Mode", "Disabled", self.labelColor.r, self.labelColor.g, self.labelColor.b, 1.0, 0.0, 0.0);
		end
	end,
}