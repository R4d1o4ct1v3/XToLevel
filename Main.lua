---
-- The main application. Contains the event callbacks that control the flow of 
-- the application.
-- @file Main.lua
-- @release @project-version@
-- @copyright Atli Þór (atli.j@advefir.com)
---
--module "XToLevel" -- For documentation purposes. Do not uncomment!

--[[
Copyright (C) 2008-2010  Atli Þór <atli.j@advefir.com>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to use, copy, modify and/or merge
the Software, subject to the following conditions:

1) The Software, or any works derived from the Software, may not 
be published, distributed, sub-licensed, and/or sold under the original
title of the Software, or as the work of the Software's authors.

2) The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
--]]

rafMessageDisplayed = false; -- Temporary. Used for the RAF beta message.

-- Create the Main XToLevel object and the main frame (used to listen to events.)
XToLevel = { }
XToLevel.version = "@project-version@"
XToLevel.releaseDate = '@project-date-iso@'

XToLevel.frame = CreateFrame("FRAME", "XToLevel", UIParent)
XToLevel.frame:RegisterEvent("PLAYER_LOGIN")

XToLevel.timer = LibStub:GetLibrary("AceTimer-3.0")

--
-- Member variables
XToLevel.playerHasXpLossRequest = false
XToLevel.playerHasResurrectRequest = false
XToLevel.hasLfgProposalSucceeded = false
XToLevel.onUpdateTotal = 0

XToLevel.questCompleteDialogOpen = false;
XToLevel.questCompleteDialogLastOpen = 0

XToLevel.gatheringAction = nil;
XToLevel.gatheringTarget = nil;
XToLevel.gatheringTime = nil;

---
-- Temporary variables
local targetList = { }
local regenEnabled = true;

local targetUpdatePending = false; -- Used if the chat message is fired before the combat log, to update the target's XP value in the targetList

---
-- ON_EVENT handler. Set in the XToLevelDisplay XML file. Called for every event
-- and only used to attach the callback functions to their respective event.
function XToLevel:MainOnEvent(event, ...)
    if event == "PLAYER_LOGIN" then
        self:OnPlayerLogin()
    elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
        self:OnChatXPGain(select(1, ...))
    elseif event == "CHAT_MSG_OPENING" then
        self:OnChatMsgOpening(select(1, ...));
    elseif event == "PLAYER_LEVEL_UP" then
        self:OnPlayerLevelUp(select(1, ...))
    elseif event == "PLAYER_XP_UPDATE" then
        self:OnPlayerXPUpdate()
    elseif event == "UNIT_NAME_UPDATE" then
        self:OnUnitNameUpdate(select(1, ...))
    elseif event == "PLAYER_ENTERING_BATTLEGROUND" then
        self:OnPlayerEnteringBattleground()
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:OnPlayerEnteringWorld()
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED" then
        self:OnAreaChanged()
    elseif event == "PLAYER_UNGHOST" then
        self:OnPlayerUnghost()
    elseif event == "CONFIRM_XP_LOSS" then
        self:OnConfirmXpLoss();
    elseif event == "RESURRECT_REQUEST" then
        self:OnResurrectRequest();
    elseif event == "PLAYER_ALIVE" then
        self:OnPlayerAlive()
    elseif event == "LFG_PROPOSAL_SUCCEEDED" then
    	self:OnLfgProposalSucceeded()
	elseif event == "PLAYER_EQUIPMENT_CHANGED" then
		self:OnEquipmentChanged(select(1, ...), select(2, ...))
	elseif event == "TIME_PLAYED_MSG" then
		self:OnTimePlayedMsg(select(1, ...), select(2, ...))
    --elseif event == "GUILD_XP_UPDATE" or event == "PLAYER_GUILD_UPDATE" then
    --    self:OnGuildXpUpdate()
    elseif event == "QUEST_COMPLETE" then
        self:OnQuestComplete()
    elseif event == "QUEST_FINISHED" then
        self:OnQuestFinished()
    elseif event == "PLAYER_TARGET_CHANGED" then
        self:OnPlayerTargetChanged()
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        self:OnCombatLogEventUnfiltered(...)
    elseif event == "PLAYER_REGEN_ENABLED" then
        self:OnPlayerRegenEnabled()
    elseif event == "PLAYER_REGEN_DISABLED" then
        self:OnPlayerRegenDisabled()
    end
