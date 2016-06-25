--[[----
--
-- Broker_WorldQuests
--
-- World of Warcraft addon to display Legion world quests in convenient list form.
-- Doesn't do anything on its own; requires a data broker addon!
--
-- Author: myno
-- Version: r3
--
--]]----

local ITEM_QUALITY_COLORS, WORLD_QUEST_QUALITY_COLORS = ITEM_QUALITY_COLORS, WORLD_QUEST_QUALITY_COLORS
local GetQuestsForPlayerByMapID = C_TaskQuest.GetQuestsForPlayerByMapID
local GetQuestTimeLeftMinutes = C_TaskQuest.GetQuestTimeLeftMinutes
local GetQuestTagInfo = GetQuestTagInfo
local GetQuestInfoByQuestID = C_TaskQuest.GetQuestInfoByQuestID
local GetFactionInfoByID = GetFactionInfoByID
local GetQuestObjectiveInfo = GetQuestObjectiveInfo
local GetQuestProgressBarInfo = C_TaskQuest.GetQuestProgressBarInfo
local UnitLevel, IsQuestFlaggedCompleted = UnitLevel, IsQuestFlaggedCompleted
local GetCurrentMapAreaID, GetCurrentMapContinent, GetCurrentMapDungeonLevel = GetCurrentMapAreaID, GetCurrentMapContinent, GetCurrentMapDungeonLevel
local GetNumQuestLogRewards, GetQuestLogRewardInfo, GetQuestLogRewardMoney = GetNumQuestLogRewards, GetQuestLogRewardInfo, GetQuestLogRewardMoney
local GetNumQuestLogRewardCurrencies, GetQuestLogRewardCurrencyInfo = GetNumQuestLogRewardCurrencies, GetQuestLogRewardCurrencyInfo

local WORLD_QUEST_ICONS_BY_TAG_ID = {
	[114] = "worldquest-icon-firstaid",
	[116] = "worldquest-icon-blacksmithing",
	[117] = "worldquest-icon-leatherworking",
	[118] = "worldquest-icon-alchemy",
	[119] = "worldquest-icon-herbalism",
	[120] = "worldquest-icon-mining",
	[122] = "worldquest-icon-engineering",
	[123] = "worldquest-icon-enchanting",
	[125] = "worldquest-icon-jewelcrafting",
	[126] = "worldquest-icon-inscription",
	[129] = "worldquest-icon-archaeology",
	[130] = "worldquest-icon-fishing",
	[131] = "worldquest-icon-cooking",
	[121] = "worldquest-icon-tailoring",
	[124] = "worldquest-icon-skinning",
	[137] = "worldquest-icon-dungeon",
	[113] = "worldquest-icon-pvp-ffa",
	[115] = "worldquest-icon-petbattle",
	[111] = "worldquest-questmarker-dragon",
	[112] = "worldquest-questmarker-dragon",
	[136] = "worldquest-questmarker-dragon",
}

local MAP_ZONES = {
	GetMapNameByID(1015), 1015,  -- Aszuna
	GetMapNameByID(1096), 1096,  -- Eye of Azshara
	GetMapNameByID(1018), 1018,  -- Val'sharah
	GetMapNameByID(1024), 1024,  -- Highmountain
	GetMapNameByID(1017), 1017,  -- Stormheim
	GetMapNameByID(1033), 1033,  -- Suramar
	GetMapNameByID(1014), 1014,  -- Dalaran
}

local BWQ = CreateFrame("Frame", "Broker_WorldQuests", UIParent)
BWQ:SetFrameStrata("HIGH")
BWQ:EnableMouse(true)
BWQ:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground", 
		edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
		tile = false,
		tileSize = 0, 
		edgeSize = 2, 
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	})
BWQ:SetBackdropColor(0, 0, 0, .9)
BWQ:SetBackdropBorderColor(0, 0, 0, 1)
BWQ:Hide()

local FilterButtonWrapper = CreateFrame("Frame", "BWQ_FilterButtonWrapper", BWQ)

-- local Block_OnEnter = function(self)
	
