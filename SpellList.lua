local _, Data = ...

Data.n_MAP = {
	["Trinket"] = {
	--	[195710]	= 180,	-- Honorable Medallion
	--	[208683]	= 120,	-- Gladiator's Medallion
	--	[195901]	= 60,  	-- Adapted
	--	[196029]	= -1,	-- Relentless

		[42292]		= 120,	-- Item Trinket PvP Trinket Account attribution (Require Texture setting)
		[336126]	= 120,	-- Item Trinket Gladiator's Medallion
		[336139]	= 60,	-- Item Trinket Adapted
		[336128]	= -1,	-- Item Trinket Relentless
	--	[283167]	= 60,	-- Item Trinket Adapted
	--	[363117]    = 180,  -- Item Trinket 9.2 Gladiator's Resolve 우주적 검투사의 치밀한 결의 발동효과ID(362699)
	--	[363121]    = 12,   -- Item Trinket 9.2 Gladiator's Echoing Resolve 우주적 검투사의 메아리치는 결의
	--	[362699]    = 12,   -- Item Trinket 9.2 Gladiator's Echoing Resolve 우주적 검투사의 메아리치는 결의
	},
	["RST_Racial"] = {
		[59752]		= 180,	-- Every Man for Himself (Human)
		[7744]		= 120,	-- Will of the Forsaken (Undead(Scourge))
		[65116]		= 120,	-- Stoneform (Dwarf)
		[273104]	= 120,	-- Fireblood (Dark Iron Dwarf) 265221(x)
	},
	["Racial"] = {
		[33697]		= 120,	-- Blood Fury (Orc Shaman, Monk)
		[33702]		= 120,	-- Blood Fury (Orc Mage, Warlock)
		[20572]		= 120,	-- Blood Fury (Orc Warrior, Hunter, Rogue, Death Knight)
		[26297]		= 180,	-- Berserking (Troll)
		[20549]		= 90,	-- War Stomp (Tauren)
		[69070]		= 90,	-- Rocket Jump (Goblin)
	--	[69041]		= 90,	-- Rocket Barrage (Goblin)
		[107079]	= 120,	-- Quaking Palm (Pandaren)
		[58984]		= 120,	-- Shadowmeld (Night Elf)
		[20589]		= 60,	-- Escape Artist (Gnome)
		[68992]		= 120,	-- Darkflight (Worgen)

		[59545] 	= 180,	-- Gift of the Naaru (Draenei Death Knight)
		[59543] 	= 180,	-- Gift of the Naaru (Draenei Hunter)
		[59548] 	= 180,	-- Gift of the Naaru (Draenei Mage)
		[121093]	= 180,	-- Gift of the Naaru (Draenei Monk)
		[59542] 	= 180,	-- Gift of the Naaru (Draenei Paladin)
		[59544] 	= 180,	-- Gift of the Naaru (Draenei Priest)
		[59547] 	= 180,	-- Gift of the Naaru (Draenei Shaman)
		[28880] 	= 180,	-- Gift of the Naaru (Draenei Warrior)

		[255654]	= 120,	-- Bull Rush (Highmountain Tauren)
		[260364]	= 180,	-- Arcane Pulse (Nightborne)
		[255647]	= 150,	-- Light's Judgment (Lightforged Draenei)
		[256948]	= 180,	-- Spatial Rift (Void Elf)
		[274738]	= 120,	-- Ancestral Call (Mag'har Orc)
		[291944]	= 150,	-- Regeneratin' (Zandalari Troll)
	--	[281954]	= 15 * 60,	-- Pterrordax Swoop (Zandalari Troll)
		[287712]	= 150,	-- Haymaker (Kul Tiran)

		[69179]  	= 120, 	-- Arcane Torrent (Blood Elf Warrior)
		[50613]		= 120,	-- Arcane Torrent (Blood Elf Death Knight)
		[155145]	= 120,	-- Arcane Torrent (Blood Elf Paladin)
		[25046]		= 120,	-- Arcane Torrent (Blood Elf Rogue)
		[80483]		= 120,	-- Arcane Torrent (Blood Elf Hunter)
		[129597]	= 120,	-- Arcane Torrent (Blood Elf Monk)
		[28730]		= 120,	-- Arcane Torrent (Blood Elf Mage, Warlock)
		[202719]	= 120,	-- Arcane Torrent (Blood Elf Demon Hunter)
		[232633]	= 120,	-- Arcane Torrent (Blood Elf Priest)

		[312411]	= 90,	-- Bag of Tricks (Vulpera)
	--	[312924]	= 180,	-- Hyper Organic Light Originator (Mechagnome)
		[312916]	= 150,	-- Emergency Failsafe (Mechagnome)
	},
	["Interrupt"] = {
		[204263]	= 45,	-- Shining Force (Priest Discipline, Holy)
		[15487] 	= 45,	-- Silence (Priest Shadow)

		[31821]		= 180,	-- Aura Mastery (Paladin Holy)
		[96231]		= 15,	-- Rebuke (Paladin Protection, Retribution)

		[57994] 	= 12,	-- Wind Shear (Shaman All)

		[102793]	= 60,	-- Ursol's Vortex (Druid Restoration)
		[106839]	= 15,	-- Skull Bash (Druid Feral, Guardian)
		[78675] 	= 60,	-- Solar Beam (Druid Balance)

		[2139]  	= 24,	-- Counterspell (Mage All)

		[198898]	= 30,	-- Song of Chi-Ji (Monk Mistweaver)
		[116705]	= 15,	-- Spear Hand Strike (Monk Brewmaster, Windwalker)

		[183752]	= 15,	-- Consume Magic (Demon Hunter All)

		[47528] 	= 15,	-- Mind Freeze (Death Knight All)

		[6552]  	= 15,	-- Pummel (Warrior All)

		[119910]	= 24,	-- Spell Lock (Warlock Fel hound)
		[132409]	= 24,	-- Spell Lock (Warlock Fel hound Grimoire of Sacrifice)
		[119909]	= 30, 	-- Seduction (Warlock Succubus)
		[261589]	= 30,	-- Seduction (Warlock Succubus Grimoire of Sacrifice)

		[1766]  	= 15,	-- Kick (Rogue All)

		[187707]	= 15,	-- Muzzle (Hunter Survival)
		[147362]	= 24,	-- Counter Shot (Hunter Beast Mastery, Marksmanship)
	},
	["Dispel"] = {
		[527]       = 8,    -- Purify (Priest Discipline, Holy)
		[213634]    = 8,    -- Purify Disease (Priest Shadow)

		[4987]      = 8,    -- Cleanse (Paladin Holy)
		[213644]    = 8,    -- Cleanse Toxins (Paladin Protection, Retribution)

		[77130]     = 8,    -- Purify Spirit (Shaman Restoration)
		[51886]     = 8,    -- Cleanse Spirit (Shaman Enhancement, Elemental)

		[88423]     = 8,    -- Nature's Cure (Druid Restoration)
		[2782]      = 8,    -- Remove Corruption (Druid Balance, Feral, Guardian)

		[475]       = 8,    -- Remove Curse (Mage All)

		[115450]    = 8,    -- Detox (Monk Mistweaver)
		[218164]    = 8,    -- Detox (Monk Windwalker, Brewmaster)
	},
	["ETCCD"] = {
		[205604]    = 60,   -- Reverse Magic (Demon Hunter All)

		[48707]		= 60,	-- Anti-Magic Shell (Death Knight All)

		[18499]		= 60, 	-- Berserker Rage (Warrior All)

		[119905]	= 15,	-- Singe Magic (Warlock Imp)
		[132411]	= 15,	-- Singe Magic (Warlock Imp Grimoire of Sacrifice)
		[119907]	= 120, 	-- Shadow Bulwark (Warlock Void Walker)
		[132413]	= 120,	-- Shadow Bulwark (Warlock Void Walker Grimoire of Sacrifice)
		[119914]	= 30,	-- Axe Toss (Warlock Felguard)

		[31224]		= 120,	-- Cloak of Shadows (Rogue All)

		[187650]	= 25,	-- Freezing Trap (Hunter All)
	},
	["Reset"] = {
	--	[195710]	= 30,	-- Honorable Medallion
	--	[208683]	= 30,	-- Gladiator's Medallion
	--	[195901]	= 30,  	-- Adapted
		[42292]		= 30,	-- Item Trinket PvP Trinket Account attribution (Require Texture setting)
		[336126]	= 30,	-- Item Trinket Gladiator's Medallion
		[336139]	= 30,	-- Item Trinket Adapted

		[59752]		= 90,	-- Every Man for Himself (Human)
		[7744]	 	= 30,	-- Will of the Forsaken (Undead(Scourge))
		[65116]	 	= 30,	-- Stoneform (Dwarf)
		[273104]	= 30,	-- Fireblood (Dark Iron Dwarf) 265221(x)
	},
}