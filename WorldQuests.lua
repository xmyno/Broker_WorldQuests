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

local             GetQuestsForPlayerByMapID,             GetQuestTimeLeftMinutes,             GetQuestInfoByQuestID,             GetQuestProgressBarInfo,            QuestHasWarModeBonus
	= C_TaskQuest.GetQuestsForPlayerByMapID, C_TaskQuest.GetQuestTimeLeftMinutes, C_TaskQuest.GetQuestInfoByQuestID, C_TaskQuest.GetQuestProgressBarInfo, C_QuestLog.QuestHasWarModeBonus

local            GetQuestTagInfo,            IsQuestFlaggedCompleted,            IsQuestCriteriaForBounty,            GetBountiesForMapID,            GetLogIndexForQuestID,            GetTitleForLogIndex,            GetQuestWatchType
	= C_QuestLog.GetQuestTagInfo, C_QuestLog.IsQuestFlaggedCompleted, C_QuestLog.IsQuestCriteriaForBounty, C_QuestLog.GetBountiesForMapID, C_QuestLog.GetLogIndexForQuestID, C_QuestLog.GetTitleForLogIndex, C_QuestLog.GetQuestWatchType

local              GetSuperTrackedQuestID
	= C_SuperTrack.GetSuperTrackedQuestID

local              IsFactionParagon,              GetFactionParagonInfo
	= C_Reputation.IsFactionParagon, C_Reputation.GetFactionParagonInfo

local       GetBestMapForUnit,       GetMapInfo
	= C_Map.GetBestMapForUnit, C_Map.GetMapInfo

local       IsWarModeDesired
	= C_PvP.IsWarModeDesired

local GetFactionInfoByID, GetQuestObjectiveInfo, GetNumQuestLogRewards, GetQuestLogRewardInfo, GetQuestLogRewardMoney, GetNumQuestLogRewardCurrencies, GetQuestLogRewardCurrencyInfo, HaveQuestData
	= GetFactionInfoByID, GetQuestObjectiveInfo, GetNumQuestLogRewards, GetQuestLogRewardInfo, GetQuestLogRewardMoney, GetNumQuestLogRewardCurrencies, GetQuestLogRewardCurrencyInfo, HaveQuestData

local REPUTATION
	= REPUTATION

local _, addon = ...
local CONSTANTS = addon.CONSTANTS
local DEBUG = false

local isHorde = UnitFactionGroup("player") == "Horde"

local MAP_ZONES = {
	[CONSTANTS.EXPANSIONS.SHADOWLANDS] = {
		[1525] = { id = 1525, name = GetMapInfo(1525).name, quests = {}, buttons = {}, }, --Revendreth 9.0
		[1533] = { id = 1533, name = GetMapInfo(1533).name, quests = {}, buttons = {}, }, -- Bastion 9.0
		[1536] = { id = 1536, name = GetMapInfo(1536).name, quests = {}, buttons = {}, }, -- Maldraxxus 9.0
		[1565] = { id = 1565, name = GetMapInfo(1565).name, quests = {}, buttons = {}, }, -- Ardenwald 9.0
	},
	[CONSTANTS.EXPANSIONS.BFA] = {
		[863] = { id = 863, name = GetMapInfo(863).name, faction = CONSTANTS.FACTIONS.HORDE, quests = {}, buttons = {}, },  -- Nazmir
		[864] = { id = 864, name = GetMapInfo(864).name, faction = CONSTANTS.FACTIONS.HORDE, quests = {}, buttons = {}, },  -- Vol'dun
		[862] = { id = 862, name = GetMapInfo(862).name, faction = CONSTANTS.FACTIONS.HORDE, quests = {}, buttons = {}, },  -- Zuldazar
		[895] = { id = 895, name = GetMapInfo(895).name, faction = CONSTANTS.FACTIONS.ALLIANCE, quests = {}, buttons = {}, },  -- Tiragarde
		[942] = { id = 942, name = GetMapInfo(942).name, faction = CONSTANTS.FACTIONS.ALLIANCE, quests = {}, buttons = {}, },  -- Stormsong Valley
		[896] = { id = 896, name = GetMapInfo(896).name, faction = CONSTANTS.FACTIONS.ALLIANCE, quests = {}, buttons = {}, },  -- Drustvar
		[1161] = { id = 1161, name = GetMapInfo(1161).name, faction = CONSTANTS.FACTIONS.ALLIANCE, quests = {}, buttons = {}, },  -- Boralus
		[1355] = { id = 1355, name = GetMapInfo(1355).name, quests = {}, buttons = {}, },  -- Nazjatar 8.2
		[1462] = { id = 1462, name = GetMapInfo(1462).name, quests = {}, buttons = {}, },  -- Mechagon 8.2
		[14] = { id = 14, name = GetMapInfo(14).name,  quests = {}, buttons = {}, },  -- Arathi
		[62] = { id = 62, name = GetMapInfo(62).name,  quests = {}, buttons = {}, },  -- Darkshore
	},
	[CONSTANTS.EXPANSIONS.LEGION] = {
		[630] = { id = 630, name = GetMapInfo(630).name, quests = {}, buttons = {}, },  -- Aszuna
		[790] = { id = 790, name = GetMapInfo(790).name, quests = {}, buttons = {}, },  -- Eye of Azshara
		[641] = { id = 641, name = GetMapInfo(641).name, quests = {}, buttons = {}, },  -- Val'sharah
		[650] = { id = 650, name = GetMapInfo(650).name, quests = {}, buttons = {}, },  -- Highmountain
		[634] = { id = 634, name = GetMapInfo(634).name, quests = {}, buttons = {}, },  -- Stormheim
		[680] = { id = 680, name = GetMapInfo(680).name, quests = {}, buttons = {}, },  -- Suramar
		[627] = { id = 627, name = GetMapInfo(627).name, quests = {}, buttons = {}, },  -- Dalaran
		[646] = { id = 646, name = GetMapInfo(646).name, quests = {}, buttons = {}, },  -- Broken Shore
		[830] = { id = 830, name = GetMapInfo(830).name, quests = {}, buttons = {}, },  -- Krokuun
		[882] = { id = 882, name = GetMapInfo(882).name, quests = {}, buttons = {}, },  -- Mac'aree
		[885] = { id = 885, name = GetMapInfo(885).name, quests = {}, buttons = {}, },  -- Antoran Wastes
	},
}
local MAP_ZONES_SORT = {
	[CONSTANTS.EXPANSIONS.SHADOWLANDS] = {
		1525, 1533, 1536, 1565
	},
	[CONSTANTS.EXPANSIONS.BFA] = {
		1355, 1462, 62, 14, 863, 864, 862, 895, 942, 896, 1161
	},
	[CONSTANTS.EXPANSIONS.LEGION] = {
		630, 790, 641, 650, 634, 680, 627, 646, 830, 882, 885
	},
}


local defaultConfig = {
	-- general
	attachToWorldMap = false,
	showOnClick = false,
	usePerCharacterSettings = false,
	expansion = CONSTANTS.EXPANSIONS.BFA, -- TODO: set to SHADOWLANDS on launch
	enableClickToOpenMap = false,
	enableTomTomWaypointsOnClick = true,
	alwaysShowBountyQuests = true,
	alwaysShowEpicQuests = true,
	onlyShowRareOrAbove = false,
	showTotalsInBrokerText = true,
		brokerShowAP = true,
		brokerShowServiceMedals = true,
		brokerShowWakeningEssences = true,
		brokerShowWarResources = true,
		brokerShowPrismaticManapearl = true,
		brokerShowResources = true,
		brokerShowLegionfallSupplies = true,
		brokerShowHonor = true,
		brokerShowGold = false,
		brokerShowGear = false,
		brokerShowMarkOfHonor = false,
		brokerShowHerbalism = false,
		brokerShowMining = false,
		brokerShowFishing = false,
		brokerShowSkinning = false,
		brokerShowBloodOfSargeras = false,
	sortByTimeRemaining = false,
	-- reward type
	showArtifactPower = true,
	showPrismaticManapearl = true,
	showItems = true,
		showGear = true,
		showRelics = true,
		showCraftingMaterials = true,
		showMarkOfHonor = true,
		showOtherItems = true,
	showSLReputation = true,
	showBFAReputation = true,
	showBFAServiceMedals = true,
	showHonor = true,
	showLowGold = true,
	showHighGold = true,
	showWarResources = true,
	showResources = true,
	showLegionfallSupplies = true,
	showNethershards = true,
	showArgunite = true,
	showWakeningEssences = true,
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
		showProfessionFishing = true,
	showDungeon = true,
	showPvP = true,
	hideFactionColumn = false,
	hideFactionParagonBars = false,
	-- BFA
	alwaysShow7thLegion = false,
	alwaysShowStormsWake = false,
	alwaysShowOrderOfEmbers = false,
	alwaysShowProudmooreAdmiralty = false,
	alwaysShowWavebladeAnkoan = false,
	alwaysShowTheHonorbound = false,
	alwaysShowZandalariEmpire = false,
	alwaysShowTalanjisExpedition = false,
	alwaysShowVoldunai = false,
	alwaysShowTheUnshackled = false,
	alwaysShowRustboltResistance = false,
	alwaysShowTortollanSeekers = false,
	alwaysShowChampionsOfAzeroth = false,
		-- Legion
		alwaysShowCourtOfFarondis = false,
		alwaysShowDreamweavers = false,
		alwaysShowHighmountainTribe = false,
		alwaysShowNightfallen = false,
		alwaysShowWardens = false,
		alwaysShowValarjar = false,
		alwaysShowArmiesOfLegionfall = false,
		alwaysShowArmyOfTheLight = false,
		alwaysShowArgussianReach = false,
		
		-- Shadowlands
		alwaysShowAscended = false,
		alwaysShowUndyingArmy = false,
		alwaysShowCourtofHarvesters = false,
		alwaysShowAvowed = false,
		alwaysShowWildHunt = false,

	showPetBattle = true,
	hidePetBattleBountyQuests = false,
	alwaysShowPetBattleFamilyFamiliar = true,

	collapsedZones = {},
}
local C = function(k)
	if BWQcfg.usePerCharacterSettings then
		return BWQcfgPerCharacter[k]
	else
		return BWQcfg[k]
	end
end

local expansion
local warmodeEnabled = false

local BWQ = CreateFrame("Frame", "Broker_WorldQuests", UIParent, "BackdropTemplate")
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


BWQ.buttonShadowlands = CreateFrame("Button", nil, BWQ, "BackdropTemplate")
BWQ.buttonShadowlands:SetSize(20, 15)
BWQ.buttonShadowlands:SetPoint("TOPRIGHT", BWQ, "TOPRIGHT", -92, -8)
BWQ.buttonShadowlands:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = false, tileSize = 0, edgeSize = 2, insets = { left = 0, right = 0, top = 0, bottom = 0 }, })
BWQ.buttonShadowlands:SetBackdropColor(0.1, 0.1, 0.1)
BWQ.buttonShadowlands.texture = BWQ.buttonShadowlands:CreateTexture(nil, "OVERLAY")
BWQ.buttonShadowlands.texture:SetPoint("TOPLEFT", 1, -1)
BWQ.buttonShadowlands.texture:SetPoint("BOTTOMRIGHT", -1, 1)
BWQ.buttonShadowlands.texture:SetTexture("Interface\\Calendar\\Holidays\\Calendar_WeekendShadowlandsStart")
BWQ.buttonShadowlands.texture:SetTexCoord(0.15, 0.55, 0.23, 0.47)

