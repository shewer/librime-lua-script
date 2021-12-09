#! /usr/bin/env lua
--
-- english.lua
-- Copyright (C) 2020 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--

-- windows  path setup 

--USERDIR= ( USERDIR or  os.getenv("APPDATA") or "" ) .. [[\Rime]]
--USERDIR= rime_api.user_dir()

local English= "english"
local Toggle_key= "F10"
local Ascii_mode = "ascii_mode"
local Pre_english = "pre_english" 
local Fold_sw = "fold_comments"
local Toggle_fold_key= "F9" 
local English_complete="english_complete"
local English_complete_key="F8"

--require "english/english_init"
--string.find_word,string.word_info= require("english/english_dict")() 

--require('english.english_init')
-- init  dictionary  function to string table 
--local dict= require('english.english_dict')() -- (USERDIR .. "\\" .. [[lua\english\english.txt]] )
--string.find_words,string.word_info,string.iter_match= dict.words,dict.info,dict.iter_match
--string.wildfmt=dict.wildfmt
--string.wildfmt=dict.iter_dict_match
-- chcek mode   
local function english_mode(env)
	local ascii_mode= env.engine.context:get_option(Ascii_mode)
	local english_mode= env.engine.context:get_option(English )
	--return  english_mode   and   not ascii_mode
	return  english_mode   and not  ascii_mode
end 
local function toggle_mode(env,name)
	local context=env.engine.context
	local name_status=context:get_option(name)
	context:set_option(name , not name_status)
end 	

--if context:is_composing() and  [,/. ] then
local function  commit_chk(char,env) 
	local context=env.engine.context

	if not context:is_composing()  then return false end  
	if char:match([[^[, ]$]]  ) then  return true
	elseif  char == "."  and not context:has_menu() then return true
	else return false end  
end 
local function commit_input(chr,env)
	local context=env.engine.context
	local cand= context:get_selected_candidate()
	context.input = (cand and cand.text ) or context.input  -- 更新 context.input
	context:commit() 
	
end 

local function complate_text(env) 
	local context=env.engine.context
	local seg=context.composition:back()
	local dict=env.dict
	log.info( string.format( "--complate start has_menu:%s  menu_count: %s, select_index: %s", 
	context:has_menu(), seg.menu:candidate_count() ,seg.selected_index ) ) 
	if not seg then return  end 

	-- 在 intput 字串 有 "/"  補齊 wildfmt 如 auto/i  --> auto*ing  
	if  context.input:match("/") then -- and backup_input ~= word  then 
		local _ , word , part= dict.Wildfmt(context.input)
		word =    word   ..  context.input:match(":.*")  or "" 
		env.history_words:push(context.input)
		context.input= word .. part

		log.info( string.format( "--complate   / :%s  menu_count: %s, select_index: %s", 
		context:has_menu(), seg.menu:candidate_count() ,seg.selected_index ) ) 
		return 
	end 

	-- 如果有 menu 以讀取 目前 select cand 補齊 input 
	if context:has_menu() then 
		local cand=seg:get_selected_candidate( )
		-- 如果 cand 是第一個 且 type== "pre_english" 重取下一個 cand 補齊  
		if  seg.selected_index == 0 and cand.type == Pre_english and seg.menu:candidate_count() >=1  then  
			cand= seg:get_candidate_at(seg.selected_index +1 ) 
		end 
		env.history_words:push( context.input )
		log.info( string.format( "--complate has_menu  hasmenu :%s  menu_count: %s, select_index: %s", 
		context:has_menu(), seg.menu:candidate_count() ,seg.selected_index ) ) 
		context.input= cand.text
	end 
end 
local function restore_word(env) 
	local context=env.engine.context
	context.input=  env.history_words:pop()  or context.input 
end 
local function hot_keyword1(hotkey,env) 
	local context=env.engine.context
	local wildword_ = (env.keyname2[hotkey] and "*" ..  env.keyname2[hotkey] ) or "" 
	env.history_words:insert(context.input)
	context.input = context.input  .. wildword_ 
end 

local function menu_hotkey_cmd(env, hotkey)
	local context= env.engine.context

	--  Tab    intput 補齊
	if  hotkey == "Tab" then  complate_text(env) ; return true end 
	-- 返迴 上一次 補齊的 context:input 
	if  hotkey == "Shift+Tab" or hotkey== "Shift_L+Tab" or hotkey== "Shift_R+Tab"  then 
		--restore_word(env) 
		context.input= env.history_words:pop() or context.input 
		return true 
	end 
	return false 
end 
local function always_hotkey_cmd(env, hotkey)
	local context= env.engine.context

	-- 字典 展開 收縮  開關
	if hotkey ==  Toggle_fold_key then toggle_mode(env,Fold_sw ) ; return true end 

	--  字根補齊熱鍵  drr  English_complete enable  
	if hotkey == English_complete_key then toggle_mode(env,English_complete) ;return true end 

	--  字根補齊熱鍵   English_complete enable  
	if context:get_option(English_complete) then 
	    --  
		--local hotkey_char= hotkey:match("^Control%+(%w)$") 
		--local part_word= env.dict.Eng_suffix(  hotkey_char or "" ) 
		--if part_word  then  context.input= context.input .. part_word ;  return true end 
	end 


	return false 
end 
local function status(ctx)
	local stat=metatable()
	local comp= ctx.composition
	stat.always=true
	stat.composing= ctx:is_composing()
	stat.has_menu= ctx:has_menu()
	stat.paging= not comp.empty() and comp:back():has_tag("paging") 
	return stat
end 

