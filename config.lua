local _, NS = ...

NS.IN_DUEL = false

NS.SPELL_PVPADAPTATION = 195901
NS.SPELL_PVPTRINKET = 336126
NS.SPELL_RESET = 294701

NS.ICON_GROW_DIRECTION_RIGHT = "right"
NS.ICON_GROW_DIRECTION_LEFT = "left"
NS.ICON_GROW_DIRECTION_UP = "up"
NS.ICON_GROW_DIRECTION_DOWN = "down"

NS.SORT_MODE_NONE = "none"
NS.SORT_MODE_TRINKET_INTERRUPT_OTHER = "trinket-interrupt-other"
NS.SORT_MODE_INTERRUPT_TRINKET_OTHER = "interrupt-trinket-other"
NS.SORT_MODE_TRINKET_OTHER = "trinket-other"
NS.SORT_MODE_INTERRUPT_OTHER = "interrupt-other"

NS.GLOW_TIME_INFINITE = 4 * 1000 * 1000 * 1000

NS.INSTANCE_TYPE_NONE = "none"
NS.INSTANCE_TYPE_UNKNOWN = "unknown"
NS.INSTANCE_TYPE_PVP = "pvp"
NS.INSTANCE_TYPE_PVP_BG_40PPL = "pvp_bg_40ppl"
NS.INSTANCE_TYPE_ARENA = "arena"
NS.INSTANCE_TYPE_PARTY = "party"
NS.INSTANCE_TYPE_RAID = "raid"
NS.INSTANCE_TYPE_SCENARIO = "scenario"

NS.UNKNOWN_CLASS = "MISC"
NS.ALL_CLASSES = "ALL-CLASSES"

NS.EPIC_BG_ZONE_IDS = {
  [30] = true, -- Alterac Valley
  [628] = true, -- Isle of Conquest
  [1191] = true, -- Ashran
  [1280] = true, -- Southshore vs. Tarren Mill
  [2118] = true, -- Battle for Wintergrasp
  [2197] = true, -- Korrak's Revenge
}

NS.DefaultDatabase = {
  global = {
    anchor = "BOTTOMLEFT",
    anchorTo = "TOPRIGHT",
    growDirection = "RIGHT",
    offsetX = 2,
    offsetY = 2,
    iconAlpha = 1,
    iconSize = 25,
    iconSpacing = 1,
    trinketOnly = true,
    showOnAllies = true,
    SpellCDs = {},
    targetOnly = false,
    ignoreNameplateAlpha = false,
    ignoreNameplateScale = false,
    frameStrata = "HIGH",
    enableGlow = true,
    test = false,
    debug = false,
  },
}
