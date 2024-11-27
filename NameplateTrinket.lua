local AddonName, NS = ...

local CreateFrame = CreateFrame
local IsInInstance = IsInInstance
local GetTime = GetTime
local UnitGUID = UnitGUID
local UnitIsUnit = UnitIsUnit
local UnitIsPlayer = UnitIsPlayer
local UnitIsFriend = UnitIsFriend
-- local UnitIsEnemy = UnitIsEnemy
-- local UnitCanAttack = UnitCanAttack
local UnitHealth = UnitHealth
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
-- local UnitReaction = UnitReaction
local UnitAffectingCombat = UnitAffectingCombat
local UnitExists = UnitExists
local issecure = issecure
local pairs = pairs
local ipairs = ipairs
local LibStub = LibStub
local next = next
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local select = select
local tostring = tostring
local tonumber = tonumber

local mceil = math.ceil
local mmax = math.max
local tinsert = table.insert
local tsort = table.sort
local twipe = table.wipe
local smatch = string.match
local bband = bit.band

local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
local GetNamePlates = C_NamePlate.GetNamePlates
local After = C_Timer.After
local IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local GetSpellInfo = C_Spell.GetSpellInfo
local GetSpellDescription = C_Spell.GetSpellDescription
-- local GetUnitTooltip = C_TooltipInfo.GetUnit
-- local GUIDIsPlayer = C_PlayerInfo.GUIDIsPlayer

local SpellTextureByID = NS.SpellTextureByID
local Interrupts = NS.Interrupts
local Trinkets = NS.Trinkets

local NameplateTrinket = {}
NS.NameplateTrinket = NameplateTrinket

AllCooldowns = NS.AllCooldowns

local NameplateTrinketFrame = CreateFrame("Frame", AddonName .. "Frame")
NameplateTrinketFrame:SetScript("OnEvent", function(_, event, ...)
  if NameplateTrinket[event] then
    NameplateTrinket[event](NameplateTrinket, ...)
  end
end)
NameplateTrinketFrame.TestModeActive = false
NameplateTrinketFrame.wasOnLoadingScreen = true
NameplateTrinketFrame.instanceType = nil
NameplateTrinketFrame.inArena = false
NameplateTrinketFrame.loaded = false
NameplateTrinketFrame.dbChanged = false
NS.NameplateTrinket.frame = NameplateTrinketFrame

-- local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE
local SPELL_PVPTRINKET = NS.SPELL_PVPTRINKET
local SPELL_PVPADAPTATION = NS.SPELL_PVPADAPTATION
local SPELL_RESET = NS.SPELL_RESET
local ICON_GROW_DIRECTION_LEFT = NS.ICON_GROW_DIRECTION_LEFT
local ICON_GROW_DIRECTION_RIGHT = NS.ICON_GROW_DIRECTION_RIGHT
local SORT_MODE_NONE = NS.SORT_MODE_NONE
local SORT_MODE_TRINKET_INTERRUPT_OTHER = NS.SORT_MODE_TRINKET_INTERRUPT_OTHER
local SORT_MODE_INTERRUPT_TRINKET_OTHER = NS.SORT_MODE_INTERRUPT_TRINKET_OTHER
local SORT_MODE_TRINKET_OTHER = NS.SORT_MODE_TRINKET_OTHER
local SORT_MODE_INTERRUPT_OTHER = NS.SORT_MODE_INTERRUPT_OTHER
local MinCdDuration = 0
local MaxCdDuration = 10 * 3600
local ShowCooldownAnimation = true
local InverseLogic = false
local TimerTextUseRelativeScale = true
local ShowInactiveCd = false
local TestFrame
local EventFrame
local spellIDs = {
  [378464] = 90,
  [20589] = 60,
  [354489] = 20,
}
local SpellsPerPlayerGUID = {}
local TestSpellsPerPlayerGUID = {}
local Nameplates = {}
local NameplatesVisible = {}
local Healers = {}
-- local HEALER_SPECS = {
--   ["Restoration Druid"] = 105,
--   ["Restoration Shaman"] = 264,
--   ["Mistweaver Monk"] = 270,
--   ["Holy Priest"] = 257,
--   ["Holy Paladin"] = 65,
--   ["Discipline Priest"] = 256,
--   ["Preservation Evoker"] = 1468,
-- }
local HEALER_SPELL_EVENTS = {
  ["SPELL_HEAL"] = true,
  ["SPELL_AURA_APPLIED"] = true,
  ["SPELL_CAST_START"] = true,
  ["SPELL_CAST_SUCCESS"] = true,
  ["SPELL_EMPOWER_START"] = true,
  ["SPELL_EMPOWER_END"] = true,
  ["SPELL_PERIODIC_HEAL"] = true,
}
local HEALER_SPELLS = {
  -- Holy Priest
  [2060] = "PRIEST", -- Heal
  [14914] = "PRIEST", -- Holy Fire
  [596] = "PRIEST", -- Prayer of Healing
  [204883] = "PRIEST", -- Circle of Healing
  [289666] = "PRIEST", -- Greater Heal
  -- Discipline Priest
  [47540] = "PRIEST", -- Penance
  [194509] = "PRIEST", -- Power Word: Radiance
  [214621] = "PRIEST", -- Schism
  [129250] = "PRIEST", -- Power Word: Solace
  [204197] = "PRIEST", -- Purge of the Wicked
  [314867] = "PRIEST", -- Shadow Covenant
  -- Druid
  [102351] = "DRUID", -- Cnenarion Ward
  [33763] = "DRUID", -- Nourish
  [81262] = "DRUID", -- Efflorescence
  [391888] = "DRUID", -- Adaptive Swarm -- Shared with Feral
  [392160] = "DRUID", -- Invigorate
  -- Shaman
  [61295] = "SHAMAN", -- Riptide
  [77472] = "SHAMAN", -- Healing Wave
  [73920] = "SHAMAN", -- Healing Rain
  [73685] = "SHAMAN", -- Unleash Life
  [207778] = "SHAMAN", -- Downpour
  -- Paladin
  [275773] = "PALADIN", -- Judgment
  [20473] = "PALADIN", -- Holy Shock
  [82326] = "PALADIN", -- Holy Light
  [85222] = "PALADIN", -- Light of Dawn
  [223306] = "PALADIN", -- Bestow Faith
  [214202] = "PALADIN", -- Rule of Law
  [210294] = "PALADIN", -- Divine Favor
  [114165] = "PALADIN", -- Holy Prism
  [148039] = "PALADIN", -- Barrier of Faith
  -- Monk
  [124682] = "MONK", -- Envelopping Mist
  [191837] = "MONK", -- Essence Font
  [115151] = "MONK", -- Renewing Mist
  [116680] = "MONK", -- Thunder Focus Tea
  [124081] = "MONK", -- Zen Pulse
  [209584] = "MONK", -- Zen Focus Tea
  [205234] = "MONK", -- Healing Sphere
  -- Evoker - Preservation
  [364343] = "EVOKER", -- Echo
  [382614] = "EVOKER", -- Dream Breath
  [366155] = "EVOKER", -- Reversion
  [382731] = "EVOKER", -- Spiritbloom
  [373861] = "EVOKER", -- Temporal Anomaly
}

local function GetSafeNameplateFrame(nameplate)
  if not nameplate then
    return nil
  end

  if not nameplate.UnitFrame then
    return nil
  end

  local frame = nameplate.UnitFrame

  if frame:IsForbidden() then
    return nil
  end

  if not frame.unit then
    return nil
  end

  if not smatch(frame.unit, "nameplate") then
    return nil
  end

  return frame
end

local function GetHealthBarFrame(nameplate)
  local frame = GetSafeNameplateFrame(nameplate)
  if frame then
    if frame.HealthBarsContainer then
      return frame.HealthBarsContainer.healthBar
    else
      return frame
    end
  end
  return nil
end

