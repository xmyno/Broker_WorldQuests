--[[----
--
-- Broker_WorldQuests
--
-- World of Warcraft addon to display Legion world quests in convenient list form.
-- Doesn't do anything on its own; requires a data broker addon!
--
-- Author: myno
--
--]]----

local ITEM_QUALITY_COLORS, WORLD_QUEST_QUALITY_COLORS, UnitLevel
	= ITEM_QUALITY_COLORS, WORLD_QUEST_QUALITY_COLORS, UnitLevel

local             GetQuestsForPlayerByMapID,             GetQuestTimeLeftMinutes,             GetQuestInfoByQuestID,             GetQuestProgressBarInfo
	= C_TaskQuest.GetQuestsForPlayerByMapID, C_TaskQuest.GetQuestTimeLeftMinutes, C_TaskQuest.GetQuestInfoByQuestID, C_TaskQuest.GetQuestProgressBarInfo

local GetQuestTagInfo, GetFactionInfoByID, GetQuestObjectiveInfo, GetNumQuestLogRewards, GetQuestLogRewardInfo, GetQuestLogRewardMoney, GetNumQuestLogRewardCurrencies, GetQuestLogRewardCurrencyInfo, IsQuestFlaggedCompleted
	= GetQuestTagInfo, GetFactionInfoByID, GetQuestObjectiveInfo, GetNumQuestLogRewards, GetQuestLogRewardInfo, GetQuestLogRewardMoney, GetNumQuestLogRewardCurrencies, GetQuestLogRewardCurrencyInfo, IsQuestFlaggedCompleted

local GetCurrentMapAreaID, GetCurrentMapContinent, GetCurrentMapDungeonLevel
	= GetCurrentMapAreaID, GetCurrentMapContinent, GetCurrentMapDungeonLevel

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
	[1015] = { id = 1015, name = GetMapNameByID(1015), quests = {}, buttons = {}, glows = {}, },  -- Aszuna
	[1096] = { id = 1096, name = GetMapNameByID(1096), quests = {}, buttons = {}, glows = {}, },  -- Eye of Azshara
	[1018] = { id = 1018, name = GetMapNameByID(1018), quests = {}, buttons = {}, glows = {}, },  -- Val'sharah
	[1024] = { id = 1024, name = GetMapNameByID(1024), quests = {}, buttons = {}, glows = {}, },  -- Highmountain
	[1017] = { id = 1017, name = GetMapNameByID(1017), quests = {}, buttons = {}, glows = {}, },  -- Stormheim
	[1033] = { id = 1033, name = GetMapNameByID(1033), quests = {}, buttons = {}, glows = {}, },  -- Suramar
	[1014] = { id = 1014, name = GetMapNameByID(1014), quests = {}, buttons = {}, glows = {}, },  -- Dalaran
}
local MAP_ZONES_SORT = {
	1015, 1096, 1018, 1024, 1017, 1033, 1014
}
local MAPID_BROKENISLES = 1007
local SORT_ORDER = {
	ARTIFACTPOWER = 1,
	RELIC = 2,
	EQUIP = 3,
	ITEM = 4,
	PROFESSION = 5,
	RESOURCES = 6,
	MONEY = 7,
}

local WORLD_QUEST_TYPES = {
	PROFESSION = 1,
	PVE = 2,
	PVP = 3,
	PETBATTLE = 4,
	-- ?? = 5,
	DUNGEON = 6,
}


local ARTIFACTPOWER_SPELL_NAME = select(1, GetSpellInfo(228111))
local FAMILY_FAMILIAR_QUEST_IDS = { -- WQ pet battle achievement
	[42442] = true, -- Fight Night: Amalia
	[40299] = true, -- Fight Night: Bodhi Sunwayver
	[40298] = true, -- Fight Night: Sir Galveston
	[40277] = true, -- Fight Night: Tiffany Nelson
	[42159] = true, -- Training with the Nightwatchers
	[41860] = true, -- Dealing with Satyrs
	[40279] = true, -- Training with Durian
	[40280] = true, -- Training with Bredda
	[41687] = true, -- Snail Fight!
	[40282] = true, -- Tiny Poacher, Tiny Animals
	[40278] = true, -- My Beasts's Bidding
	[41944] = true, -- Jarrun's Ladder
	[41895] = true, -- The Master of Pets
	[40337] = true, -- Flummoxed
	[41990] = true, -- Chopped
}

local defaultConfig = {
	-- general
	attachToWorldMap = false,
	showOnClick = false,
	usePerCharacterSettings = false,
	alwaysShowBountyQuests = true,
	alwaysShowEpicQuests = true,
	onlyShowRareOrAbove = false,
	showTotalsInBrokerText = true,
		brokerShowAP = true,
		brokerShowResources = true,
		brokerShowGold = false,
		brokerShowGear = false,
		brokerShowHerbalism = false,
		brokerShowMining = false,
		brokerShowFishing = false,
		brokerShowSkinning = false,
		brokerShowBloodOfSargeras = false,
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
		showProfessionAlchemy = true,
		showProfessionBlacksmithing = true,
		showProfessionInscription = true,
		showProfessionJewelcrafting = true,
		showProfessionLeatherworking = true,
		showProfessionTailoring = true,
		showProfessionEnchanting = true,
		showProfessionEngineering = true,
		showProfessionHerbalism = true,
		showProfessionMining = true,
		showProfessionSkinning = true,
		showProfessionCooking = true,
		showProfessionArchaeology = true,
		showProfessionFirstAid = true,
		showProfessionFishing = true,
	showDungeon = true,
	showPvP = true,
	hideFactionColumn = false,
	alwaysShowCourtOfFarondis = false,
	alwaysShowDreamweavers = false,
	alwaysShowHighmountainTribe = false,
	alwaysShowNightfallen = false,
	alwaysShowWardens = false,
	alwaysShowValarjar = false,
	showPetBattle = true,
	hidePetBattleBountyQuests = false,
	alwaysShowPetBattleFamilyFamiliar = true,
}
local C = function(k)
	if BWQcfg.usePerCharacterSettings then
		return BWQcfgPerCharacter[k]
	else
		return BWQcfg[k]
	end
end

local BWQ = CreateFrame("Frame", "Broker_WorldQuests", UIParent)
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
	if not C("attachToWorldMap") or (C("attachToWorldMap") and not WorldMapFrame:IsShown()) then
		if not BWQ:IsMouseOver() then
			BWQ:Hide()
		end
	end
end
BWQ:SetScript("OnLeave", Block_OnLeave)

BWQ.slider = CreateFrame("Slider", nil, BWQ)
BWQ.slider:SetWidth(16)
BWQ.slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
BWQ.slider:SetBackdrop( {
	bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
	--edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
	edgeSize = 8, tile = true, tileSize = 8,
	insets = { left=3, right=3, top=6, bottom=6 }
} )
BWQ.slider:SetValueStep(1)

BWQ.slider:SetHeight(200)
BWQ.slider:SetMinMaxValues( 0, 100 )
BWQ.slider:SetValue(0)
BWQ.slider:Hide()


local bounties = {}
local questIds = {}
local numQuestsTotal, totalWidth, offsetTop = 0, 0, -15
local showDownwards = false
local blockYPos = 0
local highlightedRow = true

local CreateErrorFS = function()
	BWQ.errorFS = BWQ:CreateFontString("BWQerrorFS", "OVERLAY", "SystemFont_Shadow_Med1")
	BWQ.errorFS:SetJustifyH("CENTER")
	BWQ.errorFS:SetTextColor(.9, .8, 0)
end

local hasUnlockedWorldQuests
function BWQ:WorldQuestsUnlocked()
	if not hasUnlockedWorldQuests then
		hasUnlockedWorldQuests = UnitLevel("player") == 110 -- and IsQuestFlaggedCompleted(43341)) -- http://wowhead.com/quest=43341
	end

	if not hasUnlockedWorldQuests then
		if C("attachToWorldMap") and WorldMapFrame:IsShown() then -- don't show error box on map
			BWQ:Hide()
			return false
		end
		if not BWQ.errorFS then CreateErrorFS() end

		BWQ.errorFS:SetPoint("TOP", BWQ, "TOP", 0, -10)
		BWQ.errorFS:SetText("You need to reach Level 110 to unlock World Quests.")
		BWQ:SetSize(BWQ.errorFS:GetStringWidth() + 20, BWQ.errorFS:GetStringHeight() + 20)
		BWQ.errorFS:Show()

		return false
	else
		if BWQ.errorFS then
			BWQ.errorFS:Hide()
		end

		return true
	end
