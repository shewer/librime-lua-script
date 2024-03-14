#! /usr/bin/env lua
--
-- english_dict.lua
-- Copyright (C) 2020 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
--[[

  ex :
  Eng=require('tools/english_dict' )
  e = Eng( 'english')
  for w in e:iter('th/i:ad') do    --  * ? /  :
    print(w.word,w:get_info(1) )
  end

  list = e:match('th/i:ad') --List table
  for i,v in ipairs(list)
    print(w.word,w:get_info(1)
  end

  pw=function(w) print(w.word,w:get_info()) end
  list:each(pw)


--
--
--]]
require 'tools/string'
require 'tools/_file'
local List = List or require 'tools/list'
--local Word= require 'tools/english_word'
local Eng_suffix={
   ['f'] = "*ful",
   ['y'] = "*ly",
   ['t'] = "*tion",
   ['s'] = "*sion",
   ['a'] = "*able",
   ['i'] = "*ing",
   ['m'] = "*ment",
   ['r'] = "*er",
   ['g'] = "*ght",
   ['n'] = "*ness",
   ['l'] = "*less",
}

local function Split_text(str)
   local w,p = str:match("^([-%a].*):(.+)$")
   w = w and w or str
   local prefix = w:match("^[-%a][%a]*")
   local pattern = "^" .. w:gsub("/(%a)", Eng_suffix):gsub("([?*])", ".%1")
   return prefix,pattern, p
end

local function New(self,...)
  local obj= setmetatable({} , self)
  return not obj._initialize and  obj or obj:_initialize(...)
end
--- Word
--
local class= require 'tools/class'


-- Word
-- class method  Phrase_chunk(row_chunk)  Parse_text(row_tab)
-- instance method  get_info(mode_num) to_s() prefix_match(prefix_str) match:(text)

--local Word=Class("Word")
--Word.__name= "Word"
--[[
function Word:__eq(obj)
  return self.word == obj
end
--]]
--
local is_unix = package.config:sub(1,1) == "/"
local NR = is_unix and "\n" or "\r"
local Word = class()--{}
Word.Eng_suffix = Eng_suffix
Word.Split_text = Split_text
Word.__name="Word"
function Word:_initialize(tab)
  if type(tab)=="table" and tab.word and tab.word:len() >0 then
    --and tab.translation and tab.phonetic then
    for k,v in next, tab do
      self[k] = v
    end
    self.phonetic = self.phonetic or ""
    return self
  end
end

-- <word>\t<translation>
function Word.Parse_text(line)
  local tab={}
  local word, translation= table.unpack(line:split("\t"))
  if word:len() < 1 then return end
  tab.word=word
  translation= translation or ""

  local  head,tail=translation:find('^%[.*%];')
  if head and tail then
    tab.phonetic=translation:sub(head,tail-1)
    tab.translation=translation:sub(tail+1)
  else
    tab.phonetic=""
    tab.translation=translation
  end
  return Word(tab)
end
function Word.Parse_chunk(str,replace)
   if type(str) ~=  "string" then return end
   --str = replace and str:gsub("\\n","\\n"):gsub("\\r","\r") or str
   local tab=load("return " .. str )()
   return Word(tab)
end

function Word:to_s()
  local l = List()
  for k,v in next,self do
    l:push( string.format(" %s=%q",k,v) )
  end
  return "{ " .. l:concat(',') .. "}"
end
-- 利用此func 設定comment 輸出格式
--
function Word:get_info(mode)
  mode= tonumber(mode or Word._mode or 1)
  local info= self
  if not info then return  "" end
  mode= (mode) % 7

  if mode == 1 then
     return info.phonetic .. " " .. info.translation
  elseif mode == 2  then
     return (info.translation)
  elseif mode == 3 then
     return (info.phonetic)
  elseif mode == 4 then
     return (info.definition)
  elseif mode == 5 then
     return (info.word)
  elseif mode== 6 then
    return ""
  else
    return info.phonetic .. " " .. info.translation
  end
end

function Word:to_cand(s,e,q, mode)   
   local cand = Candidate("english",s,e,self.word, self:get_info(mode))
   if q then
      cand.quality = q
   end
   return cand
end

function Word:prefix_match(prefix, case_match )
  if case_match then
    return self.word:find( prefix) == 1
  else
    return self.word:lower():find( prefix:lower()) == 1
  end
  return false
end

function Word:chk_parts(parts)
  return (self.translation:match(parts) and true)  or false
end
-- handle args  (word, text, case_match) 
function Word:match(text,handle, case_match)
   if type(handle) == "function" then
      return handle(self, text, case_match)
   end
   

   local pw,ww,pn = self.Split_text(text)

   --Log(DEBUG,'word match :', pw,ww,pn,self.word, self.word:match(ww) and true or false ,self:prefix_match(pw))
   local w_match = case_match and self.word:match(ww) or self.word:lower():match(ww)
   pn = pn and #pn>0 and ("%%s%s%%.%%s"):format(pn)  or ""
   local p_match = self.translation:match(pn) 
   return w_match and p_match and true or false
end
Word.is_match= Word.match

return Word
