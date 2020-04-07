local _, addonTable = ...
---
-- Controls all Playe related functionality.
-- @file XToLevel.Player.lua
-- @release @project-version@
-- @author Atli Þór (r4d1o4ct1v3v3@gmail.com)
---
--module "XToLevel.Player" -- For documentation purposes. Do not uncomment!

local L = addonTable.GetLocale()

---
-- Control object for player functionality and calculations.
-- @class table
-- @name XToLevel.Player
-- @field isActive Indicates whether the object has been sucessfully initialized.
-- @field level The current level of the player.
-- @field maxLevel The max level for the player, according to the account type.
-- @field currentXP The current XP of the player.
-- @field restedXP The amount of extra "rested" XP the player has accumulated.
-- @field maxXP The total XP required for the current level.
-- @field killAverage Holds the latest value of the GetAverageKillXP method. Do
--        not use this field directly. Call the funciton instead.
-- @field killRange Holds the lates value of the GetKillXpRange method. Do not
--        use this field directly. Call the function instead.
-- @field questAverage Holds the latest value of the GetAverageQuestXP method.
--        Do not use this field directly. Call the funciton instead.
-- @field questRange Holds the lates value of the GetQuestXpRange method. Do not
--        use this field directly. Call the function instead.
-- @field bgAverage Holds the latest value of the GetAverageBGXP method. Do not
--        use this field directly. Call the funciton instead.
-- @field bgAverageObj Holds the latest value of the GetAverageBGObjectiveXP
--        method. Do not use this field directly. Call the funciton instead.
-- @field dungeonAverage Holds the latest value of the GetAverageDungeonXP method. 
--        Do not use this field directly. Call the funciton instead.
-- @field killListLength The max number of kills to record.
-- @field questListLength The max number of quests to record.
-- @field bgListLength The max number of battlegrounds to record.
-- @field dungeonListLength The max number of dungeons to record.
-- @field hasEnteredBG Indicates whether the player is in a bg.
-- @field dungeonList A list of dungeon names. Set by the GetDungeonsListed function
-- @field latestDungeonData The data for the lates/current dungeon.
-- @field bgList A list of bg names. Set by the GetBattlegroundsListed
-- @field latestBgData The data for the latest bg.
---
XToLevel.Player = {
	-- Members
	isActive = false,
	level = nil,
	maxLevel = nil, -- Assume WotLK-enabled. Will be corrected once properly initialized.
	class = nil,
	currentXP = nil,
    restedXP = 0,
	maxXP = nil,
    killAverage = nil,
    killRange = { low = nil, high = nil, average = nil },
	questAverage = nil,
	questRange = { low = nil, high = nil, average = nil },
    petBattleAverage = nil,
	bgAverage = nil,
	bgObjAverage = nil,
    dungeonAverage = nil,
	killListLength = 100, -- The max allowed value, not the current selection.
	questListLength = 100,
    petBattleListLength = 50,
	bgListLength = 300,
	dungeonListLength = 100,
    digListLength = 1,
	hasEnteredBG = true,
    
    guildLevel = nil,
    guildXP = nil,
    guildXPMax = nil,
    guildXPDaily = nil,
    guildXPDailyMax = nil,
    guildHasQueried = false,
	
	timePlayedTotal = nil,
	timePlayedLevel = nil,
	timePlayedUpdated = nil,
	
	dungeonList = {},
	latestDungeonData = { totalXP = nil, killCount = nil, xpPerKill = nil, otherXP = nil },
	bgList = { },
	latestBgData = { totalXP = nil, objCount = nil, killCount = nil, xpPerObj = nil, xpPerKill = nil, otherXP = nil, inProgress = nil, name = nil,},
	
	lastSync = time(),
	lastXpPerHourUpdate = time() - 60,
	xpPerSec = nil,
	xpPerSecTimeout = 2, -- The number of seconds between re-calculating the xpPerSec
	timerHandler = nil,
    
    percentage = nil,
	lastKnownXP = nil,
    
    guildPercentage = nil,
    guildLastKnownXP = nil,
    
    guildDailyPercentage = nil,
    guildDailyLastKnownXP = nil,
}
	
-- Constructor
function XToLevel.Player:Initialize()
    self:SyncData()
    --self:SyncGuildData()

    self:GetMaxLevel();

    if self.level == self.maxLevel then
        self.isActive = false
    else
        self.isActive = true
    end

    self.killAverage = nil
    self.bgObjAverage = nil
    self.questAverage = nil

    if XToLevel.db.profile.timer.enabled then
        self.timerHandler = XToLevel.timer:ScheduleRepeatingTimer(XToLevel.Player.TriggerTimerUpdate, self.xpPerSecTimeout)
    end
end

---
-- Calculates the max level for the player, based on the expansion level
-- available to the player.
---
function XToLevel.Player:GetMaxLevel()
    if self.maxLevel == nil then
        self.maxLevel = MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()]
    end
    return self.maxLevel
end

---
-- Returns the player class in English, fully capitalized. For example:
-- "HUNTER", "WARRIOR".
function XToLevel.Player:GetClass()
    if self.class == nil then
        local playerClass, englishClass = UnitClass("player");
        self.class = englishClass
    end
    return self.class
end

---
-- Creates an empty template entry for the bg list.
-- @return The empty template table.
--- 
function XToLevel.Player:CreateBgDataArray()
    return {
        inProgress = false,
        level = nil,
        name = nil,
        totalXP = 0,
        objTotal = 0,
        objCount = 0,
        killCount = 0,
        killTotal = 0,
        objMinorTotal = 0,
        objMinorCount = 0,
    }
end

---
-- Creates an empty template entry for the dungeon list.
-- @return The empty template table.
--- 
function XToLevel.Player:CreateDungeonDataArray()
    return {
        inProgress = false,
        level = nil,
        name = nil,
        totalXP = 0,
        killCount = 0,
        killTotal = 0,
        rested = 0,
    }
end

---
-- Updates the level and XP values in the table with the actual values on
-- the server.
---
function XToLevel.Player:SyncData()
    self.level = UnitLevel("player")
    self.currentXP = UnitXP("player")
    self.maxXP = UnitXPMax("player")
    self.lastSync = time() -- Used for the XP/hr calculations. May be altered elsewhere!

    local rested = GetXPExhaustion() or 0
    self.restedXP = rested / 2
end

---
-- Updates the guild XP info.
---
function XToLevel.Player:SyncGuildData()
    if IsInGuild() then
        self.guildLevel = GetGuildLevel();

        local currentXP, remainingXP, dailyXP, maxDailyXP = UnitGetGuildXP("player");
        -- maxDailyXP is the only field that *should* always be positive.
        if maxDailyXP > 0 then 
            self.guildXP = currentXP;
            self.guildXPMax = currentXP + remainingXP;
            self.guildXPDaily = dailyXP;
            self.guildXPDailyMax = maxDailyXP;
        elseif not self.guildHasQueried then
            QueryGuildXP()
            self.guildHasQueried = true;
        end
    else
        self.guildLevel = nil
        self.guildXP =  nil;
        self.guildXPMax =  nil;
        self.guildXPDaily = nil;
        self.guildXPDailyMax = nil;
    end
end

--- Updates the time played values.
-- @param total The total time played on this char, in seconds.
-- @param level The total time played this level, in seconds.
function XToLevel.Player:UpdateTimePlayed(total, level)
    if type(level) == "number" and level > 0 then
        self.timePlayedLevel = level
    end
    if type(total) == "number" and total > 0 then
        self.timePlayedTotal = total
    end
    self.timePlayedUpdated = GetTime()
end

--- Callback for the timer registration function.
function XToLevel.Player:TriggerTimerUpdate()
    XToLevel.Player:UpdateTimer()
