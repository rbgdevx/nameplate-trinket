local AddonName, NS = ...

local _G = _G

local pairs = pairs
local select = select
local unpack = unpack
local CreateFrame = CreateFrame
local GetTime = GetTime
local GetPlayerInfoByGUID = GetPlayerInfoByGUID
local LibStub = LibStub
local UnitGUID = UnitGUID
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo

local band = bit.band
local floor = math.floor
local strfind = string.find

local UnitAura = C_UnitAuras.GetAuraDataByIndex
local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit

local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE
local COMBATLOG_OBJECT_REACTION_MASK = COMBATLOG_OBJECT_REACTION_MASK

---@type NameplateTrinket
local NameplateTrinket = NS.NameplateTrinket
local NameplateTrinketFrame = NS.NameplateTrinket.frame

local DRL = LibStub("DRList-1.0")
local LHT = LibStub("LibHealerTracker-1.0")

local DR_TIME = DRL.resetTimes.retail["default"]
local getUpdate = 0
local npUnitID = {}
local CDTimeCache = {}
local RSTimeCache = {}
local CDTextureCache = {}
local gradual = {}
local cooldown = {}
local UPDATE_INTERVAL = 0.25
local PGUID = UnitGUID("player")
local bordertex = {
  ["2px"] = "Interface\\AddOns\\NameplateTrinket\\media\\32x2px.tga",
  ["3px"] = "Interface\\AddOns\\NameplateTrinket\\media\\32x3px.tga",
}
local CommonIcon = {
  ["taunt"] = 355,
  ["incapacitate"] = 118,
  ["silence"] = 15487,
  ["disorient"] = 118699,
  ["stun"] = 408,
  ["root"] = 122,
  ["knockback"] = 236777,
  ["disarm"] = 236077,
}

function NameplateTrinket:Refresh()
  self:ClearValue(false)
end

local function GetAuraDuration(unitID, spellID)
  if not unitID then
    return
  end

  for i = 1, 40 do
    local aura = UnitAura(unitID, i, "HARMFUL")
    if not aura or not aura.spellId then
      return
    end -- no more debuffs

    if spellID == aura.spellId then
      return aura.duration, aura.expirationTime
    end
  end
end

local function isHarm(fl)
  local val = COMBATLOG_OBJECT_REACTION_HOSTILE
  if NS.db.global.gSetting.ShowFriendlyPlayer then
    val = COMBATLOG_OBJECT_REACTION_MASK
  end
  return band(fl, val)
end

local function isTarget(n, tar)
  local tn = UnitGUID(tar)
  return (tn and n == tn)
end

local function SetTextureChange(spellid)
  if spellid == 334693 then -- Absolute Zero
    spellid = 279302 -- Breath of Sindragosa
  end
  return spellid
end

local function CreateBorderTexture(FirstName, SecondName)
  local frame = CreateFrame("Frame", "NCT" .. FirstName .. SecondName)
  frame:SetFrameStrata("BACKGROUND")
  frame:SetSize(NS.db.global.gSetting.FrameSize, NS.db.global.gSetting.FrameSize)
  frame:SetPoint("TOP", UIParent, "TOP", 0, 100)
  frame.Texture = frame:CreateTexture(nil, "BACKGROUND")
  frame.Texture:SetAllPoints()

  frame.border = frame:CreateTexture(nil, "BORDER")
  frame.border:SetTexture(bordertex[NS.db.global.Func.IconBorder])
  frame.border:SetVertexColor(unpack(NS.db.global.Func.ColorBasc))
  frame.border:SetAllPoints()

  frame.c = CreateFrame("Cooldown", nil, frame) -- "CooldownFrameTemplate Frame IsVisible?
  frame.c:SetFrameLevel(frame:GetFrameLevel() + 2)
  local ctex = frame:CreateTexture(nil, "BACKGROUND") -- "CooldownFrameTemplate"
  ctex:SetColorTexture(1, 1, 1)
  frame.c:SetSwipeTexture(ctex:GetTexture() or "", 1, 1, 1, 1) -- Added missing arguments
  frame.c:SetSwipeColor(0, 0, 0, 0.6)
  frame.c:SetReverse(true)
  frame.c:SetDrawSwipe(NS.db.global.gSetting.CooldownSpiral)
  frame.c:SetHideCountdownNumbers(true) -- basic interface
  frame.c.noCooldownCount = true -- OmniCC
  frame.c:SetAllPoints()

  frame._font = CreateFrame("Cooldown")
  frame._font:SetFrameLevel(frame:GetFrameLevel() + 8)
  frame._font:SetHideCountdownNumbers(not NS.db.global.Func.FontEnable) -- basic interface
  frame._font.noCooldownCount = not NS.db.global.Func.FontEnable -- OmniCC
  frame._font:SetSize(NS.db.global.gSetting.FrameSize, NS.db.global.gSetting.FrameSize)
  frame._font:SetScale(NS.db.global.Func.FontScale)
  frame._font:SetPoint("CENTER", frame, NS.db.global.Func.FontPoint, 0, 0)