BWQ.buttonBFA = CreateFrame("Button", nil, BWQ, "BackdropTemplate")
BWQ.buttonBFA:SetSize(20, 15)
BWQ.buttonBFA:SetPoint("TOPRIGHT", BWQ, "TOPRIGHT", -65, -8)
BWQ.buttonBFA:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = false, tileSize = 0, edgeSize = 2, insets = { left = 0, right = 0, top = 0, bottom = 0 }, })
BWQ.buttonBFA:SetBackdropColor(0.1, 0.1, 0.1)
BWQ.buttonBFA.texture = BWQ.buttonBFA:CreateTexture(nil, "OVERLAY")
BWQ.buttonBFA.texture:SetPoint("TOPLEFT", 1, -1)
BWQ.buttonBFA.texture:SetPoint("BOTTOMRIGHT", -1, 1)
BWQ.buttonBFA.texture:SetTexture("Interface\\Calendar\\Holidays\\Calendar_WeekendBattleforAzerothStart")
BWQ.buttonBFA.texture:SetTexCoord(0.15, 0.55, 0.23, 0.45)

BWQ.buttonLegion = CreateFrame("Button", nil, BWQ, "BackdropTemplate")
BWQ.buttonLegion:SetSize(20, 15)
BWQ.buttonLegion:SetPoint("TOPRIGHT", BWQ, "TOPRIGHT", -38, -8)
BWQ.buttonLegion:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = false, tileSize = 0, edgeSize = 2, insets = { left = 0, right = 0, top = 0, bottom = 0 }, })
BWQ.buttonLegion:SetBackdropColor(0.1, 0.1, 0.1)
BWQ.buttonLegion.texture = BWQ.buttonLegion:CreateTexture(nil, "OVERLAY")
BWQ.buttonLegion.texture:SetPoint("TOPLEFT", 1, -1)
BWQ.buttonLegion.texture:SetPoint("BOTTOMRIGHT", -1, 1)
BWQ.buttonLegion.texture:SetTexture("Interface\\Calendar\\Holidays\\Calendar_WeekendLegionStart")
BWQ.buttonLegion.texture:SetTexCoord(0.15, 0.55, 0.23, 0.47)

BWQ.buttonShadowlands:SetScript("OnClick", function(self) BWQ:SwitchExpansion(CONSTANTS.EXPANSIONS.SHADOWLANDS) end)
BWQ.buttonBFA:SetScript("OnClick", function(self) BWQ:SwitchExpansion(CONSTANTS.EXPANSIONS.BFA) end)
BWQ.buttonLegion:SetScript("OnClick", function(self) BWQ:SwitchExpansion(CONSTANTS.EXPANSIONS.LEGION) end)

BWQ.buttonSettings = CreateFrame("BUTTON", nil, BWQ, "BackdropTemplate")
BWQ.buttonSettings:SetWidth(15)
BWQ.buttonSettings:SetHeight(15)
BWQ.buttonSettings:SetPoint("TOPRIGHT", BWQ, "TOPRIGHT", -12, -8)
BWQ.buttonSettings.texture = BWQ.buttonSettings:CreateTexture(nil, "BORDER")
BWQ.buttonSettings.texture:SetAllPoints()
BWQ.buttonSettings.texture:SetTexture("Interface\\WorldMap\\Gear_64.png")
BWQ.buttonSettings.texture:SetTexCoord(0, 0.50, 0, 0.50)
BWQ.buttonSettings.texture:SetVertexColor(1.0, 0.82, 0, 1.0)
BWQ.buttonSettings:SetScript("OnClick", function(self) BWQ:OpenConfigMenu(self) end)

local Block_OnLeave = function(self)
	if not C("attachToWorldMap") or (C("attachToWorldMap") and not WorldMapFrame:IsShown()) then
		if not BWQ:IsMouseOver() then
			BWQ:Hide()
		end
	end
end
BWQ:SetScript("OnLeave", Block_OnLeave)

BWQ.slider = CreateFrame("Slider", nil, BWQ, "BackdropTemplate")
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
local hasCollapsedQuests = false
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
		hasUnlockedWorldQuests = (expansion == CONSTANTS.EXPANSIONS.SHADOWLANDS and UnitLevel("player") >= 51 and IsQuestFlaggedCompleted(57559))
			or (expansion == CONSTANTS.EXPANSIONS.BFA and UnitLevel("player") >= 50 and
				(IsQuestFlaggedCompleted(51916) or IsQuestFlaggedCompleted(52451) -- horde
				or IsQuestFlaggedCompleted(51918) or IsQuestFlaggedCompleted(52450))) -- alliance
			or (expansion == CONSTANTS.EXPANSIONS.LEGION and UnitLevel("player") >= 45 and
				(IsQuestFlaggedCompleted(43341) or IsQuestFlaggedCompleted(45727))) -- broken isles
	end

	if not hasUnlockedWorldQuests then
		if not BWQ.errorFS then CreateErrorFS() end

		local level, quest
		if expansion == CONSTANTS.EXPANSIONS.SHADOWLANDS then
			level = "51" -- TODO: can we somehow find out if we have a character that reached 60?
			quest = "|cffffff00|Hquest:57559:-1|h[UNKNOWN TITLE]|h|r" -- TODO: find the corresponding Covenant lines
		elseif expansion == CONSTANTS.EXPANSIONS.BFA then
			level = "50"
			quest = isHorde and "|cffffff00|Hquest:57559:-1|h[Uniting Zandalar]|h|r" or "|cffffff00|Hquest:51918:-1|h[Uniting Kul Tiras]|h|r"
		else -- legion
			level = "45"
			quest = "|cffffff00|Hquest:43341:-1|h[Uniting the Isles]|h|r"
		end

		BWQ:SetErrorFSPosition(offsetTop)
		BWQ.errorFS:SetText(("You need to reach Level %s and complete the\nquest %s to unlock World Quests."):format(level, quest))
		BWQ:SetSize(BWQ.errorFS:GetStringWidth() + 20, BWQ.errorFS:GetStringHeight() + 45)
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
	BWQ:SetErrorFSPosition(offsetTop - 10)
	BWQ.errorFS:SetPoint("TOP", BWQ, "TOP", 0, offsetTop - 10)

	BWQ.errorFS:SetText("There are no world quests available that match your filter settings.")
	BWQ.errorFS:Show()
end

function BWQ:SetErrorFSPosition(offsetTop)
	if BWQ.factionDisplay:IsShown() then
		BWQ.errorFS:SetPoint("TOP", BWQ.factionDisplay, "BOTTOM", 0, -10)
	else 
		BWQ.errorFS:SetPoint("TOP", BWQ, "TOP", 0, offsetTop)
	end
end

local locale = GetLocale()
local millionSearchLocalized = { enUS = "million", enGB = "million", zhCN = "万", frFR = "million", deDE = "Million", esES = "mill", itIT = "milion", koKR = "만", esMX = "mill", ptBR = "milh", ruRU = "млн", zhTW = "萬", }
local billionSearchLocalized = { enUS = "billion", enGB = "billion", zhCN = "亿", frFR = "milliard", deDE = "Milliarde", esES = "mil millones", itIT = "miliard", koKR = "억", esMX = "mil millones", ptBR = "bilh", ruRU = "млрд", zhTW = "億", }
local BWQScanTooltip = CreateFrame("GameTooltip", "BWQScanTooltip", nil, "GameTooltipTemplate", "BackdropTemplate")
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
				-- gsub french special-space character (wtf..)
				local power = text:gsub(" ", ""):match("%d+%p?%d*") or "0"
				if (text:find(millionSearchLocalized[locale])) then
					-- en locale only use ',' for thousands, shouldn't occur in these million digit numbers
					-- replace ',' for german etc comma numbers so we can do math with them.
					power = power:gsub(",", ".")
					power = power * 1000000
				elseif (text:find(billionSearchLocalized[locale])) then
					power = power:gsub(",", ".")
					power = power * 1000000000
				else 
					-- get rid of thousands comma for non-million numbers
					power = power:gsub("%p", "")
				end

				return power
			end
		end
	end
	return "0"
end
function BWQ:GetItemLevelValueForQuestId(questId)
	BWQScanTooltip:SetOwner(BWQ, "ANCHOR_NONE")
	BWQScanTooltip:SetQuestLogItem("reward", 1, questId)
	local numLines = BWQScanTooltip:NumLines()
	for i = 2, numLines do
		local text = _G["BWQScanTooltipTextLeft" .. i]:GetText()
		local e = ITEM_LEVEL_PLUS:find("%%d")
		if text and text:find(ITEM_LEVEL_PLUS:sub(1, e - 1)) then
			return text:match("%d+%+?") or ""
		end
	end
	return ""
end

function BWQ:ValueWithWarModeBonus(questId, value)
	local multiplier = warmodeEnabled and 1.1 or 1
	return floor(value * multiplier + 0.5)
end

function BWQ:IsQuestAchievementCriteriaMissing(achievementId, questId)
	local criteriaId = CONSTANTS.ACHIEVEMENT_CRITERIAS[questId]
	if criteriaId then
		local _, _, completed = GetAchievementCriteriaInfo(achievementId, criteriaId)
		return not completed
	else
		return false
	end
end

local AbbreviateNumber = function(number)
	number = tonumber(number)
	if number >= 1000000 then
		number = number / 1000000
		return string.format((number % 1 == 0) and "%.0f%s" or "%.1f%s", number, "M")
	elseif number >= 10000 then
		return string.format("%.0f%s", number / 1000, "K")
	end
	return number
end

local FormatTimeLeftString = function(timeLeft)
	if timeLeft <= 0 then return "" end
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
	local color = WORLD_QUEST_QUALITY_COLORS[row.quest.quality]
	tip:AddLine(row.quest.title, color.r, color.g, color.b, true)

	for objectiveIndex = 1, row.quest.numObjectives do
		local objectiveText, objectiveType, finished = GetQuestObjectiveInfo(row.quest.questId, objectiveIndex, false);
		if objectiveText and #objectiveText > 0 then
			color = finished and GRAY_FONT_COLOR or HIGHLIGHT_FONT_COLOR;
			tip:AddLine(QUEST_DASH .. objectiveText, color.r, color.g, color.b, true);
		end
	end

	local percent = GetQuestProgressBarInfo(row.quest.questId)
	if percent then
		GameTooltip_ShowProgressBar(tip, 0, 100, percent, PERCENTAGE_STRING:format(percent))
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
local mapTextures = CreateFrame("Frame", "BWQ_MapTextures", WorldMapFrame:GetCanvas())
mapTextures:SetSize(200,200)
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
	local quests = GetQuestsForPlayerByMapID(mapId)
	if quests then
		for _, v in next, quests do
			local quest = MAP_ZONES[expansion][mapId].quests[v.questId] 
			if quest then
				quest.x = v.x
				quest.y = v.y
			end
		end
	end
end

function BWQ:CalculateMapPosition(x, y)
	return x * WorldMapFrame:GetCanvas():GetWidth() , -1 * y * WorldMapFrame:GetCanvas():GetHeight() 
