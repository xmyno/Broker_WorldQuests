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

local defaultConfig = {
	-- general
	alwaysShowBountyQuests = true,
	hidePetBattleBountyQuests = false,
	-- reward type
	showArtifactPower = true,
	showItems = true,
		showGear = true,
		showRelics = true,
		showCraftingMaterials = true,
		showOtherItems = true,
	showLowGold = true,
	showHighGold = true,
	showResources = true,
		showOrderHallResources = true,
		showAncientMana = true,
		showOtherResources = true,
	-- quest type
	showProfession = true,
	showPetBattle = true,
	showDungeon = true,
	showPvP = true,
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
BWQ:SetClampedToScreen(true)
BWQ:Hide()

local Block_OnLeave = function(self)
	if not BWQ:IsMouseOver() then
		BWQ:Hide()
	end

	BWQ:UnregisterEvent("QUEST_LOG_UPDATE")
	BWQ:UnregisterEvent("WORLD_MAP_UPDATE")
end
BWQ:SetScript("OnLeave", Block_OnLeave)


local buttonCache = {}
local zoneSepCache = {}
local numQuestsTotal, numQuestsZone, offsetY = 0, 0, 0
local notFinishedLoading = false
local highlightedRow = true

local CreateBountyBoardFS = function(offsetY)
	BWQ.bountyBoardFS = BWQ:CreateFontString("BWQbountyBoardFS", "OVERLAY", "SystemFont_Shadow_Med1")
	BWQ.bountyBoardFS:SetJustifyH("CENTER")
	BWQ.bountyBoardFS:SetTextColor(0.95, 0.95, 0.95)
	BWQ.bountyBoardFS:SetPoint("TOP", BWQ, "TOP", 0, offsetY)
end

local CreateErrorFS = function()
	BWQ.errorFS = BWQ:CreateFontString("BWQerrorFS", "OVERLAY", "SystemFont_Shadow_Med1")
	BWQ.errorFS:SetJustifyH("CENTER")
	BWQ.errorFS:SetTextColor(.9, .8, 0)
end

local WorldQuestsUnlocked = function()
	if UnitLevel("player") < 110 or not IsQuestFlaggedCompleted(43341) then -- http://legion.wowhead.com/quest=43341/a-world-of-quests
		if not BWQ.errorFS then CreateErrorFS() end

	BWQ.errorFS:SetPoint("TOP", BWQ, "TOP", 0, -10)
		BWQ:SetSize(BWQ.errorFS:GetStringWidth() + 20, BWQ.errorFS:GetStringHeight() + 20)
		BWQ.errorFS:SetText("You need to reach Level 110 and complete the\nquest \124cffffff00\124Hquest:43341:-1\124h[A World of Quests]\124h\124r to unlock World Quests.")
		BWQ.errorFS:Show()

		return false
	else
		if BWQ.errorFS then
			BWQ.errorFS:Hide()
		end

		return true
	end
end

local ShowNoWorldQuestsInfo = function()
	if not BWQ.errorFS then CreateErrorFS() end

	BWQ.errorFS:ClearAllPoints()
	if BWQ.bountyBoardFS:IsShown() then
		BWQ.errorFS:SetPoint("TOP", BWQ, "TOP", 0, -40)
	else
		BWQ.errorFS:SetPoint("TOP", BWQ, "TOP", 0, -13)
	end
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
					quest.bounties = {}

					quests[#quests+1] = quest
				end
			end
		end
	end

	return quests
end

local ArtifactPowerScanTooltip = CreateFrame ("GameTooltip", "ArtifactPowerScanTooltip", nil, "GameTooltipTemplate")
function BWQ:GetArtifactPowerValue(itemId)
	_, itemLink = GetItemInfo(itemId)
	ArtifactPowerScanTooltip:SetOwner (BWQ, "ANCHOR_NONE")
	ArtifactPowerScanTooltip:SetHyperlink (itemLink)
	return _G["ArtifactPowerScanTooltipTextLeft4"]:GetText():match("%d.-%s") or ""
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

function BWQ:UpdateBlock()
	if not WorldQuestsUnlocked() then return end

	local originalMap = GetCurrentMapAreaID()
	local originalContinent = GetCurrentMapContinent()
	local originalDungeonLevel = GetCurrentMapDungeonLevel()

	local buttonIndex = 1
	local titleMaxWidth, bountyMaxWidth, factionMaxWidth, rewardMaxWidth, timeLeftMaxWidth = 0, 0, 0, 0, 0

	notFinishedLoading = false
	offsetY = -15 -- initial padding from top
	numQuestsTotal = 0
	highlightedRow = true

	local bounties = GetQuestBountyInfoForMapID(1014)
	local bountyBoardText = ""
	for bountyIndex, bounty in ipairs(bounties) do
		local questIndex = GetQuestLogIndexByID(bounty.questID);
		local title = GetQuestLogTitle(questIndex);
		local _, _, finished, numFulfilled, numRequired = GetQuestObjectiveInfo(bounty.questID, 1, false)

		bountyBoardText = string.format("%s|T%s$s:20:20|t %s   %d/%d", bountyBoardText, bounty.icon, title, numFulfilled, numRequired)
		if bountyIndex < #bounties then
			bountyBoardText = string.format("%s        ", bountyBoardText)
		end
	end

	if not BWQ.bountyBoardFS then CreateBountyBoardFS(offsetY) end
	if #bounties > 0 then
		BWQ.bountyBoardFS:Show()
		BWQ.bountyBoardFS:SetText(bountyBoardText)
		offsetY = offsetY - 25
	else
		BWQ.bountyBoardFS:Hide()
	end

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

					button.bountyFS = button:CreateFontString("BWQbountyFS", "OVERLAY", "SystemFont_Shadow_Med1")
					button.bountyFS:SetJustifyH("LEFT")
					button.bountyFS:SetWordWrap(false)

					button.factionFS = button:CreateFontString("BWQfactionFS", "OVERLAY", "SystemFont_Shadow_Med1")
					button.factionFS:SetJustifyH("LEFT")
					button.factionFS:SetTextColor(.9, .9, .9)
					button.factionFS:SetWordWrap(false)

					button.reward = CreateFrame("Button", nil, button)
					button.reward:SetScript("OnClick", function(self)
						Row_OnClick(button)
					end)

					button.rewardFS = button.reward:CreateFontString("BWQrewardFS", "OVERLAY", "SystemFont_Shadow_Med1")
					button.rewardFS:SetJustifyH("LEFT")
					button.rewardFS:SetTextColor(.9, .9, .9)
					button.rewardFS:SetWordWrap(false)

					button.timeLeftFS = button:CreateFontString("BWQtimeLeftFS", "OVERLAY", "SystemFont_Shadow_Med1")
					button.timeLeftFS:SetJustifyH("LEFT")
					button.timeLeftFS:SetTextColor(.9, .9, .9)
					button.timeLeftFS:SetWordWrap(false)

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


						local itemText
						local itemSpell = GetItemSpell(button.reward.itemId)
						if itemSpell and itemSpell == "Empowering" then
							if BWQcfg.showArtifactPower then hideQuest = false end
							itemText = string.format("|cffe5cc80[%sArtifact Power]|r", BWQ:GetArtifactPowerValue(itemId))
						else
							if BWQcfg.showItems then
								_, _, _, _, _, class, subClass, _, equipSlot, _, _ = GetItemInfo(itemId)
								if class == "Tradeskill" then
									if BWQcfg.showCraftingMaterials then hideQuest = false end
								elseif equipSlot ~= "" then
									if BWQcfg.showGear then hideQuest = false end
								elseif subClass == "Artifact Relic" then
									if BWQcfg.showRelics then hideQuest = false end
								else 
									if BWQcfg.showOtherItems then hideQuest = false end
								end
							end
							itemText = string.format("%s[%s]|r", ITEM_QUALITY_COLORS[button.reward.itemQuality].hex, itemName)
						end
							
						rewardText = string.format(
							"|T%s$s:14:14|t %s%s",
							button.reward.itemTexture,
							itemText,
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
					if money < 1000000 then
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

					local name, texture, numItems = GetQuestLogRewardCurrencyInfo(i, button.quest.questId)
					if name then
						
						if BWQcfg.showResources then
							if name == "Ancient Mana" then
								if BWQcfg.showAncientMana then hideQuest = false end
							elseif name == "Order Resources" then
								if BWQcfg.showOrderHallResources then hideQuest = false end
							else
								if BWQcfg.showOtherResources then hideQuest = false end
							end
						end

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

				end

				button.quest.bountyIcons = {}
				for _, bounty in ipairs(bounties) do
					if IsQuestCriteriaForBounty(button.quest.questId, bounty.questID) then
						button.quest.bountyIcons[#button.quest.bountyIcons + 1] = bounty.icon
					end
				end

				-- quest type filters
				if not BWQcfg.showPetBattle and button.quest.worldQuestType == 5 then hideQuest = true
				elseif not BWQcfg.showProfession and button.quest.worldQuestType == 2 then hideQuest = true
				elseif not BWQcfg.showPvP and button.quest.worldQuestType == 4 then hideQuest = true
				elseif not BWQcfg.showDungeon and button.quest.worldQuestType == 7 then hideQuest = true
				end
				-- always show bounty quests filter
				if BWQcfg.alwaysShowBountyQuests and #button.quest.bountyIcons > 0 then
					-- pet battle override
					if BWQcfg.hidePetBattleBountyQuests and not BWQcfg.showPetBattle and button.quest.worldQuestType == 5 then
						hideQuest = true
					else
						hideQuest = false
					end
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
					--local titleWidth = button.titleFS:GetStringWidth()
					--if titleWidth > titleMaxWidth then titleMaxWidth = titleWidth end

					local bountyText = ""
					for _, bountyIcon in ipairs(button.quest.bountyIcons) do
						bountyText = string.format("%s |T%s$s:14:14|t", bountyText, bountyIcon)
					end
					button.bountyFS:SetText(bountyText)
					local bountyWidth = button.bountyFS:GetStringWidth()
					if bountyWidth > bountyMaxWidth then bountyMaxWidth = bountyWidth end

					button.factionFS:SetText(button.quest.faction)
					local factionWidth = button.factionFS:GetStringWidth()
					if factionWidth > factionMaxWidth then factionMaxWidth = factionWidth end

					button.timeLeftFS:SetText(FormatTimeLeftString(button.quest.timeLeft))
					--local timeLeftWidth = button.factionFS:GetStringWidth()
					--if timeLeftWidth > timeLeftMaxWidth then timeLeftMaxWidth = timeLeftWidth end


					button.rewardFS:SetText(rewardText)

					local rewardWidth = button.rewardFS:GetStringWidth()
					if rewardWidth > rewardMaxWidth then rewardMaxWidth = rewardWidth end
					button.reward:SetHeight(button.rewardFS:GetStringHeight())
					button.title:SetHeight(button.titleFS:GetStringHeight())

					button.icon:SetPoint("LEFT", button, "LEFT", 5, 0)
					button.titleFS:SetPoint("LEFT", button.icon, "RIGHT", 5, 0)
					button.title:SetPoint("LEFT", button.titleFS, "LEFT", 0, 0)
					button.rewardFS:SetPoint("LEFT", button.titleFS, "RIGHT", 10, 0)
					button.reward:SetPoint("LEFT", button.rewardFS, "LEFT", 0, 0)
					button.bountyFS:SetPoint("LEFT", button.rewardFS, "RIGHT", 10, 0)
					button.factionFS:SetPoint("LEFT", button.bountyFS, "RIGHT", 10, 0)
					button.timeLeftFS:SetPoint("LEFT", button.factionFS, "RIGHT", 10, 0)
				end

				buttonIndex = buttonIndex + 1
			end -- quest loop

			if numQuestsZone == 0 then
				zoneSepCache[mapIndex-1]:Hide()
				zoneSepCache[mapIndex]:Hide()
				if #quests > 0 then
					offsetY = offsetY + 16
				end
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

	-- all quests filtered or all done (haha.)
	if numQuestsTotal == 0 then
		ShowNoWorldQuestsInfo()
		offsetY = offsetY - 15
	else
		if BWQ.errorFS then BWQ.errorFS:Hide() end
	end

	-- hide buttons if there are more cached buttons than quests available
	for i = buttonIndex, #buttonCache do
		buttonCache[i]:Hide()
	end
	
	titleMaxWidth = 200
	rewardMaxWidth = rewardMaxWidth < 150 and 150 or rewardMaxWidth
	factionMaxWidth = factionMaxWidth < 100 and 100 or factionMaxWidth
	timeLeftMaxWidth = 65
	totalWidth = titleMaxWidth + bountyMaxWidth + factionMaxWidth + rewardMaxWidth + timeLeftMaxWidth + 70

	local bountyBoardWidth = BWQ.bountyBoardFS:GetStringWidth()
	if totalWidth < bountyBoardWidth then
		local diff = bountyBoardWidth - totalWidth
		totalWidth = bountyBoardWidth
		rewardMaxWidth = rewardMaxWidth + diff
	end

	for i = 1, (buttonIndex - 1) do
		if buttonCache[i]:IsShown() then -- dont care about the hidden ones
			buttonCache[i]:SetHeight(15)
			buttonCache[i]:SetWidth(totalWidth)
			buttonCache[i].title:SetWidth(titleMaxWidth)
			buttonCache[i].titleFS:SetWidth(titleMaxWidth)
			buttonCache[i].bountyFS:SetWidth(bountyMaxWidth)
			buttonCache[i].factionFS:SetWidth(factionMaxWidth)
			buttonCache[i].reward:SetWidth(rewardMaxWidth)
			buttonCache[i].rewardFS:SetWidth(rewardMaxWidth)
			buttonCache[i].timeLeftFS:SetWidth(timeLeftMaxWidth)
		end
	end

	local totalWidth = totalWidth + 20
	for i = 1, #MAP_ZONES do
		zoneSepCache[i]:SetWidth(totalWidth)
	end

	BWQ:SetWidth(totalWidth > 550 and totalWidth or 550)
	BWQ:SetHeight(-1 * offsetY + 10)

	if notFinishedLoading then
		C_Timer.After(.5, BWQ.UpdateBlock)
	end
end


local configMenu
local info = {}
function BWQ:SetupConfigMenu()
	configMenu = CreateFrame("Frame", "BWQ_ConfigMenu")
	configMenu.displayMode = "MENU"

	options = {
		{ text = "Always show quests for active bounty", check = "alwaysShowBountyQuests" },
		{ text = "Hide pet battle quests even when active bounty", check = "hidePetBattleBountyQuests" },
		{ text = "" },
		{ text = "Filter by reward...", isTitle = true },
		{ text = ("|T%1$s:16:16|t  Artifact Power"):format("Interface\\Icons\\inv_enchant_shardradientlarge"), check = "showArtifactPower" },
		{ text = ("|T%1$s:16:16|t  Items"):format("Interface\\Minimap\\Tracking\\Banker"), check = "showItems", submenu = {
				{ text = ("|T%1$s:16:16|t  Gear"):format("Interface\\Icons\\Inv_chest_plate_legionendgame_c_01"), check = "showGear" },
				{ text = ("|T%1$s:16:16|t  Artifact Relics"):format("Interface\\Icons\\inv_misc_statue_01"), check = "showRelics" },
				{ text = ("|T%s$s:16:16|t  Crafting Materials"):format("1417744"), check = "showCraftingMaterials" },
				{ text = "Other", check = "showOtherItems" },
			}
		},
		{ text = ("|T%1$s:16:16|t  Low gold reward"):format("Interface\\GossipFrame\\auctioneerGossipIcon"), check = "showLowGold" },
		{ text = ("|T%1$s:16:16|t  High gold reward"):format("Interface\\GossipFrame\\auctioneerGossipIcon"), check = "showHighGold" },
		{ text = "Resources", check = "showResources", submenu = {
				{ text = ("|T%1$s:16:16|t  Order Hall Resources"):format("Interface\\Icons\\inv_orderhall_orderresources"), check = "showOrderHallResources" },
				{ text = ("|T%1$s:16:16|t  Ancient Mana"):format("Interface\\Icons\\inv_misc_ancient_mana"), check = "showAncientMana" },
				{ text = "Other", check = "showOtherResources" },
			}
		},
		{ text = "" },
		{ text = "Filter by type...", isTitle = true },
		{ text = ("|T%1$s:16:16|t  Profession Quests"):format("Interface\\Minimap\\Tracking\\Profession"), check = "showProfession" },
		{ text = ("|T%1$s:16:16|t  Pet Battle Quests"):format("Interface\\Icons\\tracking_wildpet"), check = "showPetBattle" },
		{ text = "Dungeon Quests", check = "showDungeon" },
		{ text = ("|T%1$s:16:16|t  PvP Quests"):format("Interface\\Minimap\\Tracking\\BattleMaster"), check = "showPvP" },

	}

	configMenu.initialize = function(self, level)
		if not level then return end
		local opt = level > 1 and UIDROPDOWNMENU_MENU_VALUE or options
		if type(opt)=="string" and opt:find("^align") then
			for _, pos in ipairs(aligns) do
				info = wipe(info)
				info.text = pos
				info.checked = BWQcfg[opt] == pos
				info.func, info.arg1, info.arg2 = SetOption, opt, pos
				info.keepShownOnClick = true
				UIDropDownMenu_AddButton( info, level )
			end
			return
		end
		for i, v in ipairs(opt) do
			info = wipe(info)
			info.text = v.text
			info.isTitle = v.isTitle
			
			if v.check then
				info.checked = v.inv and not BWQcfg[v.check] or not v.inv and BWQcfg[v.check]
				info.func, info.arg1 = SetOption, v.check
				info.isNotRadio = true
				info.keepShownOnClick = true
			else
				info.disabled = true
			end
			info.hasArrow, info.value = v.submenu, v.submenu
			UIDropDownMenu_AddButton( info, level )
		end
	end

	SetOption = function(bt, var, val)
		BWQcfg[var] = val or not BWQcfg[var]
		BWQ:UpdateBlock()
		if WorldMapFrame:IsShown() then
			BWQ:OpenConfigMenu(nil)
		end
	end

	BWQ.SetupConfigMenu = nil
end


function BWQ:OpenConfigMenu(anchor)
	if not configMenu and anchor then
		BWQ:SetupConfigMenu()
		configMenu.anchor = anchor
	end
	--BWQ:Hide()
	ToggleDropDownMenu(1, nil, configMenu, configMenu.anchor, 0, 0)
end

local skipNextUpdate = false
BWQ:RegisterEvent("PLAYER_ENTERING_WORLD")
BWQ:SetScript("OnEvent", function(self, event)
	if event == "QUEST_LOG_UPDATE" and not skipNextUpdate then
		skipNextUpdate = false
		BWQ:UpdateBlock()
	--[[
	Opening quest details in the side bar of the world map fires QUEST_LOG_UPDATE event.
	To avoid setting the currently shown map again, which would hide the quest details,
	skip updating after a WORLD_MAP_UPDATE event happened 
	--]]
	elseif event == "WORLD_MAP_UPDATE" and WorldMapFrame:IsShown() then
		skipNextUpdate = true
	elseif event == "PLAYER_ENTERING_WORLD" then
		BWQcfg = BWQcfg or defaultConfig
		BWQ:UpdateBlock()
		BWQ:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end
end)

-- data broker object
local ldb = LibStub("LibDataBroker-1.1")
BWQ.WorldQuestsBroker = ldb:NewDataObject("WorldQuests", {
	type = "launcher",
	label = "World Quests",
	icon = "Interface\\ICONS\\Achievement_Dungeon_Outland_DungeonMaster",
	OnEnter = function(self)
		CloseDropDownMenus()
		BWQ:RegisterEvent("QUEST_LOG_UPDATE")
		BWQ:RegisterEvent("WORLD_MAP_UPDATE")

		BWQ:UpdateBlock()
		local showDownwards = select(2, self:GetCenter()) > UIParent:GetHeight() / 2
		BWQ:ClearAllPoints()
		BWQ:SetPoint(showDownwards and "TOP" or "BOTTOM", self, showDownwards and "BOTTOM" or "TOP", 0, 0)
		BWQ:Show()
	end,
	OnLeave = Block_OnLeave,
	OnClick = function(self, button)
		if button == "LeftButton" then
			BWQ:UpdateBlock()
		elseif button == "RightButton" then
			BWQ:OpenConfigMenu(self)
		end
	end,
})
