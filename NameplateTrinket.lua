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
-- local UnitHealth = UnitHealth
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
-- local UnitReaction = UnitReaction
local UnitAffectingCombat = UnitAffectingCombat
local UnitTokenFromGUID = UnitTokenFromGUID
local UnitExists = UnitExists
local UnitClass = UnitClass
local issecure = issecure
local pairs = pairs
local ipairs = ipairs
local LibStub = LibStub
local next = next
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local select = select
-- local tostring = tostring
local tonumber = tonumber
local print = print

local mceil = math.ceil
local mmax = math.max
local tinsert = table.insert
local tsort = table.sort
local twipe = table.wipe
-- local smatch = string.match
local sfind = string.find
local bband = bit.band

local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
local GetNamePlates = C_NamePlate.GetNamePlates
local After = C_Timer.After
local IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local GetSpellInfo = C_Spell.GetSpellInfo
local GetSpellDescription = C_Spell.GetSpellDescription
local GetUnitTooltip = C_TooltipInfo.GetUnit
-- local GUIDIsPlayer = C_PlayerInfo.GUIDIsPlayer

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

--- @type table<integer, integer>
local SpellTextureByID = NS.SpellTextureByID
--- @type table<number, boolean>
local Interrupts = NS.Interrupts
--- @type table<number, boolean>
local Trinkets = NS.Trinkets

local NameplateTrinket = {}
NS.NameplateTrinket = NameplateTrinket

--- @type AllCooldowns
AllCooldowns = NS.AllCooldowns

local NameplateTrinketFrame = CreateFrame("Frame", AddonName .. "Frame")
NameplateTrinketFrame:SetScript("OnEvent", function(_, event, ...)
  if NameplateTrinket[event] then
    NameplateTrinket[event](NameplateTrinket, ...)
  end
end)
NameplateTrinketFrame.TestModeActive = false
NameplateTrinketFrame.wasOnLoadingScreen = true
--- @type nil | "unknown" | "none" | "pvp" | "arena" | "party" | "raid" | "scenario"
NameplateTrinketFrame.instanceType = nil
NameplateTrinketFrame.inArena = false
NameplateTrinketFrame.loaded = false
NameplateTrinketFrame.dbChanged = false
NS.NameplateTrinket.frame = NameplateTrinketFrame

local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE
--- @type integer
local SPELL_PVPTRINKET = NS.SPELL_PVPTRINKET
--- @type integer
local SPELL_PVPADAPTATION = NS.SPELL_PVPADAPTATION
--- @type integer
local SPELL_RESET = NS.SPELL_RESET
--- @type "left"
local ICON_GROW_DIRECTION_LEFT = NS.ICON_GROW_DIRECTION_LEFT
--- @type "right"
local ICON_GROW_DIRECTION_RIGHT = NS.ICON_GROW_DIRECTION_RIGHT
--- @type "none"
local SORT_MODE_NONE = NS.SORT_MODE_NONE
--- @type "trinket-interrupt-other"
local SORT_MODE_TRINKET_INTERRUPT_OTHER = NS.SORT_MODE_TRINKET_INTERRUPT_OTHER
--- @type "interrupt-trinket-other"
local SORT_MODE_INTERRUPT_TRINKET_OTHER = NS.SORT_MODE_INTERRUPT_TRINKET_OTHER
--- @type "trinket-other"
local SORT_MODE_TRINKET_OTHER = NS.SORT_MODE_TRINKET_OTHER
--- @type "interrupt-other"
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
local HEALER_CLASS_IDS = {
  [2] = true,
  [5] = true,
  [7] = true,
  [10] = true,
  [11] = true,
  [13] = true,
}
local HEALER_SPECS = {
  ["Restoration Druid"] = 105,
  ["Restoration Shaman"] = 264,
  ["Mistweaver Monk"] = 270,
  ["Holy Priest"] = 257,
  ["Holy Paladin"] = 65,
  ["Discipline Priest"] = 256,
  ["Preservation Evoker"] = 1468,
}