end
function XToLevel.Player:UpdateTimer()
    self = XToLevel.Player
    self.lastXpPerHourUpdate = GetTime();
    XToLevel.db.char.data.timer.lastUpdated = self.lastXpPerHourUpdate;

    local useMode = XToLevel.db.profile.timer.mode

    -- Use the session data
    if useMode == 1 then
        if type(XToLevel.db.char.data.timer.start) == "number" and type(XToLevel.db.char.data.timer.total) == "number" and XToLevel.db.char.data.timer.total > 0 then
            XToLevel.db.char.data.timer.xpPerSec = XToLevel.db.char.data.timer.total / (XToLevel.db.char.data.timer.lastUpdated - XToLevel.db.char.data.timer.start)
            local secondsToLevel = (self.maxXP - self.currentXP) / XToLevel.db.char.data.timer.xpPerSec
            XToLevel.Average:UpdateTimer(secondsToLevel)
        elseif type(XToLevel.db.char.data.timer.xpPerSec) == "number" and XToLevel.db.char.data.timer.xpPerSec > 0 then
            -- Fallback method #1, in case no XP has been gained this session, but data remains from the last session.
            local secondsToLevel = (self.maxXP - self.currentXP) / XToLevel.db.char.data.timer.xpPerSec
            XToLevel.Average:UpdateTimer(secondsToLevel)
        else
            -- Fallback method #2. Use level data.
            useMode = 2
        end
    end

    -- Use the level data.
    if useMode == 2 then
        if type(self.timePlayedLevel) == "number" and (self.timePlayedLevel + (XToLevel.db.char.data.timer.lastUpdated - self.timePlayedUpdated)) > 0 then
            local xpPerSec = self.currentXP / (self.timePlayedLevel + (XToLevel.db.char.data.timer.lastUpdated - self.timePlayedUpdated))
            if xpPerSec > 0 then
                local secondsToLevel = (self.maxXP - self.currentXP) / xpPerSec
            else
                -- There seems to be a rare temporary condition, whereby some of the data used to calculate the
                -- xpPreSec data is not set correctly and it is set to nil or zero. In those cases, just set
                -- the time-to-level to an hour, until the player gets some XP and the calculations correct themselves.
                local secondsToLevel = 3600
            end
            XToLevel.Average:UpdateTimer(secondsToLevel)
        else
            useMode = false
        end
    end

    -- Fallback, in case both above failed.
    if useMode == false then		
        XToLevel.db.char.data.timer.xpPerSec = 0
        XToLevel.Average:UpdateTimer(nil)
    end
    XToLevel.LDB:UpdateTimer()
end

--- Returns details about the estimated time remaining.
-- @return mode, timeToLevel, timePlayed, xpPerHour, totalXP, warning
function XToLevel.Player:GetTimerData()
    local mode = XToLevel.db.profile.timer.mode == 1 and (L['Session'] or "Session") or (L['Level'] or "Level")
    local timePlayed, totalXP, xpPerSecond, xpPerHour, timeToLevel, warning;
    if XToLevel.db.profile.timer.mode == 1 and tonumber(XToLevel.db.char.data.timer.total) > 0 then
        mode = 1
        warning = 0
        timePlayed = GetTime() - XToLevel.db.char.data.timer.start
        totalXP = XToLevel.db.char.data.timer.total
        xpPerSecond = totalXP / timePlayed 
        xpPerHour = ceil(xpPerSecond * 3600)
        timeToLevel = (self.maxXP - self.currentXP) / xpPerSecond
    elseif XToLevel.db.profile.timer.mode == 1 and XToLevel.db.char.data.timer.xpPerSec ~= nil and tonumber(XToLevel.db.char.data.timer.xpPerSec) > 0 then
        mode = 1
        warning = 1
        timePlayed = GetTime() - XToLevel.db.char.data.timer.start
        totalXP = self.currentXP
        xpPerSecond = XToLevel.db.char.data.timer.xpPerSec   
        xpPerHour = ceil(xpPerSecond * 3600)
        timeToLevel = (self.maxXP - self.currentXP) / xpPerSecond
    elseif XToLevel.Player.timePlayedLevel then
        if XToLevel.Player.currentXP > 0 then
            mode = 2
            if XToLevel.db.profile.timer.mode ~= 2 then
                warning = 2
            else
                warning = 0;
            end
            timePlayed = self.timePlayedLevel + (GetTime() - self.timePlayedUpdated)
            totalXP = self.currentXP
            xpPerSecond = totalXP / timePlayed 
            xpPerHour = ceil(xpPerSecond * 3600)
            timeToLevel = (self.maxXP - self.currentXP) / xpPerSecond
        else
            mode = nil
            warning = 3
            timePlayed = self.timePlayedLevel + (GetTime() - self.timePlayedUpdated)
            totalXP = 0
            xpPerSecond = nil
            xpPerHour = nil
            timeToLevel = 0
        end
    else
        mode = nil
        warning = 3
        timePlayed = 0
        totalXP = nil
        xpPerSecond = nil
        xpPerHour = nil
        timeToLevel = 0
    end

    return mode, timeToLevel, timePlayed, xpPerHour, totalXP, warning
end

---
-- Calculatest the unrested XP. If a number is passed, it will be used instead of
-- the player's remaining XP.
-- @param totalXP The total XP gained from a kill
function XToLevel.Player:GetUnrestedXP(totalXP)
    if totalXP == nil then
        totalXP = self.maxXP - self.currentXP
    end
    local killXP = totalXP
    if self.restedXP > 0 then
        if self.restedXP > totalXP / 2 then
            killXP = totalXP / 2
            --self.restedXP = self.restedXP - killXP
        else
            killXP = totalXP - self.restedXP
            --self.restedXP = 0
        end
    end
    return killXP
end

