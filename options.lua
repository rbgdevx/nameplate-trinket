local AddonName, NS = ...

local IsInInstance = IsInInstance
local print = print
local CopyTable = CopyTable

NS.AceConfig = {
  name = AddonName,
  type = "group",
  args = {
    test = {
      name = "Turns on test mode for placement of icons",
      desc = "Only works outside of an instance.",
      type = "toggle",
      width = "double",
      order = 1,
      set = function(_, val)
        NS.db.global.test = val

        if val then
          if IsInInstance() then
            print("Can't test while in instance")
          else
            NS.EnableTestMode()
          end
        else
          NS.DisableTestMode()
        end
      end,
      get = function(_)
        return NS.db.global.test
      end,
    },
    trinketOnly = {
      name = "Track Trinket Only",
      desc = "Turning this off tracks other spells similar that prevent cc.",
      type = "toggle",
      width = "full",
      order = 2,
      set = function(_, val)
        NS.db.global.trinketOnly = val

        NS.OnDbChanged(val)
      end,
      get = function(_)
        return NS.db.global.trinketOnly
      end,
    },
    targetOnly = {
      name = "Track current target only",
      desc = "Show only for the current target nameplate",
      type = "toggle",
      width = "full",
      order = 3,
      set = function(_, val)
        NS.db.global.targetOnly = val

        NS.OnDbChanged()
      end,
      get = function(_)
        return NS.db.global.targetOnly
      end,
    },
    showOnAllies = {
      name = "Show on Allies",
      desc = "Shows on friendly nameplates",
      type = "toggle",
      width = "full",
      order = 4,
      set = function(_, val)
        NS.db.global.showOnAllies = val

        NS.OnDbChanged()
      end,
      get = function(_)
        return NS.db.global.showOnAllies
      end,
    },
    ignoreNameplateAlpha = {
      name = "Ignore Nameplate Alpha",
      desc = "Turning this off keeps the icons fully visible even when the nameplate fades out.",
      type = "toggle",
      width = "full",
      order = 5,
      set = function(_, val)
        NS.db.global.ignoreNameplateAlpha = val

        NS.OnDbChanged()
      end,
      get = function(_)
        return NS.db.global.ignoreNameplateAlpha
      end,
    },
    ignoreNameplateScale = {
      name = "Ignore Nameplate Scale",
      desc = "Turning this off keeps the icons at the size you set even when the nameplate gets bigger or smaller.",
      type = "toggle",
      width = "full",
      order = 6,
      set = function(_, val)
        NS.db.global.ignoreNameplateScale = val

        NS.OnDbChanged()
      end,
      get = function(_)
        return NS.db.global.ignoreNameplateScale
      end,
    },
    enableGlow = {
      name = "Enable Glow on Trinket",
      desc = "Shows a yellow glow around the trinket icon.",
      type = "toggle",
      width = "full",
      order = 7,
      set = function(_, val)
        NS.db.global.enableGlow = val

        NS.OnDbChanged()
      end,
      get = function(_)
        return NS.db.global.enableGlow
      end,
    },
    frameStrata = {
      name = "Frame Strata",
      desc = "Set how high or low the icons are in the frame stack (in front or behind things)",
      type = "select",
      width = "normal",
      order = 8,
      values = {
        ["BACKGROUND"] = "Background",
        ["LOW"] = "Low",
        ["MEDIUM"] = "Medium",
        ["HIGH"] = "High",
        ["DIALOG"] = "Dialog",
        ["FULLSCREEN"] = "Fullscreen",
        ["FULLSCREEN_DIALOG"] = "Fullscreen Dialog",
        ["TOOLTIP"] = "Tooltip",
      },
      set = function(_, val)
        NS.db.global.frameStrata = val

        NS.OnDbChanged()
      end,
      get = function(_)
        return NS.db.global.frameStrata
      end,
    },
    spacing1 = { type = "description", order = 9, name = " " },
    iconAlpha = {
      name = "Icon Alpha",
      type = "range",
      width = "normal",
      order = 10,
      isPercent = false,
      min = 0,
      max = 1,
      step = 0.01,
      set = function(_, val)
        NS.db.global.iconAlpha = val

        NS.OnDbChanged()
      end,
      get = function(_)
        return NS.db.global.iconAlpha
      end,
    },
    iconSize = {
      name = "Icon Size",
      type = "range",
      width = "normal",
      order = 11,
      isPercent = false,
      min = 12,
      max = 64,
      step = 1,
      set = function(_, val)
        NS.db.global.iconSize = val

        NS.OnDbChanged()
      end,
      get = function(_)
        return NS.db.global.iconSize
      end,
    },
    iconSpacing = {
      name = "Icon Spacing",
      desc = "Spacing between each icon",
      type = "range",
      width = "normal",
      order = 12,
      isPercent = false,
      min = 0,
      max = 25,
      step = 1,
      set = function(_, val)
        NS.db.global.iconSpacing = val

        NS.OnDbChanged()
      end,
      get = function(_)
        return NS.db.global.iconSpacing
      end,
    },
    spacing2 = { type = "description", order = 13, name = " " },
    anchor = {
      name = "Anchor",
      type = "select",
      width = "normal",
      order = 14,
      values = {
        ["TOP"] = "Top",
        ["BOTTOM"] = "Bottom",
        ["LEFT"] = "Left",
        ["RIGHT"] = "Right",
        ["TOPLEFT"] = "Top Left",
        ["TOPRIGHT"] = "Top Right",
        ["BOTTOMLEFT"] = "Bottom Left",
        ["BOTTOMRIGHT"] = "Bottom Right",
        ["CENTER"] = "Center",
      },
      sorting = {
        "TOPLEFT",
        "TOP",
        "TOPRIGHT",
        "LEFT",
        "CENTER",
        "RIGHT",
        "BOTTOMLEFT",
        "BOTTOM",
        "BOTTOMRIGHT",
      },
      set = function(_, val)
        NS.db.global.anchor = val

        NS.OnDbChanged()
      end,
      get = function(_)
        return NS.db.global.anchor
      end,
    },
    anchorTo = {
      name = "Anchor To",
      type = "select",
      width = "normal",
      order = 15,
      values = {
        ["TOP"] = "Top",
        ["BOTTOM"] = "Bottom",
        ["LEFT"] = "Left",
        ["RIGHT"] = "Right",
        ["TOPLEFT"] = "Top Left",
        ["TOPRIGHT"] = "Top Right",
        ["BOTTOMLEFT"] = "Bottom Left",
        ["BOTTOMRIGHT"] = "Bottom Right",
        ["CENTER"] = "Center",
      },
      sorting = {
        "TOPLEFT",
        "TOP",
        "TOPRIGHT",
        "LEFT",
        "CENTER",
        "RIGHT",
        "BOTTOMLEFT",
        "BOTTOM",
        "BOTTOMRIGHT",
      },
      set = function(_, val)
        NS.db.global.anchorTo = val

        NS.OnDbChanged()
      end,
      get = function(_)
        return NS.db.global.anchorTo
      end,
    },
    growDirection = {
      name = "Grow Direction",
      desc = "The direction the icons will output",
      type = "select",
      width = "normal",
      order = 16,
      values = {
        ["RIGHT"] = "Right",
        ["LEFT"] = "Left",
      },
      set = function(_, val)
        NS.db.global.growDirection = val

        NS.OnDbChanged()
      end,
      get = function(_)
        return NS.db.global.growDirection
      end,
    },
    spacing3 = { type = "description", order = 17, name = " " },
    offsetX = {
      name = "Offset X",
      desc = "Offset left/right from the anchor point",
      type = "range",
      width = "normal",
      order = 18,
      isPercent = false,
      min = -250,
      max = 250,
      step = 1,
      set = function(_, val)
        NS.db.global.offsetX = val

        NS.OnDbChanged()
      end,
      get = function(_)
        return NS.db.global.offsetX
      end,
    },
    offsetY = {
      name = "Offset Y",
      desc = "Offset top/bottom from the anchor point",
      type = "range",
      width = "normal",
      order = 19,
      isPercent = false,
      min = -250,
      max = 250,
      step = 1,
      set = function(_, val)
        NS.db.global.offsetY = val

        NS.OnDbChanged()
      end,
      get = function(_)
        return NS.db.global.offsetY
      end,
    },
    spacing4 = { type = "description", order = 20, name = " " },
    debug = {
      name = "Toggle debug mode",
      desc = "Turning this feature on prints debug messages to the chat window.",
      type = "toggle",
      width = "full",
      order = 99,
      set = function(_, val)
        NS.db.global.debug = val
      end,
      get = function(_)
        return NS.db.global.debug
      end,
    },
    reset = {
      name = "Reset Everything",
      type = "execute",
      width = "normal",
      order = 100,
      func = function()
        NameplateTrinketDB = CopyTable(NS.DefaultDatabase)
        NS.db = CopyTable(NS.DefaultDatabase)
        NS.OnDbChanged()
      end,
    },
  },
}