local function GetAnchorFrame(nameplate)
  if nameplate.unitFrame then
    if nameplate.unitFrame then
      -- works as Plater internal nameplate.unitFramePlater
      return nameplate.unitFrame.healthBar
    end
  elseif nameplate.UnitFrame then
    if IsAddOnLoaded("TidyPlates_ThreatPlates") then
      local tFrame = nameplate.TPFrame
      if tFrame then
        return tFrame
      end
    elseif IsAddOnLoaded("Kui_Nameplates") then
      local kFrame = nameplate.kui
      if kFrame then
        return kFrame
      end
    elseif IsAddOnLoaded("TidyPlates") then
      local tFrame = nameplate.extended
      if tFrame then
        return tFrame
      end
    elseif IsAddOnLoaded("NeatPlates") then
      local nFrame = nameplate.extended
      if nFrame then
        return nFrame
      end
    elseif nameplate.UnitFrame.HealthBarsContainer then
      -- does not work as NeatPlates internal nameplate.extended
      return nameplate.UnitFrame.HealthBarsContainer
    elseif nameplate.UnitFrame.healthBar then
      -- does not work as NeatPlates internal nameplate.extended
      return nameplate.UnitFrame.healthBar
    else
      -- works as NeatPlates internal nameplate.extended
      -- does not work as TidyPlates internal nameplate.extended
      -- does not work as Kui_Nameplates internal nameplate.kui
      -- does not work as TidyPlates_ThreatPlates internal nameplate.TPFrame
      return nameplate.UnitFrame
    end
  else
    return nameplate
  end
end

local function checkIsHealer(nameplate, guid)
  local unit = nameplate.namePlateUnitToken

  local isPlayer = UnitIsPlayer(unit)
  local _, _, classId = UnitClass(unit)
  local canBeHealer = classId ~= nil and HEALER_CLASS_IDS[classId] == true

  if isPlayer and canBeHealer and not Healers[guid] then
    local tooltipData = GetUnitTooltip(unit)
    if tooltipData then
      if
        tooltipData.guid
        and tooltipData.lines
        and #tooltipData.lines >= 3
        and tooltipData.type == Enum.TooltipDataType.Unit
      then
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

function CreateIcon(nameplate, spellId, index)
  local icon = {}

  icon.spellId = spellId

  local iconFrame =
    CreateFrame("Frame", AddonName .. "IconFrame" .. "Spell" .. spellId .. "Index" .. index, nameplate.nptIconFrame)
  iconFrame:SetWidth(NS.db.global.iconSize)
  iconFrame:SetHeight(NS.db.global.iconSize)
  iconFrame:SetAlpha(NS.db.global.iconAlpha)
  iconFrame:Hide()
  icon.frame = iconFrame

  PlaceIcon(nameplate, icon)

  icon.cooldownFrame = CreateFrame("Cooldown", nil, iconFrame, "CooldownFrameTemplate")
  icon.cooldownFrame:SetAllPoints(iconFrame)
  icon.cooldownFrame:SetReverse(true)
  icon.cooldownFrame:SetHideCountdownNumbers(true)
  icon.cooldownFrame:SetDrawSwipe(true)
  icon.cooldownFrame:SetSwipeColor(0, 0, 0, 0.6)

  icon.texture = iconFrame:CreateTexture(nil, "BORDER")
  icon.texture:SetAllPoints(iconFrame)
  icon.texture:SetTexCoord(0, 1, 0, 1)

  icon.border = iconFrame:CreateTexture(nil, "OVERLAY")
  icon.border:SetAllPoints(iconFrame)
  icon.border:SetTexture("Interface\\AddOns\\NameplateTrinket\\CooldownFrameBorder.tga")
  icon.border:SetVertexColor(1, 0.35, 0)
  icon.border:Hide()

  icon.cooldownText = nil

  local loadedOrLoading, loaded = IsAddOnLoaded("OmniCC")
  if loaded or loadedOrLoading then
    icon.cooldownText = nil
  else
    local fontScale = 1
    local timerScale = NS.db.global.iconSize - NS.db.global.iconSize / 2
    local timerTextSize = mceil(timerScale)

    icon.cooldownText = iconFrame:CreateFontString(nil, "OVERLAY")
    icon.cooldownText:SetTextColor(0.7, 1, 0, 1)
    icon.cooldownText:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)

    if TimerTextUseRelativeScale then
      icon.cooldownText:SetFont("Fonts\\FRIZQT__.TTF", mceil(timerScale * fontScale), "OUTLINE")
    else
      icon.cooldownText:SetFont("Fonts\\FRIZQT__.TTF", timerTextSize, "OUTLINE")
    end
  end

  nameplate.nptIconCount = nameplate.nptIconCount + 1
  tinsert(nameplate.nptIcons, icon)
