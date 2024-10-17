local AddonName, NS = ...

local LibStub = LibStub
local CreateFrame = CreateFrame
local pairs = pairs
local UnitGUID = UnitGUID
local GetTime = GetTime
local IsInInstance = IsInInstance
local issecure = issecure
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local print = print
local next = next

local mmax = math.max
local tinsert = table.insert
local tsort = table.sort
local wipe = table.wipe
local bband = bit.band

local After = C_Timer.After
local GetNamePlates = C_NamePlate.GetNamePlates
local GUIDIsPlayer = C_PlayerInfo.GUIDIsPlayer
local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit

local Interrupts = NS.Interrupts
local Trinkets = NS.Trinkets

local LHT = LibStub("LibHealerTracker-1.0")

local NameplateTrinket = {}
NS.NameplateTrinket = NameplateTrinket

local NameplateTrinketFrame = CreateFrame("Frame", AddonName .. "Frame")
NameplateTrinketFrame:SetScript("OnEvent", function(_, event, ...)
  if NameplateTrinket[event] then
    NameplateTrinket[event](NameplateTrinket, ...)
  end
end)
NS.NameplateTrinket.frame = NameplateTrinketFrame

-- Consts
local SPELL_PVPADAPTATION, SPELL_PVPTRINKET, SORT_MODE_NONE
local SORT_MODE_TRINKET_INTERRUPT_OTHER, SORT_MODE_INTERRUPT_TRINKET_OTHER, SORT_MODE_TRINKET_OTHER, SORT_MODE_INTERRUPT_OTHER
do
  SPELL_PVPADAPTATION, SPELL_PVPTRINKET, SPELL_RESET = NS.SPELL_PVPADAPTATION, NS.SPELL_PVPTRINKET, NS.SPELL_RESET
  SORT_MODE_NONE, SORT_MODE_TRINKET_INTERRUPT_OTHER, SORT_MODE_INTERRUPT_TRINKET_OTHER, SORT_MODE_TRINKET_OTHER, SORT_MODE_INTERRUPT_OTHER =
    NS.SORT_MODE_NONE,
    NS.SORT_MODE_TRINKET_INTERRUPT_OTHER,
    NS.SORT_MODE_INTERRUPT_TRINKET_OTHER,
    NS.SORT_MODE_TRINKET_OTHER,
    NS.SORT_MODE_INTERRUPT_OTHER
end

-- Utilities
local SpellTextureByID, SpellNameByID = NS.SpellTextureByID, NS.SpellNameByID

local SpellsPerPlayerGUID = {}

local ElapsedTimer = 0
local Nameplates = {}
local NameplatesVisible = {}
local AllCooldowns = {}
NS.AllCooldowns = AllCooldowns
local EventFrame, TestFrame, LocalPlayerGUID

EventFrame = CreateFrame("Frame")
EventFrame:SetScript("OnEvent", function(self, event, ...)
  self[event](...)
end)

local AllocateIcon, ReallocateAllIcons, UpdateOnlyOneNameplate, HideCDIcon, ShowCDIcon, OnUpdate

-------------------------------------------------------------------------------------------------
----- Initialize
-------------------------------------------------------------------------------------------------
do
  function NS.GetDefaultDBEntryForSpell()
    return {
      ["enabled"] = true,
    }
  end

  function NS.BuildCooldownValues()
    wipe(AllCooldowns)

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
end

