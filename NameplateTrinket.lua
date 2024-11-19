local AddonName, NS = ...

local CreateFrame = CreateFrame
local IsInInstance = IsInInstance
local GetTime = GetTime
local UnitGUID = UnitGUID
local UnitIsUnit = UnitIsUnit
local UnitIsPlayer = UnitIsPlayer
local UnitIsFriend = UnitIsFriend
local UnitIsEnemy = UnitIsEnemy
local UnitCanAttack = UnitCanAttack
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
local GetUnitTooltip = C_TooltipInfo.GetUnit
local GUIDIsPlayer = C_PlayerInfo.GUIDIsPlayer

local SpellTextureByID = NS.SpellTextureByID
local SpellNameByID = NS.SpellNameByID
local Interrupts = NS.Interrupts
local Trinkets = NS.Trinkets

local NameplateTrinket = {}
NS.NameplateTrinket = NameplateTrinket

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
NS.NameplateTrinket.frame = NameplateTrinketFrame

-- local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE
local SPELL_PVPTRINKET = NS.SPELL_PVPTRINKET
local SPELL_PVPADAPTATION = NS.SPELL_PVPADAPTATION
local SPELL_RESET = NS.SPELL_RESET
local SORT_MODE_NONE = NS.SORT_MODE_NONE
local SORT_MODE_TRINKET_INTERRUPT_OTHER = NS.SORT_MODE_TRINKET_INTERRUPT_OTHER
local SORT_MODE_INTERRUPT_TRINKET_OTHER = NS.SORT_MODE_INTERRUPT_TRINKET_OTHER
local SORT_MODE_TRINKET_OTHER = NS.SORT_MODE_TRINKET_OTHER
local SORT_MODE_INTERRUPT_OTHER = NS.SORT_MODE_INTERRUPT_OTHER
local GLOW_TIME_INFINITE = NS.GLOW_TIME_INFINITE
local MinCdDuration = 0
local MaxCdDuration = 10 * 3600
local ShowCooldownAnimation = true
local InverseLogic = false
local TimerTextUseRelativeScale = true
local ShowInactiveCD = false
local TestFrame
local EventFrame
local spellIDs = {
  [378464] = 90,
  [20589] = 60,
  [354489] = 20,
}
local SpellsPerPlayerGUID = {}
local TestSpellsPerPlayerGUID = {}
local AllCooldowns = {}
NS.AllCooldowns = AllCooldowns
local Nameplates = {}
local NameplatesVisible = {}
local Healers = {}
local HEALER_SPECS = {
  ["Restoration Druid"] = 105,
  ["Restoration Shaman"] = 264,
  ["Mistweaver Monk"] = 270,
  ["Holy Priest"] = 257,
  ["Holy Paladin"] = 65,
  ["Discipline Priest"] = 256,
  ["Preservation Evoker"] = 1468,
}
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

local function GetHealthbarFrame(originalFrame)
  local frame = originalFrame
  if frame.HealthBarsContainer then
    frame = frame.HealthBarsContainer.healthBar
  end
  return frame
end

local function GetSecureNameplate(unit)
  return GetNamePlateForUnit(unit, issecure())
end

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

function NS.GetDefaultDBEntryForSpell()
  return {
    ["enabled"] = true,
    ["glow"] = nil,
  }
end

function NS.BuildCooldowns()
  twipe(AllCooldowns)

  for _, cds in pairs(NS.CDs) do
    for spellId, cd in pairs(cds) do
      if SpellNameByID[spellId] ~= nil then
        AllCooldowns[spellId] = cd
        if NS.db.global.SpellCDs[spellId] == nil then
          NS.db.global.SpellCDs[spellId] = NS.GetDefaultDBEntryForSpell()
        end
      end
    end
  end

  for spellID in pairs(AllCooldowns) do
    if NS.db.global.SpellCDs[spellID] ~= nil and NS.db.global.SpellCDs[spellID].customCD ~= nil then
      AllCooldowns[spellID] = NS.db.global.SpellCDs[spellID].customCD
    end
  end

  -- delete invalid spells
  for spellId in pairs(NS.db.global.SpellCDs) do
    if SpellNameByID[spellId] == nil then
      NS.db.global.SpellCDs[spellId] = nil
    end
  end
end