end

local function CreateDiminishFrame(tempGUID, tempSpellID, isApplied, isTest)
  local cat = NameplateTrinket:CheckCategory(tempSpellID)
  if not cat then
    return
  end

  if not gradual[tempGUID] then
    gradual[tempGUID] = {}
  end

  if not gradual[tempGUID][cat] then
    CreateBorderTexture(cat, tempGUID)
    gradual[tempGUID][cat] = _G["NCT" .. cat .. tempGUID]
    gradual[tempGUID][cat].c:SetScript("OnHide", function(self)
      self.count = nil
    end)
  end

  local frame = gradual[tempGUID][cat]
  local fTime, expTime

  if isApplied then
    if frame.c.count then
      frame.c.count = frame.c.count + 1
    else
      frame.c.count = 1
    end
    if isTest then
      fTime = 0
    else
      local tmpuid
      if tempGUID == PGUID then
        tmpuid = "player"
      else
        tmpuid = npUnitID[tempGUID]
      end
      fTime, expTime = GetAuraDuration(tmpuid, tempSpellID)
      if not fTime then
        return
      end
    end
  else
    if not frame.c.count then
      frame.c.count = 1
    end
    fTime = 0
  end

  local mask_rgb = { 0, 1, 0, 0.6 }
  if frame.c.count == 2 then
    mask_rgb = { 1, 1, 0, 0.6 }
  elseif frame.c.count > 2 then
    mask_rgb = { 1, 0, 0, 0.6 }
  end

  frame.border:SetVertexColor(mask_rgb[1], mask_rgb[2], mask_rgb[3], mask_rgb[4])
  frame.Texture:SetTexture(C_Spell.GetSpellTexture(SetTextureChange(tempSpellID)))
  frame.c:SetCooldown(GetTime(), fTime + DR_TIME)
  frame._font:SetCooldown(GetTime(), fTime + DR_TIME)
end

local function CreateCooldownFrame(spellID, sourceGUID)
  if not cooldown[sourceGUID] then
    cooldown[sourceGUID] = {}
  end
  if not cooldown[sourceGUID][spellID] then
    CreateBorderTexture(sourceGUID, spellID)
    cooldown[sourceGUID][spellID] = _G["NCT" .. sourceGUID .. spellID]
    cooldown[sourceGUID][spellID].Texture:SetTexture(CDTextureCache[spellID])
  end
end

local function CreateRacialnTrinket(sourceGUID, setid, timeid)
  if RSTimeCache[setid] then
    if
      not _G["NCT" .. sourceGUID .. setid]
      or (_G["NCT" .. sourceGUID .. setid].timeleft and _G["NCT" .. sourceGUID .. setid].timeleft < RSTimeCache[timeid])
    then
      CreateCooldownFrame(setid, sourceGUID)
      cooldown[sourceGUID][setid].timeleft = RSTimeCache[timeid] -- timeleft CreateCooldownFrame
      cooldown[sourceGUID][setid].c:SetCooldown(GetTime(), RSTimeCache[timeid])
      cooldown[sourceGUID][setid]._font:SetCooldown(GetTime(), RSTimeCache[timeid])
    end
  end
