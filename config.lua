local _, NS = ...

NS.IN_DUEL = false

NS.SPELL_PVPTRINKET = 336126
NS.SPELL_PVPADAPTATION = 195901
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

NS.INSTANCE_TYPES = {}

NS.DefaultDatabase = {
  global = {
    anchor = "BOTTOMLEFT",
    anchorTo = "TOPRIGHT",
    growDirection = "RIGHT",
    offsetX = 2,
    offsetY = 2,
    iconAlpha = 1,
    iconSize = 24,
    iconSpacing = 1,
    trinketOnly = true,
    showOnAllies = true,
    SpellCDs = {},
    targetOnly = false,
    showSelf = false,
    ignoreNameplateAlpha = false,
    ignoreNameplateScale = false,
    frameStrata = "HIGH",
    enableGlow = true,
    test = false,
    debug = false,
    showEverywhere = true,
    instanceTypes = {
      none = true,
      pvp = true,
      arena = true,
      party = true,
      raid = true,
      scenario = true,
      unknown = true,
    },
  },
}
