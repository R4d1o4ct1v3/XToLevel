---
-- Contains definitions for Chat and Floating Error window message controls.
-- @file objects/Messages.lua
-- @release 3.3.3_13r
-- @copyright Atli Þór (atli@advefir.com)
---
--module "XToLevel.Messages" -- For documentation purposes. Do not uncomment!

XToLevel.Messages = 
{  
    -- A shortcut to add a message to the default chat window
    printStyle = {
        white = { r=1.0, g=1.0, b=1.0, group=54, addToStart=false },
        gray = { r=0.5, g=0.5, b=0.5, group=53, addToStart=false }
    },
    
    ---
    -- function description
    Print = function(self, message, style, color)
 		r, g, b = unpack(color or {1, 1, 1});
        if style == nil then
            style = self.printStyle.white
        end
        DEFAULT_CHAT_FRAME:AddMessage(message, r, g, b, style.group, style.addToStart);
    end,
	
	---
	-- function description
	Debug = function(self, message)
		if sConfig.general.showDebug then
			self:Print(message, self.printStyle.gray, {0.5, 0.5, 0.5})
		end
	end,

    ---
    -- Controls for the floating display
    -- The settings check is added here to simplify the calling code.
    Floating = 
    {
        killStyle =  { r=0.5, g=1.0, b=0.7, group=56, fade=5 },
		petStyle =  { r=1.0, g=0.7, b=0.5, group=57, fade=5 },
        questStyle = { r=0.5, g=1.0, b=0.7, group=56, fade=5 },
        levelStyle = { r=0.35, g=1.0, b=0.35, group=56, fade=6 },
        
        ---
        -- function description
        PrintKill = function(self, mobName, mobsRequired)
            if sConfig.messages.playerFloating then
                local message = mobsRequired .." ".. mobName .. L["Kills Needed"]
                self:Print(message, sConfig.messages.colors.playerKill, self.killStyle)
            end
        end,
		
		---
		-- function description
		PrintPetKill = function(self, petName, mobName, mobsRequired)
            if sConfig.messages.petFloating then
                local message = mobsRequired .. " " .. mobName .. L["Pet Kills Needed"] .. petName
                self:Print(message, sConfig.messages.colors.petKill, self.petStyle)
            end
        end,
        
        ---
        -- function description
        PrintQuest = function(self, questsRequired)
            if sConfig.messages.playerFloating then
                local message = questsRequired .. L["Quests Needed"]
                self:Print(message, sConfig.messages.colors.playerQuest, self.questStyle)
            end
        end,
		
		---
		-- function description
		PrintBattleground = function(self, bgsRequired)
            if sConfig.messages.playerFloating then
                local message = bgsRequired .. L["Battlegrounds Needed"]
                self:Print(message, sConfig.messages.colors.playerBattleground, self.questStyle)
            end
        end,
		---
		-- function description
		PrintBGObjective = function(self, bgsRequired)
            if sConfig.messages.playerFloating and sConfig.messages.bgObjectives then
                local message = bgsRequired .. L["Battleground Objectives Needed"]
                self:Print(message, sConfig.messages.colors.playerBattleground, self.questStyle)
            end
        end,
        
        ---
        -- function description
        PrintDungeon = function(self, remaining)
            if sConfig.messages.playerFloating then
                local message = remaining .. L["Dungeons Needed"]
                self:Print(message, sConfig.messages.colors.playerDungeon, self.questStyle)
            end
        end,
        
        ---
        -- function description
        PrintLevel = function(self, level)
            if sConfig.messages.playerFloating then
                local message = L["Level Reached"]
                self:Print(message, sConfig.messages.colors.playerLevel, self.levelStyle)
            end
        end,
        
        ---
        -- function description
        PrintPetLevel = function(self, petName)
            if sConfig.messages.petFloating then
                local message = petName .. L["Pet Level Reached"]
                self:Print(message, sConfig.messages.colors.playerLevel, self.levelStyle)
            end
        end,
        
        ---
        -- function description
        Print = function(self, text, color, style)
        	local r, g, b = unpack(color or {1, 0.75, 0.35})
			if type(style) ~= "table" then
				style = self.questStyle
			end
            UIErrorsFrame:AddMessage(text, r, g, b, style.group, style.fade);
        end
    },
    
    ---
    -- Controls for the chat display
    ---
    Chat = 
    {
        killStyle =  { r=0.5, g=1.0, b=0.7, group=56, addToStart=false },
		petStyle =  { r=1.0, g=0.7, b=0.5, group=57, fade=5, addToStart=false },
        questStyle = { r=0.5, g=1.0, b=0.7, group=56, addToStart=false },
        levelStyle = { r=0.35, g=1.0, b=0.35, group=56, addToStart=false},
        
        ---
        -- function description
        PrintKill = function(self, mobName, mobsRequired)
            if sConfig.messages.playerChat then
                local message = mobsRequired .." ".. mobName .. L["Kills Needed"]
                XToLevel.Messages:Print(message, self.killStyle, sConfig.messages.colors.playerKill)
            end
        end,
		
		---
		-- function description
		PrintPetKill = function(self, petName, mobName, mobsRequired)
            if sConfig.messages.petChat then
                local message = mobsRequired .. " " .. mobName .. L["Pet Kills Needed"] .. petName
                XToLevel.Messages:Print(message, self.petStyle, sConfig.messages.colors.petKill)
            end
        end,
        
        ---
        -- function description
        PrintQuest = function(self, questsRequired)
            if sConfig.messages.playerChat then
                local message = questsRequired .. L["Quests Needed"]
                XToLevel.Messages:Print(message, self.questStyle, sConfig.messages.colors.playerQuest)
            end
        end,
		
		---
		-- function description
		PrintBattleground = function(self, bgsRequired)
            if sConfig.messages.playerChat then
                local message = bgsRequired .. L["Battlegrounds Needed"]
                XToLevel.Messages:Print(message, self.questStyle, sConfig.messages.colors.playerBattleground)
            end
        end,
		---
		-- function description
		PrintBGObjective = function(self, bgsRequired)
            if sConfig.messages.playerChat and sConfig.messages.bgObjectives then
                local message = bgsRequired .. L["Battleground Objectives Needed"]
                XToLevel.Messages:Print(message, self.questStyle, sConfig.messages.colors.playerBattleground)
            end
        end,
        
        ---
        -- function description
        PrintDungeon = function(self, remaining)
            if sConfig.messages.playerChat then
                local message = remaining .. L["Dungeons Needed"]
                XToLevel.Messages:Print(message, self.questStyle, sConfig.messages.colors.playerDungeon)
            end
        end,
        
        ---
        -- function description
        PrintLevel = function(self, level)
            if sConfig.messages.playerChat then
                local message = L["Level Reached"]
                XToLevel.Messages:Print(message, self.levelStyle, sConfig.messages.colors.playerLevel)
            end
        end,
        
        ---
        -- function description
        PrintPetLevel = function(self, petName)
            if sConfig.messages.petChat then
                local message = petName .. L["Pet Level Reached"]
                XToLevel.Messages:Print(message, self.levelStyle, sConfig.messages.colors.playerLevel)
            end
        end,
    }
}
