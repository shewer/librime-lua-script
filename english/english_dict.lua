#! /usr/bin/env lua
--
-- english_dict.lua
-- Copyright (C) 2020 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--

-- environment setting
-- rime log  redefine 
if not log then 
	log={}
	log.info= function(str) print(str) end 

end 

print( "---filename :" , string.gsub(debug.getinfo(1).source, "^@(.+/)[^/]+$", "%1english.txt") )
--USERDIR= ( USERDIR or  os.getenv("APPDATA") or "" ) .. [[\Rime]]

-- 字典 字根 查碼 table
--  
--local eng_suffixe1={ ["Control+f"] ="*ful" , ["Control+y"]= "*ly" , ["Control+n"]= "*tion" , ["Control+a"] = "*able" ,
--["Control+i"] = "*ing" , ["Control+m"]= "*ment"	, ["Control+r"]= "*er", }
--env.keyname2={ f ="*ful" , y= "*ly" , n= "*tion" , a = "*able" ,
--i = "ing" , m= "*ment"	, r= "*er", 
--}
--   f="ful"  --> /f or   Control+f  
require 'tools/object'





local eng_suffix={ f ="ful" , y= "ly" , n= "tion" , a = "able" ,
i = "ing" , m= "ment"	, r= "er", g="ght" ,  l="less" ,  }
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
local function wtab(str)
	if type(str)== "string" then 
		return  "*"  .. ( eng_suffix[str] or str ) 
	end 
	return ""
end
--  panding  bypass str
local function ptab(str)
	if type(str)== "string" then 
		return  "*"  .. (  eng_parts[str] or str ) 
	end 
	return ""
end
-- 取得 字頭 英文字串    a-z  A-Z . - _ 
local function pre_suffix_word(wild_word)
	return wild_word:match("^[%a][%a%.%-_]*"),wild_word 
end
-- 轉換 reg pattern  隔離字元  - .  %- %.    萬用字元 ? * .? .*
local function conver_reg(str) 
	return   str:gsub("([%-%.])","%%%1"):gsub("([?*])",".%1")
end
-- 切割 字串   轉換字串   再組合  return  字頭  全字  詞類
local function split_str(str)
	str= type(str)== "string" and  str  or ""
	local w,p=str:split(":"):unpack()
    local w1,w2,w3= w:split("/"):unpack()
	
	local pw = pre_suffix_word(w1)
	return  pw ,  w1 .. wtab(w2) .. wtab(w3) , ptab(p)
end 
-- 轉換 reg 字串  字頭 全字 詞類
local function conv_pattern(org_text)
	local pw,ww,p = split_str(org_text) 
	print( pw , ww, p) 
	pw= pw:lower()
	ww= ww:lower()
	p= p:lower()
	pw= "^" .. conver_reg(pw)
	ww="^"  .. conver_reg(ww)
	p= p:len() >0 and   "%s" .. conver_reg(p) .. "[%a-%.]*%." or "" --  [ ] p [%a]*%."
	return pw, ww, p
end 
local function conv_pattern1(org_text,level)
	level = level or 3
	local pw,ww,p = split_str(org_text) 
	pw=pw:lower():sub(1,level)
	ww=ww:lower()
	p=p:lower()
	pw= "^" .. conver_reg(pw)
	ww="^"  .. conver_reg(ww)
	p= p:len() >0 and   "%s" .. conver_reg(p) .. "[%a-%.]*%." or "" --  [ ] p [%a]*%."
	return pw, ww, p
end 


local Word=Class("Word")

 

function Word:chk_parts(parts)
	return (self.info:match(parts) and true)  or false
end 
function Word.Parse(line)
	local tab={}
	local word, info_str = line:split("\t"):unpack()
	local  head,tail=  info_str:find('^%[[^%s]*];') 
	if head and tail then 
		tab.phonics= info_str:sub(head,tail-1)
		tab.info= info_str:sub(tail+1)
	else 
		tab.info= info_str
	end 
	tab.word=word
	return Word:New(tab) 
end 
function Word:_initialize(tab) 
	for i,v in next ,{"word","info","phonics"} do 
		self[v]= (type(tab[v]) == "string" and tab[v] ) or ""
	end 
	return self
end 
function Word:get_info(mode)
	mode= tonumber(mode)
	local info= self 
	if not info then return  "" end 

	mode= mode or 1 
	if mode == 1 then 
	    return info.info
	elseif mode == 2  then 
		return info.phonics 
	elseif mode == 3 then 
		return info.word
	elseif mode==4 then 
		return "" 
	else 
		return info.phonics .. info.info 
	end 

end 
function Word:is_match(pw) 
	return self.word:lower():match(pw) 
end 









-- when  commit  clean 
local function openfile(filename)

	-- 取得目前路逕
	local path= string.gsub(debug.getinfo(1).source,"^@(.+/)[^/]+$", "%1")
	filename =  path ..  (filename or "english.txt" )
	log.info(path,filename)
	local dict_file =  io.open(filename)
	if dict_file  then 
		log.info("english module : open file:" .. filename ) 
	else
		log.error("english module : open file failed :" .. filename ) 
	end 
	return dict_file