local CDSortFunctions = {
  [SORT_MODE_NONE] = function() end,
  [SORT_MODE_TRINKET_INTERRUPT_OTHER] = function(item1, item2)
    if Trinkets[item1.spellId] then
      if Trinkets[item2.spellId] then
        return item1.expires < item2.expires
      else
        return true
      end
    elseif Trinkets[item2.spellId] then
      return false
    elseif Interrupts[item1.spellId] then
      if Interrupts[item2.spellId] then
        return item1.expires < item2.expires
      else
        return true
      end
    elseif Interrupts[item2.spellId] then
      return false
    else
      return item1.expires < item2.expires
    end
  end,
  [SORT_MODE_INTERRUPT_TRINKET_OTHER] = function(item1, item2)
    if Interrupts[item1.spellId] then
      if Interrupts[item2.spellId] then
        return item1.expires < item2.expires
      else
        return true
      end
    elseif Interrupts[item2.spellId] then
      return false
    elseif Trinkets[item1.spellId] then
      if Trinkets[item2.spellId] then
        return item1.expires < item2.expires
      else
        return true
      end
    elseif Trinkets[item2.spellId] then
      return false
    else
      return item1.expires < item2.expires
    end
  end,
  [SORT_MODE_TRINKET_OTHER] = function(item1, item2)
    if Trinkets[item1.spellId] then
      if Trinkets[item2.spellId] then
        return item1.expires < item2.expires
      else
        return true
      end
    elseif Trinkets[item2.spellId] then
      return false
    else
      return item1.expires < item2.expires
    end
  end,
  [SORT_MODE_INTERRUPT_OTHER] = function(item1, item2)
    if Interrupts[item1.spellId] then
      if Interrupts[item2.spellId] then
        return item1.expires < item2.expires
      else
        return true
      end
    elseif Interrupts[item2.spellId] then
      return false
    else
      return item1.expires < item2.expires
    end
  end,
}

