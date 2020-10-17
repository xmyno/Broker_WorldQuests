local _, addon = ...
local CONSTANTS = {}


CONSTANTS.EXPANSIONS = {
	LEGION = "LEGION",
	BFA = "BFA",
	SHADOWLANDS = "SHADOWLANDS",
}
CONSTANTS.FACTIONS = {
	NEUTRAL = 0,
	ALLIANCE = 1,
	HORDE = 2,
}

CONSTANTS.MAPID_KUL_TIRAS = 876
CONSTANTS.MAPID_DALARAN_BROKEN_ISLES = 627

CONSTANTS.SORT_ORDER = {
	ARTIFACTPOWER = 8,
	RESOURCES = 7,
	HONOR = 6,
	RELIC = 5,
	EQUIP = 4,
	ITEM = 3,
	PROFESSION = 2,
	MONEY = 1,
}

CONSTANTS.WORLD_QUEST_TYPES = {
	PROFESSION = 1,
	PVE = 2,
	PVP = 3,
	PETBATTLE = 4,
	-- ?? = 5,
	DUNGEON = 6,
	INVASION = 7,
	RAID = 8,
}

CONSTANTS.REWARD_TYPES = {
	ARTIFACTPOWER = 0,
	RESOURCES = 1,
	MONEY = 2,
	GEAR = 3, 
	BLOODOFSARGERAS = 4, 
	LEGIONFALL_SUPPLIES = 5,
	HONOR = 6, 
	NETHERSHARD = 7, 
	ARGUNITE = 8, 
	WAKENING_ESSENCES = 9,
	WAR_RESOURCES = 10,
	MARK_OF_HONOR = 11,
	SERVICE_MEDALS = 12,
	PRISMATIC_MANAPEARL = 13,
}

CONSTANTS.QUEST_TYPES = {
	HERBALISM = 0,
	MINING = 1,
	FISHING = 2,
	SKINNING = 3,
}

local isHorde = UnitFactionGroup("player") == "Horde"
CONSTANTS.WORLD_QUEST_ICONS_BY_TAG_ID = {
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
	[139] = "worldquest-icon-burninglegion",
	[142] = "worldquest-icon-burninglegion",
	[259] = isHorde and "worldquest-icon-horde" or "worldquest-icon-alliance",
	[260] = isHorde and "worldquest-icon-horde" or "worldquest-icon-alliance",
}


CONSTANTS.CURRENCIES_AFFECTED_BY_WARMODE = {
	[1226] = true, -- nethershard
	[1508] = true, -- argunite
	[1533] = true, -- wakening essence
	[1342] = true, -- legionfall supplies
	[1220] = true, -- order hall (legion)
	[1560] = true, -- war resources (bfa)
	[1553] = true, -- azerite
}

CONSTANTS.SHADOWLANDS_REPUTATION_CURRENCY_IDS = {
	[1804] = true, -- The Ascended
	[1805] = true, -- Undying Army
	[1806] = true, -- Wild Hunt
	[1807] = true, -- Court of Harvesters
	[1877] = true, -- XP
}

CONSTANTS.BFA_REPUTATION_CURRENCY_IDS = {
	[1579] = true, -- both
	[1598] = true,
	[1600] = true, -- alliance
	[1595] = true,
	[1597] = true,
	[1596] = true,
	[1599] = true, -- horde
	[1593] = true,
	[1594] = true,
	[1592] = true,
}

