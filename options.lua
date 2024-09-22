local AddonName, NS = ...

local LibStub = LibStub
local unpack = unpack

local math_floor = math.floor

local GetSpellInfo = C_Spell.GetSpellInfo

---@type NameplateTrinket
local NameplateTrinket = NS.NameplateTrinket
local NameplateTrinketFrame = NS.NameplateTrinket.frame

local Options = {}
NS.Options = Options

local function InChatTexture(val)
  local icon_str
  local tex = GetSpellInfo(val).iconID
  if tex then
    icon_str = "\124T" .. tex .. ":15:15:-5:-5\124t"
  else
    icon_str = ""
  end
  return icon_str .. tostring(val)
end

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
        CCCommonIcon = {
          type = "toggle",
          width = "normal",
          order = 2,
          name = "CC Common Icon",
          desc = "Marked by icon representing CC category",
        },
        CCShowMonster = {
          type = "toggle",
          width = "normal",
          order = 3,
          name = "CC Show Monster",
          desc = "Show CC on Monster",
        },
        --[[
        CurrentTime = {
          type = "toggle",
          width = "normal",
          order = 4,
          name = "CC Highlight",
          desc = "CurrentTime Desc",
        },]]
        SortingStyle = {
          type = "toggle",
          width = "normal",
          order = 4,
          name = "Right Frame Style",
          desc = "Grid or Straight",
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
        LeftxOfs = {
          name = "Left Frame X",
          desc = "X point of Left Frame Icon",
          type = "range",
          width = "normal",
          order = 8,
          isPercent = false,
          min = -200,
          max = 200,
          step = 1,
        },
        RightxOfs = {
          name = "Right Frame X",
          desc = "X point of Right Frame Icon",
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
        OtherAlpha = {
          name = "non-Target Opacity",
          desc = "Opacity of non-Target Frame",
          type = "range",
          width = "normal",
          order = 12,
          isPercent = true,
          min = 0,
          max = 1,
          step = 0.01,
        },
        OtherScale = {
          name = "OtherScale",
          desc = "OtherScale Desc",
          type = "range",
          width = "normal",
          order = 13,
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
        attachFrame = {
          type = "input",
          disabled = function()
            return not NS.db.global.pSetting.pEnable
          end,
          order = 6,
          name = "Relative Frame",
          desc = "Relative to Player Diminish Frame",
          set = function(_, val)
            if _G[val] == nil then
              DEFAULT_CHAT_FRAME:AddMessage(
                "|c00008000" .. "NameplateTrinket" .. " |r" .. val .. " Please enter a valid frame name"
              )
            else
              NS.db.global.pSetting.attachFrame = val
            end
          end,
          get = function()
            return NS.db.global.pSetting.attachFrame
          end,
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
        Interrupt = {
          type = "toggle",
          width = "normal",
          order = 1,
          name = "Interrupt",
          desc = "Interrupt Desc",
        },
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
        CC = {
          type = "toggle",
          width = "normal",
          order = 4,
          name = "CC",
          desc = "CC Desc",
        },
        Dispel = {
          type = "toggle",
          width = "normal",
          order = 5,
          name = "Dispel",
          desc = "Dispel Desc",
        },
        dummy = {
          name = "",
          type = "description",
          width = "full",
          order = 6,
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
            ["2px"] = "2 Pixel",
            ["3px"] = "3 Pixel",
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
        dummy = {
          name = "",
          type = "description",
          width = "full",
          order = 10,
        },
        tauntCommon = {
          type = "input",
          disabled = function()
            return not (NS.db.global.gSetting.CCCommonIcon and NS.db.global.Group.taunt)
          end,
          order = 11,
          name = "Taunt Common Icon",
          desc = "Default 355",
          set = function(_, val)
            local num = tonumber(val)
            if num and GetSpellInfo(num) then
              NS.db.global.Group.tauntCommon = num
            else
              DEFAULT_CHAT_FRAME:AddMessage(
                "|c00008000" .. "NameplateTrinket" .. " |r" .. val .. " Invalid spellID Insert an existing spell"
              )
            end
          end,
          get = function()
            return InChatTexture(NS.db.global.Group.tauntCommon)
          end,
        },
        incapacitateCommon = {
          type = "input",
          disabled = function()
            return not (NS.db.global.gSetting.CCCommonIcon and NS.db.global.Group.incapacitate)
          end,
          order = 12,
          name = "Incapacitate Common Icon",
          desc = "Default 118",
          set = function(_, val)
            local num = tonumber(val)
            if num and GetSpellInfo(num) then
              NS.db.global.Group.incapacitateCommon = num
            else
              DEFAULT_CHAT_FRAME:AddMessage(
                "|c00008000" .. "NameplateTrinket" .. " |r" .. val .. " Invalid spellID Insert an existing spell"
              )
            end
          end,
          get = function()
            return InChatTexture(NS.db.global.Group.incapacitateCommon)
          end,
        },
        silenceCommon = {
          type = "input",
          disabled = function()
            return not (NS.db.global.gSetting.CCCommonIcon and NS.db.global.Group.silence)
          end,
          order = 13,
          name = "Silence Common Icon",
          desc = "Default 15487",
          set = function(_, val)
            local num = tonumber(val)
            if num and GetSpellInfo(num) then
              NS.db.global.Group.silenceCommon = num
            else
              DEFAULT_CHAT_FRAME:AddMessage(
                "|c00008000" .. "NameplateTrinket" .. " |r" .. val .. " Invalid spellID Insert an existing spell"
              )
            end
          end,
          get = function()
            return InChatTexture(NS.db.global.Group.silenceCommon)
          end,
        },
        disorientCommon = {
          type = "input",
          disabled = function()
            return not (NS.db.global.gSetting.CCCommonIcon and NS.db.global.Group.disorient)
          end,
          order = 14,
          name = "Disorient Common Icon",
          desc = "Default 118699",
          set = function(_, val)
            local num = tonumber(val)
            if num and GetSpellInfo(num) then
              NS.db.global.Group.disorientCommon = num
            else
              DEFAULT_CHAT_FRAME:AddMessage(
                "|c00008000" .. "NameplateTrinket" .. " |r" .. val .. " Invalid spellID Insert an existing spell"
              )
            end
          end,
          get = function()
            return InChatTexture(NS.db.global.Group.disorientCommon)
          end,
        },
        stunCommon = {
          type = "input",
          disabled = function()
            return not (NS.db.global.gSetting.CCCommonIcon and NS.db.global.Group.stun)
          end,
          order = 15,
          name = "Stun Common Icon",
          desc = "Default 408",
          set = function(_, val)
            local num = tonumber(val)
            if num and GetSpellInfo(num) then
              NS.db.global.Group.stunCommon = num
            else
              DEFAULT_CHAT_FRAME:AddMessage(
                "|c00008000" .. "NameplateTrinket" .. " |r" .. val .. " Invalid spellID Insert an existing spell"
              )
            end
          end,
          get = function()
            return InChatTexture(NS.db.global.Group.stunCommon)
          end,
        },
        rootCommon = {
          type = "input",
          disabled = function()
            return not (NS.db.global.gSetting.CCCommonIcon and NS.db.global.Group.root)
          end,
          order = 16,
          name = "Root Common Icon",
          desc = "Default 122",
          set = function(_, val)
            local num = tonumber(val)
            if num and GetSpellInfo(num) then
              NS.db.global.Group.rootCommon = num
            else
              DEFAULT_CHAT_FRAME:AddMessage(
                "|c00008000" .. "NameplateTrinket" .. " |r" .. val .. " Invalid spellID Insert an existing spell"
              )
            end
          end,
          get = function()
            return InChatTexture(NS.db.global.Group.rootCommon)
          end,
        },
        knockbackCommon = {
          type = "input",
          disabled = function()
            return not (NS.db.global.gSetting.CCCommonIcon and NS.db.global.Group.knockback)
          end,
          order = 17,
          name = "Knockback Common Icon",
          desc = "Default 132469",
          set = function(_, val)
            local num = tonumber(val)
            if num and GetSpellInfo(num) then
              NS.db.global.Group.knockbackCommon = num
            else
              DEFAULT_CHAT_FRAME:AddMessage(
                "|c00008000" .. "NameplateTrinket" .. " |r" .. val .. " Invalid spellID Insert an existing spell"
              )
            end
          end,
          get = function()
            return InChatTexture(NS.db.global.Group.knockbackCommon)
          end,
        },
        disarmCommon = {
          type = "input",
          disabled = function()
            return not (NS.db.global.gSetting.CCCommonIcon and NS.db.global.Group.disarm)
          end,
          order = 18,
          name = "Disarm Common Icon",
          desc = "Default 236077",
          set = function(_, val)
            local num = tonumber(val)
            if num and GetSpellInfo(num) then
              NS.db.global.Group.disarmCommon = num
            else
              DEFAULT_CHAT_FRAME:AddMessage(
                "|c00008000" .. "NameplateTrinket" .. " |r" .. val .. " Invalid spellID Insert an existing spell"
              )
            end
          end,
          get = function()
            return InChatTexture(NS.db.global.Group.disarmCommon)
          end,
        },
        dummyCommon = {
          name = "",
          type = "description",
          width = "full",
          order = 19,
        },
        ColorFull = {
          name = "100% Diminish Color",
          desc = function()
            local color = NS.db.global.Group.ColorFull
            local R = "|cffff0000R|r:" .. color[1] * 0xff
            local G = " |cff00ff00G|r:" .. color[2] * 0xff
            local B = " |cff0000ffB|r:" .. color[3] * 0xff
            local A = " A:" .. math_floor((color[4] * 100) + 0.5)

            return R .. G .. B .. A
          end,
          type = "color",
          width = "normal",
          order = 41,
          hasAlpha = true,
          set = function(info, ...)
            NS.db.global.Group.ColorFull = { ... }
          end,
          get = function()
            return unpack(NS.db.global.Group.ColorFull)
          end,
        },
        ColorHalf = {
          name = "50% Diminish Color",
          desc = function()
            local color = NS.db.global.Group.ColorHalf
            local R = "|cffff0000R|r:" .. color[1] * 0xff
            local G = " |cff00ff00G|r:" .. color[2] * 0xff
            local B = " |cff0000ffB|r:" .. color[3] * 0xff
            local A = " A:" .. math_floor((color[4] * 100) + 0.5)

            return R .. G .. B .. A
          end,
          type = "color",
          width = "normal",
          order = 42,
          hasAlpha = true,
          set = function(info, ...)
            NS.db.global.Group.ColorHalf = { ... }
          end,
          get = function()
            return unpack(NS.db.global.Group.ColorHalf)
          end,
        },
        ColorQuat = {
          name = "25% Diminish Color",
          desc = function()
            local color = NS.db.global.Group.ColorQuat
            local R = "|cffff0000R|r:" .. color[1] * 0xff
            local G = " |cff00ff00G|r:" .. color[2] * 0xff
            local B = " |cff0000ffB|r:" .. color[3] * 0xff
            local A = " A:" .. math_floor((color[4] * 100) + 0.5)

            return R .. G .. B .. A
          end,
          type = "color",
          width = "normal",
          order = 43,
          hasAlpha = true,
          set = function(info, ...)
            NS.db.global.Group.ColorQuat = { ... }
          end,
          get = function()
            return unpack(NS.db.global.Group.ColorQuat)
          end,
        },
      },
    },
    CCHL = {
      name = "CC Highlight",
      type = "group",
      order = 9,
      set = function(info, val)
        NS.db.global.CCHL[info[#info]] = val
      end,
      get = function(info)
        return NS.db.global.CCHL[info[#info]]
      end,
      args = {
        Description = {
          type = "description",
          name = "Gives highlight effect for Crowd Control duration ",
          width = "full",
          order = 1,
        },
        Enable = {
          type = "toggle",
          width = 3,
          order = 2,
          name = "CC Highlight Enable",
        },
        Style = {
          name = "Highlight Style",
          type = "select",
          disabled = function()
            return not NS.db.global.CCHL.Enable
          end,
          width = "normal",
          order = 3,
          values = {
            ["ButtonGlow"] = "ButtonGlow",
            ["PixelGlow"] = "PixelGlow",
            ["AutoCastGlow"] = "AutoCastGlow",
          },
        },
        dummy = {
          name = "",
          type = "description",
          width = "full",
          order = 4,
        },
        pixellength = {
          name = "Length of lines",
          type = "range",
          disabled = function()
            return not NS.db.global.CCHL.Enable
          end,
          hidden = function(info)
            if NS.db.global.CCHL.Style == "PixelGlow" then
              return false
            end
            return true
          end,
          width = "normal",
          order = 5,
          isPercent = false,
          min = 2,
          max = 10,
          step = 1,
        },
        pixelth = {
          name = "Thickness of lines",
          type = "range",
          disabled = function()
            return not NS.db.global.CCHL.Enable
          end,
          hidden = function(info)
            if NS.db.global.CCHL.Style == "PixelGlow" then
              return false
            end
            return true
          end,
          width = "normal",
          order = 6,
          isPercent = false,
          min = 1,
          max = 7,
          step = 1,
        },
        autoscale = {
          name = "Scale of particles",
          type = "range",
          disabled = function()
            return not NS.db.global.CCHL.Enable
          end,
          hidden = function(info)
            if NS.db.global.CCHL.Style == "AutoCastGlow" then
              return false
            end
            return true
          end,
          width = "normal",
          order = 7,
          isPercent = false,
          min = 1,
          max = 5,
          step = 0.1,
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
