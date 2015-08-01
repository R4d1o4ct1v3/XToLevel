local _, addonTable = ...

local L = addonTable.GetLocale()

if XToLevel.AverageFrameAPI == nil then
    XToLevel.AverageFrameAPI = { }
end

--- 
-- Control methods and members for the XToLevel_AvergeFrame window.
-- @class table
-- 
XToLevel.AverageFrameAPI["Blocky"] = 
{
    isMoving = false,
    lastTooltip = nil,
    playerBoxes = {},

    --- Called when the frame first loads
    Initialize = function(self)
	    local iconName = (UnitFactionGroup("player") == "Alliance") and "battle_ally_icon.tga" or "battle_horde_icon.tga"
	    XToLevel_AverageFrame_Blocky_PlayerFrameCounterBattlesIcon:SetTexture("Interface\\AddOns\\XToLevel\\textures\\" .. iconName)
        
        -- Fetch boxes
        self.playerBoxes = {
	        {   
	            name =  'XToLevel_AverageFrame_Blocky_PlayerFrameCounterKills',
	            ref =   XToLevel_AverageFrame_Blocky_PlayerFrameCounterKills,
	            visible = XToLevel.db.profile.averageDisplay.playerKills
	        },
	        {   
	            name = 'XToLevel_AverageFrame_Blocky_PlayerFrameCounterQuests',
	            ref =   XToLevel_AverageFrame_Blocky_PlayerFrameCounterQuests,
	            visible = XToLevel.db.profile.averageDisplay.playerQuests
	        },
	        {   
	            name = 'XToLevel_AverageFrame_Blocky_PlayerFrameCounterDungeons',
	            ref =   XToLevel_AverageFrame_Blocky_PlayerFrameCounterDungeons,
	            visible = XToLevel.db.profile.averageDisplay.playerDungeons
	        },
	        {   name = 'XToLevel_AverageFrame_Blocky_PlayerFrameCounterBattles',
	            ref =   XToLevel_AverageFrame_Blocky_PlayerFrameCounterBattles,
	            visible = XToLevel.db.profile.averageDisplay.playerBGs
	        },
	        {   name = 'XToLevel_AverageFrame_Blocky_PlayerFrameCounterObjectives',
	            ref =   XToLevel_AverageFrame_Blocky_PlayerFrameCounterObjectives,
	            visible = XToLevel.db.profile.averageDisplay.playerBGOs
	        },
            {   name = 'XToLevel_AverageFrame_Blocky_PlayerFrameCounterPetBattles',
	            ref =   XToLevel_AverageFrame_Blocky_PlayerFrameCounterPetBattles,
	            visible = XToLevel.db.profile.averageDisplay.playerPetBattles
	        },
	        {   name = 'XToLevel_AverageFrame_Blocky_PlayerFrameCounterGathering',
	            ref =   XToLevel_AverageFrame_Blocky_PlayerFrameCounterGathering,
	            visible = XToLevel.db.profile.averageDisplay.playerGathering
	        },
            {   name = 'XToLevel_AverageFrame_Blocky_PlayerFrameCounterDigs',
	            ref =   XToLevel_AverageFrame_Blocky_PlayerFrameCounterDigs,
	            visible = XToLevel.db.profile.averageDisplay.playerDigs
	        },
	        {   
	            name = 'XToLevel_AverageFrame_Blocky_PlayerFrameCounterProgress',
	            ref =   XToLevel_AverageFrame_Blocky_PlayerFrameCounterProgress,
	            visible = XToLevel.db.profile.averageDisplay.playerProgress
	        },
	        {   
	            name = 'XToLevel_AverageFrame_Blocky_PlayerFrameCounterTimer',
	            ref =   XToLevel_AverageFrame_Blocky_PlayerFrameCounterTimer,
	            visible = XToLevel.db.profile.averageDisplay.playerTimer
	        },
	        {   
	            name = 'XToLevel_AverageFrame_Blocky_PlayerFrameCounterGuildProgress',
	            ref =   XToLevel_AverageFrame_Blocky_PlayerFrameCounterGuildProgress,
	            visible = XToLevel.db.profile.averageDisplay.guildProgress
	        }
	    }
        
        -- Stack frames
        self:Update()
    end,
    
    ---
    -- Hides the frame
    Hide = function(self)
        XToLevel_AverageFrame_Blocky_PlayerFrame:Hide()
    end,
    
    ---
    -- A wrapper to retrieve the anchor point of the window.
    -- Returns the exact same parameters as the Frame:GetPoint method.
    GetPoint = function(self)
        return XToLevel_AverageFrame_Blocky_PlayerFrame:GetPoint()
    end,
    
    ---
    -- Sets the anchor point for the window.
    -- Takes the same parameters the Frame:SetPoint method takes.
    SetAnchor = function(self, point, relativeTo, relativePoint, xOfs, yOfs)
        XToLevel_AverageFrame_Blocky_PlayerFrame:ClearAllPoints()
        XToLevel_AverageFrame_Blocky_PlayerFrame:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)
        self:Update()
    end,
    
    AlignTo = function(self, anchorFrame)
        local point, relativeTo, relativePoint, xOfs, yOfs = anchorFrame:GetPoint()
        XToLevel_AverageFrame_Blocky_PlayerFrame:ClearAllPoints()
        XToLevel_AverageFrame_Blocky_PlayerFrame:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)
        self:Update()
    end,
        
    --- Displays the tooltip next to the window.
    ShowTooltip = function(self, mode)
        if not self.isMoving and XToLevel.db.profile.averageDisplay.tooltip then
	        local footer = (XToLevel.db.profile.general.allowSettingsClick and L['Right Click To Configure']) or nil
	        -- a1 = child anchor point, f1 = parent frame, a2 = anchor-at point.
	        local a1, f1, a2 = XToLevel.Lib:FindAnchor(XToLevel_AverageFrame_Blocky_PlayerFrame);
	        if XToLevel.db.profile.averageDisplay.orientation == "v" then
	           -- If the tooltip is aligning at the bottom/top of the frame while
	           -- it is vertical, reverse it so it aligns at the side of it instead.
	           if a2 == "TOPRIGHT" or a2 == "TOPLEFT" or a2 == "BOTTOMLEFT" or a2 == "BOTTOMRIGHT" then
	               a2 = XToLevel.Lib:ReverseAnchor(a2)
               end
            end
            
            if XToLevel.db.profile.averageDisplay.combineTooltip then
                mode = nil
            end
            
            self.lastTooltip = mode
	        XToLevel.Tooltip:Show(XToLevel_AverageFrame_Blocky_PlayerFrame, a1, f1, a2, footer, mode);
	    end
    end,
    
    ---
    -- function description
    HideTooltip = function(self)
        XToLevel.Tooltip:Hide()
        if not self.isMoving then
            self.lastTooltip = nil
        end
    end,
    
    --- 
    -- Starts moving the frame
    StartDrag = function(self)
        if not self.isMoving and XToLevel.db.profile.general.allowDrag then
            XToLevel_AverageFrame_Blocky_PlayerFrame:StartMoving();
            self.isMoving = true
            XToLevel.Tooltip:Hide();
            
        end
    end,
    
    ---
    -- function description
    StopDrag = function(self)
        if self.isMoving then
            XToLevel_AverageFrame_Blocky_PlayerFrame:StopMovingOrSizing();
            self.isMoving = false
            if self.lastTooltip ~= nil then
                self:ShowTooltip(self.lastTooltip)
            end
        end
    end,
    
    ---
    -- Updates the LAYOUT of the frame.
    -- NOTE! This does NOT updated the values of the frames, only the positions.
    Update = function(self)
        if XToLevel.db.profile.averageDisplay.mode == 1 then
            -- Update the player frame
            local level = XToLevel.Player.level;
            local maxLevel = XToLevel.Player:GetMaxLevel()
	        if type(level) == "number" and type(maxLevel) == "number" and level < maxLevel then
	            XToLevel_AverageFrame_Blocky_PlayerFrame:Show()
                XToLevel_AverageFrame_Blocky_PlayerFrame:SetScale(XToLevel.db.profile.averageDisplay.scale)
		        self:StackPlayer()
	        else
                XToLevel_AverageFrame_Blocky_PlayerFrame:Hide()
	        end
        else
            XToLevel_AverageFrame_Blocky_PlayerFrame:Hide()
        end
    end,
    
    ---
    -- function description
    StackPlayer = function(self)           
        self.playerBoxes[1]["visible"] = XToLevel.db.profile.averageDisplay.playerKills
        self.playerBoxes[2]["visible"] = XToLevel.db.profile.averageDisplay.playerQuests
        self.playerBoxes[3]["visible"] = XToLevel.db.profile.averageDisplay.playerDungeons and XToLevel.Player.level >= 15
        self.playerBoxes[4]["visible"] = XToLevel.db.profile.averageDisplay.playerBGs and XToLevel.Player.level >= 10
        self.playerBoxes[5]["visible"] = XToLevel.db.profile.averageDisplay.playerBGOs and XToLevel.Player.level >= 10
        self.playerBoxes[6]["visible"] = XToLevel.db.profile.averageDisplay.playerPetBattles and XToLevel.Player:HasPetBattleInfo()
        self.playerBoxes[7]["visible"] = XToLevel.db.profile.averageDisplay.playerGathering and XToLevel.Player:HasGatheringInfo()
        self.playerBoxes[8]["visible"] = XToLevel.db.profile.averageDisplay.playerDigs and XToLevel.Player:HasDigInfo()
        self.playerBoxes[9]["visible"] = XToLevel.db.profile.averageDisplay.playerProgress
		self.playerBoxes[10]["visible"] = XToLevel.db.profile.averageDisplay.playerTimer and XToLevel.db.profile.averageDisplay.playerTimer
        self.playerBoxes[11]["visible"] = XToLevel.db.profile.averageDisplay.guildProgress and type(XToLevel.Player.guildXP) == 'number'
    
        local orientation = XToLevel.db.profile.averageDisplay.orientation or 'v'
        self:StackBoxes(orientation, self.playerBoxes, XToLevel_AverageFrame_Blocky_PlayerFrame, 'XToLevel_AverageFrame_Blocky_PlayerFrame');
    end,
    
    ---
    -- Stacks the boxes.
    -- @param direction Either "h" for horizontal or "v" for vertical.
    StackBoxes = function(self, direction, boxes, container, parent)
        local xcurr = 1
        local ycurr = 1
        local xmax = xcurr
        local ymax = ycurr
        local padding = 5
        
        for index, values in ipairs(boxes) do
            if values.visible and values.ref ~= nil then
                values.ref:ClearAllPoints();
                values.ref:SetPoint('TOPLEFT', parent, 'TOPLEFT', xcurr, ycurr);
                values.ref:Show()
                
                if direction == 'h' then
                    xcurr = xcurr + values.ref:GetWidth() + padding
                    ymax = (ymax < values.ref:GetHeight() and values.ref:GetHeight()) or ymax
                else
                    ycurr = ycurr - (values.ref:GetHeight() + padding)
                    xmax = (xmax < values.ref:GetWidth() and values.ref:GetWidth()) or xmax
                end
            elseif values.ref ~= nil then
                values.ref:Hide()
            end
        end
        
        
        if direction == 'h' then
            container:SetWidth(xcurr)
            container:SetHeight(ymax)
        else
            container:SetWidth(xmax)
            container:SetHeight(-ycurr)
        end
        
    end,
    
    --- Called each time an event is fired.
    OnEvent = function(self)
        return true
    end,

    --- Sets the kill value for the frame
    SetKills = function(self, value)
        XToLevel_AverageFrame_Blocky_PlayerFrameCounterKillsValueText:SetText(tonumber(value))
    end,
    
    --- Sets the quest value for the frame
    SetQuests = function(self, value)
        XToLevel_AverageFrame_Blocky_PlayerFrameCounterQuestsValueText:SetText(tonumber(value))
    end,
    
    --- Sets the quest value for the frame
    SetPetBattles = function(self, value)
        XToLevel_AverageFrame_Blocky_PlayerFrameCounterPetBattlesValueText:SetText(tonumber(value))
    end,
    
    --- Sets the dungeon value for the frame
    SetDungeons = function(self, value)
        XToLevel_AverageFrame_Blocky_PlayerFrameCounterDungeonsValueText:SetText(tonumber(value))
    end,
    
    --- Sets the battle value for the frame
    SetBattles = function(self, value)
        XToLevel_AverageFrame_Blocky_PlayerFrameCounterBattlesValueText:SetText(tonumber(value))
    end,
    
    --- Sets the objectives value for the frame
    SetObjectives = function(self, value)
        XToLevel_AverageFrame_Blocky_PlayerFrameCounterObjectivesValueText:SetText(tonumber(value))
    end,
    
    --- Sets the gathering average
    SetGathering = function(self, value)
        XToLevel_AverageFrame_Blocky_PlayerFrameCounterGatheringValueText:SetText(tonumber(value))
    end,
    
    --- Sets the archaeology average
    SetDigs = function(self, value)
        XToLevel_AverageFrame_Blocky_PlayerFrameCounterDigsValueText:SetText(tonumber(value))
    end,

    --- Sets the value for the progress bar.
    -- Changes both the progress bar and the text.
    SetProgress = function(self, percent)
        if percent ~= nil and (percent >= 0 and percent <= 100) then
            local progressFrame = XToLevel_AverageFrame_Blocky_PlayerFrameCounterProgress
            local progressBar = XToLevel_AverageFrame_Blocky_PlayerFrameCounterProgressBar
            local progressBarColor = XToLevel_AverageFrame_Blocky_PlayerFrameCounterProgressBarColor
            local progressText = XToLevel_AverageFrame_Blocky_PlayerFrameCounterProgressValueText
            
            local totalWidth = progressFrame:GetWidth() - 5
            local barWidth = totalWidth * (percent / 100)
            local bars = ceil((100 - percent) / 5)
            
            if barWidth == 0 then
                barWidth = 1
            end
            
            local hex, rgb = XToLevel.Lib:GetProgressColor(percent)
            rgb = { r= (rgb.r / 256), g= (rgb.g) / 256, b= (rgb.b / 256) }
            
            progressBar:SetWidth(barWidth)
            if XToLevel.db.profile.averageDisplay.progressAsBars then
                progressText:SetText(tostring(bars) .. " " .. L['Bars'])
            else
                progressText:SetText(tostring(floor(percent)) .. "%")
            end
            progressText:SetTextColor(rgb.r, rgb.g, rgb.b, 1.0)
        end
    end,
    
    --- Sets the value for the progress bar.
    -- Changes both the progress bar and the text.
    SetGuildProgress = function(self, percent)
        if percent ~= nil and (percent >= 0 and percent <= 100) then
            local progressFrame = XToLevel_AverageFrame_Blocky_PlayerFrameCounterGuildProgress
            local progressBar = XToLevel_AverageFrame_Blocky_PlayerFrameCounterGuildProgressBar
            local progressBarColor = XToLevel_AverageFrame_Blocky_PlayerFrameCounterGuildProgressBarColor
            local progressText = XToLevel_AverageFrame_Blocky_PlayerFrameCounterGuildProgressValueText
            
            local totalWidth = progressFrame:GetWidth() - 5
            local barWidth = totalWidth * (percent / 100)
            local bars = ceil((100 - percent) / 5)
            
            if barWidth == 0 then
                barWidth = 1
            end
            
            local hex, rgb = XToLevel.Lib:GetProgressColor(percent)
            rgb = { r= (rgb.r / 256), g= (rgb.g) / 256, b= (rgb.b / 256) }
            
            progressBar:SetWidth(barWidth)
            if XToLevel.db.profile.averageDisplay.progressAsBars then
                progressText:SetText(tostring(bars) .. " " .. L['Bars'])
            else
                progressText:SetText(tostring(floor(percent)) .. "%")
            end
            progressText:SetTextColor(rgb.r, rgb.g, rgb.b, 1.0)
        end
    end,
	
	SetTimer = function(self, shortTimeString, longTimeString)
		if type(shortTimeString) == "string" then
			XToLevel_AverageFrame_Blocky_PlayerFrameCounterTimerValueText:SetText(shortTimeString)
		end
	end,
    
    --- Sets whether or not to hide the XToLevel header.
    HeaderVisible = function(self, value)
        local header = XToLevel_AverageFrame_Blocky_PlayerFrameLabel
        if value ~= nil then
            if value == true then
                XToLevel_AverageFrame_Blocky_PlayerFrameLabel:Show()
                XToLevel_AverageFrame_Blocky_PlayerFrame:SetHeight(56)
                -- Move Counters
                XToLevel_AverageFrame_Blocky_PlayerFrameCounter:ClearAllPoints()
                XToLevel_AverageFrame_Blocky_PlayerFrameCounter:SetPoint("TOPLEFT", XToLevel_AverageFrame_Blocky_PlayerFrame, "TOPLEFT", 0, -14);
                -- Move Progress bar
                XToLevel_AverageFrame_Blocky_PlayerFrameProgress:ClearAllPoints()
                XToLevel_AverageFrame_Blocky_PlayerFrameProgress:SetPoint("TOPLEFT", XToLevel_AverageFrame_Blocky_PlayerFrame, "TOPLEFT", 15, -37);
                
            else
                XToLevel_AverageFrame_Blocky_PlayerFrameLabel:Hide()
                XToLevel_AverageFrame_Blocky_PlayerFrame:SetHeight(39)
                -- Move Counters
                XToLevel_AverageFrame_Blocky_PlayerFrameCounter:ClearAllPoints()
                XToLevel_AverageFrame_Blocky_PlayerFrameCounter:SetPoint("TOPLEFT", XToLevel_AverageFrame_Blocky_PlayerFrame, "TOPLEFT", 0, 0);
                -- Move Progress bar
                XToLevel_AverageFrame_Blocky_PlayerFrameProgress:ClearAllPoints()
                XToLevel_AverageFrame_Blocky_PlayerFrameProgress:SetPoint("TOPLEFT", XToLevel_AverageFrame_Blocky_PlayerFrame, "TOPLEFT", 15, -20);
            end
        else
            return XToLevel_AverageFrame_Blocky_PlayerFrameLabel:IsVisible()
        end
    end
}