-------------------------------------------------------------------------------------------------
----- Nameplates
-------------------------------------------------------------------------------------------------
do
  local function SetIconPlace(frame, icon, iconIndex)
    icon:ClearAllPoints()
    local index = iconIndex == nil and frame.NCIconsCount or (iconIndex - 1)
    if index == 0 then
      if NS.db.global.growDirection == "RIGHT" then
        icon:SetPoint("LEFT", frame.NCFrame, "LEFT", 0, 0)
      elseif NS.db.global.growDirection == "LEFT" then
        icon:SetPoint("RIGHT", frame.NCFrame, "RIGHT", 0, 0)
      end
    else
      if NS.db.global.growDirection == "RIGHT" then
        icon:SetPoint("LEFT", frame.NCIcons[index], "RIGHT", NS.db.global.iconSpacing, 0)
      elseif NS.db.global.growDirection == "LEFT" then
        icon:SetPoint("RIGHT", frame.NCIcons[index], "LEFT", -NS.db.global.iconSpacing, 0)
      end
    end
  end

  local function SetFrameSize(frame)
    local maxWidth, maxHeight = 0, 0
    if frame.NCFrame then
      for _, icon in pairs(frame.NCIcons) do
        if icon.shown then
          maxHeight = mmax(maxHeight, icon:GetHeight())
          maxWidth = maxWidth + icon:GetWidth() + NS.db.global.iconSpacing
        end
      end
    end
    maxWidth = maxWidth - NS.db.global.iconSpacing
    maxHeight = maxHeight -- maxHeight - NS.db.global.iconSpacing
    frame.NCFrame:SetWidth(mmax(maxWidth, 1))
    frame.NCFrame:SetHeight(mmax(maxHeight, 1))
  end

  function HideCDIcon(icon, frame)
    icon.border:Hide()
    icon.borderState = nil
    icon:Hide()
    icon.shown = false
    icon.textureID = 0
    SetFrameSize(frame)
  end

  function ShowCDIcon(icon, frame)
    icon:Show()
    icon.shown = true
    SetFrameSize(frame)
  end

  local function GetNameplateAddonFrame(nameplate)
    local frame = nameplate
    if Plater and frame.UnitFrame and frame.UnitFrame.PlaterOnScreen then
      frame = frame.UnitFrame.healthBar
    elseif frame.kui and frame.kui.bg and frame.kui:IsShown() then
      frame = frame.kui.bg
    elseif ElvUIPlayerNamePlateAnchor then
      frame = ElvUIPlayerNamePlateAnchor
    elseif frame.UnitFrame then
      frame = frame.UnitFrame.healthBar
    end

    return frame
  end

  function AllocateIcon(frame)
    if not frame.NCFrame then
      frame.NCFrame = CreateFrame("frame", nil, frame)
      frame.NCFrame:SetIgnoreParentAlpha(NS.db.global.ignoreNameplateAlpha)
      frame.NCFrame:SetIgnoreParentScale(NS.db.global.ignoreNameplateScale)
      frame.NCFrame:SetWidth(NS.db.global.iconSize)
      frame.NCFrame:SetHeight(NS.db.global.iconSize)
      local anchorFrame = GetNameplateAddonFrame(frame)
      frame.NCFrame:SetPoint(
        NS.db.global.anchor,
        anchorFrame,
        NS.db.global.anchorTo,
        NS.db.global.offsetX,
        NS.db.global.offsetY
      )
      frame.NCFrame:Show()
    end
    local icon = CreateFrame("frame", nil, frame.NCFrame)
    icon:SetWidth(NS.db.global.iconSize)
    icon:SetHeight(NS.db.global.iconSize)
    SetIconPlace(frame, icon)
    icon:Hide()

    icon.cooldownFrame = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    icon.cooldownFrame:SetAllPoints(icon)
    icon.cooldownFrame:SetReverse(true)
    -- icon.cooldownFrame:SetHideCountdownNumbers(true)
    -- icon.cooldownFrame.noCooldownCount = true -- refuse OmniCC

    icon.texture = icon:CreateTexture(nil, "BORDER")
    icon.texture:SetAllPoints(icon)
    icon.border = icon:CreateTexture(nil, "OVERLAY")
    icon.border:SetTexture("Interface\\AddOns\\NameplateTrinket\\CooldownFrameBorder.tga")
    icon.border:SetVertexColor(1, 0.35, 0)
    icon.border:SetAllPoints(icon)
    icon.border:Hide()
    frame.NCIconsCount = frame.NCIconsCount + 1
    tinsert(frame.NCIcons, icon)
  end

  function ReallocateAllIcons(clearSpells)
    for frame in pairs(Nameplates) do
      if frame.NCFrame then
        frame.NCFrame:SetIgnoreParentAlpha(NS.db.global.ignoreNameplateAlpha)
        frame.NCFrame:SetIgnoreParentScale(NS.db.global.ignoreNameplateScale)
        frame.NCFrame:ClearAllPoints()
        local anchorFrame = GetNameplateAddonFrame(frame)
        frame.NCFrame:SetPoint(
          NS.db.global.anchor,
          anchorFrame,
          NS.db.global.anchorTo,
          NS.db.global.offsetX,
          NS.db.global.offsetY
        )
        local counter = 0
        for iconIndex, icon in pairs(frame.NCIcons) do
          icon:SetWidth(NS.db.global.iconSize)
          icon:SetHeight(NS.db.global.iconSize)
          SetIconPlace(frame, icon, iconIndex)
          icon.texture:SetTexCoord(0, 1, 0, 1)
          if clearSpells then
            HideCDIcon(icon, frame)
          end
          counter = counter + 1
        end
        SetFrameSize(frame)
      end
    end
    if clearSpells then
      OnUpdate()
    end
  end

  local function GlobalFilterNameplate(unitGUID)
    if not NS.db.global.targetOnly or UnitGUID("target") == unitGUID then
      local matchesInstance = true
      if matchesInstance then
        return true
      end
    end
    return false
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

  local function SetCooldown(icon, started, cooldownLength, isActive)
    -- cooldown animation
    if isActive then
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

  local MinCdDuration = 0
  local MaxCdDuration = 10 * 3600

  local function FilterSpell(_dbInfo, _remain, _isActiveCD, spellID)
    if not _dbInfo or not _dbInfo.enabled then
      return false
    end

    if not _isActiveCD then
      return false
    end

    if NS.db.global.trinketOnly and spellID ~= SPELL_PVPTRINKET then
      return false
    end

    if _remain > 0 and (_remain < MinCdDuration or _remain > MaxCdDuration) then
      return false
    end

    return true
  end

  function UpdateOnlyOneNameplate(frame, unitGUID)
    if unitGUID == LocalPlayerGUID then
      return
    end
    local counter = 1
    if GlobalFilterNameplate(unitGUID) then
      if SpellsPerPlayerGUID[unitGUID] then
        local currentTime = GetTime()
        local sortedCDs = SortAuras(SpellsPerPlayerGUID[unitGUID])
        for _, spellInfo in pairs(sortedCDs) do
          local spellID = spellInfo.spellID
          local isActiveCD = spellInfo.expires > currentTime
          local dbInfo = NS.db.global.SpellCDs[spellID]
          local remain = spellInfo.expires - currentTime
          if FilterSpell(dbInfo, remain, isActiveCD, spellID) then
            if counter > frame.NCIconsCount then
              AllocateIcon(frame)
            end
            local icon = frame.NCIcons[counter]
            SetTexture(icon, spellInfo.texture, isActiveCD)
            local cooldown = AllCooldowns[spellID]
            SetCooldown(icon, spellInfo.started, cooldown, isActiveCD)
            SetBorder(icon, spellID, isActiveCD)
            if not icon.shown then
              ShowCDIcon(icon, frame)
            end
            counter = counter + 1
          end
        end
      end
    end
    for k = counter, frame.NCIconsCount do
      local icon = frame.NCIcons[k]
      if icon.shown then
        HideCDIcon(icon, frame)
      end
    end
  end
