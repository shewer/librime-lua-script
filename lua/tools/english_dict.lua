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
  local pw= w:match("^[-.%a][%a%.%-_]*")
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

--- Word
--
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
-- <word>\t<translation>
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

function Word:match(text)
  local pw,ww,pn = conv_pattern(text)
  return self.word:lower():match(ww) and self.translation:match(pn)
end
Word.is_match= Word.match



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
  fn:write("return ")
  serialize(fn, obj)
  --[[
  fn:write("local tree = ")
  serialize(fn, obj.tree)
  fn:write("local info= {}\n for i,v in next, index do info[v.word] = v end\n")
  fn:write("return {index = index , tree = tree, info =info} \n")
  --]]
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

local function init_dict_from_txt(filename)
  local dictfile,res =  io.open(filename)
  if not dictfile then
    puts(ERROR, "dict file open failed",filename,res)
    return
  end
  local tab={}
  --dict_tree.insert_index= dict_tree_insert_index
  for line in dictfile:lines() do
    if not line:match("^#") then  -- 第一字 #  不納入字典
      table.insert(tab, Word:Parse(line))
    end
  end
  dictfile:close()
  return tab
end
local function init_dict_from_csv(filename)
  local CSV = require 'tools/csvtotab'
  local ok,res = pcall(CSV.Load_csv,filename,true)
  if ok then
    for i,w in ipairs(res) do
      w.phonetic = #w.phonetic > 0 and "[".. w.phonetic ..  "]" or ""
    end
    return res
  else
    puts(ERROR, 'load dict chunk faild' ,  filename, res)
  end
end

local function init_dict_from_chunk(filename)
  puts(INFO, "init_dict from chunk",filename)
  local ok,res = pcall(dofile, filename)
  if ok then
    return res -- dict.index ,dict.info, dict.tree
  else
    puts(ERROR, 'load dict chunk faild' ,  filename, res)
  end
end
-- 建立字頭索引使用 hash map 找字頭開始index
local function init_dictdb( dict, level)
  local obj = {}
  obj.index = dict.index and dict.index or dict
  obj.tree  = dict.tree  and dict.tree  or {}
  obj.info  = dict.info  and dict.info  or {}
  for i,w in ipairs( obj.index) do
    w.index = i
    setmetatable(w,Word)
    obj.info[w.word] = w
    dict_tree_insert_index(obj.tree, w, level)
  end
  return obj
end

local function init_dict(dict_name,level,force)
  -- force (true) init_dict form txt
   local dict
   local filen = get_path(dict_name .. ".txtl")
   dict= not force and file_exists(filen) and init_dict_from_chunk(filen)
   filen = get_path( dict_name .. ".txt" )
   dict = not dict and file_exists(filen) and init_dict_from_txt( filen) or dict
   filen = get_path( dict_name .. ".csv" )
   dict = not dict and file_exists(filen) and init_dict_from_csv( filen) or dict

   if not dict then
      puts(ERROR, 'dict file not found', dict_name,filen,res)
      return nil
   end
   return init_dictdb(dict,level)
end

--local English =Class("English")
local English =setmetatable({},MT)
English.__index=English
English.__name="English"
English._dictdb={}
function English:_getdb()
  return self._dictdb[self._filename]
end

function English:_initialize(filename,force,level,max_level)
  self._filename= filename or "english_tw"
  self._level= level or 3
  self._maxlevel = max_level or 10
  self._mode=0
  --local dictdb = self:_getdb()
  if not self:_getdb() then
    self:reload(force)
    if not file_exists( get_path(filename .. ".txtl" ) ) then
      self:make_chunk()
    end
  end
  return self
end
function English:make_chunk(mode)
  -- only save wordes table
  mode = true

  if self._filename then
    -- object
    local filen= get_path( self._filename .. ".txtl")
    save_table( filen , mode and self:_getdb().index or self:_getdb())
  else
    -- class
    for k,v in next, self._dictdb do
      local filen= get_path( k .. ".txtl")
      save_table( filen , mode and v.index or v)
    end
  end
end
function English:reload(force)
  self._dictdb[self._filename] =  init_dict(self._filename,self._level,force)
end


function English:_find_index(pw,len)
  local db = self:_getdb()

  len = len and len < self._maxlevel and len or self._maxlevel
  len = #pw < len and #pw or len

  if len <1 then return end
  local ppw = pw:lower():sub(1, len )
  local pindex=db.tree[ppw]
  if not pindex then
    return self:_find_index(pw ,len -1)
  else
    -- find index form start of pw
    local i,w= pindex, db.index[pindex]
    repeat
      if w:match(pw) then
        if #pw >self._level then
          local l= w.index - db.tree[ppw]
          db.tree[pw] =  l > 20 and w.index or nil
        end
        return w.index
      end
      i,w = next(db.index,i)
    until not i or not w:match(ppw)
    --[[
    pindex = pindex > 1 and pindex -1 or nil
    for i,w in next, db.index, pindex do
      if not w:match("^"..ppw) then return end
      if w:match("^" .. pw) then
        db.tree[pw] = db.tree[pw] and db.tree[pw] or w.index
        return w.index
      end
    end
    --]]
  end
end
function English:iter(org_text,mode)
  local pw = split_str(org_text)
  local index= self:_find_index( pw )
  local db = self:_getdb()

  return coroutine.wrap(
  function ()
    -- start from index
    local i,w = index, db.index[index]
    if not i then return end
    repeat
      if w:match(org_text) then
        coroutine.yield( w)
      end
      i,w = next(db.index, i)
      -- stop for pw out of scope
    until not ( i and w:match(pw) )
  end)
end

function English:match(word)   --  return list
  local tab_result=List()
  for elm  in  self:iter(word) do
    tab_result:push(elm)
  end
  return tab_result
end
function English:get_word(word_str)
  return self:_getinfo().info[word_str]
end
--  English.Wildfmt("e/a:a")
--  --> e.*able  e*able  a ()
--
--
--






-- for debug and check
--[[ debug function

function English.Wildfmt(word)
  local _,ww , p =split_str(word)
  local pattern=conver_rex(ww)
  return pattern,ww ,p
end

English.Split=split_str  --1 ('seteu/i/a:m') 字首seteu 單字 seteu*ing*able 詞類 m
English.Conver_rex=conver_rex --2 ('seteu*?ing:m') 展開/ :  seteu.*.?ing:ment 2
English.Conver_pattern= conv_pattern --3 ('seteu/i/a:m') 字首 ^seteu  ^seteu.*ing.*able%sm[%a%-%.]*%.
English.Word=Word


English.save_table= save_table
English.init_dict= init_dict
--]]


return English

--return init

