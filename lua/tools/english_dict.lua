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
local List = List or require 'tools/list'
local Log= require'tools/debugtool'

--USERDIR= ( USERDIR or  os.getenv("APPDATA") or "" ) .. [[\Rime]]

-- 字典 字根 查碼 table
--
--local eng_suffixe1={ ["Control+f"] ="*ful" , ["Control+y"]= "*ly" , ["Control+n"]= "*tion" , ["Control+a"] = "*able" ,
--["Control+i"] = "*ing" , ["Control+m"]= "*ment"	, ["Control+r"]= "*er", }
--env.keyname2={ f ="*ful" , y= "*ly" , n= "*tion" , a = "*able" ,
--i = "ing" , m= "*ment"	, r= "*er",
--}
--   f="ful"  --> /f or   Control+f
--require 'tools/object'
-- 設定 存入bin格式
--local chunk_bin= true
local NR = package.config:sub(1,1):match("/") and "\n" or "\r"

local function exists(name)
    if type(name)~="string" then return false end
    return os.rename(name,name) and true or false
end

local function isFile(name)
    if not exists(name) then return false end
    local f = io.open(name)
    if f and f:read(1) then
        f:close()
        return true
    end
    return false
end

local function isDir(name)
    return (exists(name) and not isFile(name))
end


local eng_suffix={ f ="ful" , y= "ly" , t= "tion" ,s="sion", a = "able" ,
i = "ing" , m= "ment"	, r= "er", g="ght" , n="ness", l="less" ,  }
local eng_suffix_list={ }

-- 詞類
local eng_parts={ "a", "abbr", "ad", "art", "aux", "phr", "pl", "pp", "prep", "pron", "conj", "int", "v", "vi", "vt"   }
setmetatable(eng_parts,{__index=table } )

