local _, NS = ...

local print = print
local select = select
local tostring = tostring
local setmetatable = setmetatable
local getmetatable = getmetatable
local pairs = pairs
local type = type
local CreateFrame = CreateFrame
local debugprofilestop = debugprofilestop
local assert = assert
local next = next

local sformat = string.format
local twipe = table.wipe

local GetSpellTexture = C_Spell.GetSpellTexture
local GetSpellInfo = C_Spell.GetSpellInfo

NS.Debug = function(...)
  if NS.db and NS.db.global.debug then
    print(...)
  end
end

function NS.Print(...)
  local text = ""
  for i = 1, select("#", ...) do
    text = text .. tostring(select(i, ...)) .. " "
  end
  DEFAULT_CHAT_FRAME:AddMessage(sformat("NameplateTrinket: %s", text), 0, 128, 128)
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

function NS.colorize_text(text, r, g, b)
  return sformat("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, text)
end

function NS.table_count(t)
  local count = 0
  for _ in pairs(t) do
    count = count + 1
  end
  return count
end

function NS.msg(text)
  local name = "NCOOLDOWNS_MSG"
  if StaticPopupDialogs[name] == nil then
    StaticPopupDialogs[name] = {
      text = name,
      button1 = OKAY,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3,
    }
  end
  StaticPopupDialogs[name].text = text
  StaticPopup_Show(name)
end

function NS.msgWithQuestion(text, funcOnAccept, funcOnCancel)
  local frameName = "NameplateTrinket_msgWithQuestion"
  if StaticPopupDialogs[frameName] == nil then
    StaticPopupDialogs[frameName] = {
      button1 = YES,
      button2 = NO,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3,
    }
  end
  StaticPopupDialogs[frameName].text = text
  StaticPopupDialogs[frameName].OnAccept = funcOnAccept
  StaticPopupDialogs[frameName].OnCancel = funcOnCancel
  StaticPopup_Show(frameName)
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

NS.SpellNameByID = setmetatable({}, {
  __index = function(t, key)
    local spellInfo = GetSpellInfo(key)
    local name = spellInfo ~= nil and spellInfo.name or nil
    t[key] = name
    return name
  end,
})

-- // CoroutineProcessor
do
  local CoroutineProcessor = {}
  CoroutineProcessor.frame = CreateFrame("frame")
  CoroutineProcessor.update = {}
  CoroutineProcessor.size = 0

  function NS.coroutine_queue(name, func)
    if not name then
      name = sformat("NIL%d", CoroutineProcessor.size + 1)
    end
    if not CoroutineProcessor.update[name] then
      CoroutineProcessor.update[name] = func
      CoroutineProcessor.size = CoroutineProcessor.size + 1
      CoroutineProcessor.frame:Show()
    end
  end

  function NS.coroutine_delete(name)
    if CoroutineProcessor.update[name] then
      CoroutineProcessor.update[name] = nil
      CoroutineProcessor.size = CoroutineProcessor.size - 1
      if CoroutineProcessor.size == 0 then
        CoroutineProcessor.frame:Hide()
      end
    end
  end

  CoroutineProcessor.frame:Hide()
  CoroutineProcessor.frame:SetScript("OnUpdate", function()
    local start = debugprofilestop()
    local hasData = true
    while debugprofilestop() - start < 16 and hasData do
      hasData = false
      for name, func in pairs(CoroutineProcessor.update) do
        hasData = true
        if coroutine.status(func) ~= "dead" then
          assert(coroutine.resume(func))
        else
          NS.coroutine_delete(name)
        end
      end
    end
  end)
end

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
      dst[k] = NS.CopyDefaults(v, dst[k])
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
      if key ~= "offsetsX" and key ~= "offsetsY" and key ~= "version" then
        src[key] = nil
      end
    elseif type(value) == "table" then
      if key ~= "disabledCategories" and key ~= "categoryTextures" then -- also sat on demand
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
