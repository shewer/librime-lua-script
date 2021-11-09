List=require 'tools/list'


string.utf8_len= utf8.len
string.utf8_offset=utf8.offset

string.utf8_sub=function(str,si,ei)
  local function index(ustr,i)
    return i>=0 and ( ustr:utf8_offset(i) or ustr:len() +1 )
    or ( ustr:utf8_offset(i) or 1 )
  end

  local u_si= index(str,si)
  ei = ei or str:utf8_len()
  ei = ei >=0 and ei +1 or ei
  local u_ei= index(str, ei ) -1
  return str:sub(u_si,u_ei)
end

-- utf8  split_word(word, num) num default 1
local function split_word(word, num )
  if utf8.len(word) < 2 then
    return word,""
  end
  num= type(num) == "number" and num  or 1
  local index= utf8.offset(word,num+1)
  return word:sub(1,index-1) , word:sub(index)
end
--  line= "word\twegiht"
local function conv_line(line)
    local word,weight= line:match("^(.*)\t%s*([%d]*).*")
    local key,sub_word=split_word(word)
    return key,word,weight
end
local function word_weight(word)
  return tonumber(word:match("^.*-([%d]*).*") )
end

warn("@on")
local function load_essay(filename)
  local fn=io.open(filename)
  if not fn then
    if log then
      log.error( filename .. " not exist in path of user_data or shared_data" )
    else
      warn( filename .. " not exist in path of user_data or shared_data" )
    end
    return
  end

  words={}
  for line in fn:lines() do
    local key,word,weight = conv_line(line)
    words[key] = type(words[key]) == "table" and words[key] or List()
    word= ("%s-%s"):format(word, weight or  0)
    words[key]:push(word)
  end
  fn:close()

  -- sorc dicts by weight
  for k,v in pairs(words) do
    v:sort_self(function(a,b)
      return word_weight(a) > word_weight(b)
    end )
  end

  return words
end

local M={}
function M:New(filename)
  --filename = filename or "essay.txt"
  local words =  load_essay(filename)
  if words then
    return setmetatable(words,self)
  end
end
M.__index=M
setmetatable(M,{__call=M.New})



function M:find_word( word)
    local key,sub_word=split_word(word)
    local dict=self[key] or List()
    local res_tab= dict
    :select(function(elm) return elm:match("^" .. word .. ".+-.*" ) end )
 --   :sort_self(function(a,b) return word_weight(a) > word_weight(b) end )
    :map(function(elm) return elm:match("^" .. word .. "(.*)-.*$") end )
    return res_tab
end

function M:reduce_find_word(word)
    local res_tab= List()
    while 0 < utf8.len(word)  do
      self:find_word(word)
      :reduce(function(elm,dict) return dict:push(elm) end ,res_tab)

      _,word= split_word( word)
    end
    return res_tab
end


function M:empty(word)
  local last_w=word:sub( utf8.offset(word,utf8.len(word) ))
  return self[last_w] == nil or #self[last_w] < 2 or false
end

function M:word_iter(word)
  return coroutine.wrap(function()
    for i,elm in ipairs( self[word:utf8_sub(1,1) ] or {}) do
      local w,wt = elm:match("^" .. word .. "(.+)-(%d*).*$" )
      if w then
        coroutine.yield( w,wt)
      end
    end
  end )
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

return M

--- example

--[[
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