end

function BWQ:ShowNoWorldQuestsInfo()
	if not BWQ.errorFS then CreateErrorFS() end

	BWQ.errorFS:ClearAllPoints()
	BWQ.errorFS:SetPoint("TOP", BWQ, "TOP", 0, offsetTop - 10)

	BWQ.errorFS:SetText("There are no world quests available that match your filter settings.")
	BWQ.errorFS:Show()
end


local BWQScanTooltip = CreateFrame("GameTooltip", "BWQScanTooltip", nil, "GameTooltipTemplate")
BWQScanTooltip:Hide()
function BWQ:GetArtifactPowerValue(itemId)
	local _, itemLink = GetItemInfo(itemId)
	BWQScanTooltip:SetOwner(BWQ, "ANCHOR_NONE")
	BWQScanTooltip:SetHyperlink(itemLink)
	local numLines = BWQScanTooltip:NumLines()
	local isArtifactPower = false
	for i = 2, numLines do
		local text = _G["BWQScanTooltipTextLeft" .. i]:GetText()
		if text then
			if text:find(ARTIFACT_POWER) then
				isArtifactPower = true
			end

			if isArtifactPower and text:find(ITEM_SPELL_TRIGGER_ONUSE) then
				return text:gsub("%p", ""):match("%d[%d%s]+"):gsub("%s+", "") or ""
			end
		end
	end
	return ""
end
function BWQ:GetItemLevelValueForQuestId(questId)
	BWQScanTooltip:SetOwner(BWQ, "ANCHOR_NONE")
	BWQScanTooltip:SetQuestLogItem("reward", 1, questId)
	local numLines = BWQScanTooltip:NumLines()
	for i = 2, numLines do
		local text = _G["BWQScanTooltipTextLeft" .. i]:GetText()
		if text and text:find(ITEM_LEVEL:gsub(" %%d", "")) then
			return text:match("[%d]+%p*") or ""
		end
	end
	return ""
end

local FormatTimeLeftString = function(timeLeft)
	local timeLeftStr = ""
	-- if timeLeft >= 60 * 24 then -- at least 1 day
	-- 	timeLeftStr = string.format("%.0fd", timeLeft / 60 / 24)
	-- end
	if timeLeft >= 60 then -- hours
		timeLeftStr = string.format("%.0fh", math.floor(timeLeft / 60))
	end
	timeLeftStr = string.format("%s%s%sm", timeLeftStr, timeLeftStr ~= "" and " " or "", timeLeft % 60) -- always show minutes

	if 		timeLeft <= 120 then timeLeftStr = string.format("|cffD96932%s|r", timeLeftStr)
	elseif 	timeLeft <= 240 then timeLeftStr = string.format("|cffDBA43B%s|r", timeLeftStr)
	elseif 	timeLeft <= 480 then timeLeftStr = string.format("|cffE6D253%s|r", timeLeftStr)
	elseif 	timeLeft <= 960 then timeLeftStr = string.format("|cffE6DA8E%s|r", timeLeftStr)
	end
	return timeLeftStr
end


local tip = GameTooltip
local ShowQuestObjectiveTooltip = function(row)
	tip:SetOwner(row, "ANCHOR_CURSOR")
	local color = WORLD_QUEST_QUALITY_COLORS[row.quest.isRare]
	tip:AddLine(row.quest.title, color.r, color.g, color.b, true)

	for objectiveIndex = 1, row.quest.numObjectives do
		local objectiveText, objectiveType, finished = GetQuestObjectiveInfo(row.quest.questId, objectiveIndex, false);
		if objectiveText and #objectiveText > 0 then
			color = finished and GRAY_FONT_COLOR or HIGHLIGHT_FONT_COLOR;
			tip:AddLine(QUEST_DASH .. objectiveText, color.r, color.g, color.b, true);
		end
	end

	local percent = GetQuestProgressBarInfo(row.quest.questId);
	if percent then
		GameTooltip_InsertFrame(GameTooltip, WorldMapTaskTooltipStatusBar);
		WorldMapTaskTooltipStatusBar.Bar:SetValue(percent);
		WorldMapTaskTooltipStatusBar.Bar.Label:SetFormattedText(PERCENTAGE_STRING, percent);
	end

	tip:Show()
end

local ShowQuestLogItemTooltip = function(button)
	local name, texture = GetQuestLogRewardInfo(1, button.quest.questId)
	if name and texture then
		tip:SetOwner(button.reward, "ANCHOR_CURSOR")
		BWQScanTooltip:SetQuestLogItem("reward", 1, button.quest.questId)
		local _, itemLink = BWQScanTooltip:GetItem()
		tip:SetHyperlink(itemLink)
		tip:Show()
	end
end


-- super track map ping
local mapTextures = CreateFrame("Frame", "BWQ_MapTextures", WorldMapButton)
mapTextures:SetSize(64, 64)
mapTextures:SetFrameStrata("DIALOG")
mapTextures:SetFrameLevel(2001)
local highlightArrow = mapTextures:CreateTexture("highlightArrow")
highlightArrow:SetTexture("Interface\\minimap\\MiniMap-DeadArrow")
highlightArrow:SetSize(56, 56)
highlightArrow:SetRotation(3.14)
highlightArrow:SetPoint("CENTER", mapTextures)
highlightArrow:SetDrawLayer("ARTWORK", 1)
mapTextures.highlightArrow = highlightArrow
local animationGroup = mapTextures:CreateAnimationGroup()
animationGroup:SetLooping("REPEAT")
animationGroup:SetScript("OnPlay", function(self)
	mapTextures.highlightArrow:Show()
end)
animationGroup:SetScript("OnStop", function(self)
	mapTextures.highlightArrow:Hide()
end)
local downAnimation = animationGroup:CreateAnimation("Translation")
downAnimation:SetChildKey("highlightArrow")
downAnimation:SetOffset(0, -10)
downAnimation:SetDuration(0.4)
downAnimation:SetOrder(1)
local upAnimation = animationGroup:CreateAnimation("Translation")
upAnimation:SetChildKey("highlightArrow")
upAnimation:SetOffset(0, 10)
upAnimation:SetDuration(0.4)
upAnimation:SetOrder(2)
mapTextures.animationGroup = animationGroup
BWQ.mapTextures = mapTextures


function BWQ:QueryZoneQuestCoordinates(mapId)
	if mapId == GetCurrentMapAreaID() then
		local quests = GetQuestsForPlayerByMapID(mapId)
		for _, v in next, quests do
			if MAP_ZONES[mapId].quests[v.questId] then
				MAP_ZONES[mapId].quests[v.questId].x = v.x
				MAP_ZONES[mapId].quests[v.questId].y = v.y
			end
		end
	end
end

function BWQ:CalculateMapPosition(x, y)
	return x * WorldMapUnitPositionFrame:GetWidth(), -1 * y * WorldMapUnitPositionFrame:GetHeight()
end

function BWQ:CreateWatchGlow()
	local texture = BWQ.mapTextures:CreateTexture("glowTexture")
	texture:SetAtlas("worldquest-questmarker-glow", true);
	texture:SetSize(48, 48)
	texture:SetDesaturated(1)
	texture:SetBlendMode("ADD")
	texture:SetDrawLayer("BORDER", -1)
	texture:SetVertexColor(1, 1, 1, 0.9)

	return texture
end

function BWQ:UpdateWatchGlows(mapId)
	if not MAP_ZONES[mapId] or not MAP_ZONES[mapId].questsSort then return end

	for _, questId in next, MAP_ZONES[mapId].questsSort do
		if IsWorldQuestHardWatched(questId) then
			BWQ:AddWatchGlow(mapId, questId)
			BWQ:ShowWatchGlow(mapId, questId)
		else
			BWQ:HideWatchGlow(mapId, questId)
		end
	end
end

function BWQ:ShowAllWatchGlows(mapId)
	if not MAP_ZONES[mapId] then return end

	for questId, glow in next, MAP_ZONES[mapId].glows do
		if glow.active then
			BWQ:ShowWatchGlow(mapId, questId)
		end
	end