end

function NameplateTrinket:ClearValue(isTest)
  for n, table in pairs(cooldown) do
    for id, _ in pairs(table) do
      _G["NCT" .. n .. id]:Hide()
      _G["NCT" .. n .. id].c:Clear()
      _G["NCT" .. n .. id]._font:Clear()
      --_G["NCT"..n..id].c = nil
      --_G["NCT"..n..id]._font = nil
      _G["NCT" .. n .. id] = nil
    end
  end
  for n, table in pairs(gradual) do
    for id, _ in pairs(table) do
      _G["NCT" .. id .. n]:Hide()
      _G["NCT" .. id .. n].c:Clear()
      _G["NCT" .. id .. n]._font:Clear()
      --_G["NCT"..id..n].c = nil
      --_G["NCT"..id..n]._font = nil
      _G["NCT" .. id .. n] = nil
    end
  end
  gradual = {}
  cooldown = {}

  if not isTest then
    for k in pairs(npUnitID) do
      npUnitID[k] = nil
    end
    npUnitID = {}
  end
end

function NameplateTrinket:Test()
  self:ClearValue(true)

  local GUID = UnitGUID("target")
  if not GUID then
    DEFAULT_CHAT_FRAME:AddMessage("|c00008000" .. AddonName .. " |r " .. "Please select a nameplate to test")
    return
  end
  local PUID = PGUID
  local spellID = { 336126, 59752 }
  --	local spellID = { 362699, 59752 }
  local testset = true
  if not cooldown[GUID] then
    cooldown[GUID] = {}
  end
  for i = 1, #spellID do
    CreateBorderTexture(GUID, spellID[i])
    cooldown[GUID][spellID[i]] = _G["NCT" .. GUID .. spellID[i]]
    cooldown[GUID][spellID[i]].Texture:SetTexture(CDTextureCache[spellID[i]])
    cooldown[GUID][spellID[i]].c:SetCooldown(GetTime(), CDTimeCache[spellID[i]])
    cooldown[GUID][spellID[i]]._font:SetCooldown(GetTime(), CDTimeCache[spellID[i]])
    --if spellID[i] == 362699 then -- echoing
    --	NameplateTrinket:ShowGlow(cooldown, GUID, spellID[i], NS.db.global.Func.ColorBasc)
    --end
  end

  -- Do not Change about CommonIcon Just test spellid
  if NS.db.global.Group.taunt then
    CreateDiminishFrame(GUID, CommonIcon["taunt"], true, testset)
    CreateDiminishFrame(PUID, CommonIcon["taunt"], true, testset)
  end
  if NS.db.global.Group.incapacitate then
    CreateDiminishFrame(GUID, CommonIcon["incapacitate"], true, testset)
    CreateDiminishFrame(PUID, CommonIcon["incapacitate"], true, testset)
  end
  if NS.db.global.Group.silence then
    CreateDiminishFrame(GUID, CommonIcon["silence"], true, testset)
    CreateDiminishFrame(PUID, CommonIcon["silence"], true, testset)
  end
  if NS.db.global.Group.disorient then
    CreateDiminishFrame(GUID, CommonIcon["disorient"], true, testset)
    CreateDiminishFrame(PUID, CommonIcon["disorient"], true, testset)
  end
  if NS.db.global.Group.stun then
    CreateDiminishFrame(GUID, CommonIcon["stun"], true, testset)
    CreateDiminishFrame(PUID, CommonIcon["stun"], true, testset)
  end
  if NS.db.global.Group.root then
    CreateDiminishFrame(GUID, CommonIcon["root"], true, testset)
    CreateDiminishFrame(PUID, CommonIcon["root"], true, testset)
  end
  if NS.db.global.Group.knockback then
    CreateDiminishFrame(GUID, CommonIcon["knockback"], true, testset)
    CreateDiminishFrame(PUID, CommonIcon["knockback"], true, testset)
  end
  if NS.db.global.Group.disarm then
    CreateDiminishFrame(GUID, CommonIcon["disarm"], true, testset)
    CreateDiminishFrame(PUID, CommonIcon["disarm"], true, testset)
  end