end

-------------------------------------------------------------------------------------------------
----- OnUpdates
-------------------------------------------------------------------------------------------------
do
  function OnUpdate()
    for frame, unitGUID in pairs(NameplatesVisible) do
      UpdateOnlyOneNameplate(frame, unitGUID)
    end
  end
end

-------------------------------------------------------------------------------------------------
----- Test mode
-------------------------------------------------------------------------------------------------
do
  local _t = 0
  local _charactersDB
  local _spellCDs
  local _spellIDs = {
    [378464] = 90,
    [20589] = 60,
    [354489] = 20,
  }

  local function refreshCDs()
    local cTime = GetTime()
    for _, unitGUID in pairs(NameplatesVisible) do
      if not SpellsPerPlayerGUID[unitGUID] then
        SpellsPerPlayerGUID[unitGUID] = {}
      end
      SpellsPerPlayerGUID[unitGUID][SPELL_PVPTRINKET] = {
        ["spellID"] = SPELL_PVPTRINKET,
        ["expires"] = cTime + 120,
        ["texture"] = SpellTextureByID[SPELL_PVPTRINKET],
        ["started"] = cTime,
      } -- // 2m test
      if not NS.db.global.trinketOnly then
        for spellID, cd in pairs(_spellIDs) do
          if not SpellsPerPlayerGUID[unitGUID][spellID] then
            SpellsPerPlayerGUID[unitGUID][spellID] = {
              ["spellID"] = spellID,
              ["expires"] = cTime + cd,
              ["texture"] = SpellTextureByID[spellID],
              ["started"] = cTime,
            }
          else
            if cTime - SpellsPerPlayerGUID[unitGUID][spellID]["expires"] > 0 then
              SpellsPerPlayerGUID[unitGUID][spellID] = {
                ["spellID"] = spellID,
                ["expires"] = cTime + cd,
                ["texture"] = SpellTextureByID[spellID],
                ["started"] = cTime,
              }
            end
          end
        end
      end
    end
  end

  function NS.EnableTestMode()
    if not IsInInstance() and not NS.IN_DUEL then
      for nameplate, _ in pairs(Nameplates) do
        nameplate.NCFrame = nil
        nameplate.NCIcons = {}
        nameplate.NCIconsCount = 0 -- // it's faster than #nameplate.NCIcons
        Nameplates[nameplate] = true
        NameplatesVisible[nameplate] = nil
      end

      -- https://warcraft.wiki.gg/wiki/API_C_NamePlate.GetNamePlates
      -- https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/AddOns/Blizzard_NamePlates/Blizzard_NamePlates.lua#L264
      for _, nameplate in pairs(GetNamePlates(issecure())) do
        local unitID = nameplate.namePlateUnitToken
        local unitGUID = UnitGUID(unitID)
        if
          nameplate
          and unitGUID
          and unitGUID ~= LocalPlayerGUID
          and GUIDIsPlayer(unitGUID)
          and not NameplatesVisible[nameplate]
        then
          NameplatesVisible[nameplate] = unitGUID
          if not Nameplates[nameplate] then
            nameplate.NCFrame = nil
            nameplate.NCIcons = {}
            nameplate.NCIconsCount = 0 -- // it's faster than #nameplate.NCIcons
            Nameplates[nameplate] = true
          end
        end
      end

      NameplateTrinketFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
      NameplateTrinketFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    end

    _charactersDB = NS.deepcopy(SpellsPerPlayerGUID)
    _spellCDs = NS.deepcopy(NS.db.global.SpellCDs)
    NS.db.global.SpellCDs[SPELL_PVPTRINKET] = NS.GetDefaultDBEntryForSpell()
    NS.db.global.SpellCDs[SPELL_PVPTRINKET].enabled = true
    if not NS.db.global.trinketOnly then
      for spellID in pairs(_spellIDs) do
        NS.db.global.SpellCDs[spellID] = NS.GetDefaultDBEntryForSpell()
        NS.db.global.SpellCDs[spellID].enabled = true
      end
    end
    if not TestFrame then
      TestFrame = CreateFrame("frame")
      TestFrame:SetScript("OnEvent", function()
        NS.DisableTestMode()
      end)
    end
    TestFrame:SetScript("OnUpdate", function(_, elapsed)
      _t = _t + elapsed
      if _t >= 2 then
        refreshCDs()
        _t = 0
      end
    end)
    refreshCDs() -- // for instant start
    OnUpdate() -- // for instant start
    NS.TestModeActive = true
  end

  function NS.DisableTestMode()
    if not IsInInstance() and not NS.IN_DUEL then
      NameplateTrinketFrame:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
      NameplateTrinketFrame:UnregisterEvent("NAME_PLATE_UNIT_REMOVED")
    end

    TestFrame:SetScript("OnUpdate", nil)
    SpellsPerPlayerGUID = NS.deepcopy(_charactersDB)
    NS.db.global.SpellCDs = NS.deepcopy(_spellCDs)
    OnUpdate() -- // for instant start
    NS.TestModeActive = false
  end

  NS.OnDbChanged = function(clearSpells)
    if NS.db.global.targetOnly then
      if IsInInstance() then
        NameplateTrinketFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
      end
    else
      NameplateTrinketFrame:UnregisterEvent("PLAYER_TARGET_CHANGED")
    end

    if clearSpells then
      if not IsInInstance() then
        if NS.db.global.test then
          -- maybe new function to wipe non-trinket test spells only
          NS.DisableTestMode()
          NS.EnableTestMode()
        end
      else
        OnUpdate()
      end
    end

    if not IsInInstance() then
      ReallocateAllIcons(true)
    end
  end
