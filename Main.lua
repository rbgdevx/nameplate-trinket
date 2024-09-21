local _, Data = ...
local NameplateCCnTrinket = LibStub("AceAddon-3.0"):NewAddon("NameplateCCnTrinket", "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("NameplateCCnTrinket")
local LCG = LibStub("LibCustomGlow-1.0")

local DRL = LibStub("DRList-1.0")
local LHT = LibStub("LibHealerTracker-1.0")

local _G, pairs, select, band, floor, strfind, unpack = _G, pairs, select, bit.band, math.floor, string.find, unpack
local CreateFrame = CreateFrame
local GetTime, GetPlayerInfoByGUID = GetTime, GetPlayerInfoByGUID

local UnitAura, UnitGUID = C_UnitAuras.GetAuraDataByIndex, UnitGUID
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local GetCVar, GetNamePlateForUnit = C_CVar.GetCVar, C_NamePlate.GetNamePlateForUnit
local COMBATLOG_OBJECT_REACTION_HOSTILE, COMBATLOG_OBJECT_REACTION_MASK =
	COMBATLOG_OBJECT_REACTION_HOSTILE, COMBATLOG_OBJECT_REACTION_MASK

local DR_TIME = DRL.resetTimes.retail["default"]
local getUpdate = 0
local npUnitID = {}
local CDTimeCache = {}
local CDDTimeCache = {}
local RSTimeCache = {}
local CDTextureCache = {}
local gradual = {}
local cooldown = {}
local UPDATE_INTERVAL = 0.25
local PGUID = UnitGUID("player")
local bordertex = {
	["2px"] = "Interface\\AddOns\\NameplateCCnTrinket\\media\\32x2px.tga",
	["3px"] = "Interface\\AddOns\\NameplateCCnTrinket\\media\\32x3px.tga",
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
local DefaultConfig = {
	profile = {
		gSetting = {
			ShowFriendlyPlayer = true,
			CCCommonIcon = false,
			CCShowMonster = false,
			--	CurrentTime = true,
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
			pScale = 0.9,
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
			FontScale = 0.8,
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
	},
}

function NameplateCCnTrinket:OnInitialize()
	self.Settings = LibStub("AceDB-3.0"):New("NameplateCCnTrinketSettings", DefaultConfig, true)

	self.Settings.RegisterCallback(self, "OnProfileChanged", "Refresh")
	self.Settings.RegisterCallback(self, "OnProfileCopied", "Refresh")
	self.Settings.RegisterCallback(self, "OnProfileReset", "Refresh")
	self.Settings.RegisterCallback(self, "OnProfileShutdown", "Refresh")

	self:Option()
	self:RegisterChatCommand("nct", "ChatCommand")
	self:RegisterChatCommand("NameplateCCnTrinket", "ChatCommand")

	for str in pairs(Data.n_MAP) do
		for sp, tm in pairs(Data.n_MAP[str]) do
			if C_Spell.GetSpellName(sp) then
				if str == "Dispel" then
					CDDTimeCache[sp] = tm
				elseif str == "Reset" then
					RSTimeCache[sp] = tm
				else
					CDTimeCache[sp] = tm
				end
				CDTextureCache[sp] = C_Spell.GetSpellTexture(sp)
			else
				DEFAULT_CHAT_FRAME:AddMessage("|c00008000NameplateCCnTrinket|r n_MAP[" .. str .. "] " .. sp)
			end
		end
	end
	CDTextureCache[336139] = "Interface\\Icons\\Sha_ability_rogue_sturdyrecuperate" -- Adaptation
	--  CDTextureCache[196029] = "Interface\\Icons\\Ability_bossdarkvindicator_auraofcontempt" -- Relentless

	for _, id in pairs(CommonIcon) do
		if not C_Spell.GetSpellName(id) then
			DEFAULT_CHAT_FRAME:AddMessage("|c00008000NameplateCCnTrinket|r [CommonIcon] " .. id)
		end
	end

	self.Frame = CreateFrame("Frame")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
	self:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self.Frame:SetScript("OnUpdate", self.OnUpdate)
end

function NameplateCCnTrinket:Refresh()
	self:ClearValue(false)
end

function NameplateCCnTrinket:ChatCommand(input)
	if not input or input:trim() == "" then
		LibStub("AceConfigDialog-3.0"):SetDefaultSize("NameplateCCnTrinket", 600, 550)
		LibStub("AceConfigDialog-3.0"):Open("NameplateCCnTrinket")
	else
		LibStub("AceConfigCmd-3.0"):HandleCommand("nct", "NameplateCCnTrinket", input)
	end
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
	if NameplateCCnTrinket.Settings.profile.gSetting.ShowFriendlyPlayer then
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
	local profile = NameplateCCnTrinket.Settings.profile
	local frame = CreateFrame("Frame", "NCT" .. FirstName .. SecondName)
	frame:SetFrameStrata("BACKGROUND")
	frame:SetSize(profile.gSetting.FrameSize, profile.gSetting.FrameSize)
	frame:SetPoint("TOP", UIParent, "TOP", 0, 100)
	frame.Texture = frame:CreateTexture(nil, "BACKGROUND")
	frame.Texture:SetAllPoints()

	frame.border = frame:CreateTexture(nil, "BORDER")
	frame.border:SetTexture(bordertex[profile.Func.IconBorder])
	frame.border:SetVertexColor(unpack(profile.Func.ColorBasc))
	frame.border:SetAllPoints()

	frame.c = CreateFrame("Cooldown", nil, frame) -- "CooldownFrameTemplate"를 사용하면 Frame이 늦게 사라지는 문제가 있음 IsVisible과 관련있는가?
	frame.c:SetFrameLevel(frame:GetFrameLevel() + 2)
	local ctex = frame:CreateTexture(nil, "BACKGROUND") -- "CooldownFrameTemplate" 사용하지 않으면 ctex를 직접 만들어넣어야함
	ctex:SetTexture(1, 1, 1)
	frame.c:SetSwipeTexture(ctex:GetTexture())
	frame.c:SetSwipeColor(0, 0, 0, 0.6)
	frame.c:SetReverse(true)
	frame.c:SetDrawSwipe(profile.gSetting.CooldownSpiral)
	frame.c:SetHideCountdownNumbers(true) -- basic interface
	frame.c.noCooldownCount = true -- OmniCC
	frame.c:SetAllPoints()

	frame._font = CreateFrame("Cooldown")
	frame._font:SetFrameLevel(frame:GetFrameLevel() + 8)
	frame._font:SetHideCountdownNumbers(not profile.Func.FontEnable) -- basic interface
	frame._font.noCooldownCount = not profile.Func.FontEnable -- OmniCC
	frame._font:SetSize(profile.gSetting.FrameSize, profile.gSetting.FrameSize)
	frame._font:SetScale(profile.Func.FontScale)
	frame._font:SetPoint("CENTER", frame, profile.Func.FontPoint, 0, 0)
end

local function CreateDiminishFrame(tempGUID, tempSpellID, isApplied, isTest)
	local cat = NameplateCCnTrinket:CheckCategory(tempSpellID)
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

	local profile = NameplateCCnTrinket.Settings.profile
	local mask_rgb = profile.Group.ColorFull
	if frame.c.count == 2 then
		mask_rgb = profile.Group.ColorHalf
	elseif frame.c.count > 2 then
		mask_rgb = profile.Group.ColorQuat
	end

	if profile.CCHL.Enable then
		if isApplied then
			NameplateCCnTrinket:ShowGlow(gradual, tempGUID, cat, mask_rgb)
		else
			NameplateCCnTrinket:HideGlow(gradual, tempGUID, cat)
		end
	end

	frame.border:SetVertexColor(mask_rgb[1], mask_rgb[2], mask_rgb[3])
	if profile.gSetting.CCCommonIcon then
		local dat
		if cat == "taunt" then
			dat = profile.Group.tauntCommon
		elseif cat == "incapacitate" then
			dat = profile.Group.incapacitateCommon
		elseif cat == "silence" then
			dat = profile.Group.silenceCommon
		elseif cat == "disorient" then
			dat = profile.Group.disorientCommon
		elseif cat == "stun" then
			dat = profile.Group.stunCommon
		elseif cat == "root" then
			dat = profile.Group.rootCommon
		elseif cat == "knockback" then
			dat = profile.Group.knockbackCommon
		elseif cat == "disarm" then
			dat = profile.Group.disarmCommon
		end
		frame.Texture:SetTexture(C_Spell.GetSpellTexture(dat))
	else
		frame.Texture:SetTexture(C_Spell.GetSpellTexture(SetTextureChange(tempSpellID)))
	end

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
		-- 아무것도 없을때 진입하기 위함 or 남은시간이 더 적을때 30초로 바꾸기
		if
			not _G["NCT" .. sourceGUID .. setid]
			or (
				_G["NCT" .. sourceGUID .. setid].timeleft
				and _G["NCT" .. sourceGUID .. setid].timeleft < RSTimeCache[timeid]
			)
		then
			CreateCooldownFrame(setid, sourceGUID)
			cooldown[sourceGUID][setid].timeleft = RSTimeCache[timeid] --timeleft를 사용하지 않는 애들때문에 CreateCooldownFrame 내에 넣지 않는다
			cooldown[sourceGUID][setid].c:SetCooldown(GetTime(), RSTimeCache[timeid])
			cooldown[sourceGUID][setid]._font:SetCooldown(GetTime(), RSTimeCache[timeid])
		end
	end
end

function NameplateCCnTrinket:ClearValue(isTest)
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

function NameplateCCnTrinket:Test()
	self:ClearValue(true)

	local GUID = UnitGUID("target")
	if not GUID then
		DEFAULT_CHAT_FRAME:AddMessage(L["selectnameplate"])
		return
	end
	local PUID = PGUID
	local spellID = { 336126, 59752, 6552, 527 }
	--	local spellID = { 362699, 59752, 6552, 527 }
	local testset = true
	local profile = self.Settings.profile
	local ct = profile.CCHL.Enable
	if not cooldown[GUID] then
		cooldown[GUID] = {}
	end
	for i = 1, #spellID do
		CreateBorderTexture(GUID, spellID[i])
		cooldown[GUID][spellID[i]] = _G["NCT" .. GUID .. spellID[i]]
		cooldown[GUID][spellID[i]].Texture:SetTexture(CDTextureCache[spellID[i]])
		if i == 4 then
			cooldown[GUID][spellID[i]].c:SetCooldown(GetTime(), CDDTimeCache[spellID[i]])
			cooldown[GUID][spellID[i]]._font:SetCooldown(GetTime(), CDDTimeCache[spellID[i]])
		else
			cooldown[GUID][spellID[i]].c:SetCooldown(GetTime(), CDTimeCache[spellID[i]])
			cooldown[GUID][spellID[i]]._font:SetCooldown(GetTime(), CDTimeCache[spellID[i]])
		end
		--if spellID[i] == 362699 then -- echoing
		--	NameplateCCnTrinket:ShowGlow(cooldown, GUID, spellID[i], NameplateCCnTrinket.Settings.profile.Func.ColorBasc)
		--end
	end

	-- Do not Change about CommonIcon Just test spellid
	if profile.Group.taunt then
		CreateDiminishFrame(GUID, CommonIcon["taunt"], ct, testset)
		CreateDiminishFrame(PUID, CommonIcon["taunt"], ct, testset)
	end
	if profile.Group.incapacitate then
		CreateDiminishFrame(GUID, CommonIcon["incapacitate"], ct, testset)
		CreateDiminishFrame(PUID, CommonIcon["incapacitate"], ct, testset)
	end
	if profile.Group.silence then
		CreateDiminishFrame(GUID, CommonIcon["silence"], ct, testset)
		CreateDiminishFrame(PUID, CommonIcon["silence"], ct, testset)
	end
	if profile.Group.disorient then
		CreateDiminishFrame(GUID, CommonIcon["disorient"], ct, testset)
		CreateDiminishFrame(PUID, CommonIcon["disorient"], ct, testset)
	end
	if profile.Group.stun then
		CreateDiminishFrame(GUID, CommonIcon["stun"], ct, testset)
		CreateDiminishFrame(PUID, CommonIcon["stun"], ct, testset)
	end
	if profile.Group.root then
		CreateDiminishFrame(GUID, CommonIcon["root"], ct, testset)
		CreateDiminishFrame(PUID, CommonIcon["root"], ct, testset)
	end
	if profile.Group.knockback then
		CreateDiminishFrame(GUID, CommonIcon["knockback"], ct, testset)
		CreateDiminishFrame(PUID, CommonIcon["knockback"], ct, testset)
	end
	if profile.Group.disarm then
		CreateDiminishFrame(GUID, CommonIcon["disarm"], ct, testset)
		CreateDiminishFrame(PUID, CommonIcon["disarm"], ct, testset)
	end
end

function NameplateCCnTrinket:CheckCategory(spellID)
	local profile = self.Settings.profile
	local tempstr = DRL.spells[spellID]
	if tempstr == "taunt" and profile.Group.taunt then
	elseif tempstr == "incapacitate" and profile.Group.incapacitate then
	elseif tempstr == "silence" and profile.Group.silence then
	elseif tempstr == "disorient" and profile.Group.disorient then
	elseif tempstr == "stun" and profile.Group.stun then
	elseif tempstr == "root" and profile.Group.root then
	elseif tempstr == "knockback" and profile.Group.knockback then
	elseif tempstr == "disarm" and profile.Group.disarm then
	else
		return
	end
	return tempstr
end

function NameplateCCnTrinket:PLAYER_ENTERING_WORLD()
	self:ClearValue(false)
end

function NameplateCCnTrinket:COMBAT_LOG_EVENT_UNFILTERED()
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
	local profile = self.Settings.profile

	if isHarm(destFlags) ~= 0 and AuraType == "DEBUFF" then
		if not profile.gSetting.CCShowMonster then
			if not strfind(destGUID, "Player") then
				return
			end
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
			-- Timeleft Used - Trinket, RST_Racial, Reset // Not Used - Dispel, Interrupt, ETCCD, Racial
			if CDTimeCache[spellID] then
				CreateCooldownFrame(spellID, sourceGUID)
				if
					not (
						Data.n_MAP["Interrupt"][spellID]
						or Data.n_MAP["ETCCD"][spellID]
						or Data.n_MAP["Racial"][spellID]
					)
				then
					if
						(spellID == 42292 or spellID == 336126)
						and Data.n_MAP["Trinket"][spellID]
						and LHT.IsPlayerHealer(sourceGUID)
					then
						cooldown[sourceGUID][spellID].timeleft = CDTimeCache[spellID] - 30
					else
						cooldown[sourceGUID][spellID].timeleft = CDTimeCache[spellID]
					end
				end

				if
					(spellID == 42292 or spellID == 336126)
					and Data.n_MAP["Trinket"][spellID]
					and LHT.IsPlayerHealer(sourceGUID)
				then
					cooldown[sourceGUID][spellID].c:SetCooldown(GetTime(), CDTimeCache[spellID] - 30)
					cooldown[sourceGUID][spellID]._font:SetCooldown(GetTime(), CDTimeCache[spellID] - 30)
				else
					cooldown[sourceGUID][spellID].c:SetCooldown(GetTime(), CDTimeCache[spellID])
					cooldown[sourceGUID][spellID]._font:SetCooldown(GetTime(), CDTimeCache[spellID])
				end
				--if spellID == 362699 then -- echoing
				--	self:ShowGlow(cooldown, sourceGUID, spellID, profile.Func.ColorBasc)
				--	cooldown[sourceGUID][spellID]:Show()
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
		elseif combatEvent == "SPELL_DISPEL" then
			if CDDTimeCache[spellID] then
				CreateCooldownFrame(spellID, sourceGUID)
				cooldown[sourceGUID][spellID].c:SetCooldown(GetTime(), CDDTimeCache[spellID])
				cooldown[sourceGUID][spellID]._font:SetCooldown(GetTime(), CDDTimeCache[spellID])
			end
		end
	end
end

function NameplateCCnTrinket:ShowGlow(data, sourceGUID, spellID, mask_rgb)
	local profile = self.Settings.profile
	local frame = data[sourceGUID][spellID]

	if profile.CCHL.Enable and frame then
		if profile.CCHL.Style == "ButtonGlow" then
			LCG.ButtonGlow_Start(frame, mask_rgb)
		elseif profile.CCHL.Style == "PixelGlow" then
			--	LCG.PixelGlow_Start(frame[, color[, N[, frequency[, length[, th[, xOffset[, yOffset[, border[ ,key]]]]]]]])
			LCG.PixelGlow_Start(frame, mask_rgb, nil, nil, profile.CCHL.pixellength, profile.CCHL.pixelth)
		elseif profile.CCHL.Style == "AutoCastGlow" then
			--	LCG.AutoCastGlow_Start(frame[, color[, N[, frequency[, scale[, xOffset[, yOffset[, key]]]]]]])
			LCG.AutoCastGlow_Start(frame, mask_rgb, nil, nil, profile.CCHL.autoscale)
		end
	end
end

function NameplateCCnTrinket:HideGlow(data, sourceGUID, spellID)
	local profile = self.Settings.profile
	local frame = data[sourceGUID][spellID]

	if profile.CCHL.Enable and frame then
		if profile.CCHL.Style == "ButtonGlow" then
			LCG.ButtonGlow_Stop(frame)
		elseif profile.CCHL.Style == "PixelGlow" then
			LCG.PixelGlow_Stop(frame)
		elseif profile.CCHL.Style == "AutoCastGlow" then
			LCG.AutoCastGlow_Stop(frame)
		end
	end
end

function NameplateCCnTrinket:NAME_PLATE_UNIT_ADDED(_, unitID)
	local guid = UnitGUID(unitID)
	npUnitID[guid] = unitID
end

function NameplateCCnTrinket:NAME_PLATE_UNIT_REMOVED(_, unitID)
	local guid = UnitGUID(unitID)
	npUnitID[guid] = nil
end

local function UpdateFrame(g_tb, sel, elapsed)
	elapsed = elapsed or 0
	local profile = NameplateCCnTrinket.Settings.profile
	local alpha, scale
	for n, tb in pairs(g_tb) do -- n = guid
		if profile.pSetting.pEnable and sel and n == PGUID then
			local PCNT = 0
			alpha = profile.gSetting.TargetAlpha
			scale = profile.pSetting.pScale

			for _, fr in pairs(tb) do
				fr:ClearAllPoints()
				if fr.c:IsVisible() then
					fr:SetAlpha(alpha)
					fr:SetScale(scale)
					fr:SetPoint(
						"TOPLEFT",
						profile.pSetting.attachFrame,
						"TOPLEFT",
						profile.pSetting.pxOfs + (profile.gSetting.FrameSize + 2) * PCNT,
						profile.pSetting.pyOfs + profile.gSetting.FrameSize * 2
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
				local gn = 0
				local SCNT = 0
				if isTarget(n, "target") or isTarget(n, "focus") then
					alpha = profile.gSetting.TargetAlpha
					scale = 1
				else
					alpha = profile.gSetting.OtherAlpha
					scale = profile.gSetting.OtherScale
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

						if profile.gSetting.SortingStyle then
							if sel then
								if profile.Func.CC then
									fr:SetPoint(
										"RIGHT",
										pl,
										"RIGHT",
										profile.gSetting.RightxOfs
											+ (profile.gSetting.FrameSize * 3)
											+ profile.gSetting.FrameSize * SCNT,
										profile.gSetting.yOfs
									)
									SCNT = SCNT + 1
								else
									fr:SetPoint("TOP", UIParent, "TOP", 0, 100)
								end
							else
								if profile.Func.Trinket and Data.n_MAP["Trinket"][id] then
									fr:SetPoint(
										"RIGHT",
										pl,
										"RIGHT",
										profile.gSetting.RightxOfs + profile.gSetting.FrameSize,
										profile.gSetting.yOfs
									)
								elseif
									profile.Func.Racial and (Data.n_MAP["Racial"][id] or Data.n_MAP["RST_Racial"][id])
								then
									fr:SetPoint(
										"RIGHT",
										pl,
										"RIGHT",
										profile.gSetting.RightxOfs + profile.gSetting.FrameSize * 2,
										profile.gSetting.yOfs
									)
								elseif profile.Func.Interrupt and Data.n_MAP["Interrupt"][id] then
									fr:SetPoint(
										"BOTTOMRIGHT",
										pl,
										"TOPLEFT",
										profile.gSetting.LeftxOfs,
										profile.gSetting.yOfs - profile.gSetting.FrameSize
									)
								elseif
									profile.Func.Dispel and (Data.n_MAP["Dispel"][id] or Data.n_MAP["ETCCD"][id])
								then
									fr:SetPoint(
										"BOTTOMRIGHT",
										pl,
										"TOPLEFT",
										profile.gSetting.LeftxOfs,
										profile.gSetting.yOfs - profile.gSetting.FrameSize * 2
									)
								else
									fr:SetPoint("TOP", UIParent, "TOP", 0, 100)
								end
							end
						else
							if sel then
								if profile.Func.CC then
									fr:SetPoint(
										"BOTTOMLEFT",
										pl,
										"TOPRIGHT",
										profile.gSetting.RightxOfs
											+ profile.gSetting.FrameSize
											+ profile.gSetting.FrameSize * floor(gn / 2),
										profile.gSetting.yOfs
											- profile.gSetting.FrameSize
											- profile.gSetting.FrameSize * (gn % 2)
									)
									gn = gn + 1
								else
									fr:SetPoint("TOP", UIParent, "TOP", 0, 100)
								end
							else
								if profile.Func.Trinket and Data.n_MAP["Trinket"][id] then
									fr:SetPoint(
										"BOTTOMLEFT",
										pl,
										"TOPRIGHT",
										profile.gSetting.RightxOfs,
										profile.gSetting.yOfs - profile.gSetting.FrameSize
									)
								elseif
									profile.Func.Racial and (Data.n_MAP["Racial"][id] or Data.n_MAP["RST_Racial"][id])
								then
									fr:SetPoint(
										"BOTTOMLEFT",
										pl,
										"TOPRIGHT",
										profile.gSetting.RightxOfs,
										profile.gSetting.yOfs - profile.gSetting.FrameSize * 2
									)
								elseif profile.Func.Interrupt and Data.n_MAP["Interrupt"][id] then
									fr:SetPoint(
										"BOTTOMRIGHT",
										pl,
										"TOPLEFT",
										profile.gSetting.LeftxOfs,
										profile.gSetting.yOfs - profile.gSetting.FrameSize
									)
								elseif
									profile.Func.Dispel and (Data.n_MAP["Dispel"][id] or Data.n_MAP["ETCCD"][id])
								then
									fr:SetPoint(
										"BOTTOMRIGHT",
										pl,
										"TOPLEFT",
										profile.gSetting.LeftxOfs,
										profile.gSetting.yOfs - profile.gSetting.FrameSize * 2
									)
								else
									fr:SetPoint("TOP", UIParent, "TOP", 0, 100)
								end
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

function NameplateCCnTrinket:OnUpdate(elapsed)
	getUpdate = getUpdate + elapsed

	if getUpdate > UPDATE_INTERVAL then
		UpdateFrame(gradual, true)
		UpdateFrame(cooldown, false, getUpdate)
		getUpdate = 0
	end
end
