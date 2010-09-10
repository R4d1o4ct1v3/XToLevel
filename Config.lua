---
-- Defines all data and functionality related to the configuration and per-char
-- data tables.
-- @file XToLevel.Config.lua
-- @release 3.3.3_14r
-- @copyright Atli Þór (atli@advefir.com)
---
--module "XToLevel.Config" -- For documentation purposes. Do not uncomment!

---
-- Per-char configuration table.
-- @class table
sConfig = {
    general = {
		allowDrag = true,
		allowSettingsClick = true,
		displayLocale = nil,
		showDebug = false,
	    rafEnabled = false,
		showNpcTooltipData = true,
	},
    messages = {
		playerFloating = true,
		playerChat = false,
		petFloating = true,
		petChat = false,
		bgObjectives = true,
		colors = {
			playerKill = {0.72, 1, 0.71, 1},
			playerQuest = {0.5, 1, 0.7, 1},
			playerBattleground = {1, 0.5, 0.5, 1},
			playerDungeon = {1, 0.75, 0.35, 1},
			playerLevel = {0.35, 1, 0.35, 1},
			petKill = {0.52, 0.73, 1, 1},
		},
	},
    averageDisplay = {
		visible = true,
		mode = 1, -- 1 = Blocky, 2 = Classic
		showPetFrame = true,
		detachPetFrame = false,
		backdrop = true,
		verbose = true,
		colorText = true,
        header = true,
		tooltip = true,
		combineTooltip = false,
		orientation = 'v',
		playerKills = true,
		playerQuests = true,
		playerDungeons = true,
		playerBGs = true,
		playerBGOs = false,
		playerProgress = true,
		playerTimer = true,
		progress = true, -- Duplicate?
		progressAsBars = false,
		petKills = true,
		petProgress = true,
		playerKillListLength = 10,
		playerQuestListLength = 10,
		playerBGListLength = 15,
		playerBGOListLength = 15,
		playerDungeonListLength = 15,
		petKillListLength = 10,
	},
	ldb = {
		allowTextColor = true,
		showIcon = true,
		showLabel = false,
		showText = true,
		textPattern = "default",
		text = {
			kills = true,
			quests = true,
			dungeons = true,
			bgs = true,
			bgo = false,
			pet = true,
			xp = true,
			xpnum = true,
			xpnumFormat = true,
			xpAsBars = false,
			petxp = true,
			petxpnum = true,
			xpCountdown = false,
			timer = true,
			colorValues = true,
			verbose = true,
			rested = true,
			restedp = true,
		},
		tooltip = {
			showDetails = true,
			showExperience = true,
			showBGInfo = true,
			showDungeonInfo = true,
			showPetInfo = true,
			showTimerInfo = true,
		}
	},
	timer = {
		enabled = true,
		mode = 1, -- 1 = session, 2 = level, 3 = kill range (3 is not implemented yet!)
		allowLevelFallback = true,
	}
}
sData = {
	player = {
		killAverage = 0,
		questAverage = 0,
		killList = {},
		questList = {},
		bgList = {},
		dungeonList = {},
		timer = {
			start = nil,
			total = nil,
			xpPerSecond = nil,
		}
	},
	pet = {
		killAverage = 0,
		killList = {},
		xpList = {}
	},
	customPattern = nil,
}