end
XToLevel.frame:SetScript("OnEvent", function(self, ...) XToLevel:MainOnEvent(...) end);

---
-- Registers events listeners and slash commands. Note, the callbacks for
-- the events are defined in the MainOnEvent function.
function XToLevel:RegisterEvents(level)
	if not level then
		level = UnitLevel("player")
	end

    -- Register Events
    if level < XToLevel.Player:GetMaxLevel() then
        --self.frame:RegisterAllEvents();
	    self.frame:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN");
        self.frame:RegisterEvent("CHAT_MSG_OPENING");
	    
	    self.frame:RegisterEvent("PLAYER_LEVEL_UP");
	    self.frame:RegisterEvent("PLAYER_XP_UPDATE");
	    self.frame:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND");
	    self.frame:RegisterEvent("PLAYER_ENTERING_WORLD");
	    self.frame:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL");
	    
	    self.frame:RegisterEvent("ZONE_CHANGED_INDOORS");
	    self.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA");
	    self.frame:RegisterEvent("ZONE_CHANGED");
	    
	    self.frame:RegisterEvent("PLAYER_UNGHOST");
	    self.frame:RegisterEvent("CONFIRM_XP_LOSS");
	    self.frame:RegisterEvent("CANCEL_SUMMON");
	    self.frame:RegisterEvent("RESURRECT_REQUEST");
	    self.frame:RegisterEvent("CONFIRM_SUMMON");
	    self.frame:RegisterEvent("PLAYER_ALIVE");
	    self.frame:RegisterEvent("LFG_PROPOSAL_SUCCEEDED")
		self.frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
		
		self.frame:RegisterEvent("TIME_PLAYED_MSG")
        
        --self.frame:RegisterEvent("GUILD_XP_UPDATE")
        --self.frame:RegisterEvent("PLAYER_GUILD_UPDATE")
        
        self.frame:RegisterEvent("QUEST_FINISHED")
        self.frame:RegisterEvent("QUEST_COMPLETE")
        
        self.frame:RegisterEvent("PLAYER_TARGET_CHANGED")
        self.frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        self.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    end
    
    -- Register slash commands
    SLASH_XTOLEVEL1 = "/xtolevel";
    SLASH_XTOLEVEL2 = "/xtl";
    SlashCmdList["XTOLEVEL"] = function(arg1) XToLevel:OnSlashCommand(arg1) end
end

---
-- Clears all registered events from the addon.
function XToLevel:UnregisterEvents()
	self.frame:UnregisterEvent("CHAT_MSG_COMBAT_XP_GAIN");
    self.frame:UnregisterEvent("CHAT_MSG_SYSTEM");

    self.frame:UnregisterEvent("PLAYER_LEVEL_UP");
    self.frame:UnregisterEvent("PLAYER_XP_UPDATE");
    self.frame:UnregisterEvent("PLAYER_ENTERING_BATTLEGROUND");
    self.frame:UnregisterEvent("PLAYER_ENTERING_WORLD");
    self.frame:UnregisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL");
    
    self.frame:UnregisterEvent("ZONE_CHANGED_INDOORS");
    self.frame:UnregisterEvent("ZONE_CHANGED_NEW_AREA");
    self.frame:UnregisterEvent("ZONE_CHANGED");
    
    self.frame:UnregisterEvent("PLAYER_UNGHOST");
    self.frame:UnregisterEvent("CONFIRM_XP_LOSS");
    self.frame:UnregisterEvent("CANCEL_SUMMON");
    self.frame:UnregisterEvent("RESURRECT_REQUEST");
    self.frame:UnregisterEvent("CONFIRM_SUMMON");
    self.frame:UnregisterEvent("PLAYER_ALIVE");
    self.frame:UnregisterEvent("LFG_PROPOSAL_SUCCEEDED")
	self.frame:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
	
	self.frame:UnregisterEvent("TIME_PLAYED_MSG")
    
    --self.frame:UnregisterEvent("GUILD_XP_UPDATE")
    --self.frame:UnregisterEvent("PLAYER_GUILD_UPDATE")
    
    self.frame:UnregisterEvent("PLAYER_TARGET_CHANGED")
    self.frame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self.frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
    self.frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
end