end

function NameplateTrinket:CheckCategory(spellID)
  local tempstr = DRL.spells[spellID]
  if tempstr == "taunt" and NS.db.global.Group.taunt then
  elseif tempstr == "incapacitate" and NS.db.global.Group.incapacitate then
  elseif tempstr == "silence" and NS.db.global.Group.silence then
  elseif tempstr == "disorient" and NS.db.global.Group.disorient then
  elseif tempstr == "stun" and NS.db.global.Group.stun then
  elseif tempstr == "root" and NS.db.global.Group.root then
  elseif tempstr == "knockback" and NS.db.global.Group.knockback then
  elseif tempstr == "disarm" and NS.db.global.Group.disarm then
  else
    return
  end
  return tempstr
end

function NameplateTrinket:PLAYER_ENTERING_WORLD()
  self:ClearValue(false)
end

function NameplateTrinket:COMBAT_LOG_EVENT_UNFILTERED()
  local _, combatEvent, _, sourceGUID, _, sourceFlags, _, destGUID, _, destFlags, _, spellID, _, _, AuraType =
    CombatLogGetCurrentEventInfo()

  if not (destGUID or sourceGUID) then
    return
  end
  if
    combatEvent ~= "SPELL_AURA_REMOVED"
    and combatEvent ~= "SPELL_AURA_APPLIED"
    and combatEvent ~= "SPELL_AURA_REFRESH"
    and combatEvent ~= "SPELL_CAST_SUCCESS"
    and combatEvent ~= "SPELL_MISSED"
    and combatEvent ~= "SPELL_DISPEL"
  then
    return
  end
  if isHarm(destFlags) ~= 0 and AuraType == "DEBUFF" then
    if not strfind(destGUID, "Player") then
      return
    end
    if combatEvent == "SPELL_AURA_APPLIED" or combatEvent == "SPELL_AURA_REFRESH" then
      CreateDiminishFrame(destGUID, spellID, true, false)
    elseif combatEvent == "SPELL_AURA_REMOVED" then
      CreateDiminishFrame(destGUID, spellID, false, false)
    end
  end
  if isHarm(sourceFlags) ~= 0 then
    if
      combatEvent == "SPELL_CAST_SUCCESS"
      or combatEvent == "SPELL_AURA_APPLIED"
      or combatEvent == "SPELL_MISSED"
      or combatEvent == "SPELL_SUMMON"
    then
      -- Timeleft Used - Trinket, RST_Racial, Reset // Not Used - Dispel, ETCCD, Racial
      if CDTimeCache[spellID] then
        CreateCooldownFrame(spellID, sourceGUID)
        if not (NS.n_MAP["ETCCD"][spellID] or NS.n_MAP["Racial"][spellID]) then
          if
            (spellID == 42292 or spellID == 336126)
            and NS.n_MAP["Trinket"][spellID]
            and LHT.IsPlayerHealer(sourceGUID)
          then
            cooldown[sourceGUID][spellID].timeleft = CDTimeCache[spellID] - 30
          else
            cooldown[sourceGUID][spellID].timeleft = CDTimeCache[spellID]
          end
        end

        if
          (spellID == 42292 or spellID == 336126)
          and NS.n_MAP["Trinket"][spellID]
          and LHT.IsPlayerHealer(sourceGUID)
        then
          cooldown[sourceGUID][spellID].c:SetCooldown(GetTime(), CDTimeCache[spellID] - 30)
          cooldown[sourceGUID][spellID]._font:SetCooldown(GetTime(), CDTimeCache[spellID] - 30)
        else
          cooldown[sourceGUID][spellID].c:SetCooldown(GetTime(), CDTimeCache[spellID])
          cooldown[sourceGUID][spellID]._font:SetCooldown(GetTime(), CDTimeCache[spellID])
        end
        --if spellID == 362699 then -- echoing
        --  cooldown[sourceGUID][spellID]:Show()
        --end
      end
      --if spellID == 195710 or spellID == 208683 or spellID == 195901 then
      if spellID == 42292 or spellID == 336126 or spellID == 336139 then
        local race = select(4, GetPlayerInfoByGUID(sourceGUID))
        if race == "Scourge" then -- Undead
          CreateRacialnTrinket(sourceGUID, 7744, 7744)
        elseif race == "Dwarf" then
          CreateRacialnTrinket(sourceGUID, 65116, 65116)
        elseif race == "DarkIronDwarf" then
          CreateRacialnTrinket(sourceGUID, 273104, 273104)
        elseif race == "Human" then
          CreateRacialnTrinket(sourceGUID, 59752, 59752)
        end
      elseif spellID == 7744 or spellID == 65116 or spellID == 273104 then
        CreateRacialnTrinket(sourceGUID, 336126, 336126)
      elseif spellID == 59752 then
        CreateRacialnTrinket(sourceGUID, 336126, spellID)
      end
    end
  end