end

function CreateTestIcon(nameplate, spellId, index)
  local icon = {}

  icon.spellId = spellId

  local iconFrame = CreateFrame(
    "Frame",
    AddonName .. "TestIconFrame" .. "Spell" .. spellId .. "Index" .. index,
    nameplate.nptTestIconFrame
  )
  iconFrame:SetWidth(NS.db.global.iconSize)
  iconFrame:SetHeight(NS.db.global.iconSize)
  iconFrame:SetAlpha(NS.db.global.iconAlpha)
  iconFrame:Hide()
  icon.frame = iconFrame

  PlaceTestIcon(nameplate, icon)

  icon.cooldownFrame = CreateFrame("Cooldown", nil, iconFrame, "CooldownFrameTemplate")
  icon.cooldownFrame:SetAllPoints(iconFrame)
  icon.cooldownFrame:SetReverse(true)
  icon.cooldownFrame:SetHideCountdownNumbers(true)
  icon.cooldownFrame:SetDrawSwipe(true)
  icon.cooldownFrame:SetSwipeColor(0, 0, 0, 0.6)

  icon.texture = iconFrame:CreateTexture(nil, "BORDER")
  icon.texture:SetAllPoints(iconFrame)
  icon.texture:SetTexCoord(0, 1, 0, 1)

  icon.border = iconFrame:CreateTexture(nil, "OVERLAY")
  icon.border:SetAllPoints(iconFrame)
  icon.border:SetTexture("Interface\\AddOns\\NameplateTrinket\\CooldownFrameBorder.tga")
  icon.border:SetVertexColor(1, 0.35, 0)
  icon.border:Hide()

  local loadedOrLoading, loaded = IsAddOnLoaded("OmniCC")
  if loaded or loadedOrLoading then
    icon.cooldownText = nil
  else
    local fontScale = 1
    local timerScale = NS.db.global.iconSize - NS.db.global.iconSize / 2
    local timerTextSize = mceil(timerScale)

    icon.cooldownText = iconFrame:CreateFontString(nil, "OVERLAY")
    icon.cooldownText:SetTextColor(0.7, 1, 0, 1)
    icon.cooldownText:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)

    if TimerTextUseRelativeScale then
      icon.cooldownText:SetFont("Fonts\\FRIZQT__.TTF", mceil(timerScale * fontScale), "OUTLINE")
    else
      icon.cooldownText:SetFont("Fonts\\FRIZQT__.TTF", timerTextSize, "OUTLINE")
    end
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
      local dbInfo = NS.db.spells[spellId]
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
      local dbInfo = NS.db.spells[spellId]
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
  local unit = nameplate.namePlateUnitToken

  local isPlayer = UnitIsPlayer(unit)
  local isNpc = not isPlayer
  local isSelf = UnitIsUnit(unit, "player")
  local isFriend = UnitIsFriend("player", unit)
  local isEnemy = UnitIsEnemy("player", unit)
  -- local canAttack = UnitCanAttack("player", unit)
  -- local isHealer = (NS.isHealer("player") or Healers[guid]) and true or false
  local isDeadOrGhost = UnitIsDeadOrGhost(unit)
  local isAlive = not isDeadOrGhost
  local isTarget = UnitIsUnit(unit, "target")
  local targetExists = UnitExists("target")
  local isArena = NameplateTrinketFrame.instanceType == "arena"
  local isBattleground = NameplateTrinketFrame.instanceType == "pvp"
  local isOutdoors = NameplateTrinketFrame.instanceType == "none" or not IsInInstance()

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

  local targetIsUnit = targetExists and isTarget
  local hideDead = not isAlive
  local hideNonTargets = NS.db.global.targetOnly and (not targetExists or not targetIsUnit)
  local hideAllies = not NS.db.global.showOnAllies and isFriend
  local hideEnemies = not NS.db.global.showOnEnemies and isEnemy
  local hideOnSelf = not NS.db.global.showSelf and isSelf
  local hideNPCs = not NS.db.global.testNPCs and isNpc

  local hideOutsideArena = not NS.db.global.instanceTypes.arena and isArena
  local hideOutsideBattleground = not NS.db.global.instanceTypes.pvp and isBattleground
  local hideOutside = not NS.db.global.instanceTypes.none and isOutdoors
  local hideLocation = true
  if isArena then
    hideLocation = hideOutsideArena
  elseif isBattleground then
    hideLocation = hideOutsideBattleground
  elseif isOutdoors then
    hideLocation = hideOutside
  end

  local inInstance = IsInInstance()
  local testMode = NS.db.global.test
  local hideRules = hideNPCs or hideOnSelf or hideDead or hideAllies or hideEnemies or hideNonTargets or hideLocation
  local hideIcons = inInstance and hideRules or (not inInstance and (testMode or hideRules))

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
    local anchorFrame = NS.db.global.attachToHealthBar and GetAnchorFrame(nameplate) or nameplate
    -- Anchor -- Frame -- To Frame's -- offsetsX -- offsetsY
    nameplate.nptIconFrame:ClearAllPoints()
    nameplate.nptIconFrame:SetPoint(NS.db.global.anchor, anchorFrame, NS.db.global.anchorTo, NS.OFFSET.x, NS.OFFSET.y)
    nameplate.nptIconFrame:SetScale(1)
    nameplate.nptIcons = {}
    nameplate.nptIconCount = 0
  end

  nameplate.nptIconFrame:SetIgnoreParentAlpha(NS.db.global.ignoreNameplateAlpha)
  nameplate.nptIconFrame:SetIgnoreParentScale(NS.db.global.ignoreNameplateScale)
  nameplate.nptIconFrame:SetWidth(NS.db.global.iconSize)
  nameplate.nptIconFrame:SetHeight(NS.db.global.iconSize)
  local anchorFrame = NS.db.global.attachToHealthBar and GetAnchorFrame(nameplate) or nameplate
  -- Anchor -- Frame -- To Frame's -- offsetsX -- offsetsY
  nameplate.nptIconFrame:ClearAllPoints()
  nameplate.nptIconFrame:SetPoint(NS.db.global.anchor, anchorFrame, NS.db.global.anchorTo, NS.OFFSET.x, NS.OFFSET.y)

  addIcons(nameplate, guid)

  nameplate.nptIconFrame:Show()
