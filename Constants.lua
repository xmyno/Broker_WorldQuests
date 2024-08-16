local _, addon = ...
local CONSTANTS = {}

CONSTANTS.EXPANSIONS = {
	LEGION = "LEGION",
	BFA = "BFA",
	SHADOWLANDS = "SHADOWLANDS",
	DRAGONFLIGHT = "DRAGONFLIGHT",
	THEWARWITHIN = "THEWARWITHIN"
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

-- The name here should match the currency name in game (verified via Wowhead).  Some currencies are singular, some are plural.
CONSTANTS.REWARD_TYPES = {
	IRRELEVANT = -1,
	ARTIFACTPOWER = 0,
	RESOURCES = 1,
	MONEY = 2,
	GEAR = 3, 
	BLOODOFSARGERAS = 4, 
	LEGIONFALL_SUPPLIES = 5,
	HONOR = 6, 
	NETHERSHARD = 7, 
	ARGUNITE = 8, 
	WAKENING_ESSENCE = 9,
	WAR_RESOURCES = 10,
	MARK_OF_HONOR = 11,
	SERVICE_MEDAL = 12,
	PRISMATIC_MANAPEARL = 13,
	SOULBIND_CONDUIT = 14,
	ANIMA_CONTAINER = 15,
	GRATEFUL_OFFERING = 15,
	CYPHERS_OF_THE_FIRST_ONES = 16,
	BLOODY_TOKENS = 17,
	DRAGON_ISLES_SUPPLIES = 18,
	ELEMENTAL_OVERFLOW = 19,
	FLIGHTSTONES = 20,
	POLISHED_PET_CHARM = 21,
	BATTLE_PET_BANDAGE = 22,
	WHELPLINGS_DREAMING_CREST = 23,
	DRAKES_DREAMING_CREST = 24,
	WYRMS_DREAMING_CREST = 25,
	ASPECTS_DREAMING_CREST = 26,
	WHELPLINGS_AWAKENED_CREST = 27,
	DRAKES_AWAKENED_CREST = 28,
	WYRMS_AWAKENED_CREST = 29,
	ASPECTS_AWAKENED_CREST = 30,
	MYSTERIOUS_FRAGMENT = 31,
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
	[1553] = true, -- azerite (bfa)
	[2123] = true, -- Bloody Tokens (dragonflight)
}

CONSTANTS.THEWARWITHIN_REPUTATION_CURRENCY_IDS = {
-- TODO
}

CONSTANTS.DRAGONFLIGHT_REPUTATION_CURRENCY_IDS = {
	[2107] = true, -- Artisan's Consortium
	[2108] = true, -- Maruuk Centaur
	[2109] = true, -- Iskaara Tuskarr
	[2031] = true, -- Dragonscale Expedition
	[2106] = true, -- Valdrakken Accord
	[2420] = true, -- Loamm Niffen
	[2652] = true, -- Dream wardens
}

CONSTANTS.SHADOWLANDS_REPUTATION_CURRENCY_IDS = {
	[1804] = true, -- The Ascended
	[1805] = true, -- Undying Army
	[1806] = true, -- Wild Hunt
	[1807] = true, -- Court of Harvesters	
	[1884] = true, -- avowed *** (no supplies chest) ***
	[1887] = true, -- Court of Night *** (no supplies chest) ***
	[1880] = true, -- Venari
	[1907] = true, -- Death
	[1997] = true, -- The Archivists
	[1982] = true, -- The Enlightened
	[1877] = true, -- XP
}

CONSTANTS.BFA_REPUTATION_CURRENCY_IDS = {
	[1579] = true, -- Champions of Azeroth
	[1598] = true, -- Tortollan Seekers
	[1600] = true, -- Honorbound
	[1595] = true, -- Talanji's Expedition
	[1597] = true, -- Zandalari Empire
	[1596] = true, -- Voldunai
	[1599] = true, -- 7th Legion
	[1593] = true, -- Proudmoore Admiralty
	[1594] = true, -- Storm's Wake
	[1592] = true, -- Order of Embers
	[1742] = true, -- Rustbolt Resistance
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

CONSTANTS.ACHIEVEMENT_IDS = {
	PET_BATTLE_WQ = {
		[CONSTANTS.EXPANSIONS.THEWARWITHIN] = 0,					-- TODO
		[CONSTANTS.EXPANSIONS.DRAGONFLIGHT] = 16464,
		[CONSTANTS.EXPANSIONS.SHADOWLANDS] = 14625,
		[CONSTANTS.EXPANSIONS.BFA] = 12936,
		[CONSTANTS.EXPANSIONS.LEGION] = 10876,
	},
	LEGION_FISHING_WQ = 10598,
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
	-- Battle in the shadowlands
	[61949] = 1,
	[61948] = 2,
	[61947] = 3,
	[61946] = 4,
	[61886] = 5,
	[61885] = 6,
	[61883] = 7,
	[61879] = 8,
	[61870] = 9,
	[61868] = 10,
	[61867] = 11,
	[61866] = 12,
	[61791] = 13,
	[61787] = 14,
	[61784] = 15,
	[61783] = 16,
	-- Dragonflight
	[71206] = 1,
	[71202] = 2,
	[66588] = 3,
	[71145] = 4,
	[71166] = 5,
	[66551] = 6,
	[71140] = 7,
	[71180] = 8,

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
		order = { 2407, 2410, 2413, 2465, 2432, 2470, 2472, 2478 },
		[2407] = "ui_sigil_kyrian", -- ascended
		[2410] = "inv_shoulder_mail_maldraxxus_d_01", -- undying army
		[2413] = "inv_cape_special_revendreth_d_01", -- court of harvesters

		[2465] = "inv_wand_1h_ardenweald_d_01", -- wild hunt
		[2439] = "6bf_blackrock_nova", -- avowed *** (no supplies chest) ***
		[2464] = "inv_legion_cache_courtoffarnodis", -- Court of Night *** (no supplies chest) ***
		[2432] = "item_venari_paragonchest_03", -- Venari
		[2470] = "item_korthia_paragonchest_02", -- deathsadvance
		[2472] = "inv_archaeology_80_witch_book", -- The Archivists' Codex
		[2478] = "inv_misc_enlightenedbrokers_paragoncache01", -- TheEnlightened
	},
	dragonflight = {
		order = {2507, 2503, 2511, 2510, 2564, 2574 },
		[2507] = "ui_majorfaction_expedition", -- Dragonscale Expedition
		[2503] = "ui_majorfaction_centaur", -- Maruuk Centaur
		[2511] = "ui_majorfaction_tuskarr", -- Iskaara Tuskarr
		[2510] = "ui_majorfaction_valdrakken", -- Valdrakken Accord
		[2564] = "ui_majorfaction_niffen", -- Loamm Niffen
		[2574] = "ui_majorfaction_denizens", -- Dream Wardens
	},
	thewarwithin = {			-- TODO
		order = {},
	},
}

addon.CONSTANTS = CONSTANTS
