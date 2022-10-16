--
--
--[[
-- Dict(filename) return object of dict or  nil
dict:find_word(word) -- return table(list) or nil
dict:reduce_find_word(word) return table(list) or nil
dict:word_iter(word) return iter function for loop
dict:reduce_iter(word) return iter function for loop


--
-- example
--
local Dict=require 'tools/dict'
local dict= Dict(filename)  --essay.txt
dict:find_words("一天") -- return List ; dict:select(function(word) return word:match("^一天") end )
dict:reduce_find_word("一天") -- return List ;  find_word("一天") + find_word("天")

-- dict:empty( word ) -- return bool
-- coroutine function
for word,weight in dict:reduce_iter("一天") do
  local cand= Candidate("", 1,1, word, weight)
  yield(cand)
end


--]]

local List=require 'tools/list'
require 'tools/string'
local class = require 'tools/class'

warn("@on")
--  line= "word\twegiht"
local function conv_line(line)
    local word,weight = line:match("^(.*)\t%s*([%d]*).*")
    local key = word:utf8_sub(1,1)
    return key,word,weight
end
local function word_weight(word)
  return tonumber(word:match("^.*\t%s*([%d]*).*") )
end


local function load_essay(fpath)
  if fpath then
    local dict={}
    for data in io.open(fpath):lines() do
      local key= utf8.sub(data,1,1)
      dict[key] = type(dict[key]) == "table" and dict[key] or List()
      dict[key]:push( data )
    end
    return dict
  end
  (log and log.warning or warn)(filename .. " not exist in path of user_data or shared_data")
end

local pool={}
local M={}
M.__name= "Dict"
function M:_dict()
  return pool[self.filename]
end
function M:_load_dict()
  if not self:_dict() then
    pool[self.filename] = load_essay(self.path .."/".. self.filename)
  end
end
function M:_initialize(filename,path)
  self.path = path or "."
  self.filename=filename
  self:_load_dict()
  return self
end

local s_func=function(a,b) return word_weight(a)> word_weight(b) end

--function M:empty(word)
  --local key=word:utf8_sub(1,1)
  --return self[key] == nil or #self[key] < 2 or false
--end
function M:empty(word)
  for w,wt in self:reduce_iter(word) do
    return false
  end
  return true
end

function M:word_iter(word)
  local db=self:_dict()
  local words_tab = db and db[word:utf8_sub(1,1)] or List()
  return coroutine.wrap(function()
    --- sort check
    if not words_tab._sorted then
      words_tab:sort_self(s_func)
      words_tab._sorted = true
    end
    -- sort check
    for i,elm in ipairs(words_tab) do
      local w,wt = elm:match("^" .. word .. "(.+)\t%s*(%d*).*$" )
      if w then
        coroutine.yield( w,tonumber(wt))
      end
    end
  end )
end
function M:find_word(word)
  local l= List()
  for w in self:word_iter(word) do
    l:push(w)
  end
  return l
end

function M:reduce_iter(word)
  return coroutine.wrap(
  function()
    repeat
      for w,wt in self:word_iter(word) do
        coroutine.yield(w,wt)
      end
      word= word:utf8_sub(2)
    until word == ""
  end)
end
function M:reduce_find_word(word)
  local l=List()
  for w in self:reduce_iter(word) do
    l:push(w)
  end
  return l
end
return class(M)