-- end
local Block_OnLeave = function(self)
	if not BWQ:IsMouseOver() then
		BWQ:Hide()
	end
end

--BWQ:SetScript("OnEnter", Block_OnEnter)
BWQ:SetScript("OnLeave", Block_OnLeave)

local buttonCache = {}
local zoneSepCache = {}
local numQuestsTotal, numQuestsZone, offsetY = 0, 0, 0
local notFinishedLoading = false
local highlightedRow = true

local CreateErrorFS = function(offsetY)
	BWQ.errorFS = BWQ:CreateFontString("BWQerrorFS", "OVERLAY", "SystemFont_Shadow_Med1")
	BWQ.errorFS:SetJustifyH("CENTER")
	BWQ.errorFS:SetTextColor(.9, .8, 0)
	BWQ.errorFS:SetPoint("TOP", BWQ, "TOP", 0, offsetY)
end

local WorldQuestsUnlocked = function()
	if UnitLevel("player") < 110 or not IsQuestFlaggedCompleted(43341) then -- http://legion.wowhead.com/quest=43341/a-world-of-quests
		if not BWQ.errorFS then CreateErrorFS(-10) end

		BWQ:SetSize(BWQ.errorFS:GetStringWidth() + 20, BWQ.errorFS:GetStringHeight() + 20)
		BWQ.errorFS:SetText("You need to reach Level 110 and complete the\nquest \124cffffff00\124Hquest:43341:-1\124h[A World of Quests]\124h\124r to unlock World Quests.")
		BWQ.errorFS:Show()

		FilterButtonWrapper:Hide()
		return false
	else
		if BWQ.errorFS then
			BWQ.errorFS:Hide()
		end
		
		FilterButtonWrapper:Show()
		return true
	end
end

local ShowNoWorldQuestsInfo = function()
	if not BWQ.errorFS then CreateErrorFS(-45) end

	BWQ:SetSize(BWQ.errorFS:GetStringWidth() + 20, BWQ.errorFS:GetStringHeight() + 20)
	BWQ.errorFS:SetText("There are no world quests available that match your filter settings.")
	BWQ.errorFS:Show()
end