end

function BWQ:ShowWatchGlow(mapId, questId)
	if not MAP_ZONES[mapId] or not MAP_ZONES[mapId].glows then return end

	MAP_ZONES[mapId].glows[questId].active = true
	local glow = MAP_ZONES[mapId].glows[questId]
	local quest = MAP_ZONES[mapId].quests[questId]
	if not quest.x or not quest.y then
		BWQ:QueryZoneQuestCoordinates(mapId)
	end
	quest = MAP_ZONES[mapId].quests[questId]

	if quest.x and quest.y then
		local x, y = BWQ:CalculateMapPosition(quest.x, quest.y)
		glow.texture:ClearAllPoints()
		glow.texture:SetPoint("CENTER", WorldMapButton, "TOPLEFT", x, y)
		glow.texture:Show()
	end
end

function BWQ:AddWatchGlow(mapId, questId)
	if not MAP_ZONES[mapId] then return end

	local glow = MAP_ZONES[mapId].glows[questId] or {}
	if not glow.texture then
		glow.texture = BWQ:CreateWatchGlow()
	end
	MAP_ZONES[mapId].glows[questId] = glow
end

function BWQ:HideAllWatchGlows(mapId)
	if not MAP_ZONES[mapId] then return end

	for questId in next, MAP_ZONES[mapId].glows do
		BWQ:HideWatchGlow(mapId, questId)
	end
end

function BWQ:HideWatchGlow(mapId, questId)
	if not MAP_ZONES[mapId] then return end

	if MAP_ZONES[mapId].glows[questId] then
		MAP_ZONES[mapId].glows[questId].texture:Hide()
		MAP_ZONES[mapId].glows[questId].active = false
	end
end

function BWQ:DisableWatchGlow(mapId, questId)
	if not MAP_ZONES[mapId] then return end

	if MAP_ZONES[mapId].glows[questId] then
		MAP_ZONES[mapId].glows[questId].active = false
		MAP_ZONES[mapId].glows[questId].texture:Hide()
	end
end

local Row_OnClick = function(row)
	if IsShiftKeyDown() then
		if IsWorldQuestHardWatched(row.quest.questId) or (IsWorldQuestWatched(row.quest.questId) and GetSuperTrackedQuestID() == row.quest.questId) then
			BonusObjectiveTracker_UntrackWorldQuest(row.quest.questId)
		else
			BonusObjectiveTracker_TrackWorldQuest(row.quest.questId, true)
		end
	else
		if not WorldMapFrame:IsShown() then ShowQuestLog() end
		if not InCombatLockdown() then SetMapByID(row.mapId) end

		if not row.quest.x or not row.quest.y then BWQ:QueryZoneQuestCoordinates(row.mapId) end
		if row.quest.x and row.quest.y then
			local x, y = BWQ:CalculateMapPosition(row.quest.x, row.quest.y)
			BWQ.mapTextures:ClearAllPoints()
			BWQ.mapTextures:SetPoint("CENTER", WorldMapButton, "TOPLEFT", x, y + 25)
	  		BWQ.mapTextures.animationGroup:Play()
	  	end
	end
end

