---
-- Contains definitions for the Average Information windows
-- @file XToLevel.Average.lua
-- @release 3.3.3_13r
-- @copyright Atli Þór (atli@advefir.com)
---
XToLevel.Average =
{
    activeAPI = "Blocky",
    knownAPIs = {
        "Blocky",
        "Classic"
    }
}

---
-- Initialize the Average control methods. This basically just sets
-- which API should be used.
function XToLevel.Average:Initialize()
    self.activeAPI = self.knownAPIs[sConfig.averageDisplay.mode]
    for index, name in ipairs(self.knownAPIs) do
        XToLevel.AverageFrameAPI[name]:Initialize()
    end
    
    self:Update()
end

---
-- Updates the active AverageFrame window.
function XToLevel.Average:Update()
    if self.activeAPI ~= self.knownAPIs[sConfig.averageDisplay.mode] then
        for index, name in ipairs(self.knownAPIs) do
	        XToLevel.AverageFrameAPI[name]:Update()
	    end
	    if self.knownAPIs[sConfig.averageDisplay.mode] ~= nil then
            self:AlignBoxes(self.activeAPI, self.knownAPIs[sConfig.averageDisplay.mode])
            self.activeAPI = self.knownAPIs[sConfig.averageDisplay.mode]
        end
    end
    if self.knownAPIs[sConfig.averageDisplay.mode] ~= nil then
	    if XToLevel.Player.isActive then
		    XToLevel.AverageFrameAPI[self.activeAPI]:SetKills       (XToLevel.Player:GetAverageKillsRemaining() or nil)
		    XToLevel.AverageFrameAPI[self.activeAPI]:SetQuests      (XToLevel.Player:GetAverageQuestsRemaining() or nil)
		    XToLevel.AverageFrameAPI[self.activeAPI]:SetDungeons    (XToLevel.Player:GetAverageDungeonsRemaining() or nil)
		    XToLevel.AverageFrameAPI[self.activeAPI]:SetBattles     (XToLevel.Player:GetAverageBGsRemaining() or nil)
		    XToLevel.AverageFrameAPI[self.activeAPI]:SetObjectives  (XToLevel.Player:GetAverageBGObjectivesRemaining() or nil)
		    XToLevel.AverageFrameAPI[self.activeAPI]:SetProgress    (XToLevel.Lib:round((XToLevel.Player.currentXP or 0) / (XToLevel.Player.maxXP or 1) * 100, 1))
			--XToLevel.AverageFrameAPI[self.activeAPI]:SetTimer		Done separately for performance reasons.
	    end
	    if XToLevel.Pet.isActive or XToLevel.Pet.hasBeenActive then
	        XToLevel.AverageFrameAPI[self.activeAPI]:SetPetKills    (XToLevel.Pet:GetAverageKillsRemaining() or nil);
	        XToLevel.AverageFrameAPI[self.activeAPI]:SetPetProgress (floor(XToLevel.Pet.xp / XToLevel.Pet.maxXP * 100));
	    end
	    XToLevel.AverageFrameAPI[self.activeAPI]:Update()
    end
end

function XToLevel.Average:UpdateTimer(secondsToLevel)
    if self.knownAPIs[sConfig.averageDisplay.mode] ~= nil then
        if type(secondsToLevel) == "number" and secondsToLevel > 0 and tostring(secondsToLevel) ~= "1.#INF" then
            local formattedTime
            if secondsToLevel < 60 then
                formattedTime = string.format("%ds", tonumber(date("%S", secondsToLevel)))
            elseif secondsToLevel < 3600 then
                local m, s
                m = tonumber(date("%M", secondsToLevel))
                s = tonumber(date("%S", secondsToLevel))
                if s > 30 then
                    m = m + 1
                end
                formattedTime = string.format("%dm",m)
            else
                local h, m
                h = tonumber(date("%H", secondsToLevel))
                m = tonumber(date("%M", secondsToLevel))
                if m > 30 then
                    h = h + 1
                end
                formattedTime = string.format("%dh",h)
            end
            XToLevel.AverageFrameAPI[self.activeAPI]:SetTimer(formattedTime)
        else
            XToLevel.AverageFrameAPI[self.activeAPI]:SetTimer("N/A")
        end
    end
end

---
-- Aligns the boxes, placing the "child" on top of the "parent"
-- @param parent The box that marks where the child should be placed.
-- @param child The box that should be moved.
function XToLevel.Average:AlignBoxes(parent, child)
    if parent ~= child and parent ~= nil and child ~= nil then
	    local parentAPI = XToLevel.AverageFrameAPI[parent]
	    local childAPI = XToLevel.AverageFrameAPI[child]
	    childAPI:AlignTo(parentAPI)
    end
end