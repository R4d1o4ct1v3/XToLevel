--[[
 File: Libs.lua
 Description:
   A collection of globally available functions, used througout the addon.

 Functions:
   ZoneID() - Returns the ID of the zone the player is current in
   IsPlayerRafEligable() - Determines whether the player is eligable for the 3x RAF bonus.
   IsRafApplied() - Determines whether the RAF bonus should be applied.
   ZeroDifference(charLevel) - Used for Mob XP calculations.
   IsInBattleground() - Determines whether the player is currently inside a battleground zone.
   ShowBattlegroundData() - Determines whether the BG data should be displayed in the tooltip.
   ShowDungeonData() - Determines whether the Dungeon data should be displayed in the tooltip.
   MobXP(charlvl, moblvl) - Calculates the amount of XP the mob is worth to the player.
   PetXP(playerLevel, petLevel, mobLevel) - Calculates the amount of XP the mob is worth to the player's pet.
   ParseChatXPMessage(msg, locale) - Parses the chat XP message into XP amount and Mob name (if available).
   round(input, precision, roundDown) - Rounds the input number to the given precision.
   NumberFormat(input) - Formats the input number to a human-readable number. (Adds commas and periods)
   ShrinkNumber(input) - Shrinks a number to a smaller format. (E.g. 1234000 = 1,23M)
   DecToHex(input) - Converts a decimal (base 10) number to a hex (base 16) number.
   GetProgressColor(percent) - Gets a color value to represent the given progress. (Green for 100%, red for 0%)
   GetBGObjectiveMinXP() - Gets the minimum amount of XP that would be considered a valid BG objective reward.
   FindAnchor(frame) - Gets the appropriate tooltip anchor point for the give frame. (E.g. "TOPLEFT", "BOTTOMRIGHT")
   Split(str, delim, maxNb) - Splits the str on the delim char, maxNb number of times.
--]]

console = { }
function console:log(message)
    XToLevel.Messages:Debug(message)
end

XToLevel.Lib = { }

---
-- Counts the number of times the needle is found in the heystack.
-- @param needle The needle
-- @param heystack The heystack
function XToLevel.Lib:strcount(needle, heystack)
	local index = 1
	local count = 0
	local startPos, endPos = strfind(heystack, needle)
	while endPos ~= nil and count < 10000 do -- 10000 to avoid infinite loops
		count = count + 1
		index = index + endPos
		startPos, endPos = strfind(strsub(heystack, index), needle)
	end
	return count
end

--- Converts a global message, such as FACTION_STANDING_INCREASED
-- to a regular expression that can be used to pull info
-- from messages built from them.
-- @param input The value from the global to be changed.
function XToLevel.Lib:ConvertGlobalToRegexp(input)
	local reg = string.gsub(input, "(%%d)", "(%%d+)")
	reg = string.gsub(reg, "(%%s)", "(.+)")
	return reg
end

--- Runs through the faction list, searching for the faction who's name matches 
-- the one give. If found, returns the following info, or nill otherwise: 
--  desc, start, amount, current, atWar, isWatched.
-- @param searchName The name of the faction to search for.
function XToLevel.Lib:GetFactionInfoByName(searchName)
	local factionIndex = 1
	while factionIndex <= GetNumFactions() do
		local name, description, standingId, bottomValue, topValue, earnedValue, atWarWith, 
			  canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild = GetFactionInfo(factionIndex)
		if isHeader == nil and name == searchName then
			--console:log("FACTION : " .. tostring(bottomValue) .. " - " .. tostring(earnedValue) .. " - " .. tostring(topValue))
			local repAmountPerLevel = nil
			if bottomValue < 0 then
				repAmountPerLevel = math.abs(tonumber(bottomValue)) + tonumber(topValue)
			else
				repAmountPerLevel = tonumber(topValue) - tonumber(bottomValue)
			end
			-- Read: desc, start, amount, current, atWar, isWatched.
		    return description, bottomValue, repAmountPerLevel, earnedValue, atWarWith, isWatched
		else
			ExpandFactionHeader(factionIndex)
		end
		factionIndex = factionIndex + 1
	end
end

