local AddonName, NS = ...

local IsInInstance = IsInInstance
local print = print
local CopyTable = CopyTable
local tonumber = tonumber
local tostring = tostring
local CreateFrame = CreateFrame
local pairs = pairs
local next = next

local tinsert = table.insert
local tsort = table.sort

local GetSpellInfo = C_Spell.GetSpellInfo
local GetSpellDescription = C_Spell.GetSpellDescription
-- local GetSpellInfo = C_Spell.GetSpellInfo

-- local AllCooldowns = NS.AllCooldowns

local AceConfig = {
  name = AddonName,
  type = "group",
  childGroups = "tab",
  args = {
    general = {
      name = "General",
      type = "group",
      args = {
        test = {
          name = "Enable test mode",
          desc = "Only works outside of an instance.",
          type = "toggle",
          width = 0.9,
          order = 1,
          set = function(_, val)
            if val then
              if IsInInstance() then
                print("Can't test while in an instance")
              else
                NS.db.global.test = val
                NS.EnableTestMode()
              end
            else
              NS.db.global.test = false
              NS.DisableTestMode()
            end
          end,
          get = function(_)
            return NS.db.global.test
          end,
        },
        testNPCs = {
          name = "Enable testing on NPCs",
          desc = "Show test icons on npcs.",
          type = "toggle",
          width = 1.0,
          order = 2,
          set = function(_, val)
            NS.db.global.testNPCs = val
            NS.OnDbChanged()
          end,
          get = function(_)
            return NS.db.global.testNPCs
          end,
        },
        spacing1 = { type = "description", order = 3, name = "" },
        trinketOnly = {
          name = "Track Trinket Only",
          desc = "Turning this off tracks other spells similar that prevent cc.",
          type = "toggle",
          width = 0.9,
          order = 4,
          set = function(_, val)
            NS.db.global.trinketOnly = val
            NS.OnDbChanged()
          end,
          get = function(_)
            return NS.db.global.trinketOnly
          end,
        },
        targetOnly = {
          name = "Track current target only",
          desc = "Show only for the current target nameplate",
          type = "toggle",
          width = 1.5,
          order = 5,
          set = function(_, val)
            NS.db.global.targetOnly = val
            NS.OnDbChanged()
          end,
          get = function(_)
            return NS.db.global.targetOnly
          end,
        },
        spacing2 = { type = "description", order = 6, name = "" },
        showSelf = {
          name = "Show on Self",
          desc = "Show on your nameplate",
          type = "toggle",
          width = 0.9,
          order = 7,
          set = function(_, val)
            NS.db.global.showSelf = val
            NS.OnDbChanged()
          end,
          get = function(_)
            return NS.db.global.showSelf
          end,
        },
        showOnAllies = {
          name = "Show on friendly players",
          desc = "Shows on friendly player nameplates",
          type = "toggle",
          width = 1.2,
          order = 8,
          set = function(_, val)
            NS.db.global.showOnAllies = val
            NS.OnDbChanged()
          end,
          get = function(_)
            return NS.db.global.showOnAllies
          end,
        },
        showOnEnemies = {
          name = "Show on enemy players",
          desc = "Shows on enemy player nameplates",
          type = "toggle",
          width = 1.2,
          order = 9,
          set = function(_, val)
            NS.db.global.showOnEnemies = val
            NS.OnDbChanged()
          end,
          get = function(_)
            return NS.db.global.showOnEnemies
          end,
        },
        spacing3 = { type = "description", order = 10, name = "" },
        enableGlow = {
          name = "Enable Glow on Trinkets",
          desc = "Shows a yellow glow around trinket icons.",
          type = "toggle",
          width = 1.2,
          order = 11,
          set = function(_, val)
            NS.db.global.enableGlow = val
            NS.OnDbChanged()
          end,
          get = function(_)
            return NS.db.global.enableGlow
          end,
        },
        attachToHealthBar = {
          name = "Attach directly to the healthbar",
          type = "toggle",
          order = 12,
          width = 1.5,
          get = function(_)
            return NS.db.global.attachToHealthBar
          end,
          set = function(_, val)
            NS.db.global.attachToHealthBar = val
            NS.OnDbChanged()
          end,
        },
        spacing4 = { type = "description", order = 13, name = "" },
        desc1 = {
          type = "description",
          order = 14,
          name = "Manage how nameplate scale and alpha effect icons:",
        },
        ignoreNameplateAlpha = {
          name = "Ignore Nameplate Alpha",
          desc = "Turning this off keeps the icons fully visible even when the nameplate fades out.",
          type = "toggle",
          width = 1.2,
          order = 15,
          set = function(_, val)
            NS.db.global.ignoreNameplateAlpha = val
            NS.OnDbChanged()
          end,
          get = function(_)
            return NS.db.global.ignoreNameplateAlpha
          end,
        },
        ignoreNameplateScale = {
          name = "Ignore Nameplate Scale",
          desc = "Turning this off keeps the icons at the size you set even when the nameplate gets bigger or smaller.",
          type = "toggle",
          width = 1.1,
          order = 16,
          set = function(_, val)
            NS.db.global.ignoreNameplateScale = val
            NS.OnDbChanged()
          end,
          get = function(_)
            return NS.db.global.ignoreNameplateScale
          end,
        },
        enableGroup = {
          name = "Choose what content icons should show in:",
          type = "group",
          inline = true,
          order = 17,
          args = {
            arena = {
              name = "Arena",
              type = "toggle",
              width = 0.45,
              order = 1,
              set = function(_, val)
                NS.db.global.instanceTypes.arena = val
                NS.OnDbChanged()
              end,
              get = function(_)
                return NS.db.global.instanceTypes.arena
              end,
            },
            pvp = {
              name = "Battlegrounds",
              type = "toggle",
              width = 0.75,
              order = 2,
              set = function(_, val)
                NS.db.global.instanceTypes.pvp = val
                NS.OnDbChanged()
              end,
              get = function(_)
                return NS.db.global.instanceTypes.pvp
              end,
            },
            none = {
              name = "Outdoors",
              type = "toggle",
              width = 0.5,
              order = 3,
              set = function(_, val)
                NS.db.global.instanceTypes.none = val
                NS.OnDbChanged()
              end,
              get = function(_)
                return NS.db.global.instanceTypes.none
              end,
            },
          },
        },
        sortOrder = {
          name = "Sort Order",
          desc = "Set what order the icons should display in.",
          type = "select",
          width = "normal",
          order = 18,
          values = {
            [NS.SORT_MODE_NONE] = "None",
            [NS.SORT_MODE_TRINKET_INTERRUPT_OTHER] = "Trinket > Interrupt > Other",
            [NS.SORT_MODE_INTERRUPT_TRINKET_OTHER] = "Interrupt > Trinket > Other",
            [NS.SORT_MODE_TRINKET_OTHER] = "Trinket > Other",
            [NS.SORT_MODE_INTERRUPT_OTHER] = "Interrupt > Other",
          },
          sorting = {
            NS.SORT_MODE_NONE,
            NS.SORT_MODE_TRINKET_INTERRUPT_OTHER,
            NS.SORT_MODE_INTERRUPT_TRINKET_OTHER,
            NS.SORT_MODE_TRINKET_OTHER,
            NS.SORT_MODE_INTERRUPT_OTHER,
          },
          set = function(_, val)
            NS.db.global.sortOrder = val
            NS.OnDbChanged()
          end,
          get = function(_)
            return NS.db.global.sortOrder
          end,
        },
        spacing5 = { type = "description", order = 19, name = " " },
        iconAlpha = {
          name = "Icon Alpha",
          type = "range",
          width = "normal",
          order = 20,
          isPercent = false,
          min = 0,
          max = 1,
          step = 0.01,
          set = function(_, val)
            NS.db.global.iconAlpha = val
            NS.OnDbChanged()
          end,
          get = function(_)
            return NS.db.global.iconAlpha
          end,
        },
        iconSize = {
          name = "Icon Size",
          type = "range",
          width = "normal",
          order = 21,
          isPercent = false,
          min = 12,
          max = 64,
          step = 1,
          set = function(_, val)
            NS.db.global.iconSize = val
            NS.OnDbChanged()
          end,
          get = function(_)
            return NS.db.global.iconSize
          end,
        },
        iconSpacing = {
          name = "Icon Spacing",
          desc = "Spacing between each icon",
          type = "range",
          width = "normal",
          order = 22,
          isPercent = false,
          min = 0,
          max = 25,
          step = 1,
          set = function(_, val)
            NS.db.global.iconSpacing = val
            NS.OnDbChanged()
          end,
          get = function(_)
            return NS.db.global.iconSpacing
          end,
        },
        spacing6 = { type = "description", order = 23, name = " " },
        anchor = {
          name = "Anchor",
          type = "select",
          width = "normal",
          order = 24,
          values = {
            ["TOP"] = "Top",
            ["BOTTOM"] = "Bottom",
            ["LEFT"] = "Left",
            ["RIGHT"] = "Right",
            ["TOPLEFT"] = "Top Left",
            ["TOPRIGHT"] = "Top Right",
            ["BOTTOMLEFT"] = "Bottom Left",
            ["BOTTOMRIGHT"] = "Bottom Right",
            ["CENTER"] = "Center",
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
          set = function(_, val)
            NS.db.global.anchor = val
            NS.OnDbChanged()
          end,
          get = function(_)
            return NS.db.global.anchor
          end,
        },
        anchorTo = {
          name = "Anchor To",
          type = "select",
          width = "normal",
          order = 25,
          values = {
            ["TOP"] = "Top",
            ["BOTTOM"] = "Bottom",
            ["LEFT"] = "Left",
            ["RIGHT"] = "Right",
            ["TOPLEFT"] = "Top Left",
            ["TOPRIGHT"] = "Top Right",
            ["BOTTOMLEFT"] = "Bottom Left",
            ["BOTTOMRIGHT"] = "Bottom Right",
            ["CENTER"] = "Center",
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
          set = function(_, val)
            NS.db.global.anchorTo = val
            NS.OnDbChanged()
          end,
          get = function(_)
            return NS.db.global.anchorTo
          end,
        },
        growDirection = {
          name = "Grow Direction",
          desc = "The direction the icons will output",
          type = "select",
          width = "normal",
          order = 26,
          values = {
            [NS.ICON_GROW_DIRECTION_LEFT] = "Left",
            [NS.ICON_GROW_DIRECTION_RIGHT] = "Right",
          },
          set = function(_, val)
            NS.db.global.growDirection = val
            NS.OnDbChanged()
          end,
          get = function(_)
            return NS.db.global.growDirection
          end,
        },
        spacing7 = { type = "description", order = 27, name = " " },
        offsetX = {
          name = "Offset X",
          desc = "Offset left/right from the anchor point",
          type = "range",
          width = "normal",
          order = 28,
          isPercent = false,
          min = -250,
          max = 250,
          step = 1,
          set = function(_, val)
            NS.db.global.offsetX = val
            --- @class OFFSET
            NS.OFFSET.x = val
            NS.OnDbChanged()
          end,
          get = function(_)
            return NS.db.global.offsetX
          end,
        },
        offsetY = {
          name = "Offset Y",
          desc = "Offset top/bottom from the anchor point",
          type = "range",
          width = "normal",
          order = 29,
          isPercent = false,
          min = -250,
          max = 250,
          step = 1,
          set = function(_, val)
            NS.db.global.offsetY = val
            --- @class OFFSET
            NS.OFFSET.y = val
            NS.OnDbChanged()
          end,
          get = function(_)
            return NS.db.global.offsetY
          end,
        },
        spacing8 = { type = "description", order = 30, name = " " },
        reset = {
          name = "Reset Everything",
          type = "execute",
          width = "normal",
          order = 100,
          func = function()
            NameplateTrinketDB = CopyTable(NS.DefaultDatabase)
            NS.db = CopyTable(NS.DefaultDatabase)
            NS.OnDbChanged()
          end,
        },
      },
    },
    spells = {
      name = "Spells",
      type = "group",
      childGroups = "tree",
      args = {
        addSpell = {
          order = 1,
          type = "input",
          name = "Add a new spell to the list",
          desc = "Enter a Spell ID or Name (case sensitive) then press Okay.",
          set = function(info, value)
            if value then
              local trimmedValue = NS.trimToEmpty(value)
              if trimmedValue == "" then
                NS.AceConfig.args.spells.args.addSpellError.name = ""
              else
                local spellId = tonumber(value)
                if spellId then
                  local spellInfo = GetSpellInfo(spellId)
                  if spellInfo then
                    NS.AceConfig.args.spells.args.addSpellError.name = "|cFF00FF00"
                      .. spellInfo.name
                      .. " Added! Now you need to enter a cooldown for it."

                    local spellDescription = GetSpellDescription(spellInfo.spellID)
                    NS.db.spells[spellInfo.spellID] = {
                      cooldown = 0,
                      enabled = false,
                      spellId = spellInfo.spellID,
                      spellIcon = spellInfo.iconID,
                      spellName = spellInfo.name,
                      spellDescription = spellDescription or "",
                    }
                    NS.RebuildOptions()
                    NS.OnDbChanged()
                  else
                    NS.AceConfig.args.spells.args.addSpellError.name = "|cFFFF0000" .. " Invalid Spell ID"
                  end
                else
                  local spellInfo = GetSpellInfo(value)
                  if spellInfo then
                    NS.AceConfig.args.spells.args.addSpellError.name = "|cFF00FF00"
                      .. spellInfo.name
                      .. " Added! Now you need to enter a cooldown for it."

                    local spellDescription = GetSpellDescription(spellInfo.spellID)
                    NS.db.spells[spellInfo.spellID] = {
                      cooldown = 0,
                      enabled = false,
                      spellId = spellInfo.spellID,
                      spellIcon = spellInfo.iconID,
                      spellName = spellInfo.name,
                      spellDescription = spellDescription or "",
                    }
                    NS.RebuildOptions()
                    NS.OnDbChanged()
                  else
                    NS.AceConfig.args.spells.args.addSpellError.name = "|cFFFF0000"
                      .. " Invalid Spell Name. Try a Spell ID instead."
                  end
                end
              end
            else
              NS.AceConfig.args.spells.args.addSpellError.name = ""
            end
          end,
        },
        addSpellError = {
          order = 2,
          type = "description",
          name = "",
          width = "double",
        },
      },
    },
  },
}
NS.AceConfig = AceConfig

--- @type fun(spellId: number): boolean
NS.hasErrors = function(spellId)
  if NS.db then
    --- @type boolean
    local cooldownValid = NS.db.spells[spellId].cooldown ~= nil
      and tonumber(NS.db.spells[spellId].cooldown) ~= nil
      and tonumber(NS.db.spells[spellId].cooldown) > 0
    --- @type boolean
    local spellIdValid = NS.db.spells[spellId].spellId ~= nil and tonumber(NS.db.spells[spellId].spellId) ~= nil
    --- @type boolean
    local spellIconValid = NS.db.spells[spellId].spellIcon ~= nil and tonumber(NS.db.spells[spellId].spellIcon) ~= nil

    return not cooldownValid or not spellIdValid or not spellIconValid
  end

  return false
end

--- @type fun(spellId: number, spellInfo: MySpellInfo, index: integer)
NS.MakeOption = function(spellId, spellInfo, index)
  local spellName = spellInfo.spellName
  local spellIcon = spellInfo.spellIcon
  local spellDescription = spellInfo.spellDescription
  local spellCooldown = spellInfo.cooldown
  local spellID = spellInfo.spellId
  local SPELL_ID = tostring(spellId)

  local color = ""
  if spellInfo.enabled and spellCooldown > 0 then
    color = "|cFF00FF00" --green
  elseif not spellInfo.enabled then
    color = "|cFFFF0000" --red
  elseif spellInfo.enabled and spellCooldown <= 0 then
    color = "|cFFFFFF00" --yellow
  end

  NS.AceConfig.args.spells.args[SPELL_ID] = {
    name = color .. spellName,
    icon = spellIcon,
    desc = spellDescription,
    type = "group",
    order = 10 + index,
    args = {
      enabled = {
        name = "Enable",
        type = "toggle",
        width = "full",
        order = 1,
        disabled = function()
          return NS.hasErrors(spellId)
        end,
        get = function(info)
          return NS.db[info[1]][tonumber(info[2])] and NS.db[info[1]][tonumber(info[2])][info[3]] or spellInfo.enabled
        end,
        set = function(info, value)
          local hasErrors = NS.hasErrors(spellId)

          if value and tonumber(NS.db.spells[spellId].cooldown) > 0 then
            color = "|cFF00FF00" --green
          elseif not value then
            color = "|cFFFF0000" --red
          elseif value and tonumber(NS.db.spells[spellId].cooldown) <= 0 then
            color = "|cFFFFFF00" --yellow
          end

          NS.AceConfig.args.spells.args[SPELL_ID].name = color .. spellName

          if value and not hasErrors then
            NS.db[info[1]][tonumber(info[2])][info[3]] = true

            if NS.AceConfig.args.spells.args[SPELL_ID].args.enabledError then
              NS.AceConfig.args.spells.args[SPELL_ID].args.enabledError.name = ""
            end
          else
            NS.db[info[1]][tonumber(info[2])][info[3]] = false

            if hasErrors then
              if NS.AceConfig.args.spells.args[SPELL_ID].args.enabledError then
                NS.AceConfig.args.spells.args[SPELL_ID].args.enabledError.name = "|cFFFF0000"
                  .. " Correct any errors below before you can enable this spell"
              end
            end
          end

          NS.OnDbChanged()
        end,
      },
      enabledError = {
        order = 2,
        type = "description",
        name = NS.hasErrors(spellId) and "|cFFFF0000" .. " Correct any errors below before you can enable this spell"
          or "",
        width = "double",
      },
      spellId = {
        order = 3,
        type = "input",
        name = "Spell ID",
        get = function(info)
          return NS.db[info[1]][tonumber(info[2])] and tostring(NS.db[info[1]][tonumber(info[2])][info[3]])
            or tostring(spellID)
        end,
        set = function(info, value)
          if spellId then
            local checkedSpellInfo = GetSpellInfo(spellId)
            if checkedSpellInfo then
              NS.db[info[1]][tonumber(info[2])][info[3]] = spellId

              NS.AceConfig.args.spells.args[SPELL_ID].args.spellIdError.name = ""

              NS.OnDbChanged()
            else
              NS.AceConfig.args.spells.args[SPELL_ID].args.spellIdError.name = "|cFFFF0000" .. " Invalid Spell ID"
            end
          else
            local trimmedValue = NS.trimToEmpty(value)
            if trimmedValue == "" then
              NS.AceConfig.args.spells.args[SPELL_ID].args.spellIdError.name = "|cFFFF0000" .. " Must enter a value"
            else
              local checkedSpellInfo = GetSpellInfo(value)
              if checkedSpellInfo then
                NS.db[info[1]][tonumber(info[2])][info[3]] = spellId

                NS.AceConfig.args.spells.args[SPELL_ID].args.spellIdError.name = ""

                NS.OnDbChanged()
              else
                NS.AceConfig.args.spells.args[SPELL_ID].args.spellIdError.name = "|cFFFF0000" .. " Invalid Spell Name"
              end
            end
          end
        end,
      },
      spellIdError = {
        order = 4,
        type = "description",
        name = "",
        width = "normal",
      },
      spacer2 = {
        order = 5,
        type = "description",
        name = "",
        width = "full",
      },
      cooldown = {
        order = 6,
        type = "input",
        name = "Cooldown",
        desc = "Cooldown time in seconds",
        get = function(info)
          return NS.db[info[1]][tonumber(info[2])] and tostring(NS.db[info[1]][tonumber(info[2])][info[3]])
            or tostring(spellCooldown)
        end,
        set = function(info, value)
          local cooldownValue = tonumber(value)

          if cooldownValue then
            if cooldownValue > 0 then
              NS.db[info[1]][tonumber(info[2])][info[3]] = value

              NS.AceConfig.args.spells.args[SPELL_ID].args.cooldownError.name = ""
              NS.AceConfig.args.spells.args[SPELL_ID].args.enabledError.name = ""

              NS.OnDbChanged()
            else
              NS.AceConfig.args.spells.args[SPELL_ID].args.cooldownError.name = "|cFFFF0000"
                .. " Must be greater than 0"
            end

            if NS.db[info[1]][tonumber(info[2])].enabled and cooldownValue > 0 then
              color = "|cFF00FF00" --green
            elseif not NS.db[info[1]][tonumber(info[2])].enabled then
              color = "|cFFFF0000" --red
            elseif NS.db[info[1]][tonumber(info[2])].enabled and cooldownValue <= 0 then
              color = "|cFFFFFF00" --yellow
            end

            NS.AceConfig.args.spells.args[SPELL_ID].name = color .. spellName
          else
            local trimmedValue = NS.trimToEmpty(value)
            if trimmedValue == "" then
              NS.AceConfig.args.spells.args[SPELL_ID].args.cooldownError.name = "|cFFFF0000" .. " Must enter a value"
            else
              NS.AceConfig.args.spells.args[SPELL_ID].args.cooldownError.name = "|cFFFF0000" .. " Must be a number"
            end
          end
        end,
      },
      cooldownError = {
        order = 7,
        type = "description",
        name = spellCooldown <= 0 and "|cFFFF0000" .. " Must be greater than 0" or "",
        width = "normal",
      },
      spacer3 = {
        order = 8,
        type = "description",
        name = "",
        width = "full",
      },
      spellIcon = {
        order = 9,
        type = "input",
        name = "Spell Icon ID",
        get = function(info)
          return NS.db[info[1]][tonumber(info[2])] and tostring(NS.db[info[1]][tonumber(info[2])][info[3]])
            or tostring(spellIcon)
        end,
        set = function(info, value)
          local iconValue = tonumber(value)
          local valueLength = #value

          if iconValue then
            if valueLength <= 10 then
              local f = CreateFrame("Frame")
              local t = f:CreateTexture(nil, "BORDER")
              function TextureExists(path)
                t:SetTexture("?")
                t:SetTexture(path)
                return (t:GetTexture() ~= "?")
              end

              if TextureExists(iconValue) then
                NS.db[info[1]][tonumber(info[2])][info[3]] = iconValue

                t:Hide()
                f:Hide()

                NS.AceConfig.args.spells.args[SPELL_ID].args.spellImage.image = iconValue
                NS.AceConfig.args.spells.args[SPELL_ID].args.spellIconError.name = ""

                NS.OnDbChanged()
              else
                NS.AceConfig.args.spells.args[SPELL_ID].args.spellIconError.name = " Invalid Spell Icon ID"
              end
            else
              NS.AceConfig.args.spells.args[SPELL_ID].args.spellIconError.name = " Must be less than 11 digits"
            end
          else
            local trimmedValue = NS.trimToEmpty(value)
            if trimmedValue == "" then
              NS.AceConfig.args.spells.args[SPELL_ID].args.spellIconError.name = "|cFFFF0000" .. " Must enter a value"
            else
              NS.AceConfig.args.spells.args[SPELL_ID].args.spellIconError.name = "|cFFFF0000" .. " Must enter a number"
            end
          end
        end,
      },
      spellIconError = {
        order = 10,
        type = "description",
        name = "",
        width = "normal",
      },
      spacer4 = {
        order = 11,
        type = "description",
        name = "",
        width = "full",
      },
      spellImage = {
        order = 12,
        type = "description",
        name = " ",
        image = function(info)
          return NS.db[info[1]][tonumber(info[2])] and NS.db[info[1]][tonumber(info[2])].spellIcon or spellIcon
        end,
        imageHeight = 100,
        imageWidth = 100,
      },
      spacer5 = {
        order = 13,
        type = "description",
        name = "",
        width = "full",
      },
      removeSpell = {
        name = "Remove",
        type = "execute",
        width = "normal",
        confirm = true,
        order = 100,
        func = function()
          NS.AceConfig.args.spells.args[SPELL_ID].args.spellImage.image = nil
          NS.AceConfig.args.spells.args[SPELL_ID] = nil
          NS.db.spells[spellId] = nil
          NameplateTrinketDB = NS.db

          NS.RebuildOptions()
          NS.OnDbChanged()
        end,
      },
    },
  }
end

-- --
-- -- WE DON'T WANT TO INITIALIZE THE OPTIONS SINCE
-- -- WE SOLELY WANT TO ONLY USE SPELLS FROM THE DB
-- --
-- local spellList = {}
-- for spellId, cooldown in pairs(AllCooldowns) do
--   local spellInfo = GetSpellInfo(spellId)
--   local spellDescription = GetSpellDescription(spellId)
--   if spellInfo and spellInfo.name then
--     local spell = {
--       [spellId] = {
--         cooldown = cooldown,
--         enabled = true,
--         spellId = spellInfo.spellID,
--         spellIcon = spellInfo.iconID,
--         spellName = spellInfo.name,
--         spellDescription = spellDescription or "",
--       },
--     }
--     tinsert(spellList, spell)
--   end
-- end
-- tsort(spellList, NS.SortSpellList)
-- for i = 1, #spellList do
--   local spell = spellList[i]
--   if spell then
--     local spellId, spellInfo = next(spell)
--     NS.MakeOption(spellId, spellInfo, i)
--   end
-- end

NS.BuildOptions = function()
  --- @type table<number, MySpellInfo>
  local buildList = {}
  for spellId, spellInfo in pairs(NS.db.spells) do
    --- @type table<number, MySpellInfo>
    local spell = {
      [spellId] = spellInfo,
    }
    tinsert(buildList, spell)
  end
  tsort(buildList, NS.SortSpellList)

  for i = 1, #buildList do
    local spell = buildList[i]
    if spell then
      --- @type number, MySpellInfo
      local spellId, spellInfo = next(spell)
      NS.MakeOption(spellId, spellInfo, i)
    end
  end
end