-- 可接收輸入字串   %a[%a%-%.%:_[]%?%*]*  萬用字   ? 0-1   *0-N  萬用字 符合字元[%a%-%.:_]   [] 限制字元範圍
--  /  快捷字串   : 詞類
--  字頭[/快捷1[/快捷2][:詞類]
--
--  分割詞類  字頭[/快捷1[/快捷2]     [:詞類] --> 字頭[/快捷1[/快捷2]     詞類
--  分割快捷碼  字頭    [/快捷1   [/快捷2]  -->  字頭    快捷   快捷
--  截取 字頭字串 %a[%a%-%.%:_]*
--  如果字字串  1 字元 查全表
--  如果字頭字串 大於2  查表至 不符合時  中斷查詢  因爲 字典是按照 字元排序
--
--  如果input 長度 1  送出全表 不用查
--
--
--
--  詞類  快捷  字串 查表 轉換   *ing *tion ...   查不到的  字串加上 *       v* a* adv ad* ...
--
--
--
-- input: string   [%a][%a/: %*%.%?_%-]
-- ?*  ->   "([%?%*])","([%a%.%-_]%%%1" --? *    [$a%.%-_]?   [%a%.%-]*
--
-- 1 gen per_suffix input      input:match("^%a[%a%-%.-]+")    %a[%a-._]+
-- 2 pre_suffix input  conver rex with escap   gsub("([%.%-_])","%%%1")
--
--
-- 3  pattern , wild_word
--   1   split(":")    英文單字：詞類
--
--   2   split("/")    字根 萬用字 快捷碼分割
--       "ab*/i/n"    ab*  i   n
--
--
--
--  "i"  -> *ing  n -> tion   not match:  g -> *g

-- 取得 字頭 英文字串    a-z  A-Z . - _
local function pre_suffix_word(wild_word)
  return wild_word:match("^[-.%a][%a%.%-_]*"),wild_word
end
-- 轉換 reg pattern  隔離字元  - .  %- %.    萬用字元 ? * .? .*
local function conver_rex(str)
  return   str:gsub("([%-%.])","%%%1"):gsub("([?*])",".%1")
end
-- 切割 字串   轉換字串   再組合  return  字頭  全字  詞類
local function split_str(str)
  str= type(str)== "string" and  str  or ""
  local w,p=table.unpack(str:split(":"))
  local pw= w:match("^[-.%a][%a%.%-_ ]*")
  local ws= List( w:split("/") )
  local ww= ws:shift()
  ww=  ww .. ws:map(function(elm)
    return "*" .. (eng_suffix[elm] or elm)
  end):concat()
  return  pw , ww , p or ""
end
-- 轉換 reg 字串  字頭 全字 詞類
local function conv_pattern(org_text)
  local pw,ww,p = split_str(org_text)
  pw= "^" .. conver_rex(pw:lower() or "")
  ww="^"  .. conver_rex(ww:lower())
  p= p:len() >0
    --and   "%s" .. conver_rex(p:lower() ) .. "[%l%-%.]*%."
    and   conver_rex(p:lower() ) .. "[%l%-%.]*%."
    or "" --  [ ] p [%a]*%."
  return pw, ww, p
end
local function conv_pattern1(org_text,level)
  level = level or 3
  local pw,ww,p = split_str(org_text)
  pw=pw:lower():sub(1,level)
  ww=ww:lower()
  p=p:lower()
  pw= "^" .. conver_rex(pw)
  ww="^"  .. conver_rex(ww)
  p= p:len() >0 and   "%s" .. conver_rex(p) .. "[%a-%.]*%." or "" --  [ ] p [%a]*%."
  return pw, ww, p
end

--- Word
--
local function New(self,...)
  local obj= setmetatable({} , self)
  return not obj._initialize and  obj or obj:_initialize(...)
end
local MT={}
MT.__index=MT
MT.__call=New

-- Word
-- class method  Phrase_chunk(row_chunk)  Parse_text(row_tab)
-- instance method  get_info(mode_num) to_s() prefix_match(prefix_str) match:(text)
local Word= setmetatable({} , MT)
Word.__index=Word
Word.__name="Word"

--local Word=Class("Word")
--Word.__name= "Word"
--[[
function Word:__eq(obj)
  return self.word == obj
end
--]]
--

function Word:_initialize(tab)
  if type(tab)=="table" and tab.word and tab.word:len() >0 then
    --and tab.translation and tab.phonetic then
    for k,v in next, tab do
      self[k] = v
    end
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
    tab.translation=translation
  end
  return Word(tab)
end
function Word.Parse_chunk(str,replace)
  if type(str) == "string" then
    str = replace and str:gsub("\\n","\\n"):gsub("\\r","\r") or str
    local tab=load("return " .. str )()
    return Word(tab)
  end
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
  mode= tonumber(mode)
  local info= self
  if not info then return  "" end
  mode= mode and mode % 7 or 0

  if mode == 1 then
    return (info.phonetic .. " " .. info.translation):gsub("\\n",NR)
  elseif mode == 2  then
    return info.translation:gsub("\\n", " ")
  elseif mode == 3 then
    return info.translation:gsub("\\n", NR)
  elseif mode == 4 then
    return info.phonetic
  elseif mode == 5 then
    return info.word
  elseif mode== 6 then
    return ""
  else

    return (info.phonetic .. " " .. info.translation):gsub("\\n"," ")
  end
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

function Word:match(text,case_match)
  local pw,ww,pn = conv_pattern(text)
  --Log(DEBUG,'word match :', pw,ww,pn,self.word, self.word:match(ww) and true or false ,self:prefix_match(pw))
  local w_match = case_match and self.word:match(ww) or self.word:lower():match(ww)
  local p_match = #pn<1 and true or self.translation:match(pn)
  return w_match and p_match and true or false
end
Word.is_match= Word.match


-- Dict  instance method
-- iter(text) return iter function for match text pattern
-- get(word) return
-- LuaDict

local function init_tree(tree_tab, index, word,level)
  local prefix=word:sub(1,level):lower()
  for i= #prefix, 1,-1 do
    local  w = prefix:sub(1,i)
    if tree_tab[w] then break end
    tree_tab[w] = index
    init_tree(tree_tab, index, word, level -1)
  end
end

local LuaDict=setmetatable({},MT)
LuaDict.__index = LuaDict
LuaDict.__name = 'LuaDict'
function LuaDict:_initialize(full_path,level)
  level = level and level>1 and level  or 3
  self._db = loadfile(full_path)()
  self._tree = {}
  self._words = {}
  for i,v in next,self._db do
    local w = Word(v)
    self._db[i] = w
    self._words[v.word] = i
    init_tree(self._tree,i,w.word,level)
  end
  return self
end
function LuaDict:_prefix_index(pw)
  --local pw,ww,pn = conv_pattern(text)
  local index = 1
  if #pw <1 then return index end

  -- 找最近的index
  for i= #pw,1,-1 do
    local tree_index= self._tree[ pw:sub(1,i) ]
    if tree_index  then
      index = tree_index
      break
    end
  end
  -- 找 prefix word index
  local count = 0
  repeat
    local ww = self._db[index]
    if self._db[index]:prefix_match(pw) then
      -- 找到索引 如果count > 200  增加 pw 索引
      if count > 200 then
        self._tree[pw] = index
      end
      break
    end
    count = count +1
    index = index+1
  until index > #self._db
  return index
end

function LuaDict:iter(text)
  local pw,ww,pn = split_str(text)
  local index = self:_prefix_index(pw)
  return coroutine.wrap(function()
    while self._db[index]:prefix_match(pw) do
      if self._db[index]:match(text) then
        coroutine.yield(self._db[index])
      end
      index = index +1
    end
  end)
end

function LuaDict:get(word)
  local index = self._words[word]
  return self._db[index]
end

-- Dict  instance method
-- iter(text) return iter function for match text pattern
-- get(word) return
-- LevelDict
--
local  LevelDict=setmetatable({},MT)
LevelDict.__index = LevelDict
LevelDict.__name = 'LewelDict'


function LevelDict:_initialize(full_path)
  self._db = rime_api.leveldb_open(full_path)
  return self._db and self
end

function LevelDict:iter(text, case_match)
  --local pw,ww,pn = conv_pattern(text)
  local pw,ww,pn = split_str(text)
  local dbacc = self._db:query(pw:lower())
  return  coroutine.wrap(function()
    for k,v in dbacc:iter() do
      local w = Word.Parse_chunk(v)
      if w and w:match(text,case_match) then
        coroutine.yield(w)
      end
    end
  end)
end

function LevelDict:get(word)
  --  have upcae word  ex   Abort   abort\tAbort
  word = word:match("%u") and string.format("%s\t%s",word:lower(),word) or word
  local chk_str = self._db:fetch(word)
  return chk_str and Word.Parse_chunk(chk_str)
end

-- English(dict_name)
-- instance method
-- iter(text)  return Word  for w in e:iter(text) do  ... end
-- match(text) return Word of List
-- word(word)  return Word
--
local English =setmetatable({},MT)
English.__index=English
English.__name="English"
English._dicts={}
function English:_getdict()
  return English._dicts[self._dict_name]
end
--[[
function English:_setdict()
  English._dicts[self._dict_name] = self._dict
end
--]]
function English:_initialize(dict_name,reload)
  dict_name= dict_name or "english_tw"
  self._dict_name = dict_name
  --local dictdb = self:_getdb()
  if reload or not self:_getdict()  then
    self:reload()
  end

  return self:_getdict() and self or nil
end
function English:_find_file(ftype)
  local fmt = ftype == "dir" and "%s%s" or "%s%s.txtl"
  local func = ftype == "dir" and isDir or isFile
  local slash = package.config:sub(1,1)
  -- userdata
  local path = rime_api.get_user_data_dir() .. slash
  path = (fmt):format( path, self._dict_name)
  --Log(DEBUG,'--user---_find_file : ---', ftype, fmt,path,"--res --",func(pathh) )
  if func(path) then return path end 
  -- shared
  local path = rime_api.get_shared_data_dir() .. slash
  path = (fmt):format( path, self._dict_name)
  --Log(DEBUG,'--shared---_find_file : ---', ftype, fmt,path,"--res --",func(pathh) )
  if func(path) then return path end 
end

function English:reload(force)
    local dict_name = self._dict_name
    local ph= rime_api.get_user_data_dir()
    local dp = self:_find_file("dir")
    local fp = self:_find_file("file")
    if LevelDb and self:_find_file("dir")  then
      self._dicts[dict_name]=  LevelDict(self:_find_file("dir"))
    elseif self:_find_file("file") then
      self._dicts[dict_name] = LuaDict(self:_find_file("file"))
    end
    for k,v in next,self._dicts do 
    end
    
    return self:_getdict() and true or false
end

function English:iter(org_text,case_match)
  return self:_getdict():iter(org_text,case_match)
end

function English:match(org_text)
  local tab=List()
  for w in self:iter(org_text) do
    tab:push(w)
  end
  return tab
end

function English:word(word)
  return self:_getdict():get(word)
end


-- for debug and check
--[[ debug function
English.Split=split_str  --1 ('seteu/i/a:m') 字首seteu 單字 seteu*ing*able 詞類 m
English.Conver_rex=conver_rex --2 ('seteu*?ing:m') 展開/ :  seteu.*.?ing:ment 2
English.Conver_pattern= conv_pattern --3 ('seteu/i/a:m') 字首 ^seteu  ^seteu.*ing.*able%sm[%a%-%.]*%.
English.Word=Word
--]]
English.isFile=isFile
English.isDir=isDir
English.LevelDict = LevelDict
English.luaDict = luaDict

return English