XToLevel.Config =
{
    LINE_HEIGHT = 30,
    H1_MARGIN = { top = -16, left = 10, bottom = 0, right = 0 },
    H2_MARGIN = { top = 0, left = 15, bottom = 0, right = 0 },
    SCROLL_MARGIN = { top = -42, left = 0, bottom = 10, right = -30},
    SCROLL_DIMENSIONS = { width = 380, height = 380 },
    
    panels = { },
    
    Initialize = function(self)
        -- self:Verify()
        local topPanel = self:CreateMainPanel()
        self:CreateGeneralPanel(topPanel)
        self:CreateMessagesPanel(topPanel)
        self:CreateWindowPanel(topPanel)
        self:CreateDataPanel(topPanel)
        self:CreateLDB(topPanel)
		self:CreateTooltipPanel(topPanel)
		self:CreateTimerPanel(topPanel)
        
		--
	    -- Initialize Popup Windows
	    --
	    StaticPopupDialogs['XToLevelConfig_MessageColorsReset'] = {
			text = L['Color Reset Dialog'],
			button1 = "Yes",
			button2 = "No",
			OnAccept = function()
				sConfig.messages.colors = {
					playerKill = {0.72, 1, 0.71, 1},
					playerQuest = {0.5, 1, 0.7, 1},
					playerBattleground = {1, 0.5, 0.5, 1},
					playerDungeon = {1, 0.75, 0.35, 1},
					playerLevel = {0.35, 1, 0.35, 1},
					petKill = {0.52, 0.73, 1, 1},
				};
				local messagesFrames = XToLevel.Config.panels["MessagesPanel"].childFrame
				messagesFrames["KillColorPicker"]:SetAttribute("currentColor", sConfig.messages.colors.playerKill)
				messagesFrames["QuestColorPicker"]:SetAttribute("currentColor", sConfig.messages.colors.playerQuest)
				messagesFrames["DungeonColorPicker"]:SetAttribute("currentColor", sConfig.messages.colors.playerDungeon)
				messagesFrames["BattleColorPicker"]:SetAttribute("currentColor", sConfig.messages.colors.playerBattleground)
				messagesFrames["PetColorPicker"]:SetAttribute("currentColor", sConfig.messages.colors.petKill)
				messagesFrames["LevelColorPicker"]:SetAttribute("currentColor", sConfig.messages.colors.playerLevel)
				XToLevel.Config:Open("messages")
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
		}
	    StaticPopupDialogs['XToLevelConfig_ResetPlayerKills'] = {
			text = L['Reset Player Kill Dialog'],
			button1 = "Yes",
			button2 = "No",
			OnAccept = function()
				XToLevel.Player:ClearKills();
	            XToLevel.Average:Update();
	            XToLevel.LDB:BuildPattern();
	            XToLevel.LDB:Update();
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
		}
	    StaticPopupDialogs['XToLevelConfig_ResetPlayerQuests'] = {
			text = L['Reset Player Quest Dialog'],
			button1 = "Yes",
			button2 = "No",
			OnAccept = function()
				XToLevel.Player:ClearQuests();
				XToLevel.Average:Update();
	            XToLevel.LDB:BuildPattern();
	            XToLevel.LDB:Update();
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
		}
	    StaticPopupDialogs['XToLevelConfig_ResetBattles'] = {
			text = L['Reset Battleground Dialog'],
			button1 = "Yes",
			button2 = "No",
			OnAccept = function()
				XToLevel.Player:ClearBattlegrounds();
				XToLevel.Average:Update();
	            XToLevel.LDB:BuildPattern();
	            XToLevel.LDB:Update();
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
		}
	    StaticPopupDialogs['XToLevelConfig_ResetPetKills'] = {
			text = L['Reset Pet Kill Dialog'],
			button1 = "Yes",
			button2 = "No",
			OnAccept = function()
				XToLevel.Pet:ClearKills();
				XToLevel.Average:Update();
	            XToLevel.LDB:BuildPattern();
	            XToLevel.LDB:Update();
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
		}
		StaticPopupDialogs['XToLevelConfig_ResetDungeons'] = {
	        text = L['Reset Dungeon Dialog'],
	        button1 = "Yes",
	        button2 = "No",
	        OnAccept = function()
	            XToLevel.Player:ClearDungeonList();
	            XToLevel.Average:Update();
	            XToLevel.LDB:BuildPattern();
	            XToLevel.LDB:Update();
	        end,
	        timeout = 0,
	        whileDead = true,
	        hideOnEscape = true,
	    }
    end,
    
    ---
    -- Open the configuration window.
    -- @param panel The name of the panel to open. Defaults to the main panel if
    --              the name is not valid.
    Open = function(self, panel)
		if type(self.panel_alias[panel]) == "string" and self.panels[self.panel_alias[panel]] then
			InterfaceOptionsFrame_OpenToCategory(self.panels[self.panel_alias[panel]])
		else
			InterfaceOptionsFrame_OpenToCategory("XToLevel_Config_XToLevel_MainPanel")
			console:log("Invalid panel ('" .. tostring(panel) .."'). Opening default instead.")
		end
    end,
	panel_alias = {
		["messages"] = "XToLevel_MessagesPanel",
		["average"] = "XToLevel_WindowPanel",
		["window"] = "XToLevel_WindowPanel",
		["ldb"] = "XToLevel_LdbPanel",
		["general"] = "XToLevel_GeneralPanel",
		["data"] = "XToLevel_DataPanel",
		["timer"]= "XToLevel_TimerPanel",
	},
    
    ---
    -- Creates the main "XToLevel" tab
    CreateMainPanel = function(self)
        local mainPanel = self:CreatePanel("XToLevel_MainPanel", "XToLevel", 200)
        
        -- Add the description.
        self:CreateDescription(mainPanel, "MainDescription", L['MainDescription'], 33, "FFFFFF")
        
        -- Add the about header
        local aboutHeader = self:CreateH2(mainPanel, "AboutHeader", "About", 45)
        aboutHeader:ClearAllPoints()
        aboutHeader:SetPoint("TOPLEFT", 24, -46)
        
        -- Create the about frame
        mainPanel.childFrame["AboutFrame"] = CreateFrame("Frame", "XToLevel_Config_Main_AboutFrame", mainPanel.childFrame)
        mainPanel.childFrame["AboutFrame"]:SetPoint("TOPLEFT", 9, -61)
        mainPanel.childFrame["AboutFrame"]:SetPoint("TOPRIGHT", 0, -161)
        mainPanel.childFrame["AboutFrame"]:SetHeight(100)
        mainPanel.childFrame["AboutFrame"]:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", --"Interface\\TUTORIALFRAME\\TutorialFrameBackground",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, tileSize = 0, edgeSize = 16, -- 
                insets = { left = 0, right = 0, top = 0, bottom = 0 }
            })
        mainPanel.childFrame["AboutFrame"]:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.85)
        mainPanel.childFrame["AboutFrame"]:SetBackdropColor(0.15, 0.15, 0.15, 0.65)
        
        -- Add text
        mainPanel.childFrame["AboutFrame"].lineTop = 12
        mainPanel.childFrame["AboutFrame"].lines = { }
        
        self:CreateTextLine(mainPanel.childFrame["AboutFrame"], "Version", L["Version"], "3.3.3_14r|r |cFFAAFFAA(2010-07-11)", "00FF00")
        self:CreateTextLine(mainPanel.childFrame["AboutFrame"], "Author", L["Author"], "Atli þór Jónsson", "E07B02")
        self:CreateTextLine(mainPanel.childFrame["AboutFrame"], "Email", L["Email"], "atli@advefir.com", "FFFFFF")
        self:CreateTextLine(mainPanel.childFrame["AboutFrame"], "Website", L["Website"], "wowinterface.com/downloads/info14368-XToLevel.html", "FFFFFF")
        self:CreateTextLine(mainPanel.childFrame["AboutFrame"], "Category", L["Category"], "Quests & Leveling, Battlegrounds, Dungeons, Pets.", "FFFFFF")
        self:CreateTextLine(mainPanel.childFrame["AboutFrame"], "License", L["License"], L['All Rights Reserved'] .. " (See LICENSE.txt)", "FFFFFF")
        
        
        return mainPanel
    end,
    
    ---
    -- Creates the general panel
    CreateGeneralPanel = function(self, parent)
        local generalPanel = self:CreatePanel("XToLevel_GeneralPanel", L["General Tab"], 300, parent)
        
        -- The locale section
        self:CreateH2(generalPanel, "LocalHeader", "Locale", 0)
        self:CreateSelectBox(generalPanel, "LocaleSelect", {"English", "Français", "Deutsch", "Español", "Dansk"}, "English",
            -- OnShow callback 
	        function(self)
	            local localeValue = sConfig.general.displayLocale;
	            local languageName = nil;
	            for language, locale in pairs(DISPLAY_LOCALES) do
	                if locale == localeValue then
	                    languageName = language;
	                end
	            end
	            if not languageName then
	                languageName = "English";
	            end
	            UIDropDownMenu_SetSelectedName(generalPanel.childFrame["LocaleSelect"], languageName, true);
	            UIDropDownMenu_SetText(generalPanel.childFrame["LocaleSelect"], languageName);
	        end, 
	        -- OnChange callback
	        function(self)
	            UIDropDownMenu_SetSelectedID(generalPanel.childFrame["LocaleSelect"], this:GetID(), 0);
	            
	            local rawLanguage = UIDropDownMenu_GetText(generalPanel.childFrame["LocaleSelect"]);
	            local newLocale = nil;
	            for lang, locale in pairs(DISPLAY_LOCALES) do
	                if rawLanguage == lang then
	                    newLocale = locale;
	                end
	            end
	            
	            console:log("Language changed: " .. rawLanguage .. " (" .. newLocale .. ")")
	            
	            -- LOCALE_DISPLAY = newLocale;
	            -- L = LOCALE[LOCALE_DISPLAY]
	            sConfig.general.displayLocale = newLocale;
	            XToLevel.Average:Update();
	            XToLevel.LDB:BuildPattern();
	            XToLevel.LDB:Update();
	            
	            StaticPopupDialogs['XToLevelConfig_LocaleReload'] = {
					text = L['Config Language Reload Prompt'],
					button1 = L["Yes"],
					button2 = L["No"],
					OnAccept = ReloadUI,
					timeout = 30,
					whileDead = true,
					hideOnEscape = true,
				}
	            
	            StaticPopup_Show("XToLevelConfig_LocaleReload");
	        end
	    )
        
        -- The debug section
        self:CreateH2(generalPanel, "DebugHeader", L['Debug'], 50)
        self:CreateCheckbox(generalPanel, "LocaleBox", L["Show Debug Info"], function(self)
            self:SetChecked(sConfig.general.showDebug)
        end, function(self)
            sConfig.general.showDebug = self:GetChecked() or false
        end)
        
        self:CreateH2(generalPanel, "RAFHeader", L['Recruit A Friend'], 55)
        
        self:CreateDescription(generalPanel, "RAFDescription", L["RAF Description"], 44, "FFFFFF")
        
        self:CreateCheckbox(generalPanel, "RAFBox", L['Enable'] .. " " .. L['Recruit A Friend'], function(self)
            self:SetChecked(sConfig.general.rafEnabled)
        end, function(self)
            sConfig.general.rafEnabled = self:GetChecked() or false
        end)
        
        return generalPanel
    end,
    
    ---
    -- Creates the main config panel
    CreateMessagesPanel = function(self, parent)
    	local height = XToLevel.Player:GetClass() == "HUNTER" and 300 or 350
        local messagesPanel = self:CreatePanel("XToLevel_MessagesPanel", L["Messages Tab"], height, parent)
        
        -- Player boxes
        self:CreateH2(messagesPanel, "PlayerHeader", L['Player Messages'], 0)
        self:CreateCheckbox(messagesPanel, "PlayerFloating", L['Show Floating'], function(self)
            self:SetChecked(sConfig.messages.playerFloating)
        end, function(self)
            sConfig.messages.playerFloating = self:GetChecked() or false
        end)
        self:CreateCheckbox(messagesPanel, "PlayerChat", L['Show In Chat'], function(self)
            self:SetChecked(sConfig.messages.playerChat)
        end, function(self)
            sConfig.messages.playerChat = self:GetChecked() or false
        end)
        self:CreateCheckbox(messagesPanel, "PlayerObjective", L['Show BG Objectives'], function(self)
            self:SetChecked(sConfig.messages.bgObjectives)
        end, function(self)
            sConfig.messages.bgObjectives = self:GetChecked() or false
        end)
        
        -- Pet boxes
        if XToLevel.Player:GetClass() == "HUNTER" then
	        self:CreateH2(messagesPanel, "PetHeader", L['Pet Messages'], 120)
	        self:CreateCheckbox(messagesPanel, "PetFloating", L['Show Floating'], function(self)
	            self:SetChecked(sConfig.messages.petFloating)
	        end, function(self)
	            sConfig.messages.petFloating = self:GetChecked() or false
	        end)
	        self:CreateCheckbox(messagesPanel, "PetChat", L['Show In Chat'], function(self)
	            self:SetChecked(sConfig.messages.petChat)
	        end, function(self)
	            sConfig.messages.petChat = self:GetChecked() or false
	        end)
        end
        
        -- Colors
        self:CreateH2(messagesPanel, "ColorHeader", L['Message Colors'], 210)
        self:CreateColorPicker(messagesPanel, "KillColorPicker", L['Player Kills'], sConfig.messages.colors.playerKill,
        	function(self)
        		if type(self.currentColor) == "table" then
    				sConfig.messages.colors.playerKill = self.currentColor
        		end
        	end)
    	self:CreateColorPicker(messagesPanel, "QuestColorPicker", L['Player Quests'], sConfig.messages.colors.playerQuest,
        	function(self)
        		if type(self.currentColor) == "table" then
    				sConfig.messages.colors.playerQuest = self.currentColor
        		end
        	end)
    	self:CreateColorPicker(messagesPanel, "DungeonColorPicker", L['Player Dungeons'], sConfig.messages.colors.playerDungeon,
        	function(self)
        		if type(self.currentColor) == "table" then
    				sConfig.messages.colors.playerDungeon = self.currentColor
        		end
        	end)
    	self:CreateColorPicker(messagesPanel, "BattleColorPicker", L['Player Battles'], sConfig.messages.colors.playerBattleground,
        	function(self)
        		if type(self.currentColor) == "table" then
    				sConfig.messages.colors.playerBattleground = self.currentColor
        		end
        	end)
    	self:CreateColorPicker(messagesPanel, "LevelColorPicker", L['Player Levelup'], sConfig.messages.colors.playerLevel,
        	function(self)
        		if type(self.currentColor) == "table" then
    				sConfig.messages.colors.playerLevel = self.currentColor
        		end
        	end)
    	self:CreateColorPicker(messagesPanel, "PetColorPicker", L['Pet Kills'], sConfig.messages.colors.petKill,
        	function(self)
        		if type(self.currentColor) == "table" then
    				sConfig.messages.colors.petKill = self.currentColor
        		end
        	end)
        	
    	local resetButton = self:CreateButton(messagesPanel, "ColorReset", L['Color Reset'], 75, 25,
    		function(self) end,
    		function(self) StaticPopup_Show("XToLevelConfig_MessageColorsReset") end)
		resetButton:ClearAllPoints()
		resetButton:SetPoint("TOP", 0, -(messagesPanel.insertHeight - 30))
        
        return messagesPanel
    end,
    
    ---
    -- Creates the Window config panel
    CreateWindowPanel = function(self, parent)
    	local height = 615
    	if XToLevel.Player:GetClass() == "HUNTER" then
    		height = 730
        end
        local windowPanel = self:CreatePanel("XToLevel_WindowPanel", L["Window Tab"], height, parent)
        
    	self:CreateH2(windowPanel, "ActiveHeader", L['Active Window Header'], 0)
        self:CreateSelectBox(windowPanel, "WindowSelect", {"None", "Blocky", "Classic"}, "Blocky",
	        -- OnShow
	        function()
	           local chosenType = sConfig.averageDisplay.mode or nil
	           local chosenWindow = false
	           if chosenType == 1 then
	               chosenWindow = "Blocky"
	           elseif chosenType == 2 then
	               chosenWindow = "Classic"
	           end
	           if not chosenWindow then
                    chosenWindow = this.default
                end
                UIDropDownMenu_SetSelectedName(this, chosenWindow, true);
                UIDropDownMenu_SetText(this, chosenWindow);
	        end,
	        -- OnChange
	        function(selectBox)
	           local choice = UIDropDownMenu_GetText(selectBox)
	           local number = 0
	           for i, value in ipairs(AVERAGE_WINDOWS) do
	               if value == choice then
	                   number = i
	               end
	           end
	           sConfig.averageDisplay.mode = number
	           XToLevel.Average:Update()
	           XToLevel.LDB:BuildPattern()
	           XToLevel.LDB:Update()
	        end
	    )
	   
        -- Classic boxes.
        self:CreateH2(windowPanel, "ClassicHeader", L['Classic Specific Options'], 0)
        self:CreateCheckbox(windowPanel, "ShowHeader", L["Show XToLevel Header"], 
            function(self) self:SetChecked(sConfig.averageDisplay.header) end, 
            function(self) sConfig.averageDisplay.header = self:GetChecked() or false end)
        self:CreateCheckbox(windowPanel, "ShowPetFrame", L["Show Window Frame"], 
            function(self) self:SetChecked(sConfig.averageDisplay.backdrop) end, 
            function(self) sConfig.averageDisplay.backdrop = self:GetChecked() or false end)
        self:CreateCheckbox(windowPanel, "UseVerboseText", L["Show Verbose Text"], 
            function(self) self:SetChecked(sConfig.averageDisplay.verbose) end, 
            function(self) sConfig.averageDisplay.verbose = self:GetChecked() or false end)
        self:CreateCheckbox(windowPanel, "ShowColoredText", L["Show Colored Text"], 
            function(self) self:SetChecked(sConfig.averageDisplay.colorText) end, 
            function(self) sConfig.averageDisplay.colorText = self:GetChecked() or false end)
            
        -- Blocky boxes.
        self:CreateH2(windowPanel, "BlockyHeader", L['Blocky Specific Options'], 0)
        self:CreateCheckbox(windowPanel, "ShowPetFrame", L["Vertical Align"], 
            function(self) self:SetChecked(sConfig.averageDisplay.orientation == "v") end, 
            function(self) sConfig.averageDisplay.orientation = self:GetChecked() and "v" or "h" end)
            
        if XToLevel.Player:GetClass() == "HUNTER" then
        	self:CreateCheckbox(windowPanel, "ShowPetFrame", L["Show Pet Frame"], 
            	function(self) self:SetChecked(sConfig.averageDisplay.showPetFrame) end, 
            	function(self) sConfig.averageDisplay.showPetFrame = self:GetChecked() or false end)
       	end
        
	    -- Behavior boxes
        self:CreateH2(windowPanel, "BehaviorHeader", L['Window Behavior Header'], 125)
        self:CreateCheckbox(windowPanel, "LockWindow", L["Lock Avarage Display"], 
            function(self) self:SetChecked(not sConfig.general.allowDrag) end, 
            function(self) sConfig.general.allowDrag = not (self:GetChecked() or false) end)
        self:CreateCheckbox(windowPanel, "AllowConfigClick", L["Allow Average Click"], 
            function(self) self:SetChecked(sConfig.general.allowSettingsClick) end, 
            function(self) sConfig.general.allowSettingsClick = self:GetChecked() or false end)
        self:CreateCheckbox(windowPanel, "ShowTooltip", L["Show Tooltip"], 
            function(self) self:SetChecked(sConfig.averageDisplay.tooltip) end, 
            function(self) sConfig.averageDisplay.tooltip = self:GetChecked() or false end)
        self:CreateCheckbox(windowPanel, "CombineTooltip", L["Combine Tooltip Data"], 
            function(self) self:SetChecked(sConfig.averageDisplay.combineTooltip) end, 
            function(self) sConfig.averageDisplay.combineTooltip = self:GetChecked() or false end)
        self:CreateCheckbox(windowPanel, "ProgressAsBars", L["Progress As Bars"], 
            function(self) self:SetChecked(sConfig.averageDisplay.progressAsBars) end, 
            function(self) sConfig.averageDisplay.progressAsBars = self:GetChecked() or false end)
        
        -- Data boxes
        self:CreateH2(windowPanel, "PlayerDataHeader", L['LDB Player Data Header'], 250)
        self:CreateCheckbox(windowPanel, "PlayerKills", L["Kills"], 
            function(self) self:SetChecked(sConfig.averageDisplay.playerKills) end, 
            function(self) sConfig.averageDisplay.playerKills = self:GetChecked() or false end)
        self:CreateCheckbox(windowPanel, "PlayerQuests", L["Player Quests"], 
            function(self) self:SetChecked(sConfig.averageDisplay.playerQuests) end, 
            function(self) sConfig.averageDisplay.playerQuests = self:GetChecked() or false end)
        local dungeons = self:CreateCheckbox(windowPanel, "PlayerDungeons", L["Player Dungeons"], 
            function(self) self:SetChecked(sConfig.averageDisplay.playerDungeons) end, 
            function(self) sConfig.averageDisplay.playerDungeons = self:GetChecked() or false end)
        local battles = self:CreateCheckbox(windowPanel, "PlayerBattles", L["Player Battles"], 
            function(self) self:SetChecked(sConfig.averageDisplay.playerBGs) end, 
            function(self) sConfig.averageDisplay.playerBGs = self:GetChecked() or false end)
        local objectives = self:CreateCheckbox(windowPanel, "PlayerObjectives", L["Player Objectives"], 
            function(self) self:SetChecked(sConfig.averageDisplay.playerBGOs) end, 
            function(self) sConfig.averageDisplay.playerBGOs = self:GetChecked() or false end)
        self:CreateCheckbox(windowPanel, "PlayerProgress", L["Player Progress"], 
            function(self) self:SetChecked(sConfig.averageDisplay.playerProgress) end, 
            function(self) sConfig.averageDisplay.playerProgress = self:GetChecked() or false end)
		self:CreateCheckbox(windowPanel, "PlayerTimer", L["Player Timer"] or "Timer", 
            function(self) self:SetChecked(sConfig.averageDisplay.playerTimer) end, 
            function(self) sConfig.averageDisplay.playerTimer = self:GetChecked() or false end)
        
        -- Add low-level warning tooltips
        if XToLevel.Player.level < 10 then
        	XToLevel.Tooltip:SetConfigInfo(battles, L["This option becomes available at level 10"]);
        	XToLevel.Tooltip:SetConfigInfo(objectives, L["This option becomes available at level 10"]);
        end
        if XToLevel.Player.level < 15 then
        	XToLevel.Tooltip:SetConfigInfo(dungeons, L["This option becomes available at level 15"]);
        end
            
       	-- Set tooltips for hunter-only options, in case the player is not a
       	-- hunter.
       	if XToLevel.Player:GetClass() == "HUNTER" then
        	self:CreateH2(windowPanel, "PetDataHeader", L['LDB Pet Data Header'], 250)
	        self:CreateCheckbox(windowPanel, "PetKills", L["Pet Kills"], 
	            function(self) self:SetChecked(sConfig.averageDisplay.petKills) end, 
	            function(self) sConfig.averageDisplay.petKills = self:GetChecked() or false end)
	        self:CreateCheckbox(windowPanel, "PetProgress", L["Pet Progress"], 
	            function(self) self:SetChecked(sConfig.averageDisplay.petProgress) end, 
	            function(self) sConfig.averageDisplay.petProgress = self:GetChecked() or false end)
        end
        
        
        return windowPanel
    end,
    
    ---
    -- Creates the LDB config panel
    CreateLDB = function(self, parent)
    	local height = 600
    	if XToLevel.Player:GetClass() == "HUNTER" then
    		height = 670
    	end
        local ldbPanel = self:CreatePanel("XToLevel_LdbPanel", L["LDB Tab"], height, parent)
        
        -- Text pattern section
        self:CreateH2(ldbPanel, "TextPatternHeader", L['LDB Pattern Header'])
        self:CreateSelectBox(ldbPanel, "LDBPatternSelect", {"default", "minimal", "minimal_dashed", "brackets", "countdown", "custom"}, "default",
            -- OnShow
            function()
               local chosenType = sConfig.ldb.textPattern or nil
                if not chosenType then
                    chosenType = this.default
                end
                UIDropDownMenu_SetSelectedName(this, chosenType, true);
                UIDropDownMenu_SetText(this, chosenType);
            end,
            -- OnChange
            function(selectBox)
				sConfig.ldb.textPattern = UIDropDownMenu_GetText(selectBox)
				if sConfig.ldb.textPattern == "custom" then
				    XToLevel.Config.panels["XToLevel_LdbPanel"].childFrame["LDBCustomPatternBox"]:Show()
			    else
                    XToLevel.Config.panels["XToLevel_LdbPanel"].childFrame["LDBCustomPatternBox"]:Hide()
				end
				if sConfig.ldb.textPattern == "countdown" and sConfig.ldb.text.xpCountdown == false then
					sConfig.ldb.text.xpCountdown = true
					XToLevel.Config.panels["XToLevel_LdbPanel"].childFrame["CountXpDown"]:SetChecked(true);
				end
				XToLevel.LDB:BuildPattern()
                XToLevel.LDB:Update()
            end
        )
        local patternBox = self:CreateEditBox(ldbPanel, "LDBCustomPatternBox", sData.customPattern, 350, 30, 
            function(self, newText)
                sData.customPattern = newText
                XToLevel.LDB:BuildPattern()
                XToLevel.LDB:Update()
            end)
        if sConfig.ldb.textPattern ~= "custom" then
            patternBox:Hide()
        end
        
        -- Appearence header
        self:CreateH2(ldbPanel, "AppearenceHeader", L['LDB Appearence Header'])
        self:CreateCheckbox(ldbPanel, "ShowTextBox", L["Show Text"],
            function(self) self:SetChecked(sConfig.ldb.showText)  end,
            function(self) sConfig.ldb.showText = self:GetChecked() or false end)
        self:CreateCheckbox(ldbPanel, "ShowLabelBox", L["Show Label"],
            function(self) self:SetChecked(sConfig.ldb.showLabel)  end,
            function(self) 
				sConfig.ldb.showLabel = self:GetChecked() or false 
				XToLevel.LDB:UpdateTimer()
			end)
        self:CreateCheckbox(ldbPanel, "ShowIconBox", L["Show Icon"],
            function(self) self:SetChecked(sConfig.ldb.showIcon)  end,
            function(self) sConfig.ldb.showIcon = self:GetChecked() or false end)
        self:CreateCheckbox(ldbPanel, "AllowColoredTextBox", L['Allow Colored Text'],
            function(self) self:SetChecked(sConfig.ldb.allowTextColor)  end,
            function(self) sConfig.ldb.allowTextColor = self:GetChecked() or false end)
        self:CreateCheckbox(ldbPanel, "ColorDataByProgressBox", L['Color By XP'],
            function(self) self:SetChecked(sConfig.ldb.text.colorValues)  end,
            function(self) sConfig.ldb.text.colorValues = self:GetChecked() or false end)
        self:CreateCheckbox(ldbPanel, "ShowXpAsBarsBox", L['Show Progress As Bars'],
            function(self) self:SetChecked(sConfig.ldb.text.xpAsBars)  end,
            function(self) sConfig.ldb.text.xpAsBars = self:GetChecked() or false end)
         self:CreateCheckbox(ldbPanel, "ShowVerboseText", L['Show Verbose'],
            function(self) self:SetChecked(sConfig.ldb.text.verbose)  end,
            function(self) sConfig.ldb.text.verbose = self:GetChecked() or false end)
		self:CreateCheckbox(ldbPanel, "CountXpDown", L['Show XP remaining'],
            function(self) self:SetChecked(sConfig.ldb.text.xpCountdown)  end,
            function(self) sConfig.ldb.text.xpCountdown = self:GetChecked() or false end)
		self:CreateCheckbox(ldbPanel, "ShrinkXpValues", L['Shorten XP values'],
            function(self) self:SetChecked(sConfig.ldb.text.xpnumFormat)  end,
            function(self) sConfig.ldb.text.xpnumFormat = self:GetChecked() or false end)
            
        -- Player data
        self:CreateH2(ldbPanel, "PlayerData", L['LDB Player Data Header'])
        self:CreateCheckbox(ldbPanel, "ShowKills", L["Player Kills"],
            function(self) self:SetChecked(sConfig.ldb.text.kills)  end,
            function(self) sConfig.ldb.text.kills = self:GetChecked() or false end)
        self:CreateCheckbox(ldbPanel, "ShowQuests", L["Player Quests"],
            function(self) self:SetChecked(sConfig.ldb.text.quests)  end,
            function(self) sConfig.ldb.text.quests = self:GetChecked() or false end)
        local dungeons = self:CreateCheckbox(ldbPanel, "ShowDungeons", L["Player Dungeons"],
            function(self) self:SetChecked(sConfig.ldb.text.dungeons)  end,
            function(self) sConfig.ldb.text.dungeons = self:GetChecked() or false end)
        local battles = self:CreateCheckbox(ldbPanel, "ShowBattles", L["Player Battles"],
            function(self) self:SetChecked(sConfig.ldb.text.bgs)  end,
            function(self) sConfig.ldb.text.bgs = self:GetChecked() or false end)
        local objectives = self:CreateCheckbox(ldbPanel, "ShowObjectives", L["Player Objectives"],
            function(self) self:SetChecked(sConfig.ldb.text.bgo)  end,
            function(self) sConfig.ldb.text.bgo = self:GetChecked() or false end)
        self:CreateCheckbox(ldbPanel, "ShowProgress", L["Player Progress"],
            function(self) self:SetChecked(sConfig.ldb.text.xp)  end,
            function(self) sConfig.ldb.text.xp = self:GetChecked() or false end)
		self:CreateCheckbox(ldbPanel, "ShowXp", L["Player Experience"],
            function(self) self:SetChecked(sConfig.ldb.text.xpnum)  end,
            function(self) sConfig.ldb.text.xpnum = self:GetChecked() or false end)
        
        -- Add low-level warning tooltips
        if XToLevel.Player.level < 10 then
        	XToLevel.Tooltip:SetConfigInfo(battles, L["This option becomes available at level 10"]);
        	XToLevel.Tooltip:SetConfigInfo(objectives, L["This option becomes available at level 10"]);
        end
        if XToLevel.Player.level < 15 then
        	XToLevel.Tooltip:SetConfigInfo(dungeons, L["This option becomes available at level 15"]);
        end
        
        -- Pet data
        if XToLevel.Player:GetClass() == "HUNTER" then
	        self:CreateH2(ldbPanel, "PlayerData", L['LDB Pet Data Header'])
	        self:CreateCheckbox(ldbPanel, "ShowPetKills", L["Pet Kills"],
	            function(self) self:SetChecked(sConfig.ldb.text.pet)  end,
	            function(self) sConfig.ldb.text.pet = self:GetChecked() or false end)
	        self:CreateCheckbox(ldbPanel, "ShowPetProgress", L["Pet Progress"],
	            function(self) self:SetChecked(sConfig.ldb.text.petxp)  end,
	            function(self) sConfig.ldb.text.petxp = self:GetChecked() or false end)
			self:CreateCheckbox(ldbPanel, "ShowPetExperience", L["Player Experience"],
	            function(self) self:SetChecked(sConfig.ldb.text.petxpnum)  end,
	            function(self) sConfig.ldb.text.petxpnum = self:GetChecked() or false end)
        end
    end,
    
    ---
    -- Cretes the data panel
    CreateDataPanel = function(self, parent)
    	local height = 475
    	if XToLevel.Player:GetClass() == "HUNTER" then
    		height = 525
    	end
        local ldbPanel = self:CreatePanel("XToLevel_DataPanel", L["Data Tab"], height, parent)
        
        -- Add the header and description.
        self:CreateH2(ldbPanel, "RangeHeader", L['Data Range Header'])
        self:CreateDescription(ldbPanel, "RangeDescription1", L['Data Range Subheader'], 33, "FFFFFF")
        
        -- Add ranges
        self:CreateRange(ldbPanel, "KillDataLength", L['Player Kills'], 1, 100, sConfig.averageDisplay.playerKillListLength,
        	function(self, newValue) XToLevel.Player:SetKillAverageLength(newValue) end)
    	self:CreateRange(ldbPanel, "QuestDataLength", L['Player Quests'], 1, 100, sConfig.averageDisplay.playerQuestListLength,
        	function(self, newValue) XToLevel.Player:SetQuestAverageLength(newValue) end)
    	self:CreateRange(ldbPanel, "BattleDataLength", L['Player Battles'], 1, 100, sConfig.averageDisplay.playerBGListLength,
        	function(self, newValue) XToLevel.Player:SetBattleAverageLength(newValue) end)
    	self:CreateRange(ldbPanel, "ObjectiveDataLength", L['Player Objectives'], 1, 100, sConfig.averageDisplay.playerBGOListLength,
        	function(self, newValue) XToLevel.Player:SetObjectiveAverageLength(newValue); end)
    	self:CreateRange(ldbPanel, "DungeonDataLength", L['Player Dungeons'], 1, 100, sConfig.averageDisplay.playerDungeonListLength,
        	function(self, newValue) XToLevel.Player:SetDungeonAverageLength(newValue) end)
    	if XToLevel.Player:GetClass() == "HUNTER" then
	    	self:CreateRange(ldbPanel, "PetDataLength", L['Reset Pet Kills'], 1, 100, sConfig.averageDisplay.petKillListLength,
	        	function(self, newValue) XToLevel.Pet:SetKillAverageLength(newValue) end)
    	end
    	
    	-- Add the header and description.
        self:CreateH2(ldbPanel, "ClearHeader", L['Clear Data Header'])
        self:CreateDescription(ldbPanel, "ClearDescription", L['Clear Data Subheader'], 22, "FFFFFF")
        self:CreateButton(ldbPanel, "ClearKillsButton", L['Reset Player Kills'], 105, 30, 
        	function(self) end, 
        	function(self) StaticPopup_Show("XToLevelConfig_ResetPlayerKills"); end, 
    	true)
    	self:CreateButton(ldbPanel, "ClearQuestsButton", L['Reset Player Quests'], 105, 30, 
        	function(self) end, 
        	function(self) StaticPopup_Show("XToLevelConfig_ResetPlayerQuests"); end, 
    	true)
    	self:CreateButton(ldbPanel, "ClearDungeonsButton", L['Reset Dungeons'], 105, 30, 
        	function(self) end, 
        	function(self) StaticPopup_Show("XToLevelConfig_ResetDungeons"); end, 
    	false)
    	self:CreateButton(ldbPanel, "ClearBattlesButton", L['Reset Battlegrounds'], 105, 30, 
        	function(self) end, 
        	function(self) StaticPopup_Show("XToLevelConfig_ResetBattles"); end, 
    	true)
    	if XToLevel.Player:GetClass() == "HUNTER" then
			self:CreateButton(ldbPanel, "ClearPetButton", L['Reset Pet Kills'], 105, 30, 
		    	function(self) end, 
		    	function(self) StaticPopup_Show("XToLevelConfig_ResetPetKills"); end, 
			false)
		end
    end,
	
	CreateTooltipPanel = function(self, parent)
		local height = 350
        local tooltipPanel = self:CreatePanel("XToLevel_TooltipPanel", L["Tooltip"], height, parent)
	
		-- Tooltip sections
        self:CreateH2(tooltipPanel, "TooltipSectionsHeader", L['Tooltip Sections Header'])
        self:CreateCheckbox(tooltipPanel, "TooltipPlayer", L['Show Player Details'],
            function(self) self:SetChecked(sConfig.ldb.tooltip.showDetails)  end,
            function(self) sConfig.ldb.tooltip.showDetails = self:GetChecked() or false end)
        self:CreateCheckbox(tooltipPanel, "TooltipXP", L['Show Player Experience'],
            function(self) self:SetChecked(sConfig.ldb.tooltip.showExperience)  end,
            function(self) sConfig.ldb.tooltip.showExperience = self:GetChecked() or false end)
        self:CreateCheckbox(tooltipPanel, "TooltipBG", L['Show Battleground Info'],
            function(self) self:SetChecked(sConfig.ldb.tooltip.showBGInfo)  end,
            function(self) sConfig.ldb.tooltip.showBGInfo = self:GetChecked() or false end)
        self:CreateCheckbox(tooltipPanel, "TooltipDungeon", L['Show Dungeon Info'],
            function(self) self:SetChecked(sConfig.ldb.tooltip.showDungeonInfo)  end,
            function(self) sConfig.ldb.tooltip.showDungeonInfo = self:GetChecked() or false  end)
        self:CreateCheckbox(tooltipPanel, "TooltipPet", L['Show Pet Details'],
            function(self) self:SetChecked(sConfig.ldb.tooltip.showPetInfo)  end,
            function(self) sConfig.ldb.tooltip.showPetInfo = self:GetChecked() or false end)
        self:CreateCheckbox(tooltipPanel, "TooltipTimer", L['Show Timer Details'],
            function(self) self:SetChecked(sConfig.ldb.tooltip.showTimerInfo)  end,
            function(self) sConfig.ldb.tooltip.showTimerInfo = self:GetChecked() or false end)
			
		self:CreateH2(tooltipPanel, "TooltipMiscHeader", "Misc")
        self:CreateCheckbox(tooltipPanel, "TooltipNpc", "Show kills needed in NPC tooltips.",
            function(self) self:SetChecked(sConfig.general.showNpcTooltipData)  end,
            function(self) sConfig.general.showNpcTooltipData = self:GetChecked() or false end)
	end,
	
	CreateTimerPanel = function(self, parent)
		local height = 350
        local timerPanel = self:CreatePanel("XToLevel_TimerPanel", L["Timer"] or "Timer", height, parent)
		
        self:CreateCheckbox(timerPanel, "TimerEnable", L["Enable timer"] or "Enable timer",
            function(self) 
				self:SetChecked(sConfig.timer.enabled)
			end,
            function(self) 
				sConfig.timer.enabled = self:GetChecked() or false 
				if sConfig.timer.enabled then
					XToLevel.Player.timerHandler = XToLevel.timer:ScheduleRepeatingTimer(XToLevel.Player.TriggerTimerUpdate, XToLevel.Player.xpPerSecTimeout)
				else
					XToLevel.timer:CancelTimer(XToLevel.Player.timerHandler)
				end
				XToLevel.Average:UpdateTimer(nil)
				XToLevel.LDB:UpdateTimer()
			end)
			
		local desc =  "Choose the source of the data used for the timer. - "
		desc = desc .."\"Session\" uses only the XP gained since the UI was loaded. Ideal as a \"real-time\" estimate while farming. - "
		desc = desc .."\"Level\" uses the total time and XP this level. Gives a better long-term estimate for quest and dungeon runners."
		desc = desc .."(Note that the Level mode may be fairly inaccurate during the first few % of a new level.)"
		
		self:CreateH2(timerPanel, "TimerModeHeader", L["Mode"] or "Mode")
		self:CreateDescription(timerPanel, "TimerModeDescriotion", desc, 66, "FFFFFF")
		self:CreateSelectBox(timerPanel, "TimerModeSelect", {"Session", "Level"}, "Session",
            -- OnShow
            function()
               local chosenType = sConfig.timer.mode == 1 and "Session" or "Level"
                UIDropDownMenu_SetSelectedName(this, chosenType, true);
                UIDropDownMenu_SetText(this, chosenType);
            end,
            -- OnChange
            function(selectBox)
				local chosen = UIDropDownMenu_GetText(selectBox)
				sConfig.timer.mode = chosen == "Session" and 1 or 2
				XToLevel.Average:Update()
            end
        )
		
		self:CreateH2(timerPanel, "TimerFallbackPadder", " ")
		self:CreateCheckbox(timerPanel, "TimerModeFallback", L['TimerModeFallback'] or "Fall back on \"Level\" if session data is not available",
            function(self) self:SetChecked(sConfig.ldb.tooltip.showDetails)  end,
            function(self) sConfig.ldb.tooltip.showDetails = self:GetChecked() or false end)
		
		self:CreateH2(timerPanel, "TimerFallbackPadder", " ")
		self:CreateH2(timerPanel, "TimerSessionResetHeader", L["Reset"] or "Reset")
		--desc = "This button will clear out the session data, resettning the session estimate."
		--self:CreateDescription(timerPanel, "TimerModeResetDesc", desc, 22, "FFFFFF")
		
		self:CreateButton(timerPanel, "ResetSessionButton", L["Reset Session"] or "Reset Session", nil, nil, function() end, 
			function()
				sData.player.timer.start = time()
				sData.player.timer.total = 0
				XToLevel.Average:UpdateTimer()
				XToLevel.LDB:UpdateTimer()
			end
		)
		
	end,
    
    ---
    -- Creates a panel.
    -- @param name The name used internally. Should be a valid variable name
    --        without any dashes or underscores! (Preferably C# style notation)
    -- @param title The title displayed as the header of the panel and the label
    --        in the config window's tree view.
    -- @param height The total height of the panel. If this is larger than the
    --        height of the panel window, a scroll bar will be displayed.
    -- @param parent Specifies the parent panel, in case this is a sub-menu. By
    --        default this will be omitted and the panel made a top-level menu.
    -- @return Returns the new panel.
    CreatePanel = function(self, name, title, height, parent)
        -- Create the panel; the top-level wrapper around the panel.
        self.panels[name] = CreateFrame("Frame", "XToLevel_Config_" .. name, InterfaceOptionFramePanelContainer)
        self.panels[name].name = title
        if parent ~= nil then
            self.panels[name].parent = parent.name
        end
        InterfaceOptions_AddCategory(self.panels[name])
        
        -- Set the page title.
        self.panels[name].title = self.panels[name]:CreateFontString("XToLevel_Config_" .. name .. "_Tile", "ARTWORK", "GameFontNormalLarge")
        self.panels[name].title:SetPoint("TOPLEFT", self.H1_MARGIN.left, self.H1_MARGIN.top)
        self.panels[name].title:SetText(strtrim(title, " -"))
        self.panels[name].insertHeight = 0
        self.panels[name].insertLeft = 0
        
        if height > self.SCROLL_DIMENSIONS.height then
	        -- Create content frame
	        self.panels[name].childFrame = CreateFrame("Frame", "XToLevel_Config_" .. name .."_Contents", InterfaceOptionsFramePanelContainer)
	        self.panels[name].childFrame:SetWidth(self.SCROLL_DIMENSIONS.width)
	        self.panels[name].childFrame:SetHeight(self.SCROLL_DIMENSIONS.height)
	        
	        -- The content frame scroll wrapper
	        self.panels[name].scroller = CreateFrame("ScrollFrame", "XToLevel_Config_" .. name .."_Scroller", self.panels[name], "FauxScrollFrameTemplate")
	        self.panels[name].scroller:SetPoint("TOPLEFT", self.SCROLL_MARGIN.left, self.SCROLL_MARGIN.top)
	        self.panels[name].scroller:SetPoint("BOTTOMRIGHT", self.SCROLL_MARGIN.right, self.SCROLL_MARGIN.bottom)
	        self.panels[name].scroller:SetScrollChild(self.panels[name].childFrame)
	        
	        FauxScrollFrame_Update(XToLevel.Config.panels[name].scroller, height, XToLevel.Config.SCROLL_DIMENSIONS.height, 1);
            
            -- Set scroll bar drag-button background
            local scrollBar = getglobal( self.panels[name].scroller:GetName() .. "ScrollBar" );
            scrollBar:SetBackdrop({
                bgFile = "Interface\\TutorialFrame\\TutorialFrameBackground", 
                edgeFile = nil, tile = false, tileSize = 0, edgeSize = 0, -- "Interface\\DialogFrame\\UI-DialogBox-Border"
                insets = { left = 0, right = 0, top = 0, bottom = 0 }
            })
            scrollBar:SetBackdropColor(0, 0, 0, 0.65)
            
            self.panels[name].scroller:Show()
        else
            -- Create content frame
            self.panels[name].childFrame = CreateFrame("Frame", "XToLevel_Config_" .. name .."_Contents", self.panels[name])
            self.panels[name].childFrame:SetWidth(self.SCROLL_DIMENSIONS.width)
            self.panels[name].childFrame:SetHeight(self.SCROLL_DIMENSIONS.height)
            self.panels[name].childFrame:SetPoint("TOPLEFT", self.SCROLL_MARGIN.left, self.SCROLL_MARGIN.top)
            self.panels[name].childFrame:SetPoint("BOTTOMRIGHT", self.SCROLL_MARGIN.right, self.SCROLL_MARGIN.bottom)
            self.panels[name].childFrame:Show()
        end
        
        return self.panels[name]
    end,
    
    ---
    -- Creates a description text.
    -- @param parent The frame on which to put the text on.
    -- @param fieldName The name of the field.
    -- @param text The text to use as the description.
    -- @param height The height of the rendering area. Text will be truncated if it is to long.
    -- @param color The color of the text.
    CreateDescription = function(self, parent, fieldName, text, height, color)
    	-- local lineCount = XToLevel.Lib:strcount("\n", text) + 1
    	parent.childFrame[fieldName] = parent.childFrame:CreateFontString("XToLevel_Config_DataRange_Description", "ARTWORK", "SpellFont_Small")
        parent.childFrame[fieldName]:SetPoint("TOPLEFT", self.H2_MARGIN.left, -(parent.insertHeight - 5))
        parent.childFrame[fieldName]:SetPoint("TOPRIGHT", self.H2_MARGIN.right, -(parent.insertHeight - 5))
        parent.childFrame[fieldName]:SetHeight(height)
        parent.childFrame[fieldName]:SetWordWrap(true)
        parent.childFrame[fieldName]:SetNonSpaceWrap(true)
        parent.childFrame[fieldName]:SetText("|cFF" .. color .. text .. "|r")
        parent.childFrame[fieldName]:SetJustifyH("LEFT")
        parent.insertHeight = parent.insertHeight + (height) + 5
        return parent.childFrame[fieldName]
    end,
    
    ---
    -- Creates a level 2 header and assigns it to the given field.
    -- @param parent The parent framem usually a child of a scroll frame.
    -- @param fieldName The name of the field, assigned to the parent frame.
    -- @param text The text of the header line. Shouldn't be more than 30 chars.
    -- @param offsetTop The number of pixels between the top of the frame and
    --                  the top of the header line. (Positive!)
    -- @param globalName The global name to assign the new object. Needs to be
    --        unique enough so not to overwrite values from other components.
    -- @return The new FontString object
    CreateH2 = function(self, parent, fieldName, text, offsetTop, globalName)
        -- First subheader of the content frame
        parent.childFrame[fieldName] = parent.childFrame:CreateFontString(parent:GetName() .. "_" .. fieldName, "ARTWORK", "GameFontNormal")
        parent.childFrame[fieldName]:SetPoint("TOPLEFT", self.H2_MARGIN.left, -(parent.insertHeight + 10))
        parent.childFrame[fieldName]:SetPoint("TOPRIGHT", self.H2_MARGIN.right, -(parent.insertHeight + 10))
        parent.childFrame[fieldName]:SetJustifyH("Left")
        parent.childFrame[fieldName]:SetText(strtrim(text, " -"))
        parent.insertHeight = parent.insertHeight + 28
        
        return parent.childFrame[fieldName]
    end,
    
    ---
    -- Creates a line in the About box.
    -- @param frame The About box frame.
    -- @param label The label for the line, colored dark yellow.
    -- @param text The value of the line.
    -- @param textColor The color of the value.
    CreateAboutLine = function(self, frame, label, text, textColor)
        frame.lines[label] = frame:CreateFontString("XToLevel_Config_Main_Version", "ARTWORK", "SpellFont_Small")
        frame.lines[label]:SetPoint("TOPLEFT", 10, -frame.lineTop)
        frame.lines[label]:SetTextColor(1, 0.82, 0, 1)
        frame.lines[label]:SetText(label .. ": |cFF" .. textColor .. text .."|r")
        frame.lines[label]:SetJustifyH("LEFT")
        
        frame.lineTop  = frame.lineTop + 13
        
        return frame.lines[label]
    end,
    
    ---
    -- Creates a line in the About box.
    -- @param frame The About box frame.
    -- @param fieldName The name to give the line.
    -- @param label The label for the line, colored dark yellow.
    -- @param text The value of the line.
    -- @param textColor The color of the value.
    CreateTextLine = function(self, frame, fieldName, label, text, textColor)
        frame.lines[fieldName] = frame:CreateFontString(frame:GetName() .. "_" .. fieldName, "ARTWORK", "SpellFont_Small")
        frame.lines[fieldName]:SetPoint("TOPLEFT", 10, -frame.lineTop)
        if label ~= "" then
            frame.lines[fieldName]:SetTextColor(1, 0.82, 0, 1)
            frame.lines[fieldName]:SetText(label .. ": |cFF" .. textColor .. text .."|r")
        else
            frame.lines[fieldName]:SetText("|cFF" .. textColor .. text .."|r")
        end
        frame.lines[fieldName]:SetJustifyH("LEFT")
        
        frame.lineTop  = frame.lineTop + 13
        
        return frame.lines[fieldName]
    end,
    
    ---
    -- Creats a checkbox
    -- @param parent The panel to which this button should belong
    -- @param fieldName The name of the field, assigned to the parent frame.
    -- @param text The check button's label.
    -- @param configDirective The config directive tied to this button.
    CreateCheckbox = function(self, parent, fieldName, text, onShow, postClick)
        -- Create box
        parent.childFrame[fieldName] = CreateFrame("CheckButton", parent.childFrame:GetName() .. "_" .. fieldName, parent.childFrame, "InterfaceOptionsCheckButtonTemplate ")
        parent.childFrame[fieldName]:SetPoint("TOPLEFT",  self.SCROLL_MARGIN.left + 20, -parent.insertHeight)
        parent.childFrame[fieldName]:SetWidth(24)
        parent.childFrame[fieldName]:SetHeight(24)
        parent.childFrame[fieldName]:SetScale(1)
        
        -- Create label
        parent.childFrame[fieldName].Text = parent.childFrame[fieldName]:CreateFontString(parent.childFrame[fieldName]:GetName() .. "Text", "ARTWORK", "GameFontNormal")
        parent.childFrame[fieldName].Text:SetPoint("LEFT", parent.childFrame[fieldName], "RIGHT", 0, 2)
        parent.childFrame[fieldName].Text:SetText(text)
        parent.childFrame[fieldName].Text:SetTextColor(1, 1, 1, 1)
        
        -- Set events
        parent.childFrame[fieldName]:SetScript("OnShow", onShow)
        parent.childFrame[fieldName]:SetScript("PostClick", function(self)
            postClick(self)
            XToLevel.Average:Update()
            XToLevel.LDB:BuildPattern()
            XToLevel.LDB:Update()    
        end)
        
        parent.insertHeight = parent.insertHeight + 26
        
        return parent.childFrame[fieldName]
    end,
    
    ---
    -- Creates an editable text input box.
    -- @param parent The panel to which this button should belong
    -- @param fieldName The name of the field, assigned to the parent frame.
    -- @param text The initial text of the button.
    -- @param width The width of the button.
    -- @param height The height of the button.
    -- @param onPatternUpdate The function to execute when the OnShow event is fired.
    CreateEditBox = function(self, parent, fieldName, text, width, height, onPatternUpdate)
        parent.childFrame[fieldName] = CreateFrame("EditBox", parent.childFrame:GetName() .. "_" .. fieldName, parent.childFrame)--, "InputBoxTemplate")
        parent.childFrame[fieldName]:SetPoint("TOPLEFT", self.SCROLL_MARGIN.left + 30, -parent.insertHeight)
        parent.insertHeight = parent.insertHeight + 33
        parent.childFrame[fieldName]:SetText(text)
        parent.childFrame[fieldName]:SetAutoFocus(false)
    	parent.childFrame[fieldName]:SetFontObject(GameFontHighlightSmall)
    	parent.childFrame[fieldName]:SetJustifyH("LEFT")
    	parent.childFrame[fieldName]:SetCursorPosition(0)
    	parent.childFrame[fieldName]:SetBackdrop({
			bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
			edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
			tile = true, edgeSize = 1, tileSize = 5,
		})
		parent.childFrame[fieldName]:SetBackdropColor(0,0,0,0.5)
		parent.childFrame[fieldName]:SetBackdropBorderColor(0.3,0.3,0.30,0.80)
        
        
        if width ~= nil and type(width) == "number" then
            parent.childFrame[fieldName]:SetWidth(width)
        else    
            parent.childFrame[fieldName]:SetWidth(250)
        end
        if false and height ~= nil and type(height) == "number" then
            parent.childFrame[fieldName]:SetHeight(height)
        else    
            parent.childFrame[fieldName]:SetHeight(15)
        end
        
        parent.childFrame[fieldName]:SetScript("OnShow", function() this:SetCursorPosition(1) end)
        parent.childFrame[fieldName]:SetScript("OnEditFocusLost", function() onPatternUpdate(this, this:GetText())  end)
        parent.childFrame[fieldName]:SetScript("OnEnterPressed", function() this:ClearFocus();  end)
        parent.childFrame[fieldName]:SetScript("OnTabPressed", function() this:ClearFocus(); end)
        parent.childFrame[fieldName]:SetScript("OnEscapePressed", function() this:ClearFocus(); end)
        
        return parent.childFrame[fieldName]
    end,
    
    ---
    -- Creates a button
    -- @param parent The panel to which this button should belong
    -- @param fieldName The name of the field, assigned to the parent frame.
    -- @param text The check button's label.
    -- @param width The width of the button.
    -- @param height The height of the button.
    -- @param onShow The function to execute when the OnShow event is fired.
    -- @param onClick The function to execute when the OnClick even is fired.
    -- @param float If true, what follows the button will appear to the left of this button.
    CreateButton = function(self, parent, fieldName, text, width, height, onShow, onClick, float)
        parent.childFrame[fieldName] = CreateFrame("Button", parent.childFrame:GetName() .. "_" .. fieldName, parent.childFrame, "UIPanelButtonTemplate")
        parent.childFrame[fieldName]:EnableMouse(true)
        parent.childFrame[fieldName]:SetText(text)
        
        if width == nil or type(width) ~= "number" then
            width = 150
        end
        if height == nil or type(height) ~= "number" then
            height = 30
        end
        parent.childFrame[fieldName]:SetWidth(width)
        parent.childFrame[fieldName]:SetHeight(height)
        parent.childFrame[fieldName]:SetPoint("TOPLEFT", self.SCROLL_MARGIN.left + 30 + parent.insertLeft, -parent.insertHeight)
        
        if float then
        	parent.insertLeft = parent.insertLeft + width + 10
        else
        	parent.insertHeight = parent.insertHeight + height + 3
        	parent.insertLeft = 0
    	end
        
        parent.childFrame[fieldName]:SetScript("OnShow", onShow)
        parent.childFrame[fieldName]:SetScript("OnClick", function(self) onClick(self) end)
        
        return parent.childFrame[fieldName]
    end,
    
    ---
    -- Creates a Drop Down box.
    -- @param parent The panel to which this button should belong
    -- @param fieldName The name of the field, assigned to the parent frame.
    -- @param fields An array of values for to select from.
    -- @param default The default choice. Should be one of the choices from the array! (obviously)
    -- @param onShow The function to execute when the OnShow event is fired.
    -- @param onChange The function to execute when the OnChange even is fired.
    CreateSelectBox = function(self, parent, fieldName, fields, default, onShow, onChange)
        parent.childFrame[fieldName] = CreateFrame("Button", parent.childFrame:GetName() .. "_" .. fieldName, parent.childFrame, "XToLevel_Config_DropDown")
        parent.childFrame[fieldName].initialized = false
        parent.childFrame[fieldName].fields = fields
        parent.childFrame[fieldName].defaultField = default
        parent.childFrame[fieldName]:SetPoint("TOPLEFT", self.SCROLL_MARGIN.left + 15, -parent.insertHeight)
        
        parent.insertHeight = parent.insertHeight + 30
        
        parent.childFrame[fieldName]:SetScript("OnHide", function(self) CloseDropDownMenus() end)
        parent.childFrame[fieldName]:SetScript("OnShow", function()
            if not parent.childFrame[fieldName].initialized then
                parent.childFrame[fieldName].initialized = true
                local cb_init_fn = function()
                    local info
                    local num = # fields
                    local i = 1
                    while i <= num do
                        info = {}
                        info.text = fields[i]
                        info.func = function() 
                            UIDropDownMenu_SetSelectedID(parent.childFrame[fieldName], this:GetID(), 0);
                            if onShow ~= nil and type(onShow) == "function" then
                                onChange(parent.childFrame[fieldName])
                            end
                        end
                        UIDropDownMenu_AddButton(info);
                        i = i + 1
                    end
                end
                UIDropDownMenu_Initialize(this, cb_init_fn)
            end
            if onShow ~= nil and type(onShow) == "function" then
                onShow()
            end
        end)
    end,
    
    ---
    -- Creates a slider to select integer values from.
    -- @param parent The panel to which the new slider should be on.
    -- @param fieldName The name of the field.
    -- @param label The label. Will be put to the left of the slider. Will be truncated to 10 chars.
    -- @param min The 
    CreateRange = function(self, parent, fieldName, label, min, max, inital, onChange)
    	parent.childFrame[fieldName] = { }
    	
    	-- Create the value box.
    	parent.childFrame[fieldName].label = parent.childFrame:CreateFontString(parent:GetName() .. "_" .. fieldName .. "_Label", "ARTWORK", "GameFontNormal")
    	parent.childFrame[fieldName].label:SetPoint("TOPLEFT", 15, -parent.insertHeight)
    	parent.childFrame[fieldName].label:SetPoint("TOPRIGHT", 0, -parent.insertHeight)
    	parent.childFrame[fieldName].label:SetHeight(15)
    	parent.childFrame[fieldName].label:SetText(label)
    	parent.childFrame[fieldName].label:SetJustifyH("CENTER")
    	
    	parent.insertHeight = parent.insertHeight + 15
    	
    	-- Create the slider
    	parent.childFrame[fieldName].slider = CreateFrame("Slider", parent.childFrame:GetName() .. "_" .. fieldName .. "_Slider", parent.childFrame)
    	parent.childFrame[fieldName].slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    	parent.childFrame[fieldName].slider:SetBackdrop({
			  bgFile = "Interface\\Buttons\\UI-SliderBar-Background",  
			  edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
			  tile = true, tileSize = 8, edgeSize = 8,
			  insets = { left = 3, right = 3, top = 6, bottom = 6 }
			})
    	parent.childFrame[fieldName].slider:SetOrientation("HORIZONTAL")
    	parent.childFrame[fieldName].slider:SetMinMaxValues(min, max)
    	parent.childFrame[fieldName].slider:SetValue(inital)
    	parent.childFrame[fieldName].slider:SetValueStep(1)
    	parent.childFrame[fieldName].slider:SetHeight(14)
    	parent.childFrame[fieldName].slider:SetPoint("TOPLEFT", 15, -(parent.insertHeight))
    	parent.childFrame[fieldName].slider:SetPoint("TOPRIGHT", 0, -(parent.insertHeight))
    	
    	parent.insertHeight = parent.insertHeight + 14
    	
    	-- Add the min and max values
    	parent.childFrame[fieldName].minLabel = parent.childFrame:CreateFontString(parent:GetName() .. "_" .. fieldName .. "_MinLabel", "ARTWORK", "SystemFont_Tiny")
    	parent.childFrame[fieldName].minLabel:SetPoint("TOPLEFT", parent.childFrame[fieldName].slider, "BOTTOMLEFT", 0, 5)
    	parent.childFrame[fieldName].minLabel:SetHeight(15)
    	parent.childFrame[fieldName].minLabel:SetText(tostring(min))
    	parent.childFrame[fieldName].minLabel:SetJustifyH("LEFT")
    	
    	parent.childFrame[fieldName].maxLabel = parent.childFrame:CreateFontString(parent:GetName() .. "_" .. fieldName .. "_MaxLabel", "ARTWORK", "SystemFont_Tiny")
    	parent.childFrame[fieldName].maxLabel:SetPoint("TOPRIGHT", parent.childFrame[fieldName].slider, "BOTTOMRIGHT", -5, 5)
    	parent.childFrame[fieldName].maxLabel:SetHeight(15)
    	parent.childFrame[fieldName].maxLabel:SetText(tostring(max))
    	parent.childFrame[fieldName].maxLabel:SetJustifyH("RIGHT")
    	
    	-- Create the value box.
    	parent.childFrame[fieldName].value = CreateFrame("EditBox", parent.childFrame:GetName() .. "_" .. fieldName .. "_Value", parent.childFrame)
    	parent.childFrame[fieldName].value:SetPoint("TOP", parent.childFrame[fieldName].slider, "BOTTOM")
    	parent.childFrame[fieldName].value:SetHeight(15)
    	parent.childFrame[fieldName].value:SetWidth(50)
    	parent.childFrame[fieldName].value:SetText(tostring(inital))
    	parent.childFrame[fieldName].value:SetFontObject(GameFontHighlightSmall)
    	parent.childFrame[fieldName].value:SetJustifyH("CENTER")
    	parent.childFrame[fieldName].value:SetAutoFocus(false)
    	parent.childFrame[fieldName].value:SetCursorPosition(0)
    	parent.childFrame[fieldName].value:SetBackdrop({
			bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
			edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
			tile = true, edgeSize = 1, tileSize = 5,
		})
		parent.childFrame[fieldName].value:SetBackdropColor(0,0,0,0.5)
		parent.childFrame[fieldName].value:SetBackdropBorderColor(0.3,0.3,0.30,0.80)
		
		parent.insertHeight = parent.insertHeight + 20
    	
    	
    	-- Set events
    	parent.childFrame[fieldName].value:SetScript("OnShow", function() this:SetCursorPosition(1) end)
        parent.childFrame[fieldName].value:SetScript("OnEditFocusLost", function() 
        	local newValue = tonumber(parent.childFrame[fieldName].value:GetText())
        	if type(newValue) ~= "number" or newValue < min or newValue > max then
        		console:log("Value invalid! " .. tostring(newValue) .. " (" .. type(newValue) ..")")
        		parent.childFrame[fieldName].value:SetText(tostring(parent.childFrame[fieldName].slider:GetValue()))
    		else
    			parent.childFrame[fieldName].slider:SetValue(newValue)
        	end
    	end)
        parent.childFrame[fieldName].value:SetScript("OnEnterPressed", function() this:ClearFocus();  end)
        parent.childFrame[fieldName].value:SetScript("OnTabPressed", function() this:ClearFocus(); end)
        parent.childFrame[fieldName].slider:SetScript("OnValueChanged",
        	function(self, value)
        		parent.childFrame[fieldName].value:SetText(tostring(value))
        		-- onChange(self, value)
        	end)
    	parent.childFrame[fieldName].slider:SetScript("OnMouseUp",
    		function()
    			onChange(self, parent.childFrame[fieldName].slider:GetValue())
    		end)
    end,
    
    ---
    -- Creates a color picker frame.
    -- @param parent The frame's parent.
    -- @param fieldName The name to give the field.
    -- @param label The text to place next to the color icon
    -- @param initalColor An array of r, g, b and a values that the frame should initally use.
    -- @param onChange The callback function to call when the color changes.
    CreateColorPicker = function(self, parent, fieldName, label, initalColor, onChange)
    	parent.childFrame[fieldName] = CreateFrame("Frame", parent.childFrame:GetName() .. "_" .. fieldName, parent.childFrame, "XToLevel_ColorPicker")
    	parent.childFrame[fieldName].currentColor = initalColor
    	_G[parent.childFrame:GetName() .. "_" .. fieldName .. "Text"]:SetText(label)
    	_G[parent.childFrame:GetName() .. "_" .. fieldName .. "Color"]:SetTexture(unpack(initalColor or {1, 1, 1, 1}))
    	parent.childFrame[fieldName].colorChangeCallback = onChange
    	parent.childFrame[fieldName]:SetPoint("TOPLEFT", self.SCROLL_MARGIN.left + parent.insertLeft + 20, -parent.insertHeight)
    	parent.insertLeft = parent.insertLeft + (self.SCROLL_DIMENSIONS.width / 3)
    	if parent.insertLeft >= self.SCROLL_DIMENSIONS.width then
    		parent.insertLeft = 0
    		parent.insertHeight = parent.insertHeight + 30
    	end
    	return parent.childFrame[fieldName]
    end,
}