local function lua_init(...)
	local dict= require("english/english_dict"):New() 
	local function processor_func(key,env) -- key:KeyEvent,env_
		local Rejected, Accepted, Noop = 0,1,2 

		local context=env.engine.context 
		local composition=context.composition
		local status= status(context) 
		local keycode=key.keycode 
		local keyrepr=key:repr()
		print( "----keycode: ",keycode, "keyrepr:" , keyrepr) 
		local keychar= (keycode >=0x20 and keycode <0x80 and string.char(keycode) ) or ""
		if ( key:alt() or key:release() ) then return Noop end 
		if keyrepr == Toggle_key then  toggle_mode(env,English)   ; return Accepted  end 
		if not english_mode(env)  then  return Noop end 

		
		-- in english mode 
		if status.always then 
		-- 任何模式下
		--  toggle mode    ascii - chinese  -- english -- ascii 

			if always_hotkey_cmd(env,keyrepr) then return Accepted end 
			--  在 not is_composing 時如果 第一字母為 pucnt  
			if  context.input:len() == 0 and keychar:match("[%p ]") then return Noop end  
			--  
			if  commit_chk(keychar, env) then commit_input(keychar,env) return Rejected end  --  
			--  正常模式 
			if  keychar:match([[^[%a%:/'?*_.-]$]]) then  
				context:push_input(keychar)
				return Accepted
			end 

		elseif status.composing then
			if menu_hotkey_cmd(env,keyrepr) then return Accepted end 

		elseif status.has_menu then 

		elseif status.paging then 

		else 
			return Noop

		end 

		return Noop  
	end  

	local function processor_init_func(env)
		env.dict=dict 
		env.history_words= setmetatable({} , {__index=table } ) 
		-- 註冊 commit_notifier 上屏後  清空 history_words 
		env.connection= env.engine.context.commit_notifier:connect(
		function(context)  
			for i=0, #env.history_words	do env.history_words[i]=nil end 
			--env.history_words= setmetatable({} , {__index=table } ) 
		end )
		----LINE   --- function 引用 dict 需要再檢查 
	end 

	local function processor_fini_func(env)
		-- 移除註冊 commit_notifier 上屏後  清空 history_words 
		env.keyname=nil 
		env.history_words=nil 
		env.dict=nil
		env.connection:disconnect() 
	end 


	-- lua segmentor
	local function segmentor_func(segs ,env) -- segmetation:Segmentation,env_
		local context=env.engine.context
		local cartpos= segs:get_current_start_position()

		-- 在english_mode() 為 input 打上 english tag  
		if english_mode(env) and context:is_composing() then 
			local str = segs.input:sub(cartpos) 
			if not  str:match([[^%a[%a'?*_.-]*]]) then  return true  end 
			local str= segs.input:sub(segs:get_current_start_position() )
			local seg=Segment(cartpos,segs.input:len())
			seg.tags=  Set({English})
			seg.prompt="(english)"
			segs:add_segment(seg) 

			-- 終止 後面 segmentor   打tag
			return false 
		end 
		-- 不是 english_mode  pass 此 segmentor  由後面處理 
		return true
	end 

	local function segmentor_init_func(env)
	end 
	local function segmentor_fini_func(env)
	end 
	-- lua translator 
	
	local function translator_func(input,seg,env)  -- input:string, seg:Segment, env_

		local context=env.engine.context
		local fold_status=context:get_option( Fold_sw ) 
		--在  模式  和 tag 為 english 才 翻譯
		if english_mode(env) and seg:has_tag(English)  then 
			-- 為模擬 英文模式 將input 設第一個候選字 空白鍵 原碼+空白 上屏
			yield( Candidate(Pre_english , seg.start,seg._end , input  , "[english]"))
			for word_info in env.dict:iter(input:lower(),1)  do 
				yield( Candidate(English, seg.start,seg._end , word_info.word, word_info.word ))
			end 
		end 
	end 

	local function translator_init_func(env)
		env.dict=dict 
	end 
	local function translator_fini_func(env)
		env.dict=nil
	end 

	-- lua filter

	--  cand data to string 
	local function filter_func(input,env)  -- input:Tranlation , env_
		local context=env.engine.context

		for cand in  input:iter() do 

			if cand.type== English then  
				local  fold_sw =  context:get_option(Fold_sw) 
				comment= dict:info(cand.text) 

				if fold_sw then 
					--  分割 "\\n"  加 candidate
					comment:split("\\n"):each( function(elm)
						yield( Candidate( cand.type,cand.start,cand._end,cand.text,elm) )
					end )
				else 
					-- 不分割 去掉 ”\\n" 
					cand.comment= comment:gsub("\\n"," ")
					yield(cand) 
				end 

			elseif cand.type == Pre_english then yield(cand)   -- pass 
			else yield(cand) end  -- pass 
		end 
	end 

	local function filter_init_func(env) -- non return 
		env.dict=dict 
	end 
	local function filter_fini_func(env)  -- non return 
		env.dict=nil
		--env.connection:disconnect() 
	end 

	return { 
		processor= { func=processor_func, init=processor_init_func, fini=processor_fini_func} , 
		segmentor= { func= segmentor_func, init=segmentor_init_func , fini=segmentor_fini_func} , 
		translator={ func=translator_func, init=translator_init_func,fini=translator_fini_func} , 
		filter=    { func=filter_func, init=filter_init_func,    fini=filter_fini_func } ,   
	}

end 
-- init  lua component  to global variable
--[[
local function init(tagname, unload_)
	local tab_= lua_init() 
	for k,v in pairs( tab_) do 
		local kk= tagname .. "_" .. k 
		_G[kk] =  ( not unload_ and  v ) or nil  --  load and v    or  nil 
	end 


end 
--]]

return lua_init