end
--- 取消  match()     inline to  dict_match() 
--local function insert_tree(tree,node,level)
	--local w=node.word:lower()
	--local w_len=w:len() 
	--level_ =  w_len < level and w_len or level
	--for i=1,level do
		--local key= w:sub(1,i)
		--if tree[key] then 
			--if tree[key] > node.index then 
				--tree[key] = node.index
			--end 
		--else 
			--tree[key] = node.index
		--end 
	--end 

--end 

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
local function init_dict(filename,level) 
	level= level or 3
	local dictfile =  openfile(filename)
	if not dictfile then return end  --- open file failed 

	local  dict_index = metatable() 
	local  dict_info = metatable() 
	local  dict_tree = metatable() 
	dict_tree.insert_index= dict_tree_insert_index
		
	for line in dictfile:lines() do 
		if not line:match("^#") then  -- 第一字 #  不納入字典
			local w = Word.Parse(line) 
			if type(w) == "Word" then 
				dict_index:insert(w)
				w.index= #dict_index 
				dict_info[w.word] = w
				dict_tree:insert_index(w,level)
			end 
		end 
	end 
	dictfile:close() 
	return dict_index ,dict_info, dict_tree
end 

local English= Class("English")
function English:_initialize(filename,level)
	self._filename= filename or "english_tw.txt"
	self._level= level or 3
	self._mode=0
	self:_load(filename,level)
	return self
end 
function English:_load(filename,level)
	print("load dictfile",self._filename)
	self._dict_index, self._dict_info ,self._dict_tree = self.Parse(filename,level)
end
function English:reload()
	self:_load(self._filename,self._level)
end 
	

function English.Parse(filename,level) -- return table ,table
	return init_dict(filename,level)

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


----  -----  以下重構

function English:_chk_part(word,ph)
	local info=self._dict_info[word]
	return ( info and info:chk_parts(ph) ) 
end 
--[[
function English:iter(org_text,mode)

	local pw,ww,p=conv_pattern(org_text) 
	local tab= self._dict_index[ org_text:sub(1,1):lower() ]  or metatable() 
	print (pw, "pw" , "(" .. pw ..")", pw:len() , pw:sub(1,1) , ww,p, tab, #tab )
	print("pw" , pw , "ww" , ww , "p", p)
	
	local pre_match =function()
			local count=0
			local index 
			for i,w in next, tab do 
					--print("--chcek-- nomatch :", i,index,w, w:lower() , ww ,  w:lower():match(ww) )
				if w:lower():match(pw) then 
					break
				end 
				index=i
				count=count+1
			end 
			print("------------------------------index-------------------" ,index,count )
			for i,w in next,tab,index do 
				--print(i,w)
				if w:lower():match(pw) then 
					if w:lower():match(ww) then 
						--print(w,ww)
						if self:chk_parts(w,p)  then 
							
							coroutine.yield( self:get_info(w))
						end 
					end 
				else 
					--print("-break--- nomatch :", i, index,w, w:lower() , ww ,  w:lower():match(ww) )
					break
				end 
			end 
		end 

	local pass_match= function()
		for i,w in next,tab do
			coroutine.yield( self:info1( node.word,mode))
		end 
	end 
	local f 
	--if org_text:len() >1 then 
		  f= org_text:len() >1 and pre_match or pass_match 
	 --end 
	 print("pre_math" ,pre_match,"pass method", pass_match, "f=",  f )


	return coroutine.wrap( org_text:len() >1 and pre_match or pass_match )

end 
--]]
function English:pre_suffix(key)
	return self._dict_tree[ key:lower() ]
end 
function English:iter(org_text,mode)
	local pw,ww,p=self.Split(org_text)
	local key=pw:sub(1,self._level):lower()
	--local pw,ww,p=conv_pattern1(org_text,self._level) 
	local pw,ww,p=conv_pattern(org_text) 
	local index= self:pre_suffix( key )  
	if not index then return function() end  end 
	local info_tab= self._dict_info
	if org_text:match("^[a-yA-Y]$") then 
		local endi= self:pre_suffix( string.char( key:byte() +1 ) ) -1
		return coroutine.wrap(function()
			for i=index , endi do
				coroutine.yield(self._dict_index[i] )
			end
		end )
	end 

	index= (index >2 and index-1) or nil
	return coroutine.wrap( 
	function()
		for i,node in next, self._dict_index ,index do 
			index=i
			if node:is_match(pw) then 
				break
			end 
		end 
		index= (index >2 and index-1) or nil
		--index=index-1 
		for i,node in next, self._dict_index , index do 
			if not node:is_match(pw) then  break end 
			if node:is_match(ww) then 
				if node:chk_parts( p)  then 
					coroutine.yield( node)
				end 
			end 
		end 
	end )
end 



function English:dict_match(word,func)   -- iter yield { word= , info= ...} 
	local tab_result=metatable( ) 
	func= func or function(elm)  return elm end 
	for elm  in  self:iter(word) do
		tab_result:insert( func(elm) )
	end 
	return tab_result
end 
function English.Eng_suffix(chr) 
	return eng_suffix[chr] or ""
end 
English.Wildfmt2=wildfmt2 
English.Wildfmt1=wildfmt1
English.Conver_rex=conver_reg 
English.Split=split_str 
English.Conver_pattern= conv_pattern
function English.Wildfmt(word)
	local _,ww , p =split_str(word)
	local pattern=conver_reg(ww) 
	return pattern,ww ,p
end 
--English.Dict_init1=init_dict1










return English


--return init