local function SortAuras(cds)
  local t = {}
  for _, spellInfo in pairs(cds) do
    if spellInfo ~= nil then
      t[#t + 1] = spellInfo
    end
  end
  tsort(t, CDSortFunctions[NS.db.global.sortOrder])
  return t
end

local function SetFrameSize(nameplate)
  local maxWidth, maxHeight = 0, 0
  if nameplate.nptIconFrame then
    for _, icon in pairs(nameplate.nptIcons) do
      if icon.shown then
        maxHeight = mmax(maxHeight, icon.frame:GetHeight())
        maxWidth = maxWidth + icon.frame:GetWidth() + NS.db.global.iconSpacing
      end
    end
    maxWidth = maxWidth - NS.db.global.iconSpacing
    maxHeight = maxHeight -- maxHeight - NS.db.global.iconSpacing
    nameplate.nptIconFrame:SetWidth(mmax(maxWidth, 1))
    nameplate.nptIconFrame:SetHeight(mmax(maxHeight, 1))
  end
end

local function SetTestFrameSize(nameplate)
  local maxWidth, maxHeight = 0, 0
  if nameplate.nptTestIconFrame then
    for _, icon in pairs(nameplate.nptTestIcons) do
      if icon.shown then
        maxHeight = mmax(maxHeight, icon.frame:GetHeight())
        maxWidth = maxWidth + icon.frame:GetWidth() + NS.db.global.iconSpacing
      end
    end
    maxWidth = maxWidth - NS.db.global.iconSpacing
    maxHeight = maxHeight -- maxHeight - NS.db.global.iconSpacing
    nameplate.nptTestIconFrame:SetWidth(mmax(maxWidth, 1))
    nameplate.nptTestIconFrame:SetHeight(mmax(maxHeight, 1))
  end
end

function HideIcon(icon, nameplate)
  icon.border:Hide()
  icon.borderState = nil
  if icon.cooldownText then
    icon.cooldownText:Hide()
  end
  icon.frame:Hide()
  icon.shown = false
  icon.textureID = 0
  if NS.db.global.enableGlow and icon.glowTexture then
    icon.glowTexture:Hide()
    icon.glowTexture = nil
    icon.glow = false
  end
  SetFrameSize(nameplate)
end

function HideTestIcon(icon, nameplate)
  icon.border:Hide()
  icon.borderState = nil
  if icon.cooldownText then
    icon.cooldownText:Hide()
  end
  icon.frame:Hide()
  icon.shown = false
  icon.textureID = 0
  if NS.db.global.enableGlow and icon.glowTexture then
    icon.glowTexture:Hide()
    icon.glowTexture = nil
    icon.glow = false
  end
  SetTestFrameSize(nameplate)
end

function ShowIcon(icon, nameplate)
  if icon.cooldownText then
    icon.cooldownText:Show()
  end
  local hideIcon = NS.db.global.trinketOnly and not Trinkets[icon.spellId]
  if hideIcon then
    icon.frame:Hide()
    icon.shown = false
  else
    icon.frame:Show()
    icon.shown = true
  end
  SetFrameSize(nameplate)
end

function ShowTestIcon(icon, nameplate)
  if icon.cooldownText then
    icon.cooldownText:Show()
  end
  local hideIcon = NS.db.global.trinketOnly and not Trinkets[icon.spellId]
  if hideIcon then
    icon.frame:Hide()
    icon.shown = false
  else
    icon.frame:Show()
    icon.shown = true
  end
  SetTestFrameSize(nameplate)
end

local function SetGlow(icon, spellId, isActive)
  local offsetMultiplier = 0.41
  local widthOffset = NS.db.global.iconSize * offsetMultiplier
  local heightOffset = NS.db.global.iconSize * offsetMultiplier

  if not icon.glowTexture then
    icon.glowTexture = icon.frame:CreateTexture(nil, "OVERLAY")
    icon.glowTexture:SetBlendMode("ADD")
    icon.glowTexture:SetAtlas("clickcast-highlight-spellbook")
    icon.glowTexture:SetDesaturated(true)
    icon.glowTexture:SetVertexColor(1, 0.69, 0, 0.5)
    icon.glowTexture:SetPoint("TOPLEFT", icon.frame, "TOPLEFT", -widthOffset, heightOffset)
    icon.glowTexture:SetPoint("BOTTOMRIGHT", icon.frame, "BOTTOMRIGHT", widthOffset, -heightOffset)
  end

  if isActive and Trinkets[spellId] then
    icon.glowTexture:Show()
    icon.glow = true
  elseif icon.glowTexture ~= nil then
    icon.glowTexture:Hide()
    icon.glowTexture = nil
    icon.glow = false
  end
end

local function SetBorder(icon, spellId, isActive)
  if isActive and Trinkets[spellId] then
    if icon.borderState ~= 2 then
      icon.border:SetVertexColor(1, 0.843, 0, 1)
      icon.border:Show()
      icon.borderState = 2
    end
  elseif icon.borderState ~= nil then
    icon.border:Hide()
    icon.borderState = nil
  end
end

local function SetTexture(icon, texture, isActive)
  local correctTexture = texture == nil and 134400 or texture
  if icon.textureID ~= correctTexture then
    icon.texture:SetTexture(correctTexture)
    icon.textureID = correctTexture
  end
  if icon.desaturation ~= not isActive then
    icon.texture:SetDesaturated(not isActive)
    icon.desaturation = not isActive
  end
end

local function PlaceIcon(nameplate, icon, iconIndex)
  icon.frame:ClearAllPoints()
  local index = iconIndex == nil and nameplate.nptIconCount or (iconIndex - 1)
  if index == 0 then
    if NS.db.global.growDirection == ICON_GROW_DIRECTION_RIGHT then
      icon.frame:SetPoint("LEFT", nameplate.nptIconFrame, "LEFT", 0, 0)
    elseif NS.db.global.growDirection == ICON_GROW_DIRECTION_LEFT then
      icon.frame:SetPoint("RIGHT", nameplate.nptIconFrame, "RIGHT", 0, 0)
    end
  else
    local previousIcon = nameplate.nptIcons[index]
    if NS.db.global.growDirection == ICON_GROW_DIRECTION_RIGHT then
      icon.frame:SetPoint("LEFT", previousIcon.frame, "RIGHT", NS.db.global.iconSpacing, 0)
    elseif NS.db.global.growDirection == ICON_GROW_DIRECTION_LEFT then
      icon.frame:SetPoint("RIGHT", previousIcon.frame, "LEFT", -NS.db.global.iconSpacing, 0)
    end
  end
end

local function PlaceTestIcon(nameplate, icon, iconIndex)
  icon.frame:ClearAllPoints()
  local index = iconIndex == nil and nameplate.nptTestIconCount or (iconIndex - 1)
  if index == 0 then
    if NS.db.global.growDirection == ICON_GROW_DIRECTION_RIGHT then
      icon.frame:SetPoint("LEFT", nameplate.nptTestIconFrame, "LEFT", 0, 0)
    elseif NS.db.global.growDirection == ICON_GROW_DIRECTION_LEFT then
      icon.frame:SetPoint("RIGHT", nameplate.nptTestIconFrame, "RIGHT", 0, 0)
    end
  else
    local previousIcon = nameplate.nptTestIcons[index]
    if NS.db.global.growDirection == ICON_GROW_DIRECTION_RIGHT then
      icon.frame:SetPoint("LEFT", previousIcon.frame, "RIGHT", NS.db.global.iconSpacing, 0)
    elseif NS.db.global.growDirection == ICON_GROW_DIRECTION_LEFT then
      icon.frame:SetPoint("RIGHT", previousIcon.frame, "LEFT", -NS.db.global.iconSpacing, 0)
    end
  end
end

local function SetCooldown(icon, remainingTime, started, cooldownLength, isActive)
  if icon.cooldownText then
    if remainingTime > 0 and (isActive or InverseLogic) then
      local text = (remainingTime >= 60) and (mceil(remainingTime / 60) .. "m") or mceil(remainingTime)
      if icon.text ~= text then
        icon.cooldownText:SetText(text)
        icon.text = text
        if not ShowCooldownAnimation or not isActive or InverseLogic then
          icon.cooldownText:SetParent(icon)
        else
          icon.cooldownText:SetParent(icon.cooldownFrame)
        end
      end
    elseif icon.text ~= "" then
      icon.cooldownText:SetText("")
      icon.text = ""
    end
  end

  -- cooldown animation
  if ShowCooldownAnimation and isActive then
    if started ~= icon.cooldownStarted or cooldownLength ~= icon.cooldownLength then
      icon.cooldownFrame:SetCooldown(started, cooldownLength)
      icon.cooldownFrame:Show()
      icon.cooldownStarted = started
      icon.cooldownLength = cooldownLength
    end
  else
    icon.cooldownFrame:Hide()
  end
end

local function SetTestCooldown(icon, remainingTime, started, cooldownLength, isActive)
  if icon.cooldownText then
    if remainingTime > 0 and (isActive or InverseLogic) then
      local text = (remainingTime >= 60) and (mceil(remainingTime / 60) .. "m") or mceil(remainingTime)
      if icon.text ~= text then
        icon.cooldownText:SetText(text)
        icon.text = text
        if not ShowCooldownAnimation or not isActive or InverseLogic then
          icon.cooldownText:SetParent(icon)
        else
          icon.cooldownText:SetParent(icon.cooldownFrame)
        end
      end
    elseif icon.text ~= "" then
      icon.cooldownText:SetText("")
      icon.text = ""
    end
  end

  -- cooldown animation
  if ShowCooldownAnimation and isActive then
    if started ~= icon.cooldownStarted or cooldownLength ~= icon.cooldownLength then
      icon.cooldownFrame:SetCooldown(started, cooldownLength)
      icon.cooldownFrame:Show()
      icon.cooldownStarted = started
      icon.cooldownLength = cooldownLength
    end
  else
    icon.cooldownFrame:Hide()
  end
end

-- frame = nameplate.UnitFrame
function CreateIcon(nameplate, spellId, index)
  local iconFrame =
    CreateFrame("Frame", AddonName .. "IconFrame" .. "Spell" .. spellId .. "Index" .. index, nameplate.nptIconFrame)
  local icon = {}
  icon.spellId = spellId

  iconFrame:SetWidth(NS.db.global.iconSize)
  iconFrame:SetHeight(NS.db.global.iconSize)
  iconFrame:SetAlpha(NS.db.global.iconAlpha)
  icon.frame = iconFrame
  PlaceIcon(nameplate, icon)
  iconFrame:Hide()

  icon.cooldownFrame = CreateFrame("Cooldown", nil, iconFrame, "CooldownFrameTemplate")
  icon.cooldownFrame:SetAllPoints(iconFrame)
  icon.cooldownFrame:SetReverse(true)

  icon.texture = iconFrame:CreateTexture(nil, "BORDER")
  icon.texture:SetAllPoints(iconFrame)
  icon.texture:SetTexCoord(0, 1, 0, 1)

  icon.border = iconFrame:CreateTexture(nil, "OVERLAY")
  icon.border:SetAllPoints(iconFrame)
  icon.border:SetTexture("Interface\\AddOns\\NameplateTrinket\\CooldownFrameBorder.tga")
  icon.border:SetVertexColor(1, 0.35, 0)
  icon.border:Hide()

  local loadedOrLoading, loaded = IsAddOnLoaded("OmniCC")
  if not loaded and not loadedOrLoading then
    icon.cooldownFrame:SetHideCountdownNumbers(true)

    local fontScale = 1
    local timerScale = NS.db.global.iconSize - NS.db.global.iconSize / 2
    local timerTextSize = mceil(timerScale)

    icon.cooldownText = icon.frame:CreateFontString(nil, "OVERLAY")
    icon.cooldownText:SetTextColor(0.7, 1, 0, 1)
    icon.cooldownText:SetPoint("CENTER", icon.frame, "CENTER", 0, 0)
    if TimerTextUseRelativeScale then
      icon.cooldownText:SetFont("Fonts\\FRIZQT__.TTF", mceil(timerScale * fontScale), "OUTLINE")
    else
      icon.cooldownText:SetFont("Fonts\\FRIZQT__.TTF", timerTextSize, "OUTLINE")
    end
  else
    icon.cooldownText = nil
  end

  nameplate.nptIconCount = nameplate.nptIconCount + 1
  tinsert(nameplate.nptIcons, icon)
end

-- frame = nameplate.UnitFrame
function CreateTestIcon(nameplate, spellId, index)
  local iconFrame = CreateFrame(
    "Frame",
    AddonName .. "TestIconFrame" .. "Spell" .. spellId .. "Index" .. index,
    nameplate.nptTestIconFrame
  )
  local icon = {}
  icon.spellId = spellId

  iconFrame:SetWidth(NS.db.global.iconSize)
  iconFrame:SetHeight(NS.db.global.iconSize)
  iconFrame:SetAlpha(NS.db.global.iconAlpha)
  icon.frame = iconFrame
  PlaceTestIcon(nameplate, icon)
  iconFrame:Hide()

  icon.cooldownFrame = CreateFrame("Cooldown", nil, iconFrame, "CooldownFrameTemplate")
  icon.cooldownFrame:SetAllPoints(iconFrame)
  icon.cooldownFrame:SetReverse(true)

  icon.texture = iconFrame:CreateTexture(nil, "BORDER")
  icon.texture:SetAllPoints(iconFrame)
  icon.texture:SetTexCoord(0, 1, 0, 1)

  icon.border = iconFrame:CreateTexture(nil, "OVERLAY")
  icon.border:SetAllPoints(iconFrame)
  icon.border:SetTexture("Interface\\AddOns\\NameplateTrinket\\CooldownFrameBorder.tga")
  icon.border:SetVertexColor(1, 0.35, 0)
  icon.border:Hide()

  local loadedOrLoading, loaded = IsAddOnLoaded("OmniCC")
  if not loaded and not loadedOrLoading then
    icon.cooldownFrame:SetHideCountdownNumbers(true)

    local fontScale = 1
    local timerScale = NS.db.global.iconSize - NS.db.global.iconSize / 2
    local timerTextSize = mceil(timerScale)

    icon.cooldownText = icon.frame:CreateFontString(nil, "OVERLAY")
    icon.cooldownText:SetTextColor(0.7, 1, 0, 1)
    icon.cooldownText:SetPoint("CENTER", icon.frame, "CENTER", 0, 0)
    if TimerTextUseRelativeScale then
      icon.cooldownText:SetFont("Fonts\\FRIZQT__.TTF", mceil(timerScale * fontScale), "OUTLINE")
    else
      icon.cooldownText:SetFont("Fonts\\FRIZQT__.TTF", timerTextSize, "OUTLINE")
    end
  else
    icon.cooldownText = nil
  end

  nameplate.nptTestIconCount = nameplate.nptTestIconCount + 1
  tinsert(nameplate.nptTestIcons, icon)
end

local function FilterSpell(dbInfo, remainingTime, isActive)
  if not dbInfo or not dbInfo.enabled then
    return false
  end

  if not ShowInactiveCd and not isActive then
    return false
  end

  if tonumber(dbInfo.cooldown) <= 0 then
    return false
  end

  if remainingTime > 0 and (remainingTime < MinCdDuration or remainingTime > MaxCdDuration) then
    return false
  end

  return true
end

local function addIcons(nameplate, guid)
  if not nameplate.nptIconCount then
    return
  end

  local counter = 1
  if SpellsPerPlayerGUID[guid] then
    local currentTime = GetTime()
    local sortedCDs = SortAuras(SpellsPerPlayerGUID[guid])
    for index, spellInfo in pairs(sortedCDs) do
      local spellId = spellInfo.spellId
      local isActive = spellInfo.expires > currentTime
      if InverseLogic then
        isActive = not isActive
      end
      local dbInfo = NS.db.spells[tostring(spellId)]
      local remainingTime = spellInfo.expires - currentTime
      if FilterSpell(dbInfo, remainingTime, isActive) then
        if counter > nameplate.nptIconCount then
          CreateIcon(nameplate, spellId, index)
        end
        local icon = nameplate.nptIcons[counter]
        SetTexture(icon, spellInfo.texture, isActive)
        SetBorder(icon, spellId, isActive)
        if NS.db.global.enableGlow and Trinkets[spellId] then
          SetGlow(icon, spellId, isActive)
        end
        SetCooldown(icon, remainingTime, spellInfo.started, spellInfo.duration, isActive)
        if not icon.shown then
          ShowIcon(icon, nameplate)
        end
        counter = counter + 1
      end
    end
  end

  for k = counter, nameplate.nptIconCount do
    local icon = nameplate.nptIcons[k]
    if icon.shown then
      HideIcon(icon, nameplate)
    end
  end
end

local function addTestIcons(nameplate, guid)
  if not nameplate.nptTestIconCount then
    return
  end

  local counter = 1
  if TestSpellsPerPlayerGUID[guid] then
    local currentTime = GetTime()
    local sortedCDs = SortAuras(TestSpellsPerPlayerGUID[guid])
    for index, spellInfo in ipairs(sortedCDs) do
      local spellId = spellInfo.spellId
      local isActive = spellInfo.expires > currentTime
      if InverseLogic then
        isActive = not isActive
      end
      local dbInfo = NS.db.spells[tostring(spellId)]
      -- We create a copy of dbInfo to avoid modifying the users settings just for testing
      local dbInfoCopy
      if not dbInfo then
        local fallBackInfo = GetSpellInfo(spellId)
        local spellDescription = GetSpellDescription(spellId)
        if fallBackInfo then
          dbInfoCopy = {
            cooldown = AllCooldowns[fallBackInfo.spellID],
            enabled = true,
            spellId = fallBackInfo.spellID,
            spellIcon = fallBackInfo.iconID,
            spellName = fallBackInfo.name,
            spellDescription = spellDescription or "",
          }
        end
      else
        dbInfoCopy = {
          cooldown = dbInfo.cooldown,
          enabled = true,
          spellId = dbInfo.spellId,
          spellIcon = dbInfo.spellIcon,
          spellName = dbInfo.spellName,
          spellDescription = dbInfo.spellDescription,
        }
      end
      local remainingTime = spellInfo.expires - currentTime
      if FilterSpell(dbInfoCopy, remainingTime, isActive) then
        if counter > nameplate.nptTestIconCount then
          CreateTestIcon(nameplate, spellId, index)
        end
        local icon = nameplate.nptTestIcons[counter]
        SetTexture(icon, spellInfo.texture, isActive)
        SetBorder(icon, spellId, isActive)
        if NS.db.global.enableGlow and Trinkets[spellId] then
          SetGlow(icon, spellId, isActive)
        end
        SetTestCooldown(icon, remainingTime, spellInfo.started, spellInfo.duration, isActive)
        if not icon.shown then
          ShowTestIcon(icon, nameplate)
        end
        counter = counter + 1
      end
    end
  end

  for k = counter, nameplate.nptTestIconCount do
    local icon = nameplate.nptTestIcons[k]
    if icon.shown then
      HideTestIcon(icon, nameplate)
    end
  end
end

local function addNameplateIcons(nameplate, guid)
  if not nameplate.namePlateUnitToken then
    return
  end

  local unit = nameplate.namePlateUnitToken

  --[[
  -- local r = UnitReaction("player", unit)
  -- if r then
  --   return r < 5 and "hostile" or "friendly"
  -- end
  ]]
  -- local reaction = UnitReaction(unit, "player")
  -- local isEnemy = (reaction and reaction < 4) and not isSelf
  -- local isNeutral = (reaction and reaction == 4) and not isSelf
  -- local isFriend = (reaction and reaction >= 5) and not isSelf

  local isPlayer = UnitIsPlayer(unit)
  local isNpc = not isPlayer
  local isSelf = UnitIsUnit(unit, "player")
  local isFriend = UnitIsFriend("player", unit)
  -- local isEnemy = UnitIsEnemy("player", unit)
  -- local canAttack = UnitCanAttack("player", unit)
  -- local isHealer = NS.isHealer("player") or Healers[guid] and true or false
  local isDeadOrGhost = UnitIsDeadOrGhost(unit)
  local isAlive = not isDeadOrGhost and UnitHealth(unit) >= 1
  local hideDead = not isAlive
  local isTarget = UnitIsUnit(unit, "target")
  local targetExists = UnitExists("target")
  local targetIsUnit = targetExists and isTarget
  local hideNonTargets = NS.db.global.targetOnly and (not targetExists or not targetIsUnit)
  local hideAllies = not NS.db.global.showOnAllies and isFriend
  local hideOnSelf = not NS.db.global.showSelf and isSelf
  local hideInstanceTypes = not NS.db.global.showEverywhere
    and not NS.INSTANCE_TYPES[NameplateTrinketFrame.instanceType]
  local hideNPCs = isNpc
  local hideDuringTestMode = NS.db.global.test and not IsInInstance()
  local hideIcons = hideDuringTestMode
    or hideNPCs
    or hideOnSelf
    or hideDead
    or hideAllies
    or hideNonTargets
    or hideInstanceTypes

  if hideIcons then
    if nameplate.nptIconFrame then
      nameplate.nptIconFrame:Hide()
    end
    return
  end

  if not nameplate.nptIconFrame then
    nameplate.nptIconFrame = CreateFrame("Frame", nil, nameplate.rbgdAnchorFrame)
    nameplate.nptIconFrame:SetIgnoreParentAlpha(NS.db.global.ignoreNameplateAlpha)
    nameplate.nptIconFrame:SetIgnoreParentScale(NS.db.global.ignoreNameplateScale)
    nameplate.nptIconFrame:SetWidth(NS.db.global.iconSize)
    nameplate.nptIconFrame:SetHeight(NS.db.global.iconSize)
    nameplate.nptIconFrame:SetFrameStrata(NS.db.global.frameStrata)
    nameplate.nptIconFrame:ClearAllPoints()
    local frame = GetSafeNameplateFrame(nameplate)
    local anchorFrame = frame and frame.healthBar or nameplate
    -- Anchor -- Frame -- To Frame's -- offsetsX -- offsetsY
    nameplate.nptIconFrame:SetPoint(
      NS.db.global.anchor,
      anchorFrame,
      NS.db.global.anchorTo,
      NS.db.global.offsetX,
      NS.db.global.offsetY
    )
    nameplate.nptIconFrame:SetScale(1)
    nameplate.nptIcons = {}
    nameplate.nptIconCount = 0
  end

  if NameplateTrinketFrame.dbChanged then
    nameplate.nptIconFrame:SetIgnoreParentAlpha(NS.db.global.ignoreNameplateAlpha)
    nameplate.nptIconFrame:SetIgnoreParentScale(NS.db.global.ignoreNameplateScale)
    nameplate.nptIconFrame:SetWidth(NS.db.global.iconSize)
    nameplate.nptIconFrame:SetHeight(NS.db.global.iconSize)
    nameplate.nptIconFrame:SetFrameStrata(NS.db.global.frameStrata)
    nameplate.nptIconFrame:ClearAllPoints()
    local frame = GetSafeNameplateFrame(nameplate)
    local anchorFrame = frame and frame.healthBar or nameplate
    -- Anchor -- Frame -- To Frame's -- offsetsX -- offsetsY
    nameplate.nptIconFrame:SetPoint(
      NS.db.global.anchor,
      anchorFrame,
      NS.db.global.anchorTo,
      NS.db.global.offsetX,
      NS.db.global.offsetY
    )
  end

  addIcons(nameplate, guid)

  nameplate.nptIconFrame:Show()
end
NS.addNameplateIcons = addNameplateIcons

local function addNameplateTestIcons(nameplate, guid)
  if not nameplate.namePlateUnitToken then
    return
  end

  local unit = nameplate.namePlateUnitToken

  --[[
  -- local r = UnitReaction("player", unit)
  -- if r then
  --   return r < 5 and "hostile" or "friendly"
  -- end
  ]]
  -- local reaction = UnitReaction(unit, "player")
  -- local isEnemy = (reaction and reaction < 4) and not isSelf
  -- local isNeutral = (reaction and reaction == 4) and not isSelf
  -- local isFriend = (reaction and reaction >= 5) and not isSelf

  local isPlayer = UnitIsPlayer(unit)
  local isNpc = not isPlayer
  local isSelf = UnitIsUnit(unit, "player")
  local isFriend = UnitIsFriend("player", unit)
  -- local isEnemy = UnitIsEnemy("player", unit)
  -- local canAttack = UnitCanAttack("player", unit)
  -- local isHealer = NS.isHealer("player") or Healers[guid] and true or false
  local isDeadOrGhost = UnitIsDeadOrGhost(unit)
  local isAlive = not isDeadOrGhost and UnitHealth(unit) >= 1
  local hideDead = not isAlive
  local isTarget = UnitIsUnit(unit, "target")
  local targetExists = UnitExists("target")
  local targetIsUnit = targetExists and isTarget
  local hideNonTargets = NS.db.global.targetOnly and (not targetExists or not targetIsUnit)
  local hideAllies = not NS.db.global.showOnAllies and isFriend
  local hideOnSelf = not NS.db.global.showSelf and isSelf
  local hideInstanceTypes = not NS.db.global.showEverywhere
    and not NS.INSTANCE_TYPES[NameplateTrinketFrame.instanceType]
  local hideNPCs = isNpc
  local hideDuringTestMode = not NS.db.global.test or IsInInstance()
  local hideIcons = hideDuringTestMode
    or hideNPCs
    or hideOnSelf
    or hideDead
    or hideAllies
    or hideNonTargets
    or hideInstanceTypes

  if hideIcons then
    if nameplate.nptTestIconFrame then
      nameplate.nptTestIconFrame:Hide()
    end
    return
  end

  if not nameplate.nptTestIconFrame then
    nameplate.nptTestIconFrame = CreateFrame("Frame", nil, nameplate.rbgdAnchorFrame)
    nameplate.nptTestIconFrame:SetIgnoreParentAlpha(NS.db.global.ignoreNameplateAlpha)
    nameplate.nptTestIconFrame:SetIgnoreParentScale(NS.db.global.ignoreNameplateScale)
    nameplate.nptTestIconFrame:SetWidth(NS.db.global.iconSize)
    nameplate.nptTestIconFrame:SetHeight(NS.db.global.iconSize)
    nameplate.nptTestIconFrame:SetFrameStrata(NS.db.global.frameStrata)
    nameplate.nptTestIconFrame:SetScale(1)
    nameplate.nptTestIconFrame:ClearAllPoints()
    local frame = GetSafeNameplateFrame(nameplate)
    local anchorFrame = frame and frame.healthBar or nameplate
    -- Anchor -- Frame -- To Frame's -- offsetsX -- offsetsY
    nameplate.nptTestIconFrame:SetPoint(
      NS.db.global.anchor,
      anchorFrame,
      NS.db.global.anchorTo,
      NS.db.global.offsetX,
      NS.db.global.offsetY
    )
    nameplate.nptTestIcons = {}
    nameplate.nptTestIconCount = 0
  end

  if NameplateTrinketFrame.dbChanged then
    nameplate.nptTestIconFrame:SetIgnoreParentAlpha(NS.db.global.ignoreNameplateAlpha)
    nameplate.nptTestIconFrame:SetIgnoreParentScale(NS.db.global.ignoreNameplateScale)
    nameplate.nptTestIconFrame:SetWidth(NS.db.global.iconSize)
    nameplate.nptTestIconFrame:SetHeight(NS.db.global.iconSize)
    nameplate.nptTestIconFrame:SetFrameStrata(NS.db.global.frameStrata)
    local frame = GetSafeNameplateFrame(nameplate)
    local anchorFrame = frame and frame.healthBar or nameplate
    -- Anchor -- Frame -- To Frame's -- offsetsX -- offsetsY
    nameplate.nptTestIconFrame:SetPoint(
      NS.db.global.anchor,
      anchorFrame,
      NS.db.global.anchorTo,
      NS.db.global.offsetX,
      NS.db.global.offsetY
    )
  end

  addTestIcons(nameplate, guid)

  nameplate.nptTestIconFrame:Show()
end
NS.addNameplateTestIcons = addNameplateTestIcons

local function refreshNameplates(override)
  if not override and NameplateTrinketFrame.wasOnLoadingScreen then
    return
  end

  for _, nameplate in pairs(GetNamePlates(issecure())) do
    if nameplate and nameplate.namePlateUnitToken then
      local guid = UnitGUID(nameplate.namePlateUnitToken)

      if guid then
        NameplateTrinket:attachToNameplate(nameplate, guid)
      end
    end
  end
end

function NS.RefreshTestSpells()
  local currentTime = GetTime()
  for nameplate, guid in pairs(NameplatesVisible) do
    if nameplate and guid then
      if not TestSpellsPerPlayerGUID[guid] then
        TestSpellsPerPlayerGUID[guid] = {}
      end
      if not TestSpellsPerPlayerGUID[guid][SPELL_PVPTRINKET] then
        TestSpellsPerPlayerGUID[guid][SPELL_PVPTRINKET] = {
          ["spellId"] = SPELL_PVPTRINKET,
          ["expires"] = currentTime + (Healers[guid] and 90 or 120),
          ["texture"] = NS.db.spells[tostring(SPELL_PVPTRINKET)] and NS.db.spells[tostring(SPELL_PVPTRINKET)].spellIcon
            or SpellTextureByID[SPELL_PVPTRINKET],
          ["duration"] = (Healers[guid] and 90 or 120),
          ["started"] = currentTime,
        }
      else
        if currentTime - TestSpellsPerPlayerGUID[guid][SPELL_PVPTRINKET].expires > 0 then
          TestSpellsPerPlayerGUID[guid][SPELL_PVPTRINKET] = {
            ["spellId"] = SPELL_PVPTRINKET,
            ["expires"] = currentTime + (Healers[guid] and 90 or 120),
            ["texture"] = NS.db.spells[tostring(SPELL_PVPTRINKET)]
                and NS.db.spells[tostring(SPELL_PVPTRINKET)].spellIcon
              or SpellTextureByID[SPELL_PVPTRINKET],
            ["duration"] = (Healers[guid] and 90 or 120),
            ["started"] = currentTime,
          }
        end
      end
      if not NS.db.global.trinketOnly then
        for spellId, cd in pairs(spellIDs) do
          if not TestSpellsPerPlayerGUID[guid][spellId] then
            TestSpellsPerPlayerGUID[guid][spellId] = {
              ["spellId"] = spellId,
              ["expires"] = currentTime + cd,
              ["texture"] = NS.db.spells[tostring(spellId)] and NS.db.spells[tostring(spellId)].spellIcon
                or SpellTextureByID[spellId],
              ["duration"] = cd,
              ["started"] = currentTime,
            }
          else
            if currentTime - TestSpellsPerPlayerGUID[guid][spellId].expires > 0 then
              TestSpellsPerPlayerGUID[guid][spellId] = {
                ["spellId"] = spellId,
                ["expires"] = currentTime + cd,
                ["texture"] = NS.db.spells[tostring(spellId)] and NS.db.spells[tostring(spellId)].spellIcon
                  or SpellTextureByID[spellId],
                ["duration"] = cd,
                ["started"] = currentTime,
              }
            end
          end
        end
      end
      addNameplateTestIcons(nameplate, guid)
    end
  end
end

function NS.DisableTestMode()
  NameplateTrinketFrame.TestModeActive = false
  NameplateTrinketFrame:UnregisterEvent("PLAYER_LOGOUT")
  TestFrame:SetScript("OnUpdate", nil)
  twipe(TestSpellsPerPlayerGUID)
  for nameplate in pairs(Nameplates) do
    if nameplate and nameplate.nptTestIconFrame then
      nameplate.nptTestIconFrame:Hide()
      nameplate.nptTestIconFrame = nil
      nameplate.nptTestIcons = {}
      nameplate.nptTestIconCount = 0
    end
  end
end

function NameplateTrinket:PLAYER_LOGOUT()
  if NS.db.global.test and TestFrame then
    NS.DisableTestMode()
  end
end

function NS.EnableTestMode()
  NameplateTrinketFrame.TestModeActive = true
  NameplateTrinketFrame:RegisterEvent("PLAYER_LOGOUT")
  twipe(TestSpellsPerPlayerGUID)
  NS.RefreshTestSpells()
  if not TestFrame then
    TestFrame = CreateFrame("Frame")
  end
  local timeElapsed = 0
  TestFrame:SetScript("OnUpdate", function(_, elapsed)
    timeElapsed = timeElapsed + elapsed
    if timeElapsed >= 1 then
      NS.RefreshTestSpells()
      timeElapsed = 0
    end
  end)
end

function ReallocateIcons(clearSpells)
  for nameplate in pairs(Nameplates) do
    if nameplate and nameplate.nptIconFrame then
      nameplate.nptIconFrame:SetIgnoreParentAlpha(NS.db.global.ignoreNameplateAlpha)
      nameplate.nptIconFrame:SetIgnoreParentScale(NS.db.global.ignoreNameplateScale)
      nameplate.nptIconFrame:ClearAllPoints()
      local frame = GetSafeNameplateFrame(nameplate)
      local anchorFrame = frame and frame.healthBar or nameplate
      nameplate.nptIconFrame:SetPoint(
        NS.db.global.anchor,
        anchorFrame,
        NS.db.global.anchorTo,
        NS.db.global.offsetX,
        NS.db.global.offsetY
      )
      local counter = 0
      for index, icon in pairs(nameplate.nptIcons) do
        icon.frame:SetWidth(NS.db.global.iconSize)
        icon.frame:SetHeight(NS.db.global.iconSize)
        icon.frame:SetAlpha(NS.db.global.iconAlpha)
        PlaceIcon(nameplate, icon, index)
        icon.texture:SetTexCoord(0, 1, 0, 1)
        if icon.cooldownText then
          icon.cooldownText:SetTextColor(0.7, 1, 0, 1)
          icon.cooldownText:ClearAllPoints()
          icon.cooldownText:SetPoint("CENTER", icon.frame, "CENTER", 0, 0)

          local fontScale = 1
          local timerScale = NS.db.global.iconSize - NS.db.global.iconSize / 2
          local timerTextSize = mceil(timerScale)

          if TimerTextUseRelativeScale then
            icon.cooldownText:SetFont("Fonts\\FRIZQT__.TTF", mceil(timerScale * fontScale), "OUTLINE")
          else
            icon.cooldownText:SetFont("Fonts\\FRIZQT__.TTF", timerTextSize, "OUTLINE")
          end
        end
        if clearSpells then
          HideIcon(icon, nameplate)
        end
        counter = counter + 1
      end
      SetTestFrameSize(nameplate)
    end
  end
  if clearSpells then
    for nameplate, guid in pairs(NameplatesVisible) do
      if nameplate and guid then
        addNameplateIcons(nameplate, guid)
      end
    end
  end
end

function ReallocateTestIcons(clearSpells)
  for nameplate in pairs(Nameplates) do
    if nameplate and nameplate.nptTestIconFrame then
      nameplate.nptTestIconFrame:SetIgnoreParentAlpha(NS.db.global.ignoreNameplateAlpha)
      nameplate.nptTestIconFrame:SetIgnoreParentScale(NS.db.global.ignoreNameplateScale)
      nameplate.nptTestIconFrame:ClearAllPoints()
      local frame = GetSafeNameplateFrame(nameplate)
      local anchorFrame = frame and frame.healthBar or nameplate
      nameplate.nptTestIconFrame:SetPoint(
        NS.db.global.anchor,
        anchorFrame,
        NS.db.global.anchorTo,
        NS.db.global.offsetX,
        NS.db.global.offsetY
      )
      local counter = 0
      for index, icon in pairs(nameplate.nptTestIcons) do
        icon.frame:SetWidth(NS.db.global.iconSize)
        icon.frame:SetHeight(NS.db.global.iconSize)
        icon.frame:SetAlpha(NS.db.global.iconAlpha)
        PlaceTestIcon(nameplate, icon, index)
        icon.texture:SetTexCoord(0, 1, 0, 1)
        if icon.cooldownText then
          icon.cooldownText:SetTextColor(0.7, 1, 0, 1)
          icon.cooldownText:ClearAllPoints()
          icon.cooldownText:SetPoint("CENTER", icon.frame, "CENTER", 0, 0)

          local fontScale = 1
          local timerScale = NS.db.global.iconSize - NS.db.global.iconSize / 2
          local timerTextSize = mceil(timerScale)

          if TimerTextUseRelativeScale then
            icon.cooldownText:SetFont("Fonts\\FRIZQT__.TTF", mceil(timerScale * fontScale), "OUTLINE")
          else
            icon.cooldownText:SetFont("Fonts\\FRIZQT__.TTF", timerTextSize, "OUTLINE")
          end
        end
        if clearSpells then
          HideTestIcon(icon, nameplate)
        end
        counter = counter + 1
      end
      SetTestFrameSize(nameplate)
    end
  end
  if clearSpells then
    for nameplate, guid in pairs(NameplatesVisible) do
      if nameplate and guid then
        addNameplateTestIcons(nameplate, guid)
      end
    end
  end
end

-- frame = nameplate.UnitFrame
function NameplateTrinket:detachFromNameplate(nameplate)
  NameplatesVisible[nameplate] = nil

  if nameplate.nptTestIconFrame ~= nil then
    nameplate.nptTestIconFrame:Hide()
  end
  if nameplate.nptIconFrame ~= nil then
    nameplate.nptIconFrame:Hide()
  end
end

-- frame = nameplate.UnitFrame
function NameplateTrinket:attachToNameplate(nameplate, guid)
  NameplatesVisible[nameplate] = guid

  if not Nameplates[nameplate] then
    Nameplates[nameplate] = true
  end

  if nameplate.nptTestIconFrame ~= nil then
    nameplate.nptTestIconFrame:Show()
  end
  if nameplate.nptIconFrame ~= nil then
    nameplate.nptIconFrame:Show()
  end

  if not nameplate.rbgdAnchorFrame then
    local attachmentFrame = GetHealthBarFrame(nameplate)
    if attachmentFrame then
      nameplate.rbgdAnchorFrame = CreateFrame("Frame", nil, attachmentFrame)
    end
  end

  addNameplateIcons(nameplate, guid)
  if NS.db.global.test and not IsInInstance() then
    addNameplateTestIcons(nameplate, guid)
  end
end

-- unitId == unitToken, UnitGUID takes unitId, formely unitToken, as its param
function NameplateTrinket:NAME_PLATE_UNIT_REMOVED(unitToken)
  if not unitToken then
    return
  end

  local nameplate = GetNamePlateForUnit(unitToken, issecure())

  if nameplate then
    self:detachFromNameplate(nameplate)
  end
end

-- UnitIsPlayer takes unitToken
-- C_PlayerInfo.GUIDIsPlayer takes unitGUID
function NameplateTrinket:NAME_PLATE_UNIT_ADDED(unitToken)
  if not unitToken then
    return
  end

  local nameplate = GetNamePlateForUnit(unitToken, issecure())
  local guid = UnitGUID(unitToken)

  if nameplate and guid then
    self:attachToNameplate(nameplate, guid)
  end
end

function NameplateTrinket:PLAYER_TARGET_CHANGED()
  ReallocateIcons(true)
  if NS.db.global.test and not IsInInstance() then
    ReallocateTestIcons(true)
  end
end

--[[
1. timestamp: number
2. subevent: string
3. hideCaster: boolean
4. sourceGUID: string
5. sourceName: string
6. sourceFlags: number
7. sourceRaidFlags: number
8. destGUID: string
9. destName: string
10. destFlags: number
11. destRaidFlags: number
-- extra for certain subevent types
12. spellId: number
13. spellName: string
14. spellSchool: string
15. auraType: string
--]]
function NameplateTrinket:COMBAT_LOG_EVENT_UNFILTERED()
  local hideDuringTestMode = NS.db.global.test and not IsInInstance()
  if hideDuringTestMode then
    return
  end
  local hideInstanceTypes = not NS.db.global.showEverywhere
    and not NS.INSTANCE_TYPES[NameplateTrinketFrame.instanceType]
  if hideInstanceTypes then
    return
  end
  local _, subevent, _, sourceGUID, _, sourceFlags, _, destGUID, _, _, _ = CombatLogGetCurrentEventInfo()
  if not (sourceGUID or destGUID) then
    return
  end
  local hideForSelf = not NS.db.global.showSelf and sourceGUID == UnitGUID("player")
  if hideForSelf then
    return
  end
  -- @TODO: don't want to deal with Mind Controlled players right now since they become pets
  -- local isPlayer = bband(sourceFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0
  -- if not isPlayer then
  --   return
  -- end
  local spellId = select(12, CombatLogGetCurrentEventInfo())
  if spellId then
    if HEALER_SPELL_EVENTS[subevent] and HEALER_SPELLS[spellId] then
      if not Healers[sourceGUID] then
        Healers[sourceGUID] = true
      end
    end
    if bband(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= 0 or (NS.db.global.showOnAllies == true) then
      local entry = NS.db.spells[tostring(spellId)]
      if entry ~= nil and entry.enabled then
        local cooldown = tonumber(entry.cooldown)
        if cooldown ~= nil and cooldown > 0 then
          local trackTrinketOnly = NS.db.global.trinketOnly and not Trinkets[spellId]
          if trackTrinketOnly then
            return
          end
          if
            subevent == "SPELL_CAST_SUCCESS"
            or subevent == "SPELL_AURA_APPLIED"
            or subevent == "SPELL_MISSED"
            or subevent == "SPELL_SUMMON"
          then
            local currentTime = GetTime()
            local expires = currentTime + cooldown
            local texture = entry.spellIcon
            if not SpellsPerPlayerGUID[sourceGUID] then
              SpellsPerPlayerGUID[sourceGUID] = {}
            end
            SpellsPerPlayerGUID[sourceGUID][spellId] = {
              ["spellId"] = spellId,
              ["expires"] = expires,
              ["texture"] = texture,
              ["duration"] = cooldown,
              ["started"] = currentTime,
            }
            -- // pvptier 1/2 used, correcting cd of PvP trinket
            if
              spellId == SPELL_PVPADAPTATION
              and NS.db.spells[SPELL_PVPTRINKET] ~= nil
              and NS.db.spells[SPELL_PVPTRINKET].enabled
            then
              local existingEntry = SpellsPerPlayerGUID[sourceGUID][SPELL_PVPTRINKET]
              if existingEntry then
                existingEntry.expires = currentTime + 60
                existingEntry.duration = currentTime + 60
              end
            -- caster is a healer, reducing cd of pvp trinket
            elseif
              spellId == SPELL_PVPTRINKET
              and NS.db.spells[SPELL_PVPTRINKET] ~= nil
              and NS.db.spells[SPELL_PVPTRINKET].enabled
              and Healers[sourceGUID]
            then
              local existingEntry = SpellsPerPlayerGUID[sourceGUID][SPELL_PVPTRINKET]
              if existingEntry then
                existingEntry.expires = existingEntry.expires - 30
                existingEntry.duration = existingEntry.duration - 30
              end
            end
            for nameplate, guid in pairs(NameplatesVisible) do
              if nameplate and guid and guid == sourceGUID then
                addNameplateIcons(nameplate, guid)
                break
              end
            end
          end
        end
      end
      -- reset
      if subevent == "SPELL_AURA_APPLIED" and spellId == SPELL_RESET then
        if SpellsPerPlayerGUID[sourceGUID] then
          SpellsPerPlayerGUID[sourceGUID] = {}
          for nameplate, guid in pairs(NameplatesVisible) do
            if nameplate and guid and guid == sourceGUID then
              addNameplateIcons(nameplate, guid)
            end
          end
        end
      end
    end
  end
end

local ShuffleFrame = CreateFrame("Frame")
ShuffleFrame.eventRegistered = false

function NameplateTrinket:PLAYER_REGEN_ENABLED()
  NameplateTrinketFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
  ShuffleFrame.eventRegistered = false
  refreshNameplates()
end

function NameplateTrinket:GROUP_ROSTER_UPDATE()
  if not NameplateTrinketFrame.inArena then
    return
  end

  local name = AuraUtil.FindAuraByName("Arena Preparation", "player", "HELPFUL")
  if not name then
    return
  end

  if UnitAffectingCombat("player") then
    if not ShuffleFrame.eventRegistered then
      NameplateTrinketFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
      ShuffleFrame.eventRegistered = true
    end
  else
    if NS.isInGroup() then
      for unit in NS.IterateGroupMembers() do
        local guid = UnitGUID(unit)
        if unit and guid then
          if NS.isHealer(unit) and not Healers[guid] then
            Healers[guid] = true
          end
          if not NS.isHealer(unit) and Healers[guid] then
            Healers[guid] = nil
          end
        end
      end
    else
      local guid = UnitGUID("player")
      if guid then
        if NS.isHealer("player") and not Healers[guid] then
          Healers[guid] = true
        end
      end
    end

    refreshNameplates()
  end
end

function NameplateTrinket:ARENA_OPPONENT_UPDATE()
  if not NameplateTrinketFrame.inArena then
    return
  end

  local name = AuraUtil.FindAuraByName("Arena Preparation", "player", "HELPFUL")
  if not name then
    return
  end

  if UnitAffectingCombat("player") then
    if not ShuffleFrame.eventRegistered then
      NameplateTrinketFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
      ShuffleFrame.eventRegistered = true
    end
  else
    if NS.isInGroup() then
      for unit in NS.IterateGroupMembers() do
        local guid = UnitGUID(unit)
        if unit and guid then
          if NS.isHealer(unit) and not Healers[guid] then
            Healers[guid] = true
          end
          if not NS.isHealer(unit) and Healers[guid] then
            Healers[guid] = nil
          end
        end
      end
    else
      local guid = UnitGUID("player")
      if guid then
        if NS.isHealer("player") and not Healers[guid] then
          Healers[guid] = true
        end
      end
    end

    refreshNameplates()
  end
end

function NameplateTrinket:PVP_MATCH_ACTIVE()
  twipe(TestSpellsPerPlayerGUID)
  twipe(SpellsPerPlayerGUID)
end

local function instanceCheck()
  local inInstance, instanceType = IsInInstance()

  if instanceType == nil or instanceType == "unknown" then
    print("report this to the addon author: instanceType is: ", instanceType == nil and "nil" or "unknown")
  end

  local correctedInstanceType = instanceType == nil and "unknown" or instanceType

  NameplateTrinketFrame.inArena = inInstance and (correctedInstanceType == "arena")

  if correctedInstanceType ~= NameplateTrinketFrame.instanceType then
    NameplateTrinketFrame.instanceType = correctedInstanceType

    ReallocateIcons(false)
    if NS.db.global.test then
      if correctedInstanceType == "none" then
        ReallocateTestIcons(false)
      elseif TestFrame then
        NS.DisableTestMode()
      end
    end
  end
end

function NameplateTrinket:LOADING_SCREEN_DISABLED()
  After(2, function()
    NameplateTrinketFrame.wasOnLoadingScreen = false

    if NS.db.global.test and not IsInInstance() then
      NS.EnableTestMode()
    end
  end)
end

function NameplateTrinket:LOADING_SCREEN_ENABLED()
  NameplateTrinketFrame.wasOnLoadingScreen = true
end

function NameplateTrinket:PLAYER_LEAVING_WORLD()
  After(2, function()
    NameplateTrinketFrame.wasOnLoadingScreen = false
  end)
end

function NameplateTrinket:PLAYER_ENTERING_WORLD()
  NameplateTrinketFrame.wasOnLoadingScreen = true

  if NS.isInGroup() then
    for unit in NS.IterateGroupMembers() do
      local guid = UnitGUID(unit)
      if unit and guid then
        if NS.isHealer(unit) and not Healers[guid] then
          Healers[guid] = true
        end
        if not NS.isHealer(unit) and Healers[guid] then
          Healers[guid] = nil
        end
      end
    end
  else
    local guid = UnitGUID("player")
    if guid then
      if NS.isHealer("player") and not Healers[guid] then
        Healers[guid] = true
      end
    end
  end

  -- this code only runs when you hover over a player
  -- local function OnTooltipSetItem(tooltip, tooltipData)
  --   if tooltip == GameTooltip then
  --     if tooltipData then
  --       if
  --         tooltipData.guid
  --         and tooltipData.lines
  --         and #tooltipData.lines >= 3
  --         and tooltipData.type == Enum.TooltipDataType.Unit
  --       then
  --         if GUIDIsPlayer(tooltipData.guid) then
  --           for _, line in ipairs(tooltipData.lines) do
  --             if line and line.type == Enum.TooltipDataLineType.None then
  --               if line.leftText and line.leftText ~= "" then
  --                 if Healers[tooltipData.guid] and HEALER_SPECS[line.leftText] then
  --                   break
  --                 end
  --                 if Healers[tooltipData.guid] and not HEALER_SPECS[line.leftText] then
  --                   Healers[tooltipData.guid] = nil
  --                   break
  --                 end
  --                 if not Healers[tooltipData.guid] and HEALER_SPECS[line.leftText] then
  --                   Healers[tooltipData.guid] = true
  --                   break
  --                 end
  --               end
  --             end
  --           end
  --         end
  --       end
  --     end
  --   end
  -- end
  -- TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipSetItem)

  NS.INSTANCE_TYPES = {
    -- nil resolves to "unknown"
    ["unknown"] = NS.db.global.instanceTypes.unknown, -- when in an unknown instance
    ["none"] = NS.db.global.instanceTypes.none, -- when outside an instance
    ["pvp"] = NS.db.global.instanceTypes.pvp, --  when in a battleground
    ["arena"] = NS.db.global.instanceTypes.arena, -- when in an arena
    ["party"] = NS.db.global.instanceTypes.party, -- when in a 5-man instance
    ["raid"] = NS.db.global.instanceTypes.raid, -- when in a raid instance
    ["scenario"] = NS.db.global.instanceTypes.scenario, -- when in a scenario
  }

  instanceCheck()

  twipe(TestSpellsPerPlayerGUID)
  twipe(SpellsPerPlayerGUID)

  if not NameplateTrinketFrame.loaded then
    NameplateTrinketFrame.loaded = true

    local timeElapsed = 0
    if not EventFrame then
      EventFrame = CreateFrame("Frame")
    end
    EventFrame:SetScript("OnUpdate", function(_, elapsed)
      timeElapsed = timeElapsed + elapsed
      if timeElapsed >= 1 then
        for nameplate, guid in pairs(NameplatesVisible) do
          if nameplate and guid then
            addNameplateIcons(nameplate, guid)
          end
        end
        timeElapsed = 0
      end
    end)

    NameplateTrinketFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    NameplateTrinketFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    NameplateTrinketFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
    NameplateTrinketFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    NameplateTrinketFrame:RegisterEvent("PVP_MATCH_ACTIVE")
    NameplateTrinketFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    if NS.db.global.targetOnly then
      NameplateTrinketFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    end
  end
end

function NameplateTrinket:PLAYER_LOGIN()
  NameplateTrinketFrame:UnregisterEvent("PLAYER_LOGIN")

  NameplateTrinketFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  NameplateTrinketFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
  NameplateTrinketFrame:RegisterEvent("LOADING_SCREEN_ENABLED")
  NameplateTrinketFrame:RegisterEvent("LOADING_SCREEN_DISABLED")
end
NameplateTrinketFrame:RegisterEvent("PLAYER_LOGIN")

function NS.OnDbChanged()
  NameplateTrinketFrame.dbChanged = true

  if NS.db.global.targetOnly then
    NameplateTrinketFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
  else
    NameplateTrinketFrame:UnregisterEvent("PLAYER_TARGET_CHANGED")
  end

  NS.INSTANCE_TYPES = {
    -- nil resolves to "unknown"
    ["unknown"] = NS.db.global.instanceTypes.unknown, -- when in an unknown instance
    ["none"] = NS.db.global.instanceTypes.none, -- when outside an instance
    ["pvp"] = NS.db.global.instanceTypes.pvp, --  when in a battleground
    ["arena"] = NS.db.global.instanceTypes.arena, -- when in an arena
    ["party"] = NS.db.global.instanceTypes.party, -- when in a 5-man instance
    ["raid"] = NS.db.global.instanceTypes.raid, -- when in a raid instance
    ["scenario"] = NS.db.global.instanceTypes.scenario, -- when in a scenario
  }

  ReallocateIcons(true)
  if NS.db.global.test and not IsInInstance() then
    ReallocateTestIcons(true)
  end

  NameplateTrinketFrame.dbChanged = false
end

function NS.Options_SlashCommands(_)
  LibStub("AceConfigDialog-3.0"):Open(AddonName)
end

function NS.Options_Setup()
  NS.RebuildOptions()

  LibStub("AceConfig-3.0"):RegisterOptionsTable(AddonName, NS.AceConfig)
  LibStub("AceConfigDialog-3.0"):AddToBlizOptions(AddonName, AddonName)

  SLASH_NPT1 = AddonName
  SLASH_NPT2 = "/npt"

  function SlashCmdList.NPT(message)
    NS.Options_SlashCommands(message)
  end
end

function NameplateTrinket:ADDON_LOADED(addon)
  NameplateTrinketFrame:UnregisterEvent("ADDON_LOADED")

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

    NS.Options_Setup()
  end
end
NameplateTrinketFrame:RegisterEvent("ADDON_LOADED")
