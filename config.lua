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
      CCShowMonster = false,
      -- CurrentTime = true,
      SortingStyle = false,
      CooldownSpiral = true,
      FrameSize = 25,
      LeftxOfs = 0,
      RightxOfs = 0,
      yOfs = 0,
      TargetAlpha = 1,
      OtherAlpha = 0.6,
      OtherScale = 1 / GetCVar("nameplateSelectedScale"),
    },
    pSetting = {
      pEnable = true,
      pxOfs = 0,
      pyOfs = 0,
      pScale = 1.0,
      attachFrame = "PlayerFrame",
    },
    Func = {
      Interrupt = true,
      Racial = true,
      Trinket = true,
      CC = true,
      Dispel = true,
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
      tauntCommon = 355,
      incapacitateCommon = 118,
      silenceCommon = 15487,
      disorientCommon = 118699,
      stunCommon = 408,
      rootCommon = 122,
      knockbackCommon = 236777,
      disarmCommon = 236077,
      ColorFull = { 0, 1, 0, 0.6 },
      ColorHalf = { 1, 1, 0, 0.6 },
      ColorQuat = { 1, 0, 0, 0.6 },
    },
    CCHL = {
      Enable = true,
      Style = "ButtonGlow",
      pixellength = 8,
      pixelth = 2,
      autoscale = 1,
    },
    debug = false,
  },
}
