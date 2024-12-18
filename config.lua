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
  ["none"] = false, -- when outside an instance
  ["pvp"] = false, --  when in a battleground
  ["arena"] = false, -- when in an arena
  ["party"] = false, -- when in a 5-man instance
  ["raid"] = false, -- when in a raid instance
  ["scenario"] = false, -- when in a scenario
}

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
end

local AllCooldowns = {}
-- category, { [spellId] = cd }
for _, cds in pairs(NS.CDs) do
  -- spellId, cd
  for spellId, cd in pairs(cds) do
    AllCooldowns[spellId] = cd
  end
end
NS.AllCooldowns = AllCooldowns

local DefaultDatabase = {
  global = {
    test = false,
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
    targetOnly = false,
    showSelf = false,
    ignoreNameplateAlpha = false,
    ignoreNameplateScale = false,
    sortOrder = NS.SORT_MODE_TRINKET_INTERRUPT_OTHER,
    frameStrata = "HIGH",
    enableGlow = true,
    showEverywhere = false,
    instanceTypes = {
      unknown = false,
      none = true,
      pvp = true,
      arena = true,
      party = false,
      raid = false,
      scenario = false,
    },
  },
  spells = {},
}
NS.DefaultDatabase = DefaultDatabase

NS.OFFSET = {
  x = DefaultDatabase.global.offsetX,
  y = DefaultDatabase.global.offsetY,
}

local spellList = {}
for spellId, cooldown in pairs(AllCooldowns) do
  local spellInfo = GetSpellInfo(spellId)
  local spellDescription = GetSpellDescription(spellId)
  if spellInfo and spellInfo.name then
    local spell = {
      [spellId] = {
        cooldown = cooldown,
        enabled = true,
        spellId = spellInfo.spellID,
        spellIcon = spellId == 336139 and 895886 or spellInfo.iconID,
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
    local spellId, spellInfo = next(spell)
    local SPELL_ID = tostring(spellId)
    NS.DefaultDatabase.spells[SPELL_ID] = {
      cooldown = spellInfo.cooldown,
      enabled = spellInfo.enabled,
      spellId = spellInfo.spellId,
      spellIcon = spellInfo.spellIcon,
      spellName = spellInfo.spellName,
      spellDescription = spellInfo.spellDescription,
    }
  end
end
