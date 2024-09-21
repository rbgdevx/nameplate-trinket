local NameplateCCnTrinket = LibStub("AceAddon-3.0"):GetAddon("NameplateCCnTrinket")
local L = LibStub("AceLocale-3.0"):GetLocale("NameplateCCnTrinket")
local _, drminor = LibStub("DRList-1.0")

local unpack, math_floor, GetSpellInfo = unpack, math.floor, C_Spell.GetSpellInfo
local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata

local function InChatTexture(val)
	local icon_str
	local tex = GetSpellInfo(val).iconID
	if tex then
		icon_str = "\124T"..tex..":15:15:-5:-5\124t"
	else
		icon_str = ""
	end
	return icon_str..tostring(val)
end

function NameplateCCnTrinket:Option()
	local AceConfig = {
		name = "NameplateCCnTrinket",
		type = "group",
		childGroups = "tab",
		plugins = { profiles = { profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.Settings) } },
		args = {
			vers = {
				order = 1,
				type = "description",
				width = "normal",
				name = "|cffffd700" .. L["Version"] .. "|r " .. GetAddOnMetadata("NameplateCCnTrinket", "Version"), -- .. "\n",
				cmdHidden = true
			},
			drlistvers = {
				order = 2,
				type = "description",
				width = "normal",
				name = " |cffffd700" .. L["DRList-1.0"] .. "|r " .. drminor .. "\n",
				cmdHidden = true
			},
			desc = {
				order = 3,
				type = "description",
				name = "|cffffd700 " .. L["Author"] .. "|r " .. GetAddOnMetadata("NameplateCCnTrinket", "Author") .. "\n",
				cmdHidden = true
			},
			Description = {
				type = "description",
				name = "|c00008000" .. L["/NCT\n/NameplateCCnTrinket\n"] .. "|r ",
				width = "full",
				order = 4,
			},
			test = {
				type = "execute",
				name = L["Test"],
				desc = L["Test Desc"],
				width = "normal",
				order = 5,
				func = "Test",
				handler = NameplateCCnTrinket,
			},
			gSetting = {
				type = "group",
				name = "Settings",
				order = 5,
				set = function(info, val) self.Settings.profile.gSetting[info[#info]] = val end,
				get = function(info) return self.Settings.profile.gSetting[info[#info]] end,
				args = {
					ShowFriendlyPlayer = {
						type = "toggle",
						width = "normal",
						order = 1,
						name = L["Show Friendly Player"],
						desc = L["Show Friendly Player Desc"],
					},
					CCCommonIcon = {
						type = "toggle",
						width = "normal",
						order = 2,
						name = L["CC Common Icon"],
						desc = L["CC Common Icon Desc"],
					},
					CCShowMonster = {
						type = "toggle",
						width = "normal",
						order = 3,
						name = L["CC Show Monster"],
						desc = L["CC Show Monster Desc"],
					},
					--[[
					CurrentTime = {
						type = "toggle",
						width = "normal",
						order = 4,
						name = L["CurrentTime"],
						desc = L["CurrentTime Desc"],
					},]]
					SortingStyle = {
						type = "toggle",
						width = "normal",
						order = 4,
						name = L["SortingStyle"],
						desc = L["SortingStyle Desc"],
					},
					CooldownSpiral = {
						type = "toggle",
						width = 1,
						order = 5,
						name = L["CooldownSpiral"],
						desc = L["CooldownSpiral Desc"],
					},
					dummygSetting = {
						name = "",
						type = "description",
						width = 1,
						order = 6,
					},
					FrameSize = {
						name = L["FrameSize"],
						desc = L["FrameSize Desc"],
						type = "range",
						width = "normal",
						order = 7,
						isPercent = false,
						min = 10,
						max = 40,
						step = 1,
					},
					LeftxOfs = {
						name = L["Left Frame X"],
						desc = L["Left X Desc"],
						type = "range",
						width = "normal",
						order = 8,
						isPercent = false,
						min = -200,
						max = 200,
						step = 1,
					},
					RightxOfs = {
						name = L["Right Frame X"],
						desc = L["Right X Desc"],
						type = "range",
						width = "normal",
						order = 9,
						isPercent = false,
						min = -200,
						max = 200,
						step = 1,
					},
					yOfs = {
						name = L["Y"],
						desc = L["Y Desc"],
						type = "range",
						width = "normal",
						order = 10,
						isPercent = false,
						min = -100,
						max = 100,
						step = 1,
					},
					TargetAlpha = {
						name = L["TargetAlpha"],
						desc = L["TargetAlpha Desc"],
						type = "range",
						width = "normal",
						order = 11,
						isPercent = true,
						min = 0,
						max = 1,
						step = 0.01,
					},
					OtherAlpha = {
						name = L["OtherAlpha"],
						desc = L["OtherAlpha Desc"],
						type = "range",
						width = "normal",
						order = 12,
						isPercent = true,
						min = 0,
						max = 1,
						step = 0.01,
					},
					OtherScale = {
						name = L["OtherScale"],
						desc = L["OtherScale Desc"],
						type = "range",
						width = "normal",
						order = 13,
						isPercent = true,
						min = 0.5,
						max = 1,
						step = 0.01,
					},
				}
			},
			pSetting ={
				name = L["pSetting"],
				type = "group",
				order = 6,
				set = function(info, val) self.Settings.profile.pSetting[info[#info]] = val end,
				get = function(info) return self.Settings.profile.pSetting[info[#info]] end,
				args = {
					Description = {
						type = "description",
						name = L["pSetting Desc"],
						width = "full",
						order = 1,
					},
					pEnable = {
						type = "toggle",
						width = 3,
						order = 2,
						name = L["Enable"],
						desc = L["Enable Desc"],
					},
					pxOfs = {
						name = L["pxOfs"],
						desc = L["pxOfs Desc"],
						type = "range",
						disabled = function() return not self.Settings.profile.pSetting.pEnable end,
						width = "full",
						order = 3,
						isPercent = false,
						min = -1200,
						max = 1200,
						step = 1,
					},
					pyOfs = {
						name = L["pyOfs"],
						desc = L["pyOfs Desc"],
						type = "range",
						disabled = function() return not self.Settings.profile.pSetting.pEnable end,
						width = "full",
						order = 4,
						isPercent = false,
						min = -600,
						max = 600,
						step = 1,
					},
					pScale = {
						name = L["pScale"],
						desc = L["pScale Desc"],
						type = "range",
						disabled = function() return not self.Settings.profile.pSetting.pEnable end,
						width = "normal",
						order = 5,
						isPercent = true,
						min = 0.5,
						max = 1.5,
						step = 0.01,
					},
					attachFrame = {
						type = "input",
						disabled = function() return not self.Settings.profile.pSetting.pEnable end,
						order = 6,
						name = L["attachFrame"],
						desc = L["attachFrame Desc"],
						set = function(_, val)
							if _G[val] == nil then
								DEFAULT_CHAT_FRAME:AddMessage("|c00008000".."NameplateCCnTrinket".." |r"..val..L["rightframe"])
							else
								self.Settings.profile.pSetting.attachFrame = val
							end
						end,
						get = function() return self.Settings.profile.pSetting.attachFrame end,
					},
				},
			},
			Func = {
				name = L["Function"],
				type = "group",
				order = 7,
				set = function(info, val) self.Settings.profile.Func[info[#info]] = val end,
				get = function(info) return self.Settings.profile.Func[info[#info]] end,
				args = {
					Interrupt = {
						type = "toggle",
						width = "normal",
						order = 1,
						name = L["Interrupt"],
						desc = L["Interrupt Desc"],
					},
					Racial = {
						type = "toggle",
						width = "normal",
						order = 2,
						name = L["Racial"],
						desc = L["Racial Desc"],
					},
					Trinket = {
						type = "toggle",
						width = "normal",
						order = 3,
						name = L["Trinket"],
						desc = L["Trinket Desc"],
					},
					CC = {
						type = "toggle",
						width = "normal",
						order = 4,
						name = L["CC"],
						desc = L["CC Desc"],
					},
					Dispel = {
						type = "toggle",
						width = "normal",
						order = 5,
						name = L["Dispel"],
						desc = L["Dispel Desc"],
					},
					dummy = {
						name = "",
						type = "description",
						width = "full",
						order = 6,
					},
					ColorBasc = {
						name = L["ColorBasc"],
						desc = function ()
							local color = self.Settings.profile.Func.ColorBasc
							local R = "|cffff0000R|r:"..color[1] * 0xff
							local G = " |cff00ff00G|r:"..color[2] * 0xff
							local B = " |cff0000ffB|r:"..color[3] * 0xff
							--local A = " A:"..math_floor((color[4] * 100) + 0.5)

							--return R..G..B..A
							return R..G..B
						end,
						type = "color",
						width = "normal",
						order = 7,
						--hasAlpha = true,
						set = function(info, ...) self.Settings.profile.Func.ColorBasc = {...} end,
						get = function() return unpack(self.Settings.profile.Func.ColorBasc) end,
					},
					IconBorder = {
						name = L["Func_IconBorder"],
						type = "select",
						width = "normal",
						order = 8,
						values = {
							["2px"] = "2 Pixel",
							["3px"] = "3 Pixel",
						},
					},
					dummy2 = {
						name = "",
						type = "description",
						width = "normal",
						order = 9,
					},
					FontEnable = {
						name = L["Func_FontEnable"],
						type = "toggle",
						width = "normal",
						order = 10,
					},
					FontScale = {
						name = L["Func_FontScale"],
						type = "range",
						width = "normal",
						disabled = function() return not self.Settings.profile.Func.FontEnable end,
						order = 11,
						isPercent = true,
						min = 0.4,
						max = 1.2,
						step = 0.01,
					},
					FontPoint = {
						name = L["Func_FontPoint"],
						type = "select",
						width = "normal",
						disabled = function() return not self.Settings.profile.Func.FontEnable end,
						order = 12,
						values = {
							["TOP"] = L["TOP"],
							["TOPLEFT"] = L["TOPLEFT"],
							["TOPRIGHT"] = L["TOPRIGHT"],
							["RIGHT"] = L["RIGHT"],
							["CENTER"] = L["CENTER"],
							["LEFT"] = L["LEFT"],
							["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
							["BOTTOMLEFT"] = L["BOTTOMLEFT"],
							["BOTTOM"] = L["BOTTOM"],
						},
						sorting = {
							"TOPLEFT",
							"TOP",
							"TOPRIGHT",
							"LEFT",
							"CENTER",
							"RIGHT",
							"BOTTOMLEFT",
							"BOTTOM",
							"BOTTOMRIGHT",
						},
					},
				},
			},
			Group = {
				name = L["Category"],
				type = "group",
				order = 8,
				set = function(info, val) self.Settings.profile.Group[info[#info]] = val end,
				get = function(info) return self.Settings.profile.Group[info[#info]] end,
				args = {
					Description = {
						type = "description",
						name = L["Category Desc"],
						width = "full",
						order = 1,
					},
					taunt = {
						type = "toggle",
						width = "normal",
						order = 2,
						name = L["taunt"],
						desc = L["taunt Desc"],
					},
					incapacitate = {
						type = "toggle",
						width = "normal",
						order = 3,
						name = L["incapacitate"],
						desc = L["incapacitate Desc"],
					},
					silence = {
						type = "toggle",
						width = "normal",
						order = 4,
						name = L["silence"],
						desc = L["silence Desc"],
					},
					disorient = {
						type = "toggle",
						width = "normal",
						order = 5,
						name = L["disorient"],
						desc = L["disorient Desc"],
					},
					stun = {
						type = "toggle",
						width = "normal",
						order = 6,
						name = L["stun"],
						desc = L["stun Desc"],
					},
					root = {
						type = "toggle",
						width = "normal",
						order = 7,
						name = L["root"],
						desc = L["root Desc"],
					},
					knockback = {
						type = "toggle",
						width = "normal",
						order = 8,
						name = L["knockback"],
						desc = L["knockback Desc"],
					},
					disarm = {
						type = "toggle",
						width = "normal",
						order = 9,
						name = L["disarm"],
						desc = L["disarm Desc"],
					},
					dummy = {
						name = "",
						type = "description",
						width = "full",
						order = 10,
					},
					tauntCommon = {
						type = "input",
						disabled = function() return not (self.Settings.profile.gSetting.CCCommonIcon and self.Settings.profile.Group.taunt) end,
						order = 11,
						name = L["taunt name"],
						desc = L["taunt Common Desc"],
						set = function(_, val)
							local num = tonumber(val)
							if GetSpellInfo(num) then
								self.Settings.profile.Group.tauntCommon = num
							else
								DEFAULT_CHAT_FRAME:AddMessage("|c00008000".."NameplateCCnTrinket".." |r"..val..L["rightcommon"])
							end
						end,
						get = function() return InChatTexture(self.Settings.profile.Group.tauntCommon) end,
					},
					incapacitateCommon = {
						type = "input",
						disabled = function() return not (self.Settings.profile.gSetting.CCCommonIcon and self.Settings.profile.Group.incapacitate) end,
						order = 12,
						name = L["incapacitate name"],
						desc = L["incapacitate Common Desc"],
						set = function(_, val)
							local num = tonumber(val)
							if GetSpellInfo(num) then
								self.Settings.profile.Group.incapacitateCommon = num
							else
								DEFAULT_CHAT_FRAME:AddMessage("|c00008000".."NameplateCCnTrinket".." |r"..val..L["rightcommon"])
							end
						end,
						get = function() return InChatTexture(self.Settings.profile.Group.incapacitateCommon) end,
					},
					silenceCommon = {
						type = "input",
						disabled = function() return not (self.Settings.profile.gSetting.CCCommonIcon and self.Settings.profile.Group.silence) end,
						order = 13,
						name = L["silence name"],
						desc = L["silence Common Desc"],
						set = function(_, val)
							local num = tonumber(val)
							if GetSpellInfo(num) then
								self.Settings.profile.Group.silenceCommon = num
							else
								DEFAULT_CHAT_FRAME:AddMessage("|c00008000".."NameplateCCnTrinket".." |r"..val..L["rightcommon"])
							end
						end,
						get = function() return InChatTexture(self.Settings.profile.Group.silenceCommon) end,
					},
					disorientCommon = {
						type = "input",
						disabled = function() return not (self.Settings.profile.gSetting.CCCommonIcon and self.Settings.profile.Group.disorient) end,
						order = 14,
						name = L["disorient name"],
						desc = L["disorient Common Desc"],
						set = function(_, val)
							local num = tonumber(val)
							if GetSpellInfo(num) then
								self.Settings.profile.Group.disorientCommon = num
							else
								DEFAULT_CHAT_FRAME:AddMessage("|c00008000".."NameplateCCnTrinket".." |r"..val..L["rightcommon"])
							end
						end,
						get = function() return InChatTexture(self.Settings.profile.Group.disorientCommon) end,
					},
					stunCommon = {
						type = "input",
						disabled = function() return not (self.Settings.profile.gSetting.CCCommonIcon and self.Settings.profile.Group.stun) end,
						order = 15,
						name = L["stun name"],
						desc = L["stun Common Desc"],
						set = function(_, val)
							local num = tonumber(val)
							if GetSpellInfo(num) then
								self.Settings.profile.Group.stunCommon = num
							else
								DEFAULT_CHAT_FRAME:AddMessage("|c00008000".."NameplateCCnTrinket".." |r"..val..L["rightcommon"])
							end
						end,
						get = function() return InChatTexture(self.Settings.profile.Group.stunCommon) end,
					},
					rootCommon = {
						type = "input",
						disabled = function() return not (self.Settings.profile.gSetting.CCCommonIcon and self.Settings.profile.Group.root) end,
						order = 16,
						name = L["root name"],
						desc = L["root Common Desc"],
						set = function(_, val)
							local num = tonumber(val)
							if GetSpellInfo(num) then
								self.Settings.profile.Group.rootCommon = num
							else
								DEFAULT_CHAT_FRAME:AddMessage("|c00008000".."NameplateCCnTrinket".." |r"..val..L["rightcommon"])
							end
						end,
						get = function() return InChatTexture(self.Settings.profile.Group.rootCommon) end,
					},
					knockbackCommon = {
						type = "input",
						disabled = function() return not (self.Settings.profile.gSetting.CCCommonIcon and self.Settings.profile.Group.knockback) end,
						order = 17,
						name = L["knockback name"],
						desc = L["knockback Common Desc"],
						set = function(_, val)
							local num = tonumber(val)
							if GetSpellInfo(num) then
								self.Settings.profile.Group.knockbackCommon = num
							else
								DEFAULT_CHAT_FRAME:AddMessage("|c00008000".."NameplateCCnTrinket".." |r"..val..L["rightcommon"])
							end
						end,
						get = function() return InChatTexture(self.Settings.profile.Group.knockbackCommon) end,
					},
					disarmCommon = {
						type = "input",
						disabled = function() return not (self.Settings.profile.gSetting.CCCommonIcon and self.Settings.profile.Group.disarm) end,
						order = 18,
						name = L["disarm name"],
						desc = L["disarm Common Desc"],
						set = function(_, val)
							local num = tonumber(val)
							if GetSpellInfo(num) then
								self.Settings.profile.Group.disarmCommon = num
							else
								DEFAULT_CHAT_FRAME:AddMessage("|c00008000".."NameplateCCnTrinket".." |r"..val..L["rightcommon"])
							end
						end,
						get = function() return InChatTexture(self.Settings.profile.Group.disarmCommon) end,
					},
					dummyCommon = {
						name = "",
						type = "description",
						width = "full",
						order = 19,
					},
					ColorFull = {
						name = L["ColorFull"],
						desc = function ()
							local color = self.Settings.profile.Group.ColorFull
							local R = "|cffff0000R|r:"..color[1] * 0xff
							local G = " |cff00ff00G|r:"..color[2] * 0xff
							local B = " |cff0000ffB|r:"..color[3] * 0xff
							local A = " A:"..math_floor((color[4] * 100) + 0.5)

							return R..G..B..A
						end,
						type = "color",
						width = "normal",
						order = 41,
						hasAlpha = true,
						set = function(info, ...) self.Settings.profile.Group.ColorFull = {...} end,
						get = function() return unpack(self.Settings.profile.Group.ColorFull) end,
					},
					ColorHalf = {
						name = L["ColorHalf"],
						desc = function ()
							local color = self.Settings.profile.Group.ColorHalf
							local R = "|cffff0000R|r:"..color[1] * 0xff
							local G = " |cff00ff00G|r:"..color[2] * 0xff
							local B = " |cff0000ffB|r:"..color[3] * 0xff
							local A = " A:"..math_floor((color[4] * 100) + 0.5)

							return R..G..B..A
						end,
						type = "color",
						width = "normal",
						order = 42,
						hasAlpha = true,
						set = function(info, ...) self.Settings.profile.Group.ColorHalf = {...} end,
						get = function() return unpack(self.Settings.profile.Group.ColorHalf) end,
					},
					ColorQuat = {
						name = L["ColorQuat"],
						desc = function ()
							local color = self.Settings.profile.Group.ColorQuat
							local R = "|cffff0000R|r:"..color[1] * 0xff
							local G = " |cff00ff00G|r:"..color[2] * 0xff
							local B = " |cff0000ffB|r:"..color[3] * 0xff
							local A = " A:"..math_floor((color[4] * 100) + 0.5)

							return R..G..B..A
						end,
						type = "color",
						width = "normal",
						order = 43,
						hasAlpha = true,
						set = function(info, ...) self.Settings.profile.Group.ColorQuat = {...} end,
						get = function() return unpack(self.Settings.profile.Group.ColorQuat) end,
					},
				},
			},
			CCHL = {
				name = "CC Highlight",
				type = "group",
				order = 9,
				set = function(info, val) self.Settings.profile.CCHL[info[#info]] = val end,
				get = function(info) return self.Settings.profile.CCHL[info[#info]] end,
				args = {
					Description = {
						type = "description",
						name = L["CCHL Desc"],
						width = "full",
						order = 1,
					},
					Enable = {
						type = "toggle",
						width = 3,
						order = 2,
						name = L["CCHL Enable"],
					},
					Style = {
						name = L["CCHL Style"],
						type = "select",
						disabled = function() return not self.Settings.profile.CCHL.Enable end,
						width = "normal",
						order = 3,
						values = {
							["ButtonGlow"] = "ButtonGlow",
							["PixelGlow"] = "PixelGlow",
							["AutoCastGlow"] = "AutoCastGlow",
						},
					},
					dummy = {
						name = "",
						type = "description",
						width = "full",
						order = 4,
					},
					pixellength = {
						name = L["CCHL pixellength"],
						type = "range",
						disabled = function() return not self.Settings.profile.CCHL.Enable end,
						hidden = function(info)
							if self.Settings.profile.CCHL.Style == "PixelGlow" then
								return false
							end
							return true
						end,
						width = "normal",
						order = 5,
						isPercent = false,
						min = 2,
						max = 10,
						step = 1,
					},
					pixelth = {
						name = L["CCHL pixelth"],
						type = "range",
						disabled = function() return not self.Settings.profile.CCHL.Enable end,
						hidden = function(info)
							if self.Settings.profile.CCHL.Style == "PixelGlow" then
								return false
							end
							return true
						end,
						width = "normal",
						order = 6,
						isPercent = false,
						min = 1,
						max = 7,
						step = 1,
					},
					autoscale = {
						name = L["CCHL autoscale"],
						type = "range",
						disabled = function() return not self.Settings.profile.CCHL.Enable end,
						hidden = function(info)
							if self.Settings.profile.CCHL.Style == "AutoCastGlow" then
								return false
							end
							return true
						end,
						width = "normal",
						order = 7,
						isPercent = false,
						min = 1,
						max = 5,
						step = 0.1,
					},
				},
			},
		}
	}

	LibStub("AceConfig-3.0"):RegisterOptionsTable("NameplateCCnTrinket", AceConfig)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("NameplateCCnTrinket", "NameplateCCnTrinket")
end