end

-------------------------------------------------------------------------------------------------
----- Frame for events
-------------------------------------------------------------------------------------------------
do
  function NameplateTrinket:COMBAT_LOG_EVENT_UNFILTERED()
    local cTime = GetTime()
    local _, eventType, _, srcGUID, _, srcFlags, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()
    if
      bband(srcFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= 0
      or (NS.db.global.showOnAllies == true and srcGUID ~= LocalPlayerGUID)
    then
      if NS.db.global.trinketOnly then
        if spellID == SPELL_PVPTRINKET then
          local entry = NS.db.global.SpellCDs[SPELL_PVPTRINKET]
          local cooldown = AllCooldowns[SPELL_PVPTRINKET]
          if cooldown ~= nil and entry and entry.enabled then
            if
              eventType == "SPELL_CAST_SUCCESS"
              or eventType == "SPELL_AURA_APPLIED"
              or eventType == "SPELL_MISSED"
              or eventType == "SPELL_SUMMON"
            then
              if not SpellsPerPlayerGUID[srcGUID] then
                SpellsPerPlayerGUID[srcGUID] = {}
              end
              local expires = cTime + cooldown
              SpellsPerPlayerGUID[srcGUID][SPELL_PVPTRINKET] = {
                ["spellID"] = SPELL_PVPTRINKET,
                ["expires"] = expires,
                ["texture"] = SpellTextureByID[SPELL_PVPTRINKET],
                ["started"] = cTime,
              }
              for frame, unitGUID in pairs(NameplatesVisible) do
                if unitGUID == srcGUID then
                  UpdateOnlyOneNameplate(frame, unitGUID)
                  break
                end
              end
            end
          end
        end
      else
        local entry = NS.db.global.SpellCDs[spellID]
        local cooldown = AllCooldowns[spellID]
        if cooldown ~= nil and entry and entry.enabled then
          if
            eventType == "SPELL_CAST_SUCCESS"
            or eventType == "SPELL_AURA_APPLIED"
            or eventType == "SPELL_MISSED"
            or eventType == "SPELL_SUMMON"
          then
            if not SpellsPerPlayerGUID[srcGUID] then
              SpellsPerPlayerGUID[srcGUID] = {}
            end
            local expires = cTime + cooldown
            SpellsPerPlayerGUID[srcGUID][spellID] = {
              ["spellID"] = spellID,
              ["expires"] = expires,
              ["texture"] = SpellTextureByID[spellID],
              ["started"] = cTime,
            }
            for frame, unitGUID in pairs(NameplatesVisible) do
              if unitGUID == srcGUID then
                UpdateOnlyOneNameplate(frame, unitGUID)
                break
              end
            end
          end
        end
      end
      -- reset
      if eventType == "SPELL_AURA_APPLIED" and spellID == SPELL_RESET then
        if SpellsPerPlayerGUID[srcGUID] then
          SpellsPerPlayerGUID[srcGUID] = {}
          for frame, unitGUID in pairs(NameplatesVisible) do
            if unitGUID == srcGUID then
              UpdateOnlyOneNameplate(frame, unitGUID)
              break
            end
          end
        end
      -- // pvptier 1/2 used, correcting cd of PvP trinket
      elseif
        eventType == "SPELL_AURA_APPLIED"
        and spellID == SPELL_PVPADAPTATION
        and NS.db.global.SpellCDs[SPELL_PVPTRINKET] ~= nil
        and NS.db.global.SpellCDs[SPELL_PVPTRINKET].enabled
      then
        if SpellsPerPlayerGUID[srcGUID] then
          SpellsPerPlayerGUID[srcGUID][SPELL_PVPTRINKET] = {
            ["spellID"] = SPELL_PVPTRINKET,
            ["expires"] = cTime + 60,
            ["texture"] = SpellTextureByID[SPELL_PVPTRINKET],
            ["started"] = cTime,
          }
          for frame, unitGUID in pairs(NameplatesVisible) do
            if unitGUID == srcGUID then
              UpdateOnlyOneNameplate(frame, unitGUID)
              break
            end
          end
        end
      -- caster is a healer, reducing cd of pvp trinket
      elseif
        eventType == "SPELL_CAST_SUCCESS"
        and spellID == SPELL_PVPTRINKET
        and NS.db.global.SpellCDs[SPELL_PVPTRINKET] ~= nil
        and NS.db.global.SpellCDs[SPELL_PVPTRINKET].enabled
        and LHT.IsPlayerHealer(srcGUID)
      then
        if SpellsPerPlayerGUID[srcGUID] then
          local existingEntry = SpellsPerPlayerGUID[srcGUID][SPELL_PVPTRINKET]
          if existingEntry then
            existingEntry.expires = existingEntry.expires - 30
            for frame, unitGUID in pairs(NameplatesVisible) do
              if unitGUID == srcGUID then
                UpdateOnlyOneNameplate(frame, unitGUID)
                break
              end
            end
          end
        end
      end
    end
  end

  function NameplateTrinket:NAME_PLATE_UNIT_ADDED(unitID)
    local nameplate = GetNamePlateForUnit(unitID)
    local unitGUID = UnitGUID(unitID)
    if nameplate and unitGUID and GUIDIsPlayer(unitGUID) then
      NameplatesVisible[nameplate] = unitGUID
      if not Nameplates[nameplate] then
        nameplate.NCIcons = {}
        nameplate.NCIconsCount = 0 -- // it's faster than #nameplate.NCIcons
        Nameplates[nameplate] = true
      end
      if nameplate.NCFrame ~= nil and unitGUID ~= LocalPlayerGUID then
        nameplate.NCFrame:Show()
      end
      UpdateOnlyOneNameplate(nameplate, unitGUID)
    end
  end

  function NameplateTrinket:NAME_PLATE_UNIT_REMOVED(unitID)
    local nameplate = GetNamePlateForUnit(unitID)
    if nameplate and NameplatesVisible[nameplate] then
      NameplatesVisible[nameplate] = nil
      if nameplate.NCFrame ~= nil then
        nameplate.NCFrame:Hide()
      end
    end
  end

  function NameplateTrinket:PLAYER_TARGET_CHANGED()
    ReallocateAllIcons(true)
  end

  function NameplateTrinket:PVP_MATCH_ACTIVE()
    NS.Debug("PVP_MATCH_ACTIVE", IsInInstance())
    wipe(SpellsPerPlayerGUID)
  end

  function NameplateTrinket:PVP_MATCH_COMPLETE()
    NS.Debug("PVP_MATCH_COMPLETE", IsInInstance())
    wipe(SpellsPerPlayerGUID)
  end

  -- we care about out of combat always out of instances
  function NameplateTrinket:PLAYER_REGEN_ENABLED()
    if not IsInInstance() and not NS.IN_DUEL then
      wipe(SpellsPerPlayerGUID)
      ReallocateAllIcons(false)

      if NS.db.global.test then
        NS.EnableTestMode()
      end

      NameplateTrinketFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
      NameplateTrinketFrame:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
      NameplateTrinketFrame:UnregisterEvent("NAME_PLATE_UNIT_REMOVED")

      if NS.db.global.targetOnly then
        NameplateTrinketFrame:UnregisterEvent("PLAYER_TARGET_CHANGED")
      end
    end
  end

  -- we care about in combat always out of instances
  function NameplateTrinket:PLAYER_REGEN_DISABLED()
    if not IsInInstance() and not NS.IN_DUEL then
      if NS.db.global.test and TestFrame then
        NS.DisableTestMode()
      end

      NameplateTrinketFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
      NameplateTrinketFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
      NameplateTrinketFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

      if NS.db.global.targetOnly then
        NameplateTrinketFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
      end
    end
  end

  function NameplateTrinket:CHAT_MSG_SYSTEM(text)
    NS.Debug("CHAT_MSG_SYSTEM", text, IsInInstance())
    if not IsInInstance() then
      if text == "Duel starting: 3" or text == "Duel starting: 2" or text == "Duel starting: 1" then
        NameplateTrinketFrame:UnregisterEvent("CHAT_MSG_SYSTEM")

        NS.IN_DUEL = true

        if NS.db.global.test and TestFrame then
          NS.DisableTestMode()
        end

        wipe(SpellsPerPlayerGUID)
        ReallocateAllIcons(false)

        NameplateTrinketFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        NameplateTrinketFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
        NameplateTrinketFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

        if NS.db.global.targetOnly then
          NameplateTrinketFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
        end
      end
    end
  end

  function NameplateTrinket:DUEL_FINISHED()
    NS.Debug("DUEL_FINISHED", IsInInstance())
    NameplateTrinketFrame:UnregisterEvent("CHAT_MSG_SYSTEM")
    NS.IN_DUEL = false

    wipe(SpellsPerPlayerGUID)
    ReallocateAllIcons(false)

    if not IsInInstance() then
      if NS.db.global.test then
        NS.EnableTestMode()
      end

      NameplateTrinketFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
      NameplateTrinketFrame:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
      NameplateTrinketFrame:UnregisterEvent("NAME_PLATE_UNIT_REMOVED")

      if NS.db.global.targetOnly then
        NameplateTrinketFrame:UnregisterEvent("PLAYER_TARGET_CHANGED")
      end
    end
  end

  function NameplateTrinket:DUEL_REQUESTED(playerName)
    NS.Debug("DUEL_REQUESTED", playerName)
    NameplateTrinketFrame:RegisterEvent("CHAT_MSG_SYSTEM")
  end

  function NameplateTrinket:LOADING_SCREEN_DISABLED()
    NS.Debug("LOADING_SCREEN_DISABLED", IsInInstance(), NS.IN_DUEL, NS.db.global.test)
    if NS.db.global.test then
      if not IsInInstance() and not NS.IN_DUEL then
        wipe(SpellsPerPlayerGUID)
        ReallocateAllIcons(true)

        After(0, function()
          if NS.db.global.test then
            if not IsInInstance() and not NS.IN_DUEL then
              NS.EnableTestMode()
            end
          end
        end)
      end
    end
  end

  -- we onlu care about leaving world in instances
  function NameplateTrinket:PLAYER_LEAVING_WORLD()
    NS.Debug("PLAYER_LEAVING_WORLD", IsInInstance())
    wipe(SpellsPerPlayerGUID)

    if not IsInInstance() then
      NameplateTrinketFrame:UnregisterEvent("PLAYER_LEAVING_WORLD")
      NameplateTrinketFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
      NameplateTrinketFrame:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
      NameplateTrinketFrame:UnregisterEvent("NAME_PLATE_UNIT_REMOVED")

      if NS.db.global.targetOnly then
        NameplateTrinketFrame:UnregisterEvent("PLAYER_TARGET_CHANGED")
      end
    end
  end

  function NameplateTrinket:PLAYER_ENTERING_WORLD()
    NS.Debug("PLAYER_ENTERING_WORLD", IsInInstance(), NS.IN_DUEL, NS.db.global.test)
    wipe(SpellsPerPlayerGUID)
    ReallocateAllIcons(false)

    LHT.Subscribe(function(_guid, _)
      if SpellsPerPlayerGUID[_guid] then
        local existingEntry = SpellsPerPlayerGUID[_guid][SPELL_PVPTRINKET]
        if existingEntry then
          existingEntry.expires = existingEntry.expires - 30
          for frame, unitGUID in pairs(NameplatesVisible) do
            if unitGUID == _guid then
              UpdateOnlyOneNameplate(frame, unitGUID)
              break
            end
          end
        end
      end
    end)

    if IsInInstance() then
      if NS.db.global.test then
        for nameplate, _ in pairs(Nameplates) do
          nameplate.NCFrame = nil
          nameplate.NCIcons = {}
          nameplate.NCIconsCount = 0 -- // it's faster than #nameplate.NCIcons
          Nameplates[nameplate] = true
          NameplatesVisible[nameplate] = nil
        end

        if TestFrame then
          NS.DisableTestMode()
        end
      end

      NameplateTrinketFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
      NameplateTrinketFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
      NameplateTrinketFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
      NameplateTrinketFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

      if NS.db.global.targetOnly then
        NameplateTrinketFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
      end
    end
  end

  function NameplateTrinket:PLAYER_LOGIN()
    NS.Debug("PLAYER_LOGIN", IsInInstance())
    NameplateTrinketFrame:UnregisterEvent("PLAYER_LOGIN")

    LocalPlayerGUID = UnitGUID("player")
    NS.BuildCooldownValues()
    -- // starting OnUpdate()
    EventFrame:SetScript("OnUpdate", function(_, elapsed)
      ElapsedTimer = ElapsedTimer + elapsed
      if ElapsedTimer >= 1 then
        OnUpdate()
        ElapsedTimer = 0
      end
    end)

    NameplateTrinketFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    NameplateTrinketFrame:RegisterEvent("LOADING_SCREEN_DISABLED")

    NameplateTrinketFrame:RegisterEvent("PVP_MATCH_ACTIVE")
    NameplateTrinketFrame:RegisterEvent("PVP_MATCH_COMPLETE")
    NameplateTrinketFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    NameplateTrinketFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    NameplateTrinketFrame:RegisterEvent("DUEL_REQUESTED")
    NameplateTrinketFrame:RegisterEvent("DUEL_FINISHED")
  end
  NameplateTrinketFrame:RegisterEvent("PLAYER_LOGIN")

  function Options_SlashCommands(message)
    if message == "test" then
      if not NS.TestModeActive then
        if IsInInstance() then
          print("Can't test while in an instance")
        else
          NS.EnableTestMode()
        end
      else
        NS.DisableTestMode()
      end
    else
      LibStub("AceConfigDialog-3.0"):Open(AddonName)
    end
  end

  function Options_Setup()
    LibStub("AceConfig-3.0"):RegisterOptionsTable(AddonName, NS.AceConfig)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(AddonName, AddonName)

    SLASH_NPC1 = AddonName
    SLASH_NPC2 = "/npc"

    function SlashCmdList.NPC(message)
      Options_SlashCommands(message)
    end
  end

  function NameplateTrinket:ADDON_LOADED(addon)
    NameplateTrinketFrame:UnregisterEvent("ADDON_LOADED")

    if addon == AddonName then
      NS.Debug("ADDON_LOADED")
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
end
