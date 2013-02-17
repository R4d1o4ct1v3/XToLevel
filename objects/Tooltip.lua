local _, addonTable = ...
---
-- Contains definitions for the Tooltip display.
-- @file XToLevel.Display.lua
-- @release @project-version@
-- @copyright Atli Þór (atli.j@advefir.com)
---
--module "XToLevel.Tooltip" -- For documentation purposes. Do not uncomment!

local L = addonTable.GetLocale()

XToLevel.Tooltip = 
{
    initialized = false,

    OnShow_Before = nil,
    OnShow_XpData = { },

    labelColor = {},
    dataColor = {},
    footerColor = {},

    verticalMargin = 2,
    horizontalMargin = 20,
}

---
-- function description
function XToLevel.Tooltip:Initialize()
    if XToLevel.db.profile.ldb.allowTextColor then
        self.labelColor = { r=0.75, g=0.75, b=0.75 }
        self.dataColor = { r=0.9, g=1, b=0.9 }
        self.footerColor = { r=0.6, g=0.6, b=0.6 }
    end
    self.initialized = true

    GameTooltip:HookScript("OnShow", self.OnShow_HookCallback);
end

---
-- Used to resize the GameTooltip after adding a new line to it.
function XToLevel.Tooltip:ResizeTooltip()
    local str = _G[GameTooltip:GetName() .. "TextLeft" .. GameTooltip:NumLines()]
    if str ~= nil then
        local width = str:GetStringWidth() + self.horizontalMargin
        GameTooltip:SetHeight(GameTooltip:GetHeight() + str:GetStringHeight() + self.verticalMargin);
        if (GameTooltip:GetWidth() < width) then
            GameTooltip:SetWidth(width)
        end
    else
        -- Fallback in case the line couldn't be found.
        GameTooltip:Show()
        console:log("XToLevel.Tooltip::ResizeTooltip - Primary resize method failed, falling back on GameTooltip::Show")
    end
end

---
-- Callback for the GameTooltip:OnShow hook
-- Adds the number of kills needed to unfriendly NPC tooltips.
function XToLevel.Tooltip:OnShow_HookCallback(...)
    if XToLevel.db.profile.general.showNpcTooltipData and XToLevel.Player.level < XToLevel.Player.maxLevel then
        local name, unit = GameTooltip:GetUnit()
        if unit and not UnitIsPlayer(unit) and not UnitIsFriend("player", unit) and UnitLevel(unit) > 0 and not UnitIsTrivial(unit) and UnitHealthMax(unit) > -1 then
            local level = UnitLevel(unit)
            local classification = UnitClassification(unit)

            local thexp = XToLevel.Lib:MobXP(XToLevel.Player.level, level, classification);
            -- console:log("XToLevel.Lib:MobXP(" .. tostring(XToLevel.Player.level) .. ", " .. tostring(level) .. ", " .. tostring(classification) .. ") = " .. tostring(thexp))

            local requiredText = ""
            local cl = nil

            if thexp == 0 then
                -- Search for an approximation from lower levels.
                cl = XToLevel.Player.level - 1
                while thexp == 0 and cl > XToLevel.Player.level - 5 do
                    thexp = XToLevel.Lib:MobXP(cl, level)
                    cl = cl - 1
                end
            end

            if thexp > 0 then
                local killsRequired = XToLevel.Player:GetKillsRequired(thexp);
                if killsRequired > 0 then
                    local output = XToLevel.Player:GetKillsRequired(thexp)
                    if cl ~= nil then
                        output = "~" .. output;
                    end

                    local color = "888888"
                    local diff = XToLevel.Player.level - level

                    local percent = 50 + (diff * 10)
                    if percent <= 100 then
                        if percent < 0 then
                            percent = 0
                        end
                        color = XToLevel.Lib:GetProgressColor(percent)
                    end

                    GameTooltip:AddLine("|cFFAAAAAA" .. L['Kills to level'] ..": |r |cFF" .. color .. output .. "|r", 0.75, 0.75, 0.75)
                    XToLevel.Tooltip:ResizeTooltip()
                else
                    requiredText = nil
                end
            else
                requiredText = nil
            end

            if requiredText then

            end
        else
            local addLine = false
            for i = 1, GameTooltip:NumLines() do
                local text = _G["GameTooltipTextLeft" .. i]:GetText();
                if text == UNIT_SKINNABLE_ROCK or text == UNIT_SKINNABLE_HERB then
                    addLine = i
                end
            end
            if addLine ~= false then
                -- First line should always be the item's name.
                local itemName = _G["GameTooltipTextLeft1"]:GetText()

                -- Copy the color of the "Requires Mining/Herbalism" and use
                -- it as the color of the value.
                local r, g, b = _G["GameTooltipTextLeft" .. addLine]:GetTextColor()
                local required, __, isOldData = XToLevel.Player:GetGatheringRequired_ByItem(itemName)
                if type(required) == "number" and required > 0 then
                    if isOldData then
                        required = "~" .. tostring(required)
                    end
                    GameTooltip:AddLine("|cFFAAAAAANeeded to level: |r " .. required, (r or 1.0), (g or 1.0), (b or 1.0))
                    XToLevel.Tooltip:ResizeTooltip()
                end
            end
        end
    end