--- PLAYER_LOGIN callback. Initializes the config, locale and c Objects.
function XToLevel:OnPlayerLogin()
    -- If the player is at max level, and not a hunter, then there is no reason
    -- to load the addon.
    if UnitLevel("player") >= XToLevel.Player:GetMaxLevel() and XToLevel.Player:GetClass() ~= "HUNTER" then
        XToLevel:Unload()
        return false;
    end

    self:RegisterEvents()
    XToLevel.Config:Verify()
    
    L = LOCALE[sConfig.general.displayLocale]
    if L == nil then
        console:log("Attempted to load unknow locale '" .. tostring(sConfig.general.displayLocale) .."'. Falling back on 'enUS'.")
        L = LOCALE["enUS"]
        sConfig.general.displayLocale = "enUS"
        if L == nil then
            XToLevel.Messages:Print("|cFFaaaaaaXToLevel - |r|cFFFF5533Fatal error:|r Locale files not found. (Try re-installing the addon.)")
            return;
        end
    end
    LOCALE = nil -- Removing the extra locale tables. They'r just a waste of memory.
    
    XToLevel.Player:Initialize(sData.player.killAverage, sData.player.questAverage)
    XToLevel.Config:Initialize()
    
    -- Register the played message to be executed after 2 seconds
    if UnitLevel("player") < XToLevel.Player:GetMaxLevel() then
        self.timer:ScheduleTimer(XToLevel.TimePlayedTriggerCallback, 2)
    end
    
    XToLevel.LDB:Initialize()
    XToLevel.Average:Initialize()
	XToLevel.Tooltip:Initialize()
end

--- Disables the addon for this session. Basically, this hides all frames and
-- wipes the XToLevel table.
function XToLevel:Unload()
    for name, ref in pairs(self.AverageFrameAPI) do
        ref:Hide();
    end
    table.wipe(XToLevel)
end

--------------------------------------------------------------------------------
-- PLAYER XP stuff
--------------------------------------------------------------------------------

---
-- Used to keep track of the player's targets while in combat. Once they die,
-- the chat and combat log events can then be used to match the targets and the
-- data stored and used to calculate the kills needed to level. - This is needed
-- because none of those messages pass along the level of a mob, but the GUIDs
-- are the same so I can record the levels here and match them in those events.
function XToLevel:OnPlayerTargetChanged()
    if not regenEnabled then
        local target_guid = UnitGUID("target")
        if target_guid ~= nil then
            local target_name = UnitName("target")
            local target_level = UnitLevel("target")
            local target_classification = UnitClassification("target")
            local exists = false
            
            -- Look for an existing entry and updated it if it does.
            for i, data in ipairs(targetList) do
                if data.guid == target_guid then
                    exists = true
                    targetList[i].name = target_name
                    targetList[i].level = target_level
                    targetList[i].classification = target_classification
                end
            end
            
            -- Add the target if it doesn't exist.
            if not exists then
                table.insert(targetList, {
                    guid = target_guid,
                    name = target_name,
                    level = target_level,
                    classification = target_classification,
                    dead = false,
                    xp = nil
                });
            end
        end
    end
end

---
-- Look for the combat log event that tells of a NPC death. 
function XToLevel:OnCombatLogEventUnfiltered(...)
    local cl_event = select(2, ...)
    local npc_guid = select(7, ...)
    -- 4.2 compatibility fix. (In case I miss the patch week again.)
    if tonumber(select(4, GetBuildInfo())) >= 40200 then
        npc_guid = select(8, ...)
    end
    if cl_event ~= nil and npc_guid ~= nil and cl_event == "UNIT_DIED" then
        for i, data in ipairs(targetList) do
            if data.guid == npc_guid then
                data.dead = true
                if type(targetUpdatePending) == "number" and targetUpdatePending > 0 then
                    data.xp = targetUpdatePending;
                    targetUpdatePending = nil;
                    XToLevel:AddMobXpRecord(data.name, data.level, UnitLevel("player"), data.xp, data.classification)
                end
            end
        end
    end
end

function XToLevel:OnPlayerRegenDisabled()
    regenEnabled = false;
    self:OnPlayerTargetChanged() -- So if a target is already targetted, it will not be overlooked.
end

--- Reset the target list. No point keeping a list of targets out of combat.
function XToLevel:OnPlayerRegenEnabled()
    regenEnabled = true;
    table.wipe(targetList)
end

