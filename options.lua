local AddonName, NS = ...

local LibStub = LibStub
local unpack = unpack

---@type NameplateTrinket
local NameplateTrinket = NS.NameplateTrinket
local NameplateTrinketFrame = NS.NameplateTrinket.frame

local Options = {}
NS.Options = Options

NS.AceConfig = {
  name = AddonName,
  descStyle = "inline",
  type = "group",
  childGroups = "tab",
  args = {
    test = {
      type = "execute",
      name = "Test",
      desc = "First, select a nameplate and then press the Test button",
      width = "normal",
      order = 5,
      func = "Test",
      handler = NameplateTrinket,
    },
    gSetting = {
      type = "group",
      name = "Settings",
      order = 5,
      set = function(info, val)
        NS.db.global.gSetting[info[#info]] = val
      end,
      get = function(info)
        return NS.db.global.gSetting[info[#info]]
      end,
      args = {
        ShowFriendlyPlayer = {
          type = "toggle",
          width = "normal",
          order = 1,
          name = "Show Friendly Player",
          desc = "Also displayed on friendly targets",
        },
        CooldownSpiral = {
          type = "toggle",
          width = 1,
          order = 5,
          name = "Cooldown Spiral",
          desc = "Toggle showing of the cooldown spiral",
        },
        dummygSetting = {
          name = "",
          type = "description",
          width = 1,
          order = 6,
        },
        FrameSize = {
          name = "Icon Size",
          desc = "Icon Size inc or dec(20 ~ 30 Recommended)",
          type = "range",
          width = "normal",
          order = 7,
          isPercent = false,
          min = 10,
          max = 40,
          step = 1,
        },
        xOfs = {
          name = "X",
          desc = "X point of Icon",
          type = "range",
          width = "normal",
          order = 9,
          isPercent = false,
          min = -200,
          max = 200,
          step = 1,
        },
        yOfs = {
          name = "Y",
          desc = "Y point of Icon",
          type = "range",
          width = "normal",
          order = 10,
          isPercent = false,
          min = -100,
          max = 100,
          step = 1,
        },
        TargetAlpha = {
          name = "Target Opacity",
          desc = "Opacity of Target Frame",
          type = "range",
          width = "normal",
          order = 11,
          isPercent = true,
          min = 0,
          max = 1,
          step = 0.01,
        },
        TargetScale = {
          name = "Target Scale",
          desc = "Scale of Target Frame",
          type = "range",
          width = "normal",
          order = 12,
          isPercent = true,
          min = 0.5,
          max = 1,
          step = 0.01,
        },
        OtherAlpha = {
          name = "non-Target Opacity",
          desc = "Opacity of non-Target Frame",
          type = "range",
          width = "normal",
          order = 13,
          isPercent = true,
          min = 0,
          max = 1,
          step = 0.01,
        },
        OtherScale = {
          name = "non-Target Scale",
          desc = "Scale of non-Target Frame",
          type = "range",
          width = "normal",
          order = 14,
          isPercent = true,
          min = 0.5,
          max = 1,
          step = 0.01,
        },
      },
    },
    pSetting = {
      name = "My Diminish",
      type = "group",
      order = 6,
      set = function(info, val)
        NS.db.global.pSetting[info[#info]] = val
      end,
      get = function(info)
        return NS.db.global.pSetting[info[#info]]
      end,
      args = {
        Description = {
          type = "description",
          name = "Player Diminish Frame Setting(To use this feature, [Show Friendly Player] option in Settings must be turned on.)\n",
          width = "full",
          order = 1,
        },
        pEnable = {
          type = "toggle",
          width = 3,
          order = 2,
          name = "Enable",
          desc = "Enable Desc",
        },
        pxOfs = {
          name = "X",
          desc = "Move to Left and Right",
          type = "range",
          disabled = function()
            return not NS.db.global.pSetting.pEnable
          end,
          width = "full",
          order = 3,
          isPercent = false,
          min = -1200,
          max = 1200,
          step = 1,
        },
        pyOfs = {
          name = "Y",
          desc = "Move to Up and Down",
          type = "range",
          disabled = function()
            return not NS.db.global.pSetting.pEnable
          end,
          width = "full",
          order = 4,
          isPercent = false,
          min = -600,
          max = 600,
          step = 1,
        },
        pScale = {
          name = "Scale",
          desc = "Scale",
          type = "range",
          disabled = function()
            return not NS.db.global.pSetting.pEnable
          end,
          width = "normal",
          order = 5,
          isPercent = true,
          min = 0.5,
          max = 1.5,
          step = 0.01,
        },
      },
    },
    Func = {
      name = "Function",
      type = "group",
      order = 7,
      set = function(info, val)
        NS.db.global.Func[info[#info]] = val
      end,
      get = function(info)
        return NS.db.global.Func[info[#info]]
      end,
      args = {
        Racial = {
          type = "toggle",
          width = "normal",
          order = 2,
          name = "Racial",
          desc = "Racial Desc",
        },
        Trinket = {
          type = "toggle",
          width = "normal",
          order = 3,
          name = "Trinket",
          desc = "Trinket Desc",
        },
        ColorBasc = {
          name = "Color of Basic Icon",
          desc = function()
            local color = NS.db.global.Func.ColorBasc
            local R = "|cffff0000R|r:" .. color[1] * 0xff
            local G = " |cff00ff00G|r:" .. color[2] * 0xff
            local B = " |cff0000ffB|r:" .. color[3] * 0xff
            --local A = " A:"..math_floor((color[4] * 100) + 0.5)
            --return R..G..B..A
            return R .. G .. B
          end,
          type = "color",
          width = "normal",
          order = 7,
          --hasAlpha = true,
          set = function(info, ...)
            NS.db.global.Func.ColorBasc = { ... }
          end,
          get = function()
            return unpack(NS.db.global.Func.ColorBasc)
          end,
        },
        IconBorder = {
          name = "Thickness of Icon Border",
          type = "select",
          width = "normal",
          order = 8,
          values = {
            ["1px"] = "1 Pixel",
            ["2px"] = "2 Pixel",
            ["3px"] = "3 Pixel",
            ["4px"] = "4 Pixel",
          },
        },
        dummy2 = {
          name = "",
          type = "description",
          width = "normal",
          order = 9,
        },
        FontEnable = {
          name = "Cooldown Font Enable",
          type = "toggle",
          width = "normal",
          order = 10,
        },
        FontScale = {
          name = "Cooldown Font Scale",
          type = "range",
          width = "normal",
          disabled = function()
            return not NS.db.global.Func.FontEnable
          end,
          order = 11,
          isPercent = true,
          min = 0.4,
          max = 1.2,
          step = 0.01,
        },
        FontPoint = {
          name = "Cooldown Font Point",
          type = "select",
          width = "normal",
          disabled = function()
            return not NS.db.global.Func.FontEnable
          end,
          order = 12,
          values = {
            ["TOP"] = "Top",
            ["TOPLEFT"] = "Top Left",
            ["TOPRIGHT"] = "Top Right",
            ["RIGHT"] = "Right",
            ["CENTER"] = "Center",
            ["LEFT"] = "Left",
            ["BOTTOMRIGHT"] = "Bottom Right",
            ["BOTTOMLEFT"] = "Bottom Left",
            ["BOTTOM"] = "Bottom",
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
        },
      },
    },
    Group = {
      name = "CC Category",
      type = "group",
      order = 8,
      set = function(info, val)
        NS.db.global.Group[info[#info]] = val
      end,
      get = function(info)
        return NS.db.global.Group[info[#info]]
      end,
      args = {
        Description = {
          type = "description",
          name = "Taunt and Knockback category does not work right yet\n",
          width = "full",
          order = 1,
        },
        taunt = {
          type = "toggle",
          width = "normal",
          order = 2,
          name = "Taunt",
          desc = "Taunt, Dark Command..",
        },
        incapacitate = {
          type = "toggle",
          width = "normal",
          order = 3,
          name = "Incapacitate",
          desc = "Polymorph, Hex..",
        },
        silence = {
          type = "toggle",
          width = "normal",
          order = 4,
          name = "Silence",
          desc = "Sigil of Silence, Strangulate..",
        },
        disorient = {
          type = "toggle",
          width = "normal",
          order = 5,
          name = "Disorient",
          desc = "Fear, Cyclone..",
        },
        stun = {
          type = "toggle",
          width = "normal",
          order = 6,
          name = "Stun",
          desc = "Smash, Storm Bolt..",
        },
        root = {
          type = "toggle",
          width = "normal",
          order = 7,
          name = "Root",
          desc = "Freeze, Entangling Roots..",
        },
        knockback = {
          type = "toggle",
          width = "normal",
          order = 8,
          name = "Knockback",
          desc = "Gorefiend's Grasp, Typhoon..",
        },
        disarm = {
          type = "toggle",
          width = "normal",
          order = 9,
          name = "Disarm",
          desc = "Dismantle, Grapple Weapon..",
        },
      },
    },
  },
}

function Options:SlashCommands(_)
  LibStub("AceConfigDialog-3.0"):Open(AddonName)
end

function Options:Setup()
  LibStub("AceConfig-3.0"):RegisterOptionsTable(AddonName, NS.AceConfig)
  LibStub("AceConfigDialog-3.0"):AddToBlizOptions(AddonName, AddonName)

  SLASH_NameplateTrinket1 = AddonName
  SLASH_NameplateTrinket2 = "/npt"

  function SlashCmdList.NameplateTrinket(message)
    self:SlashCommands(message)
  end
end

function NameplateTrinket:ADDON_LOADED(addon)
  if addon == AddonName then
    NameplateTrinketFrame:UnregisterEvent("ADDON_LOADED")

    NameplateTrinketDB = NameplateTrinketDB and next(NameplateTrinketDB) ~= nil and NameplateTrinketDB or {}

    -- Copy any settings from default if they don't exist in current profile
    NS.CopyDefaults(NS.DefaultDatabase, NameplateTrinketDB)

    -- Reference to active db profile
    -- Always use this directly or reference will be invalid
    NS.db = NameplateTrinketDB

    -- Remove table values no longer found in default settings
    NS.CleanupDB(NameplateTrinketDB, NS.DefaultDatabase)

    Options:Setup()
  end
end
NameplateTrinketFrame:RegisterEvent("ADDON_LOADED")