end

---
-- Shows the given message when the given frame is rolled over by the mouse.
-- This is tailored to config option error details, such as the low level
-- warning for battleground options, and is displayed in red at the mouse.
-- @param frame The frame that should trigger the message tooltip
-- @param text The text to show in the tooltip.
function XToLevel.Tooltip:SetConfigInfo(frame, text)
    frame:SetScript("OnEnter", function()
        XToLevel.Tooltip:ShowConfigDescription(text)
    end)
    frame:SetScript("OnLeave", function()
        XToLevel.Tooltip:HideConfigDescription()
    end)
end

---
-- The callback for when a config option, set by the SetConfigInfo() function
-- is rolled over by the mouse. Shows the given text at the mosue posistion.
-- The text is displayed in red, at 75% the normal size.
-- NOTE! Use the HideConfigDescription method to hide this tooltip, or you 
-- risk that the scale bleeds over to the next tooltip that is shown.
-- @param text The text to show.
function XToLevel.Tooltip:ShowConfigDescription(text)
    GameTooltip:SetOwner(XToLevel.frame, "ANCHOR_CURSOR")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(text, 1, 0.25, 0.25, true)
    GameTooltip:Show()
end

---
-- Hides the tooltip, setting hte scale back to normal.
function XToLevel.Tooltip:HideConfigDescription()
    GameTooltip:Hide();
end

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
--        "all". ("all" is the default, if an invalid mode
--        is passed.)
function XToLevel.Tooltip:Show(frame, anchorPont, relativeFrame, relativePoint, footerText, mode)
    -- Initialize
    if not self.initialized then
        self:Initialize()
    end

    GameTooltip:Hide()

    if false and frame ~= nil then
        GameTooltip:SetOwner(frame, "ANCHOR_NONE")
    end
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    if anchorPont ~= nil or relativeFrame ~= nil or relativePoint ~= nil then
        GameTooltip:ClearAllPoints()
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
    elseif mode == "gathering" then
        GameTooltip:AddLine(L['Gathering'] or "Gathering")
        self:AddGathering()
        GameTooltip:AddLine(" ")
        if XToLevel.Player:HasGatheringInfo() then
            self:AddGatheringDetails()
            GameTooltip:AddLine(" ")
        end
    elseif mode == "experience" then
        GameTooltip:AddLine(L['Experience'])
        self:AddExperience()
        GameTooltip:AddLine(" ")
    elseif mode == "timer" then
        GameTooltip:AddLine("Time to level")
        self:AddTimerDetailes(false)
        GameTooltip:AddLine(" ")
    elseif mode == "guild" then
        GameTooltip:AddLine(L['Guild'] .. ": ")
        self:AddGuildInfo()
        GameTooltip:AddLine(" ")
    else
        -- The old "overall" tootip
        GameTooltip:AddLine(L["XToLevel"])

        if XToLevel.Player.level < XToLevel.Player:GetMaxLevel() then
            if XToLevel.db.profile.ldb.tooltip.showDetails then
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
            if XToLevel.db.profile.ldb.tooltip.showExperience then
                GameTooltip:AddLine(L["Experience"] .. ": ")
                self:AddExperience()
                GameTooltip:AddLine(" ")
            end
            if XToLevel.db.profile.ldb.tooltip.showGuildInfo then
                GameTooltip:AddLine(L['Guild'] .. ": ")
                self:AddGuildInfo()
                GameTooltip:AddLine(" ")
            end
            if XToLevel.db.profile.ldb.tooltip.showGatheringInfo then
                GameTooltip:AddLine((L["Gathering"] or "Gathering") .. ": ")
                self:AddGathering()
                GameTooltip:AddLine(" ")
                if XToLevel.Player:HasGatheringInfo() then
                    self:AddGatheringDetails()
                    GameTooltip:AddLine(" ")
                end
            end
            if XToLevel.Lib:ShowDungeonData() then
                self:AddDungeons()
                GameTooltip:AddLine(" ")
            end
            if XToLevel.Lib:ShowBattlegroundData() then
                self:AddBattles()
                GameTooltip:AddLine(" ")
            end
            if XToLevel.db.profile.timer.enabled and XToLevel.db.profile.ldb.tooltip.showTimerInfo then
                GameTooltip:AddLine(L["Timer"] .. ":")
                self:AddTimerDetailes(true)
                GameTooltip:AddLine(" ")
            end
        else
            GameTooltip:AddLine(L['Max Level LDB Message'], 255, 255, 255)
        end
    end -- END "Overall" tooltip creation

    if footerText ~= nil then
        GameTooltip:AddLine(tostring(footerText), self.footerColor.r, self.footerColor.g, self.footerColor.b)
    end

    GameTooltip:Show()
