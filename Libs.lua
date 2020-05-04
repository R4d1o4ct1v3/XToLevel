﻿---
-- A collection of globally available functions, used througout the addon.
-- @file Libs.lua
-- @release 4.1.0_26
-- @author Atli Þór (r4d1o4ct1v3v3@gmail.com)
---
--module "XToLevel.Lib" -- For documentation purposes. Do not uncomment!

--[[
 Functions:
   ZoneID() - Returns the ID of the zone the player is current in
   IsPlayerRafEligable() - Determines whether the player is eligable for the 3x RAF bonus.
   IsRafApplied() - Determines whether the RAF bonus should be applied.
   IsInBattleground() - Determines whether the player is currently inside a battleground zone.
   ShowBattlegroundData() - Determines whether the BG data should be displayed in the tooltip.
   ShowDungeonData() - Determines whether the Dungeon data should be displayed in the tooltip.
   MobXP(charlvl, moblvl) - Calculates the amount of XP the mob is worth to the player.
   GetChatXPRegexp(isQuest) - Retrieves the proper regexp to parse a chat XP message.
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

function XToLevel.Lib:IsClassic()
	local interfaceNumber = select(4, GetBuildInfo())
	return interfaceNumber < 80000
	-- If this check ever needs an update... I guess the corona virus didn't turn into a zombie apocalypse?
end

---
-- Either returns the name of the ongoing battleground, or a nil of no battleground is in progress.
function XToLevel.Lib:GetCurrentBattlegroundName()
	local bgName = nil
	for index=1,GetMaxBattlefieldID() do
		local status, name = GetBattlefieldStatus(index)
		if status == "active" then
			bgName = name
		end
	end
	return bgName
end

---
-- Determines whether item fitted in the given slot is an heirloom.
-- NOTE that it doesn't check if the item has any XP bonus on it.
-- @param slotType See https://wow.gamepedia.com/InventorySlotId#Values (Use the string values, e.g: "HEADSLOT")
function XToLevel.Lib:IsActiveHeirloom(slotType)
	if not self:IsClassic() then
		local itemID = GetInventoryItemID("player", GetInventorySlotInfo(slotType))
		if not itemID then
			return false
		end
		
		local heirloomInfo = {C_Heirloom.GetHeirloomInfo(itemID)}
		if # heirloomInfo == 0 then
			return false
		end
		
		if heirloomInfo[10] < XToLevel.Player.level then
			return false
		end
		
		return true
	end
end

---
-- Checks for heirlooms, and returns a multiplier value that should be used with any 
-- XP estimates that are not based on collected data. (As collected data will include this already.)
function XToLevel.Lib:GetHeirloomMultiplier()
	if not self:IsClassic() then
		-- Slots that always have 10% xp bonuses on them.
		local checkList = {
			{slot = "HEADSLOT", modifier = 0.1},
			{slot = "SHOULDERSLOT", modifier = 0.1},
			{slot = "CHESTSLOT", modifier = 0.1},
			{slot = "LEGSSLOT", modifier = 0.1},
			{slot = "BACKSLOT", modifier = 0.05},
			{slot = "FINGER0SLOT", modifier = 0.05},
			{slot = "FINGER1SLOT", modifier = 0.05},
		}

		local multiplier = 1.0
		for _, d in pairs(checkList) do
			if self:IsActiveHeirloom(d.slot) then
				multiplier = multiplier + d.modifier
			end
		end
		
		-- Temporarily adding a flat 100% increase here for the "Winds of Wisdom" buff
		-- added by Blizzard in March 2020. Should be removed after April 20th, 2020.
		-- UPDATE: buff extended until Shadowland pre-patch. Date not announced. Needs
		-- to be updated at that point.
		multiplier = multiplier + 1

		return multiplier
	else
		return 1
	end
end

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
-- Returns the ID of the zone the player is currently in.
-- Borrowed from: https://www.wowinterface.com/forums/showpost.php?p=328804&postcount=4
-- /dump C_Map.GetMapInfo(C_Map.GetMapInfo(XToLevel.Lib:ZoneID())["parentMapID"])["name"]
---
function XToLevel.Lib:ZoneID()
	local mapID = C_Map.GetBestMapForUnit("player")
	if mapID then
		local info = C_Map.GetMapInfo(mapID)
		if info then
			while info['mapType'] and info['mapType'] > 3 do
				info = C_Map.GetMapInfo(info['parentMapID'])
			end
			return info['mapID']
		end
	end
	return 1
end

---
-- Converts a classification between it's name and it's number. If you pass the
-- function a name, it will return and number, and the same in reverse.
-- If the input can not be converted, the function returns nil.
function XToLevel.Lib:ConvertClassification(classification)
    if type(classification) == "number" and classification > 0 and classification <= # XToLevel.UNIT_CLASSIFICATIONS then
        return XToLevel.UNIT_CLASSIFICATIONS[classification]
    elseif type(classification) == "string" then
        local out = nil
        for i, v in ipairs(XToLevel.UNIT_CLASSIFICATIONS) do
            if v == classification then
                out = i
            end
        end
        return out
    end
    return nil
end

---
-- Determines whether the player is eligable for the 3x Recriuit A Friend bonus.
---
function XToLevel.Lib:IsPlayerRafEligable()
    local numPartyMembers = GetNumSubgroupMembers();
    if numPartyMembers > 0 then
        local memberID = 1;
        while memberID <= numPartyMembers do
            local member = "party" .. memberID;
            if UnitInParty(member) then
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
    return XToLevel.db.profile.general.rafEnabled and self:IsPlayerRafEligable();
end

---
-- Determines whether the player is currently inside a battleground zone.
---
function XToLevel.Lib:IsInBattleground()
	local currentZone = GetRealZoneText()
	for key, val in ipairs(XToLevel.BG_NAMES) do
		if val == currentZone then
			return true
		end
	end
	return false
end

function XToLevel.Lib:ShowBattlegroundData()
	return ((XToLevel.db.profile.ldb.tooltip.showBGInfo and XToLevel.Player.level >= 10) and (XToLevel.Player.level < XToLevel.Player.maxLevel or (# XToLevel.db.char.data.bgList) > 0))

end

function XToLevel.Lib:ShowDungeonData()
    return ((XToLevel.db.profile.ldb.tooltip.showDungeonInfo) and (XToLevel.Player.level < XToLevel.Player.maxLevel or (# XToLevel.db.char.data.dungeonList) > 0))
end

---
-- Calculates the XP gained from killing a mob
-- First return value is the XP.
-- Second return value indicates if it's an "exact" value based on recorded data, or an "estimate" based on mob level.
---
function XToLevel.Lib:MobXP(mobName, mobLevel)
	if type(mobName) ~= "string" then
		mobName = nil
	end

	local charLevel = UnitLevel("player")
	if type(mobLevel) ~= "number" then mobLevel = charLevel end
    
    if mobName ~= nil then
        for _, mobData in pairs(XToLevel.db.char.data.npcXP) do
			if mobData.name == mobName and mobData.level == mobLevel then
				return mobData.xp, "exact"
			end
        end
	end
	
	if mobLevel >= charLevel - 5 then
		-- Standard base formula for all zones now. Previously the addition would vary.
		local baseXP = (charLevel * 5) + 45
		local heirloomBonus = self:GetHeirloomMultiplier()

		-- Mobs that are higher level than the player seem to always add 5% to the base
		-- value, even at low level. (Slight variations at the lowest level, but not worth coding around now)
		-- Mobs that are lower level seem to subtract 7% for each level at level 60 or higher. Levels
		-- prior to that seem to increase that % on a gradient down to around 27% at level 1. 
		local levelDelta = mobLevel - charLevel
		if levelDelta ~= 0 then
			local modifier = 0.05 -- Default for higher levels
			if not self:IsClassic() then
				if levelDelta < 0 then
					for _, loop in ipairs(XToLevel.XP_MULTIPLIERS) do
						if loop.level <= charLevel then
							modifier = loop.modifier
						else
							break
						end
					end
				end
			else 
				-- So far, in Classic, I've observed a -20% per level below, and +5% per level above.
				-- Will update as I level on Classic if that changes at high level.
				if levelDelta < 0 then
					-- XToLevel.XP_CLASSIC_ZERO_DIFFERENCE
					for _, loop in ipairs(XToLevel.XP_CLASSIC_ZERO_DIFFERENCE) do
						if loop.level <= charLevel then
							modifier = 1/loop.divider
						else
							break
						end
					end
				end
			end
			local multiplier = (modifier * levelDelta) + 1
			return floor((baseXP * multiplier * heirloomBonus) + 0.5), "estimate"
		else
			return floor((baseXP * heirloomBonus) + 0.5), "estimate"
		end
    else
        return 0, "exact"; -- Return 0 instead of for backwards compatibility. The function always returned a number back when it was a static formula.
    end
end

---
-- Gets the gathering XP expected for a player at the given level.
function XToLevel.Lib:GatheringXP(playerLevel)
	if type(playerLevel) ~= "number" then
		playerLevel = UnitLevel("player")
	end
	local questXP = XToLevel.QUEST_XP[playerLevel]
	if type(questXP) ~= "number" then
		return 0
	end
	-- Panderia and Cataclysm zones seem to defy the usual gathering XP values.
	-- So I'm hard-coding those lower values here to correct for this.
	if playerLevel >= 80 and playerLevel < 90 then
		return 95 -- Seems to always be 95 in these areas, reglardless of anything.
	end
	local baseXP = questXP / 10
	local rounding = 5
	if baseXP >= 985 then
		rounding = 50
	elseif baseXP > 500 then
		rounding = 25
	elseif baseXP  > 100 then
		rounding = 10
	end
	return self:round(baseXP / rounding) * rounding
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

function XToLevel.Lib:GetChatXPRegexp(isQuest)
	local inInstance, itype = IsInInstance()
    local inGroup =  GetNumSubgroupMembers() > 0
	local apiRegexp = nil
	local isRested = GetXPExhaustion()
	if not isQuest then
		if inInstance and isRested then
			if itype == "party" and inGroup then
				apiRegexp = COMBATLOG_XPGAIN_EXHAUSTION1_GROUP
			elseif itype == "raid" and inGroup then
				apiRegexp = COMBATLOG_XPGAIN_EXHAUSTION1_RAID
			else
				apiRegexp = COMBATLOG_XPGAIN_EXHAUSTION1
			end
		elseif inInstance and not isRested then
			if itype == "party" and inGroup then
				apiRegexp = COMBATLOG_XPGAIN_FIRSTPERSON_GROUP
			elseif itype == "raid" and inGroup then
				apiRegexp = COMBATLOG_XPGAIN_FIRSTPERSON_RAID
			else
				apiRegexp = COMBATLOG_XPGAIN_FIRSTPERSON
			end
		else
			if isRested then
				apiRegexp = COMBATLOG_XPGAIN_EXHAUSTION1
			else
				apiRegexp = COMBATLOG_XPGAIN_FIRSTPERSON
			end
		end
	else
		-- Rested doesn't affect quests... daaa!!
		apiRegexp = COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED
	end
	apiRegexp = string.gsub(apiRegexp, "%(", "%%(")
	apiRegexp = string.gsub(apiRegexp, "%)", "%%)")
	apiRegexp = string.gsub(apiRegexp, "%+", "%%+")
	apiRegexp = string.gsub(apiRegexp, "%-", "%%-")
	apiRegexp = string.gsub(apiRegexp, "%%%d?%$?s", "(.+)")
	apiRegexp = string.gsub(apiRegexp, "%%%d?%$?d", "(%%d+)")
	return apiRegexp
end

---
-- Extracts the XP amount from a chat XP gain message, as well as the mob name if
-- the message was generated by a kill, rather then a quest gain.
---
function XToLevel.Lib:ParseChatXPMessage(message, isQuest)
	local pattern = XToLevel.Lib:GetChatXPRegexp(isQuest)
	local mob, xp = strmatch(message, pattern);
	
	-- If it is a quest, the XP will be return first and there will be no name. Swap them.
	if tonumber(mob) then
		xp = tonumber(mob)
		mob = nil
	end
	
	if not tonumber(xp) then
		xp = strmatch(message, "(%d+)")
		-- Parsing has failed.
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
	if precision == nil then
		precision = 0
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
    if pro <= 0 then pro = 1 end -- 0 doesn't play well with the formulas. CBA to fix that so I just bypass it like so.
    if pro > 100 then pro = 100 end
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

function XToLevel.Lib:GetDifficoultyColor(levelDifference)
    
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

---
-- Formats a timestamp into a human-readable Date-Time string
-- following a "5d 12h 36m 48s" format.
function XToLevel.Lib:TimeFormat(timestamp)
	if type(timestamp) == "number" and timestamp > 0 then
        local day = floor(timestamp / 86400)
		local hour = floor((timestamp - (day * 86400)) / 3600)
		local minute = floor((timestamp - (day * 86400) - (hour * 3600)) / 60)
		local second = floor(mod(timestamp, 60))
		
		if day < 0 then
			return "NaN"
		else
            local output = ""
            if day > 0 then
               output = day .. "d " 
            end
            if hour > 0 or output ~= "" then
               output = output .. hour .. "h " 
            end
            if minute > 0 or output ~= "" then
               output = output .. minute .. "m " 
            end
            if second > 0 or output ~= "" then
               output = output .. second .. "s" 
            end
            return output
		end
	else
		return "NaN"
	end	
end