--- Returns the name of the current rep level, as well as those around it.
-- @param currentRep The total amount of rep the player has earned
-- @return the anme of the current level, the next level, and the previous level, in that order.
function XToLevel.Lib:GetRepLevelName(currentRep)
	for index, value in ipairs(REP_LEVELS) do
		if value[2] <= currentRep and (value[2] + value[3]) > currentRep then
			local currentName = value[1]
			local upName = nil
			local downName = nil
			if index > 1 then
				downName = REP_LEVELS[index-1][1]
			end
			if index < # REP_LEVELS then
				upName = REP_LEVELS[index+1][1]
			end
			return currentName, upName, downName
		end
	end
end

--- Calculates the number of rep gains needed to level.
-- @param gain The rep gained
-- @param lvlStart The start point for this level; the lower end of range.
-- @param lvlAmount The amount of rep needed for this level
-- @param currentRep The total amount of rep the player has.
function XToLevel.Lib:GetRepGainsToLevel(gain, lvlStart, lvlAmount, currentRep)
	return math.ceil(((lvlStart + lvlAmount) - currentRep) / gain)
end

--- Calculates the number of rep gains needed to reach a specific rep "level".
-- @param gain The rep gained.
-- @param currentRep The total rep the player current has.
-- @param targetName The name of the target rep "level". If not valid, the function XToLevel.Lib:returns nil.
function XToLevel.Lib:GetRepGainsToTarget(gain, currentRep, targetName)
	-- Get the lower limit and amount of the target level
	local targetLower = nil
	for index, value in ipairs(REP_LEVELS) do
		if targetName == value[1] then
			targetLower = value[2]
		end
	end
	if not targetLower then
		return nil
	elseif gain > 0 and targetLower <= currentRep then
		return nil
	elseif gain < 0 and targetLower >= currentRep then
		return nil
	else
		return math.ceil((targetLower - currentRep) / gain);
	end
end

---
-- Returns the ID of the zone the player is current in
---
function XToLevel.Lib:ZoneID()
	local currentZone = GetRealZoneText();
	local continentNames, key, val = { GetMapContinents() } ;
	for key, val in pairs(continentNames) do
		local continentZones = { GetMapZones(key) };
		for i,zone in ipairs(continentZones) do
			if zone == currentZone then
				return key
			end
		end
	end
	return nil
end

---
-- Determines whether the player is eligable for the 3x Recriuit A Friend bonus.
---
function XToLevel.Lib:IsPlayerRafEligable()
    local numPartyMembers = GetNumPartyMembers();
    if numPartyMembers > 0 then
        local memberID = 1;
        while memberID <= numPartyMembers do
            if GetPartyMember(memberID) == 1 then
                local member = "party" .. memberID;
                if UnitIsVisible(member) and IsReferAFriendLinked(member) then
                    return true;
                end
            end
            memberID = memberID + 1;
        end
    end
    return false;
end

---
-- Determines whether the Recruit A Friend bonus should be applied.
---
function XToLevel.Lib:IsRafApplied()
    return sConfig.general.rafEnabled and self:IsPlayerRafEligable();
end

---
-- Used to find the Zero Difference used to calculate XP from low level mobs
---
function XToLevel.Lib:ZeroDifference(charLevel)
	for i,v in ipairs(ZD_Table) do
		if charLevel >= v[1] and charLevel <= v[2] then
			return v[3];
		end
	end
	return 16 -- Assume 60's char.
end

---
-- Determines whether the player is currently inside a battleground zone.
---
function XToLevel.Lib:IsInBattleground()
	local currentZone = GetRealZoneText()
	for key, val in ipairs(BG_NAMES) do
		if val == currentZone then
			return true
		end
	end
	return false
end