end

---
-- Wrapper function to hide the frame.
function XToLevel.Tooltip:Hide()
    GameTooltip:Hide();
end

--
-- Add functions
-- Used by the Show function to assemble the requsted tooltip
--
---
-- function description
function XToLevel.Tooltip:AddKills()
    GameTooltip:AddDoubleLine(" " .. L["Kills"] .. ":" , XToLevel.Lib:NumberFormat(XToLevel.Player:GetAverageKillsRemaining()) .." @ ".. XToLevel.Lib:NumberFormat(XToLevel.Lib:round(XToLevel.Player:GetAverageKillXP(), 0)) .." xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
end
---
-- function description
function XToLevel.Tooltip:AddKillRange()
    local range = XToLevel.Player:GetKillXpRange();
    GameTooltip:AddDoubleLine(" " .. L["Average"] .. ":" , XToLevel.Lib:NumberFormat(XToLevel.Player:GetKillsRequired(range.average)) .." @ ".. XToLevel.Lib:NumberFormat(XToLevel.Lib:round(range.average, 0)) .." xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
    GameTooltip:AddDoubleLine(" " .. L["Min"] .. ":" , XToLevel.Lib:NumberFormat(XToLevel.Player:GetKillsRequired(range.high)) .." @ ".. XToLevel.Lib:NumberFormat(XToLevel.Lib:round(range.high, 0)) .." xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
    GameTooltip:AddDoubleLine(" " .. L["Max"] .. ":" , XToLevel.Lib:NumberFormat(XToLevel.Player:GetKillsRequired(range.low)) .." @ ".. XToLevel.Lib:NumberFormat(XToLevel.Lib:round(range.low, 0)) .." xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
    GameTooltip:AddDoubleLine(" " , " ", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
    GameTooltip:AddDoubleLine(" " .. L["XP Rested"] .. ": " , XToLevel.Lib:NumberFormat(XToLevel.Player:IsRested() or 0) .. " xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
end

---
-- function description
function XToLevel.Tooltip:AddQuests()
    GameTooltip:AddDoubleLine(" " .. L["Quests"] .. ":" , XToLevel.Lib:NumberFormat(XToLevel.Player:GetAverageQuestsRemaining()) .." @ ".. XToLevel.Lib:NumberFormat(XToLevel.Lib:round(XToLevel.Player:GetAverageQuestXP(), 0)) .." xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
end
---
-- function description
function XToLevel.Tooltip:AddQuestRange()
    local range = XToLevel.Player:GetQuestXpRange();
    GameTooltip:AddDoubleLine(" " .. L["Average"] .. ":" , XToLevel.Lib:NumberFormat(XToLevel.Player:GetQuestsRequired(range.average)) .." @ ".. XToLevel.Lib:NumberFormat(XToLevel.Lib:round(range.average, 0)) .." xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
    GameTooltip:AddDoubleLine(" " .. L["Min"] .. ":" , XToLevel.Lib:NumberFormat(XToLevel.Player:GetQuestsRequired(range.high)) .." @ ".. XToLevel.Lib:NumberFormat(XToLevel.Lib:round(range.high, 0)) .." xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
    GameTooltip:AddDoubleLine(" " .. L["Max"] .. ":" , XToLevel.Lib:NumberFormat(XToLevel.Player:GetQuestsRequired(range.low)) .." @ ".. XToLevel.Lib:NumberFormat(XToLevel.Lib:round(range.low, 0)) .." xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
end

---
-- function description
function XToLevel.Tooltip:AddDungeonInfo()
    GameTooltip:AddDoubleLine(" " .. L['Dungeons'] .. ":" , XToLevel.Lib:NumberFormat(XToLevel.Player:GetAverageDungeonsRemaining()) .." @ ".. XToLevel.Lib:NumberFormat(XToLevel.Lib:round(XToLevel.Player:GetAverageDungeonXP(), 0)) .." xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
end

---
-- function description
function XToLevel.Tooltip:AddDungeons()
    if (# XToLevel.db.char.data.dungeonList) > 0 then
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

        if XToLevel.db.char.data.dungeonList[1].inProgress then
            GameTooltip:AddLine(L['Current Dungeon'] .. ":")
        else
            GameTooltip:AddLine(L['Last Dungeon'] .. ":")
        end

        local dungeonName = nil
        if type(XToLevel.db.char.data.dungeonList[1].name) ~= "string" then
            if GetRealZoneText() ~= nil then
                XToLevel.db.char.data.dungeonList[1].name = GetRealZoneText()
                dungeonName = XToLevel.db.char.data.dungeonList[1].name
            else
                dungeonName = "Unknown"
            end
        else
            dungeonName = XToLevel.db.char.data.dungeonList[1].name
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
end

---
-- function description
function XToLevel.Tooltip:AddExperience()
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
end

---
-- Guild info
function XToLevel.Tooltip:AddGuildInfo()
    if XToLevel.Player.guildLevel ~= nil and XToLevel.Player.guildXP ~= nil then
        GameTooltip:AddDoubleLine(" Level:" , XToLevel.Player.guildLevel .. ' / 25', self.labelColor.r, self.labelColor.g, self.labelColor.b,    self.dataColor.r, self.dataColor.b, self.dataColor.b)

        local xpGained = tostring(XToLevel.Lib:ShrinkNumber(XToLevel.Player.guildXP))
        local xpTotal = tostring(XToLevel.Lib:ShrinkNumber(XToLevel.Player.guildXPMax))
        local xpProgress = tostring(XToLevel.Player:GetGuildProgressAsPercentage(1))
        GameTooltip:AddDoubleLine(" " .. L["XP Progress"] .. ": " , xpGained .. ' / ' .. xpTotal .. ' [' .. xpProgress .. '%]' , self.labelColor.r, self.labelColor.g, self.labelColor.b,    self.dataColor.r, self.dataColor.b, self.dataColor.b)

        local dialyGained = tostring(XToLevel.Lib:ShrinkNumber(XToLevel.Player.guildXPDaily))
        local dialyTotal = tostring(XToLevel.Lib:ShrinkNumber(XToLevel.Player.guildXPDailyMax))
        local dialyProgress = tostring(XToLevel.Player:GetGuildDailyProgressAsPercentage(1))
        GameTooltip:AddDoubleLine(" " .. L['Daily Progress'] .. ": " , dialyGained .. ' / ' .. dialyTotal .. ' [' .. dialyProgress .. '%]' , self.labelColor.r, self.labelColor.g, self.labelColor.b,    self.dataColor.r, self.dataColor.b, self.dataColor.b)
    else
        GameTooltip:AddLine(" No guild leveling info found.", self.labelColor.r, self.labelColor.g, self.labelColor.b)
    end
end

---
-- function description
function XToLevel.Tooltip:AddBattlegroundInfo()
    GameTooltip:AddDoubleLine(" " .. L["Battles"] .. ":" , XToLevel.Lib:NumberFormat(XToLevel.Player:GetAverageBGsRemaining() or 0) .." @ ".. XToLevel.Lib:NumberFormat(XToLevel.Lib:round(XToLevel.Player:GetAverageBGXP(), 0)) .." xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
    GameTooltip:AddDoubleLine(" " .. L["Objectives"] .. ":" , XToLevel.Lib:NumberFormat(XToLevel.Player:GetAverageBGObjectivesRemaining() or 0) .." @ ".. XToLevel.Lib:NumberFormat(XToLevel.Lib:round(XToLevel.Player:GetAverageBGObjectiveXP(), 0)) .." xp", self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
end

---
-- function description
function XToLevel.Tooltip:AddBattles()
    local bgs = XToLevel.Player:GetBattlegroundsListed()
    if bgs ~= nil and (# XToLevel.db.char.data.bgList) > 0 then
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
            if latestData.inProgress then
                GameTooltip:AddLine(L['Current Battleground'] .. ":")
            else
                GameTooltip:AddLine(L['Last Battleground'] .. ":")
            end
            if type(latestData.name) ~= "string" then
                lastData.name = "Unknown"
            end

            GameTooltip:AddDoubleLine(" ".. L['Name'] ..": " , latestData.name, self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
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
end

--- Detailed timer info.
function XToLevel.Tooltip:AddTimerDetailes(mininmal)
    if XToLevel.db.profile.timer.enabled and XToLevel.Player.level < XToLevel.Player:GetMaxLevel() then
        -- Gather data.
        local mode, timeToLevel, timePlayed, xpPerHour, totalXP, warning = XToLevel.Player:GetTimerData()
        --local showUsingLevelWarning = mode ~= nil and mode ~= XToLevel.db.profile.timer.mode
        --local showUsingOldDataWarning = mode == 1 and timePlayed == 0

        if mode == nil then
            mode = L["Updating..."]
            timeToLevel = 0
            if timePlayed == nil then timePlayed = "N/A" end
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
        if warning == 2 then
            GameTooltip:AddDoubleLine(" " .. L["Data"] .. ": ", mode, self.labelColor.r, self.labelColor.g, self.labelColor.b, 1.0, 0.0, 0.0);
        else
            GameTooltip:AddDoubleLine(" " .. L["Data"] .. ": ", mode, self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b);
        end
        GameTooltip:AddDoubleLine(" " .. L["Time to level"] .. ": ", timeToLevel, self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b);
        if not mininmal then
            GameTooltip:AddLine(" ")
        end

        local fTimePlayed = XToLevel.Lib:TimeFormat(timePlayed);
        if fTimePlayed == "NaN" then
            fTimePlayed = "N/A"
        end

        GameTooltip:AddDoubleLine(" " ..L["Time elapsed"].. ": ", fTimePlayed, self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b);
        GameTooltip:AddDoubleLine(" " ..L["Total XP"] .. ": ", XToLevel.Lib:NumberFormat(totalXP), self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b);
        GameTooltip:AddDoubleLine(" " ..L["XP per hour"] .. ": ", XToLevel.Lib:NumberFormat(xpPerHour), self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b);
        GameTooltip:AddDoubleLine(" " ..L["XP Needed"] .. ": ", XToLevel.Lib:NumberFormat(XToLevel.Player.maxXP - XToLevel.Player.currentXP), self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b);

        if warning == 2 and not mininmal then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["No Kills Recorded. Using Level"], 1.0, 0.0, 0.0, true)
        elseif warning == 1 and not minimal then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["No Kills Recorded. Using Old"], 1.0, 0.0, 0.0, true)
        end
    else
        GameTooltip:AddDoubleLine(" Mode", "Disabled", self.labelColor.r, self.labelColor.g, self.labelColor.b, 1.0, 0.0, 0.0);
    end
end

function XToLevel.Tooltip:AddGathering()
    local linesAdded = 0
    local nodesRequired, xpPerNode = XToLevel.Player:GetAverageGatheringRequired()
    if nodesRequired ~= nil then
        xpPerNode = XToLevel.Lib:NumberFormat(XToLevel.Lib:round(xpPerNode, 0))
        GameTooltip:AddDoubleLine(L["Average"] .. ": ", nodesRequired.. " @ " .. xpPerNode .. " xp" , self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
    else
        GameTooltip:AddLine(" " .. L['No Battles Fought'], self.labelColor.r, self.labelColor.b, self.labelColor.b)
    end
end

function XToLevel.Tooltip:AddGatheringDetails()
    local linesAdded = 0
    local actions = XToLevel.Player:GetGatheringActions();
    if actions ~= nil and # actions > 0 then
        for i, action in ipairs(actions) do
            local items = XToLevel.Player:GetGatheringItems(action);
            if # items > 0 then
                GameTooltip:AddLine(action .. ": ")
                for i, item in ipairs(items) do
                    local required, averageXP, isOldData = XToLevel.Player:GetGatheringRequired_ByItem(item);
                    if type(required) == "number" and required > 0 then
                        if isOldData then
                            required = "~" .. required
                        end
                        local avgxpFormatted = XToLevel.Lib:NumberFormat(XToLevel.Lib:round(averageXP, 1))
                        GameTooltip:AddDoubleLine(" - " .. item, required.. " @ " .. tostring(avgxpFormatted) .. " xp" , self.labelColor.r, self.labelColor.g, self.labelColor.b, self.dataColor.r, self.dataColor.b, self.dataColor.b)
                        linesAdded = linesAdded + 1
                    end
                end
                if i < # actions then
                    GameTooltip:AddLine(" ")
                end
            end
        end
    end
end
