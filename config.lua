local _, NS = ...

local next = next
local pairs = pairs
local tostring = tostring

local GetSpellInfo = C_Spell.GetSpellInfo
local GetSpellDescription = C_Spell.GetSpellDescription
local tinsert = table.insert
local tsort = table.sort

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

NS.INSTANCE_TYPES = {
  -- nil resolves to "unknown"
  -- "unknown" - Used by a single map: Void Zone: Arathi Highlands (2695)
  ["unknown"] = false, -- when in an unknown instance
  ["none"] = true, -- when outside an instance
  ["pvp"] = true, --  when in a battleground
  ["arena"] = true, -- when in an arena
  ["party"] = false, -- when in a 5-man instance
  ["raid"] = false, -- when in a raid instance
  ["scenario"] = false, -- when in a scenario
}

---@class InstanceTypes
---@field arena boolean
---@field pvp boolean
---@field none boolean

---@class GlobalTable
---@field test boolean
---@field testNPCs boolean
---@field anchor string
---@field anchorTo string
---@field growDirection "left" | "right"
---@field offsetX number
---@field offsetY number
---@field iconAlpha number
---@field iconSize number
---@field iconSpacing number
---@field trinketOnly boolean
---@field showOnAllies boolean
---@field showOnEnemies boolean
---@field targetOnly boolean
---@field showSelf boolean
---@field ignoreNameplateAlpha boolean
---@field ignoreNameplateScale boolean
---@field sortOrder "none" | "trinket-interrupt-other" | "interrupt-trinket-other" | "trinket-other" | "interrupt-other"
---@field enableGlow boolean
---@field instanceTypes InstanceTypes

---@class MySpellInfo : table
---@field enabled boolean
---@field spellName string
---@field spellIcon number
---@field spellDescription string
---@field cooldown number
---@field spellId number

---@class Database : table
---@field migrated boolean
---@field global GlobalTable
---@field spells table<number, MySpellInfo>

---@class AllCooldowns : table<number, number>
---@class MyCooldown : table<number, number>

--- @type fun(a: table<string, MySpellInfo>?, b: table<string, MySpellInfo>?): boolean
NS.SortSpellList = function(a, b)
  if a and b then
    local _, aSpellInfo = next(a)
    local _, bSpellInfo = next(b)
    local aSpellName = aSpellInfo.spellName
    local bSpellName = bSpellInfo.spellName
    if aSpellName and bSpellName then
      if aSpellName ~= bSpellName then
        return aSpellName < bSpellName
      end
    end
  end
  return false
end

--- @type AllCooldowns
local AllCooldowns = {}

--- @type table<string, MyCooldown>
local CDs = NS.CDs
for _, cds in pairs(CDs) do -- category, { [spellId] = cd }
  --- @type number, number
  for spellId, cd in pairs(cds) do -- spellId, cd
    AllCooldowns[spellId] = cd
  end
end
NS.AllCooldowns = AllCooldowns

--- @type Database
local DefaultDatabase = {
  migrated = false,
  global = {
    test = false,
    testNPCs = false,
    anchor = "BOTTOMLEFT",
    anchorTo = "TOPRIGHT",
    growDirection = "right",
    offsetX = 1,
    offsetY = 1,
    iconAlpha = 1,
    iconSize = 24,
    iconSpacing = 1,
    trinketOnly = true,
    showOnAllies = true,
    showOnEnemies = true,
    targetOnly = false,
    showSelf = false,
    ignoreNameplateAlpha = false,
    ignoreNameplateScale = false,
    sortOrder = NS.SORT_MODE_TRINKET_INTERRUPT_OTHER,
    enableGlow = true,
    instanceTypes = {
      arena = true,
      pvp = true,
      none = true,
    },
  },
  spells = {},
}
NS.DefaultDatabase = DefaultDatabase

--- @class OFFSET
--- @field x number The horizontal offset value from the global settings.
--- @field y number The vertical offset value from the global settings.
NS.OFFSET = {
  x = DefaultDatabase.global.offsetX,
  y = DefaultDatabase.global.offsetY,
}

--- @type table<number, MySpellInfo>
local spellList = {}

for spellId, cooldown in pairs(NS.AllCooldowns) do
  --- @type number
  local spid = spellId
  --- @type number
  local cd = cooldown

  local spellInfo = GetSpellInfo(spid)
  local spellDescription = GetSpellDescription(spid)
  if spellInfo and spellInfo.name then
    --- @type table<number, MySpellInfo>
    local spell = {
      [spid] = {
        cooldown = cd,
        enabled = true,
        spellId = spellInfo.spellID,
        spellIcon = spid == 336139 and 895886 or spellInfo.iconID,
        spellName = spellInfo.name,
        spellDescription = spellDescription,
      },
    }
    tinsert(spellList, spell)
  end
end
tsort(spellList, NS.SortSpellList)

for i = 1, #spellList do
  local spell = spellList[i]
  if spell then
    --- @type number, MySpellInfo
    local spellId, spellInfo = next(spell)
    NS.DefaultDatabase.spells[spellId] = {
      cooldown = spellInfo.cooldown,
      enabled = spellInfo.enabled,
      spellId = spellInfo.spellId,
      spellIcon = spellInfo.spellIcon,
      spellName = spellInfo.spellName,
      spellDescription = spellInfo.spellDescription,
    }
  end
end