local function GetUnitInfo(unit, guid)
  if not unit then
    return nil
  end

  if not guid then
    return nil
  end

  local tooltipData = GetUnitTooltip(unit)
  if tooltipData then
    if
      tooltipData.guid
      and tooltipData.lines
      and #tooltipData.lines >= 3
      and tooltipData.type == Enum.TooltipDataType.Unit
    then
      if GUIDIsPlayer(tooltipData.guid) then
        if not Healers[tooltipData.guid] then
          for _, line in ipairs(tooltipData.lines) do
            if line and line.type == Enum.TooltipDataLineType.None then
              if line.leftText and line.leftText ~= "" then
                if Healers[tooltipData.guid] and HEALER_SPECS[line.leftText] then
                  break
                end
                if Healers[tooltipData.guid] and not HEALER_SPECS[line.leftText] then
                  Healers[tooltipData.guid] = nil
                  break
                end
                if not Healers[tooltipData.guid] and HEALER_SPECS[line.leftText] then
                  Healers[tooltipData.guid] = true
                  break
                end
              end
            end
          end
        end
      end
    end
  end

  local info = {}

  local isTarget = UnitIsUnit(unit, "target")
  local isSelf = UnitIsUnit(unit, "player")
  local isPlayer = UnitIsPlayer(unit)
  local isFriend = UnitIsFriend("player", unit)
  local isEnemy = UnitIsEnemy("player", unit)
  local canAttack = UnitCanAttack("player", unit)
  local isNpc = not isPlayer
  local isDeadOrGhost = UnitIsDeadOrGhost(unit)
  local isAlive = not isDeadOrGhost and UnitHealth(unit) >= 1
  local isHealer = NS.isHealer("player") or Healers[guid] and true or false

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

  info.isTarget = isTarget
  info.isSelf = isSelf
  info.isPlayer = isPlayer
  info.isFriend = isFriend
  info.isEnemy = isEnemy
  info.canAttack = canAttack
  info.isNpc = isNpc
  info.isAlive = isAlive
  info.isHealer = isHealer

  return info
end

