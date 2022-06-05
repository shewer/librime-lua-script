#! /usr/bin/env lua
--
-- english_dict.lua
-- Copyright (C) 2020 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--

-- environment setting
-- rime log  redefine
local puts= require'tools/debugtool'

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
require 'tools/string'
local List=require 'tools/list'
-- 設定 存入bin格式
--local chunk_bin= true
local NR = package.config:sub(1,1):match("/") and "\n" or "\r"



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
  return wild_word:match("^[%a][%a%.%-_]*"),wild_word
end
-- 轉換 reg pattern  隔離字元  - .  %- %.    萬用字元 ? * .? .*
local function conver_rex(str)
  return   str:gsub("([%-%.])","%%%1"):gsub("([?*])",".%1")
end
-- 切割 字串   轉換字串   再組合  return  字頭  全字  詞類
local function split_str(str)
  str= type(str)== "string" and  str  or ""
  local w,p=table.unpack(str:split(":"))
  local pw= w:match("^[%a][%a%.%-_]*")
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
    and   "%s" .. conver_rex(p:lower() ) .. "[%a%-%.]*%."
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

local function New(self,...)
  local obj= setmetatable({} , self)
  return not obj._initialize and  obj or obj:_initialize(...)
end
local MT={}
MT.__index=MT
MT.__call=New

local Word= setmetatable({} , MT)
Word.__index=Word
Word.__name="Word"

--local Word=Class("Word")
--Word.__name= "Word"
function Word:__eq(obj)
  return self.word == obj
end

function Word:_initialize(tab)
  if not (
    type(tab)== "table"
    and type(tab.word) == "string"
    and 0 < tab.word:len()  ) then
    return
  end

  for i,v in next ,{"word","translation","phonetic"} do
    self[v]= (type(tab[v]) == "string" and tab[v] ) or ""
  end
  return self
end


function Word:chk_parts(parts)
  return (self.translation:match(parts) and true)  or false
end
function Word:Parse(line)
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
  return self(tab)
end


-- 利用此func 設定comment 輸出格式
--
function Word:get_info(mode)
  mode= tonumber(mode)
  local info= self
  if not info then return  "" end
  mode= mode and mode % 7 or 0

  if mode == 1 then
    return (info.phonetic .. info.translation):gsub("\\n",NR)
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
    return (info.phonetic .. info.translation):gsub("\\n"," ")
  end

end
function Word:match(pw,pn)
  pn = pn or ""
  if self.word:lower():match(pw) then
    return pn == ""  and true
    -- 暫時  ecdict 欄位名不同
    or self.translation:match( pn) and  true or false
  end
  return false
end
Word.is_match= Word.match
--Class(Word)



local function file_exists(filename)
  local fn = io.open(filename)
  if fn then fn:close() end
  return fn and true or false
end
local function get_path(filename)
  local path= string.gsub(debug.getinfo(1).source,"^@(.+/)[^/]+$", "%1")
  return  path ..  (filename or "english.txt" )
end

-- 將英文字典資料存成chunk 加速載入
local function save_table(filename,obj)

  local function serialize(fn,o)
    if type(o) == "number" then
      fn:write(o)
    elseif type(o) == "string" then
      fn:write(string.format("%q", o))
    elseif type(o) == "table" then
      fn:write("{\n")

      for k,v in pairs(o) do
        local tp= type(k)
        if tp == "number" then
          fn:write( "  [" , k , "] = ")
        else
          fn:write(" [ [[",k, "]] ] = ")
        end
        serialize(fn,v)
        fn:write(",\n")
      end
      fn:write("}\n")
    else
      error("cannot serialize a " .. type(o))
    end
  end
  local fn,res = io.open(filename,"w")
  if not fn then
    puts(ERROR, "save_table: openfile error" ,res)
    return
  end
  fn:write("local index = ")
  serialize(fn, obj.index)
  fn:write("local tree = ")
  serialize(fn, obj.tree)
  fn:write("local info= {}\n for i,v in next, index do info[v.word] = v end\n")
  fn:write("return {index = index , tree = tree, info =info} \n")
  fn:close()
  -- chunk_txt 可設定  lua txt code
  if not chunk_txt then
    local f = loadfile(filename)
    fn = io.open(filename,'w')
    fn:write( string.dump(f) )
    fn:close()
  end
end
-- when  commit  clean
--
local function dict_tree_insert_index(self,word,level)
  level = level or 3
  local len= word.word:len()
  local w_lower= word.word:lower()
  len =  level > len and len  or level
  for i=1,len do
    local key= w_lower:sub(1,i)
    if not self[key] then
      self[key]=word.index
    else
    end
  end
end

local function init_dict_from_txt(filename,level)
  puts(INFO, "init_dict from txt",filename)
  if not file_exists(filename) then
    puts(ERROR, "dict file not faund",filename)
    return
  end
  level= level or 3

  local dictfile,res =  io.open(filename)
  if not dictfile then
    puts(ERROR, "dict file open failed",filename,res)
    return
  end

  local dict= {
    index = List(),
    info = {},
    tree = {},
  }
  --dict_tree.insert_index= dict_tree_insert_index

  for line in dictfile:lines() do
    if not line:match("^#") then  -- 第一字 #  不納入字典
      local w = Word:Parse(line)
      if w then
        dict.index:push(w)
        w.index= #dict.index
        dict.info[w.word] = w
        dict_tree_insert_index(dict.tree,w,level)
      end
    end
  end
  dictfile:close()
  -- mack dict of chunk
  --save_table( get_path(filename .. ".txtl"), dict)
  return dict -- dict.index ,dict.info, dict.tree