---
-- Adds a kill to the kill list and updates the recorded XP value.
-- @param xpGained The TOTAL amount of XP gained, including bonuses.
-- @param mobName The name of the killed mob.
-- @return The gained XP without any rested bounses.
---
function XToLevel.Player:AddKill(xpGained, mobName)
    self.currentXP = self.currentXP + xpGained

    local killXP = self:GetUnrestedXP(xpGained)

    if self.restedXP > killXP then
        self.restedXP = self.restedXP - killXP
    elseif self.restedXP > 0 then
        self.restedXP = 0
    end

    self.killAverage = nil
    table.insert(XToLevel.db.char.data.killList, 1, {mob=mobName, xp=killXP})
    if(# XToLevel.db.char.data.killList > self.killListLength) then
        table.remove(XToLevel.db.char.data.killList)
    end
    XToLevel.db.char.data.total.mobKills = (XToLevel.db.char.data.total.mobKills or 0) + 1

    return killXP
end

---
-- Adds a quest to the quest list and updates the recorded XP value.
-- @param xpGained The XP gained from the quest.
---
function XToLevel.Player:AddQuest (xpGained)
    self.questAverage = nil
    self.currentXP = self.currentXP + xpGained
    table.insert(XToLevel.db.char.data.questList, 1, xpGained)
    if(# XToLevel.db.char.data.questList > self.questListLength) then
        table.remove(XToLevel.db.char.data.questList)
    end
    XToLevel.db.char.data.total.quests = (XToLevel.db.char.data.total.quests or 0) + 1
end

---
-- Adds a pet battle to the quest list and updates the recorded XP value.
-- @param xpGained The XP gained from the pet battle.
---
function XToLevel.Player:AddPetBattle (xpGained)
    self.petBattleAverage = nil
    self.currentXP = self.currentXP + xpGained
    
    if XToLevel.db.char.data.petBattleList == nil then
        XToLevel.db.char.data.petBattleList = {};
    end
    
    table.insert(XToLevel.db.char.data.petBattleList, 1, xpGained)
    if(# XToLevel.db.char.data.petBattleList > self.petBattleListLength) then
        table.remove(XToLevel.db.char.data.petBattleList)
    end
    XToLevel.db.char.data.total.petBattles = (XToLevel.db.char.data.total.petBattles or 0) + 1
end

---
-- Adds XP gain from a gathering profession. Keeps a detailed list of gathered
-- items for future reference.
-- @param action The action taken. (Like: "Mining" or "Herb Gathering")
-- @param target The target of the action. ("Silverleaf", "Copper Vein")
-- @param xp The XP gained.
function XToLevel.Player:AddGathering(action, target, xp)
    if(action == nil or target == nil or xp == nil) then
        console:log("Attempt to add invalid gathering data: " .. tostring(action) .. ", " .. tostring(target) .. ", " .. tostring(xp))
        return nil
    else
        self.currentXP = self.currentXP + xp

        if XToLevel.db.char.data.gathering[action] == nil then
            XToLevel.db.char.data.gathering[action] = {};
        end

        local zoneID = XToLevel.Lib:ZoneID();

        local incremented = false
        for i, v in ipairs(XToLevel.db.char.data.gathering[action]) do
            if v["target"] == target and v["level"] == XToLevel.Player.level and v["zoneID"] == zoneID then
                incremented = true
                XToLevel.db.char.data.gathering[action][i]["count"] = XToLevel.db.char.data.gathering[action][i]["count"] + 1

                -- The XP of an item can change, apparently. I'm guessing it's
                -- a combination of player level vs the item's level range
                -- and the players skill at the given profession.
                -- In any case, if there is a change it should alter the record
                -- rather than be calculated as an average.
                XToLevel.db.char.data.gathering[action][i]["xp"] = xp
            end
        end

        if not incremented then
            table.insert(XToLevel.db.char.data.gathering[action], {
                ["target"] = target,
                ["xp"] = xp,
                ["level"] = XToLevel.Player.level,
                ["zoneID"] = zoneID,
                ["count"] = 1
            });
        end
    end
end

function XToLevel.Player:AddDig(xpGained)
    self.digAverage = nil
    self.currentXP = self.currentXP + xpGained
    if self.restedXP > 0 then
        if ceil(xpGained / 2) > self.restedXP then
            xpGained = xpGained - self.restedXP
            self.restedXP = 0
        else
            xpGained = ceil(xpGained / 2)
            self.restedXP = self.restedXP - xpGained
        end
    end
    table.insert(XToLevel.db.char.data.digs, 1, xpGained)
    if(# XToLevel.db.char.data.digs > self.digListLength) then
        table.remove(XToLevel.db.char.data.digs)
    end
end

---
-- Get the total number of the given target to reach then next level.
-- If the item is invalid, or none of them have been recorded yet, this
-- returns nil.  - If no items have been recorded this level, the function
-- goes as far as 5 levels back to search for the closest value. In this case
-- a third parameter with the value of TRUE is also returned.
-- @param itemName The name of the target. (For example: "Obsidium Mine")
-- @param levelRange The number of levels allowed to go back to find data.
--        Note that only the data for the closest level will be returned, not
--        an average for the whole range.
-- @returns Three values are returned: the # of kills required, the XP per
--          item, and a boolean indicating if the function had to use old
--          data (TRUE if using old, FALSE if not)
function XToLevel.Player:GetGatheringRequired_ByItem(itemName, levelRange)
    -- Returns the average XP gained from the given item within the given
    -- level range. Returns nil if nothing is found.
    local function countAverage(levelRange, itemName)
        if type(levelRange) ~= "number" or levelRange <= 0 then
            levelRange = 1
        end
        local tXP = 0;
        local tCount = 0;
        for action, dataTable in pairs(XToLevel.db.char.data.gathering) do
            for i, data in ipairs(dataTable) do
                if data["target"] == itemName and data["level"] > XToLevel.Player.level - levelRange then
                    tXP = tXP + (data["xp"] * data["count"]);
                    tCount = tCount + data["count"]
                end
            end
        end
        if tXP > 0 and tCount > 0 then
            return (tXP / tCount)
        else
            return nil
        end
    end

    if type(levelRange) ~= "number" then
        levelRange = 5
    end
    if levelRange > XToLevel.Player.level then
        levelRange = XToLevel.Player.level
    end

    local average = nil
    local i = 1
    -- The 85 is just a fail-safe in case... stuff I can't thing up right 
    -- now happens and this turns into an infinite loop. (I hate those things!)
    while i <= levelRange and i < 85 and average == nil do 
        average = countAverage(i, itemName)
        i = i + 1
    end
    if average ~= nil then
        local isOldData = false
        if i > 2 then isOldData = true end
        return ceil((self.maxXP - self.currentXP) / average), average, isOldData;
    else
        return nil, nil, nil
    end
end

---
-- Get the gathering actions recorded. That is; "Mining" and/or "Herb Gathering"
function XToLevel.Player:GetGatheringActions()
    local actions = { };
    for action, __ in pairs(XToLevel.db.char.data.gathering) do
        table.insert(actions, action);
    end
    if # actions > 0 then
        return actions
    else
        return nil
    end
end

---
-- Get the items recorded for a given action. (Things like, "Iron Deposit"
-- or "Silverleaf")
function XToLevel.Player:GetGatheringItems(action)
    local items = { }
    for a, __ in pairs(XToLevel.db.char.data.gathering) do
        if action == a then
            for _, c_item in ipairs(XToLevel.db.char.data.gathering[a]) do
                local alreadyListed = false;
                for _, r_item in ipairs(items) do
                    if c_item.target == r_item then
                        alreadyListed = true
                    end
                end
                if not alreadyListed then
                    table.insert(items, c_item.target)
                end
            end
        end
    end
    if # items > 0 then
        return items;
    else
        return nil;
    end
end

---
-- Get the average XP value for all gathering items within a specific range.
-- @param levelRange The number of levels to go back to fetch data.
--                   Defaults to 2 (that is: this and the last level)
-- @return Returns the avarge xp as a number on success or nil on failure.
function XToLevel.Player:GetAverageGatheringXP(levelRange)
    if type(XToLevel.db.char.data.gathering) == "table" then
        if type(levelRange) ~= "number" or levelRange <= 0 then
            levelRange = 2
        end
        local tXP = 0;
        local tCount = 0;
        for action, dataTable in pairs(XToLevel.db.char.data.gathering) do
            for i, data in ipairs(dataTable) do
                if data["level"] > XToLevel.Player.level - levelRange then
                    tXP = tXP + (data["xp"] * data["count"]);
                    tCount = tCount + data["count"]
                end
            end
        end
        if tXP > 0 and tCount > 0 then
            return (tXP / tCount)
        else
            return nil
        end
    else
        return nil
    end
end

---
-- Returns the average number of gathered items required to level, or nil if
-- there is no gathering data avaialble.
-- @param levelRange The number of levels backwards to go to fetch data.
--                   Defaults to 2 (that is: this and the last level)
-- @return Returns the required nodes and the averageXP per node on success,
--         or nil on failure.
function XToLevel.Player:GetAverageGatheringRequired(levelRange)
    local averageXP = self:GetAverageGatheringXP(levelRange)
    if type(averageXP) == "number" and averageXP > 0 then
        local required = ceil((self.maxXP - self.currentXP) / averageXP);
        if type(required) == "number" and required > 0 then
            return required, averageXP
        else
            return nil
        end
    else
        return nil
    end
end

---
-- Determines whether there is any gathering info to show.
-- Similar in many ways to the GetGatheringActions function but cheaper.
function XToLevel.Player:HasGatheringInfo(levelRange)
    if type(XToLevel.db.char.data.gathering) == "table" then
        if type(levelRange) ~= "number" or levelRange <= 0 then
            levelRange = 2
        end
        local actionCount = 0
        for _, dataList in pairs(XToLevel.db.char.data.gathering) do
            local addAction = false
            for _, data in pairs(dataList) do
                if data["level"] > XToLevel.Player.level - levelRange then
                    addAction = true
                end
            end
            if addAction then
                actionCount = actionCount + 1
            end
        end
        return actionCount > 0
    else
        return false
    end
end

---
-- Determines whether there is any dig info available yet.
function XToLevel.Player:HasDigInfo()
    if type(XToLevel.db.char.data.digs) == "table" then
        return (# XToLevel.db.char.data.digs > 0)
    else
        return nil
    end
end

---
-- Determines the average XP for the current dig-site list.
function XToLevel.Player:GetHighestDigXP()
    if type(XToLevel.db.char.data.digs) == "table" then
        local maxXP = 0
        for i, xp in ipairs(XToLevel.db.char.data.digs) do
            if xp > maxXP then
                maxXP = xp
            end
        end
        if maxXP > 0 then
            return maxXP
        else
            return nil
        end
    else
        return nil
    end
end

---
-- Determines the average arhcealogical find required for next level.
function XToLevel.Player:GetDigsRequired()
    local maxXP = self:GetHighestDigXP()
    if type(maxXP) == "number" and maxXP > 0 then
        -- Digs are calculated the same way as kills, so reusing that code.
        local required = self:GetKillsRequired(maxXP)
        if type(required) == "number" and required > 0 then
            return required, maxXP
        else
            return nil
        end
    else
        return nil
    end
end

---
-- Determines the average full digsite required for next level.
-- @param assumeOneDigIsLeft Set to true if 1 dig (or find) is to be removed from the calculations
--                           This is needed since the "digsite complete" event fires before the final
--                           dig is actually performed, so a message fired on that even may become inaccurate
--                           if that is not accounted for.
function XToLevel.Player:GetDigsitesRequired(assumeOneDigIsLeft)
    local findsPerSite = 6
    local finds, xpPerFind = self:GetDigsRequired()

    if type(finds) == "number" then
        if type(assumeOneDigIsLeft) == "boolean" and assumeOneDigIsLeft then
            finds = finds - 1
        end
        
        local sitesRequried = ceil(finds / findsPerSite)
        local xpRequired = xpPerFind * findsPerSite
        if CanScanResearchSite() and XToLevel.digsiteProgress ~= nil and XToLevel.digsiteProgress > 0 then
            -- If the player is in a digsite, calculate the value as it was when the digsite was entered,
            -- so that the value shown includes the currernt site as well.
            sitesRequried = ceil((finds + XToLevel.digsiteProgress) / findsPerSite)
        end
        return sitesRequried, xpRequired
    else
        return nil
    end
end

---
-- Determines whether there is any pet battles info to show.
function XToLevel.Player:HasPetBattleInfo()
    if type(XToLevel.db.char.data.petBattleList) == "table" then
        return (# XToLevel.db.char.data.petBattleList > 0)
    else
        return false
    end
end

---
-- Start recording a battleground. If a battleground is already in progress
-- the function fails.
-- @param bgName The name of the battleground. (This will be updated later.)
-- @return boolean
---
function XToLevel.Player:BattlegroundStart(bgName)
    if (# XToLevel.db.char.data.bgList) > 0 and XToLevel.db.char.data.bgList[1].inProgress == true then
        console:log("Attempted to start a BG while another one is in progress.")
        return false
    else
        local bgDataArray = self:CreateBgDataArray();
        table.insert(XToLevel.db.char.data.bgList, 1, bgDataArray)
        if(# XToLevel.db.char.data.bgList > self.bgListLength) then
            table.remove(XToLevel.db.char.data.bgList)
        end
        XToLevel.db.char.data.bgList[1].inProgress = true
        XToLevel.db.char.data.bgList[1].name = bgName or false
        XToLevel.db.char.data.bgList[1].level = self.level
        console:log("BG Started! (" .. tostring(XToLevel.db.char.data.bgList[1].name) .. ")")
        return true
    end
end

---
-- Attempts to end the battleground currently in progress. If no battleground
-- is in progress it fails. If the entry that is in progress has recorded no
-- honor, the function fails and removes the entry from the list.
-- @return boolean
---
function XToLevel.Player:BattlegroundEnd()
    if XToLevel.db.char.data.bgList[1].inProgress == true then
        XToLevel.db.char.data.bgList[1].inProgress = false
        console:log("BG Ended! (" .. tostring(XToLevel.db.char.data.bgList[1].name)  .. ")")

        self.bgAverage = nil
        self.bgObjAverage = nil

        if XToLevel.db.char.data.bgList[1].totalXP == 0 then
            table.remove(XToLevel.db.char.data.bgList, 1)
            console:log("BG ended without any honor gain. Disregarding it.)")
            return false
        else
            return true
        end
    else
        console:log("Attempted to end a BG before one was started.")
        return false
    end
end

---
-- Checks whether a battleground is currently in progress.
-- @return A boolean, indicating whether a battleground is in progress.
---
function XToLevel.Player:IsBattlegroundInProgress()
   if # XToLevel.db.char.data.bgList > 0 then
        return XToLevel.db.char.data.bgList[1].inProgress
    else
        return false
    end
end

---
-- Adds a battleground objective to the currently active battleground entry.
-- If the xpGained is less than the minimum required XP for an objective, 
-- the objective is recorded as a kill. (AV centry kills are often not
-- reported as kills, but as quests/objectives, and thus far below what actual
-- objectives reward.)
-- @param xpGained The XP gained from the objective.
-- @return boolean
---
function XToLevel.Player:AddBattlegroundObjective(xpGained)
    if XToLevel.db.char.data.bgList[1].inProgress then
        if xpGained > XToLevel.Lib:GetBGObjectiveMinXP() then
            self.bgObjAverage = nil
            XToLevel.db.char.data.bgList[1].totalXP = XToLevel.db.char.data.bgList[1].totalXP + xpGained
            XToLevel.db.char.data.bgList[1].objTotal = XToLevel.db.char.data.bgList[1].objTotal + xpGained
            XToLevel.db.char.data.bgList[1].objCount = XToLevel.db.char.data.bgList[1].objCount + 1
            XToLevel.db.char.data.total.objectives = (XToLevel.db.char.data.total.objectives or 0) + 1
            return true
        else
            return self:AddBattlegroundKill(xpGained, 'Unknown')
        end
    else
        console:log("Attempt to add a BG objective without starting a BG.")
        return false
    end
end

---
-- Adds a kill to the currently active battleground entry. If no entry is
-- in progress then the function fails.
-- @param xpGained The XP gained from the kill.
-- @param name The name of the mob killed.
-- @return boolean
---
function XToLevel.Player:AddBattlegroundKill(xpGained, name)
    if XToLevel.db.char.data.bgList[1].inProgress then
        XToLevel.db.char.data.bgList[1].totalXP = XToLevel.db.char.data.bgList[1].totalXP + xpGained
        XToLevel.db.char.data.bgList[1].killCount = XToLevel.db.char.data.bgList[1].killCount + 1
        XToLevel.db.char.data.bgList[1].killTotal = XToLevel.db.char.data.bgList[1].killTotal + xpGained
        XToLevel.db.char.data.total.pvpKills = (XToLevel.db.char.data.total.pvpKills or 0) + 1
    else
        console:log("Attempt to add a BG kill without starting a BG.")
    end
end

---
-- Starts recording a dungeon. Fails if already recording a dungeon.
-- @return boolean
---
function XToLevel.Player:DungeonStart()
    if self.isActive and not self:IsDungeonInProgress() then
        local dungeonName = GetRealZoneText()
        local dungeonDataArray = self:CreateDungeonDataArray()
        table.insert(XToLevel.db.char.data.dungeonList, 1, dungeonDataArray)
        if(# XToLevel.db.char.data.dungeonList > self.dungeonListLength) then
            table.remove(XToLevel.db.char.data.dungeonList)
        end

        XToLevel.db.char.data.dungeonList[1].inProgress = true
        XToLevel.db.char.data.dungeonList[1].name = dungeonName or false
        XToLevel.db.char.data.dungeonList[1].level = self.level
        console:log("Dungeon Started! (" .. tostring(XToLevel.db.char.data.dungeonList[1].name) .. ")")
        return true
    else
        console:log("Attempt to start a dungeon failed. Player either not active or already in a dungeon.")
        return false
    end

end

---
-- Stops recording a dungeon. If not recording a dungeon, the function fails.
-- If the dungeon being recorded has yielded no XP, the entry is removed and
-- the function fails.
-- @return boolean
---
function XToLevel.Player:DungeonEnd()
    if XToLevel.db.char.data.dungeonList[1].inProgress == true then
        XToLevel.db.char.data.dungeonList[1].inProgress = false
        self:UpdateDungeonName()
        console:log("Dungeon Ended! (" .. tostring(XToLevel.db.char.data.dungeonList[1].name)  .. ")")

        self.dungeonAverage = nil

        if XToLevel.db.char.data.dungeonList[1].totalXP == 0 then
            table.remove(XToLevel.db.char.data.dungeonList, 1)
            console:log("Dungeon ended without any XP gain. Disregarding it.)")
            return false
        else
            console:log("Dungeon ended successfully")
            return true
        end
    else
        console:log("Attempted to end a Dungeon before one was started.")
        return false
    end
end

---
-- Checks whether a dungeon is in progress.
-- @return boolean
---
function XToLevel.Player:IsDungeonInProgress()
    if # XToLevel.db.char.data.dungeonList > 0 then
        return XToLevel.db.char.data.dungeonList[1].inProgress
    else
        return false
    end
end

---
-- Update the name of the dungeon currently being recorded. If not recording
-- a dungeon, or if the name does not need to be updated, the function fails.
-- @return boolean
---
function XToLevel.Player:UpdateDungeonName()
    local inInstance, type = IsInInstance()
    if self:IsDungeonInProgress() and inInstance and type == "party" then
        local zoneName = GetRealZoneText()
        if XToLevel.db.char.data.dungeonList[1].name ~= zoneName then
            XToLevel.db.char.data.dungeonList[1].name = zoneName
            console:log("Dungeon name updated (" .. tostring(zoneName) ..")")
            return true
        else
            return false
        end
    else
        return false
    end
end

---
-- Adds a kill to the dungeon being recorded. If no dungeon is being recorded
-- the function fails. Note, this function triggers the UpdateDungeonName
-- method, so all dungeons that have a single kill can be asumed to have the
-- correct name associated with it. (Those who do not are discarded anyways)
-- @param xpGained The UNRESTED XP gained from the kill. Ideally, the return
--        value of the AddKill function should be used.
-- @param name The name of the killed mob.
-- @param rested The amount of rested bonus that was gained on top of the
--        base XP.
-- @return boolean
---
function XToLevel.Player:AddDungeonKill(xpGained, name, rested)
    if self:IsDungeonInProgress() then
        XToLevel.db.char.data.dungeonList[1].totalXP = XToLevel.db.char.data.dungeonList[1].totalXP + xpGained
        XToLevel.db.char.data.dungeonList[1].killCount = XToLevel.db.char.data.dungeonList[1].killCount + 1
        XToLevel.db.char.data.dungeonList[1].killTotal = XToLevel.db.char.data.dungeonList[1].killTotal + xpGained
        if type(rested) == "number" and rested > 0 then
            XToLevel.db.char.data.dungeonList[1].rested = XToLevel.db.char.data.dungeonList[1].rested + rested
        end
        XToLevel.db.char.data.total.dungeonKills = (XToLevel.db.char.data.total.dungeonKills or 0) + 1
        self:UpdateDungeonName()
        return true
    else
        console:log("Attempt to add a Dungeon kill without starting a Dungeon.")
        return false
    end
end

---
-- Gets the amount of kills required to reach the next level, based on the
-- passed XP value. The rested bonus is taken into account.
-- @param xp The XP assumed per kill
-- @return An integer or -1 if the input parameter is invalid.
---
function XToLevel.Player:GetKillsRequired(xp)
    if xp > 0 then
        local xpRemaining = self.maxXP - self.currentXP
        local xpRested = self:IsRested()
        if xpRested then
            if((xpRemaining / 2) > xpRested) then
                xpRemaining = xpRemaining - xpRested
            else
                xpRemaining = xpRemaining / 2
            end
        end
        return ceil(xpRemaining / xp)
    else
        return -1
    end
end

---
-- Gets the amount of quests required to reach the next level, based on the
-- passed XP value.
-- @param xp The XP assumed per quest
-- @return An integer or -1 if the input parameter is invalid.
---
function XToLevel.Player:GetQuestsRequired(xp)
    local xpRemaining = self.maxXP - self.currentXP
    if(xp > 0) then
        return ceil(xpRemaining / xp)
    else
        return -1
    end
end

---
-- Gets the amount of pet battles required to reach the next level, based on the
-- passed XP value.
-- @param xp The XP assumed per battle
-- @return An integer or -1 if the input parameter is invalid.
---
function XToLevel.Player:GetPetBattlesRequired(xp)
    local xpRemaining = self.maxXP - self.currentXP
    if(xp > 0) then
        return ceil(xpRemaining / xp)
    else
        return -1
    end
end

---
-- Get the average XP value for all gathering items within a specific range.
-- @param levelRange The number of levels to go back to fetch data.
--                   Defaults to 2 (that is: this and the last level)
-- @return Returns the avarge xp as a number on success or nil on failure.
function XToLevel.Player:GetAveragePetBattleXP(levelRange)
    if self.petBattleAverage == nil then
        if(# XToLevel.db.char.data.petBattleList > 0) then
            local total = 0
            local maxUsed = # XToLevel.db.char.data.petBattleList
            if maxUsed > XToLevel.db.profile.averageDisplay.playerPetBattleListLength then
                maxUsed = XToLevel.db.profile.averageDisplay.playerPetBattleListLength
            end
            for index, value in ipairs(XToLevel.db.char.data.petBattleList) do
                if index > maxUsed then
                    break;
                end
                total = total + value
            end
            self.petBattleAverage = (total / maxUsed);
        else
            return 100
        end
    end
    
    return self.petBattleAverage
end

---
-- Gets the percentage of XP already gained towards the next level.
-- @param fractions The number of fraction digits to be used. Defaults to 1.
-- @return A number between 0 and 100, representing the percentage. 
---
function XToLevel.Player:GetProgressAsPercentage(fractions)
    if type(fractions) ~= "number" or fractions <= 0 then
        fractions = 1
    end
    if self.percentage == nil or self.lastKnownXP == nil or self.lastKnownXP ~= self.currentXP then
        self.lastKnownXP = self.currentXP
        self.percentage = (self.currentXP or 0) / (self.maxXP or 1) * 100
    end
    return XToLevel.Lib:round(self.percentage, fractions)
end

---
-- Get the number of "bars" remaining until the next level is reached. Each
-- "bar" represents 5% of the total value.
-- This has become a common measurement used by players when referring
-- to their progress, inspired by the default WoW UI, where the XP progress
-- bar is split into 20 induvidual cells.
-- @param fractions The number of fraction digits to be used. Defautls to 0.
---
function XToLevel.Player:GetProgressAsBars(fractions)
    if type(fractions) ~= "number" or fractions <= 0 then
        fractions = 0
    end
    local barsRemaining = ceil((100 - ((self.currentXP or 0) / (self.maxXP or 1) * 100)) / 5, fractions)
    return barsRemaining
end

function XToLevel.Player:GetXpRemaining() 
    return self.maxXP - self.currentXP
end

function XToLevel.Player:GetRestedPercentage(fractions)
    if type(fractions) ~= "number" or fractions <= 0 then
        fractions = 0
    end
    return XToLevel.Lib:round((self.restedXP * 2) / self.maxXP * 100, fractions, true);
end

----------------------------------------------------------------------------
-- Guild methods
----------------------------------------------------------------------------
---
-- Gets the percentage the player's guild has gained towards it's next level.
-- @param fractions The number of fractions to include. Defaults to 1.
-- @return A number between 0 and 100.
function XToLevel.Player:GetGuildProgressAsPercentage(fractions)
    if type(fractions) ~= "number" or fractions <= 0 then
        fractions = 1
    end
    if self.guildPercentage == nil or self.guildLastKnownXP == nil or self.guildLastKnownXP ~= self.guildXP then
        self.guildLastKnownXP = self.guildXP
        self.guildPercentage = (self.guildXP or 0) / (self.guildXPMax or 1) * 100
    end
    return XToLevel.Lib:round(self.guildPercentage, fractions)
end

function XToLevel.Player:GetGuildXpRemaining() 
    return self.guildXPMax - self.guildXP
end

function XToLevel.Player:GetGuildDailyProgressAsPercentage(fractions)
    if type(fractions) ~= "number" or fractions <= 0 then
        fractions = 1
    end
    if self.guildDailyPercentage == nil or self.guildDailyLastKnownXP == nil or self.guildDailyLastKnownXP ~= self.guildXP then
        self.guildDailyLastKnownXP = self.guildXPDaily
        self.guildDailyPercentage = (self.guildXPDaily or 0) / (self.guildXPDailyMax or 1) * 100
    end
    return XToLevel.Lib:round(self.guildDailyPercentage, fractions)
end
function XToLevel.Player:GetGuildDailyXpRemaining() 
    return self.guildXPDailyMax - self.guildXPDaily
end

---
-- Get the average XP per kill. The number of kills used is limited by the
-- XToLevel.db.profile.averageDisplay.playerKillListLength configuration directive. 
-- The value returned is stored in the killAverage member, so calling this 
-- function twice only calculates the value once. If no data is avaiable, a 
-- level based estimate  is used.
-- Note that the function applies the Recruit-A-Friend bonus when applicable
-- but that does not affect the actual value stored. It is applied only when
-- the value is about to be returned.
-- @return A number.
---
function XToLevel.Player:GetAverageKillXP ()
    if self.killAverage == nil then
        if(# XToLevel.db.char.data.killList > 0) then
            local total = 0
            local maxUsed = # XToLevel.db.char.data.killList
            if maxUsed > XToLevel.db.profile.averageDisplay.playerKillListLength then
                maxUsed = XToLevel.db.profile.averageDisplay.playerKillListLength
            end
            for index, value in ipairs(XToLevel.db.char.data.killList) do
                if index > maxUsed then
                    break;
                end
                total = total + value.xp
            end
            self.killAverage = (total / maxUsed);
        else
            self.killAverage = XToLevel.Lib:MobXP()
        end
    end

    -- Recruit A Friend beta test.
    -- Simply tripples the DISPLAY value. The actual data remains intact.
    if XToLevel.Lib:IsRafApplied() then 
        return (self.killAverage * 3);
    else
        return self.killAverage
    end
end

---
-- Calculates the average, highest and lowest XP values recorded for kills.
-- The range of data used is limited by the 
-- XToLevel.db.profile.averageDisplay.playerKillListLength config directive. If no data 
-- is available, a level based estimate is used. Note that the function 
-- applies the Recruit-A-Friend bonus when applicable but that does not 
-- affect the actual value stored. It is applied only when the value is 
-- about to be returned.
-- @return A table as : { 'average', 'high', 'low' }
---
function XToLevel.Player:GetKillXpRange ()
    if(# XToLevel.db.char.data.killList > 0) then
        self.killRange.high = 0
        self.killRange.low = 0
        self.killRange.average = 0
        local total = 0
        local maxUsed = # XToLevel.db.char.data.killList
        if maxUsed > XToLevel.db.profile.averageDisplay.playerKillListLength then
            maxUsed = XToLevel.db.profile.averageDisplay.playerKillListLength
        end
        for index, value in ipairs(XToLevel.db.char.data.killList) do
            if index > maxUsed then
                break;
            end
            if value.xp < self.killRange.low or self.killRange.low == 0 then
                self.killRange.low = value.xp
            end
            if value.xp > self.killRange.high then
                self.killRange.high = value.xp
            end
            total = total + value.xp
        end
        self.killRange.average = (total / maxUsed);
    else
        self.killRange.average = XToLevel.Lib:MobXP()
        self.killRange.high = self.killRange.average
        self.killRange.low = self.killRange.average
    end

    -- Recruit A Friend beta test.
    -- Simply tripples the DISPLAY value. The actual data remains intact.
    if XToLevel.Lib:IsRafApplied() then 
        return {
            high = self.killRange.high * 3,
            low = self.killRange.low * 3,
            average = self.killRange.average * 3
        }
    else
        return self.killRange
    end
end

---
-- Gets the average number of kills needed to reache the next level, based
-- on the XP value returned by the GetAverageKillXP function.
-- @return A number. -1 if the function fails.
---
function XToLevel.Player:GetAverageKillsRemaining ()
    if(self:GetAverageKillXP() > 0) then
        return self:GetKillsRequired(self:GetAverageKillXP())
    else
        return -1
    end
end

---
-- Get the average XP per quest. The number of quests used is limited by the
-- XToLevel.db.profile.averageDisplay.playerQuestListLength configuration directive. - 
-- The value returned is stored in the questAverage member, so calling this 
-- function twice only calculates the value once. If no data is avaiable, 
-- a level based estimate is used.
-- Note that the function applies the Recruit-A-Friend bonus when applicable
-- but that does not affect the actual value stored. It is applied only when
-- the value is about to be returned.
-- @return A number.
---
function XToLevel.Player:GetAverageQuestXP ()
    if self.questAverage == nil then
        if(# XToLevel.db.char.data.questList > 0) then
            local total = 0
            local maxUsed = # XToLevel.db.char.data.questList
            if maxUsed > XToLevel.db.profile.averageDisplay.playerQuestListLength then
                maxUsed = XToLevel.db.profile.averageDisplay.playerQuestListLength
            end
            for index, value in ipairs(XToLevel.db.char.data.questList) do
                if index > maxUsed then
                    break;
                end
                total = total + value
            end
            self.questAverage = (total / maxUsed);
        else
            -- A very VERY rought and quite possibly very wrong estimate.
            -- But it is accurate for the first few levels, which is where the inaccuracy would be most visible, so...
            self.questAverage = XToLevel.Lib:MobXP() * math.floor(((self.level + 9) / (self.maxLevel + 9)) * 20)
        end
    end
    -- Recruit A Friend beta test.
    -- Simply tripples the DISPLAY value. The actual data remains intact.
    if XToLevel.Lib:IsRafApplied() then 
        return (self.questAverage * 3);
    else
        return self.questAverage
    end
end

---
-- Calculates the average, highest and lowest XP values recorded for quests.
-- The range of data used is limited by the 
-- XToLevel.db.profile.averageDisplay.playerQuestListLength config directive. If no data 
-- is available, a level based estimate is used. Note that the function 
-- applies the Recruit-A-Friend bonus when applicable but that does not 
-- affect the actual value stored. It is applied only whenthe value is about 
-- to be returned.
-- @return A table as : { 'average', 'high', 'low' }
---
function XToLevel.Player:GetQuestXpRange ()
    if(# XToLevel.db.char.data.questList > 0) then
        self.questRange.high = 0
        self.questRange.low = 0
        self.questRange.average = 0
        local total = 0
        local maxUsed = # XToLevel.db.char.data.questList
        if maxUsed > XToLevel.db.profile.averageDisplay.playerQuestListLength then
            maxUsed = XToLevel.db.profile.averageDisplay.playerQuestListLength
        end
        for index, value in ipairs(XToLevel.db.char.data.questList) do
            if index > maxUsed then
                break;
            end
            if value < self.questRange.low or self.questRange.low == 0 then
                self.questRange.low = value
            end
            if value > self.questRange.high then
                self.questRange.high = value
            end
            total = total + value
        end
        self.questAverage = (total / maxUsed);
        self.questRange.average = self.questAverage
    else
        -- A very VERY rought and quite possibly very wrong estimate.
        -- But it is accurate for the first few levels, which is where the inaccuracy would be most visible, so...
        self.questAverage = XToLevel.Lib:MobXP() * math.floor(((self.level + 9) / (self.maxLevel + 9)) * 20)
        self.questRange.high = self.questAverage
        self.questRange.low = self.questAverage
        self.questRange.average = self.questAverage
    end

    -- Recruit A Friend beta test.
    -- Simply tripples the DISPLAY value. The actual data remains intact.
    if XToLevel.Lib:IsRafApplied() then 
        return {
            high = self.questRange.high * 3,
            low = self.questRange.low * 3,
            average = self.questRange.average * 3
        }
    else
        return self.questRange
    end
end

---
-- Calculates the average, highest and lowest XP values recorded for pet battles.
-- The range of data used is limited by the 
-- XToLevel.db.profile.averageDisplay.playerPetBattleListLength config directive. 
-- @return A table as : { 'average', 'high', 'low' }
---
function XToLevel.Player:GetPetBattleXpRange ()   
    if (# XToLevel.db.char.data.petBattleList > 0) then
        local range = {
            average = 0,
            high = 0,
            low = 9999999
        }
        
        local maxUsed = # XToLevel.db.char.data.petBattleList
        if maxUsed > XToLevel.db.profile.averageDisplay.playerPetBattleListLength then
            maxUsed = XToLevel.db.profile.averageDisplay.playerPetBattleListLength
        end
        
        local total = 0
        local count = 0
        for index, value in ipairs(XToLevel.db.char.data.petBattleList) do
            if index > maxUsed then
                break;
            end
            
            if value > range.high then
                range.high = value
            end
            if value < range.low then
                range.low = value
            end
            total = total + value
            count = count + 1
        end
        range.average = (total / count)
        
        if range.low == 9999999 then
            range.low = range.high
        end
        
        return range
    end
end

---
-- Gets the average number of quests needed to reache the next level, based
-- on the XP value returned by the GetAverageQuestXP function.
-- @return A number. -1 if the function fails.
---
function XToLevel.Player:GetAverageQuestsRemaining ()
    if(self:GetAverageQuestXP() > 0) then
        return self:GetQuestsRequired(self:GetAverageQuestXP())
    else
        return -1
    end
end

---
-- Gets the average number of quests needed to reach the next level, based
-- on the XP value returned by the GetAverageQuestXP function.
-- @return A number. -1 if the function fails.
---
function XToLevel.Player:GetAveragePetBattlesRemaining ()
    if(self:GetAveragePetBattleXP() > 0) then
        return self:GetPetBattlesRequired(self:GetAveragePetBattleXP())
    else
        return -1
    end
end

---
-- Checks whether any battleground data has been recorded yet.
-- @return boolean
---
function XToLevel.Player:HasBattlegroundData()
    return (# XToLevel.db.char.data.bgList > 0)
end

---
-- Get the average XP per BG. The number of BGs used is limited by the
-- XToLevel.db.profile.averageDisplay.playerBGListLength configuration directive.
-- The value returned is stored in the bgAverage member, so calling this 
-- function twice only calculates the value once. If no data is avaiable, 
-- a rough level based estimate is used.
-- @return A number.
---
function XToLevel.Player:GetAverageBGXP ()
    if self.bgAverage == nil then
        if(# XToLevel.db.char.data.bgList > 0) then
            local total = 0
            local maxUsed = # XToLevel.db.char.data.bgList
            if maxUsed > XToLevel.db.profile.averageDisplay.playerBGListLength then
                maxUsed = XToLevel.db.profile.averageDisplay.playerBGListLength
            end
            local usedCounter = 0
            for index, value in ipairs(XToLevel.db.char.data.bgList) do
                if usedCounter >= maxUsed then
                    break;
                end
                -- To compensate for the fact that levels were not recorded before 3.3.3_12r.
                if value.level == nil then
                   XToLevel.db.char.data.bgList[index].level = self.level
                   value.level = self.level
                end
                if self.level - value.level < 5 then
                   total = total + value.totalXP
                   usedCounter = usedCounter + 1
                end
            end
            if usedCounter > 0 then
                self.bgAverage = (total / usedCounter)
            else
                self.bgAverage = XToLevel.Lib:MobXP() * 50  --(XToLevel.Lib:MobXP() * math.floor(((self.level + 9) / (self.maxLevel + 9)) * 20)) * 2
            end
        else
            self.bgAverage = XToLevel.Lib:MobXP() * 50  --(XToLevel.Lib:MobXP() * math.floor(((self.level + 9) / (self.maxLevel + 9)) * 20)) * 2
        end
    end
    return self.bgAverage
end

---
-- Gets the average number of BGs needed to reache the next level, based
-- on the XP value returned by the GetAverageBGXP function.
-- @return A number. nil if the function fails.
---
function XToLevel.Player:GetAverageBGsRemaining()
    local bgAverage = self:GetAverageBGXP()
    if(bgAverage > 0) then
        local xpRemaining = self.maxXP - self.currentXP
        return ceil(xpRemaining / bgAverage)
    else
        return nil
    end
end

---
-- Get the average XP per BG objective. The number of BG objectives used is 
-- limited by the XToLevel.db.profile.averageDisplay.playerBGOListLength config directive. 
-- The value returned is stored in the bgObjAverage member, so calling this 
-- function twice only calculates the value once. If no data is avaiable, 
-- a rough level based estimate is used.
-- @return A number.
---
function XToLevel.Player:GetAverageBGObjectiveXP ()
    if self.bgObjAverage == nil then
        if(# XToLevel.db.char.data.bgList > 0) then
            local total = 0
            local count = 0
            local maxcount = XToLevel.db.profile.averageDisplay.playerBGOListLength
            for index, value in ipairs(XToLevel.db.char.data.bgList) do
                if count >= maxcount then
                    break
                end
                if value.level == nil then
                    XToLevel.db.char.data.bgList[index].level = self.level
                    value.level = self.level
                end
                if (value.objTotal > 0) and (value.objCount > 0) and (self.level - value.level < 5) then
                    total = total + (value.objTotal / value.objCount)
                    count = count + 1
                end
            end
            if count == 0 then
                self.bgObjAverage = self:GetAverageQuestXP() -- * math.floor(((self.level + 9) / (self.maxLevel + 9)) * 20)
            else
                self.bgObjAverage = (total / count)
            end
        else
            self.bgObjAverage = self:GetAverageQuestXP()
        end
    end
    return self.bgObjAverage
end

---
-- Gets the average number of BG Objectives needed to reache the next level, 
-- based on the XP value returned by the GetAverageBGObjectiveXP function.
-- @return A number. -1 if the function fails.
---
function XToLevel.Player:GetAverageBGObjectivesRemaining ()
    local objAverage = self:GetAverageBGObjectiveXP()
    if(objAverage > 0) then
        local xpRemaining = self.maxXP - self.currentXP
        return ceil(xpRemaining / objAverage)
    else
        return nil	
    end
end

---
-- Gets the names of all battlegrounds that have been recorded so far.
-- @return A { 'name' = count, ... } table on success or nil if no data exists.
---
function XToLevel.Player:GetBattlegroundsListed ()
    if(# XToLevel.db.char.data.bgList > 0) then
        local count = 0
        local bgList = {}
        for index, value in ipairs(XToLevel.db.char.data.bgList) do
            if value.level == nil then
                value.level = self.level
                XToLevel.db.char.data.bgList[index].level = self.level
            end
            if self.level - value.level < 5 and value.totalXP > 0 and not value.inProgress then
                bgList[value.name] = (bgList[value.name] or 0) + 1
                count = count + 1
            end
        end
        if count > 0 then
            return bgList;
        else
            return nil
        end
    else
        return nil
    end
end

---
-- Returns the average XP for the given battleground. The data is limited by
-- the XToLevel.db.profile.averageDisplay.playerBGListLength config directive. Note that
-- battlegrounds currently in progress will not be counted.
-- @param name The name of the battleground to be used.
-- @return A number. If the database has no entries, it returns 0.
---
function XToLevel.Player:GetBattlegroundAverage(name)
    if(# XToLevel.db.char.data.bgList > 0) then
        local total = 0
        local count = 0
        local maxcount = XToLevel.db.profile.averageDisplay.playerBGListLength
        for index, value in ipairs(XToLevel.db.char.data.bgList) do
            if count >= maxcount then
                break
            end
            if value.level == nil then
                XToLevel.db.char.data.bgList[index].level = self.level
                value.level = self.level
            end
            if value.name == name and not value.inProgress and (self.level - value.level < 5) then
                total = total + value.totalXP
                count = count + 1
            end
        end
        if count == 0 then
            return 0
        else
            return XToLevel.Lib:round(total / count, 0)
        end
    else
        return 0
    end
end

---
-- Gets details for the last entry in the battleground list.
-- @return A table matching the CreateBgDataArray template, or nil if no
--         battlegrounds have been recorded yet.
---
function XToLevel.Player:GetLatestBattlegroundDetails()
    if # XToLevel.db.char.data.bgList > 0 then
        -- Make sure to get the latest BG in a 5 level range.
        for index, value in ipairs(XToLevel.db.char.data.bgList) do
            if XToLevel.Player.level - tonumber(value.level) < 5 then
                self.latestBgData.name = value.name
                self.latestBgData.totalXP = value.totalXP
                self.latestBgData.objCount = value.objCount
                self.latestBgData.killCount = value.killCount
                self.latestBgData.xpPerObj = 0
                self.latestBgData.xpPerKill = 0
                self.latestBgData.inProgress = value.inProgress
                self.latestBgData.otherXP = value.totalXP - (value.objTotal + value.killTotal)
                if self.latestBgData.objCount > 0 then
                    self.latestBgData.xpPerObj = XToLevel.Lib:round(value.objTotal / self.latestBgData.objCount, 0)
                end
                if self.latestBgData.killCount > 0 then
                    self.latestBgData.xpPerKill = XToLevel.Lib:round(value.killTotal / self.latestBgData.killCount, 0)
                end
                return self.latestBgData
            end
        end
    end
    return nil
end

---
-- Checks whether any dungeon data has been recorded yet.
-- @return boolean
---
function XToLevel.Player:HasDungeonData()
    return (# XToLevel.db.char.data.dungeonList > 0)
end

---
-- Get the average XP per dungeon. The number of dungeons used is limited by
-- the XToLevel.db.profile.averageDisplay.playerDungeonListLength configuration directive.
-- The value returned is stored in the dungeonAverage member, so calling  
-- this function twice only calculates the value once. If no data is, 
-- avaiable a rough level based estimate is used.
-- @return A number.
---
function XToLevel.Player:GetAverageDungeonXP ()
    if self.dungeonAverage == nil then
        if(# XToLevel.db.char.data.dungeonList > 0) and not ((# XToLevel.db.char.data.dungeonList == 1) and XToLevel.db.char.data.dungeonList[1].inProgress) then
            local total = 0
            local maxUsed = # XToLevel.db.char.data.dungeonList
            if maxUsed > XToLevel.db.profile.averageDisplay.playerDungeonListLength then
                maxUsed = XToLevel.db.profile.averageDisplay.playerDungeonListLength
            end
            local usedCounter = 0
            for index, value in ipairs(XToLevel.db.char.data.dungeonList) do
                if usedCounter >= maxUsed then
                    break;
                end
                -- To compensate for the fact that levels were not recorded before 3.3.3_12r.
                if value.level == nil then
                    XToLevel.db.char.data.dungeonList[index].level = self.level
                    value.level = self.level
                end
                if self.level - value.level < 5 then
                    total = total + value.totalXP
                    usedCounter = usedCounter + 1
                end
            end
            if usedCounter > 0 then
                self.dungeonAverage = (total / usedCounter)
            else
                self.dungeonAverage = XToLevel.Lib:MobXP() * 100
            end
        else
            self.dungeonAverage = XToLevel.Lib:MobXP() * 100
        end
    end
    return self.dungeonAverage
end

---
-- Gets the average number of dungeons needed to reache the next level, 
-- basedon the XP value returned by the GetAverageDungeonXP function.
-- @return A number. nil if the function fails.
---
function XToLevel.Player:GetAverageDungeonsRemaining()
    local dungeonAverage = self:GetAverageDungeonXP()
    if(dungeonAverage > 0) then
        return self:GetKillsRequired(dungeonAverage)
    else
        return nil
    end
end

---
-- Gets the names of all dungeons that have been recorded so far.
-- @return A { 'name' = count, ... } table on success or nil if no data exists.
---
function XToLevel.Player:GetDungeonsListed ()
    if # XToLevel.db.char.data.dungeonList > 0 then
        -- Clear list in a memory efficient way.
        for index, value in pairs(self.dungeonList) do
            self.dungeonList[index] = 0
        end
        local count = 0
        for index, value in ipairs(XToLevel.db.char.data.dungeonList) do
            if value.level == nil then
                XToLevel.db.char.data.dungeonList[index].level = self.level
                value.level = self.level
            end
            if self.level - value.level < 5 and value.totalXP > 0 and not value.inProgress then
                self.dungeonList[value.name] = (self.dungeonList[value.name] or 0) + 1
                count = count + 1
            end
        end
        if count > 0 then
            return self.dungeonList;
        else
            return nil
        end
    else
        return nil
    end
end

---
-- Returns the average XP for the given dungeon. The data is limited by
-- the XToLevel.db.profile.averageDisplay.playerDungeonListLength config directive. Note
-- that dungeons currently in progress will not be counted.
-- @param name The name of the dungeon to be used.
-- @return A number. If the database has no entries, it returns 0.
---
function XToLevel.Player:GetDungeonAverage(name)
    if(# XToLevel.db.char.data.dungeonList > 0) then
        local total = 0
        local count = 0
        local maxcount = XToLevel.db.profile.averageDisplay.playerDungeonListLength
        for index, value in ipairs(XToLevel.db.char.data.dungeonList) do
            if count >= maxcount then
                break
            end
            if value.level == nil then
                XToLevel.db.char.data.dungeonList[index].level = self.level
                value.level = self.level
            end
            if value.name == name and not value.inProgress and (self.level - value.level < 5) then
                total = total + value.totalXP
                count = count + 1
            end
        end
        if count == 0 then
            return 0
        else
            return XToLevel.Lib:round(total / count, 0)
        end
    else
        return 0
    end
end

---
-- Gets details for the last entry in the dungeon list.
-- @return A table matching the CreateDungeonDataArray template, or nil if
--         no battlegrounds have been recorded yet.
---
function XToLevel.Player:GetLatestDungeonDetails()
    if # XToLevel.db.char.data.dungeonList > 0 then
        self.latestDungeonData.totalXP = XToLevel.db.char.data.dungeonList[1].totalXP
        self.latestDungeonData.killCount = XToLevel.db.char.data.dungeonList[1].killCount
        self.latestDungeonData.xpPerKill = 0
        self.latestDungeonData.rested = XToLevel.db.char.data.dungeonList[1].rested
        self.latestDungeonData.otherXP = XToLevel.db.char.data.dungeonList[1].totalXP - XToLevel.db.char.data.dungeonList[1].killTotal          
        if self.latestDungeonData.killCount > 0 then
            self.latestDungeonData.xpPerKill = XToLevel.Lib:round(XToLevel.db.char.data.dungeonList[1].killTotal / self.latestDungeonData.killCount, 0)
        end

        return self.latestDungeonData
    else
        return nil
    end
end

---
-- Clears the kill list. If the initialValue parameter is passed, a single
-- entry with that value is added.
-- @param initalValue The inital value for the list. [optional]
function XToLevel.Player:ClearKills (initialValue)
    XToLevel.db.char.data.killList = { }
    XToLevel.db.char.data.npcXP = { }
    self.killAverage = nil;
    if initialValue ~= nil and tonumber(initialValue) > 0 then
        table.insert(XToLevel.db.char.data.killList, {mob='Initial', xp=tonumber(initialValue)})
    end
end

---
-- Clears the quest list. If the initialValue parameter is passed, a single
-- entry with that value is added.
-- @param initalValue The inital value for the list. [optional]
function XToLevel.Player:ClearQuests (initialValue)
    XToLevel.db.char.data.questList = { }
    self.questAverage = nil;
    if initialValue ~= nil and tonumber(initialValue) > 0 then
        table.insert(XToLevel.db.char.data.questList, tonumber(initialValue))
    end
end

---
-- Clears the pet battle list. If the initialValue parameter is passed, a single
-- entry with that value is added.
-- @param initalValue The inital value for the list. [optional]
function XToLevel.Player:ClearPetBattles (initialValue)
    XToLevel.db.char.data.petBattleList = { }
    self.petBattleAverage = nil;
    if initialValue ~= nil and tonumber(initialValue) > 0 then
        table.insert(XToLevel.db.char.data.petBattleList, tonumber(initialValue))
    end
end

---
-- Clears the BG list. If the initialValue parameter is passed, a single
-- entry with that value is added.
-- @param initalValue The inital value for the list. [optional]
function XToLevel.Player:ClearBattlegrounds(initialValue)
    XToLevel.db.char.data.bgList = { }
    self.bgAverage = nil;
    self.bgObjAverage = nil;
    if initialValue ~= nil and tonumber(initialValue) > 0 then
        table.insert(XToLevel.db.char.data.bgList, tonumber(initialValue))
    end
end

---
-- Clears the dungeon list. If the initialValue parameter is passed, a 
-- single entry with that value is added.
function XToLevel.Player:ClearDungeonList(initialValue)
    XToLevel.db.char.data.dungeonList = { }
    self.dungeonAverage = nil;

    local inInstance, type = IsInInstance()
    if inInstance and type == "party" then
        self:DungeonStart()
    end
end

---
-- Checks whether the player is rested.
-- @return The additional XP the player will get until he is unrested again
--         or FALSE if the player is not rested.
---
function XToLevel.Player:IsRested()
    if self.restedXP > 0 then
        return self.restedXP
    else
        return false
    end
end

---
-- Sets the number of kills used for average calculations
function XToLevel.Player:SetKillAverageLength(newValue)
    XToLevel.db.profile.averageDisplay.playerKillListLength = newValue
    self.killAverage = nil
    XToLevel.Average:Update()
    XToLevel.LDB:BuildPattern()
    XToLevel.LDB:Update()
end

---
-- Sets the number of quests used for average calculations
function XToLevel.Player:SetQuestAverageLength(newValue)
    XToLevel.db.profile.averageDisplay.playerQuestListLength = newValue
    self.questAverage = nil
    XToLevel.Average:Update()
    XToLevel.LDB:BuildPattern()
    XToLevel.LDB:Update()
end

---
-- Sets the number of pet battles used for average calculations
function XToLevel.Player:SetPetBattleAverageLength(newValue)
    XToLevel.db.profile.averageDisplay.playerPetBattleListLength = newValue
    self.petBattleAverage = nil
    XToLevel.Average:Update()
    XToLevel.LDB:BuildPattern()
    XToLevel.LDB:Update()
end

---
-- Sets the number of battleground used for average calculations
function XToLevel.Player:SetBattleAverageLength(newValue)
    XToLevel.db.profile.averageDisplay.playerBGListLength = newValue
    self.bgAverage = nil
    XToLevel.Average:Update()
    XToLevel.LDB:BuildPattern()
    XToLevel.LDB:Update()
end	

---
-- Sets the number of quest objectives used for average calculations
function XToLevel.Player:SetObjectiveAverageLength(newValue)
    XToLevel.db.profile.averageDisplay.playerBGOListLength = newValue
    self.bgObjAverage = nil
    XToLevel.Average:Update()
    XToLevel.LDB:BuildPattern()
    XToLevel.LDB:Update()
end

---
-- Sets the number of dungeon used for average calculations
function XToLevel.Player:SetDungeonAverageLength(newValue)
    XToLevel.db.profile.averageDisplay.playerDungeonListLength = newValue
    self.dungeonAverage = nil
    XToLevel.Average:Update()
    XToLevel.LDB:BuildPattern()
    XToLevel.LDB:Update()
end