end
local currentTomTomWaypoint
local Row_OnClick = function(row)
	if IsShiftKeyDown() then
		if (GetQuestWatchType(row.quest.questId) == Enum.QuestWatchType.Manual or GetSuperTrackedQuestID() == row.quest.questId) then
			BonusObjectiveTracker_UntrackWorldQuest(row.quest.questId)
		else
			BonusObjectiveTracker_TrackWorldQuest(row.quest.questId, Enum.QuestWatchType.Manual)
		end
	else
		if not WorldMapFrame:IsShown() then ShowUIPanel(WorldMapFrame) end
		if WorldMapFrame:IsShown() then
			WorldMapFrame:SetMapID(row.mapId)
			if not row.quest.x or not row.quest.y then BWQ:QueryZoneQuestCoordinates(row.mapId) end
			if row.quest.x and row.quest.y then
				local x, y = BWQ:CalculateMapPosition(row.quest.x, row.quest.y)
				local scale = WorldMapFrame:GetCanvasScale()
				local size = 30 / scale
				BWQ.mapTextures:ClearAllPoints()
				BWQ.mapTextures.highlightArrow:SetSize(size, size)
				BWQ.mapTextures:SetPoint("CENTER", WorldMapFrame:GetCanvas(), "TOPLEFT", x, y + 25 + (scale < 0.5 and 50 or 0))
				BWQ.mapTextures.animationGroup:Play()
			end
		end

		if TomTom and C("enableTomTomWaypointsOnClick") then
			if not row.quest.x or not row.quest.y then BWQ:QueryZoneQuestCoordinates(row.mapId) end
			if row.quest.x and row.quest.y then
				if currentTomTomWaypoint then TomTom:RemoveWaypoint(currentTomTomWaypoint) end
				currentTomTomWaypoint = TomTom:AddWaypoint(row.mapId, row.quest.x, row.quest.y, { title = row.quest.title, silent = true })
			end
		end
	end
end


