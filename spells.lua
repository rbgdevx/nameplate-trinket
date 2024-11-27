local _, NS = ...

NS.CDs = {
  ["Trinket"] = {
    [42292] = 120, -- PvP Trinket -- https://www.wowhead.com/spell=42292/pvp-trinket
    [336126] = 120, -- Gladiator's Medallion -- https://www.wowhead.com/spell=336126/gladiators-medallion
    [336139] = 60, -- Adapted -- https://www.wowhead.com/spell=336139/adapted
    [283167] = 120, -- PvP Trinket -- https://www.wowhead.com/spell=283167/pvp-trinket
    -- [195710] = 180, -- Honorable Medallion -- https://www.wowhead.com/spell=195710/honorable-medallion -- Spell Modifier
    -- [363117] = 180, -- Gladiator's Fastidious Resolve -- https://www.wowhead.com/spell=363117/gladiators-fastidious-resolve
    -- [363121] = 12, -- Gladiator's Echoing Resolve -- https://www.wowhead.com/spell=363121/gladiators-echoing-resolve
    -- [208683] = 120, -- Gladiator's Medallion -- https://www.wowhead.com/spell=208683/gladiators-medallion
    -- [362699] = 12, -- Gladiator's Resolve -- https://www.wowhead.com/spell=362699/gladiators-resolve
    -- [196029] = -1, -- Relentless -- https://www.wowhead.com/spell=196029/relentless
    -- [336128] = -1, -- Relentless -- https://www.wowhead.com/spell=336128/relentless
    -- [195901] = 60, -- Adapted -- https://www.wowhead.com/spell=195901/adapted
  },
  ["Racial"] = {
    [59752] = 180, -- Will to Survive -- Human -- https://www.wowhead.com/spell=59752/will-to-survive
    [7744] = 160, -- Will of the Forsaken -- Undead -- https://www.wowhead.com/spell=7744/will-of-the-forsaken
    [265221] = 160, -- Fireblood -- Dark Iron Dwarf -- https://www.wowhead.com/spell=265221/fireblood -- MAYBE
    [20594] = 160, -- Stoneform -- Dwarf -- https://www.wowhead.com/spell=20594/stoneform -- MAYBE
    [20589] = 60, -- Escape Artist -- Gnome -- https://www.wowhead.com/spell=20589/escape-artist
  },
  ["Spell"] = {
    [48792] = 120, -- Icebound Fortitude -- Death Knight -- https://www.wowhead.com/spell=48792
    [49039] = 120, -- Lichborne -- Death Knight -- https://www.wowhead.com/spell=49039
    [354489] = 20, -- Glimpse -- Demon Hunter -- https://www.wowhead.com/spell=354489/glimpse
    [378464] = 90, -- Nullifying Shroud --  Evoker -- https://www.wowhead.com/spell=378464/nullifying-shroud
    [357210] = 120, -- Deep Breath -- Evoker -- https://www.wowhead.com/spell=357210/deep-breath
    [359816] = 120, -- Dream Flight -- Evoker -- https://www.wowhead.com/spell=359816/dream-flight
    [403631] = 120, -- Breath of Eons -- Evoker -- https://www.wowhead.com/spell=403631/breath-of-eons
    [421453] = 240, -- Ultimate Penitence -- Priest -- https://www.wowhead.com/spell=421453/ultimate-penitence
    [227847] = 90, -- Bladestorm -- Warrior -- https://www.wowhead.com/spell=227847/bladestorm
    [389774] = 90, -- Bladestorm -- Warrior -- https://www.wowhead.com/spell=389774/bladestorm
    [642] = 300, -- Divine Shield -- Paladin -- https://www.wowhead.com/spell=642/divine-shield
  },
}

NS.Interrupts = {
  [47528] = true, -- // Mind Freeze
  [106839] = true, -- // Skull Bash
  [2139] = true, -- // Counterspell
  [96231] = true, -- // Rebuke
  [15487] = true, -- // Silence
  [1766] = true, -- // Kick
  [57994] = true, -- // Wind Shear
  [6552] = true, -- // Pummel
  [19647] = true, -- // Spell Lock https://www.wowhead.com/spell=19647
  [132409] = true, -- Spell Lock (demon sacrificed) https://www.wowhead.com/spell=132409
  [116705] = true, -- // Spear Hand Strike
  [115781] = true, -- // Optical Blast
  [183752] = true, -- // Consume Magic
  [187707] = true, -- // Muzzle
  [91802] = true, -- // Shambling Rush https://www.wowhead.com/spell=91802/shambling-rush
  [212619] = true, -- // Вызов охотника Скверны
  [78675] = true, -- // Столп солнечного света
  [351338] = true, -- Quell https://www.wowhead.com/spell=351338
  [147362] = true, -- Counter Shot
}

NS.Trinkets = {
  [59752] = true,
  [7744] = true,
  [336126] = true,
  [283167] = true,
  [42292] = true,
  [336139] = true,
}
