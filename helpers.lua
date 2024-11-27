local _, NS = ...

local IsInRaid = IsInRaid
local IsInGroup = IsInGroup
local GetNumGroupMembers = GetNumGroupMembers
local GetNumSubgroupMembers = GetNumSubgroupMembers
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local pairs = pairs
local type = type
local next = next
local setmetatable = setmetatable
local getmetatable = getmetatable

local twipe = table.wipe
local sgsub = string.gsub
local slen = string.len

local GetSpellTexture = C_Spell.GetSpellTexture

NS.trimToEmpty = function(str)
  -- Replace all whitespace characters with an empty string
  local trimmed = sgsub(str, "%s+", "")
  -- Check if the trimmed string has a length of 0
  if slen(trimmed) == 0 then
    return "" -- Return an empty string if only whitespace was present
  else
    return trimmed -- Otherwise, return the trimmed string
  end
end

NS.isInGroup = function()
  return IsInRaid() or IsInGroup()
end

NS.isHealer = function(unit)
  return UnitGroupRolesAssigned(unit) == "HEALER"
end

-- Function to assist iterating group members whether in a party or raid.
NS.IterateGroupMembers = function(reversed, forceParty)
  local unit = (not forceParty and IsInRaid()) and "raid" or "party"
  local numGroupMembers = unit == "party" and GetNumSubgroupMembers() or GetNumGroupMembers()
  local i = reversed and numGroupMembers or (unit == "party" and 0 or 1)
  return function()
    local ret
    if i == 0 and unit == "party" then
      ret = "player"
    elseif i <= numGroupMembers and i > 0 then
      ret = unit .. i
    end
    i = i + (reversed and -1 or 1)
    return ret
  end
end

function NS.deepcopy(object)
  local lookup_table = {}
  local function _copy(another_object)
    if type(another_object) ~= "table" then
      return another_object
    elseif lookup_table[another_object] then
      return lookup_table[another_object]
    end
    local new_table = {}
    lookup_table[another_object] = new_table
    for index, value in pairs(another_object) do
      new_table[_copy(index)] = _copy(value)
    end
    return setmetatable(new_table, getmetatable(another_object))
  end
  return _copy(object)
end

NS.SpellTextureByID = setmetatable({
  [NS.SPELL_PVPTRINKET] = 1322720,
  [42292] = 1322720,
  [200166] = 1247262,
}, {
  __index = function(t, key)
    local texture = GetSpellTexture(key)
    t[key] = texture
    return texture
  end,
})

-- Copies table values from src to dst if they don't exist in dst
NS.CopyDefaults = function(src, dst)
  if type(src) ~= "table" then
    return {}
  end

  if type(dst) ~= "table" then
    dst = {}
  end

  for k, v in pairs(src) do
    if type(v) == "table" then
      if k == "spells" then
        if next(dst[k]) == nil then
          dst[k] = NS.CopyDefaults(v, dst[k])
        end
      else
        dst[k] = NS.CopyDefaults(v, dst[k])
      end
    elseif type(v) ~= type(dst[k]) then
      dst[k] = v
    end
  end

  return dst
end

NS.CopyTable = function(src, dest)
  -- Handle non-tables and previously-seen tables.
  if type(src) ~= "table" then
    return src
  end

  if dest and dest[src] then
    return dest[src]
  end

  -- New table; mark it as seen an copy recursively.
  local s = dest or {}
  local res = {}
  s[src] = res

  for k, v in next, src do
    res[NS.CopyTable(k, s)] = NS.CopyTable(v, s)
  end

  return setmetatable(res, getmetatable(src))
end

-- Cleanup savedvariables by removing table values in src that no longer
-- exists in table dst (default settings)
NS.CleanupDB = function(src, dst)
  for key, value in pairs(src) do
    if dst[key] == nil then
      -- HACK: offsetsXY are not set in DEFAULT_SETTINGS but sat on demand instead to save memory,
      -- which causes nil comparison to always be true here, so always ignore these for now
      if key ~= "version" then
        src[key] = nil
      end
    elseif type(value) == "table" then
      if key ~= "spells" then -- also set on demand
        dst[key] = NS.CleanupDB(value, dst[key])
      end
    end
  end
  return dst
end

-- Pool for reusing tables. (Garbage collector isn't ran in combat unless max garbage is reached, which causes fps drops)
do
  local pool = {}

  NS.NewTable = function()
    local t = next(pool) or {}
    pool[t] = nil -- remove from pool
    return t
  end

  NS.RemoveTable = function(tbl)
    if tbl then
      pool[twipe(tbl)] = true -- add to pool, wipe returns pointer to tbl here
    end
  end

  NS.ReleaseTables = function()
    if next(pool) then
      pool = {}
    end
  end
end
