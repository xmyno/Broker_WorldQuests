--[[----
--
-- Broker_WorldQuests
--
-- World of Warcraft addon to display Legion world quests in convenient list form.
-- Doesn't do anything on its own; requires a data broker addon!
--
-- Author: myno
-- Version: r2a
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
	GetMapNameByID(1018), 1018,  -- Val'sharah
	GetMapNameByID(1024), 1024,  -- Highmountain
	GetMapNameByID(1017), 1017,  -- Stormheim
	GetMapNameByID(1033), 1033,  -- Suramar
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
local numQuests, numZonesWithQuests, offsetY = 0, 0, 0

local WorldQuestsUnlocked = function()
	if UnitLevel("player") < 110 or not IsQuestFlaggedCompleted(43341) then -- http://legion.wowhead.com/quest=43341/a-world-of-quests
		if not BWQ.errorRequiresLv110 then
			BWQ.errorRequiresLv110 = BWQ:CreateFontString("BWQerrorLv110FS", "OVERLAY", "SystemFont_Shadow_Med1")
			BWQ.errorRequiresLv110:SetJustifyH("CENTER")
			BWQ.errorRequiresLv110:SetTextColor(.9, .8, 0)
			BWQ.errorRequiresLv110:SetText("You need to reach Level 110 and complete the\nquest \124cffffff00\124Hquest:43341:-1\124h[A World of Quests]\124h\124r to unlock World Quests.")
			BWQ.errorRequiresLv110:SetPoint("TOP", BWQ, "TOP", 0, -10)

			BWQ:SetSize(BWQ.errorRequiresLv110:GetStringWidth() + 20, 45)
		end

		BWQ.errorRequiresLv110:Show()
		return false
	else
		if BWQ.errorRequiresLv110 then
			BWQ.errorRequiresLv110:Hide()
		end
		return true
	end
end

local RetrieveWorldQuests = function(mapId)

	local quests = {}

	-- set map so api returns proper values for that map
	SetMapByID(mapId)
	local questList = GetQuestsForPlayerByMapID(mapId)

	-- quest object fields are: x, y, floor, numObjectives, questId, inProgress
	if questList then
		local timeLeft, tagId, tagName, worldQuestType, isRare, isElite, tradeskillLineIndex, title, factionId = nil, nil, nil, nil, nil, nil, nil, nil, nil
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
		local objectiveText, objectiveType, finished = GetQuestObjectiveInfo(row.questId, objectiveIndex, false);
		if objectiveText and #objectiveText > 0 then
			color = finished and GRAY_FONT_COLOR or HIGHLIGHT_FONT_COLOR;
			GameTooltip:AddLine(QUEST_DASH .. objectiveText, color.r, color.g, color.b, true);
		end
	end

	local percent = GetQuestProgressBarInfo(row.questId);
	if percent then
		GameTooltip_InsertFrame(GameTooltip, WorldMapTaskTooltipStatusBar);
		WorldMapTaskTooltipStatusBar.Bar:SetValue(percent);
		WorldMapTaskTooltipStatusBar.Bar.Label:SetFormattedText(PERCENTAGE_STRING, percent);
	end

	GameTooltip:Show()
end

local Row_OnClick = function(self)
	ShowUIPanel(WorldMapFrame)
	SetMapByID(self.mapId)

	if IsWorldQuestHardWatched(self.questId) then
		SetSuperTrackedQuestID(self.questId)
	else
		BonusObjectiveTracker_TrackWorldQuest(self.questId)
	end
end

local UpdateBlock = function()

	if not WorldQuestsUnlocked() then return end

	local originalMap = GetCurrentMapAreaID()
	local originalContinent = GetCurrentMapContinent()
	local originalDungeonLevel = GetCurrentMapDungeonLevel()

	local buttonIndex = 1
	local titleMaxWidth, factionMaxWidth, rewardMaxWidth, timeLeftMaxWidth = 0, 0, 0, 0

	offsetY = -10 -- initial padding from top

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
			if #quests > 0 then
				zoneSepCache[mapIndex-1]:Show()
				zoneSepCache[mapIndex]:Show()
				zoneSepCache[mapIndex-1]:SetPoint("TOP", BWQ, "TOP", 15, offsetY)
				zoneSepCache[mapIndex]:SetPoint("TOP", BWQ, "TOP", 5, offsetY - 3)
				
				zoneSepCache[mapIndex-1]:SetText(MAP_ZONES[mapIndex-1])

				offsetY = offsetY - 16
				numZonesWithQuests = numZonesWithQuests + 1
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

					if buttonIndex % 2 == 1 then
						button.rowHighlight = button:CreateTexture()
						button.rowHighlight:SetTexture("Interface\\Buttons\\WHITE8x8")
						button.rowHighlight:SetBlendMode("ADD")
						button.rowHighlight:SetAlpha(0.05)
						button.rowHighlight:SetAllPoints(button)
					end

					button:SetScript("OnLeave", function(self)
						Block_OnLeave()
						self.highlight:SetAlpha(0)
					end)
					button:SetScript("OnEnter", function(self)
						self.highlight:SetAlpha(1)
					end)

					button:SetScript("OnClick", Row_OnClick)

					button.icon = button:CreateTexture()
					button.icon:SetTexture("Interface\\QUESTFRAME\\WorldQuest")
					button.icon:SetSize(12, 12)

					-- create font strings
					button.title = CreateFrame("Button", nil, button)
					button.title:SetScript("OnClick", Row_OnClick)
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
					button.titleFS:SetTextColor(1, 1, 1)
					button.titleFS:SetWordWrap(false)

					button.factionFS = button:CreateFontString("BWQfactionFS", "OVERLAY", "SystemFont_Shadow_Med1")
					button.factionFS:SetJustifyH("LEFT")
					button.factionFS:SetTextColor(1, 1, 1)

					button.reward = CreateFrame("Button", nil, button)
					button.reward:SetScript("OnClick", Row_OnClick)

					button.rewardFS = button.reward:CreateFontString("BWQrewardFS", "OVERLAY", "SystemFont_Shadow_Med1")
					button.rewardFS:SetJustifyH("LEFT")
					button.rewardFS:SetTextColor(1, 1, 1)

					button.timeLeftFS = button:CreateFontString("BWQtimeLeftFS", "OVERLAY", "SystemFont_Shadow_Med1")
					button.timeLeftFS:SetJustifyH("LEFT")
					button.timeLeftFS:SetTextColor(1, 1, 1)

					buttonCache[buttonIndex] = button
				else
					button = buttonCache[buttonIndex]
				end

				button:Show()

				-- set data for button (this is messy :( maybe improve this later? values needed in click listeners on self)
				button.mapId = MAP_ZONES[mapIndex]
				button.reward.mapId = button.mapId
				button.quest = quests[questIndex]
				button.reward.questId = button.quest.questId
				button.questId = button.quest.questId

				button:SetPoint("TOP", BWQ, "TOP", 0, offsetY)
				offsetY = offsetY - 16

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


				local rewardText = ""
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
						end
						rewardText = string.format(
							"|T%s$s:14:14|t %s[%s]\124r%s",
							button.reward.itemTexture,
							rewardColor,
							button.reward.itemName,
							button.reward.itemQuantity > 1 and " x" .. button.reward.itemQuantity or ""
						)

						button.reward:SetScript("OnEnter", function(self)
							button.highlight:SetAlpha(1)

							GameTooltip:SetOwner(self, "ANCHOR_CURSOR", 0, -5)
							GameTooltip:SetQuestLogItem("reward", 1, self.questId)
							--GameTooltip:SetHyperlink(string.format("item:%d:0:0:0:0:0:0:0", self.itemId))
							GameTooltip:Show()
						end)

						button.reward:SetScript("OnLeave", function(self)
							button.highlight:SetAlpha(0)

							GameTooltip:Hide()
							Block_OnLeave()
						end)
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

				buttonCache[buttonIndex] = button -- save all changes back into the array of buttons

				buttonIndex = buttonIndex + 1

			end -- quest loop
		end -- mapzone/id if
	end -- maps loop

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

	BWQ:SetWidth(totalWidth)

	-- setting the maelstrom continent map via SetMapByID would make it non-interactive
	if originalMap == 751 then
		SetMapZoom(WORLDMAP_MAELSTROM_ID)
	else
		-- set map back to the original map from before updating
		SetMapZoom(originalContinent)
		SetMapByID(originalMap)
		SetDungeonMapLevel(originalDungeonLevel)
	end
	BWQ:SetHeight(-1 * offsetY + 10)
end

--[[
Opening quest details in the side bar of the world map fires QUEST_LOG_UPDATE event.
To avoid setting the currently shown map again, which would hide the quest details,
skip updating after a WORLD_MAP_UPDATE event happened 
--]]
local skipNextUpdate = false
BWQ:RegisterEvent("QUEST_LOG_UPDATE")
BWQ:RegisterEvent("WORLD_MAP_UPDATE")
BWQ:SetScript("OnEvent", function(self, event)
	if event == "WORLD_MAP_UPDATE" and WorldMapFrame:IsShown() then
		skipNextUpdate = true
	elseif event == "QUEST_LOG_UPDATE" and not skipNextUpdate then
		skipNextUpdate = false
		UpdateBlock()
	end
end)

-- data broker object
local ldb = LibStub("LibDataBroker-1.1")
BWQ.WorldQuestsBroker = ldb:NewDataObject("WorldQuests", {
	type = "launcher",
	label = "World Quests",
	icon = nil,
	OnEnter = function(self)
		UpdateBlock()
		BWQ:SetPoint("TOP", self, "BOTTOM", 0, 0)
		BWQ:Show()
	end,
	OnLeave = Block_OnLeave,
	OnClick = function(self, button)
		UpdateBlock()
	end,
})
