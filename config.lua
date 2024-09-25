local AddonName, NS = ...

local CreateFrame = CreateFrame

---@class GlobalTable : table
---@field gSetting any
---@field pSetting any
---@field Func any
---@field Group any
---@field CCHL any
---@field debug boolean

---@class DBTable : table
---@field global GlobalTable

---@class NameplateTrinket
---@field ADDON_LOADED function
---@field PLAYER_LOGIN function
---@field LOADING_SCREEN_DISABLED function
---@field PLAYER_LEAVING_WORLD function
---@field PLAYER_ENTERING_WORLD function
---@field NAME_PLATE_UNIT_ADDED function
---@field NAME_PLATE_UNIT_REMOVED function
---@field COMBAT_LOG_EVENT_UNFILTERED function
---@field Refresh function
---@field ClearValue function
---@field Test function
---@field CheckCategory function
---@field ShowGlow function
---@field HideGlow function
---@field SlashCommands function
---@field frame Frame
---@field db GlobalTable

---@type NameplateTrinket
---@diagnostic disable-next-line: missing-fields
local NameplateTrinket = {}
NS.NameplateTrinket = NameplateTrinket

local NameplateTrinketFrame = CreateFrame("Frame", AddonName .. "Frame")
NameplateTrinketFrame:SetScript("OnEvent", function(_, event, ...)
  if NameplateTrinket[event] then
    NameplateTrinket[event](NameplateTrinket, ...)
  end
end)
NS.NameplateTrinket.frame = NameplateTrinketFrame

NS.DefaultDatabase = {
  global = {
    gSetting = {
      ShowFriendlyPlayer = true,
      CCCommonIcon = false,
      CooldownSpiral = true,
      FrameSize = 25,
      xOfs = 0,
      yOfs = 0,
      TargetAlpha = 1,
      TargetScale = 1,
      OtherAlpha = 0.6,
      OtherScale = 1 / GetCVar("nameplateSelectedScale"),
    },
    pSetting = {
      pEnable = true,
      pxOfs = 0,
      pyOfs = 0,
      pScale = 1.0,
    },
    Func = {
      Racial = true,
      Trinket = true,
      ColorBasc = { 1, 1, 1, 1.0 },
      IconBorder = "2px",
      FontEnable = true,
      FontScale = 1.0,
      FontPoint = "TOPRIGHT",
    },
    Group = {
      taunt = false,
      incapacitate = true,
      silence = true,
      disorient = true,
      stun = true,
      root = true,
      knockback = false,
      disarm = true,
    },
    debug = false,
  },
}