local CDSortFunctions = {
  [SORT_MODE_NONE] = function() end,
  [SORT_MODE_TRINKET_INTERRUPT_OTHER] = function(item1, item2)
    if Trinkets[item1.spellID] then
      if Trinkets[item2.spellID] then
        return item1.expires < item2.expires
      else
        return true
      end
    elseif Trinkets[item2.spellID] then
      return false
    elseif Interrupts[item1.spellID] then
      if Interrupts[item2.spellID] then
        return item1.expires < item2.expires
      else
        return true
      end
    elseif Interrupts[item2.spellID] then
      return false
    else
      return item1.expires < item2.expires
    end
  end,
  [SORT_MODE_INTERRUPT_TRINKET_OTHER] = function(item1, item2)
    if Interrupts[item1.spellID] then
      if Interrupts[item2.spellID] then
        return item1.expires < item2.expires
      else
        return true
      end
    elseif Interrupts[item2.spellID] then
      return false
    elseif Trinkets[item1.spellID] then
      if Trinkets[item2.spellID] then
        return item1.expires < item2.expires
      else
        return true
      end
    elseif Trinkets[item2.spellID] then
      return false
    else
      return item1.expires < item2.expires
    end
  end,
  [SORT_MODE_TRINKET_OTHER] = function(item1, item2)
    if Trinkets[item1.spellID] then
      if Trinkets[item2.spellID] then
        return item1.expires < item2.expires
      else
        return true
      end
    elseif Trinkets[item2.spellID] then
      return false
    else
      return item1.expires < item2.expires
    end
  end,
  [SORT_MODE_INTERRUPT_OTHER] = function(item1, item2)
    if Interrupts[item1.spellID] then
      if Interrupts[item2.spellID] then
        return item1.expires < item2.expires
      else
        return true
      end
    elseif Interrupts[item2.spellID] then
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
  tsort(t, CDSortFunctions["trinket-other"])
  return t
end

local function SetFrameSize(frame)
  local maxWidth, maxHeight = 0, 0
  if frame.nptIconFrame then
    for _, icon in pairs(frame.nptIcons) do
      if icon.shown then
        maxHeight = mmax(maxHeight, icon.frame:GetHeight())
        maxWidth = maxWidth + icon.frame:GetWidth() + NS.db.global.iconSpacing
      end
    end
    maxWidth = maxWidth - NS.db.global.iconSpacing
    maxHeight = maxHeight -- maxHeight - NS.db.global.iconSpacing
    frame.nptIconFrame:SetWidth(mmax(maxWidth, 1))
    frame.nptIconFrame:SetHeight(mmax(maxHeight, 1))
  end
end

local function SetTestFrameSize(frame)
  local maxWidth, maxHeight = 0, 0
  if frame.nptTestIconFrame then
    for _, icon in pairs(frame.nptTestIcons) do
      if icon.shown then
        maxHeight = mmax(maxHeight, icon.frame:GetHeight())
        maxWidth = maxWidth + icon.frame:GetWidth() + NS.db.global.iconSpacing
      end
    end
    maxWidth = maxWidth - NS.db.global.iconSpacing
    maxHeight = maxHeight -- maxHeight - NS.db.global.iconSpacing
    frame.nptTestIconFrame:SetWidth(mmax(maxWidth, 1))
    frame.nptTestIconFrame:SetHeight(mmax(maxHeight, 1))
  end
end

function HideIcon(icon, frame)
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
  SetFrameSize(frame)
end

function HideTestIcon(icon, frame)
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
  SetTestFrameSize(frame)
end

function ShowIcon(icon, frame)
  if icon.cooldownText then
    icon.cooldownText:Show()
  end
  local hideIcon = NS.db.global.trinketOnly and not Trinkets[icon.spellID]
  if hideIcon then
    icon.frame:Hide()
    icon.shown = false
  else
    icon.frame:Show()
    icon.shown = true
  end
  SetFrameSize(frame)
end

function ShowTestIcon(icon, frame)
  if icon.cooldownText then
    icon.cooldownText:Show()
  end
  local hideIcon = NS.db.global.trinketOnly and not Trinkets[icon.spellID]
  if hideIcon then
    icon.frame:Hide()
    icon.shown = false
  else
    icon.frame:Show()
    icon.shown = true
  end
  SetTestFrameSize(frame)
end

local function SetGlow(icon, spellID, isActive)
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

  if isActive and Trinkets[spellID] then
    icon.glowTexture:Show()
    icon.glow = true
  elseif icon.glowTexture ~= nil then
    icon.glowTexture:Hide()
    icon.glowTexture = nil
    icon.glow = false
  end
end

local function SetBorder(icon, spellID, isActive)
  if isActive and Trinkets[spellID] then
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
  if icon.textureID ~= texture then
    icon.texture:SetTexture(texture)
    icon.textureID = texture
  end
  if icon.desaturation ~= not isActive then
    icon.texture:SetDesaturated(not isActive)
    icon.desaturation = not isActive
  end
end

local function PlaceIcon(frame, icon, iconIndex)
  icon.frame:ClearAllPoints()
  local index = iconIndex == nil and frame.nptIconCount or (iconIndex - 1)
  if index == 0 then
    if NS.db.global.growDirection == "RIGHT" then
      icon.frame:SetPoint("LEFT", frame.nptIconFrame, "LEFT", 0, 0)
    elseif NS.db.global.growDirection == "LEFT" then
      icon.frame:SetPoint("RIGHT", frame.nptIconFrame, "RIGHT", 0, 0)
    end
  else
    local previousIcon = frame.nptIcons[index]
    if NS.db.global.growDirection == "RIGHT" then
      icon.frame:SetPoint("LEFT", previousIcon.frame, "RIGHT", NS.db.global.iconSpacing, 0)
    elseif NS.db.global.growDirection == "LEFT" then
      icon.frame:SetPoint("RIGHT", previousIcon.frame, "LEFT", -NS.db.global.iconSpacing, 0)
    end
  end
end

local function PlaceTestIcon(frame, icon, iconIndex)
  icon.frame:ClearAllPoints()
  local index = iconIndex == nil and frame.nptTestIconCount or (iconIndex - 1)
  if index == 0 then
    if NS.db.global.growDirection == "RIGHT" then
      icon.frame:SetPoint("LEFT", frame.nptTestIconFrame, "LEFT", 0, 0)
    elseif NS.db.global.growDirection == "LEFT" then
      icon.frame:SetPoint("RIGHT", frame.nptTestIconFrame, "RIGHT", 0, 0)
    end
  else
    local previousIcon = frame.nptTestIcons[index]
    if NS.db.global.growDirection == "RIGHT" then
      icon.frame:SetPoint("LEFT", previousIcon.frame, "RIGHT", NS.db.global.iconSpacing, 0)
    elseif NS.db.global.growDirection == "LEFT" then
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
function CreateIcon(frame, spellID)
  local iconFrame = CreateFrame("Frame", nil, frame.nptIconFrame)
  local icon = {}
  icon.spellID = spellID

  iconFrame:SetWidth(NS.db.global.iconSize)
  iconFrame:SetHeight(NS.db.global.iconSize)
  iconFrame:SetAlpha(NS.db.global.iconAlpha)
  icon.frame = iconFrame
  PlaceIcon(frame, icon)
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

  local loadedOrLoading, loaded = C_AddOns.IsAddOnLoaded("OmniCC")
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

  frame.nptIconCount = frame.nptIconCount + 1
  tinsert(frame.nptIcons, icon)

  return icon
end

-- frame = nameplate.UnitFrame
function CreateTestIcon(frame, spellID)
  local iconFrame = CreateFrame("Frame", nil, frame.nptTestIconFrame)
  local icon = {}
  icon.spellID = spellID

  iconFrame:SetWidth(NS.db.global.iconSize)
  iconFrame:SetHeight(NS.db.global.iconSize)
  iconFrame:SetAlpha(NS.db.global.iconAlpha)
  icon.frame = iconFrame
  PlaceTestIcon(frame, icon)
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

  local loadedOrLoading, loaded = C_AddOns.IsAddOnLoaded("OmniCC")
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

  frame.nptTestIconCount = frame.nptTestIconCount + 1
  tinsert(frame.nptTestIcons, icon)

  return icon
end

local function FilterSpell(dbInfo, remainingTime, isActive)
  if not dbInfo or not dbInfo.enabled then
    return false
  end

  if not ShowInactiveCD and not isActive then
    return false
  end

  if remainingTime > 0 and (remainingTime < MinCdDuration or remainingTime > MaxCdDuration) then
    return false
  end

  return true
end

local function addIcons(frame, guid)
  if not frame.unit then
    return
  end

  if not guid then
    return
  end

  if not frame.nptIconCount then
    return
  end

  local counter = 1
  if SpellsPerPlayerGUID[guid] then
    local currentTime = GetTime()
    local sortedCDs = SortAuras(SpellsPerPlayerGUID[guid])
    for _, spellInfo in pairs(sortedCDs) do
      local spellID = spellInfo.spellID
      local isActiveCD = spellInfo.expires > currentTime
      if InverseLogic then
        isActiveCD = not isActiveCD
      end
      local dbInfo = NS.db.global.SpellCDs[spellID]
      local remainingTime = spellInfo.expires - currentTime
      if FilterSpell(dbInfo, remainingTime, isActiveCD) then
        if counter > frame.nptIconCount then
          CreateIcon(frame, spellID)
        end
        local icon = frame.nptIcons[counter]
        SetTexture(icon, spellInfo.texture, isActiveCD)
        SetBorder(icon, spellID, isActiveCD)
        if NS.db.global.enableGlow and Trinkets[spellID] then
          dbInfo.glow = GLOW_TIME_INFINITE
          SetGlow(icon, spellID, isActiveCD)
        end
        SetCooldown(icon, remainingTime, spellInfo.started, spellInfo.duration, isActiveCD)
        if not icon.shown then
          ShowIcon(icon, frame)
        end
        counter = counter + 1
      end
    end
  end

  for k = counter, frame.nptIconCount do
    local icon = frame.nptIcons[k]
    if icon.shown then
      HideIcon(icon, frame)
    end
  end
end

local function addTestIcons(frame, guid)
  if not frame.unit then
    return
  end

  if not guid then
    return
  end

  if not frame.nptTestIconCount then
    return
  end

  local counter = 1
  if TestSpellsPerPlayerGUID[guid] then
    local currentTime = GetTime()
    local sortedCDs = SortAuras(TestSpellsPerPlayerGUID[guid])
    for _, spellInfo in ipairs(sortedCDs) do
      local spellID = spellInfo.spellID
      local isActiveCD = spellInfo.expires > currentTime
      if InverseLogic then
        isActiveCD = not isActiveCD
      end
      local dbInfo = NS.db.global.SpellCDs[spellID]
      local remainingTime = spellInfo.expires - currentTime
      if FilterSpell(dbInfo, remainingTime, isActiveCD) then
        if counter > frame.nptTestIconCount then
          CreateTestIcon(frame, spellID)
        end
        local icon = frame.nptTestIcons[counter]
        SetTexture(icon, spellInfo.texture, isActiveCD)
        SetBorder(icon, spellID, isActiveCD)
        if NS.db.global.enableGlow and Trinkets[spellID] then
          dbInfo.glow = GLOW_TIME_INFINITE
          SetGlow(icon, spellID, isActiveCD)
        end
        SetTestCooldown(icon, remainingTime, spellInfo.started, spellInfo.duration, isActiveCD)
        if not icon.shown then
          ShowTestIcon(icon, frame)
        end
        counter = counter + 1
      end
    end
  end

  for k = counter, frame.nptTestIconCount do
    local icon = frame.nptTestIcons[k]
    if icon.shown then
      HideTestIcon(icon, frame)
    end
  end
end

local function addNameplateIcons(frame, guid)
  if not frame.unit then
    return
  end

  if not guid then
    return
  end

  local info = GetUnitInfo(frame.unit, guid)

  if not info then
    return
  end

  local hideAllies = not NS.db.global.showOnAllies and info.isFriend
  local targetExists = UnitExists("target")
  local targetIsUnit = targetExists and info.isTarget -- UnitGUID("target") == guid
  local hideNonTargets = NS.db.global.targetOnly and (not targetExists or not targetIsUnit)
  local hideOnSelf = not NS.db.global.showSelf and info.isSelf
  local hideInstanceTypes = not NS.db.global.showEverywhere and NS.INSTANCE_TYPES[NameplateTrinketFrame.instanceType]
  local hideIcons = NS.db.global.test
    or info.isNpc
    or hideOnSelf
    or not info.isAlive
    or hideAllies
    or hideNonTargets
    or hideInstanceTypes

  if hideIcons then
    if frame.nptIconFrame then
      frame.nptIconFrame:Hide()
    end
    return
  end

  if not frame.nptIconFrame then
    frame.nptIconFrame = CreateFrame("Frame", nil, frame.rbgdAnchorFrame)
    frame.nptIconFrame:SetIgnoreParentAlpha(NS.db.global.ignoreNameplateAlpha)
    frame.nptIconFrame:SetIgnoreParentScale(NS.db.global.ignoreNameplateScale)
    frame.nptIconFrame:SetWidth(NS.db.global.iconSize)
    frame.nptIconFrame:SetHeight(NS.db.global.iconSize)
    frame.nptIconFrame:SetFrameStrata(NS.db.global.frameStrata)
    frame.nptIconFrame:ClearAllPoints()
    -- Anchor -- Frame -- To Frame's -- offsetsX -- offsetsY
    frame.nptIconFrame:SetPoint(
      NS.db.global.anchor,
      frame.healthBar,
      NS.db.global.anchorTo,
      NS.db.global.offsetX,
      NS.db.global.offsetY
    )
    frame.nptIconFrame:SetScale(1)
    frame.nptIconFrame:Show()
  end

  addIcons(frame, guid)
end
NS.addNameplateIcons = addNameplateIcons

local function addNameplateTestIcons(frame, guid)
  if not frame.unit then
    return
  end

  if not guid then
    return
  end

  local info = GetUnitInfo(frame.unit, guid)

  if not info then
    return
  end

  local hideAllies = not NS.db.global.showOnAllies and info.isFriend
  local targetExists = UnitExists("target")
  local targetIsUnit = targetExists and info.isTarget -- UnitGUID("target") == guid
  local hideNonTargets = NS.db.global.targetOnly and (not targetExists or not targetIsUnit)
  local hideOnSelf = not NS.db.global.showSelf and info.isSelf
  local hideInstanceTypes = not NS.db.global.showEverywhere and NS.INSTANCE_TYPES[NameplateTrinketFrame.instanceType]
  local hideIcons = not NS.db.global.test
    or info.isNpc
    or hideOnSelf
    or not info.isAlive
    or hideAllies
    or hideNonTargets
    or hideInstanceTypes

  if hideIcons then
    if frame.nptTestIconFrame then
      frame.nptTestIconFrame:Hide()
    end
    return
  end

  if not frame.nptTestIconFrame then
    frame.nptTestIconFrame = CreateFrame("Frame", nil, frame.rbgdAnchorFrame)
    frame.nptTestIconFrame:SetIgnoreParentAlpha(NS.db.global.ignoreNameplateAlpha)
    frame.nptTestIconFrame:SetIgnoreParentScale(NS.db.global.ignoreNameplateScale)
    frame.nptTestIconFrame:SetWidth(NS.db.global.iconSize)
    frame.nptTestIconFrame:SetHeight(NS.db.global.iconSize)
    frame.nptTestIconFrame:SetFrameStrata(NS.db.global.frameStrata)
    frame.nptTestIconFrame:SetScale(1)
    frame.nptTestIconFrame:ClearAllPoints()
    -- Anchor -- Frame -- To Frame's -- offsetsX -- offsetsY
    frame.nptTestIconFrame:SetPoint(
      NS.db.global.anchor,
      frame.healthBar,
      NS.db.global.anchorTo,
      NS.db.global.offsetX,
      NS.db.global.offsetY
    )
    frame.nptTestIconFrame:Show()
    frame.nptTestIcons = {}
    frame.nptTestIconCount = 0
  end

  addTestIcons(frame, guid)
end
NS.addNameplateTestIcons = addNameplateTestIcons

local function refreshNameplates(override)
  if not override and NameplateTrinketFrame.wasOnLoadingScreen then
    return
  end

  for _, nameplate in pairs(GetNamePlates(issecure())) do
    local frame = GetSafeNameplateFrame(nameplate)

    if frame then
      local guid = UnitGUID(frame.unit)

      NameplatesVisible[frame] = guid

      if not Nameplates[frame] then
        Nameplates[frame] = true
      end

      if not frame.rbgdAnchorFrame then
        local attachmentFrame = GetHealthbarFrame(frame)
        frame.rbgdAnchorFrame = CreateFrame("Frame", nil, attachmentFrame)
      end

      if frame.nptTestIconFrame ~= nil then
        frame.nptTestIconFrame:Show()
      end
      if frame.nptIconFrame ~= nil then
        frame.nptIconFrame:Show()
      end

      if guid then
        addNameplateIcons(frame, guid)
        if NS.db.global.test then
          addNameplateTestIcons(frame, guid)
        end
      end
    end
  end
end

function NS.RefreshTestSpells()
  local currentTime = GetTime()
  for frame, guid in pairs(NameplatesVisible) do
    if frame and guid then
      if not TestSpellsPerPlayerGUID[guid] then
        TestSpellsPerPlayerGUID[guid] = {}
      end
      if not TestSpellsPerPlayerGUID[guid][SPELL_PVPTRINKET] then
        TestSpellsPerPlayerGUID[guid][SPELL_PVPTRINKET] = {
          ["spellID"] = SPELL_PVPTRINKET,
          ["expires"] = currentTime + (Healers[guid] and 90 or 120),
          ["texture"] = SpellTextureByID[SPELL_PVPTRINKET],
          ["duration"] = (Healers[guid] and 90 or 120),
          ["started"] = currentTime,
        }
      else
        if currentTime - TestSpellsPerPlayerGUID[guid][SPELL_PVPTRINKET].expires > 0 then
          TestSpellsPerPlayerGUID[guid][SPELL_PVPTRINKET] = {
            ["spellID"] = SPELL_PVPTRINKET,
            ["expires"] = currentTime + (Healers[guid] and 90 or 120),
            ["texture"] = SpellTextureByID[SPELL_PVPTRINKET],
            ["duration"] = (Healers[guid] and 90 or 120),
            ["started"] = currentTime,
          }
        end
      end
      if not NS.db.global.trinketOnly then
        for spellID, cd in pairs(spellIDs) do
          if not TestSpellsPerPlayerGUID[guid][spellID] then
            TestSpellsPerPlayerGUID[guid][spellID] = {
              ["spellID"] = spellID,
              ["expires"] = currentTime + cd,
              ["texture"] = SpellTextureByID[spellID],
              ["duration"] = cd,
              ["started"] = currentTime,
            }
          else
            if currentTime - TestSpellsPerPlayerGUID[guid][spellID].expires > 0 then
              TestSpellsPerPlayerGUID[guid][spellID] = {
                ["spellID"] = spellID,
                ["expires"] = currentTime + cd,
                ["texture"] = SpellTextureByID[spellID],
                ["duration"] = cd,
                ["started"] = currentTime,
              }
            end
          end
        end
      end
      addNameplateTestIcons(frame, guid)
    end
  end
end

function NS.DisableTestMode()
  NameplateTrinketFrame.TestModeActive = false
  NameplateTrinketFrame:UnregisterEvent("PLAYER_LOGOUT")
  TestFrame:SetScript("OnUpdate", nil)
  twipe(TestSpellsPerPlayerGUID)
  for frame in pairs(Nameplates) do
    if frame and frame.unit and frame.nptTestIconFrame then
      frame.nptTestIconFrame:Hide()
      frame.nptTestIconFrame = nil
      frame.nptTestIcons = {}
      frame.nptTestIconCount = 0
    end
  end
end

function NameplateTrinket:PLAYER_LOGOUT()
  NS.DisableTestMode()
end

function NS.EnableTestMode()
  NameplateTrinketFrame.TestModeActive = true
  NameplateTrinketFrame:RegisterEvent("PLAYER_LOGOUT")
  twipe(TestSpellsPerPlayerGUID)
  NS.RefreshTestSpells()
  if not TestFrame then
    TestFrame = CreateFrame("frame")
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

function ReallocateTestIcons(clearSpells)
  for frame in pairs(Nameplates) do
    if frame and frame.unit and frame.nptTestIconFrame then
      frame.nptTestIconFrame:SetIgnoreParentAlpha(NS.db.global.ignoreNameplateAlpha)
      frame.nptTestIconFrame:SetIgnoreParentScale(NS.db.global.ignoreNameplateScale)
      frame.nptTestIconFrame:ClearAllPoints()
      frame.nptTestIconFrame:SetPoint(
        NS.db.global.anchor,
        frame.healthBar,
        NS.db.global.anchorTo,
        NS.db.global.offsetX,
        NS.db.global.offsetY
      )
      local counter = 0
      for index, icon in pairs(frame.nptTestIcons) do
        icon.frame:SetWidth(NS.db.global.iconSize)
        icon.frame:SetHeight(NS.db.global.iconSize)
        icon.frame:SetAlpha(NS.db.global.iconAlpha)
        PlaceTestIcon(frame, icon, index)
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
          HideTestIcon(icon, frame)
        end
        counter = counter + 1
      end
      SetTestFrameSize(frame)
    end
  end
  if clearSpells then
    for frame, guid in pairs(NameplatesVisible) do
      if frame and guid then
        addNameplateTestIcons(frame, guid)
      end
    end
  end
end

function ReallocateIcons(clearSpells)
  for frame in pairs(Nameplates) do
    if frame and frame.unit and frame.nptIconFrame then
      frame.nptIconFrame:SetIgnoreParentAlpha(NS.db.global.ignoreNameplateAlpha)
      frame.nptIconFrame:SetIgnoreParentScale(NS.db.global.ignoreNameplateScale)
      frame.nptIconFrame:ClearAllPoints()
      frame.nptIconFrame:SetPoint(
        NS.db.global.anchor,
        frame.healthBar,
        NS.db.global.anchorTo,
        NS.db.global.offsetX,
        NS.db.global.offsetY
      )
      local counter = 0
      for index, icon in pairs(frame.nptIcons) do
        icon.frame:SetWidth(NS.db.global.iconSize)
        icon.frame:SetHeight(NS.db.global.iconSize)
        icon.frame:SetAlpha(NS.db.global.iconAlpha)
        PlaceIcon(frame, icon, index)
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
          HideIcon(icon, frame)
        end
        counter = counter + 1
      end
      SetTestFrameSize(frame)
    end
  end
  if clearSpells then
    for frame, guid in pairs(NameplatesVisible) do
      if frame and guid then
        addNameplateIcons(frame, guid)
      end
    end
  end
end

-- frame = nameplate.UnitFrame
function NameplateTrinket:detachFromNameplate(frame)
  NameplatesVisible[frame] = nil

  if frame.nptTestIconFrame ~= nil then
    frame.nptTestIconFrame:Hide()
  end
  if frame.nptIconFrame ~= nil then
    frame.nptIconFrame:Hide()
  end
end

-- frame = nameplate.UnitFrame
function NameplateTrinket:attachToNameplate(frame)
  local guid = UnitGUID(frame.unit)

  NameplatesVisible[frame] = guid

  if not Nameplates[frame] then
    frame.nptIcons = {}
    frame.nptIconCount = 0
    Nameplates[frame] = true
  end

  if not frame.rbgdAnchorFrame then
    local attachmentFrame = GetHealthbarFrame(frame)
    frame.rbgdAnchorFrame = CreateFrame("Frame", nil, attachmentFrame)
  end

  if frame.nptTestIconFrame ~= nil then
    frame.nptTestIconFrame:Show()
  end
  if frame.nptIconFrame ~= nil then
    frame.nptIconFrame:Show()
  end

  if guid then
    addNameplateIcons(frame, guid)
    if NS.db.global.test or NameplateTrinketFrame.TestModeActive then
      addNameplateTestIcons(frame, guid)
    end
  end
end

-- unitId == unitToken, UnitGUID takes unitId, formely unitToken, as its param
function NameplateTrinket:NAME_PLATE_UNIT_REMOVED(unitToken)
  if not unitToken then
    return
  end

  local nameplate = GetSecureNameplate(unitToken)
  local frame = GetSafeNameplateFrame(nameplate)

  if frame then
    self:detachFromNameplate(frame)
  end
end

-- UnitIsPlayer takes unitToken
-- C_PlayerInfo.GUIDIsPlayer takes unitGUID
function NameplateTrinket:NAME_PLATE_UNIT_ADDED(unitToken)
  if not unitToken then
    return
  end

  local nameplate = GetSecureNameplate(unitToken)
  local frame = GetSafeNameplateFrame(nameplate)

  if frame then
    self:detachFromNameplate(frame)
    self:attachToNameplate(frame)
  end
end

function NameplateTrinket:PLAYER_TARGET_CHANGED()
  ReallocateIcons(true)
  if NS.db.global.test then
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
  local hideInstanceTypes = not NS.db.global.showEverywhere and NS.INSTANCE_TYPES[NameplateTrinketFrame.instanceType]
  if hideInstanceTypes then
    return
  end
  local _, subevent, _, sourceGUID, _, sourceFlags, _, destGUID, _, _, _ = CombatLogGetCurrentEventInfo()
  if not (sourceGUID or destGUID) then
    return
  end
  -- @TODO: don't want to deal with Mind Controlled players right now since they become pets
  -- local isPlayer = bband(sourceFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0
  -- if not isPlayer then
  -- 	return
  -- end
  local spellId = select(12, CombatLogGetCurrentEventInfo())
  if spellId then
    if HEALER_SPELL_EVENTS[subevent] and HEALER_SPELLS[spellId] then
      if not Healers[sourceGUID] then
        Healers[sourceGUID] = true
      end
    end
    if bband(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= 0 or (NS.db.global.showOnAllies == true) then
      local currentTime = GetTime()
      local entry = NS.db.global.SpellCDs[spellId]
      local cooldown = AllCooldowns[spellId]
      if cooldown ~= nil and entry and entry.enabled then
        if
          subevent == "SPELL_CAST_SUCCESS"
          or subevent == "SPELL_AURA_APPLIED"
          or subevent == "SPELL_MISSED"
          or subevent == "SPELL_SUMMON"
        then
          local expires = currentTime + cooldown
          if not SpellsPerPlayerGUID[sourceGUID] then
            SpellsPerPlayerGUID[sourceGUID] = {}
          end
          SpellsPerPlayerGUID[sourceGUID][spellId] = {
            ["spellID"] = spellId,
            ["expires"] = expires,
            ["texture"] = SpellTextureByID[spellId],
            ["duration"] = cooldown,
            ["started"] = currentTime,
          }
          -- // pvptier 1/2 used, correcting cd of PvP trinket
          if
            spellId == SPELL_PVPADAPTATION
            and NS.db.global.SpellCDs[SPELL_PVPTRINKET] ~= nil
            and NS.db.global.SpellCDs[SPELL_PVPTRINKET].enabled
          then
            local existingEntry = SpellsPerPlayerGUID[sourceGUID][SPELL_PVPTRINKET]
            if existingEntry then
              existingEntry.expires = currentTime + 60
              existingEntry.duration = currentTime + 60
              -- existingEntry.texture = SpellTextureByID[SPELL_PVPTRINKET]
            end
            -- caster is a healer, reducing cd of pvp trinket
          elseif
            spellId == SPELL_PVPTRINKET
            and NS.db.global.SpellCDs[SPELL_PVPTRINKET] ~= nil
            and NS.db.global.SpellCDs[SPELL_PVPTRINKET].enabled
            and Healers[sourceGUID]
          then
            local existingEntry = SpellsPerPlayerGUID[sourceGUID][SPELL_PVPTRINKET]
            if existingEntry then
              existingEntry.expires = existingEntry.expires - 30
              existingEntry.duration = existingEntry.duration - 30
            end
          end
          for frame, guid in pairs(NameplatesVisible) do
            if frame and guid and guid == sourceGUID then
              addNameplateIcons(frame, guid)
              break
            end
          end
        end
      end
      -- reset
      if subevent == "SPELL_AURA_APPLIED" and spellId == SPELL_RESET then
        if SpellsPerPlayerGUID[sourceGUID] then
          SpellsPerPlayerGUID[sourceGUID] = {}
          for frame, guid in pairs(NameplatesVisible) do
            if frame and guid and guid == sourceGUID then
              addNameplateIcons(frame, guid)
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

  if UnitAffectingCombat("player") then
    if not ShuffleFrame.eventRegistered then
      NameplateTrinketFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
      ShuffleFrame.eventRegistered = true
    end
  else
    twipe(TestSpellsPerPlayerGUID)
    twipe(SpellsPerPlayerGUID)
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

    twipe(TestSpellsPerPlayerGUID)
    twipe(SpellsPerPlayerGUID)
    refreshNameplates()
  end
end

function NameplateTrinket:PVP_MATCH_ACTIVE()
  twipe(TestSpellsPerPlayerGUID)
  twipe(SpellsPerPlayerGUID)
  twipe(Nameplates)
  twipe(NameplatesVisible)
end

local function instanceCheck()
  local inInstance, instanceType = IsInInstance()
  NameplateTrinketFrame.inArena = inInstance and (instanceType == "arena")

  local correctedInstanceType = instanceType == nil and "unknown" or instanceType

  if instanceType == nil or instanceType == "unknown" then
    print("report this to the addon author: instanceType is nil")
  end

  if correctedInstanceType ~= NameplateTrinketFrame.instanceType then
    NameplateTrinketFrame.instanceType = correctedInstanceType

    ReallocateIcons(false)
    if NS.db.global.test then
      ReallocateTestIcons(false)
    end
  end
end

function NameplateTrinket:ZONE_CHANGED_NEW_AREA()
  instanceCheck()
end

function NameplateTrinket:LOADING_SCREEN_DISABLED()
  After(2, function()
    NameplateTrinketFrame.wasOnLoadingScreen = false

    if NS.db.global.test then
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
  local function OnTooltipSetItem(tooltip, tooltipData)
    if tooltip == GameTooltip then
      if tooltipData then
        if
          tooltipData.guid
          and tooltipData.lines
          and #tooltipData.lines >= 3
          and tooltipData.type == Enum.TooltipDataType.Unit
        then
          if GUIDIsPlayer(tooltipData.guid) then
            for _, line in ipairs(tooltipData.lines) do
              if line and line.type == Enum.TooltipDataLineType.None then
                if line.leftText and line.leftText ~= "" then
                  if Healers[tooltipData.guid] and HEALER_SPECS[line.leftText] then
                    break
                  end
                  if Healers[tooltipData.guid] and not HEALER_SPECS[line.leftText] then
                    Healers[tooltipData.guid] = nil
                    break
                  end
                  if not Healers[tooltipData.guid] and HEALER_SPECS[line.leftText] then
                    Healers[tooltipData.guid] = true
                    break
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipSetItem)

  twipe(TestSpellsPerPlayerGUID)
  twipe(SpellsPerPlayerGUID)
  twipe(Nameplates)
  twipe(NameplatesVisible)

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

  NameplateTrinketFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
  NameplateTrinketFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
  NameplateTrinketFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
  NameplateTrinketFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
  NameplateTrinketFrame:RegisterEvent("PVP_MATCH_ACTIVE")
  NameplateTrinketFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  NameplateTrinketFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
  NameplateTrinketFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
  NameplateTrinketFrame:RegisterEvent("DUEL_REQUESTED")
  NameplateTrinketFrame:RegisterEvent("DUEL_FINISHED")
  if NS.db.global.targetOnly then
    NameplateTrinketFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
  end

  local timeElapsed = 0
  if not EventFrame then
    EventFrame = CreateFrame("frame")
  end
  EventFrame:SetScript("OnUpdate", function(_, elapsed)
    timeElapsed = timeElapsed + elapsed
    if timeElapsed >= 1 then
      for frame, guid in pairs(NameplatesVisible) do
        if frame and guid then
          addNameplateIcons(frame, guid)
        end
      end
      timeElapsed = 0
    end
  end)
end

function NameplateTrinket:PLAYER_LOGIN()
  NameplateTrinketFrame:UnregisterEvent("PLAYER_LOGIN")

  NS.BuildCooldowns()

  NameplateTrinketFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  NameplateTrinketFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
  NameplateTrinketFrame:RegisterEvent("LOADING_SCREEN_ENABLED")
  NameplateTrinketFrame:RegisterEvent("LOADING_SCREEN_DISABLED")
  NameplateTrinketFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
end
NameplateTrinketFrame:RegisterEvent("PLAYER_LOGIN")

function NS.OnDbChanged()
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
  if NS.db.global.test then
    ReallocateTestIcons(true)
  end
end

function Options_SlashCommands(_)
  LibStub("AceConfigDialog-3.0"):Open(AddonName)
end

function Options_Setup()
  LibStub("AceConfig-3.0"):RegisterOptionsTable(AddonName, NS.AceConfig)
  LibStub("AceConfigDialog-3.0"):AddToBlizOptions(AddonName, AddonName)

  SLASH_NPT1 = AddonName
  SLASH_NPT2 = "/npt"

  function SlashCmdList.NPT(message)
    Options_SlashCommands(message)
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

    Options_Setup()
  end
end
NameplateTrinketFrame:RegisterEvent("ADDON_LOADED")