CONSTANTS.FAMILY_FAMILIAR_QUEST_IDS = { -- WQ pet battle achievement
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

-- achievement id, quest id and criteria index combinations for world quest achievements
CONSTANTS.ACHIEVEMENT_CRITERIAS = {
	-- Fishing 'Round The Isles
	[41270] = 1, [41612] = 1, [41613] = 1,
	[41267] = 2,
	[41279] = 3, [41605] = 3, [41604] = 3,
	[41264] = 4, [41598] = 4, [41599] = 4,
	[41268] = 5,
	[41252] = 6,
	[41265] = 7, [41610] = 7, [41611] = 7,
	[41280] = 8, [41616] = 8, [41617] = 8,
	[41244] = 9, [41596] = 9, [41597] = 9,
	[41603] = 10, [41274] = 10, [41602] = 10,
	[41243] = 11, [41609] = 11,
	[41273] = 12,
	[41266] = 13,
	[41275] = 14, [41614] = 14, [41615] = 14,
	[41278] = 15,
	[41271] = 16,
	[41277] = 17,
	[41240] = 18,
	[41600] = 19, [41601] = 19, [41269] = 19,
	[41253] = 20,
	[41276] = 21,
	[41272] = 22,
	[41282] = 23,
	[41283] = 24,
	-- Battle on the Broken Isles
	[42063] = 1,
	[42165] = 2,
	[42146] = 3,
	[42159] = 4,
	[42148] = 5,
	[42154] = 6,
	[42442] = 7,
	[40299] = 8,
	[41881] = 9,
	[40298] = 10,
	[41886] = 11,
	[42062] = 12,
	[40277] = 13,
	[40280] = 14,
	[40282] = 15,
	[41766] = 16,
	[42064] = 17,
	[41687] = 18,
	[41624] = 19,
	[42067] = 20,
	[41944] = 21,
	[41958] = 22,
	[40278] = 23,
	[41948] = 24,
	[41935] = 25,
	[41895] = 26,
	[41914] = 27,
	[41990] = 28,
	[40337] = 29,
	[42015] = 30,
	[41931] = 31,
	[40279] = 32,
	[41862] = 33,
	[41861] = 34,
	[41855] = 35,
	[42190] = 36,
	[41860] = 37,
	-- Battle on Zandalar and Kul Tiras
	[52009] = 1,
	[52126] = 2,
	[52165] = 3,
	[52218] = 4,
	[52278] = 5,
	[52297] = 6,
	[52316] = 7,
	[52325] = 8,
	[52430] = 9,
	[52455] = 10,
	[52471] = 11,
	[52751] = 12,
	[52754] = 13,
	[52779] = 14,
	[52799] = 15,
	[52803] = 16,
	[52850] = 17,
	[52856] = 18,
	[52864] = 19,
	[52878] = 20,
	[52892] = 21,
	[52923] = 22,
	[52937] = 23,
	[52938] = 24,
}

-- faction ids and icon name for factions with paragon reputation
CONSTANTS.PARAGON_FACTIONS = {
	legion = {
		order = { 1883, 1948, 1900, 1828, 1894, 1859, 2045, 2165, 2170 },
		[1883] = "inv_legion_faction_dreamweavers", -- valsharah
		[1948] = "inv_legion_faction_valarjar", -- stormheim
		[1900] = "inv_legion_faction_courtoffarnodis", -- aszuna
		[1828] = "inv_legion_faction_hightmountaintribes", -- highmountain
		[1894] = "inv_legion_faction_warden", -- wardens
		[1859] = "inv_legion_faction_nightfallen", -- suramar
		[2045] = "achievement_faction_legionfall", -- broken isles
		[2165] = "achievement_admiral_of_the_light", -- army of light
		[2170] = "achievement_master_of_argussian_reach", -- argussian reach
	},
	bfahorde = {
		order = { 2103, 2156, 2158, 2157, 2163, 2164, 2373, 2391 },
		[2103] = "inv__faction_zandalariempire", -- zandalari
		[2156] = "inv__faction_talanjisexpedition", -- talanji
		[2157] = "inv__faction_hordewareffort", -- honorbound
		[2158] = "inv__faction_voldunai", -- voldunai
		[2163] = "inv__faction_tortollanseekers", -- tortollan
		[2164] = "inv__faction_championsofazeroth", -- coa
		[2373] = "inv__faction_unshackled", -- unshackled
		[2391] = "inv__faction_rustboltresistance", -- rustbolt resistance
	},
	bfaalliance = {
		order = { 2160, 2161, 2162, 2159, 2163, 2164, 2400, 2391 },
		[2159] = "inv__faction_alliancewareffort", -- 7th legion
		[2161] = "inv__faction_orderofembers", -- order of embers
		[2160] = "inv__faction_proudmooreadmiralty", -- proudmoore admiralty
		[2162] = "inv__faction_stormswake", -- storms wake
		[2163] = "inv__faction_tortollanseekers", -- tortollan
		[2164] = "inv__faction_championsofazeroth", -- coa
		[2400] = "inv_faction_akoan", -- waveblade ankoan
		[2391] = "inv_faction_rustbolt", -- rustbolt resistance
	},
	shadowlands = {
		order = { 2407, 2410, 2413, 2465 },
		[2407] = "ui_sigil_kyrian", -- ascended
		[2410] = "inv_shoulder_mail_maldraxxus_d_01", -- undying army
		[2413] = "inv_cape_special_revendreth_d_01", -- court of harvesters
		-- [2439] = "", -- avowed
		[2465] = "inv_wand_1h_ardenweald_d_01", -- wild hunt
	},
}

addon.CONSTANTS = CONSTANTS
