List=require 'tools/list'
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
function conv_line(line)
    local word,weight= line:match("^(.*)\t%s*([%d]*).*")
    local key,sub_word=split_word(word) 
    return key,word,weight 
end 

local function load_essay(filename)
  local fn=io.open(filename) 
  if not fn then return end

  words={}
  for line in fn:lines() do 
    local key,word,weight = conv_line(line)
    words[key] = type(words[key]) == "table" and words[key] or List()
    word= ("%s-%s"):format(word, weight or  0)
    words[key]:push(word)
  end
  fn:close() 
  return words
end 

local M={}
function M:New(filename)
  --filename = filename or "essay.txt"
  words =  load_essay(filename)
    or load_essay( rime_api.get_user_data_dir() .. package.config:sub(1,1) .. filename)
    or load_essay( rime_api.get_shared_data_dir() .. package.config:sub(1,1) .. filename)

  if not words then 
    log.error( filename .. "not exist in path of user_data or shared_data" )
    return 
  end 
  return setmetatable(words,self)
end 
M.__index=M
setmetatable(M,{__call=M.New})

local function word_weight(word)
  return tonumber(word:match("^.*-([%d]*).*") )
end 


function M:find_word( word)
    local key,sub_word=split_word(word)
    local dict=self[key] or List()
    local res_tab= dict
    :select(function(elm) return elm:match("^" .. word .. ".+-.*" ) end )
    :sort_self(function(a,b) return word_weight(a) > word_weight(b) end )
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



return M

--- example

--[[
words= load_essay("essay.txt")
find_word(words,"一天")
--]]
