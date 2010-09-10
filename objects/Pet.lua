---
-- Defines the Pet functionality.
-- functionality.
-- @file XToLevel.Pet.lua
-- @release 3.3.3_13r
-- @copyright Atli Þór (atli@advefir.com)
---
XToLevel.Pet = {
	isActive = false,
	hasBeenActive = false,
	name = nil,
	level = nil,
	xp = nil,
	maxXP = nil,
	maxLevel = nil,
	killList = nil,
	killAverage = nil,
	killListLength = 100,
	
	nextMobName = nil, -- The name of the next mob to be announced... Dirty workaround :/
	
	---
	-- function description
	Initialize = function(self)
		-- Make sure the player has a pet
		if not self:IsHunterPet() then
			return false;
		end
        
        -- Update the object with the data for the current pet
        self:Update()
        self.killAverage = nil
        
        if not sData.pet.killList[self.name] then
            sData.pet.killList[self.name] = { }
        end
	end,
	
	-- Updates the pet xp info
	---
	-- function description
	Update = function(self)
		if not self:IsHunterPet() then
			return false;
		end
        
        local oldXP, oldLevel
        local output = {}
        
		oldXP = self.xp
        oldLevel = self.level
	
		self.name = UnitName("pet")
		self.level = UnitLevel('pet')
		self.maxLevel = XToLevel.Player.level or UnitLevel('player')
		self.xp, self.maxXP = GetPetExperience()
		
		if self.level < self.maxLevel then
			self.isActive = true;
			self.hasBeenActive = true;
		else
			self.isActive = false;
			self.hasBeenActive = false;
		end
		
		if oldXP then
			output.xp = self.xp - oldXP
			-- Make sure this falls within realistic gains from a kill.
			-- Otherwise this may be an initialization update.
			if output.xp < (XToLevel.Lib:PetXP(XToLevel.Player.level, self.level, XToLevel.Player.level) * 3) then
				self:AddKill(output.xp)
			end
        else
            output.xp = 0
		end
        if oldLevel and oldLevel == (self.level - 1) then
            output.gainedLevel = true
        else
            output.gainedLevel = false      
        end
		
		return output
	end,
    
    -- Check whether the pet is a hunter's pet.
    ---
    -- function description
    IsHunterPet = function(self)
        local hasUI, isHunterPet = HasPetUI();
		if hasUI then 
            if isHunterPet then
                return true;
            else
                return false;
            end
		else
            return false;
        end
    end,
	
	---
	-- function description
	AddKill = function(self, xp)
		if not sData.pet.killList then
			sData.pet.killList = { }
		end
		if not sData.pet.killList[self.name] then
			sData.pet.killList[self.name] = {}
		end
		if xp > 0 then
			self.killAverage = nil
			table.insert(sData.pet.killList[self.name], 1, xp)
			if(# sData.pet.killList[self.name] > self.killListLength) then
				table.remove(sData.pet.killList[self.name])
			end
		end
	end,
	
	---
	-- function description
	GetAverageKillXP = function(self)
		if self.killAverage == nil then
			if sData.pet.killList[self.name] and (# sData.pet.killList[self.name] > 0) then
				local total = 0
				local maxUsed = # sData.pet.killList[self.name]
				if maxUsed > sConfig.averageDisplay.petKillListLength then
					maxUsed = sConfig.averageDisplay.petKillListLength
				end
				for index, value in ipairs(sData.pet.killList[self.name]) do
					if index > maxUsed then
						break;
					end
					total = total + (value or 0)
				end
				if total > 0 then
					self.killAverage = (total / maxUsed);
				else
					self.killAverage = XToLevel.Lib:PetXP(XToLevel.Player.level, self.level, XToLevel.Player.level)
					sData.pet.killList[self.name] = { }
					table.insert(sData.pet.killList[self.name], tonumber(self.killAverage))
				end
			else
				self.killAverage = XToLevel.Lib:PetXP(XToLevel.Player.level, self.level, XToLevel.Player.level)
			end
		end
		return self.killAverage
	end,
	
	---
	-- function description
	GetAverageKillsRemaining = function(self)
		local xpRemaining, killsRemaining;

		xpRemaining = (self.maxXP or 0) - (self.xp or 0)
		killsRemaining = ceil(xpRemaining / self:GetAverageKillXP());
		
		return killsRemaining;
	end,
	
	---
	-- function description
	GetProgressAsPercentage = function(self, fractions)
       if type(fractions) ~= "number" or fractions <= 0 then
            fractions = 0
        end
        return XToLevel.Lib:round((self.xp or 0) / (self.maxXP or 1) * 100, fractions)
    end,
	
	---
	-- function description
	GetProgressAsBars = function(self, fractions)
	   if type(fractions) ~= "number" or fractions <= 0 then
            fractions = 0
        end
        local barsRemaining = ceil((100 - ((self.xp or 0) / (self.maxXP or 1) * 100)) / 5, fractions)
        return barsRemaining
	end,
	
	GetXpRemaining = function(self)
		return self.maxXP - self.xp
	end,
	
	---
	-- function description
	ClearKillList = function (self, initialValue)
		sData.pet.killList = { }
        if initialValue ~= nil and tonumber(initialValue) > 0 then
            table.insert(sData.pet.killList, tonumber(initialValue))
        end
	end,
	
	---
	-- function description
	GetMobName = function(self)
		if self.nextMobName then
			local name = self.nextMobName
			self.nextMobName = nil
			return name
		else
			return strlower(L["Kills"])
		end
	end,
	
	---
	-- function description
	GetName = function(self)
		if not self.name then
			self.name = UnitName("pet")
		end
		return self.name -- /run XToLevel.Messages:Print(XToLevel.Pet:GetName())
	end,
    
    --
    -- Clear methods
    --
    ---
    -- function description
    ClearKills = function(self)
        sData.pet.killList = { }
        self.killAverage = nil;
    end,
    
    ---
    -- Sets the number of kills used for average calculations
    SetKillAverageLength = function(self, newValue)
    	sConfig.averageDisplay.petKillListLength = newValue
    	self.killAverage = nil
    	XToLevel.Average:Update()
    	XToLevel.LDB:BuildPattern()
    	XToLevel.LDB:Update()
    end,
};