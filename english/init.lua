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
local English_mode="english_sw"
local English_mode_key="Control+F9"

local Reflash_Dict="reflash_dict"
local Reflash_Dict_key="Control+F12"

--require "english/english_init"
--string.find_word,string.word_info= require("english/english_dict")()

--require('english.english_init')
-- init  dictionary  function to string table
--local dict= require('english.english_dict')() -- (USERDIR .. "\\" .. [[lua\english\english.txt]] )
--string.find_words,string.word_info,string.iter_match= dict.words,dict.info,dict.iter_match
--string.wildfmt=dict.wildfmt
--string.wildfmt=dict.iter_dict_match
-- chcek mode

-- 檢查 英打模式
local function chk_english_mode(env)
	local ascii_mode= env.engine.context:get_option(Ascii_mode)
	local chk_english_mode= env.engine.context:get_option(English )
	--return  chk_english_mode   and   not ascii_mode
	return  chk_english_mode   and  not ascii_mode
end
-- 切換 option  true/false
local function toggle_mode(env,name)
	local context=env.engine.context
	local name_status=context:get_option(name)
	context:set_option(name , not name_status)
end

--if context:is_composing() and  [,/. ] then
local function  commit_chk(env,char)
	local context=env.engine.context

	--if not context:is_composing()  then return false end
	if char:match([[^[, ]$]]  ) then  return true
	elseif  char == "."  and not context:has_menu() then return true
	else return false end