---
-- Adds the mob to the permenant list of known NPCs and their XP value.
-- Used to calculate the Kills To Level values for the tooltip.
function XToLevel:AddMobXpRecord(mobName, mobLevel, playerLevel, xp, mobClassification)
    -- Validate the mob classification. Default to normal if none is given
    if type(mobClassification) ~= "string" then
        mobClassification = "normal"
    end
    local mobClassIndex = XToLevel.Lib:ConvertClassification(mobClassification)
    if mobClassIndex == nil then
        console:log("AddMobXpRecord: Invalid mobClassification passed. Defaulting to 'normal'. ('" .. tostring(mobClassification) .."')")
        mobClassIndex = 1
    end
    
    -- Make sure the tables exist
    if type(sData.player.npcXP) ~= "table" then
        sData.player.npcXP = { }
    end
    if sData.player.npcXP[playerLevel] == nil then
        sData.player.npcXP[playerLevel] = { }
    end
    if sData.player.npcXP[playerLevel][mobLevel] == nil then
        sData.player.npcXP[playerLevel][mobLevel] = { }
    end
    if sData.player.npcXP[playerLevel][mobLevel][mobClassIndex] == nil then
        sData.player.npcXP[playerLevel][mobLevel][mobClassIndex] = { }
    end
    
    -- Add the data
    local alreadyRecorded = false
    if # sData.player.npcXP[playerLevel][mobLevel][mobClassIndex] > 0 then
        for i, v in ipairs(sData.player.npcXP[playerLevel][mobLevel][mobClassIndex]) do
            if v == xp then
                alreadyRecorded = true
            end
        end
    end
    
    if not alreadyRecorded then
        table.insert(sData.player.npcXP[playerLevel][mobLevel][mobClassIndex], xp)
    end
end

--- Fires when the player's equipment changes
-- @param slot The number of the slot that changed.
-- @param hasItem Whether or not the slot is filled.
function XToLevel:OnEquipmentChanged(slot, hasItem)
	table.wipe(XToLevel.Tooltip.OnShow_XpData)
end

---
-- PLAYER_LEVEL_UP callback. Displays the level up messages, updates the player,
-- and updates the average and LDB displays.
-- @param newLevel The new level of the player. Passed from the event parameters.
function XToLevel:OnPlayerLevelUp(newLevel)
    console:log("New level reaced: " .. tostring(newLevel) .. " / " .. tostring(XToLevel.Player:GetMaxLevel()))
    
	XToLevel.Player.level = newLevel
	XToLevel.Player.timePlayedLevel = 0
	XToLevel.Player.timePlayedUpdated = time()
	
	if newLevel >= XToLevel.Player:GetMaxLevel() then
        XToLevel.Player.isActive = false
        XToLevel:UnregisterEvents()
        XToLevel:RegisterEvents(newLevel)
	end
    
	XToLevel.Average:Update()
    XToLevel.LDB:BuildPattern();
	XToLevel.LDB:Update();
end

--- Used to handle Gathering profession XP gains. This stores the info so the
-- CHAT_MSG_COMBAT_XP_GAIN can direct the XP gain in the right direction.
-- 
function XToLevel:OnChatMsgOpening(message)
    local regexp = string.gsub(OPEN_LOCK_SELF, "%%%d?%$?s", "(.+)")
    local action, target = strmatch(message, regexp)
    
    XToLevel.gatheringAction = action;
    XToLevel.gatheringTarget = target;
    XToLevel.gatheringTime = GetTime();
end

