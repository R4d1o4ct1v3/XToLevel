---
-- Controls all Playe related functionality.
-- @file XToLevel.Player.lua
-- @release 3.3.3_13r
-- @copyright Atli Þór (atli@advefir.com)
---
--module "XToLevel.Player" -- For documentation purposes. Do not uncomment!

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
	maxLevel = 80, -- Assume WotLK-enabled. Will be corrected once properly initialized.
	class = nil,
	currentXP = nil,
    restedXP = 0,
	maxXP = nil,
    killAverage = nil,
    killRange = { low = nil, high = nil, average = nil },
	questAverage = nil,
	questRange = { low = nil, high = nil, average = nil },
	bgAverage = nil,
	bgObjAverage = nil,
    dungeonAverage = nil,
	killListLength = 100, -- The max allowed value, not the current selection.
	questListLength = 100,
	bgListLength = 300,
	dungeonListLength = 100,
	hasEnteredBG = true,
	
	timePlayedTotal = nil,
	timePlayedLevel = nil,
	timePlayedUpdated = nil,
	
	dungeonList = {},
	latestDungeonData = { totalXP = nil, killCount = nil, xpPerKill = nil, otherXP = nil },
	bgList = { },
	latestBgData = { totalXP = nil, objCount = nil, killCount = nil, xpPerObj = nil, xpPerKill = nil, otherXP = nil, },
	
	lastSync = time(),
	lastXpPerHourUpdate = time() - 60,
	xpPerSec = nil,
	xpPerSecTimeout = 2, -- The number of seconds between re-calculating the xpPerSec
	timerHandler = nil,
	
	-- Constructor
	Initialize = function(self)
		self:SyncData()
        
		if self.level == self.maxLevel then
			self.isActive = false
		else
			self.isActive = true
		end
		
        self.killAverage = nil
		self.bgObjAverage = nil
        self.questAverage = nil

        self.maxLevel = self:GetMaxLevel();
		
		if sConfig.timer.enabled then
			self.timerHandler = XToLevel.timer:ScheduleRepeatingTimer(XToLevel.Player.TriggerTimerUpdate, self.xpPerSecTimeout)
		end
	end,

    ---
    -- Calculates the max level for the player, based on the expansion level
    -- available to the player.
    -- This assumes a 10 level increase per expansion, starting at level 60.
    ---
    GetMaxLevel = function(self)
        return (60 + (10 * GetAccountExpansionLevel()));
    end,
    
    ---
    -- Returns the player class in English, fully capitalized. For example:
    -- "HUNTER", "WARRIOR".
    GetClass = function(self)
    	if self.class == nil then
    		local playerClass, englishClass = UnitClass("player");
    		self.class = englishClass
    	end
    	return self.class
    end,
	
	---
	-- Creates an empty template entry for the bg list.
	-- @return The empty template table.
	--- 
	CreateBgDataArray = function(self)
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
	end,
	
	---
    -- Creates an empty template entry for the dungeon list.
    -- @return The empty template table.
    --- 
	CreateDungeonDataArray = function(self)
        return {
            inProgress = false,
            level = nil,
            name = nil,
            totalXP = 0,
            killCount = 0,
            killTotal = 0,
            rested = 0,
        }
    end,
    
    ---
    -- Updates the level and XP values in the table with the actual values on
    -- the server.
    ---
    SyncData = function(self)
        self.level = UnitLevel("player")
		self.currentXP = UnitXP("player")
		self.maxXP = UnitXPMax("player")
		self.lastSync = time() -- Used for the XP/hr calculations. May be altered elsewhere!
        
        local rested = GetXPExhaustion() or 0
        self.restedXP = rested / 2
    end,
	
	
	
	--- Updates the time played values.
	-- @param total The total time played on this char, in seconds.
	-- @param level The total time played this level, in seconds.
	UpdateTimePlayed = function(self, total, level)
		if type(level) == "number" and level > 0 then
			self.timePlayedLevel = level
		end
		if type(total) == "number" and total > 0 then
			self.timePlayedTotal = total
		end
		self.timePlayedUpdated = time()
	end,
	
	--- Callback for the timer registration function.
	TriggerTimerUpdate = function(self)
		XToLevel.Player:UpdateTimer()
	end,
	UpdateTimer = function(self)
		self = XToLevel.Player
		self.lastXpPerHourUpdate = time()
		
		local useMode = sConfig.timer.mode
		
		-- Use the session data
		if useMode == 1 then
			if type(sData.player.timer.start) == "number" and type(sData.player.timer.total) == "number" and sData.player.timer.total > 0 then
				sData.player.timer.xpPerSec = sData.player.timer.total / (time() - sData.player.timer.start)
				local secondsToLevel = (self.maxXP - self.currentXP) / sData.player.timer.xpPerSec
				XToLevel.Average:UpdateTimer(secondsToLevel)
			else
				useMode = 2
			end
		end
		
		-- Use the level data.
		if useMode == 2 then
			if type(self.timePlayedLevel) == "number" and (self.timePlayedLevel + (time() - self.timePlayedUpdated)) > 0 then
				sData.player.timer.xpPerSec = self.currentXP / (self.timePlayedLevel + (time() - self.timePlayedUpdated))
				local secondsToLevel = (self.maxXP - self.currentXP) / sData.player.timer.xpPerSec
				XToLevel.Average:UpdateTimer(secondsToLevel)
			else
				useMode = false
			end
		end
		
		-- Fallback, in case both above failed.
		if useMode == false then		
			sData.player.timer.xpPerSec = 0
			XToLevel.Average:UpdateTimer(nil)
		end
		XToLevel.LDB:UpdateTimer()
	end,
	
	--- Returns details about the estimated time remaining.
	-- @return mode, timeToLevel, timePlayed, xpPerHour, totalXP
	GetTimerData = function(self)
		local mode = sConfig.timer.mode == 1 and (L['Session'] or "Session") or (L['Level'] or "Level")
		local timePlayed, totalXP, xpPerSecond, xpPerHour, timeToLevel
		if sConfig.timer.mode == 1 and tonumber(sData.player.timer.total) > 0 then
			mode = 1
			timePlayed = time() - sData.player.timer.start
			totalXP = sData.player.timer.total
			xpPerSecond = totalXP / timePlayed 
			xpPerHour = ceil(xpPerSecond * 3600)
			timeToLevel = (self.maxXP - self.currentXP) / xpPerSecond
		elseif XToLevel.Player.timePlayedLevel then
			mode = 2
			timePlayed = self.timePlayedLevel + (time() - self.timePlayedUpdated)
			totalXP = self.currentXP
			xpPerSecond = totalXP / timePlayed 
			xpPerHour = ceil(xpPerSecond * 3600)
			timeToLevel = (self.maxXP - self.currentXP) / xpPerSecond
		else
			mode = nil
			timePlayed = 0
			totalXP = nil
			xpPerSecond = nil
			xpPerHour = nil
			timeToLevel = 0
		end
		
		return mode, timeToLevel, timePlayed, xpPerHour, totalXP
	end,
    
    ---
    -- Calculatest the unrested XP. If a number is passed, it will be used instead of
	-- the player's remaining XP.
    -- @param totalXP The total XP gained from a kill
    GetUnrestedXP = function(self, totalXP)
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
    end,
	
	---
	-- Adds a kill to the kill list and updates the recorded XP value.
	-- @param xpGained The TOTAL amount of XP gained, including bonuses.
	-- @param mobName The name of the killed mob.
	-- @return The gained XP without any rested bounses.
	---
	AddKill = function(self, xpGained, mobName)
        self.currentXP = self.currentXP + xpGained
        
        local killXP = self:GetUnrestedXP(xpGained)
    
		self.killAverage = nil
        table.insert(sData.player.killList, 1, {mob=mobName, xp=killXP})
		if(# sData.player.killList > self.killListLength) then
			table.remove(sData.player.killList)
		end

        return killXP
	end,
	
	---
	-- Adds a quest to the quest list and updates the recorded XP value.
	-- @param xpGained The XP gained from the quest.
	---
	AddQuest = function (self, xpGained)
		self.questAverage = nil
		self.currentXP = self.currentXP + xpGained
        table.insert(sData.player.questList, 1, xpGained)
		if(# sData.player.questList > self.questListLength) then
			table.remove(sData.player.questList)
		end
	end,
	
	---
	-- Start recording a battleground. If a battleground is already in progress
	-- the function fails.
	-- @param bgName The name of the battleground. (This will be updated later.)
	-- @return boolean
	---
	BattlegroundStart = function(self, bgName)
		if (# sData.player.bgList) > 0 and sData.player.bgList[1].inProgress == true then
			console:log("Attempted to start a BG while another one is in progress.")
			return false
		else
			local bgDataArray = self:CreateBgDataArray();
			table.insert(sData.player.bgList, 1, bgDataArray)
			if(# sData.player.bgList > self.bgListLength) then
				table.remove(sData.player.bgList)
			end
			sData.player.bgList[1].inProgress = true
			sData.player.bgList[1].name = bgName or false
			sData.player.bgList[1].level = self.level
			console:log("BG Started! (" .. tostring(sData.player.bgList[1].name) .. ")")
			return true
		end
	end,
	
	---
	-- Attempts to end the battleground currently in progress. If no battleground
	-- is in progress it fails. If the entry that is in progress has recorded no
	-- honor, the function fails and removes the entry from the list.
	-- @return boolean
	---
	BattlegroundEnd = function(self)
		if sData.player.bgList[1].inProgress == true then
			sData.player.bgList[1].inProgress = false
			console:log("BG Ended! (" .. tostring(sData.player.bgList[1].name)  .. ")")
			
			self.bgAverage = nil
            self.bgObjAverage = nil
			
			if sData.player.bgList[1].totalXP == 0 then
				table.remove(sData.player.bgList, 1)
				console:log("BG ended without any honor gain. Disregarding it.)")
				return false
			else
                return true
			end
		else
			console:log("Attempted to end a BG before one was started.")
			return false
		end
	end,
	
	---
	-- Checks whether a battleground is currently in progress.
	-- @return A boolean, indicating whether a battleground is in progress.
    ---
	IsBattlegroundInProgress = function(self)
	   if # sData.player.bgList > 0 then
            return sData.player.bgList[1].inProgress
        else
            return false
        end
	end,
	
	---
	-- Adds a battleground objective to the currently active battleground entry.
	-- If the xpGained is less than the minimum required XP for an objective, 
	-- the objective is recorded as a kill. (AV centry kills are often not
	-- reported as kills, but as quests/objectives, and thus far below what actual
	-- objectives reward.)
	-- @param xpGained The XP gained from the objective.
	-- @return boolean
	---
    AddBattlegroundObjective = function(self, xpGained)
        if sData.player.bgList[1].inProgress then
            if xpGained > XToLevel.Lib:GetBGObjectiveMinXP() then
                self.bgObjAverage = nil
                sData.player.bgList[1].totalXP = sData.player.bgList[1].totalXP + xpGained
                sData.player.bgList[1].objTotal = sData.player.bgList[1].objTotal + xpGained
                sData.player.bgList[1].objCount = sData.player.bgList[1].objCount + 1
                return true
            else
                return self:AddBattlegroundKill(xpGained, 'Unknown')
            end
        else
            console:log("Attempt to add a BG objective without starting a BG.")
            return false
        end
    end,
    
    ---
    -- Adds a kill to the currently active battleground entry. If no entry is
    -- in progress then the function fails.
    -- @param xpGained The XP gained from the kill.
    -- @param name The name of the mob killed.
    -- @return boolean
    ---
    AddBattlegroundKill = function(self, xpGained, name)
        if sData.player.bgList[1].inProgress then
            sData.player.bgList[1].totalXP = sData.player.bgList[1].totalXP + xpGained
            sData.player.bgList[1].killCount = sData.player.bgList[1].killCount + 1
            sData.player.bgList[1].killTotal = sData.player.bgList[1].killTotal + xpGained
        else
            console:log("Attempt to add a BG kill without starting a BG.")
        end
    end,
    
	---
	-- Starts recording a dungeon. Fails if already recording a dungeon.
	-- @return boolean
	---
    DungeonStart = function(self)
        if self.isActive and not self:IsDungeonInProgress() then
	        local dungeonName = GetRealZoneText()
            local dungeonDataArray = self:CreateDungeonDataArray()
            table.insert(sData.player.dungeonList, 1, dungeonDataArray)
            if(# sData.player.dungeonList > self.dungeonListLength) then
                table.remove(sData.player.dungeonList)
            end
            
            sData.player.dungeonList[1].inProgress = true
            sData.player.dungeonList[1].name = dungeonName or false
            sData.player.dungeonList[1].level = self.level
            console:log("Dungeon Started! (" .. tostring(sData.player.dungeonList[1].name) .. ")")
            return true
	    else
	        console:log("Attempt to start a dungeon failed. Player either not active or already in a dungeon.")
	        return false
	    end
        
    end,
    
    ---
    -- Stops recording a dungeon. If not recording a dungeon, the function fails.
    -- If the dungeon being recorded has yielded no XP, the entry is removed and
    -- the function fails.
    -- @return boolean
    ---
    DungeonEnd = function(self)
        if sData.player.dungeonList[1].inProgress == true then
            sData.player.dungeonList[1].inProgress = false
            self:UpdateDungeonName()
            console:log("Dungeon Ended! (" .. tostring(sData.player.dungeonList[1].name)  .. ")")
            
            self.dungeonAverage = nil
                      
            if sData.player.dungeonList[1].totalXP == 0 then
                table.remove(sData.player.dungeonList, 1)
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
    end,
    
    ---
    -- Checks whether a dungeon is in progress.
    -- @return boolean
    ---
    IsDungeonInProgress = function(self)
        if # sData.player.dungeonList > 0 then
            return sData.player.dungeonList[1].inProgress
        else
            return false
        end
    end,
    
    ---
    -- Update the name of the dungeon currently being recorded. If not recording
    -- a dungeon, or if the name does not need to be updated, the function fails.
    -- @return boolean
    ---
    UpdateDungeonName = function(self)
        local inInstance, type = IsInInstance()
        if self:IsDungeonInProgress() and inInstance and type == "party" then
            local zoneName = GetRealZoneText()
            if sData.player.dungeonList[1].name ~= zoneName then
                sData.player.dungeonList[1].name = zoneName
                console:log("Dungeon name updated (" .. tostring(zoneName) ..")")
                return true
            else
                return false
            end
        else
            return false
        end
    end,
    
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
    AddDungeonKill = function(self, xpGained, name, rested)
        if self:IsDungeonInProgress() then
            sData.player.dungeonList[1].totalXP = sData.player.dungeonList[1].totalXP + xpGained
            sData.player.dungeonList[1].killCount = sData.player.dungeonList[1].killCount + 1
            sData.player.dungeonList[1].killTotal = sData.player.dungeonList[1].killTotal + xpGained
            if type(rested) == "number" and rested > 0 then
            	sData.player.dungeonList[1].rested = sData.player.dungeonList[1].rested + rested
        	end
            self:UpdateDungeonName()
            return true
        else
            console:log("Attempt to add a Dungeon kill without starting a Dungeon.")
            return false
        end
    end,
    
    ---
    -- Gets the amount of kills required to reach the next level, based on the
    -- passed XP value. The rested bonus is taken into account.
    -- @param xp The XP assumed per kill
    -- @return An integer or -1 if the input parameter is invalid.
    ---
    GetKillsRequired = function(self, xp)
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
    end,
    
    ---
    -- Gets the amount of quests required to reach the next level, based on the
    -- passed XP value.
    -- @param xp The XP assumed per quest
    -- @return An integer or -1 if the input parameter is invalid.
    ---
    GetQuestsRequired = function(self, xp)
        local xpRemaining = self.maxXP - self.currentXP
		if(xp > 0) then
			return ceil(xpRemaining / xp)
        else
            return -1
        end
    end,
    
    ---
    -- Gets the percentage of XP already gained towards the next level.
    -- @param fractions The number of fraction digits to be used. Defaults to 1.
    -- @return A number between 0 and 100, representing the percentage. 
    ---
	percentage = nil,
	lastKnownXP = nil,
    GetProgressAsPercentage = function(self, fractions)
		if type(fractions) ~= "number" or fractions <= 0 then
			fractions = 1
		end
		if self.percentage == nil or self.lastKnownXP == nil or self.lastKnownXP ~= self.currentXP then
			self.lastKnownXP = self.currentXP
			self.percentage = (self.currentXP or 0) / (self.maxXP or 1) * 100
		end
        return XToLevel.Lib:round(self.percentage, fractions)
    end,
    
    ---
    -- Get the number of "bars" remaining until the next level is reached. Each
    -- "bar" represents 5% of the total value.
    -- This has become a common measurement used by players when referring
    -- to their progress, inspired by the default WoW UI, where the XP progress
    -- bar is split into 20 induvidual cells.
    -- @param fractions The number of fraction digits to be used. Defautls to 0.
    ---
    GetProgressAsBars = function(self, fractions)
        if type(fractions) ~= "number" or fractions <= 0 then
            fractions = 0
        end
        local barsRemaining = ceil((100 - ((self.currentXP or 0) / (self.maxXP or 1) * 100)) / 5, fractions)
        return barsRemaining
    end,
	
	GetXpRemaining = function(self) 
		return self.maxXP - self.currentXP
	end,
	
	GetRestedPercentage = function(self, fractions)
		if type(fractions) ~= "number" or fractions <= 0 then
            fractions = 0
        end
		return XToLevel.Lib:round((self.restedXP * 2) / self.maxXP * 100, fractions, true);
	end,
    
    ---
    -- Get the average XP per kill. The number of kills used is limited by the
    -- sConfig.averageDisplay.playerKillListLength configuration directive. 
    -- The value returned is stored in the killAverage member, so calling this 
    -- function twice only calculates the value once. If no data is avaiable, a 
    -- level based estimate  is used.
    -- Note that the function applies the Recruit-A-Friend bonus when applicable
    -- but that does not affect the actual value stored. It is applied only when
    -- the value is about to be returned.
    -- @return A number.
    ---
	GetAverageKillXP = function (self)
		if self.killAverage == nil then
			if(# sData.player.killList > 0) then
				local total = 0
				local maxUsed = # sData.player.killList
				if maxUsed > sConfig.averageDisplay.playerKillListLength then
					maxUsed = sConfig.averageDisplay.playerKillListLength
				end
				for index, value in ipairs(sData.player.killList) do
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
	end,
	
	---
	-- Calculates the average, highest and lowest XP values recorded for kills.
	-- The range of data used is limited by the 
	-- sConfig.averageDisplay.playerKillListLength config directive. If no data 
	-- is available, a level based estimate is used. Note that the function 
    -- applies the Recruit-A-Friend bonus when applicable but that does not 
    -- affect the actual value stored. It is applied only when the value is 
    -- about to be returned.
    -- @return A table as : { 'average', 'high', 'low' }
	---
	GetKillXpRange = function (self)
        if(# sData.player.killList > 0) then
            self.killRange.high = 0
            self.killRange.low = 0
            self.killRange.average = 0
            local total = 0
            local maxUsed = # sData.player.killList
            if maxUsed > sConfig.averageDisplay.playerKillListLength then
                maxUsed = sConfig.averageDisplay.playerKillListLength
            end
            for index, value in ipairs(sData.player.killList) do
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
            --[[return {
                high = self.killRange.high,
                low = self.killRange.low,
                average = self.killRange.average
            }--]]
        else
            return self.killRange
        end
    end,
    
    ---
    -- Gets the average number of kills needed to reache the next level, based
    -- on the XP value returned by the GetAverageKillXP function.
    -- @return A number. -1 if the function fails.
    ---
    GetAverageKillsRemaining = function (self)
		if(self:GetAverageKillXP() > 0) then
            return self:GetKillsRequired(self:GetAverageKillXP())
		else
			return -1
		end
	end,
	
	---
    -- Get the average XP per quest. The number of quests used is limited by the
    -- sConfig.averageDisplay.playerQuestListLength configuration directive. - 
    -- The value returned is stored in the questAverage member, so calling this 
    -- function twice only calculates the value once. If no data is avaiable, 
    -- a level based estimate is used.
    -- Note that the function applies the Recruit-A-Friend bonus when applicable
    -- but that does not affect the actual value stored. It is applied only when
    -- the value is about to be returned.
    -- @return A number.
    ---
	GetAverageQuestXP = function (self)
		if self.questAverage == nil then
			if(# sData.player.questList > 0) then
				local total = 0
				local maxUsed = # sData.player.questList
				if maxUsed > sConfig.averageDisplay.playerQuestListLength then
					maxUsed = sConfig.averageDisplay.playerQuestListLength
				end
				for index, value in ipairs(sData.player.questList) do
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
	end,
	
	---
    -- Calculates the average, highest and lowest XP values recorded for quests.
    -- The range of data used is limited by the 
    -- sConfig.averageDisplay.playerQuestListLength config directive. If no data 
    -- is available, a level based estimate is used. Note that the function 
    -- applies the Recruit-A-Friend bonus when applicable but that does not 
    -- affect the actual value stored. It is applied only whenthe value is about 
    -- to be returned.
    -- @return A table as : { 'average', 'high', 'low' }
    ---
	GetQuestXpRange = function (self)
        if(# sData.player.questList > 0) then
            self.questRange.high = 0
            self.questRange.low = 0
            self.questRange.average = 0
            local total = 0
            local maxUsed = # sData.player.questList
            if maxUsed > sConfig.averageDisplay.playerQuestListLength then
                maxUsed = sConfig.averageDisplay.playerQuestListLength
            end
            for index, value in ipairs(sData.player.questList) do
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
            --[[return {
                high = self.questRange.high * 3,
                low = self.questRange.low * 3,
                average = self.questRange.average * 3
            }--]]
        else
            return self.questRange
        end
    end,
    
    ---
    -- Gets the average number of quests needed to reache the next level, based
    -- on the XP value returned by the GetAverageQuestXP function.
    -- @return A number. -1 if the function fails.
    ---
	GetAverageQuestsRemaining = function (self)
		if(self:GetAverageQuestXP() > 0) then
			return self:GetQuestsRequired(self:GetAverageQuestXP())
		else
			return -1
		end
    end,
	
	---
	-- Checks whether any battleground data has been recorded yet.
	-- @return boolean
	---
    HasBattlegroundData = function(self)
        return (# sData.player.bgList > 0)
    end,
    
    ---
    -- Get the average XP per BG. The number of BGs used is limited by the
    -- sConfig.averageDisplay.playerBGListLength configuration directive.
    -- The value returned is stored in the bgAverage member, so calling this 
    -- function twice only calculates the value once. If no data is avaiable, 
    -- a rough level based estimate is used.
    -- @return A number.
    ---
	GetAverageBGXP = function (self)
		if self.bgAverage == nil then
			if(# sData.player.bgList > 0) then
				local total = 0
				local maxUsed = # sData.player.bgList
				if maxUsed > sConfig.averageDisplay.playerBGListLength then
					maxUsed = sConfig.averageDisplay.playerBGListLength
				end
				local usedCounter = 0
				for index, value in ipairs(sData.player.bgList) do
					if usedCounter >= maxUsed then
						break;
					end
					-- To compensate for the fact that levels were not recorded before 3.3.3_12r.
					if value.level == nil then
					   sData.player.bgList[index].level = self.level
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
	end,
	
	---
    -- Gets the average number of BGs needed to reache the next level, based
    -- on the XP value returned by the GetAverageBGXP function.
    -- @return A number. nil if the function fails.
    ---
	GetAverageBGsRemaining = function(self)
		local bgAverage = self:GetAverageBGXP()
		if(bgAverage > 0) then
			local xpRemaining = self.maxXP - self.currentXP
			return ceil(xpRemaining / bgAverage)
		else
			return nil
		end
	end,
	
	---
    -- Get the average XP per BG objective. The number of BG objectives used is 
    -- limited by the sConfig.averageDisplay.playerBGOListLength config directive. 
    -- The value returned is stored in the bgObjAverage member, so calling this 
    -- function twice only calculates the value once. If no data is avaiable, 
    -- a rough level based estimate is used.
    -- @return A number.
    ---
	GetAverageBGObjectiveXP = function (self)
		if self.bgObjAverage == nil then
			if(# sData.player.bgList > 0) then
				local total = 0
				local count = 0
                local maxcount = sConfig.averageDisplay.playerBGOListLength
				for index, value in ipairs(sData.player.bgList) do
                    if count >= maxcount then
                        break
                    end
                    if value.level == nil then
                        sData.player.bgList[index].level = self.level
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
	end,
	
	---
    -- Gets the average number of BG Objectives needed to reache the next level, 
    -- based on the XP value returned by the GetAverageBGObjectiveXP function.
    -- @return A number. -1 if the function fails.
    ---
	GetAverageBGObjectivesRemaining = function (self)
		local objAverage = self:GetAverageBGObjectiveXP()
		if(objAverage > 0) then
			local xpRemaining = self.maxXP - self.currentXP
			return ceil(xpRemaining / objAverage)
		else
			return nil	
		end
	end,
	
	---
	-- Gets the names of all battlegrounds that have been recorded so far.
	-- @return A { 'name' = count, ... } table on success or nil if no data exists.
	---
	GetBattlegroundsListed = function (self)
        if(# sData.player.bgList > 0) then
            local count = 0
            for index, value in ipairs(sData.player.bgList) do
                if value.level == nil then
                    value.level = self.level
                    sData.player.bgList[index].level = self.level
                end
                if self.level - value.level < 5 and value.totalXP > 0 and not value.inProgress then
                    self.bgList[value.name] = (self.bgList[value.name] or 0) + 1
                    count = count + 1
                end
            end
            if count > 0 then
                return self.bgList;
            else
                return nil
            end
        else
            return nil
        end
    end,
	
	---
	-- Returns the average XP for the given battleground. The data is limited by
	-- the sConfig.averageDisplay.playerBGListLength config directive. Note that
	-- battlegrounds currently in progress will not be counted.
	-- @param name The name of the battleground to be used.
	-- @return A number. If the database has no entries, it returns 0.
	---
	GetBattlegroundAverage = function(self, name)
		if(# sData.player.bgList > 0) then
			local total = 0
			local count = 0
            local maxcount = sConfig.averageDisplay.playerBGListLength
			for index, value in ipairs(sData.player.bgList) do
                if count >= maxcount then
                    break
                end
                if value.level == nil then
                    sData.player.bgList[index].level = self.level
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
	end,
	
	---
	-- Gets details for the last entry in the battleground list.
	-- @return A table matching the CreateBgDataArray template, or nil if no
	--         battlegrounds have been recorded yet.
	---
	GetLatestBattlegroundDetails = function(self)
		if # sData.player.bgList > 0 then
			-- Make sure to get the latest BG in a 5 level range.
			local bgIndex = nil
			for index, value in ipairs(sData.player.bgList[1]) do
				if XToLevel.Player.level - sData.player.bgList[index].level < 5 then
					bgIndex = index
					break
				end
			end
			if not bgIndex then
				return nil
			else
	            self.latestBgData.totalXP = sData.player.bgList[1].totalXP
	            self.latestBgData.objCount = sData.player.bgList[1].objCount
	            self.latestBgData.killCount = sData.player.bgList[1].killCount
	            self.latestBgData.xpPerObj = 0
	            self.latestBgData.xpPerKill = 0
	            self.latestBgData.otherXP = sData.player.bgList[1].totalXP - (sData.player.bgList[1].objTotal + sData.player.bgList[1].killTotal)
				
				if self.latestBgData.objCount > 0 then
					self.latestBgData.xpPerObj = XToLevel.Lib:round(sData.player.bgList[1].objTotal / self.latestBgData.objCount, 0)
				end
				if self.latestBgData.killCount > 0 then
					self.latestBgData.xpPerKill = XToLevel.Lib:round(sData.player.bgList[1].killTotal / self.latestBgData.killCount, 0)
				end
				
				return self.latestBgData
			end
		else
			return nil
		end
	end,
	
	---
    -- Checks whether any dungeon data has been recorded yet.
    -- @return boolean
    ---
	HasDungeonData = function(self)
        return (# sData.player.dungeonList > 0)
    end,
    
    ---
    -- Get the average XP per dungeon. The number of dungeons used is limited by
    -- the sConfig.averageDisplay.playerDungeonListLength configuration directive.
    -- The value returned is stored in the dungeonAverage member, so calling  
    -- this function twice only calculates the value once. If no data is, 
    -- avaiable a rough level based estimate is used.
    -- @return A number.
    ---
	GetAverageDungeonXP = function (self)
        if self.dungeonAverage == nil then
            if(# sData.player.dungeonList > 0) and not ((# sData.player.dungeonList == 1) and sData.player.dungeonList[1].inProgress) then
                local total = 0
                local maxUsed = # sData.player.dungeonList
                if maxUsed > sConfig.averageDisplay.playerDungeonListLength then
                    maxUsed = sConfig.averageDisplay.playerDungeonListLength
                end
                local usedCounter = 0
                for index, value in ipairs(sData.player.dungeonList) do
                    if usedCounter >= maxUsed then
                        break;
                    end
                    -- To compensate for the fact that levels were not recorded before 3.3.3_12r.
                    if value.level == nil then
                        sData.player.dungeonList[index].level = self.level
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
    end,
    
    ---
    -- Gets the average number of dungeons needed to reache the next level, 
    -- basedon the XP value returned by the GetAverageDungeonXP function.
    -- @return A number. nil if the function fails.
    ---
    GetAverageDungeonsRemaining = function(self)
        local dungeonAverage = self:GetAverageDungeonXP()
        if(dungeonAverage > 0) then
            return self:GetKillsRequired(dungeonAverage)
        else
            return nil
        end
    end,
    
    ---
    -- Gets the names of all dungeons that have been recorded so far.
    -- @return A { 'name' = count, ... } table on success or nil if no data exists.
    ---
    GetDungeonsListed = function (self)
        if # sData.player.dungeonList > 0 then
            -- Clear list in a memory efficient way.
            for index, value in pairs(self.dungeonList) do
                self.dungeonList[index] = 0
            end
            local count = 0
            for index, value in ipairs(sData.player.dungeonList) do
                if value.level == nil then
                    sData.player.dungeonList[index].level = self.level
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
    end,
    
    ---
    -- Returns the average XP for the given dungeon. The data is limited by
    -- the sConfig.averageDisplay.playerDungeonListLength config directive. Note
    -- that dungeons currently in progress will not be counted.
    -- @param name The name of the dungeon to be used.
    -- @return A number. If the database has no entries, it returns 0.
    ---
    GetDungeonAverage = function(self, name)
        if(# sData.player.dungeonList > 0) then
            local total = 0
            local count = 0
            local maxcount = sConfig.averageDisplay.playerDungeonListLength
            for index, value in ipairs(sData.player.dungeonList) do
                if count >= maxcount then
                    break
                end
                if value.level == nil then
                    sData.player.dungeonList[index].level = self.level
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
    end,
    
    ---
    -- Gets details for the last entry in the dungeon list.
    -- @return A table matching the CreateDungeonDataArray template, or nil if
    --         no battlegrounds have been recorded yet.
    ---
    GetLatestDungeonDetails = function(self)
        if # sData.player.dungeonList > 0 then
            self.latestDungeonData.totalXP = sData.player.dungeonList[1].totalXP
            self.latestDungeonData.killCount = sData.player.dungeonList[1].killCount
            self.latestDungeonData.xpPerKill = 0
            self.latestDungeonData.rested = sData.player.dungeonList[1].rested
            self.latestDungeonData.otherXP = sData.player.dungeonList[1].totalXP - sData.player.dungeonList[1].killTotal          
            if self.latestDungeonData.killCount > 0 then
                self.latestDungeonData.xpPerKill = XToLevel.Lib:round(sData.player.dungeonList[1].killTotal / self.latestDungeonData.killCount, 0)
            end
            
            return self.latestDungeonData
        else
            return nil
        end
    end,
	
	---
	-- Clears the kill list. If the initialValue parameter is passed, a single
	-- entry with that value is added.
	-- @param initalValue The inital value for the list. [optional]
	ClearKills = function (self, initialValue)
		sData.player.killList = { }
        self.killAverage = nil;
        if initialValue ~= nil and tonumber(initialValue) > 0 then
            table.insert(sData.player.killList, {mob='Initial', xp=tonumber(initialValue)})
        end
	end,
	
	---
    -- Clears the quest list. If the initialValue parameter is passed, a single
    -- entry with that value is added.
    -- @param initalValue The inital value for the list. [optional]
	ClearQuests = function (self, initialValue)
		sData.player.questList = { }
        self.questAverage = nil;
        if initialValue ~= nil and tonumber(initialValue) > 0 then
            table.insert(sData.player.questList, tonumber(initialValue))
		end
	end,
	
	---
    -- Clears the BG list. If the initialValue parameter is passed, a single
    -- entry with that value is added.
    -- @param initalValue The inital value for the list. [optional]
	ClearBattlegrounds = function(self, initialValue)
		sData.player.bgList = { }
        self.bgAverage = nil;
        self.bgObjAverage = nil;
        if initialValue ~= nil and tonumber(initialValue) > 0 then
            table.insert(sData.player.bgList, tonumber(initialValue))
		end
	end,
	
	---
    -- Clears the dungeon list. If the initialValue parameter is passed, a 
    -- single entry with that value is added.
	ClearDungeonList = function(self, initialValue)
        sData.player.dungeonList = { }
        self.dungeonAverage = nil;
        
        local inInstance, type = IsInInstance()
        if inInstance and type == "party" then
            self:DungeonStart()
        end
    end,
    
    ---
    -- Checks whether the player is rested.
    -- @return The additional XP the player will get until he is unrested again
    --         or FALSE if the player is not rested.
    ---
    IsRested = function(self)
        if self.restedXP > 0 then
            return self.restedXP
        else
            return false
        end
    end,
    
    ---
    -- Sets the number of kills used for average calculations
    SetKillAverageLength = function(self, newValue)
    	sConfig.averageDisplay.playerKillListLength = newValue
    	self.killAverage = nil
    	XToLevel.Average:Update()
    	XToLevel.LDB:BuildPattern()
    	XToLevel.LDB:Update()
    end,
    
    ---
    -- Sets the number of kills used for average calculations
    SetQuestAverageLength = function(self, newValue)
    	sConfig.averageDisplay.playerQuestListLength = newValue
    	self.questAverage = nil
    	XToLevel.Average:Update()
    	XToLevel.LDB:BuildPattern()
    	XToLevel.LDB:Update()
    end,
    
    ---
    -- Sets the number of kills used for average calculations
    SetBattleAverageLength = function(self, newValue)
    	sConfig.averageDisplay.playerBGListLength = newValue
    	self.bgAverage = nil
    	XToLevel.Average:Update()
    	XToLevel.LDB:BuildPattern()
    	XToLevel.LDB:Update()
    end,	
    
    ---
    -- Sets the number of kills used for average calculations
    SetObjectiveAverageLength = function(self, newValue)
    	sConfig.averageDisplay.playerBGOListLength = newValue
    	self.bgObjAverage = nil
    	XToLevel.Average:Update()
    	XToLevel.LDB:BuildPattern()
    	XToLevel.LDB:Update()
    end,
    
    ---
    -- Sets the number of kills used for average calculations
    SetDungeonAverageLength = function(self, newValue)
    	sConfig.averageDisplay.playerDungeonListLength = newValue
    	self.dungeonAverage = nil
    	XToLevel.Average:Update()
    	XToLevel.LDB:BuildPattern()
    	XToLevel.LDB:Update()
    end,
};