local RetrieveWorldQuests = function(mapId)
	local quests = {}

	-- set map so api returns proper values for that map
	SetMapByID(mapId)
	local questList = GetQuestsForPlayerByMapID(mapId)

	-- quest object fields are: x, y, floor, numObjectives, questId, inProgress
	if questList then
		local timeLeft, tagId, tagName, worldQuestType, isRare, isElite, tradeskillLineIndex, title, factionId
		for i = 1, #questList do

			--[[
			local tagID, tagName, worldQuestType, isRare, isElite, tradeskillLineIndex = GetQuestTagInfo(v);
			
			tagId = 116
			tagName = Blacksmithing World Quest
			worldQuestType = 
				2 -> profession, 
				3 -> pve?
				4 -> pvp
				5 -> battle pet
				7 -> dungeon
			isRare = 
				1 -> normal
				2 -> rare
				3 -> epic
			isElite = true/false
			tradeskillLineIndex = some number, no idea of meaning atm
			]]

			timeLeft = GetQuestTimeLeftMinutes(questList[i].questId)
			if timeLeft ~= 0 then -- only show available quests
				tagId, tagName, worldQuestType, isRare, isElite, tradeskillLineIndex = GetQuestTagInfo(questList[i].questId);
				if worldQuestType ~= nil then
					local quest = {}
					-- GetQuestsForPlayerByMapID fields
					quest.questId = questList[i].questId
					quest.numObjectives = questList[i].numObjectives

					-- GetQuestTagInfo fields
					quest.tagId = tagId
					quest.tagName = tagName
					quest.worldQuestType = worldQuestType
					quest.isRare = isRare
					quest.isElite = isElite
					quest.tradeskillLineIndex = tradeskillLineIndex

					title, factionId = GetQuestInfoByQuestID(quest.questId)
					quest.title = title
					if factionId then
						quest.faction = GetFactionInfoByID(factionId)
					end
					quest.timeLeft = timeLeft

					quests[#quests+1] = quest
				end
			end
		end
	end

	return quests
end

local FormatTimeLeftString = function(timeLeft)
	local timeLeftStr = ""
	-- if timeLeft >= 60 * 24 then -- at least 1 day
	-- 	timeLeftStr = string.format("%.0fd", timeLeft / 60 / 24)
	-- end
	if timeLeft >= 60 then -- hours
		timeLeftStr = string.format("%.0fh", timeLeft / 60)
	end
	timeLeftStr = string.format("%s%s%sm", timeLeftStr, timeLeftStr ~= "" and " " or "", timeLeft % 60) -- always show minutes

	if timeLeft < 180 then -- highlight less then 3 hours
		timeLeftStr = string.format("|cffe6c800%s|r", timeLeftStr)
	end
	return timeLeftStr
end

local ShowQuestObjectiveTooltip = function(row)
	GameTooltip:SetOwner(row, "ANCHOR_CURSOR", 0, -5)
	local color = WORLD_QUEST_QUALITY_COLORS[row.quest.isRare]
	GameTooltip:AddLine(row.quest.title, color.r, color.g, color.b, true)

	for objectiveIndex = 1, row.quest.numObjectives do
		local objectiveText, objectiveType, finished = GetQuestObjectiveInfo(row.quest.questId, objectiveIndex, false);
		if objectiveText and #objectiveText > 0 then
			color = finished and GRAY_FONT_COLOR or HIGHLIGHT_FONT_COLOR;
			GameTooltip:AddLine(QUEST_DASH .. objectiveText, color.r, color.g, color.b, true);
		end
	end

	local percent = GetQuestProgressBarInfo(row.quest.questId);
	if percent then
		GameTooltip_InsertFrame(GameTooltip, WorldMapTaskTooltipStatusBar);
		WorldMapTaskTooltipStatusBar.Bar:SetValue(percent);
		WorldMapTaskTooltipStatusBar.Bar.Label:SetFormattedText(PERCENTAGE_STRING, percent);
	end

	GameTooltip:Show()
end

local Row_OnClick = function(row)
	ShowUIPanel(WorldMapFrame)
	SetMapByID(row.mapId)

	if IsWorldQuestHardWatched(row.quest.questId) then
		SetSuperTrackedQuestID(row.quest.questId)
	else
		BonusObjectiveTracker_TrackWorldQuest(row.quest.questId)
	end
end

BWQ.UpdateBlock = function()
	if not WorldQuestsUnlocked() then return end

	local originalMap = GetCurrentMapAreaID()
	local originalContinent = GetCurrentMapContinent()
	local originalDungeonLevel = GetCurrentMapDungeonLevel()

	local buttonIndex = 1
	local titleMaxWidth, factionMaxWidth, rewardMaxWidth, timeLeftMaxWidth = 0, 0, 0, 0

	notFinishedLoading = false
	offsetY = -45 -- initial padding from top
	numQuestsTotal = 0
	highlightedRow = true

	for mapIndex = 1, #MAP_ZONES do

		if mapIndex % 2 == 1 then -- uneven are zone names, even are ids
			
			if mapIndex > #zoneSepCache then
				zoneNameFS = BWQ:CreateFontString("BWQzoneNameFS", "OVERLAY", "SystemFont_Shadow_Med1")
				zoneNameFS:SetJustifyH("LEFT")
				zoneNameFS:SetTextColor(.9, .8, 0)
				zoneSepCache[mapIndex] = zoneNameFS

				local zoneSep = BWQ:CreateTexture()
				zoneSep:SetTexture("Interface\\FriendsFrame\\UI-FriendsFrame-OnlineDivider")
				zoneSep:SetHeight(8)
				zoneSepCache[mapIndex+1] = zoneSep
			end

		else

			local quests = RetrieveWorldQuests(MAP_ZONES[mapIndex])
			numQuestsTotal = numQuestsTotal + #quests -- count quests to show text when none are in list
			numQuestsZone = #quests -- count quests to hide zone header if all are hidden
				
			if #quests > 0 then
				zoneSepCache[mapIndex-1]:Show()
				zoneSepCache[mapIndex]:Show()
				zoneSepCache[mapIndex-1]:SetPoint("TOP", BWQ, "TOP", 15, offsetY)
				zoneSepCache[mapIndex]:SetPoint("TOP", BWQ, "TOP", 5, offsetY - 3)
				
				zoneSepCache[mapIndex-1]:SetText(MAP_ZONES[mapIndex-1])

				offsetY = offsetY - 16
			else
				zoneSepCache[mapIndex-1]:Hide()
				zoneSepCache[mapIndex]:Hide()
			end

			for questIndex = 1, #quests do

				local button
				if buttonIndex > #buttonCache then

					button = CreateFrame("Button", nil, BWQ)
					button:RegisterForClicks("AnyUp")

					button.highlight = button:CreateTexture()
					button.highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
					button.highlight:SetBlendMode("ADD")
					button.highlight:SetAlpha(0)
					button.highlight:SetAllPoints(button)

					button.rowHighlight = button:CreateTexture()
					button.rowHighlight:SetTexture("Interface\\Buttons\\WHITE8x8")
					button.rowHighlight:SetBlendMode("ADD")
					button.rowHighlight:SetAlpha(0.05)
					button.rowHighlight:SetAllPoints(button)
					
					button:SetScript("OnLeave", function(self)
						Block_OnLeave()
						button.highlight:SetAlpha(0)
					end)
					button:SetScript("OnEnter", function(self)
						button.highlight:SetAlpha(1)
					end)

					button:SetScript("OnClick", function(self)
						Row_OnClick(button)
					end)

					button.icon = button:CreateTexture()
					button.icon:SetTexture("Interface\\QUESTFRAME\\WorldQuest")
					button.icon:SetSize(12, 12)

					-- create font strings
					button.title = CreateFrame("Button", nil, button)
					button.title:SetScript("OnClick", function(self)
						Row_OnClick(button)
					end)
					button.title:SetScript("OnEnter", function(self)
						button.highlight:SetAlpha(1)

						ShowQuestObjectiveTooltip(button)
					end)
					button.title:SetScript("OnLeave", function(self)
						button.highlight:SetAlpha(0)

						GameTooltip:Hide()
						Block_OnLeave()
					end)

					button.titleFS = button:CreateFontString("BWQtitleFS", "OVERLAY", "SystemFont_Shadow_Med1")
					button.titleFS:SetJustifyH("LEFT")
					button.titleFS:SetTextColor(.9, .9, .9)
					button.titleFS:SetWordWrap(false)

					button.factionFS = button:CreateFontString("BWQfactionFS", "OVERLAY", "SystemFont_Shadow_Med1")
					button.factionFS:SetJustifyH("LEFT")
					button.factionFS:SetTextColor(.9, .9, .9)

					button.reward = CreateFrame("Button", nil, button)
					button.reward:SetScript("OnClick", function(self)
						Row_OnClick(button)
					end)

					button.rewardFS = button.reward:CreateFontString("BWQrewardFS", "OVERLAY", "SystemFont_Shadow_Med1")
					button.rewardFS:SetJustifyH("LEFT")
					button.rewardFS:SetTextColor(.9, .9, .9)

					button.timeLeftFS = button:CreateFontString("BWQtimeLeftFS", "OVERLAY", "SystemFont_Shadow_Med1")
					button.timeLeftFS:SetJustifyH("LEFT")
					button.timeLeftFS:SetTextColor(.9, .9, .9)

					buttonCache[buttonIndex] = button
				else
					button = buttonCache[buttonIndex]
				end

				button:Show()

				button.mapId = MAP_ZONES[mapIndex]
				button.quest = quests[questIndex]

				local rewardText = ""
				local hideQuest = true
				if GetNumQuestLogRewards(button.quest.questId) > 0 then
					local itemName, itemTexture, quantity, quality, isUsable, itemId = GetQuestLogRewardInfo(1, button.quest.questId)
					if itemName then
						button.reward.itemName = itemName
						button.reward.itemTexture = itemTexture
						button.reward.itemId = itemId
						button.reward.itemQuality = quality
						button.reward.itemQuantity = quantity
					
						local rewardColor = ITEM_QUALITY_COLORS[button.reward.itemQuality].hex
						local itemSpell = GetItemSpell(button.reward.itemId)
						if itemSpell and itemSpell == "Empowering" then
							rewardColor = "|cffe5cc80"
							if BWQcfg.showArtifactPower then hideQuest = false end
						else
							if BWQcfg.showItems then hideQuest = false end
						end
						rewardText = string.format(
							"|T%s$s:14:14|t %s[%s]\124r%s",
							button.reward.itemTexture,
							rewardColor,
							button.reward.itemName,
							button.reward.itemQuantity > 1 and " x" .. button.reward.itemQuantity or ""
						)

						button.reward:SetScript("OnEvent", function(self, event)
							if event == "MODIFIER_STATE_CHANGED" then
								GameTooltip:SetOwner(button.reward, "ANCHOR_CURSOR", 0, -5)
								GameTooltip:SetQuestLogItem("reward", 1, button.quest.questId)
								GameTooltip:Show()
							end
						end)

						button.reward:SetScript("OnEnter", function(self)
							button.highlight:SetAlpha(1)

							self:RegisterEvent("MODIFIER_STATE_CHANGED")
							GameTooltip:SetOwner(button.reward, "ANCHOR_CURSOR", 0, -5)
							GameTooltip:SetQuestLogItem("reward", 1, button.quest.questId)
							--GameTooltip:SetHyperlink(string.format("item:%d:0:0:0:0:0:0:0", self.itemId))
							GameTooltip:Show()
						end)

						button.reward:SetScript("OnLeave", function(self)
							button.highlight:SetAlpha(0)

							self:UnregisterEvent("MODIFIER_STATE_CHANGED")
							GameTooltip:Hide()
							Block_OnLeave()
						end)
					else
						notFinishedLoading = true
					end
				else
					button.reward:SetScript("OnEnter", function(self)
						button.highlight:SetAlpha(1)
					end)
					button.reward:SetScript("OnLeave", function(self)
						button.highlight:SetAlpha(0)

						GameTooltip:Hide()
						Block_OnLeave()
					end)
				end

				local money = GetQuestLogRewardMoney(button.quest.questId);
				if money > 0 then
					if money < 1500000 then
						if BWQcfg.showLowGold then hideQuest = false end
					else
						if BWQcfg.showHighGold then hideQuest = false end
					end

					local moneyText = GetCoinTextureString(money)
					rewardText = string.format(
						"%s%s%s",
						rewardText,
						rewardText ~= "" and "   " or "", -- insert some space between rewards
						moneyText
					)
				end

				local numQuestCurrencies = GetNumQuestLogRewardCurrencies(button.quest.questId)
				for i = 1, numQuestCurrencies do
					if BWQcfg.showResources then hideQuest = false end

					local name, texture, numItems = GetQuestLogRewardCurrencyInfo(i, button.quest.questId)
					local currencyText = string.format(
						"|T%1$s:14:14|t %2$d %3$s",
						texture,
						numItems,
						name
					)

					rewardText = string.format(
						"%s%s%s",
						rewardText,
						rewardText ~= "" and "   " or "", -- insert some space between rewards
						currencyText
					)
				end

				if hideQuest then
					button:Hide()
					numQuestsZone = numQuestsZone - 1
					numQuestsTotal = numQuestsTotal - 1
				else
					button:SetPoint("TOP", BWQ, "TOP", 0, offsetY)
					offsetY = offsetY - 16

					if highlightedRow then
						button.rowHighlight:Show()
					else
						button.rowHighlight:Hide()
					end
					highlightedRow = not highlightedRow

					-- if button.quest.tagId == 136 or button.quest.tagId == 111 or button.quest.tagId == 112 then
					--button.icon:SetTexCoord(.81, .84, .68, .79) -- skull tex coords
					if WORLD_QUEST_ICONS_BY_TAG_ID[button.quest.tagId] then
						button.icon:SetAtlas(WORLD_QUEST_ICONS_BY_TAG_ID[button.quest.tagId], true)
						button.icon:SetAlpha(1)
					else
						button.icon:SetAlpha(0)
					end
					button.icon:SetSize(12, 12)


					button.titleFS:SetText(string.format("%s%s|r", WORLD_QUEST_QUALITY_COLORS[button.quest.isRare].hex, button.quest.title))
					local titleWidth = button.titleFS:GetStringWidth()
					if titleWidth > titleMaxWidth then titleMaxWidth = titleWidth end

					button.factionFS:SetText(button.quest.faction)
					local factionWidth = button.factionFS:GetStringWidth()
					if factionWidth > factionMaxWidth then factionMaxWidth = factionWidth end

					button.timeLeftFS:SetText(FormatTimeLeftString(button.quest.timeLeft))
					local timeLeftWidth = button.factionFS:GetStringWidth()
					if timeLeftWidth > timeLeftMaxWidth then timeLeftMaxWidth = timeLeftWidth end



					button.rewardFS:SetText(rewardText)

					local rewardWidth = button.rewardFS:GetStringWidth()
					if rewardWidth > rewardMaxWidth then rewardMaxWidth = rewardWidth end
					button.reward:SetHeight(button.rewardFS:GetStringHeight())
					button.title:SetHeight(button.titleFS:GetStringHeight())

					button.icon:SetPoint("LEFT", button, "LEFT", 5, 0)
					button.titleFS:SetPoint("LEFT", button.icon, "RIGHT", 5, 1)
					button.title:SetPoint("LEFT", button.titleFS, "LEFT", 0, 0)
					button.rewardFS:SetPoint("LEFT", button.titleFS, "RIGHT", 10, 0)
					button.reward:SetPoint("LEFT", button.rewardFS, "LEFT", 0, 0)
					button.factionFS:SetPoint("LEFT", button.rewardFS, "RIGHT", 10, 0)
					button.timeLeftFS:SetPoint("LEFT", button.factionFS, "RIGHT", 10, 0)

					--buttonCache[buttonIndex] = button -- save all changes back into the array of buttons
				end

				buttonIndex = buttonIndex + 1
			end -- quest loop

			if #quests > 0 and numQuestsZone == 0 then
				zoneSepCache[mapIndex-1]:Hide()
				zoneSepCache[mapIndex]:Hide()
				offsetY = offsetY + 16
			else
				zoneSepCache[mapIndex-1]:Show()
				zoneSepCache[mapIndex]:Show()
			end
		end -- mapzone/id if
	end -- maps loop

	-- setting the maelstrom continent map via SetMapByID would make it non-interactive
	if originalMap == 751 then
		SetMapZoom(WORLDMAP_MAELSTROM_ID)
	else
		-- set map back to the original map from before updating
		SetMapZoom(originalContinent)
		SetMapByID(originalMap)
		SetDungeonMapLevel(originalDungeonLevel)
	end

	if numQuestsTotal == 0 then
		ShowNoWorldQuestsInfo()
		offsetY = offsetY - 15
	else
		if BWQ.errorFS then BWQ.errorFS:Hide() end
	end

	-- hide buttons if there are more cached than quests available
	for i = buttonIndex, #buttonCache do
		buttonCache[i]:Hide()
	end
	
	titleMaxWidth = titleMaxWidth > 200 and 200 or titleMaxWidth
	for i = 1, (buttonIndex - 1) do
		buttonCache[i]:SetHeight(15)
		buttonCache[i]:SetWidth(titleMaxWidth + factionMaxWidth + rewardMaxWidth + timeLeftMaxWidth)
		buttonCache[i].title:SetWidth(titleMaxWidth)
		buttonCache[i].titleFS:SetWidth(titleMaxWidth)
		buttonCache[i].factionFS:SetWidth(factionMaxWidth)
		buttonCache[i].reward:SetWidth(rewardMaxWidth)
		buttonCache[i].rewardFS:SetWidth(rewardMaxWidth)
		buttonCache[i].timeLeftFS:SetWidth(timeLeftMaxWidth)
	end

	local totalWidth = 10 + titleMaxWidth + factionMaxWidth + rewardMaxWidth + timeLeftMaxWidth + 10
	for i = 1, #MAP_ZONES do
		zoneSepCache[i]:SetWidth(totalWidth)
	end

	BWQ:SetWidth(totalWidth > 550 and totalWidth or 550)
	BWQ:SetHeight(-1 * offsetY + 10)

	if notFinishedLoading then
		C_Timer.After(.1, BWQ.UpdateBlock)
	end
end


local CreateFilterButton = function(buttonName, anchor, firstButton)
	local button = CreateFrame("Button", buttonName, anchor)
	button:SetWidth(100)
	button:SetHeight(25)
	button:SetPoint("LEFT", anchor, firstButton and "LEFT" or "RIGHT", 5, 0)
	button:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground", 
		edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
		tile = false,
		tileSize = 0, 
		edgeSize = 1, 
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	})
	return button