end

function NameplateTrinket:NAME_PLATE_UNIT_ADDED(unitID)
  local guid = UnitGUID(unitID)
  if guid then
    npUnitID[guid] = unitID
  end
end

function NameplateTrinket:NAME_PLATE_UNIT_REMOVED(unitID)
  local guid = UnitGUID(unitID)
  if guid then
    npUnitID[guid] = nil
  end
end

local function UpdateFrame(g_tb, sel, elapsed)
  elapsed = elapsed or 0
  local alpha, scale
  for n, tb in pairs(g_tb) do -- n = guid
    if NS.db.global.pSetting.pEnable and sel and n == PGUID then
      local offset = (isTarget(PGUID, "target") and NS.db.global.Func.Trinket and NS.db.global.Func.Racial) and 3
        or (isTarget(PGUID, "target") and (NS.db.global.Func.Trinket or NS.db.global.Func.Racial)) and 2
        or 1
      local PCNT = 0
      alpha = NS.db.global.gSetting.TargetAlpha
      scale = NS.db.global.pSetting.pScale

      for _, fr in pairs(tb) do
        fr:ClearAllPoints()
        if fr.c:IsVisible() then
          fr:SetAlpha(alpha)
          fr:SetScale(scale)
          fr:SetPoint(
            "TOPLEFT",
            "PlayerFrame",
            "TOPLEFT",
            NS.db.global.pSetting.pxOfs
              + ((NS.db.global.gSetting.FrameSize + 2) * offset)
              + (NS.db.global.gSetting.FrameSize + 2) * PCNT,
            NS.db.global.pSetting.pyOfs + NS.db.global.gSetting.FrameSize * 2
          )
          PCNT = PCNT + 1
        else
          fr:SetPoint("TOP", UIParent, "TOP", 0, 100)
        end
      end
    else
      local pl
      for guid, unitID in pairs(npUnitID) do
        if n == guid then
          pl = GetNamePlateForUnit(unitID)
          break
        end
      end

      if pl then
        local SCNT = 0
        if isTarget(n, "target") or isTarget(n, "focus") then
          alpha = NS.db.global.gSetting.TargetAlpha
          scale = NS.db.global.gSetting.TargetScale
        else
          alpha = NS.db.global.gSetting.OtherAlpha
          scale = NS.db.global.gSetting.OtherScale
        end

        for id, fr in pairs(tb) do -- id = spellid, category
          fr:ClearAllPoints()
          if not sel and fr.timeleft then
            if fr.timeleft <= 0 then
              fr.timeleft = 0
            else
              fr.timeleft = fr.timeleft - elapsed
            end
          end
          if fr.c:IsVisible() then
            fr:SetAlpha(alpha)
            fr:SetScale(scale)
            fr._font:SetAlpha(alpha)

            if sel then
              if
                NS.db.global.Group.taunt
                or NS.db.global.Group.incapacitate
                or NS.db.global.Group.silence
                or NS.db.global.Group.disorient
                or NS.db.global.Group.stun
                or NS.db.global.Group.root
                or NS.db.global.Group.knockback
                or NS.db.global.Group.disarm
              then
                local offsetX = (NS.db.global.Func.Trinket and NS.db.global.Func.Racial) and 3
                  or not (NS.db.global.Func.Trinket and NS.db.global.Func.Racial) and 1
                  or 2
                fr:SetPoint(
                  "RIGHT",
                  pl,
                  "RIGHT",
                  NS.db.global.gSetting.xOfs
                    + (NS.db.global.gSetting.FrameSize * offsetX)
                    + NS.db.global.gSetting.FrameSize * SCNT,
                  NS.db.global.gSetting.yOfs
                )
                SCNT = SCNT + 1
              else
                fr:SetPoint("TOP", UIParent, "TOP", 0, 100)
              end
            else
              local attachFrame = (NS.db.global.pSetting.pEnable and n == PGUID) and "PlayerFrame" or pl
              local attachPoint = (NS.db.global.pSetting.pEnable and n == PGUID) and "TOPLEFT" or "RIGHT"
              local attachX = (NS.db.global.pSetting.pEnable and n == PGUID)
                  and (NS.db.global.pSetting.pxOfs + (NS.db.global.gSetting.FrameSize + 2))
                or (NS.db.global.gSetting.xOfs + NS.db.global.gSetting.FrameSize)
              local attachY = (NS.db.global.pSetting.pEnable and n == PGUID)
                  and (NS.db.global.pSetting.pyOfs + NS.db.global.gSetting.FrameSize * 2)
                or NS.db.global.gSetting.yOfs
              if NS.db.global.Func.Trinket and NS.n_MAP["Trinket"][id] then
                fr:SetPoint(attachPoint, attachFrame, attachPoint, attachX, attachY)
              elseif NS.db.global.Func.Racial and (NS.n_MAP["Racial"][id] or NS.n_MAP["RST_Racial"][id]) then
                local offsetX = NS.db.global.Func.Trinket and 2 or 1
                fr:SetPoint(attachPoint, attachFrame, attachPoint, attachX * offsetX, attachY)
              else
                fr:SetPoint("TOP", UIParent, "TOP", 0, 100)
              end
            end
          else
            fr:SetPoint("TOP", UIParent, "TOP", 0, 100)
          end
        end
      else
        for _, fr in pairs(tb) do
          fr:ClearAllPoints()
          fr:SetPoint("TOP", UIParent, "TOP", 0, 100)
        end
      end
    end
  end