end
--  可以使用 key_bind   { when:has_menu , accept: Control+Return , action: commit_comment
local function commit_comment(env)
	local context=env.engine.context
	local cand= context:get_selected_candidate()
	env.engine:commit_text(cand.comment)
	context:clear()
end
-- tab鍵  補齊功能
local function complate_text(env)
	local context=env.engine.context
	local seg=context.composition:back()
	local dict=env.dict
	if not seg then return  end

	-- 在 intput 字串 有 "/"  補齊 wildfmt 如 auto/i  --> auto*ing
	if  context.input:match("/") then -- and backup_input ~= word  then

		env.history_words:push(context.input)
		local _ , word , part= dict.Wildfmt(context.input)
		context.input =    word   ..  ( context.input:match(":.*")  or ""  )
		return
	end

	-- 如果有 menu 以讀取 目前 select cand 補齊 input
	if context:has_menu() then
		if false then
			local cand=seg:get_selected_candidate()
			-- 如果 cand 是第一個 且 type== "pre_english" 重取下一個 cand 補齊
			if  seg.selected_index == 0 and cand.type == Pre_english and seg.menu:candidate_count() >1  then
				cand= seg:get_candidate_at(seg.selected_index +1 )
			end
			env.history_words:push( context.input )
			context.input= cand.text
		else


			local cand= seg:get_selected_candidate()
			if seg.selected_index ==0 then
				cand=  seg:get_candidate_at(1)  or cand
			else
			end
			if  context.input ~= cand.text then
				env.history_words:push( context.input )
				context.input= cand.text
			end
		end
	end
end
-- Shift-Tab 補齊返回上一層
local function restore_word(env)
	local context=env.engine.context
	context.input=  env.history_words:pop()  or context.input
end


local function menu_hotkey_cmd(env, hotkey)
	local context= env.engine.context
	log.error( "function call :in menu hotkey cmd ")

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
	--if hotkey == English_complete_key then toggle_mode(env,English_complete) ;return true end

	--  字根補齊熱鍵   English_complete enable
	if hotkey == English_mode_key then
		context:set_property(English_mode,"next")
		return true
	end
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
	stat.empty= not stat.composing
	stat.has_menu= ctx:has_menu()
	stat.paging= not comp:empty() and comp:back():has_tag("paging")
	return stat
end

local function lua_init(filename)
	local Notifier= require('tools/notifier')
	local dict= require("english/english_dict"):New(filename)
	local function processor_func(key,env) -- key:KeyEvent,env_
		local Rejected, Accepted, Noop = 0,1,2

		local context=env.engine.context
		local composition=context.composition
		local status= status(context)
		local keycode=key.keycode
		local keyrepr=key:repr()
		local keychar= (key.modifier <=1 and keycode >=0x20 and keycode <0x80 and string.char(keycode) ) or ""
		--if ( alt() or key:release() ) then return Noop end
		if ( key:release() ) then return Noop end
		if keyrepr == Toggle_key then  toggle_mode(env,English)   ; return Accepted  end

		if not chk_english_mode(env)  then  return Noop end

		if status.empty then
			--  在 not is_composing 時如果 第一字母為 pucnt
      if  keychar:match("/") then return Noop end
			if  keychar:match("[%p ]") then return Rejected end
			if  keyrepr == "Tab" then return Rejected end
			if  keyrepr == Reflash_Dict_key then env.dict:reload() ;return Accepted end


		end
		-- in english mode
		if status.always then
			-- 任何模式下
			--  toggle mode    ascii - chinese  -- english -- ascii

			if always_hotkey_cmd(env,keyrepr) then return Accepted end
			--
			--  正常模式
			if  keychar:match([[^[%a%:/'?*_.%-]$]]) then
				context:push_input(keychar)
				return Accepted
			end
		end
		if status.has_menu then
			if keychar:match("[, ]") then context:commit() ; return Rejected end
			if keyrepr== "Return"  then context:commit() ; return Rejected end
			if keyrepr=="Control+Return" then commit_comment(env) ; return Accepted   end

		end

		if status.composing then
			if keychar:match("[,%. ]")  then context:commit()  return Rejected end
			if keyrepr== "Return"  then context:commit() ; return Rejected end
			--if  commit_chk(env,keychar) then context:commit() return Rejected end  --
			if menu_hotkey_cmd(env,keyrepr) then return Accepted end
		end


		if status.paging then

		else
			return Noop

		end

		return Noop
	end

	local function processor_init_func(env)
		env.dict=dict
		env.history_words= setmetatable({} , {__index=table } )
		-- 註冊 commit_notifier 上屏後  清空 history_words
		--env.connection= env.engine.context.commit_notifier:connect(
		--function(context)
			--for i=0, #env.history_words	do env.history_words[i]=nil end
			----env.history_words= setmetatable({} , {__index=table } )
		--end )
		local function clear_history(ctx)
			for i=0, #env.history_words	do env.history_words[i]=nil end
		end
		env.notifier= Notifier(env)
		local t=env.notifier:commit(clear_history)
		print("---t commit notifiter call functoin: ", t,"connect" , connection )
		----LINE   --- function 引用 dict 需要再檢查
	end

	local function processor_fini_func(env)
		-- 移除註冊 commit_notifier 上屏後  清空 history_words
		env.keyname=nil
		env.history_words=nil
		env.dict=nil
		env.notifier:disconnect()
	end


	-- lua segmentor
	local function segmentor_func(segs ,env) -- segmetation:Segmentation,env_
		local context=env.engine.context
		local cartpos= segs:get_current_start_position()

		-- 在chk_english_mode() 為 input 打上 english tag
		if chk_english_mode(env) and context:is_composing() then
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
		-- 不是 chk_english_mode  pass 此 segmentor  由後面處理
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
		if chk_english_mode(env) and seg:has_tag(English)  then
			-- 為模擬 英文模式 將input 設第一個候選字 空白鍵 原碼+空白 上屏
			local pre_english_check = true

			for word_info in env.dict:iter(input:lower())  do
				-- 第一個 canddidate text ~= input  則要送上 pre_english
				if pre_english_check then
					pre_english_check=false
					if  input ~= word_info.word then
						yield( Candidate(Pre_english , seg.start,seg._end , input  , "[english]"))
					end
				end
				yield( Candidate(English, seg.start,seg._end , word_info.word, word_info.info  ))
			end
		end
	end

	local function translator_init_func(env)
		env.dict=dict
		local context= env.engine.context

		env.connection_property=context.property_update_notifier:connect(
		function(context,name)
			-- Control+F9  送字串上  property  切換 comment 顯示模式   ,清除 command 井將狀態寫入 info_mode
			-- 供 filter取用
			local value= context:get_property(name)
			if name == English_mode and value== "next" then
				local mode=env.dict:next_mode()
				context:set_property(name,"")
				context:set_property("info_mode",mode )

				context:refresh_non_confirmed_composition()
			end
		end )
		----LINE   --- function 引用 dict 需要再檢查
	end
	local function translator_fini_func(env)
		env.dict=nil
		if env.connection_property then
			env.connection_property:disconnect()
			env.property_connection= nil
		end
	end

	-- lua filter

	--  cand data to string
	local function filter_func(input,env)  -- input:Tranlation , env_
		local context=env.engine.context
		local mode= context:get_property("info_mode")

		for cand in  input:iter() do

			if cand.type== English then
				local  fold_sw =  context:get_option(Fold_sw)

				local comment= env.dict:get_info(cand.text):get_info(mode)

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
		local context=env.engine.context
		env.dict=dict
		local function ntf (ctx)
			local st= status(ctx)
			local seg=ctx.composition:back()
			if st.has_menu then
				local cand=seg:get_selected_candidate()
				local index=seg.selected_index
				local count= seg.menu:candidate_count()
				cand= seg:get_candidate_at(seg.selected_index +1 )
				if cand then
					index=seg.selected_index
					count= seg.menu:candidate_count()
				else
				end
			end

		end

		env.update_notifier_connection= context.update_notifier:connect(ntf)
		env.select_notifier_connection= context.select_notifier:connect(ntf)
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
local S={}
function S.func(segs ,env) -- segmetation:Segmentation,env_
  local context=env.engine.context
  local cartpos= segs:get_current_start_position()

  -- 在chk_english_mode() 為 input 打上 english tag
  if context:is_composing() and context:get_option(english) then
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
  -- 不是 chk_english_mode  pass 此 segmentor  由後面處理
  return true
end

function S.func(env)
end
function S.fini_func(env)
end
	-- lua translator


	local function translator_func(input,seg,env)  -- input:string, seg:Segment, env_
		local context=env.engine.context
		local fold_status=context:get_option( Fold_sw )
		--在  模式  和 tag 為 english 才 翻譯
		if chk_english_mode(env) and seg:has_tag(English)  then
			-- 為模擬 英文模式 將input 設第一個候選字 空白鍵 原碼+空白 上屏
			local pre_english_check = true

			for word_info in env.dict:iter(input:lower())  do
				-- 第一個 canddidate text ~= input  則要送上 pre_english
				if pre_english_check then
					pre_english_check=false
					if  input ~= word_info.word then
						yield( Candidate(Pre_english , seg.start,seg._end , input  , "[english]"))
					end
				end
				yield( Candidate(English, seg.start,seg._end , word_info.word, word_info.info  ))
			end
		end
	end

local T=require 'english/english_tran'

local F={}
function F.func(input,env)  -- input:Tranlation , env_
  local context=env.engine.context
  local mode= context:get_property("info_mode")

  for cand in  input:iter() do

    if cand.type== English then
      local  fold_sw =  context:get_option(Fold_sw)

      local comment= env.dict:get_info(cand.text):get_info(mode)

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

function F.func(env) -- non return
  local context=env.engine.context
  env.dict=dict
  local function ntf (ctx)
    local st= status(ctx)
    local seg=ctx.composition:back()
    if st.has_menu then
      local cand=seg:get_selected_candidate()
      local index=seg.selected_index
      local count= seg.menu:candidate_count()
      cand= seg:get_candidate_at(seg.selected_index +1 )
      if cand then
        index=seg.selected_index
        count= seg.menu:candidate_count()
      else
      end
    end

  end

  env.update_notifier_connection= context.update_notifier:connect(ntf)
  env.select_notifier_connection= context.select_notifier:connect(ntf)
end
function F.fini_func(env)  -- non return
  env.dict=nil
  --env.connection:disconnect()
end

function find_component(config,path,name)
  for i=0,config:get_list_size(path) -1 do
    local str=config:get_string( ("%s/@%s"):format(path,name) ) or ""
    if str:match(name) then
      return true
    end
  end
end

local function components(env)
  local config=env.engine.schema.config
  local l_seg= English .. "_segment"
  local l_tran= English .. "_tran"
  local l_filter= English .. "_filter"

  _G[l_seg] = S
  _G[l_tran] = require('english/english_tran') or nil
  _G[l_filter] = F
  if not find_component(config,"engine/segments","lua_segment@".. l_seg ) then
    config:set_string( ("%s/@befort %s"):format("engine/segments",0), "lua_segment@" .. l_seg )
  end
  if not find_component(config,"engine/translators", "lua_translator@" .. English .. "_tran" ) then
    config:set_string( ("%s/@next"):format("engine/translators"), "lua_translator@"  .. l_tran )
  end
  if not find_component(config,"english/filters", "lua_filter@" .. l_filter) then
    config:set_string( ("%s/@next"):format("engine/filters"), "lua_translator@" .. l_filter )
  end
end

local P={}
function P.init(env)
  components(env)
  env.dict=dict
  env.history_words= List()
  env.notifire = context.commit_notifier(function(ctx)
    env.history_words:clean()
  end )
end

function P.fini(env)
  -- 移除註冊 commit_notifier 上屏後  清空 history_words
  env.keyname=nil
  env.history_words=nil
  env.dict=nil
  env.notifier:disconnect()
end

function P.func(key,env)
  local Rejected, Accepted, Noop = 0,1,2

  local context=env.engine.context
  local composition=context.composition
  local status= status(context)
  local keycode=key.keycode
  local keyrepr=key:repr()
  local keychar= (key.modifier <=1 and keycode >=0x20 and keycode <0x80 and string.char(keycode) ) or ""
  --if ( alt() or key:release() ) then return Noop end
  if ( key:release() ) then return Noop end
  if keyrepr == Toggle_key then  toggle_mode(env,English)   ; return Accepted  end

  if not chk_english_mode(env)  then  return Noop end

  if status.empty then
    --  在 not is_composing 時如果 第一字母為 pucnt
    --if  keychar:match("/") then return Noop end
    --if  keychar:match("[%p ]") then return Rejected end
    --if  keyrepr == "Tab" then return Rejected end
    --if  keyrepr == Reflash_Dict_key then env.dict:reload() ;return Accepted end


  end
  -- in english mode
  if status.always then
    -- 任何模式下
    --  toggle mode    ascii - chinese  -- english -- ascii

    if always_hotkey_cmd(env,keyrepr) then return Accepted end
    --
    --  正常模式
    if  keychar:match([[^[%a%:/'?*_.%-]$]]) then
      context:push_input(keychar)
      return Accepted
    end
  end
  if status.has_menu then
    if keychar:match("[, ]") then context:commit() ; return Rejected end
    if keyrepr== "Return"  then context:commit() ; return Rejected end
    if keyrepr=="Control+Return" then commit_comment(env) ; return Accepted   end

  end

  if status.composing then
    if keychar:match("[,%. ]")  then context:commit()  return Rejected end
    if keyrepr== "Return"  then context:commit() ; return Rejected end
    --if  commit_chk(env,keychar) then context:commit() return Rejected end  --
    if menu_hotkey_cmd(env,keyrepr) then return Accepted end
  end


  if status.paging then

  else
    return Noop

  end

  return Noop
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

return P
--return lua_init