---
-- Verifies that all config values have a default value
-- (New values are sometimes not initialized if older versions of saved values exist)
function XToLevel.Config:Verify()
    -- General
    if sConfig.general == nil then sConfig.general = {  } end
    if sConfig.general.allowDrag == nil then sConfig.general.allowDrag = true end
    if sConfig.general.showDebug == nil then sConfig.general.showDebug = false end
    if sConfig.general.allowSettingsClick == nil then sConfig.general.allowSettingsClick = true end
    if sConfig.general.displayLocale == nil then sConfig.general.displayLocale = GetLocale() end
    if sConfig.general.rafEnabled == nil then sConfig.general.rafEnabled = false end
	if sConfig.general.showNpcTooltipData == nil then sConfig.general.showNpcTooltipData = true end
    
    -- Messages
    if sConfig.messages == nil then sConfig.messages = {  } end
    if sConfig.messages.playerFloating == nil then sConfig.messages.playerFloating = true end
    if sConfig.messages.playerChat == nil then sConfig.messages.playerChat = false end
    if sConfig.messages.petFloating == nil then sConfig.messages.petFloating = true end
    if sConfig.messages.petChat == nil then sConfig.messages.petChat = false end
    if sConfig.messages.bgObjectives == nil then sConfig.messages.bgObjectives = true end
    
    -- Message Colors
    if sConfig.messages.colors == nil then sConfig.messages.colors = {} end
    if sConfig.messages.colors.playerKill == nil then sConfig.messages.colors.playerKill = {0.72, 1, 0.71, nil} end
    if sConfig.messages.colors.playerQuest == nil then sConfig.messages.colors.playerQuest = {0.5, 1, 0.7, nil} end
    if sConfig.messages.colors.playerBattleground == nil then sConfig.messages.colors.playerBattleground = {1, 0.5, 0.5, nil} end
    if sConfig.messages.colors.playerDungeon == nil then sConfig.messages.colors.playerDungeon = {1, 0.75, 0.35, nil} end
    if sConfig.messages.colors.playerLevel == nil then sConfig.messages.colors.playerLevel = {0.35, 1, 0.35, nil} end
    if sConfig.messages.colors.petKill == nil then sConfig.messages.colors.petKill = {0.52, 0.73, 1, nil} end
    
    if sConfig.messages.colors.playerKill[4] ~= nil then sConfig.messages.colors.playerKill[4] = nil end
    if sConfig.messages.colors.playerQuest[4] ~= nil then sConfig.messages.colors.playerQuest[4] = nil end
    if sConfig.messages.colors.playerBattleground[4] ~= nil then sConfig.messages.colors.playerBattleground[4] = nil end
    if sConfig.messages.colors.playerDungeon[4] ~= nil then sConfig.messages.colors.playerDungeon[4] = nil end
    if sConfig.messages.colors.playerLevel[4] ~= nil then sConfig.messages.colors.playerLevel[4] = nil end
    if sConfig.messages.colors.petKill[4] ~= nil then sConfig.messages.colors.petKill[4] = nil end
    
    -- averageDisplay
    if sConfig.averageDisplay == nil then sConfig.averageDisplay = {  } end
    if sConfig.averageDisplay.visible == nil then sConfig.averageDisplay.visible = true end
    if sConfig.averageDisplay.showPetFrame == nil then sConfig.averageDisplay.showPetFrame = true end
    if sConfig.averageDisplay.detachPetFrame == nil then sConfig.averageDisplay.detachPetFrame = false end
    if sConfig.averageDisplay.mode == nil then sConfig.averageDisplay.mode = 1 end
    if sConfig.averageDisplay.backdrop == nil then sConfig.averageDisplay.backdrop = true end
    if sConfig.averageDisplay.verbose == nil then sConfig.averageDisplay.verbose = true end
    if sConfig.averageDisplay.tooltip == nil then sConfig.averageDisplay.tooltip = true end
    if sConfig.averageDisplay.combineTooltip == nil then sConfig.averageDisplay.combineTooltip = false end
    if sConfig.averageDisplay.orientation == nil then sConfig.averageDisplay.orientation = 'v' end
    if sConfig.averageDisplay.colorText == nil then sConfig.averageDisplay.colorText = true end
    if sConfig.averageDisplay.header == nil then sConfig.averageDisplay.header = true end
    if sConfig.averageDisplay.playerKills == nil then sConfig.averageDisplay.playerKills = true end
    if sConfig.averageDisplay.playerQuests == nil then sConfig.averageDisplay.playerQuests = true end
    if sConfig.averageDisplay.playerDungeons == nil then sConfig.averageDisplay.playerDungeons = true end
    if sConfig.averageDisplay.playerBGs == nil then sConfig.averageDisplay.playerBGs = true end
    if sConfig.averageDisplay.playerBGOs == nil then sConfig.averageDisplay.playerBGOs = false end
    if sConfig.averageDisplay.playerProgress == nil then sConfig.averageDisplay.playerProgress = true end
	if sConfig.averageDisplay.playerTimer == nil then sConfig.averageDisplay.playerTimer = true end
    if sConfig.averageDisplay.petKills == nil then sConfig.averageDisplay.petKills = true end
    if sConfig.averageDisplay.petProgress == nil then sConfig.averageDisplay.petProgress = true end
    if sConfig.averageDisplay.progress == nil then sConfig.averageDisplay.progress = true end
    if sConfig.averageDisplay.progressAsBars == nil then sConfig.averageDisplay.progressAsBars = false end
    if sConfig.averageDisplay.playerKillListLength == nil then sConfig.averageDisplay.playerKillListLength = 10 end
    if sConfig.averageDisplay.playerQuestListLength == nil then sConfig.averageDisplay.playerQuestListLength = 10 end
    if sConfig.averageDisplay.playerBGListLength == nil then sConfig.averageDisplay.playerBGListLength = 15 end
    if sConfig.averageDisplay.playerBGOListLength == nil then sConfig.averageDisplay.playerBGOListLength = 15 end
    if sConfig.averageDisplay.playerDungeonListLength == nil then sConfig.averageDisplay.playerDungeonListLength = 15 end
    if sConfig.averageDisplay.petKillListLength == nil then sConfig.averageDisplay.petKillListLength = 10 end

    -- LDB
    if sConfig.ldb == nil then sConfig.ldb = {  } end
    if sConfig.ldb.text == nil then sConfig.ldb.text = {  } end
    if sConfig.ldb.tooltip == nil then sConfig.ldb.tooltip = {  } end
    if sConfig.ldb.allowTextColor == nil then sConfig.ldb.allowTextColor = true end
    if sConfig.ldb.showIcon == nil then sConfig.ldb.showIcon = true end
    if sConfig.ldb.showLabel == nil then sConfig.ldb.showLabel = false end
    if sConfig.ldb.showText == nil then sConfig.ldb.showText = true end
    if sConfig.ldb.textPattern == nil then sConfig.ldb.textPattern = "default" end
    if sConfig.ldb.text.kills == nil then sConfig.ldb.text.kills = true end
    if sConfig.ldb.text.quests == nil then sConfig.ldb.text.quests = true end
    if sConfig.ldb.text.dungeons == nil then sConfig.ldb.text.dungeons = true end
    if sConfig.ldb.text.bgs == nil then sConfig.ldb.text.bgs = true end
    if sConfig.ldb.text.bgo == nil then sConfig.ldb.text.bgo = false end
    if sConfig.ldb.text.pet == nil then sConfig.ldb.text.pet = true end
    if sConfig.ldb.text.xp == nil then sConfig.ldb.text.xp = true end
    if sConfig.ldb.text.xpAsBars == nil then sConfig.ldb.text.xpAsBars = false end
    if sConfig.ldb.text.petxp == nil then sConfig.ldb.text.petxp = true end
	if sConfig.ldb.text.petxpnum == nil then sConfig.ldb.text.petxpnum = true end
	if sConfig.ldb.text.timer == nil then sConfig.ldb.text.timer = true end
    if sConfig.ldb.text.verbose == nil then sConfig.ldb.text.verbose = true end
    if sConfig.ldb.text.colorValues == nil then sConfig.ldb.text.colorValues = true end
	
	if sConfig.ldb.text.xpCountdown == nil then sConfig.ldb.text.xpCountdown = false end
	if sConfig.ldb.text.rested == nil then sConfig.ldb.text.rested = true end
	if sConfig.ldb.text.restedp == nil then sConfig.ldb.text.restedp = true end
	
	if sConfig.ldb.text.xpnum == nil then sConfig.ldb.text.xpnum = true end
	if sConfig.ldb.text.xpnumFormat == nil then sConfig.ldb.text.xpnumFormat = true end
	
    if sConfig.ldb.tooltip.showDetails == nil then sConfig.ldb.tooltip.showDetails = true end
    if sConfig.ldb.tooltip.showExperience == nil then sConfig.ldb.tooltip.showExperience = true end
    if sConfig.ldb.tooltip.showBGInfo == nil then sConfig.ldb.tooltip.showBGInfo = true end
    if sConfig.ldb.tooltip.showDungeonInfo == nil then sConfig.ldb.tooltip.showDungeonInfo = true end
    if sConfig.ldb.tooltip.showPetInfo == nil then sConfig.ldb.tooltip.showPetInfo = true end
	if sConfig.ldb.tooltip.showTimerInfo == nil then sConfig.ldb.tooltip.showTimerInfo = true end
	
	if sConfig.timer == nil then sConfig.timer = { } end
	if sConfig.timer.enabled == nil then sConfig.timer.enabled = true end
	if sConfig.timer.mode == nil then sConfig.timer.mode = 1 end
	if sConfig.timer.allowLevelFallback == nil then sConfig.timer.allowLevelFallback = 1 end
    
    -- Data
    if sData == nil then sData = {} end
    if sData.player == nil then sData.player = {} end
    if sData.pet == nil then sData.pet = {} end
    if sData.player.killAverage == nil then sData.player.killAverage = 0 end
    if sData.player.questAverage == nil then sData.player.questAverage = 0 end
    if sData.player.killList == nil then sData.player.killList = {} end
    if sData.player.questList == nil then sData.player.questList = {} end
    if sData.player.bgList == nil then sData.player.bgList = {} end
    if sData.player.dungeonList == nil then sData.player.dungeonList = {} end
	if sData.player.timer == nil then sData.player.timer = {} end
    if sData.pet.killAverage == nil then sData.pet.killAverage = 0 end
    if sData.pet.killList == nil then sData.pet.killList = {} end
    if sData.customPattern == nil then sData.customPattern = 0 end
	
	-- Timer data. Move old data into the last session var if it is available.
	sData.player.timer.start = time()
	sData.player.timer.total = 0
	if sData.player.timer.xpPerSecond == nil then sData.player.timer.xpPerSecond = 0 end
    
    -- Dungeon data
    --for index, value in ipairs(sData.player.dungeonList) do
    for index = 1, # sData.player.dungeonList, 1 do
    	if not sData.player.dungeonList[index].rested then
    		sData.player.dungeonList[index].rested = 0
    	end
    end
    
end