--- CHAT_XP_GAIN callback. Triggered whenever a XP message is displayed in the chat 
-- window, indicating that the player has gained XP (both kill, quest and BG objectives).
-- Parses the message and updates the XToLevel.Player and XToLevel.Display objects according 
-- to the type of message received.
-- @param message The message string passed by the event, as displayed in the chat window.
function XToLevel:OnChatXPGain(message)
    -- If the quest dialog was open in the last 2 seconds, assume this is a quest reward.
    local isQuest = self.questCompleteDialogOpen or (GetTime() - self.questCompleteDialogLastOpen) < 2
    local xp, mobName = XToLevel.Lib:ParseChatXPMessage(message, isQuest)
    xp = tonumber(xp)
	if not xp then
		console:log("Failed to parse XP Gain message: '" .. tostring(message) .. "'")
		return false
	end
	
	-- Update the timer total
	if sConfig.timer.enabled then
		-- TODO: Figure out a way to work rested kills into the timer without breaking everything!
		--local unrestedXP = XToLevel.Player:GetUnrestedXP(xp)
		sData.player.timer.total = sData.player.timer.total + xp
	end
    
    -- See if it is a kill or a quest (no mob name means it is a quest or BG objective.)
    if mobName ~= nil then
		if XToLevel.Player:IsBattlegroundInProgress() then
			console:log("Battleground Kill detected: " .. tostring(xp) .. "(" .. mobName ..")")
			XToLevel.Player:AddBattlegroundKill(xp, mobName)
		else
			local unrestedXP = XToLevel.Player:AddKill(xp, mobName)
            
            -- Update the temporary target list.
            local found = false;
            for i, data in ipairs(targetList) do
                if data.name == mobName and data.dead and data.xp == nil then
                    targetList[i].xp = unrestedXP
                    found = true
                    XToLevel:AddMobXpRecord(data.name, data.level, UnitLevel("player"), data.xp, data.classification)
                end
            end
            if not found then
                targetUpdatePending = unrestedXP;
            end
            
			-- sConfig.messages.bgObjectives ???
			if sConfig.messages.playerFloating or sConfig.messages.playerChat then
				local killsRequired = XToLevel.Player:GetKillsRequired(unrestedXP)
				if killsRequired > 0 then
					XToLevel.Messages.Floating:PrintKill(mobName, ceil(killsRequired / ( (XToLevel.Lib:IsRafApplied() and 3) or 1 )))
					XToLevel.Messages.Chat:PrintKill(mobName, killsRequired)
				end
			end
			
			if XToLevel.Player:IsDungeonInProgress() then
	            console:log("Dungeon Kill detected: " .. tostring(unrestedXP) .. "(" .. mobName ..")")
	            XToLevel.Player:AddDungeonKill(unrestedXP, mobName, (xp - unrestedXP))
            end
		end
    else
		if XToLevel.Player:IsBattlegroundInProgress() then
			console:log("Objective XP gained! : " .. tostring(xp))
			local isObj = XToLevel.Player:AddBattlegroundObjective(xp)
			if isObj and XToLevel.Player.isActive then
				local objectivesRequired = XToLevel.Player:GetQuestsRequired(xp)
				if objectivesRequired > 0 then
					XToLevel.Messages.Floating:PrintBGObjective(objectivesRequired)
					XToLevel.Messages.Chat:PrintBGObjective(objectivesRequired)
				end
			end
		else
            -- Only register as a quest if the quest complete dialog is open.
            -- (Note, I have not tested the effects of latency on the order of the
            --  events, so there *may* be a problem in high latency situations.)
            if isQuest then
                XToLevel.Player:AddQuest(xp)
                if sConfig.messages.playerFloating or sConfig.messages.playerChat then
                    local questsRequired = XToLevel.Player:GetQuestsRequired(xp)
                    if questsRequired > 0 then
                        XToLevel.Messages.Floating:PrintQuest( ceil(questsRequired / ( (XToLevel.Lib:IsRafApplied() and 3) or 1 )) )
                        XToLevel.Messages.Chat:PrintQuest(questsRequired)
                    end
                end
            else
                if XToLevel.gatheringTarget ~= nil and XToLevel.gatheringTime ~= nil and GetTime() - XToLevel.gatheringTime < 5 then
                    XToLevel.Player:AddGathering(XToLevel.gatheringAction, XToLevel.gatheringTarget, xp);
                    local remaining = XToLevel.Player:GetQuestsRequired(xp)
                    if type(remaining) == "number" and remaining > 0 then
                        XToLevel.Messages.Floating:PrintKill(XToLevel.gatheringTarget, remaining)
                        XToLevel.Messages.Chat:PrintKill(XToLevel.gatheringTarget, remaining)
                    end
                    XToLevel.gatheringTarget = nil;
                    XToLevel.gatheringAction = nil;
                    XToLevel.gatheringTime = nil;
                else
                    -- This estimate is made before the XP is updated, so -1 to compensate.
                    local remaining = XToLevel.Player:GetQuestsRequired(xp) - 1
                    if type(remaining) == "number" and remaining > 0 then
                        XToLevel.Messages.Floating:PrintAnonymous(remaining)
                        XToLevel.Messages.Chat:PrintAnonymous(remaining)
                    end
                end
            end
		end
    end
end

--- Callback for the QUEST_COMPLETE event.
-- Note that this is NOT fired when a quest is completed, but rather when the
-- player is given the last dialog to complete a quest. This event firing does
-- not mean a quest has been completed! 
function XToLevel:OnQuestComplete()
    self.questCompleteDialogOpen = true;