end
local CreateFilterButtonFS = function(fsName, anchor)
	local fs = anchor:CreateFontString(fsName, "OVERLAY", "SystemFont_Shadow_Med1")
	fs:SetJustifyH("CENTER")
	fs:SetTextColor(.9, .8, 0)
	fs:SetPoint("CENTER", anchor, "CENTER")
	return fs
end
local ActivateFilterButton = function(button)
	button:SetBackdropColor(.9, .8, 0, .1)
	button:SetBackdropBorderColor(.9, .8, 0, .7)
	_G[button:GetName().."FS"]:SetTextColor(.9, .8, 0)
end
local DeactivateFilterButton = function(button)
	button:SetBackdropColor(.3, .3, .3, .1)
	button:SetBackdropBorderColor(.3, .3, .3, .7)
	_G[button:GetName().."FS"]:SetTextColor(.4, .4, .4)
end
local ToggleFilterButton = function(button, active)
	if active then
		ActivateFilterButton(button)
	else
		DeactivateFilterButton(button)
	end
end


FilterButtonWrapper:SetHeight(25)
FilterButtonWrapper:SetWidth(555)
FilterButtonWrapper:SetPoint("TOP", BWQ, "TOP", 10, -10)

local FilterButtonArtifactPower = CreateFilterButton("BWQ_FilterButtonArtifactPower", FilterButtonWrapper, true)
FilterButtonArtifactPower:SetBackdropColor(.9, .8, 0, .05)
FilterButtonArtifactPower:SetBackdropBorderColor(.9, .8, 0, .5)
local FilterButtonArtifactPowerFS = CreateFilterButtonFS("BWQ_FilterButtonArtifactPowerFS", FilterButtonArtifactPower)
FilterButtonArtifactPowerFS:SetText("Artifact Power")