function XToLevel.Lib:ShowBattlegroundData()
	return ((sConfig.ldb.tooltip.showBGInfo and XToLevel.Player.level >= 10) and (XToLevel.Player.level < XToLevel.Player.maxLevel or (# sData.player.bgList) > 0))
end

function XToLevel.Lib:ShowDungeonData()
    return ((sConfig.ldb.tooltip.showDungeonInfo) and (XToLevel.Player.level < XToLevel.Player.maxLevel or (# sData.player.dungeonList) > 0))
end

---
-- Calculates the XP gained from killing a mob
---
function XToLevel.Lib:MobXP(charLevel, mobLevel)
	if charLevel == nil or charLevel <= 0 then
		charLevel = UnitLevel("player");
	end
	if mobLevel == nil then 
		mobLevel = charLevel;
	end

	-- Find the highest level that yields no experience.
	local grayLevel = 0
	if charLevel < 6 then
		grayLevel = 0
	elseif charLevel < 40 then
		grayLevel = charLevel - floor(charLevel / 10) - 5
	elseif charLevel < 60 then
		grayLevel = charLevel - floor(charLevel / 5) - 1
	else
		grayLevel = charLevel - 9
	end
	
	if mobLevel <= grayLevel then
		return 0
	end
	
	-- Get the zone specific value needed for the calculations
	-- I assume levels 58-67 and 68-80 will be leveling in Outlands and Northrend, respectively.
	-- (I do this mainly to avoid missleading information when high-level players are in the old zones.)
	zoneID = self:ZoneID()
	if charLevel >= 58 and charLevel < 69 and (zoneID or 0) < 3 then
		zoneID = 3
	elseif charLevel >= 69 and (zoneID or 0) < 4 then -- no need for an upper limit
		zoneID = 4
	end
	
	local addValue = 45 -- Default, for the pre-tbc zones
	if (zoneID or 0) == 3 then
		addValue = 235 -- Outlands
    elseif (zoneID or 0) == 4 then 
        addValue = 580 -- Northrend
	end
	
	local XP = 0
	if(charLevel == mobLevel) then
		XP = (charLevel * 5) + addValue
	elseif (charLevel < mobLevel) then
		-- Find max mob level. All mobs higher than (charLevel + 4) are worth the same amount.
		local maxMobLevel = mobLevel
		if mobLevel > charLevel + 4 then 
			maxMobLevel = charLevel + 4 
		end
		XP = ((charLevel * 5 + addValue)) * (1 + (0.05 * (maxMobLevel - charLevel)))
	elseif (charLevel > mobLevel) then
		local ZD = XToLevel.Lib:ZeroDifference(charLevel)
		XP = ((charLevel * 5 + addValue)) * (1 - ((charLevel - mobLevel) / ZD)) -- TODO: FIND THE BUG!
	end
	
	return XP * (1 + XToLevel.Lib:GetHeirloomXpBonus())
end

---
-- Gets the percent bonus received from heirloom items.
-- @return float Percentage as 0.0 to 1.0
local heirloom_slot_values = { [3] = 0.1, [5] = 0.1, [11] = 0.05, [12] = 0.05 }
function XToLevel.Lib:GetHeirloomXpBonus()
	local sID, sQuality, sBlackhole;
	local output = 0;
	for slot, value in pairs(heirloom_slot_values) do
		sID = GetInventoryItemID("player", slot)
		if sID then
			sBlackhole, sBlackhole, sQuality = GetItemInfo(sID)
			if sQuality == 7 then
				output = output + value
			end
		end
	end
	return output
end

---
-- Calculates the XP a hunter's pet gains when killing a mob.
---
function XToLevel.Lib:PetXP(playerLevel, petLevel, mobLevel)
	-- Set some default values.
	if playerLevel == nil then
		playerLevel = UnitLevel("player");
	end
	if petLevel == nil then
		petLevel = playerLevel - 1;
	end
	if mobLevel == nil then
		mobLevel = playerLevel;
	end
	return self:MobXP(playerLevel, playerLevel + (mobLevel - petLevel));
end

---
-- Extracts the XP amount from a chat XP gain message, as well as the mob name if
-- the message was generated by a kill, rather then a quest gain.
---
local REGEXP_COMBATLOG_KILL = nil
local REGEXP_COMBATLOG_QUEST = nil
function XToLevel.Lib:ParseChatXPMessage(message)
    local pattern, mob, xp;
	
	--- Check if this is a quest or a mob
	if(string.find(message, ",") == nil) then
		if not REGEXP_COMBATLOG_QUEST then
    		REGEXP_COMBATLOG_QUEST = string.gsub(COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED, "(%%d)", "(%%d+)")
		end
		xp = strmatch(message, REGEXP_COMBATLOG_QUEST);
	else
		if not REGEXP_COMBATLOG_KILL then
	    	REGEXP_COMBATLOG_KILL = string.gsub(COMBATLOG_XPGAIN_FIRSTPERSON, "(%%s)", "(.+)")
	    	REGEXP_COMBATLOG_KILL = string.gsub(REGEXP_COMBATLOG_KILL, "(%%d)", "(%%d+)")
    	end
		mob, xp = strmatch(message, REGEXP_COMBATLOG_KILL);
	end	
	return xp, mob;
end

---
-- Rounds the input number to the given precision.
---
function XToLevel.Lib:round(input, precision, roundDown)
	if input == nil then
		return  nil
	end

	precision = 10^(precision or 2)
	local altered = input * precision
	if roundDown then
		return math.floor(altered) / precision
	else
		if altered - math.floor(altered) >= 0.5 then
			return math.ceil(altered) / precision
		else
			return math.floor(altered) / precision
		end
	end
end

---
-- Formats the input number to a human-readable number. (Adds commas and periods)
---
function XToLevel.Lib:NumberFormat(input) -- /run XToLevel.Messages:Print(NumberFormat(127))
	local strVersion = tostring(input)
	local strLength = strlen(strVersion)
	
	local numVersion = ""
	local fraction = nil
	
	local i = 0
	while i < strLength do
		i = i + 1
		local current = strsub(strVersion, i, i)
		if current == "." then
			fraction = strsub(strVersion, i + 1)
			break
		else
			numVersion = numVersion .. current
		end
	end
	
	local output = ""
	strLength = strlen(numVersion)
	local i = 0
	while i < strLength do
		if i > 0 and mod(i, 3) == 0 then
			output = "," .. output
		end
		output = strsub(numVersion, (strLength - i), (strLength - i)) .. output
		i = i + 1
	end
	if fraction then
		return output .. "." .. fraction
	else
		return output
	end
end

---
-- Shrinks a number to a smaller format. (E.g. 1234000 = 1,23M)
---
local numberUnits = {"", "K", "M", "B"}
function XToLevel.Lib:ShrinkNumber(input)
	input = tonumber(input)
	if input < 100000 then
		return XToLevel.Lib:NumberFormat(input)
	else
		-- local units = {"", "K", "M", "B"}
		local index = 1
		local output = input
		while output > 1000 and index < # numberUnits do
			output = output / 1000
			index = index + 1
		end
		local precision = 2
		if output < 10 then
			precision = 2
		elseif output < 100 then
			precision = 1
		else
			precision = 0
		end
		return XToLevel.Lib:NumberFormat(tostring(XToLevel.Lib:round(output, precision, true))) .. numberUnits[index]
	end
end

---
-- Converts a decimal (base 10) number to a hex (base 16) number.
---
function XToLevel.Lib:DecToHex(IN, minChars)
    local B,K,OUT,I,D=16,"0123456789ABCDEF","",0
    while IN>0 do
        I=I+1
        IN,D=math.floor(IN/B),mod(IN,B)+1
        OUT=strsub(K,D,D)..OUT
		if I > 1000 then 
			break
		end
    end
	if minChars and tonumber(minChars) > 0 then
		I = 0
		while strlen(OUT) < tonumber(minChars) do
			OUT = "0" .. OUT
			if I > 1000 then 
				break
			end
		end
	end
    return OUT
end

---
-- Gets a color value to represent the given progress. (Green for 100%, red for 0%)
---
XToLevel.Lib.progressColor = { pro=0, hex=0, rgb={ r=0, g=0, b=0 } }
function XToLevel.Lib:GetProgressColor(pro)
	if self.progressColor.pro ~= pro then
		local lh = pro <= 50 and true or false
		self.progressColor.pro = pro
		self.progressColor.rgb.r = math.floor((lh and 255) or (255 - (((pro - 50) / 50) * 255)))
		self.progressColor.rgb.g = math.floor((lh and ((pro / 50) * 255)) or 255)
		self.progressColor.rgb.b = 0
		self.progressColor.hex = XToLevel.Lib:DecToHex(self.progressColor.rgb.r, 2) .. XToLevel.Lib:DecToHex(self.progressColor.rgb.g, 2) .. XToLevel.Lib:DecToHex(self.progressColor.rgb.b, 2)
	end
    return self.progressColor.hex, self.progressColor.rgb
end
XToLevel.Lib.progressColorS = { pro=0, proa=0, hex=0, rgb={ r=0, g=0, b=0 } } -- TODO: Complete and test
function XToLevel.Lib:GetProgressColor_Soft(progress)
    local hex
    local rgb = { r=0, g=0, b=0 }
    local pro = tonumber(progress)
    local proa = math.abs(progress-50)
    rgb.r = math.floor((pro <= 66 and 255) or (255 - (153 * ((pro-66) / 34))))
    rgb.g = math.floor((pro >= 50 and 255) or (255 - (153 * ((50-pro) / 50))))
    rgb.b = math.floor((proa >= 16 and 102) or (102 * (proa / 16)))
    hex = XToLevel.Lib:DecToHex(rgb.r, 2) .. XToLevel.Lib:DecToHex(rgb.g, 2) .. XToLevel.Lib:DecToHex(rgb.b, 2)
    return hex, rgb
end

---
-- Gets the minimum amount of XP that would be considered a valid BG objective reward.
---
function XToLevel.Lib:GetBGObjectiveMinXP()
	if XToLevel.Player.level > 10 then
		local bgMin = {
			["Alterac Valley"] = 750,
			["Isle of Conquest"] = 250,
			["Strand of the Anchients"] = 500,
			["Eye of the Storm"] = 500,
			["Arathi Basin"] = 250,
			["Warsong Gulch"] = 250,
		}
		local zone = GetRealZoneText()
		local zoneMin = 500
		
		for name, value in pairs(bgMin) do
			if name == zone then
				zoneMin = value
			end
		end
		
		local playerMultiplier = (XToLevel.Player.level - 10) / (XToLevel.Player.maxLevel - 10)
		
		return (XToLevel.Lib:round(zoneMin * playerMultiplier, 0))
	else
		return 0
	end
end

---
-- Gets the appropriate tooltip anchor point for the give frame. (E.g. "TOPLEFT", "BOTTOMRIGHT")
---
function XToLevel.Lib:FindAnchor(frame)
	local xcenter, ycenter = frame:GetCenter()
	if not xcenter or not ycenter then
		return "TOPLEFT", "BOTTOMLEFT" 
	end
	local hor = (xcenter > UIParent:GetWidth() * 2 / 3) and "RIGHT" or (xcenter < UIParent:GetWidth() / 3) and "LEFT" or ""
	local ver = (ycenter > UIParent:GetHeight() / 2) and "TOP" or "BOTTOM"
	return ver..hor, frame, (ver == "BOTTOM" and "TOP" or "BOTTOM")..hor
end

function XToLevel.Lib:ReverseAnchor(anchor)
    if string.find(anchor, "TOP") ~= nil then
        anchor = string.gsub(anchor, "TOP", "BOTTOM")
    else
        anchor = string.gsub(anchor, "BOTTOM", "TOP")
    end
    if string.find(anchor, "LEFT") ~= nil then
        anchor = string.gsub(anchor, "LEFT", "RIGHT")
    else
        anchor = string.gsub(anchor, "RIGHT", "LEFT")
    end
    return anchor
end

---
-- Splits the str on the delim char, maxNb number of times.
-- http://lua-users.org/wiki/SplitJoin
---
function XToLevel.Lib:Split(str, delim, maxNb)
    -- Eliminate bad cases...
    --if string.find(str, delim) == nil then
    --    return { str }
    --end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gmatch(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    if # result == 0 then
        result[1] = str;
    end
    return result
end

function XToLevel.Lib:TimeFormat(timestamp)
	if type(timestamp) == "number" and timestamp > 0 then
		local hour = date("%H", timestamp)
		local minute = date("%M", timestamp)
		local second = date("%S", timestamp)
		
		if not hour or not minute or not second then
			return "NaN"
		else
			if strsub(hour, 1, 1) == "0" then
				hour = strsub(hour, 2, 2)
			end
			if strsub(minute, 1, 1) == "0" then
				minute = strsub(minute, 2, 2)
			end
			if strsub(second, 1, 1) == "0" then
				second = strsub(second, 2, 2)
			end
			
			local output = ""
			if minute == "0" and hour == "0" then
				return second .. "s"
			elseif hour == "0" then
				return minute .. "m " .. second .. "s"
			else
				return hour .. "h " .. minute .. "m " .. second .. "s"
			end
		end
	else
		return "NaN"
	end	
end