end

--- Callback for the QUEST_FINISHED event.
-- This event is called when ANY quest related dialog is closed. It does NOT mean
-- a quest has been completed.
function XToLevel:OnQuestFinished()
    self.questCompleteDialogOpen = false;
    self.questCompleteDialogLastOpen = GetTime();
end

--- PLAYER_XP_UPDATE callback. Triggered when the player's XP changes.
-- Syncronizes the XP of the XToLevel.Player object and updates the average and ldb 
-- displays. Also updates the sData.player values with the current once.
function XToLevel:OnPlayerXPUpdate()
    XToLevel.Player:SyncData()
    XToLevel.Average:Update()
    XToLevel.LDB:BuildPattern();
	XToLevel.LDB:Update()
    
    sData.player.killAverage = XToLevel.Player:GetAverageKillXP()
    sData.player.questAverage = XToLevel.Player:GetAverageQuestXP()
end

--------------------------------------------------------------------------------
-- GUILD XP stuff - NOT YET IMPLEMENTED
--------------------------------------------------------------------------------

---
-- Handles GUILD_XP_UPDATE
function XToLevel:OnGuildXpUpdate()
    console:log('Guild Update');
    XToLevel.Player:SyncGuildData();
    if XToLevel.Player.guildXP ~= nil then
        XToLevel.Average:Update()
        XToLevel.LDB:Update()
    end
end

--------------------------------------------------------------------------------
-- BATTLEGROUND and INSTANCE stuff
--------------------------------------------------------------------------------

--- PLAYER_ENTERING_BATTLEGROUND callback.
function XToLevel:OnPlayerEnteringBattleground()
	if XToLevel.Player.isActive then
		XToLevel.Player:BattlegroundStart(false)
	else
		console:log("Entered BG. Player counter inactive. Count cancelled.")
	end
end

--- LFG_PROPOSAL_SUCCEEDED callback.
-- Called when all members of a PUG, assembled via the LFG system, have accepted
-- the invite. (Used here to detect whether a player is entering a dungeon
-- whiles inside another one.)
function XToLevel:OnLfgProposalSucceeded()
	self.hasLfgProposalSucceeded = true
end

--- PLAYER_LEAVING_Instance callback.
function XToLevel:PlayerLeavingInstance(force)
    if force == true or (XToLevel.Player:IsDungeonInProgress() and (UnitIsDeadOrGhost("player") == nil)) then
        local zoneName = GetRealZoneText()
        local success = XToLevel.Player:DungeonEnd(zoneName)
        
        if success and XToLevel.Player.isActive then
            local remaining = XToLevel.Player.maxXP - XToLevel.Player.currentXP;
            local lastTotalXP = sData.player.dungeonList[1].totalXP
            local dungeonsRemaning = XToLevel.Player:GetKillsRequired(lastTotalXP)
            
            if dungeonsRemaning > 0 then
                local name = sData.player.dungeonList[1].name
                XToLevel.Messages.Floating:PrintDungeon(dungeonsRemaning)
	            XToLevel.Messages.Chat:PrintDungeon(dungeonsRemaning)
	            XToLevel.Average:Update()
	            XToLevel.LDB:BuildPattern();
	            XToLevel.LDB:Update()
            end
        end
    else
        console:log("PlayerLeavingInstance cancelled.")    
    end
end

--- PLAYER_ENTERING_WORLD callback. Triggered whenever a loading screen completes.
-- Determines whether the player has left an battleground (a loading screen is
-- only shown in a BG when leaving) and closes the XToLevel.Player bg instance, printing
-- the "bgs required" message. It also checks if the player has entered or
-- left an instance and calls the appropriate functions.
function XToLevel:OnPlayerEnteringWorld()
	if self.hasLfgProposalSucceeded then
		local inInstance, type = IsInInstance()
		if XToLevel.Player:IsDungeonInProgress() and inInstance and type == "party" then
            self:PlayerLeavingInstance()
            XToLevel.Player:DungeonStart()
		end
		self.hasLfgProposalSucceeded = false
	end
    if GetRealZoneText() ~= "" then
	    -- GetRealZoneText is set to an empty string the first time this even fires,
	    -- making IsInBattleground return a false negative when actually in bg.
		if XToLevel.Player:IsBattlegroundInProgress() and not XToLevel.Lib:IsInBattleground() then
			if XToLevel.Player.isActive then
				local bgsRequired = XToLevel.Player:GetQuestsRequired(sData.player.bgList[1].totalXP)
				XToLevel.Player:BattlegroundEnd()
				XToLevel.Average:Update()
		        XToLevel.LDB:BuildPattern();
				XToLevel.LDB:Update()
				if bgsRequired > 0 then
					XToLevel.Messages.Floating:PrintBattleground(bgsRequired)
					XToLevel.Messages.Chat:PrintBattleground(bgsRequired)
				end
			end
		else
			local inInstance, type = IsInInstance()
			if not XToLevel.Player:IsDungeonInProgress() and inInstance and type == "party" then
	            XToLevel.Player:DungeonStart()
			elseif not inInstance and XToLevel.Player:IsDungeonInProgress() then
	            self:PlayerLeavingInstance()
			end
		end
	end