FilterButtonArtifactPower:SetScript("OnClick", function(self)
	BWQcfg.showArtifactPower = not BWQcfg.showArtifactPower
	ToggleFilterButton(FilterButtonArtifactPower, BWQcfg.showArtifactPower)
	BWQ:UpdateBlock()
end)

local FilterButtonLowGold = CreateFilterButton("BWQ_FilterButtonLowGold", FilterButtonArtifactPower, false)
FilterButtonLowGold:SetBackdropColor(.9, .8, 0, .05)
FilterButtonLowGold:SetBackdropBorderColor(.9, .8, 0, .5)
local FilterButtonLowGoldFS = CreateFilterButtonFS("BWQ_FilterButtonLowGoldFS", FilterButtonLowGold)
FilterButtonLowGoldFS:SetText("Low Gold")

FilterButtonLowGold:SetScript("OnClick", function(self)
	BWQcfg.showLowGold = not BWQcfg.showLowGold
	ToggleFilterButton(FilterButtonLowGold, BWQcfg.showLowGold)
	BWQ:UpdateBlock()
end)

local FilterButtonHighGold = CreateFilterButton("BWQ_FilterButtonHighGold", FilterButtonLowGold, false)
FilterButtonHighGold:SetBackdropColor(.9, .8, 0, .05)
FilterButtonHighGold:SetBackdropBorderColor(.9, .8, 0, .5)
local FilterButtonHighGoldFS = CreateFilterButtonFS("BWQ_FilterButtonHighGoldFS", FilterButtonHighGold)
FilterButtonHighGoldFS:SetText("High Gold")

