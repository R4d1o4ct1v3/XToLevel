if XToLevel.AverageFrameAPI == nil then
    XToLevel.AverageFrameAPI = { }
end

--- 
-- Control methods and members for the XToLevel_AvergeFrame window.
-- @class table
-- 
XToLevel.AverageFrameAPI["Classic"] = 
{
    isMoving = false,
    window = nil,
    backdrop = nil,
    lines = {},
    textMargin = 5,
    lineSpacing = 2,
    lastTooltip = nil,
    playerProgressColor = "0088ff",
    petProgressColor = "0088ff",
    labelColor = "ffffff",

    --- Called when the frame first loads
    Initialize = function(self)
        if XToLevel_AverageFrame_Classic ~= nil then
            self.window = XToLevel_AverageFrame_Classic
            self.backdrop = self.window:GetBackdrop();
            self:CreateLines()
            self:Update()
            -- self.window:SetScript("OnEnter", function() self:ShowTooltip() end)
            -- self.window:SetScript("OnLeave", function() self:HideTooltip() end)
        else
            console:log("The classic average window is not loaded!")
        end
    end,
    
    ---
    -- A wrapper to retrieve the anchor point of the window.
    -- Returns the exact same parameters as the Frame:GetPoint method.
    GetPoint = function(self)
        return self.window:GetPoint()
    end,
    
    ---
    -- Sets the anchor point for the window.
    -- Takes the same parameters the Frame:SetPoint method takes.
    SetAnchor = function(self, point, relativeTo, relativePoint, xOfs, yOfs)
        self.window:ClearAllPoints()
        self.window:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)
    end,
    
    AlignTo = function(self, anchorFrame)
        local point, relativeTo, relativePoint, xOfs, yOfs = anchorFrame:GetPoint()
        self.window:ClearAllPoints()
        self.window:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)
        self:Update()
    end,
    
    --- Displays the tooltip next to the window.
    ShowTooltip = function(self, mode)
        if not self.isMoving and sConfig.averageDisplay.tooltip then
	        local footer = (sConfig.general.allowSettingsClick and L['Right Click To Configure']) or nil
	        local childPoint, parentFrame, parentPoint = XToLevel.Lib:FindAnchor(self.window);
	        
            if parentPoint ~= "TOP" and parentPoint ~= "BOTTOM" then
				parentPoint = XToLevel.Lib:ReverseAnchor(parentPoint)
	        end
	        if sConfig.averageDisplay.combineTooltip then
	            XToLevel.Tooltip:Show(self.window, childPoint, parentFrame, parentPoint, footer);
            else
                XToLevel.Tooltip:Show(self.window, childPoint, parentFrame, parentPoint, footer, mode);
                self.lastTooltip = mode
            end
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
    
    --- Starts moving the frame
    StartDrag = function(self)
        if not self.isMoving and sConfig.general.allowDrag then
            self.window:StartMoving();
            self:HideTooltip()
            self.isMoving = true
        end
    end,
    
    ---
    -- function description
    StopDrag = function(self)
        if self.isMoving then
            self.window:StopMovingOrSizing();
            self:ShowTooltip(self.lastTooltip)
            self.isMoving = false
        end
    end,
    
    ---
    -- Updates the LAYOUT of the frame.
    -- NOTE! This does NOT updated the values of the frames, only the positions.
    Update = function(self)
        if sConfig.averageDisplay.mode == 2 then
            XToLevel_AverageFrame_Classic:Show()
            
            -- Show or hide the backrop
            if sConfig.averageDisplay.backdrop then
                self.window:SetBackdrop(self.backdrop);
                self.window:SetBackdropColor("0.0", "0.75", "0.5", "0.75");
                self.window:SetBackdropBorderColor("0.0", "0.0", "0.0", "1.0");
            else
                self.window:SetBackdrop(nil);
            end
            
            self:UpdateLineVisibility()
            self:UpdateLinePositions()
            self:UpdateFrameSize()
        else
            XToLevel_AverageFrame_Classic:Hide()
        end
    end,
    
    ---
    -- Updates which lines should be visible.
    UpdateLineVisibility = function(self)
        if sConfig.averageDisplay.header then
            self.lines.header:Show()
        end
        if true then
	        if not XToLevel.Player.isActive then
	            self.lines.playerKills:Hide()
	            self.lines.playerQuests:Hide()
	        else
	            self.lines.playerKills:Show()
	            self.lines.playerQuests:Show()
	        end
	        if not (XToLevel.Pet.isActive or XToLevel.Pet.hasBeenActive) then
	            self.lines.petKills:Hide()
	        else
	            self.lines.petKills:Show()
	        end
	        if not XToLevel.Player.isActive or (XToLevel.Player:GetAverageDungeonsRemaining() == nil or not XToLevel.Lib:ShowDungeonData()) then
	            self.lines.playerDungeons:Hide()
	        else
	            self.lines.playerDungeons:Show()
	        end
	        if not XToLevel.Player.isActive or (XToLevel.Player:GetAverageBGsRemaining() == nil or not XToLevel.Lib:ShowBattlegroundData()) then
	            self.lines.playerBGs:Hide()
	        else
	            self.lines.playerBGs:Show()
	        end
	        if not XToLevel.Player.isActive or (XToLevel.Player:GetAverageBGObjectivesRemaining() == nil or not XToLevel.Lib:ShowBattlegroundData()) then
	            self.lines.playerBGOs:Hide()
	        else
	            self.lines.playerBGOs:Show()
	        end
	        
	        if XToLevel.Player.isActive and sConfig.averageDisplay.progress then
	            self.lines.playerProgress:Show()
	        else
	            self.lines.playerProgress:Hide()
	        end
	        if (XToLevel.Pet.isActive or XToLevel.Pet.hasBeenActive) and sConfig.averageDisplay.petProgress then
	            self.lines.petProgress:Show()
	        else
	            self.lines.petProgress:Hide()
	        end
        end
    end,
    
    ---
    -- function description
    UpdateLinePositions = function(self)
        -- Show / Hide the lines and update the anchors
        -- The elements are re-arraged into a temp array according to their tabIndex
        local iLines = {}
        for eName, eElem in pairs(self.lines) do
            iLines[eElem.tabIndex] = { name=eName, elem=eElem }
        end
        
        local nextAnchor = self.window
        local nextMarginV = self.textMargin
        local nextMarginH = self.textMargin
        local nextPoint = "TOPLEFT"
        local currentIndent =  -nextMarginH
        for index, value in ipairs(iLines) do
            local name = value.name
            local elem = value.elem
            
            elem:ClearAllPoints()
            if sConfig.averageDisplay[name] and elem:IsShown() then
                -- Clear text indent if the previous element was in the same group
                if nextAnchor.group == elem.group then
                    nextMarginH = 0
                else
                    currentIndent = currentIndent + nextMarginH
                end
                elem:SetPoint("TOPLEFT", nextAnchor, nextPoint, nextMarginH, -nextMarginV)
                elem.lineIndent = currentIndent
                
                nextAnchor = elem
                nextMarginV = self.lineSpacing
                nextPoint = "BOTTOMLEFT"
            else
                elem:Hide()
            end
        end
    end,
    
    ---
    -- function description
    UpdateFrameSize = function(self)
        -- Calculate the height and width of the lines
        local maxWidth = 0
        local totalHeight = self.textMargin * 2
        for name, value in pairs(self.lines) do
            if value:IsVisible() then
                local currentWidth = value.text:GetWidth() + (value.lineIndent or 0)
                -- local currentWidth = value:GetWidth() + (value.lineIndent or 0)
                if currentWidth  > maxWidth then
                    maxWidth = currentWidth
                end
                totalHeight = totalHeight + value:GetHeight() + self.lineSpacing
            end
        end
        
        -- Resize all the lines, so they match the longest line.
        for name, value in pairs(self.lines) do
            value:SetWidth(maxWidth)
        end
        
        -- Set the display box size
        local totalWidth = maxWidth + (self.textMargin * 2)
        self.window:SetWidth(totalWidth)
        self.window:SetHeight(totalHeight)
    end,
    
    ---
    -- Function
    CreateLine = function(self, lineName, group, tabIndex, toolTip, initalValue, fontStringTemplate)
        self.lines[lineName] = CreateFrame("Frame", "XToLevel_AverageFrame_Classic_" .. lineName, self.window)
        self.lines[lineName]:EnableMouse(true)
        self.lines[lineName]:SetMovable(true)
        self.lines[lineName].group = group
        self.lines[lineName].tabIndex = tabIndex
        self.lines[lineName].text = self.lines[lineName]:CreateFontString(nil, 'OVERLAY', fontStringTemplate)
        self.lines[lineName].text:SetText(initalValue)
        self.lines[lineName].actualWidth = self.lines[lineName].text:GetWidth()
        self.lines[lineName]:SetHeight(self.lines[lineName].text:GetHeight())
        self.lines[lineName]:SetWidth(self.lines[lineName].text:GetWidth())
        if toolTip ~= nil then
            self.lines[lineName]:SetScript("OnEnter", function() self:ShowTooltip(toolTip) end)
            self.lines[lineName]:SetScript("OnLeave", function() self:HideTooltip() end)
        end
        self.lines[lineName]:SetScript("OnMouseDown", function()self:StartDrag() end)
        self.lines[lineName]:SetScript("OnMouseUp", function() 
            self:StopDrag()
            if arg1 == "RightButton" and sConfig.general.allowSettingsClick then
                XToLevel.Config:Open("window")
            end
        end)
    end,
    
    --- Creates the lines for the window.
    CreateLines = function(self)
        -- Create the lines
        self:CreateLine('header', 'header', 1, nil, 'XToLevel', 'XToLevel_h1')
        self:CreateLine('playerKills', 'player', 2, 'kills', L["Kills"], 'XToLevel_span')
        self:CreateLine('playerQuests', 'player', 3, 'quests', L["Quests"], 'XToLevel_span')
        self:CreateLine('playerDungeons', 'player', 4, 'dungeons', L["Dungeons"], 'XToLevel_span')
        self:CreateLine('playerBGs', 'player', 5, 'bg', L["Battles"], 'XToLevel_span')
        self:CreateLine('playerBGOs', 'player', 6, 'bg', L["Objectives"], 'XToLevel_span')
        self:CreateLine('playerProgress', 'player', 7, 'experience', L["XP Percent"], 'XToLevel_span')
        self:CreateLine('petKills', 'player', 8, 'pet', L["Pet"], 'XToLevel_span')
        self:CreateLine('petProgress', 'player', 9, 'pet xp', L["Pet XP"], 'XToLevel_span')
    end,
    
    ---
    -- function description
    WriteToLine = function(self, lineName, labelName, value, color)
        if self.lines[lineName] ~= nil and type(self.lines[lineName].text) == "table" then
            
            if color ~= nil then
                local playerProgressColor = XToLevel.Lib:GetProgressColor(XToLevel.Player:GetProgressAsPercentage())
                self.lines[lineName].text:SetText("|cFF".. self.labelColor .. tostring((sConfig.averageDisplay.verbose and L[labelName]) or L[labelName .. " Short"]) .. ':|r |cFF'.. color .. tostring(value) .."|r")
            else
                self.lines[lineName].text:SetText(((sConfig.averageDisplay.verbose and L[labelName]) or L[labelName .. " Short"]) .. ': ' .. tostring(value))
            end
            self.lines[lineName]:SetHeight(self.lines[lineName].text:GetHeight())
            self.lines[lineName]:SetWidth(self.lines[lineName].text:GetWidth())
        else
            return false
        end
    end,
    
    --- Called each time an event is fired.
    OnEvent = function(self)
        return true
    end,
    
    ---
    -- function description
    GetTextColor = function(self, type)
        if sConfig.averageDisplay.colorText then
            if type == "player" then
                return XToLevel.Lib:GetProgressColor(XToLevel.Player:GetProgressAsPercentage());
            elseif type == "pet" then
                return XToLevel.Lib:GetProgressColor(XToLevel.Pet:GetProgressAsPercentage());
            else
                console:log("Unable to determine the color to use. Type '" .. tostring(type) .."' is not valid")
                return nil
            end
        else
            return nil
        end
    end,

    --- Sets the kill value for the frame
    SetKills = function(self, value)
        self:WriteToLine("playerKills", "Kills", value, self:GetTextColor("player"))
    end,
    
    --- Sets the quest value for the frame
    SetQuests = function(self, value)
        self:WriteToLine("playerQuests", "Quests", value, self:GetTextColor("player"))
    end,
    
    --- Sets the dungeon value for the frame
    SetDungeons = function(self, value)
        self:WriteToLine("playerDungeons", "Dungeons", value, self:GetTextColor("player"))
    end,
    
    --- Sets the battle value for the frame
    SetBattles = function(self, value)
        self:WriteToLine("playerBGs", "Battles", value, self:GetTextColor("player"))
    end,
    
    --- Sets the objectives value for the frame
    SetObjectives = function(self, value)
        self:WriteToLine("playerBGOs", "Objectives", value, self:GetTextColor("player"))
    end,

    --- Sets the value for the progress bar.
    -- Changes both the progress bar and the text.
    SetProgress = function(self, percent)
        if sConfig.averageDisplay.progressAsBars then
            local barsRemaining = XToLevel.Player:GetProgressAsBars()
            self:WriteToLine("playerProgress", "XP Bars", barsRemaining .. " " .. L["Bars"], self:GetTextColor("player")) 
        else 
            self:WriteToLine("playerProgress", "XP Percent", percent .. "%", self:GetTextColor("player")) 
        end
    end,
    
    --- Sets the timer value. NOT IMPLEMENTED IN THIS FRAME!
    -- TODO: Implement this feature.
    SetTimer = function(self, value)
        return true
    end,
    
    --- Sets the pet kill value for the frame
    SetPetKills = function(self, value)
        self:WriteToLine("petKills", "Pet", value, self:GetTextColor("pet"))
    end,
    
    --- Sets the pet progress for the frame
    SetPetProgress = function(self, percent)
        
        if sConfig.averageDisplay.progressAsBars then
            local barsRemaining = XToLevel.Pet:GetProgressAsBars()
            self:WriteToLine("petProgress", "Pet Bars", barsRemaining .. " " .. L["Bars"], self:GetTextColor("pet"))
        else
            self:WriteToLine("petProgress", "Pet XP", percent .. "%", self:GetTextColor("pet"))
        end
    end,
}