end
NS.addNameplateIcons = addNameplateIcons

local function addNameplateTestIcons(nameplate, guid)
  local unit = nameplate.namePlateUnitToken

  local isPlayer = UnitIsPlayer(unit)
  local isNpc = not isPlayer
  local isSelf = UnitIsUnit(unit, "player")
  local isFriend = UnitIsFriend("player", unit)
  local isEnemy = UnitIsEnemy("player", unit)
  -- local canAttack = UnitCanAttack("player", unit)
  -- local isHealer = (NS.isHealer("player") or Healers[guid]) and true or false
  local isDeadOrGhost = UnitIsDeadOrGhost(unit)
  local isAlive = not isDeadOrGhost
  local isTarget = UnitIsUnit(unit, "target")
  local targetExists = UnitExists("target")
  local isArena = NameplateTrinketFrame.instanceType == "arena"
  local isBattleground = NameplateTrinketFrame.instanceType == "pvp"
  local isOutdoors = NameplateTrinketFrame.instanceType == "none" or not IsInInstance()

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

  local targetIsUnit = targetExists and isTarget
  local hideDead = not isAlive
  local hideNonTargets = NS.db.global.targetOnly and (not targetExists or not targetIsUnit)
  local hideAllies = not NS.db.global.showOnAllies and isFriend
  local hideEnemies = not NS.db.global.showOnEnemies and isEnemy
  local hideOnSelf = not NS.db.global.showSelf and isSelf
  local hideNPCs = not NS.db.global.testNPCs and isNpc

  local hideOutsideArena = not NS.db.global.instanceTypes.arena and isArena
  local hideOutsideBattleground = not NS.db.global.instanceTypes.pvp and isBattleground
  local hideOutside = not NS.db.global.instanceTypes.none and isOutdoors
  local hideLocation = true
  if isArena then
    hideLocation = hideOutsideArena
  elseif isBattleground then
    hideLocation = hideOutsideBattleground
  elseif isOutdoors then
    hideLocation = hideOutside
  end

  local inInstance = IsInInstance()
  local testMode = NS.db.global.test
  local hideRules = hideNPCs or hideOnSelf or hideDead or hideAllies or hideEnemies or hideNonTargets or hideLocation
  local hideIcons = inInstance and true or (not inInstance and (not testMode or hideRules))

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
    nameplate.nptTestIconFrame:SetScale(1)
    local anchorFrame = NS.db.global.attachToHealthBar and GetAnchorFrame(nameplate) or nameplate
    -- Anchor -- Frame -- To Frame's -- offsetsX -- offsetsY
    nameplate.nptTestIconFrame:ClearAllPoints()
    nameplate.nptTestIconFrame:SetPoint(
      NS.db.global.anchor,
      anchorFrame,
      NS.db.global.anchorTo,
      NS.OFFSET.x,
      NS.OFFSET.y
    )
    nameplate.nptTestIcons = {}
    nameplate.nptTestIconCount = 0
  end

  nameplate.nptTestIconFrame:SetIgnoreParentAlpha(NS.db.global.ignoreNameplateAlpha)
  nameplate.nptTestIconFrame:SetIgnoreParentScale(NS.db.global.ignoreNameplateScale)
  nameplate.nptTestIconFrame:SetWidth(NS.db.global.iconSize)
  nameplate.nptTestIconFrame:SetHeight(NS.db.global.iconSize)
  local anchorFrame = NS.db.global.attachToHealthBar and GetAnchorFrame(nameplate) or nameplate
  -- Anchor -- Frame -- To Frame's -- offsetsX -- offsetsY
  nameplate.nptTestIconFrame:ClearAllPoints()
  nameplate.nptTestIconFrame:SetPoint(NS.db.global.anchor, anchorFrame, NS.db.global.anchorTo, NS.OFFSET.x, NS.OFFSET.y)

  addTestIcons(nameplate, guid)

  nameplate.nptTestIconFrame:Show()