FilterButtonHighGold:SetScript("OnClick", function(self)
	BWQcfg.showHighGold = not BWQcfg.showHighGold
	ToggleFilterButton(FilterButtonHighGold, BWQcfg.showHighGold)
	BWQ:UpdateBlock()
end)

local FilterButtonResources = CreateFilterButton("BWQ_FilterButtonResources", FilterButtonHighGold, false)
FilterButtonResources:SetBackdropColor(.9, .8, 0, .05)
FilterButtonResources:SetBackdropBorderColor(.9, .8, 0, .5)
local FilterButtonResourcesFS = CreateFilterButtonFS("BWQ_FilterButtonResourcesFS", FilterButtonResources)
FilterButtonResourcesFS:SetText("Resources")

FilterButtonResources:SetScript("OnClick", function(self)
	BWQcfg.showResources = not BWQcfg.showResources
	ToggleFilterButton(FilterButtonResources, BWQcfg.showResources)
	BWQ:UpdateBlock()
end)

local FilterButtonItems = CreateFilterButton("BWQ_FilterButtonItems", FilterButtonResources, false)
FilterButtonItems:SetBackdropColor(.9, .8, 0, .05)
FilterButtonItems:SetBackdropBorderColor(.9, .8, 0, .5)
local FilterButtonItemsFS = CreateFilterButtonFS("BWQ_FilterButtonItemsFS", FilterButtonItems)
FilterButtonItemsFS:SetText("Items")