end

function OnUpdate(_, elapsed)
  getUpdate = getUpdate + elapsed
  if getUpdate > UPDATE_INTERVAL then
    UpdateFrame(gradual, true)
    UpdateFrame(cooldown, false, getUpdate)
    getUpdate = 0
  end
end

function NameplateTrinket:PLAYER_LOGIN()
  NameplateTrinketFrame:UnregisterEvent("PLAYER_LOGIN")

  for str in pairs(NS.n_MAP) do
    for sp, tm in pairs(NS.n_MAP[str]) do
      if C_Spell.GetSpellName(sp) then
        if str == "Reset" then
          RSTimeCache[sp] = tm
        else
          CDTimeCache[sp] = tm
        end
        CDTextureCache[sp] = C_Spell.GetSpellTexture(sp)
      else
        DEFAULT_CHAT_FRAME:AddMessage("|c00008000NameplateTrinket|r n_MAP[" .. str .. "] " .. sp)
      end
    end
  end

  CDTextureCache[336139] = "Interface\\Icons\\Sha_ability_rogue_sturdyrecuperate" -- Adaptation
  -- CDTextureCache[196029] = "Interface\\Icons\\Ability_bossdarkvindicator_auraofcontempt" -- Relentless

  NameplateTrinketFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  NameplateTrinketFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
  NameplateTrinketFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
  NameplateTrinketFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

  local TempFrame = CreateFrame("Frame")
  TempFrame:SetScript("OnUpdate", OnUpdate)
end
NameplateTrinketFrame:RegisterEvent("PLAYER_LOGIN")