end
NS.addNameplateTestIcons = addNameplateTestIcons

function NS.RefreshTestSpells()
  local currentTime = GetTime()
  for nameplate, guid in pairs(NameplatesVisible) do
    if nameplate and nameplate.namePlateUnitToken and guid then
      if not TestSpellsPerPlayerGUID[guid] then
        TestSpellsPerPlayerGUID[guid] = {}
      end
      if not TestSpellsPerPlayerGUID[guid][SPELL_PVPTRINKET] then
        TestSpellsPerPlayerGUID[guid][SPELL_PVPTRINKET] = {
          ["spellId"] = SPELL_PVPTRINKET,
          ["expires"] = currentTime + (Healers[guid] and 90 or 120),
          ["texture"] = NS.db.spells[SPELL_PVPTRINKET] and NS.db.spells[SPELL_PVPTRINKET].spellIcon
            or SpellTextureByID[SPELL_PVPTRINKET],
          ["duration"] = (Healers[guid] and 90 or 120),
          ["started"] = currentTime,
        }
      else
        if currentTime - TestSpellsPerPlayerGUID[guid][SPELL_PVPTRINKET].expires > 0 then
          TestSpellsPerPlayerGUID[guid][SPELL_PVPTRINKET] = {
            ["spellId"] = SPELL_PVPTRINKET,
            ["expires"] = currentTime + (Healers[guid] and 90 or 120),
            ["texture"] = NS.db.spells[SPELL_PVPTRINKET] and NS.db.spells[SPELL_PVPTRINKET].spellIcon
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
              ["texture"] = NS.db.spells[spellId] and NS.db.spells[spellId].spellIcon or SpellTextureByID[spellId],
              ["duration"] = cd,
              ["started"] = currentTime,
            }
          else
            if currentTime - TestSpellsPerPlayerGUID[guid][spellId].expires > 0 then
              TestSpellsPerPlayerGUID[guid][spellId] = {
                ["spellId"] = spellId,
                ["expires"] = currentTime + cd,
                ["texture"] = NS.db.spells[spellId] and NS.db.spells[spellId].spellIcon or SpellTextureByID[spellId],
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
  if NS.db and NS.db.global.test and TestFrame then
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
    if nameplate and nameplate.UnitFrame and nameplate.nptIconFrame then
      nameplate.nptIconFrame:SetIgnoreParentAlpha(NS.db.global.ignoreNameplateAlpha)
      nameplate.nptIconFrame:SetIgnoreParentScale(NS.db.global.ignoreNameplateScale)
      local anchorFrame = NS.db.global.attachToHealthBar and GetAnchorFrame(nameplate) or nameplate
      nameplate.nptIconFrame:ClearAllPoints()
      nameplate.nptIconFrame:SetPoint(NS.db.global.anchor, anchorFrame, NS.db.global.anchorTo, NS.OFFSET.x, NS.OFFSET.y)
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
      if nameplate and nameplate.namePlateUnitToken and guid then
        addNameplateIcons(nameplate, guid)
      end
    end
  end
end

function ReallocateTestIcons(clearSpells)
  for nameplate in pairs(Nameplates) do
    if nameplate and nameplate.UnitFrame and nameplate.nptTestIconFrame then
      nameplate.nptTestIconFrame:SetIgnoreParentAlpha(NS.db.global.ignoreNameplateAlpha)
      nameplate.nptTestIconFrame:SetIgnoreParentScale(NS.db.global.ignoreNameplateScale)
      local anchorFrame = NS.db.global.attachToHealthBar and GetAnchorFrame(nameplate) or nameplate
      nameplate.nptTestIconFrame:ClearAllPoints()
      nameplate.nptTestIconFrame:SetPoint(
        NS.db.global.anchor,
        anchorFrame,
        NS.db.global.anchorTo,
        NS.OFFSET.x,
        NS.OFFSET.y
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
      if nameplate and nameplate.namePlateUnitToken and guid then
        addNameplateTestIcons(nameplate, guid)
      end
    end
  end
end

function NameplateTrinket:detachFromNameplate(nameplate)
  NameplatesVisible[nameplate] = false

  if nameplate.nptTestIconFrame ~= nil then
    nameplate.nptTestIconFrame:Hide()
  end
  if nameplate.nptIconFrame ~= nil then
    nameplate.nptIconFrame:Hide()
  end
end

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
    local attachmentFrame = nameplate
    nameplate.rbgdAnchorFrame = CreateFrame("Frame", nil, attachmentFrame)
    nameplate.rbgdAnchorFrame:SetFrameStrata("HIGH")
    nameplate.rbgdAnchorFrame:SetFrameLevel(attachmentFrame:GetFrameLevel() + 1)
  end

  checkIsHealer(nameplate, guid)

  addNameplateIcons(nameplate, guid)
  if NS.db and NS.db.global.test and not IsInInstance() then
    addNameplateTestIcons(nameplate, guid)
  end
end

local function refreshNameplates(override)
  if not override and NameplateTrinketFrame.wasOnLoadingScreen then
    return
  end

  for _, nameplate in pairs(GetNamePlates(issecure())) do
    if nameplate then
      local guid = UnitGUID(nameplate.namePlateUnitToken)
      if guid then
        NameplateTrinket:attachToNameplate(nameplate, guid)
      end
    end
  end
end

-- unitId == unitToken, UnitGUID takes unitId, formely unitToken, as its param
function NameplateTrinket:NAME_PLATE_UNIT_REMOVED(unitToken)
  local nameplate = GetNamePlateForUnit(unitToken, issecure())

  if nameplate then
    self:detachFromNameplate(nameplate)
  end
end

function NameplateTrinket:NAME_PLATE_CREATED(namePlateFrame)
  -- print("NAME_PLATE_CREATED", namePlateFrame)
end

-- UnitIsPlayer takes unitToken
-- C_PlayerInfo.GUIDIsPlayer takes unitGUID
function NameplateTrinket:NAME_PLATE_UNIT_ADDED(unitToken)
  local nameplate = GetNamePlateForUnit(unitToken, issecure())
  local guid = UnitGUID(unitToken)

  if nameplate and guid then
    self:attachToNameplate(nameplate, guid)
  end
end

function NameplateTrinket:PLAYER_TARGET_CHANGED()
  ReallocateIcons(true)
  if NS.db and NS.db.global.test and not IsInInstance() then
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
  if NS.db.global.test and not IsInInstance() then
    return
  end
  if not NS.db.global.instanceTypes.arena and NameplateTrinketFrame.instanceType == "arena" then
    return
  elseif not NS.db.global.instanceTypes.pvp and NameplateTrinketFrame.instanceType == "pvp" then
    return
  elseif
    not NS.db.global.instanceTypes.none and (NameplateTrinketFrame.instanceType == "none" or not IsInInstance())
  then
    return
  elseif
    NameplateTrinketFrame.instanceType == "raid"
    or NameplateTrinketFrame.instanceType == "party"
    or NameplateTrinketFrame.instanceType == "unknown"
  then
    return
  end
  local _, subevent, _, sourceGUID, _, sourceFlags, _, destGUID, _, destFlags, _ = CombatLogGetCurrentEventInfo()
  if not (sourceGUID or destGUID) then
    return
  end
  local hideForSelf = not NS.db.global.showSelf and sourceGUID == UnitGUID("player")
  if hideForSelf then
    return
  end
  local isMindControlled = false
  local isNotPetOrPlayer = false
  local isPlayer = bband(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0
  if not isPlayer then
    -- UnitPlayerControlled -- https://warcraft.wiki.gg/wiki/API_UnitPlayerControlled
    if sfind(destGUID, "Player-") then
      -- Players have same bitmask as player pets when they're mindcontrolled and MC aura breaks, so we need to distinguish these
      -- so we can ignore the player pets but not actual players
      isMindControlled = true
    end
    if not isMindControlled then
      return
    end
    if bband(destFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) <= 0 then -- is not player pet or is not MCed
      isNotPetOrPlayer = true
    end
  end
  local spellId = select(12, CombatLogGetCurrentEventInfo())
  if spellId then
    if bband(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= 0 or (NS.db.global.showOnAllies == true) then
      local entry = NS.db.spells[spellId]
      if entry ~= nil and entry.enabled then
        local cooldown = tonumber(entry.cooldown)
        if cooldown ~= nil and cooldown > 0 then
          local trinketOnly = NS.db.global.trinketOnly and not Trinkets[spellId]
          if trinketOnly then
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
            end
            if
              spellId == SPELL_PVPTRINKET
              and NS.db.spells[SPELL_PVPTRINKET] ~= nil
              and NS.db.spells[SPELL_PVPTRINKET].enabled
              and Healers[sourceGUID] == true
            then
              local existingEntry = SpellsPerPlayerGUID[sourceGUID][SPELL_PVPTRINKET]
              if existingEntry then
                existingEntry.expires = existingEntry.expires - 30
                existingEntry.duration = existingEntry.duration - 30
              end
            end
            for nameplate, guid in pairs(NameplatesVisible) do
              if nameplate and nameplate.namePlateUnitToken and guid and guid == sourceGUID then
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
            if nameplate and nameplate.namePlateUnitToken and guid and guid == sourceGUID then
              addNameplateIcons(nameplate, guid)
              break
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

function NameplateTrinket:PLAYER_SPECIALIZATION_CHANGED()
  local guid = UnitGUID("player")
  if guid then
    if NS.isHealer("player") and not Healers[guid] then
      Healers[guid] = true
    end
  end
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
    if NS.db and NS.db.global.test then
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

    if NS.db and NS.db.global.test and not IsInInstance() then
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
          local unitToken = UnitTokenFromGUID(tooltipData.guid)
          if not unitToken then
            return
          end
          local isPlayer = UnitIsPlayer(unitToken)
          local _, _, classId = UnitClass(unitToken)
          local canBeHealer = classId ~= nil and HEALER_CLASS_IDS[classId] == true
          if not isPlayer or not canBeHealer or Healers[tooltipData.guid] == true then
            return
          end
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
  TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipSetItem)

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
          if nameplate and nameplate.namePlateUnitToken and guid then
            addNameplateIcons(nameplate, guid)
          end
        end
        timeElapsed = 0
      end
    end)

    NameplateTrinketFrame:RegisterEvent("NAME_PLATE_CREATED")
    NameplateTrinketFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    NameplateTrinketFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    NameplateTrinketFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
    NameplateTrinketFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    NameplateTrinketFrame:RegisterEvent("PVP_MATCH_ACTIVE")
    NameplateTrinketFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    NameplateTrinketFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    if NS.db and NS.db.global.targetOnly then
      NameplateTrinketFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    end
  end
end

function NameplateTrinket:PLAYER_LOGIN()
  NameplateTrinketFrame:UnregisterEvent("PLAYER_LOGIN")

  NS.INSTANCE_TYPES = {
    -- nil resolves to "unknown"
    -- "unknown" - Used by a single map: Void Zone: Arathi Highlands (2695)
    ["unknown"] = false, -- when in an unknown instance
    ["none"] = NS.db and NS.db.global.instanceTypes.none or NS.DefaultDatabase.global.instanceTypes.none, -- when outside an instance
    ["pvp"] = NS.db and NS.db.global.instanceTypes.pvp or NS.DefaultDatabase.global.instanceTypes.pvp, --  when in a battleground
    ["arena"] = NS.db and NS.db.global.instanceTypes.arena or NS.DefaultDatabase.global.instanceTypes.arena, -- when in an arena
    ["party"] = false, -- when in a 5-man instance
    ["raid"] = false, -- when in a raid instance
    ["scenario"] = false, -- when in a scenario
  }

  NameplateTrinketFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  NameplateTrinketFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
  NameplateTrinketFrame:RegisterEvent("LOADING_SCREEN_ENABLED")
  NameplateTrinketFrame:RegisterEvent("LOADING_SCREEN_DISABLED")
end
NameplateTrinketFrame:RegisterEvent("PLAYER_LOGIN")

function NS.OnDbChanged()
  NameplateTrinketFrame.dbChanged = true

  if NS.db and NS.db.global.targetOnly then
    NameplateTrinketFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
  else
    NameplateTrinketFrame:UnregisterEvent("PLAYER_TARGET_CHANGED")
  end

  NS.INSTANCE_TYPES = {
    -- nil resolves to "unknown"
    ["unknown"] = false, -- when in an unknown instance
    ["none"] = NS.db.global.instanceTypes.none, -- when outside an instance
    ["pvp"] = NS.db.global.instanceTypes.pvp, --  when in a battleground
    ["arena"] = NS.db.global.instanceTypes.arena, -- when in an arena
    ["party"] = false, -- when in a 5-man instance
    ["raid"] = false, -- when in a raid instance
    ["scenario"] = false, -- when in a scenario
  }

  ReallocateIcons(true)
  if NS.db and NS.db.global.test and not IsInInstance() then
    ReallocateTestIcons(true)
  end

  NameplateTrinketFrame.dbChanged = false
end

function NS.Options_SlashCommands(_)
  AceConfigDialog:Open(AddonName)
end

function NS.Options_Setup()
  AceConfig:RegisterOptionsTable(AddonName, NS.AceConfig)
  AceConfigDialog:AddToBlizOptions(AddonName, AddonName)

  SLASH_NPT1 = "/nameplatetrinket"
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

    NS.MigrateDB(NameplateTrinketDB)

    -- Reference to active db profile
    -- Always use this directly or reference will be invalid
    --- @type Database
    NS.db = NameplateTrinketDB

    -- Remove table values no longer found in default settings
    NS.CleanupDB(NameplateTrinketDB, NS.DefaultDatabase)

    --- @class OFFSET
    NS.OFFSET = {
      x = NS.db.global.offsetX,
      y = NS.db.global.offsetY,
    }

    NS.BuildOptions()

    NS.Options_Setup()
  end
end
NameplateTrinketFrame:RegisterEvent("ADDON_LOADED")