FilterButtonItems:SetScript("OnClick", function(self)
	BWQcfg.showItems = not BWQcfg.showItems
	ToggleFilterButton(FilterButtonItems, BWQcfg.showItems)
	BWQ:UpdateBlock()
end)

local InitializeFilterButtons = function()
	if not BWQcfg then
		BWQcfg = {}
		BWQcfg.showArtifactPower = true
		BWQcfg.showItems = true
		BWQcfg.showLowGold = true
		BWQcfg.showHighGold = true
		BWQcfg.showResources = true
	end
	ToggleFilterButton(FilterButtonArtifactPower, BWQcfg.showArtifactPower)
	ToggleFilterButton(FilterButtonLowGold, BWQcfg.showLowGold)
	ToggleFilterButton(FilterButtonHighGold, BWQcfg.showHighGold)
	ToggleFilterButton(FilterButtonResources, BWQcfg.showResources)
	ToggleFilterButton(FilterButtonItems, BWQcfg.showItems)
end

--[[
Opening quest details in the side bar of the world map fires QUEST_LOG_UPDATE event.
To avoid setting the currently shown map again, which would hide the quest details,
skip updating after a WORLD_MAP_UPDATE event happened 
--]]
local skipNextUpdate = false
BWQ:RegisterEvent("QUEST_LOG_UPDATE")
BWQ:RegisterEvent("WORLD_MAP_UPDATE")
BWQ:RegisterEvent("ADDON_LOADED")
BWQ:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == "Broker_WorldQuests" then
		InitializeFilterButtons()
		self:UnregisterEvent("ADDON_LOADED")
	-- skip updating when world map is open
	elseif event == "WORLD_MAP_UPDATE" and WorldMapFrame:IsShown() then
		skipNextUpdate = true
	elseif event == "QUEST_LOG_UPDATE" and not skipNextUpdate then
		skipNextUpdate = false
		BWQ:UpdateBlock()
	end
end)

-- data broker object
local ldb = LibStub("LibDataBroker-1.1")
BWQ.WorldQuestsBroker = ldb:NewDataObject("WorldQuests", {
	type = "launcher",
	label = "World Quests",
	icon = nil,
	OnEnter = function(self)
		BWQ:SetPoint("TOP", self, "BOTTOM", 0, 0)
		BWQ:UpdateBlock()
		BWQ:Show()
	end,
	OnLeave = Block_OnLeave,
	OnClick = function(self, button)
		BWQ:UpdateBlock()
	end,
})
