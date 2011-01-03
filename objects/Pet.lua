---
-- Defines the Pet functionality.
-- functionality.
-- @file XToLevel.Pet.lua
-- @release 4.0.1_23
-- @copyright Atli Þór (atli.j@advefir.com)
---
XToLevel.Pet = {
	isActive = false,
	hasBeenActive = false,
    isDismissed = false,
    guid = nil, -- I expecte this to be unique and perminent per pet, even x-session.
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
        
        local oldXP, oldLevel, oldName
        local output = {}
        
        oldGUID = self.guid
        oldName = self.name
		oldXP = self.xp
        oldLevel = self.level
	
        self.guid = UnitGUID("pet")
		self.name = UnitName("pet")
		self.level = UnitLevel('pet')
		self.maxLevel = XToLevel.Player.level or UnitLevel('player')
		self.xp, self.maxXP = GetPetExperience()
        
        -- If the unit name is "nil" then the pet has been dismissed or otherwise
        -- made unavailable. (Like, when mounting) In this case just do nothing.
        -- This will allow the player to see the data for their previous pet.
        -- However, flag the isActive as false, but the hasBeenActive flag to true.
        -- Then when a valid name is received, if it differs from the old one a
        -- new pet has bee summoned.
        if type(self.name) ~= "string" then
            self.isDismissed = true
            self.name = oldName
        
        -- If the unit name is "Unknown" the pet info may be incorrect. In this 
        -- case, the server may simply be slow to respond. - Best to just reuse
        -- the existing name if it is available, or if not just use Unknown as
        -- the name. The main script should update the name as soon as it becomes
        -- available.
        elseif self.name == "Unknown" then
            if type(oldName) == "string" and oldName ~= "Unknown" then
                self.name = oldName
            end
            self.isDismissed = false
            
        -- A valid name has been received. Simply use it!
        else
            self.isDismissed = false
        end
		
		if self.level < self.maxLevel then
			self.isActive = true;
			self.hasBeenActive = true;
		else
			self.isActive = false;
			self.hasBeenActive = false;
		end
        
		if oldXP and self.name ~= "Unknown" and self.guid ~= nil and self.guid == oldGUID then
			output.xp = self.xp - oldXP
			-- Make sure this falls within realistic gains from a kill.
			-- Otherwise this may be an initialization update.
			if output.xp > 0 and output.xp < (XToLevel.Lib:PetXP(XToLevel.Player.level, self.level, XToLevel.Player.level) * 3) then
                console:log("Adding pet kill: " .. tostring(output.xp))
				self:AddKill(output.xp)
			end
        else
            output.xp = 0
		end
        
        self.killAverage = nil
		
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
        if self.name == "Unknown" then
            self:Update() -- Try to refresh the data from the server.
            if self.name == "Unknown" then
                -- Return a generic result.
                self.killAverage = nil
                return XToLevel.Lib:PetXP(XToLevel.Player.level, self.level, XToLevel.Player.level)
            end
        end
        
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