local REWARD_TYPES = { ARTIFACTPOWER = 0, RESOURCES = 1, MONEY = 2, GEAR = 3, BLOODOFSARGERAS = 4, }
local QUEST_TYPES = { HERBALISM = 0, MINING = 1, FISHING = 2, SKINNING = 3, }
local lastUpdate, updateTries = 0, 0
local needsRefresh = false
local RetrieveWorldQuests = function(mapId)

	local numQuests
	local currentTime = GetTime()
	local questList = GetQuestsForPlayerByMapID(mapId, MAPID_BROKENISLES)

	-- quest object fields are: x, y, floor, numObjectives, questId, inProgress
	if questList then
		numQuests = 0
		MAP_ZONES[mapId].questsSort = {}

		local timeLeft, tagId, tagName, worldQuestType, isRare, isElite, tradeskillLineIndex, title, factionId
		for i = 1, #questList do
			--[[
			local tagID, tagName, worldQuestType, isRare, isElite, tradeskillLineIndex = GetQuestTagInfo(v);

			tagId = 116
			tagName = Blacksmithing World Quest
			worldQuestType =
				1 -> profession,
				2 -> pve?
				3 -> pvp
				4 -> battle pet
				5 -> ??
				6 -> dungeon
			isRare =
				1 -> normal
				2 -> rare
				3 -> epic
			isElite = true/false
			tradeskillLineIndex = some number, no idea of meaning atm
			]]

			timeLeft = GetQuestTimeLeftMinutes(questList[i].questId)
			if timeLeft > 0 then -- only show available quests
				tagId, tagName, worldQuestType, isRare, isElite, tradeskillLineIndex = GetQuestTagInfo(questList[i].questId);
				if worldQuestType ~= nil then
					local questId = questList[i].questId
					table.insert(MAP_ZONES[mapId].questsSort, questId)
					local quest = MAP_ZONES[mapId].quests[questId] or {}

					if not quest.timeAdded then
						quest.wasSaved = questIds[questId] ~= nil
					end
					quest.timeAdded = quest.timeAdded or currentTime
					if quest.wasSaved or currentTime - quest.timeAdded > 900 then
						quest.isNew = false
					else
						quest.isNew = true
					end

					quest.hide = true
					quest.sort = 0

					-- GetQuestsForPlayerByMapID fields
					quest.questId = questId
					quest.numObjectives = questList[i].numObjectives
					quest.xFlight = questList[i].x
					quest.yFlight = questList[i].y

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

					quest.reward = {}
					-- item reward
					local hasReward = false
					C_TaskQuest.RequestPreloadRewardData(quest.questId)

					local rewardType
					if GetNumQuestLogRewards(quest.questId) > 0 then
						local itemName, itemTexture, quantity, quality, isUsable, itemId = GetQuestLogRewardInfo(1, quest.questId)
						if itemName then
							hasReward = true
							quest.reward.itemTexture = itemTexture
							quest.reward.itemId = itemId
							quest.reward.itemQuality = quality
							quest.reward.itemQuantity = quantity

							local itemSpell = GetItemSpell(quest.reward.itemId)
							local _, _, _, _, _, _, _, _, equipSlot, _, _, classId, subClassId = GetItemInfo(quest.reward.itemId)
							if itemSpell and ARTIFACTPOWER_SPELL_NAME and itemSpell == ARTIFACTPOWER_SPELL_NAME then
								quest.reward.artifactPower = BWQ:GetArtifactPowerValue(quest.reward.itemId)
								quest.sort = SORT_ORDER.ARTIFACTPOWER

								rewardType = REWARD_TYPES.ARTIFACTPOWER
								if C("showArtifactPower") then quest.hide = false end
							else
								quest.reward.itemName = itemName

								if classId == 7 then
									quest.sort = SORT_ORDER.PROFESSION
									if quest.reward.itemId == 124124 then
										rewardType = REWARD_TYPES.BLOODOFSARGERAS
									end
									if C("showItems") and C("showCraftingMaterials") then quest.hide = false end
								elseif equipSlot ~= "" then
									quest.sort = SORT_ORDER.EQUIP
									quest.reward.realItemLevel = BWQ:GetItemLevelValueForQuestId(quest.questId)
									rewardType = REWARD_TYPES.GEAR

									if C("showItems") and C("showGear") then quest.hide = false end
								elseif classId == 3 and subClassId == 11 then
									quest.sort = SORT_ORDER.RELIC
									quest.reward.realItemLevel = BWQ:GetItemLevelValueForQuestId(quest.questId)
									rewardType = REWARD_TYPES.GEAR

									if C("showItems") and C("showRelics") then quest.hide = false end
								else
									quest.sort = SORT_ORDER.ITEM
									if C("showItems") and C("showOtherItems") then quest.hide = false end
								end
							end
						end
					end
					-- gold reward
					local money = GetQuestLogRewardMoney(quest.questId);
					if money > 20000 then -- >2g, hides these silly low gold extra rewards
						hasReward = true
						quest.reward.money = money
						quest.sort = SORT_ORDER.MONEY
						rewardType = REWARD_TYPES.MONEY

						if money < 1000000 then
							if C("showLowGold") then quest.hide = false end
						else
							if C("showHighGold") then quest.hide = false end
						end
					end
					-- currency reward
					local numQuestCurrencies = GetNumQuestLogRewardCurrencies(quest.questId)
					for i = 1, numQuestCurrencies do

						local name, texture, numItems = GetQuestLogRewardCurrencyInfo(i, quest.questId)
						if name then
							hasReward = true
							quest.reward.resourceName = name
							quest.reward.resourceTexture = texture
							quest.reward.resourceAmount = numItems
							quest.sort = SORT_ORDER.RESOURCES
							rewardType = REWARD_TYPES.RESOURCES

							if C("showResources") then quest.hide = false end
						end
					end

					if not hasReward then needsRefresh = true end -- quests always have a reward, if not api returned bad data

					for _, bounty in ipairs(bounties) do
						if IsQuestCriteriaForBounty(quest.questId, bounty.questID) then
							quest.bounties[#quest.bounties + 1] = bounty.icon
						end
					end

					local questType
					-- quest type filters
					if quest.worldQuestType == 4 then
						if C("showPetBattle") or (C("alwaysShowPetBattleFamilyFamiliar") and FAMILY_FAMILIAR_QUEST_IDS[quest.questId] ~= nil) then
							quest.hide = false
						else
							quest.hide = true
						end
					elseif quest.worldQuestType == 1 then
						if C("showProfession") then

							if quest.tagId == 119 then
								questType = QUEST_TYPES.HERBALISM
								if C("showProfessionHerbalism")	then quest.hide = false else quest.hide = true end
							elseif quest.tagId == 120 then
								questType = QUEST_TYPES.MINING
								if C("showProfessionMining")		then quest.hide = false else quest.hide = true end
							elseif quest.tagId == 130 then
								questType = QUEST_TYPES.FISHING
							 	if C("showProfessionFishing")		then quest.hide = false else quest.hide = true end
							elseif quest.tagId == 124 then
								questType = QUEST_TYPES.SKINNING
							 	if C("showProfessionSkinning") 		then quest.hide = false else quest.hide = true end
							elseif quest.tagId == 118 then 	if C("showProfessionAlchemy") 		then quest.hide = false else quest.hide = true end
							elseif quest.tagId == 129 then	if C("showProfessionArchaeology") 	then quest.hide = false else quest.hide = true end
							elseif quest.tagId == 116 then 	if C("showProfessionBlacksmithing") 	then quest.hide = false else quest.hide = true end
							elseif quest.tagId == 131 then 	if C("showProfessionCooking") 		then quest.hide = false else quest.hide = true end
							elseif quest.tagId == 123 then 	if C("showProfessionEnchanting") 		then quest.hide = false else quest.hide = true end
							elseif quest.tagId == 122 then 	if C("showProfessionEngineering") 	then quest.hide = false else quest.hide = true end
							elseif quest.tagId == 114 then 	if C("showProfessionFirstAid") 		then quest.hide = false else quest.hide = true end
							elseif quest.tagId == 126 then 	if C("showProfessionInscription") 	then quest.hide = false else quest.hide = true end
							elseif quest.tagId == 125 then 	if C("showProfessionJewelcrafting") 	then quest.hide = false else quest.hide = true end
							elseif quest.tagId == 117 then 	if C("showProfessionLeatherworking") 	then quest.hide = false else quest.hide = true end
							elseif quest.tagId == 121 then 	if C("showProfessionTailoring") 		then quest.hide = false else quest.hide = true end
							end
						else
							quest.hide = true
						end
					elseif not C("showPvP") and quest.worldQuestType == 3 then quest.hide = true
					elseif not C("showDungeon") and quest.worldQuestType == 6 then quest.hide = true
					end

					-- only show quest that are blue or above quality
					if (C("onlyShowRareOrAbove") and quest.isRare < 2) then quest.hide = true end

					-- always show bounty quests or reputation for faction filter
					if (C("alwaysShowBountyQuests") and #quest.bounties > 0) or
					   (C("alwaysShowCourtOfFarondis") 	and (mapId == 1015 or mapId == 1096)) or
					   (C("alwaysShowDreamweavers") 		and mapId == 1018) or
					   (C("alwaysShowHighmountainTribe") 	and mapId == 1024) or
					   (C("alwaysShowNightfallen") 		and mapId == 1033) or
					   (C("alwaysShowWardens") 			and quest.faction == "The Wardens") or
					   (C("alwaysShowValarjar") 			and mapId == 1017) then

						-- pet battle override
						if C("hidePetBattleBountyQuests") and not C("showPetBattle") and quest.worldQuestType == 4 then
							quest.hide = true
						else
							quest.hide = false
						end
					end
					-- don't filter epic quests based on setting
					if C("alwaysShowEpicQuests") and quest.isRare == 3 then quest.hide = false end

					MAP_ZONES[mapId].quests[questId] = quest

					if not quest.hide then
						numQuests = numQuests + 1

						if rewardType == REWARD_TYPES.ARTIFACTPOWER and quest.reward.artifactPower then
							BWQ.totalArtifactPower = BWQ.totalArtifactPower + (quest.reward.artifactPower or 0) end
						if rewardType == REWARD_TYPES.RESOURCES and quest.reward.resourceAmount then
							BWQ.totalResources = BWQ.totalResources + quest.reward.resourceAmount end
						if rewardType == REWARD_TYPES.MONEY and quest.reward.money then
							BWQ.totalGold = BWQ.totalGold + quest.reward.money end
						if rewardType == REWARD_TYPES.BLOODOFSARGERAS and quest.reward.itemQuantity then
							BWQ.totalBloodOfSargeras = BWQ.totalBloodOfSargeras + quest.reward.itemQuantity end
						if rewardType == REWARD_TYPES.GEAR then
							BWQ.totalGear = BWQ.totalGear + 1 end
						if questType == QUEST_TYPES.HERBALISM then
							BWQ.totalHerbalism = BWQ.totalHerbalism + 1 end
						if questType == QUEST_TYPES.MINING then
							BWQ.totalMining = BWQ.totalMining + 1 end
						if questType == QUEST_TYPES.FISHING then
							BWQ.totalFishing = BWQ.totalFishing + 1 end
						if questType == QUEST_TYPES.SKINNING then
							BWQ.totalSkinning = BWQ.totalSkinning + 1 end
					end
				end
			end
		end

		table.sort(MAP_ZONES[mapId].questsSort, function(a, b) return MAP_ZONES[mapId].quests[a].sort < MAP_ZONES[mapId].quests[b].sort end)

		if numQuests == nil then numQuests = 0 end
		MAP_ZONES[mapId].numQuests = numQuests
	end
end


BWQ.bountyCache = {}
BWQ.bountyDisplay = CreateFrame("Frame", "BWQ_BountyDisplay", BWQ)
function BWQ:UpdateBountyData()
	bounties = GetQuestBountyInfoForMapID(1014) -- zone id doesn't matter

	local bountyWidth = 0 -- added width of all items inside the bounty block
	for bountyIndex, bounty in ipairs(bounties) do
		local questIndex = GetQuestLogIndexByID(bounty.questID)
		local title = GetQuestLogTitle(questIndex)
		local timeleft = GetQuestTimeLeftMinutes(bounty.questID)
		local _, _, finished, numFulfilled, numRequired = GetQuestObjectiveInfo(bounty.questID, 1, false)

		local bountyCacheItem
		if not BWQ.bountyCache[bountyIndex] then
			bountyCacheItem = {}
			bountyCacheItem.icon = BWQ.bountyDisplay:CreateTexture()
			bountyCacheItem.icon:SetSize(28, 28)
			bountyCacheItem.text = BWQ.bountyDisplay:CreateFontString("BWQ_BountyDisplayText"..bountyIndex, "OVERLAY", "SystemFont_Shadow_Med1")
			BWQ.bountyCache[bountyIndex] = bountyCacheItem
		else
			bountyCacheItem = BWQ.bountyCache[bountyIndex]
		end

		if bounty.icon and title then

			bountyCacheItem.text:SetText(string.format(
											"|cff%s%s\n %s/%s      |r%s",
											numFulfilled == numRequired and "49d65e" or "e3d29f",
											title,
											numFulfilled or 0,
											numRequired or 0,
											FormatTimeLeftString(timeleft)
										))
			bountyCacheItem.icon:SetTexture(bounty.icon)
			if bountyIndex == 1 then
				bountyCacheItem.icon:SetPoint("LEFT", BWQ.bountyDisplay, "LEFT")
			else
				bountyCacheItem.icon:SetPoint("LEFT", BWQ.bountyCache[bountyIndex-1].text, "RIGHT", 25, 2)
				bountyWidth = bountyWidth + 25 -- add padding per item
			end
			bountyCacheItem.text:SetPoint("LEFT", bountyCacheItem.icon, "RIGHT", 5, -2)

			bountyWidth = bountyWidth + bountyCacheItem.text:GetStringWidth() + 33 -- icon + padding
		end
	end

	-- remove obsolete bounty entries (completed or disappeared)
	if #bounties < #BWQ.bountyCache then
		for i = bountyIndex, #BWQ.bountyCache do
			BWQ.bountyCache[i].icon:Hide()
			BWQ.bountyCache[i].text:Hide()
			BWQ.bountyCache[i] = nil
		end
	end

	-- show if bounties available, otherwise hide the bounty block
	if #bounties > 0 then
		BWQ.bountyDisplay:Show()
		BWQ.bountyDisplay:SetSize(bountyWidth, 30)
		BWQ.bountyDisplay:SetPoint("TOP", BWQ, "TOP", 0, offsetTop)
	 	offsetTop = offsetTop - 35
	else
		BWQ.bountyDisplay:Hide()
	end
end

local originalMap, originalContinent, originalDungeonLevel
function BWQ:UpdateQuestData()
	questIds = BWQcache.questIds or {}
	BWQ.totalArtifactPower, BWQ.totalGold, BWQ.totalResources, BWQ.totalGear, BWQ.totalHerbalism, BWQ.totalMining, BWQ.totalFishing, BWQ.totalSkinning, BWQ.totalBloodOfSargeras = 0, 0, 0, 0, 0, 0, 0, 0, 0

	for mapId in next, MAP_ZONES do
		RetrieveWorldQuests(mapId)
	end

	numQuestsTotal = 0
	for mapId in next, MAP_ZONES do
		numQuestsTotal = numQuestsTotal + MAP_ZONES[mapId].numQuests
	end

	-- save quests to saved vars to check new status after reload/relog
	if numQuestsTotal ~= 0 then
		questIds = {}
		for mapId in next, MAP_ZONES do
			for _, questId in next, MAP_ZONES[mapId].questsSort do
				questIds[questId] = true
			end
		end
		BWQcache.questIds = questIds
	end

	if needsRefresh and updateTries <= 5 then
		needsRefresh = false
		updateTries = updateTries + 1
		C_Timer.After(1, function() BWQ:UpdateBlock() end)
	end
end

function BWQ:RenderRows()
	local screenHeight = UIParent:GetHeight()
	local availableHeight = 0
	if showDownwards then availableHeight = screenHeight - (screenHeight - blockYPos) - 30
	else availableHeight = screenHeight - blockYPos - 30 end

	local ROW_HEIGHT = -16
	local maxEntries = math.floor((availableHeight + offsetTop - 10) / ( -1 * ROW_HEIGHT ))

	local numEntries = numQuestsTotal
	for mapId in next, MAP_ZONES do
		if MAP_ZONES[mapId].numQuests ~= 0 then
			numEntries = numEntries + 1
		end
	end

	if maxEntries >= numEntries then
		BWQ.slider:Hide()
		maxEntries = numEntries - 1
		BWQ.slider:SetMinMaxValues(0, numEntries - 1 - maxEntries)
	else
		BWQ.slider:Show()
		BWQ.slider:SetPoint("TOPRIGHT", BWQ, "TOPRIGHT", -5, offsetTop)
		BWQ.slider:SetHeight((ROW_HEIGHT * -1) * (maxEntries + 1))
		BWQ.slider:SetMinMaxValues(0, numEntries - 1 - maxEntries)
	end


	-- all quests filtered or all done (haha.)
	if numQuestsTotal == 0 then
		BWQ:ShowNoWorldQuestsInfo()
		BWQ:SetHeight((offsetTop * -1) + 10 + 30)
	else
		if BWQ.errorFS then BWQ.errorFS:Hide() end
		BWQ:SetHeight((offsetTop * -1) + 10 + (ROW_HEIGHT * -1) * (maxEntries + 1))
	end

	local sliderval = math.floor(BWQ.slider:GetValue())
	local rowIndex = 0
	local rowInViewIndex = 0
	for _, mapId in next, MAP_ZONES_SORT do
		if MAP_ZONES[mapId].numQuests == 0 or rowIndex < sliderval or rowIndex > sliderval + maxEntries then

			MAP_ZONES[mapId].zoneSep.fs:Hide()
			MAP_ZONES[mapId].zoneSep.texture:Hide()
		else

			MAP_ZONES[mapId].zoneSep.fs:Show()
			MAP_ZONES[mapId].zoneSep.fs:SetPoint("TOP", BWQ, "TOP", 15 + (totalWidth / -2) + (MAP_ZONES[mapId].zoneSep.fs:GetStringWidth() / 2), offsetTop + ROW_HEIGHT * rowInViewIndex - 2)
			MAP_ZONES[mapId].zoneSep.texture:Show()
			MAP_ZONES[mapId].zoneSep.texture:SetPoint("TOP", BWQ, "TOP", 5, offsetTop + ROW_HEIGHT * rowInViewIndex - 3)

			rowInViewIndex = rowInViewIndex + 1
		end

		if MAP_ZONES[mapId].numQuests ~= 0 then
			rowIndex = rowIndex + 1 -- count up from row with zone name
		end

		highlightedRow = true
		local buttonIndex = 1
		for _, button in ipairs(MAP_ZONES[mapId].buttons) do

			if not button.quest.hide and buttonIndex <= MAP_ZONES[mapId].numQuests then
				if rowIndex < sliderval  or rowIndex > sliderval + maxEntries then
					button:Hide()
				else
					button:Show()
					button:SetPoint("TOP", BWQ, "TOP", 0, offsetTop + ROW_HEIGHT * rowInViewIndex)
					rowInViewIndex = rowInViewIndex + 1

					if highlightedRow then
						button.rowHighlight:Show()
					else
						button.rowHighlight:Hide()
					end
				end
				highlightedRow = not highlightedRow
				buttonIndex = buttonIndex + 1
				rowIndex = rowIndex + 1
			else
				button:Hide()
			end
		end
	end
end

function BWQ:RunUpdate()
	local currentTime = GetTime()
	if currentTime - lastUpdate > 5 then
		updateTries = 1
		BWQ:UpdateBlock()
		lastUpdate = currentTime
	end
end

function BWQ:UpdateBlock()
	if not BWQ:WorldQuestsUnlocked() then return end

	offsetTop = -15 -- initial padding from top
	BWQ:UpdateBountyData()
	BWQ:UpdateQuestData()

	if needsRefresh then return end

	local titleMaxWidth, bountyMaxWidth, factionMaxWidth, rewardMaxWidth, timeLeftMaxWidth = 0, 0, 0, 0, 0
	for mapId in next, MAP_ZONES do
		local buttonIndex = 1

		if not MAP_ZONES[mapId].zoneSep then
			local zoneSep = {
				fs = BWQ:CreateFontString("BWQzoneNameFS", "OVERLAY", "SystemFont_Shadow_Med1"),
				texture = BWQ:CreateTexture(),
			}
			zoneSep.fs:SetJustifyH("LEFT")
			zoneSep.fs:SetTextColor(.9, .8, 0)
			zoneSep.fs:SetText(MAP_ZONES[mapId].name)
			zoneSep.texture:SetTexture("Interface\\FriendsFrame\\UI-FriendsFrame-OnlineDivider")
			zoneSep.texture:SetHeight(8)

			MAP_ZONES[mapId].zoneSep = zoneSep
		end

		for _, questId in next, MAP_ZONES[mapId].questsSort do

			local button
			if buttonIndex > #MAP_ZONES[mapId].buttons then

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

					tip:Hide()
					Block_OnLeave()
				end)

				button.titleFS = button:CreateFontString("BWQtitleFS", "OVERLAY", "SystemFont_Shadow_Med1")
				button.titleFS:SetJustifyH("LEFT")
				button.titleFS:SetTextColor(.9, .9, .9)
				button.titleFS:SetWordWrap(false)

				button.track = button:CreateTexture()
				button.track:SetTexture("Interface\\COMMON\\FavoritesIcon")
				button.track:SetSize(24, 24)

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

				MAP_ZONES[mapId].buttons[buttonIndex] = button
			else
				button = MAP_ZONES[mapId].buttons[buttonIndex]
			end

			button.mapId = mapId
			button.quest = MAP_ZONES[mapId].quests[questId]

			-- fill and format row
			local rewardText = ""
			if button.quest.reward.itemName or button.quest.reward.artifactPower then
				local itemText
				if button.quest.reward.artifactPower then
					itemText = string.format("|cffe5cc80[%s Artifact Power]|r", button.quest.reward.artifactPower)
				else
					itemText = string.format(
						"%s[%s%s]|r",
						ITEM_QUALITY_COLORS[button.quest.reward.itemQuality].hex,
						button.quest.reward.realItemLevel and (button.quest.reward.realItemLevel .. " ") or "",
						button.quest.reward.itemName
					)
				end

				rewardText = string.format(
					"|T%s$s:14:14|t %s%s",
					button.quest.reward.itemTexture,
					button.quest.reward.itemQuantity > 1 and button.quest.reward.itemQuantity .. "x " or "",
					itemText
				)

				button.reward:SetScript("OnEvent", function(self, event)
					if event == "MODIFIER_STATE_CHANGED" then
						if button.reward:IsMouseOver() and button.reward:IsShown() then
							ShowQuestLogItemTooltip(button)
						else
							button.reward:UnregisterEvent("MODIFIER_STATE_CHANGED")
						end
					end
				end)

				button.reward:SetScript("OnEnter", function(self)
					button.highlight:SetAlpha(1)
					self:RegisterEvent("MODIFIER_STATE_CHANGED")

					ShowQuestLogItemTooltip(button)
				end)

				button.reward:SetScript("OnLeave", function(self)
					button.highlight:SetAlpha(0)

					self:UnregisterEvent("MODIFIER_STATE_CHANGED")
					tip:Hide()
					Block_OnLeave()
				end)
			else
				button.reward:SetScript("OnEnter", function(self)
					button.highlight:SetAlpha(1)
				end)
				button.reward:SetScript("OnLeave", function(self)
					button.highlight:SetAlpha(0)

					tip:Hide()
					Block_OnLeave()
				end)
			end
			if button.quest.reward.money and button.quest.reward.money > 0 then
				local moneyText = GetCoinTextureString(button.quest.reward.money)
				rewardText = string.format(
					"%s%s%s",
					rewardText,
					rewardText ~= "" and "   " or "", -- insert some space between rewards
					moneyText
				)
			end
			if button.quest.reward.resourceName then
				local currencyText = string.format(
					"|T%1$s:14:14|t %2$d %3$s",
					button.quest.reward.resourceTexture,
					button.quest.reward.resourceAmount,
					button.quest.reward.resourceName
				)

				rewardText = string.format(
					"%s%s%s",
					rewardText,
					rewardText ~= "" and "   " or "", -- insert some space between rewards
					currencyText
				)
			end

			-- if button.quest.tagId == 136 or button.quest.tagId == 111 or button.quest.tagId == 112 then
			--button.icon:SetTexCoord(.81, .84, .68, .79) -- skull tex coords
			if WORLD_QUEST_ICONS_BY_TAG_ID[button.quest.tagId] then
				button.icon:SetAtlas(WORLD_QUEST_ICONS_BY_TAG_ID[button.quest.tagId], true)
				button.icon:SetAlpha(1)
			else
				button.icon:SetAlpha(0)
			end
			button.icon:SetSize(12, 12)

			button.titleFS:SetText(string.format("|cffe5cc80%s|r%s%s|r", button.quest.isNew and "NEW  " or "", WORLD_QUEST_QUALITY_COLORS[button.quest.isRare].hex, button.quest.title))
			--local titleWidth = button.titleFS:GetStringWidth()
			--if titleWidth > titleMaxWidth then titleMaxWidth = titleWidth end

			if IsWorldQuestHardWatched(button.quest.questId) or GetSuperTrackedQuestID() == button.quest.questId then
				button.track:Show()
			else
				button.track:Hide()
			end

			local bountyText = ""
			for _, bountyIcon in ipairs(button.quest.bounties) do
				bountyText = string.format("%s |T%s$s:14:14|t", bountyText, bountyIcon)
			end
			button.bountyFS:SetText(bountyText)
			local bountyWidth = button.bountyFS:GetStringWidth()
			if bountyWidth > bountyMaxWidth then bountyMaxWidth = bountyWidth end

			if not C("hideFactionColumn") then
				button.factionFS:SetText(button.quest.faction)
				local factionWidth = button.factionFS:GetStringWidth()
				if factionWidth > factionMaxWidth then factionMaxWidth = factionWidth end
			else
				button.factionFS:SetText("")
			end

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
			button.track:SetPoint("LEFT", button.rewardFS, "RIGHT", 5, -3)
			button.bountyFS:SetPoint("LEFT", button.rewardFS, "RIGHT", 25, 0)
			button.factionFS:SetPoint("LEFT", button.bountyFS, "RIGHT", 10, 0)
			button.timeLeftFS:SetPoint("LEFT", button.factionFS, "RIGHT", 10, 0)

			buttonIndex = buttonIndex + 1
		end -- quest loop
	end -- maps loop

	titleMaxWidth = 125
	rewardMaxWidth = rewardMaxWidth < 100 and 100 or rewardMaxWidth > 250 and 250 or rewardMaxWidth
	factionMaxWidth = C("hideFactionColumn") and 0 or factionMaxWidth < 100 and 100 or factionMaxWidth
	timeLeftMaxWidth = 65
	totalWidth = titleMaxWidth + bountyMaxWidth + factionMaxWidth + rewardMaxWidth + timeLeftMaxWidth + 80

	local bountyBoardWidth = BWQ.bountyDisplay:GetWidth()
	if totalWidth < bountyBoardWidth then
		local diff = bountyBoardWidth - totalWidth
		totalWidth = bountyBoardWidth
		rewardMaxWidth = rewardMaxWidth + diff
	end

	for mapId in next, MAP_ZONES do
		for i = 1, #MAP_ZONES[mapId].buttons do
			if not MAP_ZONES[mapId].buttons[i].quest.hide then -- dont care about the hidden ones
				MAP_ZONES[mapId].buttons[i]:SetHeight(15)
				MAP_ZONES[mapId].buttons[i]:SetWidth(totalWidth)
				MAP_ZONES[mapId].buttons[i].title:SetWidth(titleMaxWidth)
				MAP_ZONES[mapId].buttons[i].titleFS:SetWidth(titleMaxWidth)
				MAP_ZONES[mapId].buttons[i].bountyFS:SetWidth(bountyMaxWidth)
				MAP_ZONES[mapId].buttons[i].factionFS:SetWidth(factionMaxWidth)
				MAP_ZONES[mapId].buttons[i].reward:SetWidth(rewardMaxWidth)
				MAP_ZONES[mapId].buttons[i].rewardFS:SetWidth(rewardMaxWidth)
				MAP_ZONES[mapId].buttons[i].timeLeftFS:SetWidth(timeLeftMaxWidth)
			else
				MAP_ZONES[mapId].buttons[i]:Hide()
			end
		end
		MAP_ZONES[mapId].zoneSep.texture:SetWidth(totalWidth + 20)
	end

	totalWidth = totalWidth + 20
	BWQ:SetWidth(totalWidth)

	if C("showTotalsInBrokerText") then
		local brokerString = ""
		if C("brokerShowAP")              and BWQ.totalArtifactPower > 0 then brokerString = string.format("%s|TInterface\\Icons\\INV_Artifact_XP03:16:16|t %d  ", brokerString, BWQ.totalArtifactPower) end
		if C("brokerShowResources")       and BWQ.totalResources > 0     then brokerString = string.format("%s|TInterface\\Icons\\inv_orderhall_orderresources:16:16|t %d  ", brokerString, BWQ.totalResources) end
		if C("brokerShowGold")            and BWQ.totalGold > 0          then brokerString = string.format("%s|TInterface\\GossipFrame\\auctioneerGossipIcon:16:16|t %d  ", brokerString, math.floor(BWQ.totalGold / 10000)) end
		if C("brokerShowGear")            and BWQ.totalGear > 0          then brokerString = string.format("%s|TInterface\\Icons\\Inv_chest_plate_legionendgame_c_01:16:16|t %d  ", brokerString, BWQ.totalGear) end
		if C("brokerShowHerbalism")       and BWQ.totalHerbalism > 0     then brokerString = string.format("%s|TInterface\\Icons\\Trade_Herbalism:16:16|t %d  ", brokerString, BWQ.totalHerbalism) end
		if C("brokerShowMining")          and BWQ.totalMining > 0        then brokerString = string.format("%s|TInterface\\Icons\\Trade_Mining:16:16|t %d  ", brokerString, BWQ.totalMining) end
		if C("brokerShowFishing")         and BWQ.totalFishing > 0       then brokerString = string.format("%s|TInterface\\Icons\\Trade_Fishing:16:16|t %d  ", brokerString, BWQ.totalFishing) end
		if C("brokerShowSkinning")        and BWQ.totalSkinning > 0      then brokerString = string.format("%s|TInterface\\Icons\\inv_misc_pelt_wolf_01:16:16|t %d  ", brokerString, BWQ.totalSkinning) end
		if C("brokerShowBloodOfSargeras") and BWQ.totalBloodOfSargeras   then brokerString = string.format("%s|T1417744:16:16|t %d", brokerString, BWQ.totalBloodOfSargeras) end

		if brokerString and brokerString ~= "" then
			BWQ.WorldQuestsBroker.text = brokerString
		else
			BWQ.WorldQuestsBroker.text = "World Quests"
		end
	else
		BWQ.WorldQuestsBroker.text = "World Quests"
	end

	BWQ:RenderRows()
end


local configMenu
local info = {}
function BWQ:SetupConfigMenu()
	configMenu = CreateFrame("Frame", "BWQ_ConfigMenu")
	configMenu.displayMode = "MENU"

	local options = {
		{ text = "Attach list frame to world map", check = "attachToWorldMap" },
		{ text = "Show list frame on click", check = "showOnClick" },
		{ text = "Use per-character settings", check = "usePerCharacterSettings" },
		{ text = "" },
		{ text = "Always show |cffa335eeepic|r world quests (e.g. world bosses)", check = "alwaysShowEpicQuests" },
		{ text = "Only show world quests with |cff0070ddrare|r or above quality", check = "onlyShowRareOrAbove" },
		{ text = "Don't filter quests for active bounties", check = "alwaysShowBountyQuests" },
		{ text = "Show total counts in broker text", check = "showTotalsInBrokerText", submenu = {
				{ text = ("|T%1$s:16:16|t  Artifact Power"):format("Interface\\Icons\\INV_Artifact_XP03"), check = "brokerShowAP" },
				{ text = ("|T%1$s:16:16|t  Order Hall Resources"):format("Interface\\Icons\\inv_orderhall_orderresources"), check = "brokerShowResources" },
				{ text = ("|T%1$s:16:16|t  Gold"):format("Interface\\GossipFrame\\auctioneerGossipIcon"), check = "brokerShowGold" },
				{ text = ("|T%1$s:16:16|t  Gear"):format("Interface\\Icons\\Inv_chest_plate_legionendgame_c_01"), check = "brokerShowGear" },
				{ text = ("|T%1$s:16:16|t  Herbalism Quests"):format("Interface\\Icons\\Trade_Herbalism"), check = "brokerShowHerbalism" },
				{ text = ("|T%1$s:16:16|t  Mining Quests"):format("Interface\\Icons\\Trade_Mining"), check = "brokerShowMining" },
				{ text = ("|T%1$s:16:16|t  Fishing Quests"):format("Interface\\Icons\\Trade_Fishing"), check = "brokerShowFishing" },
				{ text = ("|T%1$s:16:16|t  Skinning Quests"):format("Interface\\Icons\\inv_misc_pelt_wolf_01"), check = "brokerShowSkinning" },
				{ text = ("|T%s$s:16:16|t  Blood of Sargeras"):format("1417744"), check = "brokerShowBloodOfSargeras" },
			}
		},
		{ text = "" },
		{ text = "Filter by reward...", isTitle = true },
		{ text = ("|T%1$s:16:16|t  Artifact Power"):format("Interface\\Icons\\INV_Artifact_XP03"), check = "showArtifactPower" },
		{ text = ("|T%1$s:16:16|t  Items"):format("Interface\\Minimap\\Tracking\\Banker"), check = "showItems", submenu = {
				{ text = ("|T%1$s:16:16|t  Gear"):format("Interface\\Icons\\Inv_chest_plate_legionendgame_c_01"), check = "showGear" },
				{ text = ("|T%1$s:16:16|t  Artifact Relics"):format("Interface\\Icons\\inv_misc_statue_01"), check = "showRelics" },
				{ text = ("|T%s$s:16:16|t  Crafting Materials"):format("1417744"), check = "showCraftingMaterials" },
				{ text = "Other", check = "showOtherItems" },
			}
		},
		{ text = ("|T%1$s:16:16|t  Low gold reward"):format("Interface\\GossipFrame\\auctioneerGossipIcon"), check = "showLowGold" },
		{ text = ("|T%1$s:16:16|t  High gold reward"):format("Interface\\GossipFrame\\auctioneerGossipIcon"), check = "showHighGold" },
		{ text = ("|T%1$s:16:16|t  Order Hall Resources"):format("Interface\\Icons\\inv_orderhall_orderresources"), check = "showResources" },
		{ text = "" },
		{ text = "Filter by type...", isTitle = true },
		{ text = ("|T%1$s:16:16|t  Profession Quests"):format("Interface\\Minimap\\Tracking\\Profession"), check = "showProfession", submenu = {
				{ text = "Alchemy", check="showProfessionAlchemy" },
				{ text = "Blacksmithing", check="showProfessionBlacksmithing" },
				{ text = "Inscription", check="showProfessionInscription" },
				{ text = "Jewelcrafting", check="showProfessionJewelcrafting" },
				{ text = "Leatherworking", check="showProfessionLeatherworking" },
				{ text = "Tailoring", check="showProfessionTailoring" },
				{ text = "Enchanting", check="showProfessionEnchanting" },
				{ text = "Engineering", check="showProfessionEngineering" },
				{ text = "" },
				{ text = "Herbalism", check="showProfessionHerbalism" },
				{ text = "Mining", check="showProfessionMining" },
				{ text = "Skinning", check="showProfessionSkinning" },
				{ text = "" },
				{ text = "Cooking", check="showProfessionCooking" },
				{ text = "Archaeology", check="showProfessionArchaeology" },
				{ text = "FirstAid", check="showProfessionFirstAid" },
				{ text = "Fishing", check="showProfessionFishing" },
			}
		},
		{ text = "Dungeon Quests", check = "showDungeon" },
		{ text = ("|T%1$s:16:16|t  PvP Quests"):format("Interface\\Minimap\\Tracking\\BattleMaster"), check = "showPvP" },
		{ text = "" },
		{ text = ("|T%1$s:16:16|t  Pet Battle Quests"):format("Interface\\Icons\\tracking_wildpet"), isTitle = true },
		{ text = "Show Pet Battle Quests", check = "showPetBattle" },
		{ text = "Hide Pet Battle Quests even when active bounty", check = "hidePetBattleBountyQuests" },
		{ text = "Always show Pet Battle Quests for \"Family Familiar\" achievement", check = "alwaysShowPetBattleFamilyFamiliar" },
		{ text = "" },
		{ text = "Hide faction column", check="hideFactionColumn" },
		{ text = "Always show quests for faction...", isTitle = true },
		{ text = "Court of Farondis", check="alwaysShowCourtOfFarondis" },
		{ text = "Dreamweavers", check="alwaysShowDreamweavers" },
		{ text = "Highmountain Tribe", check="alwaysShowHighmountainTribe" },
		{ text = "The Nightfallen", check="alwaysShowNightfallen" },
		{ text = "The Wardens", check="alwaysShowWardens" },
		{ text = "Valarjar", check="alwaysShowValarjar" },
	}

	local SetOption = function(bt, var, val)
		if var == "usePerCharacterSettings" or not BWQcfg.usePerCharacterSettings then
			BWQcfg[var] = val or not BWQcfg[var]
		else
			BWQcfgPerCharacter[var] = val or not BWQcfgPerCharacter[var]
		end

		BWQ:UpdateBlock()
		if WorldMapFrame:IsShown() then
			BWQ:OpenConfigMenu(nil)
		end

		-- toggle block when changing attach setting
		if var == "attachToWorldMap" then
			BWQ:Hide()
			if C(var) == true and WorldMapFrame:IsShown() then
				BWQ:AttachToWorldMap()
			end
		end

		if var == "usePerCharacterSettings" then
			CloseDropDownMenus()
			ToggleDropDownMenu(1, nil, configMenu, configMenu.anchor, 0, 0)
		end
	end

	configMenu.initialize = function(self, level)
		if not level then return end
		local opt = level > 1 and UIDROPDOWNMENU_MENU_VALUE or options
		for i, v in ipairs(opt) do
			info = wipe(info)
			info.text = v.text
			info.isTitle = v.isTitle

			if v.check then
				if (v.check == "usePerCharacterSettings") then info.checked = v.inv and not BWQcfg[v.check] or not v.inv and BWQcfg[v.check]
				else info.checked = v.inv and not C(v.check) or not v.inv and C(v.check) end
				info.func, info.arg1 = SetOption, v.check
				info.isNotRadio = true
				info.keepShownOnClick = true
			else
				info.notCheckable = true
				info.disabled = true
			end
			info.hasArrow, info.value = v.submenu, v.submenu
			UIDropDownMenu_AddButton( info, level )
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

local SetFlightMapPins = function(self)
	for pin, active in self:GetMap():EnumeratePinsByTemplate("WorldQuestPinTemplate") do
		if IsWorldQuestHardWatched(pin.questID) or GetSuperTrackedQuestID() == pin.questID then
			pin:SetAlphaLimits(2.0, 1.0, 1.0)
			pin:SetScalingLimits(1, 1.5, 0.50)
		else
			pin:SetAlphaLimits(2.0, 0.0, 1.0)
			pin:SetScalingLimits(1, 1.0, 0.50)
		end
	end
end
function BWQ:AddFlightMapHook()
	hooksecurefunc(WorldQuestDataProviderMixin, "RefreshAllData", SetFlightMapPins)
end

function BWQ:AttachToBlock(anchor)
	if not C("attachToWorldMap") or (C("attachToWorldMap") and not WorldMapFrame:IsShown()) then
		CloseDropDownMenus()

		blockYPos = select(2, anchor:GetCenter())
		showDownwards = blockYPos > UIParent:GetHeight() / 2
		BWQ:ClearAllPoints()
		BWQ:SetPoint(showDownwards and "TOP" or "BOTTOM", anchor, showDownwards and "BOTTOM" or "TOP", 0, 0)
		BWQ:SetFrameStrata("DIALOG")
		BWQ:Show()

		BWQ:RunUpdate()
	end
end

function BWQ:AttachToWorldMap()
	BWQ:ClearAllPoints()
	BWQ:SetPoint("TOPLEFT", WorldMapFrame, "TOPRIGHT", 3, 0)
	BWQ:SetFrameStrata("HIGH")
	BWQ:Show()
end

local skipNextUpdate = false
BWQ:RegisterEvent("PLAYER_ENTERING_WORLD")
BWQ:RegisterEvent("ADDON_LOADED")
BWQ:SetScript("OnEvent", function(self, event, arg1)
	if event == "QUEST_LOG_UPDATE" then
		if not skipNextUpdate then
			BWQ:RunUpdate()
		end
		skipNextUpdate = false
	--[[
	Opening quest details in the side bar of the world map fires QUEST_LOG_UPDATE event.
	To avoid setting the currently shown map again, which would hide the quest details,
	skip updating after a WORLD_MAP_UPDATE event happened
	--]]
	elseif event == "WORLD_MAP_UPDATE" then
		skipNextUpdate = true
		local mapId = GetCurrentMapAreaID()
		if BWQ.currentMapId and BWQ.currentMapId ~= mapId then
			BWQ.mapTextures.animationGroup:Stop()
			BWQ:HideAllWatchGlows(BWQ.currentMapId)
		end
		BWQ:UpdateWatchGlows(mapId)
		BWQ.currentMapId = mapId
	elseif event == "QUEST_WATCH_LIST_CHANGED" then
		BWQ:UpdateWatchGlows(GetCurrentMapAreaID())
		BWQ:UpdateBlock()
	elseif event == "PLAYER_ENTERING_WORLD" then
		BWQ.slider:SetScript("OnLeave", Block_OnLeave )
		BWQ.slider:SetScript("OnValueChanged", function(self, value)
			BWQ:RenderRows()
		end)

		BWQ:SetScript("OnMouseWheel", function(self, delta)
			BWQ.slider:SetValue(BWQ.slider:GetValue() - delta * 3)
		end)

		if Aurora and Aurora[1] then
			Aurora[1].CreateBD(BWQ)
		elseif ElvUI then
			BWQ:SetTemplate("Transparent")
		elseif TipTac then
			local tiptacBKG = { tile = false, insets = {} }
			local cfg = TipTac_Config
			if cfg.tipBackdropBG and cfg.tipBackdropEdge and cfg.tipColor and cfg.tipBorderColor then
				tiptacBKG.bgFile = cfg.tipBackdropBG
				tiptacBKG.edgeFile = cfg.tipBackdropEdge
				tiptacBKG.edgeSize = cfg.backdropEdgeSize
				tiptacBKG.insets.left = cfg.backdropInsets
				tiptacBKG.insets.right = cfg.backdropInsets
				tiptacBKG.insets.top = cfg.backdropInsets
				tiptacBKG.insets.bottom = cfg.backdropInsets
				BWQ:SetBackdrop(tiptacBKG)
				BWQ:SetBackdropColor(unpack(cfg.tipColor))
				BWQ:SetBackdropBorderColor(unpack(cfg.tipBorderColor))
			end
		end

		hooksecurefunc(WorldMapFrame, "Hide", function(self)
			if C("attachToWorldMap") then
				BWQ:Hide()
			end

			BWQ.mapTextures.animationGroup:Stop()
			BWQ:HideAllWatchGlows(BWQ.currentMapId)
		end)
		hooksecurefunc(WorldMapFrame, "Show", function(self)
			if C("attachToWorldMap") then
				BWQ:AttachToWorldMap()
				BWQ:RunUpdate()
			end
		end)

		BWQ:UnregisterEvent("PLAYER_ENTERING_WORLD")

		BWQ:RegisterEvent("QUEST_LOG_UPDATE")
		BWQ:RegisterEvent("WORLD_MAP_UPDATE")
		BWQ:RegisterEvent("QUEST_WATCH_LIST_CHANGED")
	elseif event == "ADDON_LOADED" then
		if arg1 == "Broker_WorldQuests" then
			BWQcfg = BWQcfg or defaultConfig
			BWQcfgPerCharacter = BWQcfgPerCharacter and BWQcfgPerCharacter or BWQcfg and BWQcfg or defaultConfig
			for i, v in next, defaultConfig do
				if BWQcfg[i] == nil then
					BWQcfg[i] = v
				end
			end
			BWQcache = BWQcache or {}

			if IsAddOnLoaded('Blizzard_SharedMapDataProviders') then
				BWQ:AddFlightMapHook()
				BWQ:UnregisterEvent("ADDON_LOADED")
			end
		elseif arg1 == "Blizzard_SharedMapDataProviders" then
			BWQ:AddFlightMapHook()
			BWQ:UnregisterEvent("ADDON_LOADED")
		end
	end
end)

-- data broker object
local ldb = LibStub("LibDataBroker-1.1")
BWQ.WorldQuestsBroker = ldb:NewDataObject("WorldQuests", {
	type = "data source",
	text = "World Quests",
	icon = "Interface\\ICONS\\Achievement_Dungeon_Outland_DungeonMaster",
	OnEnter = function(self)
		if not C("showOnClick") then
			BWQ:AttachToBlock(self)
		end
	end,
	OnLeave = Block_OnLeave,
	OnClick = function(self, button)
		if button == "LeftButton" then
			if C("showOnClick") then
				BWQ:AttachToBlock(self)
			else
				BWQ:RunUpdate()
			end
		elseif button == "RightButton" then
			Block_OnLeave()
			BWQ:OpenConfigMenu(self)
		end
	end,
})