local lastUpdate, updateTries = 0, 0
local needsRefresh = false
local RetrieveWorldQuests = function(mapId)

	local numQuests = 0
	local currentTime = GetTime()
	local questList = GetQuestsForPlayerByMapID(mapId)
	warmodeEnabled = IsWarModeDesired()

	-- quest object fields are: x, y, floor, numObjectives, questId, inProgress
	if questList then
		numQuests = 0
		MAP_ZONES[expansion][mapId].questsSort = {}

		local timeLeft, questTagInfo, title, factionId
		for i, q in ipairs(questList) do
				if HaveQuestData(q.questId) and q.mapID == mapId then 
				--[[
					questTagInfo = {
						tagId = 116
						tagName = Blacksmithing World Quest
						worldQuestType =
							1 -> profession,
							2 -> pve?
							3 -> pvp
							4 -> battle pet
							5 -> ??
							6 -> dungeon
							7 -> invasion
							8 -> raid
						quality =
							1 -> normal
							2 -> rare
							3 -> epic
						isElite = true/false
						tradeskillLineIndex = some number, no idea of meaning atm
					}
				]]

				timeLeft = GetQuestTimeLeftMinutes(q.questId) or 0
				questTagInfo = GetQuestTagInfo(q.questId)

				if questTagInfo and questTagInfo.worldQuestType then
					local questId = q.questId
					table.insert(MAP_ZONES[expansion][mapId].questsSort, questId)
					local quest = MAP_ZONES[expansion][mapId].quests[questId] or {}

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
					quest.numObjectives = q.numObjectives
					quest.xFlight = q.x
					quest.yFlight = q.y

					-- GetQuestTagInfo fields
					quest.tagId = questTagInfo.tagId
					quest.tagName = questTagInfo.tagName
					quest.worldQuestType = questTagInfo.worldQuestType
					quest.quality = questTagInfo.quality
					quest.isElite = questTagInfo.isElite

					title, factionId = GetQuestInfoByQuestID(quest.questId)
					quest.title = title
					quest.factionId = factionId
					if factionId then
						quest.faction = GetFactionInfoByID(factionId)
					end
					quest.timeLeft = timeLeft
					quest.bounties = {}

					quest.reward = {}
					local rewardType = {}
					local hasReward = false
					
					-- item reward
					if GetNumQuestLogRewards(quest.questId) > 0 then
						local itemName, itemTexture, quantity, quality, isUsable, itemId = GetQuestLogRewardInfo(1, quest.questId)
						if itemName then
							hasReward = true
							quest.reward.itemTexture = itemTexture
							quest.reward.itemId = itemId
							quest.reward.itemQuality = quality
							quest.reward.itemQuantity = quantity
							quest.reward.itemName = itemName
							
							local _, _, _, _, _, _, _, _, equipSlot, _, _, classId, subClassId = GetItemInfo(quest.reward.itemId)
							if classId == 7 then
								quest.sort = quest.sort > CONSTANTS.SORT_ORDER.PROFESSION and quest.sort or CONSTANTS.SORT_ORDER.PROFESSION
								if quest.reward.itemId == 124124 then
									rewardType[#rewardType+1] = CONSTANTS.REWARD_TYPES.BLOODOFSARGERAS
								end
								if C("showItems") and C("showCraftingMaterials") then quest.hide = false end
							elseif equipSlot ~= "" or itemId == 163857 --[[ Azerite Armor Cache ]] then
								quest.sort = quest.sort > CONSTANTS.SORT_ORDER.EQUIP and quest.sort or CONSTANTS.SORT_ORDER.EQUIP
								quest.reward.realItemLevel = BWQ:GetItemLevelValueForQuestId(quest.questId)
								rewardType[#rewardType+1] = CONSTANTS.REWARD_TYPES.GEAR

								if C("showItems") and C("showGear") then quest.hide = false end
							elseif itemId == 137642 then
								quest.sort = quest.sort > CONSTANTS.SORT_ORDER.ITEM and quest.sort or CONSTANTS.SORT_ORDER.ITEM
								rewardType[#rewardType+1] = CONSTANTS.REWARD_TYPES.MARK_OF_HONOR
								if C("showItems") and C("showMarkOfHonor") then quest.hide = false end
							else
								quest.sort = quest.sort > CONSTANTS.SORT_ORDER.ITEM and quest.sort or CONSTANTS.SORT_ORDER.ITEM
								rewardType[#rewardType+1] = CONSTANTS.REWARD_TYPES.IRRELEVANT
								if C("showItems") and C("showOtherItems") then quest.hide = false end
							end
						end
					end
					-- gold reward
					local money = GetQuestLogRewardMoney(quest.questId);
					if money > 20000 then -- >2g, hides these silly low gold extra rewards
						hasReward = true
						quest.reward.money = floor(BWQ:ValueWithWarModeBonus(quest.questId, money) / 10000) * 10000
						quest.sort = quest.sort > CONSTANTS.SORT_ORDER.MONEY and quest.sort or CONSTANTS.SORT_ORDER.MONEY
						rewardType[#rewardType+1] = CONSTANTS.REWARD_TYPES.MONEY

						if money < 1000000 then
							if C("showLowGold") then quest.hide = false end
						else
							if C("showHighGold") then quest.hide = false end
						end
					end
					local honor = GetQuestLogRewardHonor(quest.questId)
					if honor > 0 then
						hasReward = true
						quest.reward.honor = honor
						quest.sort = quest.sort > CONSTANTS.SORT_ORDER.HONOR and quest.sort or CONSTANTS.SORT_ORDER.HONOR
						rewardType[#rewardType+1] = CONSTANTS.REWARD_TYPES.HONOR

						if C("showHonor") then quest.hide = false end
					end
					-- currency reward
					local numQuestCurrencies = GetNumQuestLogRewardCurrencies(quest.questId)
					quest.reward.currencies = {}
					for i = 1, numQuestCurrencies do
						local name, texture, numItems, currencyId = GetQuestLogRewardCurrencyInfo(i, quest.questId)
						if name then
							hasReward = true
							local currency = {}
							if CONSTANTS.CURRENCIES_AFFECTED_BY_WARMODE[currencyId] then
								currency.amount = BWQ:ValueWithWarModeBonus(quest.questId, numItems)
							else
								currency.amount = numItems
							end
							currency.name = string.format("%d %s", currency.amount, name)
							currency.texture = texture
							
							if currencyId == 1553 then -- azerite
								currency.name = string.format("|cffe5cc80[%d %s]|r", currency.amount, name)
								rewardType[#rewardType+1] = CONSTANTS.REWARD_TYPES.ARTIFACTPOWER
								quest.reward.azeriteAmount = currency.amount -- todo: improve broker text values?
								if C("showArtifactPower") then quest.hide = false end
							elseif CONSTANTS.SHADOWLANDS_REPUTATION_CURRENCY_IDS[currencyId] then
								currency.name = string.format("%s: %d %s", name, currency.amount, REPUTATION)
								rewardType[#rewardType+1] = CONSTANTS.REWARD_TYPES.IRRELEVANT
								if C("showSLReputation") then quest.hide = false end
							elseif CONSTANTS.BFA_REPUTATION_CURRENCY_IDS[currencyId] then
								currency.name = string.format("%s: %d %s", name, currency.amount, REPUTATION)
								rewardType[#rewardType+1] = CONSTANTS.REWARD_TYPES.IRRELEVANT
								if C("showBFAReputation") then quest.hide = false end
							elseif currencyId == 1560 then -- war resources
								rewardType[#rewardType+1] = CONSTANTS.REWARD_TYPES.WAR_RESOURCES
								quest.reward.warResourceAmount = currency.amount
								if C("showWarResources") then quest.hide = false end
							elseif currencyId == 1716 or currencyId == 1717 then -- service medals
								rewardType[#rewardType+1] = CONSTANTS.REWARD_TYPES.SERVICE_MEDALS
								quest.reward.serviceMedalAmount = currency.amount
								if C("showBFAServiceMedals") then quest.hide = false end
							elseif currencyId == 1220 then -- order hall resources
								rewardType[#rewardType+1] = CONSTANTS.REWARD_TYPES.RESOURCES
								quest.reward.resourceAmount = currency.amount
								if C("showResources") then quest.hide = false end
							elseif currencyId == 1342 then -- legionfall supplies
								rewardType[#rewardType+1] = CONSTANTS.REWARD_TYPES.LEGIONFALL_SUPPLIES
								quest.reward.legionfallSuppliesAmount = currency.amount
								if C("showLegionfallSupplies") then quest.hide = false end
							elseif currencyId == 1226 then -- nethershard
								rewardType[#rewardType+1] = CONSTANTS.REWARD_TYPES.NETHERSHARD
								if C("showNethershards") then quest.hide = false end
							elseif currencyId == 1508 then -- argunite
								rewardType[#rewardType+1] = CONSTANTS.REWARD_TYPES.ARGUNITE
								if C("showArgunite") then quest.hide = false end
							elseif currencyId == 1533 then
								rewardType[#rewardType+1] = CONSTANTS.REWARD_TYPES.WAKENING_ESSENCES
								quest.reward.wakeningEssencesAmount = currency.amount
								if C("showWakeningEssences") then quest.hide = false end
							elseif currencyId == 1721 then -- prismatic manapearl
								rewardType[#rewardType+1] = CONSTANTS.REWARD_TYPES.PRISMATIC_MANAPEARL
								quest.reward.prismaticManapearlAmount = currency.amount
								if C("showPrismaticManapearl") then quest.hide = false end
							else 
								if DEBUG then print(string.format("[BWQ] Unhandled currency: ID %s", currencyId)) end
							end
							quest.reward.currencies[#quest.reward.currencies + 1] = currency

							if currencyId == 1553 then
								quest.sort = quest.sort > CONSTANTS.SORT_ORDER.ARTIFACTPOWER and quest.sort or CONSTANTS.SORT_ORDER.ARTIFACTPOWER
							else
								quest.sort = quest.sort > CONSTANTS.SORT_ORDER.RESOURCES and quest.sort or CONSTANTS.SORT_ORDER.RESOURCES
							end
							
						end
					end

					if DEBUG and not hasReward and not HaveQuestData(quest.questId) then
						print(string.format("[BWQ] Quest with no reward found: ID %s (%s)", quest.questId, quest.title))
					end
					if not hasReward then needsRefresh = true end -- in most cases no reward means api returned incomplete data
					
					for _, bounty in ipairs(bounties) do
						if IsQuestCriteriaForBounty(quest.questId, bounty.questID) then
							quest.bounties[#quest.bounties + 1] = bounty.icon
						end
					end

					local questType = {}
					-- quest type filters
					if quest.worldQuestType == CONSTANTS.WORLD_QUEST_TYPES.PETBATTLE then
						if C("showPetBattle") or (C("alwaysShowPetBattleFamilyFamiliar") and CONSTANTS.FAMILY_FAMILIAR_QUEST_IDS[quest.questId] ~= nil) then
							quest.hide = false
						else
							quest.hide = true
						end

						quest.isMissingAchievementCriteria = BWQ:IsQuestAchievementCriteriaMissing(CONSTANTS.ACHIEVEMENT_IDS.PET_BATTLE_WQ[expansion], quest.questId)
					elseif quest.worldQuestType == CONSTANTS.WORLD_QUEST_TYPES.PROFESSION then
						if C("showProfession") then

							if quest.tagId == 119 then
								questType[#questType+1] = CONSTANTS.QUEST_TYPES.HERBALISM
								if C("showProfessionHerbalism")	then quest.hide = false else quest.hide = true end
							elseif quest.tagId == 120 then
								questType[#questType+1] = CONSTANTS.QUEST_TYPES.MINING
								if C("showProfessionMining") then quest.hide = false else quest.hide = true end
							elseif quest.tagId == 130 then
								questType[#questType+1] = CONSTANTS.QUEST_TYPES.FISHING
								quest.isMissingAchievementCriteria = BWQ:IsQuestAchievementCriteriaMissing(CONSTANTS.ACHIEVEMENT_IDS.LEGION_FISHING_WQ, quest.questId)
								if C("showProfessionFishing") then quest.hide = false else quest.hide = true end
							elseif quest.tagId == 124 then
								questType[#questType+1] = CONSTANTS.QUEST_TYPES.SKINNING
								if C("showProfessionSkinning") then quest.hide = false else quest.hide = true end
							elseif quest.tagId == 118 then 	if C("showProfessionAlchemy") 			then quest.hide = false else quest.hide = true end
							elseif quest.tagId == 129 then	if C("showProfessionArchaeology") 		then quest.hide = false else quest.hide = true end
							elseif quest.tagId == 116 then 	if C("showProfessionBlacksmithing") 	then quest.hide = false else quest.hide = true end
							elseif quest.tagId == 131 then 	if C("showProfessionCooking") 			then quest.hide = false else quest.hide = true end
							elseif quest.tagId == 123 then 	if C("showProfessionEnchanting") 		then quest.hide = false else quest.hide = true end
							elseif quest.tagId == 122 then 	if C("showProfessionEngineering") 		then quest.hide = false else quest.hide = true end
							elseif quest.tagId == 126 then 	if C("showProfessionInscription") 		then quest.hide = false else quest.hide = true end
							elseif quest.tagId == 125 then 	if C("showProfessionJewelcrafting") 	then quest.hide = false else quest.hide = true end
							elseif quest.tagId == 117 then 	if C("showProfessionLeatherworking") 	then quest.hide = false else quest.hide = true end
							elseif quest.tagId == 121 then 	if C("showProfessionTailoring") 		then quest.hide = false else quest.hide = true end
							end
						else
							quest.hide = true
						end
					elseif not C("showPvP") and quest.worldQuestType == CONSTANTS.WORLD_QUEST_TYPES.PVP then quest.hide = true
					elseif not C("showDungeon") and quest.worldQuestType == CONSTANTS.WORLD_QUEST_TYPES.DUNGEON then quest.hide = true
					end

					-- only show quest that are blue or above quality
					if (C("onlyShowRareOrAbove") and quest.quality < 1) then quest.hide = true end

					-- always show bounty quests or reputation for faction filter
					if (C("alwaysShowBountyQuests") and #quest.bounties > 0) or
						-- Shadowlands
						(C("alwaysShowAscended") and quest.factionId == 2407) or
						(C("alwaysShowUndyingArmy") and quest.factionId == 2410) or
						(C("alwaysShowCourtofHarvesters") and quest.factionId == 2413) or
						(C("alwaysShowAvowed") and quest.factionId == 2439) or
						(C("alwaysShowWildHunt") and quest.factionId == 2465) or
						-- bfa
						(C("alwaysShow7thLegion") and quest.factionId == 2159) or
						(C("alwaysShowStormsWake") and quest.factionId == 2162) or
						(C("alwaysShowOrderOfEmbers") and quest.factionId == 2161) or
						(C("alwaysShowProudmooreAdmiralty") and quest.factionId == 2160) or
						(C("alwaysShowTheHonorbound") and quest.factionId == 2157) or
						(C("alwaysShowZandalariEmpire") and quest.factionId == 2103) or
						(C("alwaysShowTalanjisExpedition") and quest.factionId == 2156) or
						(C("alwaysShowVoldunai") and quest.factionId == 2158) or
						(C("alwaysShowTortollanSeekers") and quest.factionId == 2163) or
						(C("alwaysShowChampionsOfAzeroth") and quest.factionId == 2164) or
						-- 8.2 --
						(C("alwaysShowTheUnshackled") and quest.factionId == 2373) or
						(C("alwaysShowWavebladeAnkoan") and quest.factionId == 2400) or
						(C("alwaysShowRustboltResistance") and quest.factionId == 2391) or
						-- legion
						(C("alwaysShowCourtOfFarondis") and (mapId == 630 or mapId == 790)) or
						(C("alwaysShowDreamweavers") and mapId == 641) or
						(C("alwaysShowHighmountainTribe") and mapId == 650) or
						(C("alwaysShowNightfallen") and mapId == 680) or
						(C("alwaysShowWardens") and quest.factionId == 1894) or
						(C("alwaysShowValarjar") and mapId == 634) or
						(C("alwaysShowArmiesOfLegionfall") and mapId == 646) or
						(C("alwaysShowArmyOfTheLight") and quest.factionId == 2165) or
						(C("alwaysShowArgussianReach") and quest.factionId == 2170) then

						-- pet battle override
						if C("hidePetBattleBountyQuests") and not C("showPetBattle") and quest.worldQuestType == CONSTANTS.WORLD_QUEST_TYPES.PETBATTLE then
							quest.hide = true
						else
							quest.hide = false
						end
					end
					-- don't filter epic quests based on setting
					if C("alwaysShowEpicQuests") and (quest.quality == 2 or quest.worldQuestType == CONSTANTS.WORLD_QUEST_TYPES.RAID) then quest.hide = false end

					MAP_ZONES[expansion][mapId].quests[questId] = quest

					if not quest.hide then
						numQuests = numQuests + 1

						if rewardType then
							for _, rtype in next, rewardType do
								if rtype == CONSTANTS.REWARD_TYPES.ARTIFACTPOWER and quest.reward.azeriteAmount then
									BWQ.totalArtifactPower = BWQ.totalArtifactPower + (quest.reward.azeriteAmount or 0) end
								if rtype == CONSTANTS.REWARD_TYPES.WAKENING_ESSENCES and quest.reward.wakeningEssencesAmount then
									BWQ.totalWakeningEssences = BWQ.totalWakeningEssences + quest.reward.wakeningEssencesAmount end
								if rtype == CONSTANTS.REWARD_TYPES.WAR_RESOURCES and quest.reward.warResourceAmount then
									BWQ.totalWarResources = BWQ.totalWarResources + quest.reward.warResourceAmount end
								if rtype == CONSTANTS.REWARD_TYPES.SERVICE_MEDALS and quest.reward.serviceMedalAmount then
									BWQ.totalServiceMedals = BWQ.totalServiceMedals + quest.reward.serviceMedalAmount end
								if rtype == CONSTANTS.REWARD_TYPES.RESOURCES and quest.reward.resourceAmount then
									BWQ.totalResources = BWQ.totalResources + quest.reward.resourceAmount end
								if rtype == CONSTANTS.REWARD_TYPES.LEGIONFALL_SUPPLIES and quest.reward.legionfallSuppliesAmount then
									BWQ.totalLegionfallSupplies = BWQ.totalLegionfallSupplies + quest.reward.legionfallSuppliesAmount end
								if rtype == CONSTANTS.REWARD_TYPES.HONOR and quest.reward.honor then
									BWQ.totalHonor = BWQ.totalHonor + quest.reward.honor end
								if rtype == CONSTANTS.REWARD_TYPES.MONEY and quest.reward.money then
									BWQ.totalGold = BWQ.totalGold + quest.reward.money end
								if rtype == CONSTANTS.REWARD_TYPES.BLOODOFSARGERAS and quest.reward.itemQuantity then
									BWQ.totalBloodOfSargeras = BWQ.totalBloodOfSargeras + quest.reward.itemQuantity end
								if rtype == CONSTANTS.REWARD_TYPES.GEAR then
									BWQ.totalGear = BWQ.totalGear + 1 end
								if rtype == CONSTANTS.REWARD_TYPES.MARK_OF_HONOR then
									BWQ.totalMarkOfHonor = BWQ.totalMarkOfHonor + quest.reward.itemQuantity end
								if rtype == CONSTANTS.REWARD_TYPES.PRISMATIC_MANAPEARL then
									BWQ.totalPrismaticManapearl = BWQ.totalPrismaticManapearl + quest.reward.prismaticManapearlAmount end
							end
						end
						if questType then
							for _, qtype in next, questType do
								if qtype == CONSTANTS.QUEST_TYPES.HERBALISM then
									BWQ.totalHerbalism = BWQ.totalHerbalism + 1 end
								if qtype == CONSTANTS.QUEST_TYPES.MINING then
									BWQ.totalMining = BWQ.totalMining + 1 end
								if qtype == CONSTANTS.QUEST_TYPES.FISHING then
									BWQ.totalFishing = BWQ.totalFishing + 1 end
								if qtype == CONSTANTS.QUEST_TYPES.SKINNING then
									BWQ.totalSkinning = BWQ.totalSkinning + 1 end
							end
						end
					end
				end
			end
		end

		if C("sortByTimeRemaining") then
			table.sort(MAP_ZONES[expansion][mapId].questsSort, function(a, b) return MAP_ZONES[expansion][mapId].quests[a].timeLeft < MAP_ZONES[expansion][mapId].quests[b].timeLeft end)
		else -- reward type
			table.sort(MAP_ZONES[expansion][mapId].questsSort, function(a, b) return MAP_ZONES[expansion][mapId].quests[a].sort > MAP_ZONES[expansion][mapId].quests[b].sort end)
		end

		MAP_ZONES[expansion][mapId].numQuests = numQuests
	end
end


-- --- BOUNTIES --- --
BWQ.bountyCache = {}
BWQ.bountyDisplay = CreateFrame("Frame", "BWQ_BountyDisplay", BWQ)
function BWQ:UpdateBountyData()
	if expansion == CONSTANTS.EXPANSIONS.SHADOWLANDS then -- TODO: get map id for retrieving bounties
		BWQ.bountyDisplay:Hide()
		for i, item in pairs(BWQ.bountyCache) do
			item.button:Hide()
		end
		return
	end

	bounties = GetBountiesForMapID(expansion == CONSTANTS.EXPANSIONS.BFA and CONSTANTS.MAPID_KUL_TIRAS or CONSTANTS.MAPID_DALARAN_BROKEN_ISLES)
	if bounties == nil then
		BWQ.bountyDisplay:Hide()
		return
	end

	local bountyWidth = 0 -- added width of all items inside the bounty block
	for bountyIndex, bounty in ipairs(bounties) do
		local questIndex = GetLogIndexForQuestID(bounty.questID)
		local title = GetTitleForLogIndex(questIndex)
		local timeleft = GetQuestTimeLeftMinutes(bounty.questID)
		local _, _, finished, numFulfilled, numRequired = GetQuestObjectiveInfo(bounty.questID, 1, false)

		local bountyCacheItem
		if not BWQ.bountyCache[bountyIndex] then
			bountyCacheItem = {}
			bountyCacheItem.icon = BWQ.bountyDisplay:CreateTexture()
			bountyCacheItem.icon:SetSize(28, 28)

			bountyCacheItem.text = BWQ.bountyDisplay:CreateFontString("BWQ_BountyDisplayText"..bountyIndex, "OVERLAY", "SystemFont_Shadow_Med1")
			
			bountyCacheItem.button = CreateFrame("Button", nil, BWQ, "BackdropTemplate")
			bountyCacheItem.button:SetPoint("TOPLEFT", bountyCacheItem.icon)
			bountyCacheItem.button:SetPoint("BOTTOM", bountyCacheItem.icon)
			bountyCacheItem.button:SetPoint("RIGHT", bountyCacheItem.text)
			
			BWQ.bountyCache[bountyIndex] = bountyCacheItem
		else
			bountyCacheItem = BWQ.bountyCache[bountyIndex]
		end 

		if bounty.icon and title then

			bountyCacheItem.text:SetText(string.format(
											"|cff%s%s\n %s/%s      |r%s",
											numFulfilled == numRequired and "49d65e" or "fafafa",
											title,
											numFulfilled or 0,
											numRequired or 0,
											FormatTimeLeftString(timeleft)
										))
			bountyCacheItem.icon:SetTexture(bounty.icon)
			if bountyIndex == 1 then
				bountyCacheItem.icon:SetPoint("LEFT", BWQ.bountyDisplay, "LEFT", 0, 0)
			else
				bountyCacheItem.icon:SetPoint("LEFT", BWQ.bountyCache[bountyIndex-1].text, "RIGHT", 25, 2)
				bountyWidth = bountyWidth + 25
			end
			bountyCacheItem.text:SetPoint("LEFT", bountyCacheItem.icon, "RIGHT", 5, -2)

			bountyCacheItem.button:SetScript("OnEnter", function(self) BWQ:ShowBountyTooltip(self, bounty.questID) end)
			bountyCacheItem.button:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
			
			bountyWidth = bountyWidth + bountyCacheItem.text:GetStringWidth() + 33
		end
	end

	-- remove obsolete bounty entries (completed or disappeared)
	if #bounties < #BWQ.bountyCache then
		for i = #bounties + 1, #BWQ.bountyCache do
			BWQ.bountyCache[i].icon:Hide()
			BWQ.bountyCache[i].text:Hide()
			BWQ.bountyCache[i].button:Hide()
			BWQ.bountyCache[i] = nil
		end
	end

	-- show if bounties available, otherwise hide the bounty block
	if #bounties > 0 then
		BWQ.bountyDisplay:Show()
		BWQ.bountyDisplay:SetSize(bountyWidth, 30)
		BWQ.bountyDisplay:SetPoint("TOP", BWQ, "TOP", 0, offsetTop)
		offsetTop = offsetTop - 40
	else
		BWQ.bountyDisplay:Hide()
	end
end

function BWQ:ShowBountyTooltip(button, questId)
	local questIndex = GetLogIndexForQuestID(questId)
	local title = GetTitleForLogIndex(questIndex)
	if title then
		GameTooltip:SetOwner(button, "ANCHOR_BOTTOM")
		GameTooltip:SetText(title, HIGHLIGHT_FONT_COLOR:GetRGB())
		local _, questDescription = GetQuestLogQuestText(questIndex)
		GameTooltip:AddLine(questDescription, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
	
		local objectiveText, objectiveType, finished = GetQuestObjectiveInfo(questId, 1, false)
		if objectiveText and #objectiveText > 0 then
			local color = finished and GRAY_FONT_COLOR or HIGHLIGHT_FONT_COLOR;
			GameTooltip:AddLine(QUEST_DASH .. objectiveText, color.r, color.g, color.b, true);
		end

		GameTooltip_AddQuestRewardsToTooltip(GameTooltip, questId, TOOLTIP_QUEST_REWARDS_STYLE_EMISSARY_REWARD)
		GameTooltip:Show()
		GameTooltip.recalculatePadding = true
		button.UpdateTooltip = function(self) BWQ:ShowBountyTooltip(button, questId) end
	end
end


-- --- PARAGON REWARDS --- --
BWQ.factionFramePool = {
	rows = {},
	bars = {}
}
BWQ.factionDisplay = CreateFrame("Frame", nil, BWQ)
function BWQ:UpdateParagonData()
	if C("hideFactionParagonBars") then return end

	local i = 0
	local maxWidth = 0
	local rowIndex = 0
	
	local reps
	if expansion == CONSTANTS.EXPANSIONS.SHADOWLANDS then 
		reps = CONSTANTS.PARAGON_FACTIONS.shadowlands
	elseif
		expansion == CONSTANTS.EXPANSIONS.BFA then reps = isHorde and CONSTANTS.PARAGON_FACTIONS.bfahorde or CONSTANTS.PARAGON_FACTIONS.bfaalliance
	else
		reps = CONSTANTS.PARAGON_FACTIONS.legion
	end

	local row
	for _, factionId in next, reps.order do
		if IsFactionParagon(factionId) then
			
			local factionFrame

			rowIndex = math.floor(i / 6)
			if not BWQ.factionFramePool.rows[rowIndex] then
				row = CreateFrame("Frame", nil, BWQ.factionDisplay, "BackdropTemplate")
				BWQ.factionFramePool.rows[rowIndex] = row
			else row = BWQ.factionFramePool.rows[rowIndex] end
			
			if not BWQ.factionFramePool.bars[i] then
				factionFrame = {}
				factionFrame.name = row:CreateFontString("BWQ_FactionDisplayName"..i, "OVERLAY", "SystemFont_Shadow_Med1")

				factionFrame.bg = CreateFrame("Frame", "BWQ_FactionFrameBG"..i, row, "BackdropTemplate")
				factionFrame.bg:SetSize(50, 12)
				factionFrame.bg:SetPoint("LEFT", factionFrame.name, "RIGHT", 5, 0)
				
				factionFrame.bg:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", tile = false, tileSize = 0, edgeSize = 2, insets = { left = 0, right = 0, top = 0, bottom = 0 }, })
				factionFrame.bg:SetBackdropColor(0.2,0.2,0.2,0.5)

				factionFrame.bar = CreateFrame("Frame", "BWQ_FactionFrameBar"..i, factionFrame.bg, "BackdropTemplate")
				factionFrame.bar:SetPoint("TOPLEFT", factionFrame.bg, "TOPLEFT")
				factionFrame.bar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", tile = false, tileSize = 0, edgeSize = 2, insets = { left = 0, right = 0, top = 0, bottom = 0 }, })

				BWQ.factionFramePool.bars[i] = factionFrame
			else
				factionFrame = BWQ.factionFramePool.bars[i]
			end

			local index = i % 6
			if (index == 0) then
				factionFrame.name:SetPoint("TOPLEFT", row, "TOPLEFT", 8, 0)
			else
				factionFrame.name:SetPoint("LEFT", BWQ.factionFramePool.bars[i - 1].bg, "RIGHT", 18, 0)
			end

			row:SetSize(85 * (index + 1), 15)
			if (rowIndex == 0) then row:SetPoint("TOP", BWQ.factionDisplay, "TOP", 0, 0)
			else row:SetPoint("TOP", BWQ.factionFramePool.rows[rowIndex - 1], "BOTTOM", 0, -5) end
			row:Show()

			local name = GetFactionInfoByID(factionId)
			local current, threshold, rewardQuestId, hasRewardPending = GetFactionParagonInfo(factionId)
			
			local progress = 0
			if current and threshold then progress = (current % threshold) / threshold * 50 end
			if hasRewardPending then factionFrame.bar:SetBackdropColor(0, 0.8, 0.1)
			else factionFrame.bar:SetBackdropColor(0.1, 0.55, 0.1, 0.4) end
			if progress == 0 then factionFrame.bar:Hide() else factionFrame.bar:Show() end
			factionFrame.bar:SetSize(hasRewardPending and 50 or progress, 12)
			factionFrame.name:Show()
			factionFrame.bg:Show()
			factionFrame.bar:Show()
			
			factionFrame.name:SetText(string.format("|TInterface\\Icons\\%1$s:12:12|t", reps[factionId]))
			
			maxWidth = maxWidth > row:GetWidth() and maxWidth or row:GetWidth()
			i = i + 1
		end
	end

	-- hide not needed rows
	local j = rowIndex + 1
	while(BWQ.factionFramePool.rows[j]) do
		BWQ.factionFramePool.rows[j]:Hide()
		j = j + 1
	end
	-- hide not needed bars
	local barsInPool = #BWQ.factionFramePool.bars
	if barsInPool > 0 then
		local j = i
		while (j <= barsInPool) do
			BWQ.factionFramePool.bars[j].name:Hide()
			BWQ.factionFramePool.bars[j].bg:Hide()
			BWQ.factionFramePool.bars[j].bar:Hide()
			j = j + 1
		end
	end

	if (i > 0) then
		BWQ.factionDisplay:Show()
		BWQ.factionDisplay:SetSize(maxWidth, 20 * (rowIndex + 1))
		BWQ.factionDisplay:SetPoint("TOP", BWQ, "TOP", 0, offsetTop)
		offsetTop = offsetTop - 20 * (rowIndex + 1)
	else
		BWQ.factionDisplay:Hide()
	end
end
function BWQ:UpdateFactionDisplayVisible()
	if not C("hideFactionParagonBars") then
		BWQ:RegisterEvent("UPDATE_FACTION")
		BWQ.factionDisplay:Show()
	else
		BWQ:UnregisterEvent("UPDATE_FACTION")
		BWQ.factionDisplay:Hide()
	end
end


function BWQ:UpdateInfoPanel()
	BWQ:UpdateBountyData()
	BWQ:UpdateParagonData()
end


local originalMap, originalContinent, originalDungeonLevel
function BWQ:UpdateQuestData()
	questIds = BWQcache.questIds or {}
	BWQ.totalArtifactPower, BWQ.totalGold, BWQ.totalWarResources, BWQ.totalServiceMedals, BWQ.totalResources, BWQ.totalLegionfallSupplies, BWQ.totalHonor, BWQ.totalGear, BWQ.totalHerbalism, BWQ.totalMining, BWQ.totalFishing, BWQ.totalSkinning, BWQ.totalBloodOfSargeras, BWQ.totalWakeningEssences, BWQ.totalMarkOfHonor, BWQ.totalPrismaticManapearl = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

	for mapId in next, MAP_ZONES[expansion] do
		RetrieveWorldQuests(mapId)
	end

	numQuestsTotal = 0
	hasCollapsedQuests = false
	for mapId in next, MAP_ZONES[expansion] do
		local num = MAP_ZONES[expansion][mapId].numQuests
		if num > 0 then
			if not C("collapsedZones")[mapId] then
				numQuestsTotal = numQuestsTotal + num
			else
				hasCollapsedQuests = true
			end
		end
	end

	-- save quests to saved vars to check new status after reload/relog
	if numQuestsTotal ~= 0 then
		questIds = {}
		for mapId in next, MAP_ZONES[expansion] do
			for _, questId in next, MAP_ZONES[expansion][mapId].questsSort do
				questIds[questId] = true
			end
		end
		BWQcache.questIds = questIds
	end

	if needsRefresh and updateTries < 3 then
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
	for mapId in next, MAP_ZONES[expansion] do
		if MAP_ZONES[expansion][mapId].numQuests ~= 0 then
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
	if numQuestsTotal == 0 and not hasCollapsedQuests then
		BWQ:ShowNoWorldQuestsInfo()
		BWQ:SetHeight((offsetTop * -1) + 10 + 30)
	else
		if BWQ.errorFS then BWQ.errorFS:Hide() end
		BWQ:SetHeight((offsetTop * -1) + 10 + (ROW_HEIGHT * -1) * (maxEntries + 1))
	end

	local sliderval = math.floor(BWQ.slider:GetValue())
	local rowIndex = 0
	local rowInViewIndex = 0
	for _, mapId in next, MAP_ZONES_SORT[expansion] do
		
		local collapsed = C("collapsedZones")[mapId]

		if MAP_ZONES[expansion][mapId].numQuests == 0 or rowIndex < sliderval or rowIndex > sliderval + maxEntries then

			MAP_ZONES[expansion][mapId].zoneSep.fs:Hide()
			MAP_ZONES[expansion][mapId].zoneSep.texture:Hide()
		else

			MAP_ZONES[expansion][mapId].zoneSep.fs:Show()
			MAP_ZONES[expansion][mapId].zoneSep.fs:SetPoint("TOP", BWQ, "TOP", 15 + (totalWidth / -2) + (MAP_ZONES[expansion][mapId].zoneSep.fs:GetStringWidth() / 2), offsetTop + ROW_HEIGHT * rowInViewIndex - 2)
			MAP_ZONES[expansion][mapId].zoneSep.texture:Show()
			MAP_ZONES[expansion][mapId].zoneSep.texture:SetPoint("TOP", BWQ, "TOP", 5, offsetTop + ROW_HEIGHT * rowInViewIndex - 3)

			MAP_ZONES[expansion][mapId].zoneSep.collapse:Show()
			MAP_ZONES[expansion][mapId].zoneSep.collapse:SetAllPoints(MAP_ZONES[expansion][mapId].zoneSep.fs)
			local color = not collapsed and {0.9, 0.8, 0} or {0.3, 0.3, 0.3}
			MAP_ZONES[expansion][mapId].zoneSep.fs:SetTextColor(unpack(color))
			
			rowInViewIndex = rowInViewIndex + 1
		end

		if MAP_ZONES[expansion][mapId].numQuests ~= 0 then
			rowIndex = rowIndex + 1 -- count up from row with zone name
		end

		highlightedRow = true
		local buttonIndex = 1
		for _, button in ipairs(MAP_ZONES[expansion][mapId].buttons) do
			if not button.quest.hide and not collapsed and buttonIndex <= MAP_ZONES[expansion][mapId].numQuests then
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

function BWQ:SwitchExpansion(expac)
	expansion = expac
	if not C("usePerCharacterSettings") then
		BWQcfg["expansion"] = expac
	else
		BWQcfgPerCharacter["expansion"] = expac
	end

	BWQ.buttonShadowlands:SetAlpha(expac == CONSTANTS.EXPANSIONS.SHADOWLANDS and 1 or 0.4)
	BWQ.buttonBFA:SetAlpha(expac == CONSTANTS.EXPANSIONS.BFA and 1 or 0.4)
	BWQ.buttonLegion:SetAlpha(expac == CONSTANTS.EXPANSIONS.LEGION and 1 or 0.4)

	BWQ:HideRowsOfInactiveExpansions()
	hasUnlockedWorldQuests = false
	updateTries = 0
	BWQ:UpdateBlock()
end 

function BWQ:HideRowsOfInactiveExpansions()
	for k, expac in next, MAP_ZONES do
		if k ~= expansion then
			for mapId, v in next, expac do
				if v.zoneSep then
					v.zoneSep.fs:Hide()
					v.zoneSep.texture:Hide()
					v.zoneSep.collapse:Hide()
				end
				for _, button in next, v.buttons do
					button:Hide()
				end
			end
		end
	end
	BWQ.slider:Hide()
	BWQ:UpdateBountyData()
end

function BWQ:RunUpdate()
	local currentTime = GetTime()
	if currentTime - lastUpdate > 5 then
		updateTries = 0
		BWQ:UpdateBlock()
		lastUpdate = currentTime
	end
end

function BWQ:UpdateBlock()
	offsetTop = -35 -- initial padding from top
	BWQ:UpdateInfoPanel()
	
	if not BWQ:WorldQuestsUnlocked() then
		BWQ:SetHeight(offsetTop * -1 + 20 + 30) -- padding + errorFS height
		BWQ:SetWidth(math.max(BWQ.factionDisplay:GetWidth(), BWQ.errorFS:GetWidth()) + 20)
		return
	end
	BWQ:UpdateQuestData()

	-- refreshing is limited to 3 runs and then gets forced to render the block
	if needsRefresh and updateTries < 3 then
		-- skip updating the block, received data was incomplete
		needsRefresh = false
		return
	end

	local titleMaxWidth, bountyMaxWidth, factionMaxWidth, rewardMaxWidth, timeLeftMaxWidth = 0, 0, 0, 0, 0
	for mapId in next, MAP_ZONES[expansion] do
		local buttonIndex = 1

		if not MAP_ZONES[expansion][mapId].zoneSep then
			local zoneSep = {
				fs = BWQ:CreateFontString("BWQzoneNameFS", "OVERLAY", "SystemFont_Shadow_Med1"),
				texture = BWQ:CreateTexture(),
				collapse = CreateFrame("Button", nil, BWQ, "BackdropTemplate")
			}
			local faction = MAP_ZONES[expansion][mapId].faction
			local zoneText = MAP_ZONES[expansion][mapId].name
			if faction then
				local factionIcon = faction == CONSTANTS.FACTIONS.HORDE and "Interface\\Icons\\inv_misc_tournaments_banner_orc" or "Interface\\Icons\\inv_misc_tournaments_banner_human"
				zoneText = ("%2$s   |T%1$s:12:12|t"):format(factionIcon, zoneText)
			end
			zoneSep.fs:SetJustifyH("LEFT")
			zoneSep.fs:SetText(zoneText)

			zoneSep.collapse:SetFrameLevel(15)
			zoneSep.collapse:RegisterForClicks("AnyUp")
			zoneSep.collapse:SetScript("OnClick" , function(self)
				C("collapsedZones")[mapId] = not C("collapsedZones")[mapId]
				BWQ:UpdateBlock()
			end)

			zoneSep.texture:SetTexture("Interface\\FriendsFrame\\UI-FriendsFrame-OnlineDivider")
			zoneSep.texture:SetHeight(8)

			MAP_ZONES[expansion][mapId].zoneSep = zoneSep
		end

		if not C("collapsedZones")[mapId] then 

		for _, questId in next, MAP_ZONES[expansion][mapId].questsSort do

			local button
			if buttonIndex > #MAP_ZONES[expansion][mapId].buttons then

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

				MAP_ZONES[expansion][mapId].buttons[buttonIndex] = button
			else
				button = MAP_ZONES[expansion][mapId].buttons[buttonIndex]
			end

			button.mapId = mapId
			button.quest = MAP_ZONES[expansion][mapId].quests[questId]

			button.questID = button.quest.questId
			button.worldQuest = true
			button.numObjectives = button.quest.numObjectives

			-- fill and format row
			local rewardText = ""
			if button.quest.reward.itemName then
				local itemText = string.format(
					"%s[%s%s]|r",
					ITEM_QUALITY_COLORS[button.quest.reward.itemQuality].hex,
					button.quest.reward.realItemLevel and (button.quest.reward.realItemLevel .. " ") or "",
					button.quest.reward.itemName
				)

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
			if button.quest.reward.honor and button.quest.reward.honor > 0 then
				rewardText = string.format(
					"%1$s%2$s|T%3$s:14:14|t %4$d %5$s",
					rewardText,
					rewardText ~= "" and "   " or "", -- insert some space between rewards
					"Interface\\Icons\\Achievement_LegionPVPTier4",
					button.quest.reward.honor,
					HONOR
				) 
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

			if button.quest.reward.currencies then
				for _, currency in next, button.quest.reward.currencies do
					local currencyText = string.format("|T%1$s:14:14|t %s", currency.texture, currency.name)

					rewardText = string.format(
						"%s%s%s",
						rewardText,
						rewardText ~= "" and "   " or "", -- insert some space between rewards
						currencyText
					)
				end
			end

			-- if button.quest.tagId == 136 or button.quest.tagId == 111 or button.quest.tagId == 112 then
			--button.icon:SetTexCoord(.81, .84, .68, .79) -- skull tex coords
			if CONSTANTS.WORLD_QUEST_ICONS_BY_TAG_ID[button.quest.tagId] then
				button.icon:SetAtlas(CONSTANTS.WORLD_QUEST_ICONS_BY_TAG_ID[button.quest.tagId], true)
				button.icon:SetAlpha(1)
			else
				button.icon:SetAlpha(0)
			end
			button.icon:SetSize(12, 12)

			button.titleFS:SetText(string.format("%s%s%s|r",
				button.quest.isNew and "|cffe5cc80NEW|r  " or "",
				button.quest.isMissingAchievementCriteria and "|cff1EFF00" or WORLD_QUEST_QUALITY_COLORS[button.quest.quality].hex,
				button.quest.title
			))
			--local titleWidth = button.titleFS:GetStringWidth()
			--if titleWidth > titleMaxWidth then titleMaxWidth = titleWidth end

			if GetQuestWatchType(button.quest.questId) == Enum.QuestWatchType.Manual or GetSuperTrackedQuestID() == button.quest.questId then
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
	end
	end -- maps loop

	titleMaxWidth = 125
	rewardMaxWidth = rewardMaxWidth < 100 and 100 or rewardMaxWidth > 250 and 250 or rewardMaxWidth
	factionMaxWidth = C("hideFactionColumn") and 0 or factionMaxWidth < 100 and 100 or factionMaxWidth
	timeLeftMaxWidth = 65
	totalWidth = titleMaxWidth + bountyMaxWidth + factionMaxWidth + rewardMaxWidth + timeLeftMaxWidth + 80

	local bountyBoardWidth = BWQ.bountyDisplay:GetWidth()
	local factionDisplayWidth = BWQ.factionDisplay:GetWidth()
	local infoPanelWidth = bountyBoardWidth > factionDisplayWidth and bountyBoardWidth or factionDisplayWidth
	if totalWidth < infoPanelWidth then
		local diff = infoPanelWidth - totalWidth
		totalWidth = infoPanelWidth
		rewardMaxWidth = rewardMaxWidth + diff
	end

	for mapId in next, MAP_ZONES[expansion] do
		for i = 1, #MAP_ZONES[expansion][mapId].buttons do
			if not MAP_ZONES[expansion][mapId].buttons[i].quest.hide then -- dont care about the hidden ones
				MAP_ZONES[expansion][mapId].buttons[i]:SetHeight(15)
				MAP_ZONES[expansion][mapId].buttons[i]:SetWidth(totalWidth)
				MAP_ZONES[expansion][mapId].buttons[i].title:SetWidth(titleMaxWidth)
				MAP_ZONES[expansion][mapId].buttons[i].titleFS:SetWidth(titleMaxWidth)
				MAP_ZONES[expansion][mapId].buttons[i].bountyFS:SetWidth(bountyMaxWidth)
				MAP_ZONES[expansion][mapId].buttons[i].factionFS:SetWidth(factionMaxWidth)
				MAP_ZONES[expansion][mapId].buttons[i].reward:SetWidth(rewardMaxWidth)
				MAP_ZONES[expansion][mapId].buttons[i].rewardFS:SetWidth(rewardMaxWidth)
				MAP_ZONES[expansion][mapId].buttons[i].timeLeftFS:SetWidth(timeLeftMaxWidth)
			else
				MAP_ZONES[expansion][mapId].buttons[i]:Hide()
			end
		end
		MAP_ZONES[expansion][mapId].zoneSep.texture:SetWidth(totalWidth + 20)
	end

	totalWidth = totalWidth + 20
	BWQ:SetWidth(totalWidth)

	if C("showTotalsInBrokerText") then
		local brokerString = ""
		if C("brokerShowAP")                  and BWQ.totalArtifactPower > 0      then brokerString = string.format("%s|TInterface\\Icons\\inv_smallazeriteshard:16:16|t %s  ", brokerString, AbbreviateNumber(BWQ.totalArtifactPower)) end
		if C("brokerShowServiceMedals")       and BWQ.totalServiceMedals > 0      then brokerString = string.format("%s|T%s:16:16|t %s  ", brokerString, isHorde and "Interface\\Icons\\ui_horde_honorboundmedal" or "Interface\\Icons\\ui_alliance_7legionmedal", BWQ.totalServiceMedals) end
		if C("brokerShowWakeningEssences")    and BWQ.totalWakeningEssences > 0   then brokerString = string.format("%s|TInterface\\Icons\\achievement_dungeon_ulduar80_25man:16:16|t %s  ", brokerString, BWQ.totalWakeningEssences) end
		if C("brokerShowWarResources")        and BWQ.totalWarResources > 0       then brokerString = string.format("%s|TInterface\\Icons\\inv__faction_warresources:16:16|t %d  ", brokerString, BWQ.totalWarResources) end
		if C("brokerShowPrismaticManapearl")  and BWQ.totalPrismaticManapearl > 0 then brokerString = string.format("%s|TInterface\\Icons\\Inv_misc_enchantedpearlf:16:16|t %d  ", brokerString, BWQ.totalPrismaticManapearl) end
		if C("brokerShowResources")           and BWQ.totalResources > 0          then brokerString = string.format("%s|TInterface\\Icons\\inv_orderhall_orderresources:16:16|t %d  ", brokerString, BWQ.totalResources) end
		if C("brokerShowLegionfallSupplies")  and BWQ.totalLegionfallSupplies > 0 then brokerString = string.format("%s|TInterface\\Icons\\inv_misc_summonable_boss_token:16:16|t %d  ", brokerString, BWQ.totalLegionfallSupplies) end
		if C("brokerShowHonor")               and BWQ.totalHonor > 0              then brokerString = string.format("%s|TInterface\\Icons\\Achievement_LegionPVPTier4:16:16|t %d  ", brokerString, BWQ.totalHonor) end
		if C("brokerShowGold")                and BWQ.totalGold > 0               then brokerString = string.format("%s|TInterface\\GossipFrame\\auctioneerGossipIcon:16:16|t %d  ", brokerString, math.floor(BWQ.totalGold / 10000)) end
		if C("brokerShowGear")                and BWQ.totalGear > 0               then brokerString = string.format("%s|TInterface\\Icons\\Inv_chest_plate_legionendgame_c_01:16:16|t %d  ", brokerString, BWQ.totalGear) end
		if C("brokerShowMarkOfHonor")         and BWQ.totalMarkOfHonor > 0        then brokerString = string.format("%s|TInterface\\Icons\\ability_pvp_gladiatormedallion:16:16|t %d  ", brokerString, BWQ.totalMarkOfHonor) end
		if C("brokerShowHerbalism")           and BWQ.totalHerbalism > 0          then brokerString = string.format("%s|TInterface\\Icons\\Trade_Herbalism:16:16|t %d  ", brokerString, BWQ.totalHerbalism) end
		if C("brokerShowMining")              and BWQ.totalMining > 0             then brokerString = string.format("%s|TInterface\\Icons\\Trade_Mining:16:16|t %d  ", brokerString, BWQ.totalMining) end
		if C("brokerShowFishing")             and BWQ.totalFishing > 0            then brokerString = string.format("%s|TInterface\\Icons\\Trade_Fishing:16:16|t %d  ", brokerString, BWQ.totalFishing) end
		if C("brokerShowSkinning")            and BWQ.totalSkinning > 0           then brokerString = string.format("%s|TInterface\\Icons\\inv_misc_pelt_wolf_01:16:16|t %d  ", brokerString, BWQ.totalSkinning) end
		if C("brokerShowBloodOfSargeras")     and BWQ.totalBloodOfSargeras > 0    then brokerString = string.format("%s|T1417744:16:16|t %d", brokerString, BWQ.totalBloodOfSargeras) end

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
	local options = {
		{ text = "Attach list frame to world map", check = "attachToWorldMap" },
		{ text = "Show list frame on click instead of mouse-over", check = "showOnClick" },
		{ text = "Use per-character settings", check = "usePerCharacterSettings" },
		{ text = "" },
		{ text = "Always show |cffa335eeepic|r world quests (e.g. world bosses)", check = "alwaysShowEpicQuests" },
		{ text = "Only show world quests with |cff0070ddrare|r or above quality", check = "onlyShowRareOrAbove" },
		{ text = "Don't filter quests for active bounties", check = "alwaysShowBountyQuests" },
		{ text = "Show total counts in broker text", check = "showTotalsInBrokerText", submenu = {
				{ text = ("|T%1$s:16:16|t  Artifact Power"):format("Interface\\Icons\\inv_smallazeriteshard"), check = "brokerShowAP" },
				{ text = ("|T%1$s:16:16|t  Service Medals"):format(isHorde and "Interface\\Icons\\ui_horde_honorboundmedal" or "Interface\\Icons\\ui_alliance_7legionmedal"), check = "brokerShowServiceMedals" },
				{ text = ("|T%1$s:16:16|t  Wakening Essences"):format("Interface\\Icons\\achievement_dungeon_ulduar80_25man"), check = "brokerShowWakeningEssences" },
				{ text = ("|T%1$s:16:16|t  Prismatic Manapearls"):format("Interface\\Icons\\Inv_misc_enchantedpearlf"), check = "brokerShowPrismaticManapearl" },
				{ text = ("|T%1$s:16:16|t  War Resources"):format("Interface\\Icons\\inv__faction_warresources"), check = "brokerShowWarResources" },
				{ text = ("|T%1$s:16:16|t  Order Hall Resources"):format("Interface\\Icons\\inv_orderhall_orderresources"), check = "brokerShowResources" },
				{ text = ("|T%1$s:16:16|t  Legionfall War Supplies"):format("Interface\\Icons\\inv_misc_summonable_boss_token"), check = "brokerShowLegionfallSupplies" },
				{ text = ("|T%1$s:16:16|t  Honor"):format("Interface\\Icons\\Achievement_LegionPVPTier4"), check = "brokerShowHonor" },
				{ text = ("|T%1$s:16:16|t  Gold"):format("Interface\\GossipFrame\\auctioneerGossipIcon"), check = "brokerShowGold" },
				{ text = ("|T%1$s:16:16|t  Gear"):format("Interface\\Icons\\Inv_chest_plate_legionendgame_c_01"), check = "brokerShowGear" },
				{ text = ("|T%1$s:16:16|t  Mark Of Honor"):format("Interface\\Icons\\ability_pvp_gladiatormedallion"), check = "brokerShowMarkOfHonor" },
				{ text = ("|T%1$s:16:16|t  Herbalism Quests"):format("Interface\\Icons\\Trade_Herbalism"), check = "brokerShowHerbalism" },
				{ text = ("|T%1$s:16:16|t  Mining Quests"):format("Interface\\Icons\\Trade_Mining"), check = "brokerShowMining" },
				{ text = ("|T%1$s:16:16|t  Fishing Quests"):format("Interface\\Icons\\Trade_Fishing"), check = "brokerShowFishing" },
				{ text = ("|T%1$s:16:16|t  Skinning Quests"):format("Interface\\Icons\\inv_misc_pelt_wolf_01"), check = "brokerShowSkinning" },
				{ text = ("|T%s$s:16:16|t  Blood of Sargeras"):format("1417744"), check = "brokerShowBloodOfSargeras" },
			}
		},
		{ text = "Sort list by time remaining instead of reward type", check = "sortByTimeRemaining" },
		{ text = "" },
		{ text = "Filter by reward...", isTitle = true },
		{ text = ("|T%1$s:16:16|t  Azerite"):format("Interface\\Icons\\inv_smallazeriteshard"), check = "showArtifactPower" },
		{ text = ("|T%1$s:16:16|t  Prismatic Manapearl"):format("Interface\\Icons\\Inv_misc_enchantedpearlf"), check = "showPrismaticManapearl" },
		{ text = ("|T%1$s:16:16|t  Items"):format("Interface\\Minimap\\Tracking\\Banker"), check = "showItems", submenu = {
				{ text = ("|T%1$s:16:16|t  Gear"):format("Interface\\Icons\\Inv_chest_plate_legionendgame_c_01"), check = "showGear" },
				{ text = ("|T%s$s:16:16|t  Crafting Materials"):format("1417744"), check = "showCraftingMaterials" },
				{ text = ("|T%1$s:16:16|t  Mark Of Honor"):format("Interface\\Icons\\ability_pvp_gladiatormedallion"), check = "showMarkOfHonor" },
				{ text = "Other", check = "showOtherItems" },
			}
		},
		{ text = ("|T%1$s:16:16|t  Reputation Tokens"):format("Interface\\Icons\\inv_scroll_11"), check = "showBFAReputation" },
		{ text = ("|T%1$s:16:16|t  Service Medals"):format(isHorde and "Interface\\Icons\\ui_horde_honorboundmedal" or "Interface\\Icons\\ui_alliance_7legionmedal"), check = "showBFAServiceMedals" },
		{ text = ("|T%1$s:16:16|t  Honor"):format("Interface\\Icons\\Achievement_LegionPVPTier4"), check = "showHonor" },
		{ text = ("|T%1$s:16:16|t  Low gold reward"):format("Interface\\GossipFrame\\auctioneerGossipIcon"), check = "showLowGold" },
		{ text = ("|T%1$s:16:16|t  High gold reward"):format("Interface\\GossipFrame\\auctioneerGossipIcon"), check = "showHighGold" },
		{ text = ("|T%1$s:16:16|t  War Resources"):format("Interface\\Icons\\inv__faction_warresources"), check = "showWarResources" },
		{ text = "       Legion", submenu = {
				{ text = ("|T%1$s:16:16|t  Order Hall Resources"):format("Interface\\Icons\\inv_orderhall_orderresources"), check = "showResources" },
				{ text = ("|T%1$s:16:16|t  Legionfall War Supplies"):format("Interface\\Icons\\inv_misc_summonable_boss_token"), check = "showLegionfallSupplies" },
				{ text = ("|T%1$s:16:16|t  Nethershard"):format("Interface\\Icons\\inv_datacrystal01"), check = "showNethershards" },
				{ text = ("|T%1$s:16:16|t  Veiled Argunite"):format("Interface\\Icons\\oshugun_crystalfragments"), check = "showArgunite" },
				{ text = ("|T%1$s:16:16|t  Wakening Essences"):format("Interface\\Icons\\achievement_dungeon_ulduar80_25man"), check = "showWakeningEssences" },
			}
		},
		{ text = "" },
		{ text = "Filter by type...", isTitle = true },
		{ text = "Profession Quests", check = "showProfession", submenu = {
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
				{ text = "Fishing", check="showProfessionFishing" },
			}
		},
		{ text = "Dungeon Quests", check = "showDungeon" },
		{ text = "PvP Quests", check = "showPvP" },
		{ text = "Pet Battle Quests", check = "showPetBattle", submenu = {
				{ text = "Hide Pet Battle Quests even when active bounty", check = "hidePetBattleBountyQuests" },
				{ text = "Always show quests for \"Family Familiar\" achievement", check = "alwaysShowPetBattleFamilyFamiliar" },
			}
		},
		{ text = "" },
		{ text = "Hide faction column", check="hideFactionColumn" },
		{ text = "Hide faction paragon bars", check="hideFactionParagonBars" },
		{ text = "Always show quests for faction...", isTitle = true },		
		{ text = "       Shadowlands", submenu = {
				{ text = "The Avowed", check="alwaysShowAvowed" },
				{ text = "The Wild Hunt", check="alwaysShowWildHunt" },
				{ text = "Court of Harvesters", check="alwaysShowCourtofHarvesters" },
				{ text = "The Undying Army", check="alwaysShowUndyingArmy" },
				{ text = "The Ascended", check="alwaysShowAscended" },
			}
		},
		{ text = "       Battle for Azeroth", submenu = {
				{ text = "Rustbolt Resistance", check="alwaysShowRustboltResistance" },
				{ text = "Tortollan Seekers", check="alwaysShowTortollanSeekers" },
				{ text = "Champions of Azeroth", check="alwaysShowChampionsOfAzeroth" },
				{ text = ("|T%1$s:16:16|t  7th Legion"):format("Interface\\Icons\\inv_misc_tournaments_banner_human"), check="alwaysShow7thLegion" },
				{ text = ("|T%1$s:16:16|t  Storm's Wake"):format("Interface\\Icons\\inv_misc_tournaments_banner_human"), check="alwaysShowStormsWake" },
				{ text = ("|T%1$s:16:16|t  Order of Embers"):format("Interface\\Icons\\inv_misc_tournaments_banner_human"), check="alwaysShowOrderOfEmbers" },
				{ text = ("|T%1$s:16:16|t  Proudmoore Admiralty"):format("Interface\\Icons\\inv_misc_tournaments_banner_human"), check="alwaysShowProudmooreAdmiralty" },
				{ text = ("|T%1$s:16:16|t  Waveblade Ankoan"):format("Interface\\Icons\\inv_misc_tournaments_banner_human"), check="alwaysShowWavebladeAnkoan" },
				{ text = ("|T%1$s:16:16|t  The Honorbound"):format("Interface\\Icons\\inv_misc_tournaments_banner_orc"), check="alwaysShowTheHonorbound" },
				{ text = ("|T%1$s:16:16|t  Zandalari Empire"):format("Interface\\Icons\\inv_misc_tournaments_banner_orc"), check="alwaysShowZandalariEmpire" },
				{ text = ("|T%1$s:16:16|t  Talanji's Expedition"):format("Interface\\Icons\\inv_misc_tournaments_banner_orc"), check="alwaysShowTalanjisExpedition" },
				{ text = ("|T%1$s:16:16|t  Voldunai"):format("Interface\\Icons\\inv_misc_tournaments_banner_orc"), check="alwaysShowVoldunai" },
				{ text = ("|T%1$s:16:16|t  The Unshackled"):format("Interface\\Icons\\inv_misc_tournaments_banner_orc"), check="alwaysShowTheUnshackled" },
			}
		},
		{ text = "       Legion", submenu = {
				{ text = "Court of Farondis", check="alwaysShowCourtOfFarondis" },
				{ text = "Dreamweavers", check="alwaysShowDreamweavers" },
				{ text = "Highmountain Tribe", check="alwaysShowHighmountainTribe" },
				{ text = "The Nightfallen", check="alwaysShowNightfallen" },
				{ text = "The Wardens", check="alwaysShowWardens" },
				{ text = "Valarjar", check="alwaysShowValarjar" },
				{ text = "Armies of Legionfall", check="alwaysShowArmiesOfLegionfall" },
				{ text = "Army of the Light", check="alwaysShowArmyOfTheLight" },
				{ text = "Argussian Reach", check="alwaysShowArgussianReach" },
			}
		},
	}
	if TomTom then
		table.insert(options, { text = "" })
		table.insert(options, { text = "Add TomTom waypoint on row click", check = "enableTomTomWaypointsOnClick" })
	end
	
	configMenu = CreateFrame("Frame", "BWQ_ConfigMenu")
	configMenu.displayMode = "MENU"

	local SetOption = function(bt, var, val)
		if var == "usePerCharacterSettings" or not BWQcfg.usePerCharacterSettings then
			BWQcfg[var] = val or not BWQcfg[var]
		else
			BWQcfgPerCharacter[var] = val or not BWQcfgPerCharacter[var]
		end

		-- refresh radio buttons
		if val then
			local sub = bt:GetName():sub(1, 19).."%i"
			for i = 1, bt:GetParent().numButtons do
				local subi = sub:format(i)
				if _G[subi] == bt then
					_G[subi.."Check"]:Show()
				else
					_G[subi.."Check"]:Hide()
					_G[subi.."UnCheck"]:Show()
				end
			end
		end

		if var == "expansion" then
			expansion = C("expansion")
			BWQ:HideRowsOfInactiveExpansions()
			hasUnlockedWorldQuests = false
		end

		if var == "hideFactionParagonBars" then
			BWQ:UpdateFactionDisplayVisible()
		end

		BWQ:UpdateBlock()

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
				if (v.check == "usePerCharacterSettings") then info.checked = BWQcfg[v.check]
				elseif v.radio then info.checked = C(v.check) == v.val
				else info.checked = C(v.check)
				end
				info.func, info.arg1 = SetOption, v.check 
				if v.radio then info.arg2 = v.val end
				info.isNotRadio = not v.radio
				info.keepShownOnClick = true
			elseif v.submenu then
				info.notCheckable = true
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
	end
	configMenu.anchor = anchor
	ToggleDropDownMenu(1, nil, configMenu, configMenu.anchor, 0, 0)
end

local SetFlightMapPins = function(self)
	for pin, active in self:GetMap():EnumeratePinsByTemplate("WorldQuestPinTemplate") do
		if C_SuperTrack.GetSuperTrackedQuestID() == pin.questID then
			pin:SetAlphaLimits(nil, 0.0, 1.0)
			pin:SetAlpha(1)
			pin:Show()
		else
			pin:SetAlphaLimits(1.0, 0.0, 1.0)
			if FlightMapFrame.ScrollContainer:IsZoomedOut() then pin:Hide() end
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
		--[[
		Opening quest details in the side bar of the world map fires QUEST_LOG_UPDATE event.
		To avoid setting the currently shown map again, which would hide the quest details,
		skip updating after a WORLD_MAP_UPDATE event happened
		--]]
		if not skipNextUpdate then
			BWQ:RunUpdate()
		end
		skipNextUpdate = false
	elseif event == "QUEST_WATCH_LIST_CHANGED" then
		BWQ:UpdateBlock()
	elseif event == "UPDATE_FACTION" then
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
		end)
		hooksecurefunc(WorldMapFrame, "Show", function(self)
			if C("attachToWorldMap") then
				BWQ:AttachToWorldMap()
				BWQ:RunUpdate()
			end
		end)
		hooksecurefunc(WorldMapFrame, "OnMapChanged", function(self)
			skipNextUpdate = true
			local mapId = WorldMapFrame:GetMapID()
			if BWQ.currentMapId and BWQ.currentMapId ~= mapId then
				BWQ.mapTextures.animationGroup:Stop()
			end
			BWQ.currentMapId = mapId
		end)

		BWQ:UnregisterEvent("PLAYER_ENTERING_WORLD")

		BWQ:RegisterEvent("QUEST_LOG_UPDATE")
		BWQ:RegisterEvent("QUEST_WATCH_LIST_CHANGED")
		if (not C("hideFactionParagonBars")) then
			BWQ:RegisterEvent("UPDATE_FACTION")
		end
		if TomTom then
			BWQ:RegisterEvent("PLAYER_LOGOUT")
			BWQ:RegisterEvent("QUEST_ACCEPTED")
		end
	elseif event == "ADDON_LOADED" then
		if arg1 == "Broker_WorldQuests" then
			BWQcfg = BWQcfg or defaultConfig
			BWQcfgPerCharacter = BWQcfgPerCharacter and BWQcfgPerCharacter or BWQcfg and BWQcfg or defaultConfig
			for i, v in next, defaultConfig do
				if BWQcfg[i] == nil then BWQcfg[i] = v end
				if BWQcfgPerCharacter[i] == nil then BWQcfgPerCharacter[i] = v end
			end
			BWQcache = BWQcache or {}
			BWQ:SwitchExpansion(C("expansion"))

			if IsAddOnLoaded('Blizzard_SharedMapDataProviders') then
				BWQ:AddFlightMapHook()
				BWQ:UnregisterEvent("ADDON_LOADED")
			end
		elseif arg1 == "Blizzard_SharedMapDataProviders" then
			BWQ:AddFlightMapHook()
			BWQ:UnregisterEvent("ADDON_LOADED")
		end
	elseif event == "QUEST_ACCEPTED" then
		if TomTom and currentTomTomWaypoint and (GetTitleForLogIndex(arg1) == currentTomTomWaypoint.title) then TomTom:RemoveWaypoint(currentTomTomWaypoint) end
	elseif event == "PLAYER_LOGOUT" then
		if TomTom and currentTomTomWaypoint then TomTom:RemoveWaypoint(currentTomTomWaypoint) end
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