end

--- PLAYER_UNGHOST callback. Called when the a player returns from ghost mode.
-- Determines whether the player returned to life ouside of an instance after
-- dying inside an instance. Note that when resurected by another player inside
-- the instance, after releasing, the player momentarily comes back to life
-- outside the instance, which would cause the instance to be closed.
-- To avoid that, I only close the instance if a player has asked for a spirit 
-- heal and no resurection requests have been detected. 
function XToLevel:OnPlayerUnghost()
    if self.playerHasXpLossRequest and not self.playerHasResurrectRequest then
        if XToLevel.Player:IsDungeonInProgress() then
            self:PlayerLeavingInstance(true)
        else
            console:log("Spirit heal without being inside an instance. Action cancelled.");
        end
        self.playerHasXpLossRequest = false;
    end
end

--- CONFIRM_XP_LOSS callback. Triggered when a spirit healer dialog is opened.
-- Note that does NOT mean a spirit heal has been accepted, only the dialog showed.
function XToLevel:OnConfirmXpLoss()
    self.playerHasXpLossRequest = true;
end

--- RESURECT_REQUEST callback. Triggered when a player resurection dialog is opened.
function XToLevel:OnResurrectRequest()
    self.playerHasResurrectRequest = true;
end

--- PLAYER_ALIVE callback. Triggered on spirit realease, or after aceppting resurection
-- before releasing. It also fires after entering or leaving an instance.
-- (Possibly even after every load screen, but I haven't confirmed that.)
function XToLevel:OnPlayerAlive()
    self.playerHasXpLossRequest = false
    self.playerHasResurrectRequest = false
end

--- callback for ZONE_CHANGED_NEW_AREA, ZONE_CHANGED_INDOORS and ZONE_CHANGED.
-- Basically fired everytime the player moves into a new area, sub-area or the
-- indoor/outdoor status changes.
-- Determines whether the zone name of the BG in progres needs to be set, and if
-- not it checks if the name of the BG matches the zone. If not the player has
-- left the BG are and the BG in progress is stopped.
function XToLevel:OnAreaChanged()
	if XToLevel.Player:IsBattlegroundInProgress() and XToLevel.Player.isActive then
		local oldZone = sData.player.bgList[1].name
		local newZone = GetRealZoneText()
		if oldZone == false then
			sData.player.bgList[1].name = newZone
			console:log(" - BG name set. ")
		else
            if oldZone ~= newZone then
			    console:log(" - BG names don't match (" .. oldZone .." vs " .. newZone ..").")
                local bgsRequired = XToLevel.Player:GetQuestsRequired(sData.player.bgList[1].totalXP)
                XToLevel.Player:BattlegroundEnd()
                XToLevel.Average:Update()
                XToLevel.LDB:BuildPattern();
                XToLevel.LDB:Update()
                if bgsRequired > 0 then
                    XToLevel.Messages.Floating:PrintBattleground(bgsRequired)
                    XToLevel.Messages.Chat:PrintBattleground(bgsRequired)
                end
                if XToLevel.Lib:IsInBattleground() then
                    console:log(" - Player switched battlegrounds. Starting new.")
					XToLevel.Player:BattlegroundStart()
                else
                    console:log(" - Player not in a battleground. Ending")
                end
			end
		end
	end
end

--------------------------------------------------------------------------------
-- TIMER stuff
--------------------------------------------------------------------------------

--- Passes the time played info into the Player object.
function XToLevel:OnTimePlayedMsg(total, level)
    -- Possible that the argument order gets mixed up?
    -- (See bug #7)
    if total < level then
       local tmp = level
       level = total
       total = tmp
    end
    
	XToLevel.Player:UpdateTimePlayed(total, level)
end

--- Called to trigger an update of the time played. Causes the time to be flushed into the chat,
-- triggering the TIME_PLAYED_MSG event, from which the info can be retrieved.
function XToLevel:TimePlayedTriggerCallback()
	if XToLevel.Player.timePlayedTotal == nil or XToLevel.Player.timePlayedLevel == nil then
		RequestTimePlayed()
	end
end

--------------------------------------------------------------------------------
-- SLASH command stuff
--------------------------------------------------------------------------------

--- Callback for the /xtl and /xtolevel slash commands.
-- Without parametes, it simply opens the configuration dialog.
-- Various commands may exist for debuggin purposes, but none are essential to
-- the application.
function XToLevel:OnSlashCommand(arg1)
	if arg1 == "clear kills" then
		XToLevel.Player:ClearKillList()
		XToLevel.Player.killAverage = nil
		XToLevel.Messages:Print("Player kill records cleared.")
		XToLevel.Average:Update()
        XToLevel.LDB:BuildPattern();
		XToLevel.LDB:Update()
	elseif arg1 == "clear quests" then
		XToLevel.Player:ClearQuestList()
		XToLevel.Player.questAverage = nil
		XToLevel.Messages:Print("Player quests records cleared.")
		XToLevel.Average:Update()
        XToLevel.LDB:BuildPattern();
		XToLevel.LDB:Update()
	elseif arg1 == "clear bg" then
		XToLevel.Player:ClearBattlegroundList()
		XToLevel.Player.bgAverage = nil
		XToLevel.Player.bgObjAverage = nil
		XToLevel.Messages:Print("Player battleground records cleared.")
		XToLevel.Average:Update()
        XToLevel.LDB:BuildPattern();
		XToLevel.LDB:Update()
	elseif arg1 == "clear dungeons" then
        XToLevel.Player:ClearDungeonList()
        XToLevel.Messages:Print("Player dungeon records cleared.")
        XToLevel.Average:Update()
        XToLevel.LDB:BuildPattern();
        XToLevel.LDB:Update()
	elseif arg1 == "dlist" then
        console:log("-- Dungeon list--")
        for index, data in ipairs(sData.player.dungeonList) do
            console:log("#" .. tostring(index))
            console:log("  inProgress: ".. tostring(data.inProgress))
            console:log("  name: ".. tostring(data.name))
            console:log("  level: ".. tostring(data.level))
            console:log("  totalXP: ".. tostring(data.totalXP))
            console:log("  rested: ".. tostring(data.rested))
            console:log("  killCount: ".. tostring(data.killCount))
            console:log("  killTotal: ".. tostring(data.killTotal))
        end
    elseif arg1 == "blist" then
        console:log("-- BG list--")
        for index, data in ipairs(sData.player.bgList) do
            console:log("#" .. tostring(index))
            console:log("  inProgress: ".. tostring(data.inProgress))
            console:log("  name: ".. tostring(data.name))
            console:log("  level: ".. tostring(data.level))
            console:log("  totalXP: ".. tostring(data.totalXP))
            console:log("  killCount: ".. tostring(data.killCount))
            console:log("  killTotal: ".. tostring(data.killTotal))
        end
    elseif arg1 == "glist" then
		for action, actionTable in pairs(sData.player.gathering) do
            console:log("-- " .. tostring(action) .. " -- ")
            for i, row in pairs(actionTable) do
                console:log(" " .. tostring(row["target"]) .. ", l:" .. tostring(row["level"]) .. ", xp:" .. tostring(row["xp"]) .. ", z:" .. tostring(row["zoneID"]) .. ", x" .. tostring(row["count"]));
            end
        end
    elseif arg1 == "debug" then
        if type(sData.player.npcXP) == "table" then
            for playerLevel, playerData in pairs(sData.player.npcXP) do
                console:log(playerLevel .. ": ");
                for mobLevel, mobData in pairs(playerData) do
                    console:log("  " .. mobLevel .. ": ")
                    for classification, xpData in pairs(mobData) do
                        console:log("    " .. classification .. ": ")
                        for __, xp in ipairs(xpData) do
                            console:log("      " .. xp);
                        end
                    end
                end
            end
        else
            console:log("No mob data")
        end
	else
		XToLevel.Config:Open("messages")
	end
end
