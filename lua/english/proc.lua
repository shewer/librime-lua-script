#! /usr/bin/env lua
--
-- proc.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
local COM = require 'english/common'
local Env= require 'tools/env_api'
local List = require 'tools/list'

local function config_list_find(config, path, elm)
   local cl = assert(config:get_list(path), path .. " of value error: expact (List)")
   for i=0, cl.size-1 do
      if cl:get_value_at(i).value == elm then
	 return i
      end
   end
end      



local function config_list_value(cl)
   local tab = List()
   for i = 0, cl.size-1 do
      tab:push(cl:get_value_at(i))
   end
   return tab
end
local function config_list_string(cl)
   local tab = List()
   for i = 0, cl.size-1 do
      tae:push(cl:get_value_at(i).value)
   end
   return tab
end

local function config_map(cm)
   local tab = {}
   for k in ipairs(cm:keys()) do
      tab[k] = cm:get(k)
   end
   return tab
end

local English="english"
local ASCII_PUNCT="ascii_punct"
--load keybinder
-- 1 schema:   name_space/keys_binding/name: key ex: english/keybinding/toggle: "F10"
local function keybinder(env)
   local config = env.engine.schema.config
   local path = env.name_space .. "/keys_binding"
   local keys={}
   -- default 
   -- common.lua
   for k, kv in next, COM.keys_binding do
      local key  = config:get_string(path .. "/" .. k) or kv
      keys[k] = KeyEvent(key)
   end
   return keys
end   
local function log_components(env)
   local config= env.engine.schema.config
   log.info("------------------------------------------------------------")
   for _,v in next, {"processors", "segmentors", "translators", "filters"} do
      local path = "engine/" .. v
      local size = config:get_list_size(path)
      for i=0, size-1 do
	 local comp=config:get_string(path.. "/@" .. i)
	 log.info( string.format("%s\t%d\t%s",v,i,comp) )
      end
   end
   log.info("------------------------------------------------------------")
end
-- insert component

local function component(env)
   local segmentor = "lua_segmentor@*english.segm@" .. env.name_space
   local affix = "affix_segmentor@" .. env.name_space
   local translator = "lua_translator@*english.tran@" .. env.name_space

   local config = env.engine.schema.config
   local tag = config:get_string(env.name_space .. "/tag") or COM.tag or env.name_space
   -- insert segmentor before matcher
   local path = "engine/segmentors"
   if not config_list_find(config, path, mod_name ) then
      local index = config_list_find(config, path, "matcher") or 2
      config:set_string(path .. "/@before " .. index , segmentor)
   end
   -- insert segmentor before punct
   local prefix = config:get_string(env.name_space .. "/prefix") or COM.prefix
   if prefix and #prefix >0  then
      if not config_list_find(config, path, mod_name ) then
	 local index = config_list_find(config, path, "punct_segmentor") or -2
	 config:set_string(path .. "/@before " .. index, affix)
      end
      
      if not config:get_string("recognizer/patterns/".. tag) then
	 log.warning('recogniOAzer/patterns/' .. tag .. "does not setting")
         config:set_strnig("recoginzer/patterns/ .. tag", COM.prefix_pattern)
      end
   end
   -- append translator   
   local path = "engine/translators" 
   if not config_list_find(config, path, translator ) then
      local index = config:get_list_size(path)
      config:set_string(path .. "/@before " .. index , translator)
   end
end

local P={}
function P.init(env)
   Env(env)
   local context=env.engine.context
   local config= env.engine.schema.config
   -- segmetor  translator
   if COM.component_config then
      component(env)
      log_components(env)
   end
   

   env.splite_char1 = config:get_string(env.name_space .. "/splite_char1") or COM.splite_char1
   env.splite_char2 = config:get_string(env.name_space .. "/splite_char2") or COM.splite_char2
   
   env.prefix = config:get_string(env.name_space .. "/prefix") or COM.prefix
   env.keys = keybinder(env)
   env.tag = config:get_string(env.name_space .. "/tag") or COM.tag
   env.history=List() 
   if T08 and GD then GD() end


   --rime_api.test_luaobj0(1)
   local function commit_func(ctx) env.history:clear() end
   env.notifiers= {
      context.commit_notifier:connect(
      function (ctx) env.history:clear() end),
   }
end

function P.fini(env)
   for i,elm in next, env.notifiers do  elm:disconnect() end
end

function P.func(key,env)
   local Rejected,Accepted,Noop=0,1,2
   -- 過濾 release ctrl alt key 避免 key_char 重複加入input
   local context = env.engine.context
   local status = env:get_status()
   local comp = context.composition
   local segment = comp:back()
   local key_char = key.keycode >= 0x20 and key.keycode < 0x80
      and string.char( key.keycode) or ""
   local active_input = context.input .. key_char

   if key:eq( KeyEvent("Control+F5")) and GD then 
     local cand = context:get_selected_candidate()
     local scand = ShadowCandidate(cand, 's')
     local ucand = UniquifiedCandidate(cand, 'u')
     ucand:append(cand)
     local uucand = UniquifiedCandidate(ucand, 'uu')
     uucand:append(cand)
     GD() 
     print()
   end
   if key:release() or key:alt() then return Noop end   
   -- enable English mode  e
  
   if key:eq(env.keys.toggle) then
      context:set_option( English, not context:get_option(English))
      context:refresh_non_confirmed_composition()
      return Accepted
   end

   local enable_english = context:get_option(English) or
      segment and ( segment:has_tag(English) or segment:has_tag(English.. "_prefix"))
-- start check key
   if not enable_english then return Noop end

   local accept_pattern = string.format("^[%%a_%%-*?%s%s ]$", env.splite_char1, env.splite_char2)
   --   if not context:get_option(English) then return Noop end
   if key_char:match(accept_pattern) then
      context:push_input(key_char)
      return Accepted
   end
   
   if key_char:match("^[,. ]$") then
      candss = segment.menu:create_page(5,6)
      if T07 and GD then GD() end
      context:commit()
      --env.engine:commit_text( key_char==" " and key_char or key_char .. " ")
      env.engine:commit_text(key_char)
      return Accepted
   -- 切換 comment 顯示模式
   elseif key:eq(env.keys.comment_mode) then
      local mode = context:get_property(COM.property_name) % 7 +1
      context:set_property(COM.property_name,mode)
      context:refresh_non_confirmed_composition()
      return Noop
   -- 反回上一次 input text
   elseif key:eq(env.keys.completion_back) or key:eq(env.keys.completion_back1) then
      if #env.history>0 and segment then
	 context:pop_input(segment._end - segment._start)
	 local htext= env.history:pop()
	 context:push_input(htext)
	 return Accepted
      end
      return Noop
   -- 補齊input   以cand.type "ninja" 替換部分字段 "english" 替換全字母串
   elseif key:eq(env.keys.completion)  then
      if not status.has_menu  then return Noop end
      local cand=context:get_selected_candidate()
      
      -- reject
      if cand.text == context.input:sub(cand._start+1, cand._end)  then return Noop end
      if cand.type == "english" then
	 local htext = context.input:sub(cand._start+1,cand._end) 
	 env.history:push(htext)
	 context:pop_input(cand._end - cand._start)
	 context:push_input(cand.text)
      elseif cand.type== "ninja" then
	 env.history:push(cand.text)
	 context:pop_input(cand._end - cand._start)


      elseif cand.type== "english_ext" then
	 local text = cand.text
	 cand.text = cand.comment:match("%[(.*)%]")
	 cand.comment= "[" .. text .. "]"
      else
	 return Noop
      end
      return Accepted
   end
   return Noop
end




return P