end
local function init_dict_from_csv(filename,level)
  local CSV = require 'tools/csvtotab'
  print("init_from_csv level", level)
  local tab= List( CSV.Load_csv(filename,true) )
  print("after init_from_csv level", level)
  local dict= {
    index = tab,
    info = {},
    tree = {},
  }
  for i=1,#dict.index do
    if i % 10000 == 0 then print("process: ",i) end
    local w = setmetatable( dict.index[i],Word)
    w.index= i
    w.phonetic = #w.phonetic > 1 and "[" .. w.phonetic .. "]" or w.phonetic
    dict.info[w.word] = w
    dict_tree_insert_index(dict.tree,w,level)
  end
  return dict
end
local function init_dict_from_chunk(filename)
  puts(INFO, "init_dict from chunk",filename)
  local ok,res = pcall(dofile, filename)
  if ok then
    local dict = res
    setmetatable(dict.index,List)
    dict.info= {}
    for i,v in next, dict.index do
      setmetatable(v,Word)
      dict.info[v.word]= v
    end
    return dict -- dict.index ,dict.info, dict.tree
  else
    puts(ERROR, 'load dict chunk faild' ,  filename, res)
  end
end
local function init_dict(dict_name,level,force)
  -- force (true) init_dict form txt
    local cfilen = get_path( dict_name .. ".txtl" )
    local cf_exists = file_exists(cfilen)

  if not force and cf_exists then
    local dict = init_dict_from_chunk(cfilen)
    if dict then return dict end
    puts(WARN,'---init_dict_frome_chunk faild',dict_name,cfilen,res)
    -- init from_chunk faild  and recall  from txt
    return init_dict(dict_name,level,true)
  else
    local filen = get_path( dict_name .. ".txt")
    if file_exists(filen) then
      local dict  = init_dict_from_txt( filen )
      if dict then
        if not cf_exists then save_table(cfilen,dict) end
        return dict
      end
    else
      -- add csv
      filen = get_path( dict_name .. ".csv")
      if file_exists(filen) then

        local dict  = init_dict_from_csv( filen,level )
        if dict then
          if not cf_exists then save_table(cfilen,dict) end
          return dict
        end
      end
    end
    puts(ERROR, 'dict file not found', dict_name,filen,res) end
end

--local English =Class("English")
local English =setmetatable({},MT)
English.__index=English
English.__name="English"
English._dictdb={}
function English:_getdb()
  return self._dictdb[self._filename]
end

function English:_initialize(filename,level)
  self._filename= filename or "english_tw"
  self._level= level or 3
  self._mode=0
  --local dictdb = self:_getdb()
  if not self:_getdb() then
    self:reload()
  end
  local dictdb = assert( self:_getdb() )

  self._dict_index=dictdb.index
  self._dict_info=dictdb.info
  self._dict_tree=dictdb.tree
  return self
end
function English:make_chunk()
  if self._filename then
    -- object
    local filen= get_path( self._filename .. ".txtl")
    save_table( filen , self:_getdb())
  else
    -- class
    for k,v in next, self._dictdb do
      local filen= get_path( k .. ".txtl")
      save_table( filen , v)
    end
  end
end
function English:reload(force)
  self._dictdb[self._filename] =  init_dict(self._filename,self._level,force)
end
function English:next_mode()
  return self:mode(   self:mode() + 1 )
end
function English:mode(mode)
  if  ( mode and tonumber( mode ) ) then
    mode= mode % 5
    if mode >= 0 and  mode <= 4 then self._mode= mode  end
  end
  return self._mode
end

function English:get_info(word)
  return self._dict_info[word]
end

function English:_chk_part(word,ph)
  local info=self._dict_info[word]
  return ( info and info:chk_parts(ph) )
end

function English:pre_suffix(key)
  return self._dict_tree[ key:lower() ]
end

function English:find_index(org_text)
  local key= ( org_text:match("^([%a%.%_%-]+).*") or "")
  :lower()
  :sub(1, self._level )
  local index =self._dict_tree[ key:lower() ]
  if not index then return end

  --local pw,ww,p=conv_pattern1(org_text,self._level)
  local pw=conv_pattern(org_text)
  --finde first index
  index = index > 1 and index-1  or nil
  for i,w in next , self._dict_index , index do
    if w:match(pw) then
      return i
    end
  end
  return nil
end
function English:iter(org_text,mode)
  --local pw,ww,p=conv_pattern1(org_text,self._level)
  local pw,ww,p=conv_pattern(org_text)
  local index= self:find_index( org_text)
  if not index then
    return function() end
  end

  -- index -1
  index= index > 1 and index - 1 or  nil
  return coroutine.wrap(
  function()
    for i,node in next, self._dict_index , index do
      if not node:is_match(pw) then  break end
      if node:is_match(ww,p) then
        coroutine.yield( node)
      end
    end
  end )
end

function English:match(word)   --  return list
  local tab_result=List()
  for elm  in  self:iter(word) do
    tab_result:push(elm)
  end
  return tab_result
end
function English:get_word(word_str)
  return self._dict_info[word_str]
end
--  English.Wildfmt("e/a:a")
--  --> e.*able  e*able  a ()
--
function English.Wildfmt(word)
  local _,ww , p =split_str(word)
  local pattern=conver_rex(ww)
  return pattern,ww ,p
end

English.Conver_rex=conver_rex
English.Split=split_str
English.Conver_pattern= conv_pattern
English.Word=Word

return English

--return init

