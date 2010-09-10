---
-- The main application. Contains the event callbacks that control the flow of 
-- the application.
-- @file Main.lua
-- @release 3.3.3_14r
-- @copyright Atli Þór (atli@advefir.com)
---
--module "XToLevel" -- For documentation purposes. Do not uncomment!

--[[
Copyright (C) 2008-2010  Atli Þór <atli@advefir.com>

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
XToLevel.frame = CreateFrame("FRAME", "XToLevel", UIParent)
XToLevel.frame:RegisterEvent("PLAYER_LOGIN")

XToLevel.timer = LibStub:GetLibrary("AceTimer-3.0")

--
-- Member variables
XToLevel.playerHasXpLossRequest = false
XToLevel.playerHasResurrectRequest = false
XToLevel.hasLfgProposalSucceeded = false
XToLevel.onUpdateTotal = 0

---
-- ON_EVENT handler. Set in the XToLevelDisplay XML file. Called for every event
-- and only used to attach the callback functions to their respective event.
---
function XToLevel:MainOnEvent()
    if event == "PLAYER_LOGIN" then
        self:OnPlayerLogin()
    elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
        self:OnChatXPGain(arg1)
    elseif event == "PLAYER_LEVEL_UP" then
        self:OnPlayerLevelUp(arg1)
    elseif event == "PLAYER_XP_UPDATE" then
        self:OnPlayerXPUpdate()
    elseif (event == "UNIT_PET") then
        self:OnUnitPet(arg1)
    elseif event == "UNIT_PET_EXPERIENCE" then
        self:OnUnitPetExperience();
    elseif event == "PET_UI_UPDATE" then
        self:OnPetUiUpdate()
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
		self:OnEquipmentChanged(arg1, arg2)
	elseif event == "TIME_PLAYED_MSG" then
		self:OnTimePlayedMsg(arg1, arg2)
    end
end
XToLevel.frame:SetScript("OnEvent", function() XToLevel:MainOnEvent(event) end);

---
-- Registers events listeners and slash commands. Note, the callbacks for
-- the events are defined in the MainOnEvent function.
---
function XToLevel:RegisterEvents(level)
	if not level then
		level = UnitLevel("player")
	end

    -- Register Events
    if level < XToLevel.Player:GetMaxLevel() then
	    self.frame:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN");
	    
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
    end
   	if XToLevel.Player:GetClass() == "HUNTER" then
	    self.frame:RegisterEvent("UNIT_PET");
	    self.frame:RegisterEvent("UNIT_PET_EXPERIENCE");
	    self.frame:RegisterEvent("PET_UI_UPDATE");
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
	
    self.frame:UnregisterEvent("UNIT_PET");
    self.frame:UnregisterEvent("UNIT_PET_EXPERIENCE");
    self.frame:UnregisterEvent("PET_UI_UPDATE");
	
	self.frame:UnregisterEvent("TIME_PLAYED_MSG")
end

---
-- PLAYER_LOGIN callback. Initializes the config, locale and c Objects.
---
function XToLevel:OnPlayerLogin()
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
    XToLevel.Pet:Initialize(sData.pet.killAverage)
    XToLevel.Config:Initialize()
    
    -- Register the played message to be executed after 2 seconds
    if UnitLevel("player") < XToLevel.Player:GetMaxLevel() then
        self.timer:ScheduleTimer(XToLevel.TimePlayedTriggerCallback, 2)
    else
        sConfig.timer.enabled = false
    end
    
    XToLevel.LDB:Initialize()
    XToLevel.Average:Initialize()
	XToLevel.Tooltip:Initialize()
end

---
-- Fires when the player's equipment changes
-- @param slot The number of the slot that changed.
-- @param hasItem Whether or not the slot is filled.
function XToLevel:OnEquipmentChanged(slot, hasItem)
	table.wipe(XToLevel.Tooltip.OnShow_XpData)
end

---
-- PLAYER_LEVEL_UP callback. Displays the level up messages, updates the player and pet objects,
-- and updates the average and LDB displays.
-- @param newLevel The new level of the player. Passed from the event parameters.
---
function XToLevel:OnPlayerLevelUp(newLevel)
    XToLevel.Messages.Floating:PrintLevel(newLevel)
    XToLevel.Messages.Chat:PrintLevel(newLevel)
	
	XToLevel.Player.level = newLevel
	XToLevel.Player.timePlayedLevel = 0
	XToLevel.Player.timePlayedUpdated = time()
	
	XToLevel.Pet:Update()
	XToLevel.Average:Update()
    XToLevel.LDB:BuildPattern();
	XToLevel.LDB:Update();
	
	if newLevel >= XToLevel.Player:GetMaxLevel() then
		XToLevel:UnregisterEvents()
		XToLevel:RegisterEvents(newLevel)
	end
end

---
-- CHAT_XP_GAIN callback. Triggered whenever a message is displayed in the chat 
-- window, indicating that the player has gained XP (both kill, quest and BG objectives).
-- Parses the message and updates the XToLevel.Player, XToLevel.Pet and XToLevel.Display objects according 
-- to the type of message received.
-- @param message The message string passed by the event, as displayed in the chat window.
---
function XToLevel:OnChatXPGain(message)
    -- Note that this event is fired by kills, quests and BG objectives.
    local xp, mobName = XToLevel.Lib:ParseChatXPMessage(message)
    xp = tonumber(xp)
	
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
			
			-- sConfig.messages.bgObjectives ???
			if sConfig.messages.playerFloating or sConfig.messages.playerChat then
				local killsRequired = XToLevel.Player:GetKillsRequired(unrestedXP)
				if killsRequired > 0 then
					XToLevel.Messages.Floating:PrintKill(mobName, ceil(killsRequired / ( (XToLevel.Lib:IsRafApplied() and 3) or 1 )))
					XToLevel.Messages.Chat:PrintKill(mobName, killsRequired)
					XToLevel.Pet.nextMobName = mobName -- Sets the next mob to be displayed for the pet message.
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
			XToLevel.Player:AddQuest(xp)
			if sConfig.messages.playerFloating or sConfig.messages.playerChat then
				local questsRequired = XToLevel.Player:GetQuestsRequired(xp)
				if questsRequired > 0 then
					XToLevel.Messages.Floating:PrintQuest( ceil(questsRequired / ( (XToLevel.Lib:IsRafApplied() and 3) or 1 )) )
					XToLevel.Messages.Chat:PrintQuest(questsRequired)
				end
			end
		end
    end
end

--- PLAYER_XP_UPDATE callback. Triggered when the player's XP changes.
-- Syncronizes the XP of the XToLevel.Player object and updates the average and ldb 
-- displays. Also updates the sData.player values with the current once.
---
function XToLevel:OnPlayerXPUpdate()
    XToLevel.Player:SyncData()
    XToLevel.Average:Update()
    XToLevel.LDB:BuildPattern();
	XToLevel.LDB:Update()
    
    sData.player.killAverage = XToLevel.Player:GetAverageKillXP()
    sData.player.questAverage = XToLevel.Player:GetAverageQuestXP()
end

---
-- UNIT_PET callback. Triggered when the player pet changes.
-- If the type indicates this is a player pet (read: hunter pet), initalizes the
-- XToLevel.Pet object and updates the displays.
-- @param type The type of pet this is, as passed by the event.
---
function XToLevel:OnUnitPet(type)
    -- Note, it appears this event is now fired before the PLAYER_LOGIN event
    -- so the player won't be initialized the first time it is fired. (regression bugs wtf!)
	if type == "player" and XToLevel.Player.level ~= nil then
		XToLevel.Pet:Initialize()
		XToLevel.Average:Update()
        XToLevel.LDB:BuildPattern();
		XToLevel.LDB:Update()
	end
end

---
-- UNIT_PET_EXPERIENCE callback. Triggered when the pet's XP changes.
-- Calculates the change and displays a message based on that. If the change is 
-- positive it displays a "kills needed" message, if it is negative it displays
-- a "gained level" message. Note that the "kills needed" message attempts to 
-- use the nextMobName attribute (via the GetName method) which is set to the
-- last mob name the player recorded.
---
function XToLevel:OnUnitPetExperience()
	if not XToLevel.Player:IsBattlegroundInProgress() and XToLevel.Pet.isActive then
		local update, killsRemaining, mobName;
		update = XToLevel.Pet:Update()
		if update then
			if update.xp > 0 then
				killsRemaining = ceil((XToLevel.Pet.maxXP - XToLevel.Pet.xp) / update.xp)
				if killsRemaining > 0 then
					mobName = XToLevel.Pet:GetMobName()
					XToLevel.Messages.Floating:PrintPetKill(XToLevel.Pet:GetName(), mobName, killsRemaining)
					XToLevel.Messages.Chat:PrintPetKill(XToLevel.Pet:GetName(), mobName, killsRemaining)
				end
			end
	        if update.gainedLevel then
	            XToLevel.Messages.Floating:PrintPetLevel(XToLevel.Pet:GetName())
	            XToLevel.Messages.Chat:PrintPetLevel(XToLevel.Pet:GetName())
	        end
			XToLevel.Average:Update()
	        XToLevel.LDB:BuildPattern()
			XToLevel.LDB:Update()
		end
	end
end

---
-- PET_UI_UPDATE callback. This event only fires after a new pet has been trained
-- (as far as I know). Included here to circumvent a problem with the UNIT_PET
-- event firing to early when a new pet is trained.
---
function XToLevel:OnPetUiUpdate()
	-- 
	XToLevel.Pet:Initialize()
	XToLevel.Average:Update()
    XToLevel.LDB:BuildPattern();
	XToLevel.LDB:Update()
end

---
-- PLAYER_ENTERING_BATTLEGROUND callback.
---
function XToLevel:OnPlayerEnteringBattleground()
	if XToLevel.Player.isActive then
		XToLevel.Player:BattlegroundStart(false)
	else
		console:log("Entered BG. Player counter inactive. Count cancelled.")
	end
end

---
-- LFG_PROPOSAL_SUCCEEDED callback.
-- Called when all members of a PUG, assembled via the LFG system, have accepted
-- the invite. (Used here to detect whether a player is entering a dungeon
-- whiles inside another one.)
function XToLevel:OnLfgProposalSucceeded()
	self.hasLfgProposalSucceeded = true
end

---
-- PLAYER_LEAVING_Instance callback.
---
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

---
-- PLAYER_ENTERING_WORLD callback. Triggered whenever a loading screen completes.
-- Determines whether the player has left an battleground (a loading screen is
-- only shown in a BG when leaving) and closes the XToLevel.Player bg instance, printing
-- the "bgs required" message. It also checks if the player has entered or
-- left an instance and calls the appropriate functions.
---
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

---
-- PLAYER_UNGHOST callback. Called when the a player returns from ghost mode.
-- Determines whether the player returned to life ouside of an instance after
-- dying inside an instance. Note that when resurected by another player inside
-- the instance, after releasing, the player momentarily comes back to life
-- outside the instance, which would cause the instance to be closed.
-- To avoid that, I only close the instance if a player has asked for a spirit 
-- heal and no resurection requests have been detected. 
---
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

---
-- CONFIRM_XP_LOSS callback. Triggered when a spirit healer dialog is opened.
-- Note that does NOT mean a spirit heal has been accepted, only the dialog showed.
---
function XToLevel:OnConfirmXpLoss()
    self.playerHasXpLossRequest = true;
end

---
-- RESURECT_REQUEST callback. Triggered when a player resurection dialog is opened.
---
function XToLevel:OnResurrectRequest()
    self.playerHasResurrectRequest = true;
end

---
-- PLAYER_ALIVE callback. Triggered on spirit realease, or after aceppting resurection
-- before releasing. It also fires after entering or leaving an instance.
-- (Possibly even after every load screen, but I haven't confirmed that.)
---
function XToLevel:OnPlayerAlive()
    self.playerHasXpLossRequest = false
    self.playerHasResurrectRequest = false
end

---
-- callback for ZONE_CHANGED_NEW_AREA, ZONE_CHANGED_INDOORS and ZONE_CHANGED.
-- Basically fired everytime the player moves into a new area, sub-area or the
-- indoor/outdoor status changes.
-- Determines whether the zone name of the BG in progres needs to be set, and if
-- not it checks if the name of the BG matches the zone. If not the player has
-- left the BG are and the BG in progress is stopped.
---
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

--- Passes the time played info into the Player object.
function XToLevel:OnTimePlayedMsg(total, level)
	XToLevel.Player:UpdateTimePlayed(total, level)
end

--- Called to trigger an update of the time played. Causes the time to be flushed into the chat,
-- triggering the TIME_PLAYED_MSG event, from which the info can be retrieved.
function XToLevel:TimePlayedTriggerCallback()
	if XToLevel.Player.timePlayedTotal == nil or XToLevel.Player.timePlayedLevel == nil then
		RequestTimePlayed()
	end
end

---
-- Callback for the /xtl and /xtolevel slash commands.
-- Without parametes, it simply opens the configuration dialog.
-- Various commands may exist for debuggin purposes, but none are essential to
-- the application.
---
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
	elseif arg1 == "pet list" then
		console:log("-- Pet list--")
		for petName, petList in pairs(sData.pet.killList) do
			console:log("List for: " .. petName)
			for killIndex, killXP in ipairs(petList) do
				console:log(" #"..killIndex..": "..killXP)
			end
		end
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
    elseif arg1 == "debug" then
    	local diff = time() - tonumber(sData.player.timer.start)
		console:log(tostring(diff))
	else
		XToLevel.Config:Open()
	end
end