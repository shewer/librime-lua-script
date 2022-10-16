#! /usr/bin/env lua
--
-- proc.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--

local Env= require 'tools/env_api'
local List = require 'tools/list'

local English="english"
local ASCII_PUNCT="ascii_punct"
local function component(env)
  local config = env.engine.schema.config
  -- definde prefix suffix  from name_space or local prefix suffix
  -- 加入 recognizer/patterns
  --local path= "recognizer/patterns/" .. env.name_space
  --local pattern = ("^%s[a-z]%s.*$"):format(prefix,suffix)
  --config:set_string(path, pattern)
  --puts("log",__FILE__(),__LINE__(),__FUNC__(), path, config:get_string(path),  "prefix" , prefix,"suffix" , suffix)

  -- 加入 lua_sgement
  local mod_name = 'english'
  if rrequire(mod_name .. '.segm') then
    local path = "engine/segmentors"
    local comp_name = ("lua_%s@%s%s@%s"):format("segmentor",mod_name,".segm",env.name_space)
    local slist=List(env:Config_get(path))
    if not slist:find_match(comp_name) then
      local index = slist:find_index("matcher") or 2
      config:set_string(path .. '/@before ' .. index-1, comp_name)
    end
  end
  -- 加入 lua_translator
  if rrequire(mod_name .. '.tran') then
    local path = "engine/translators"
    local comp_name = ("lua_%s@%s%s@%s"):format("translator",mod_name,".tran",env.name_space)
    if not List(env:Config_get(path)):find_match(comp_name) then
      config:set_string(path .. '/@next', comp_name)
    end
  end
  --recognizer/patterns/punct: '^/([0-9]0?|[A-Za-z]+)$'

  local punct = config:get_string("recognizer/patterns/punct")
  if punct == nil or punct == "" then
    config:set_string("recognizer/patterns/punct",[[^/([0-9]0?|[A-Za-z]*)$]])
  end

  -- 替換 uniquifier filter  --> lua_filter@uniquifier 或者加入
  --[[
  local f_path= "engine/filters"
  local org_filter= "uniquifier"
  local u_ns = "uniquifier"
  local r_filter = "lua_filter@uniquifier"
  _G[u_ns] = _G[u_ns] or require("component/uniquifier")
  local f_index= config:find_index(f_path, org_filter)
  if f_index then
    config:config_list_replace( f_path, org_filter, r_filter)
  else
    config:config_list_append( f_path, r_filter)
  end
  --增加 reject_tags
  config:config_list_append( u_ns .. "/reject_tags", env.name_space )
  --]]
end

local P={}
function P.init(env)
  Env(env)
  local context=env.engine.context
  local config= env.engine.schema.config
  --load_config(env)
  component(env)
  --recognizer/patterns/english: "^[a-zA-Z]+[*/:'._-].*"
  env.keys= env:get_keybinds()
  env.keys.completion= KeyEvent("Tab")
  env.keys.completion_back= KeyEvent("Shift+Tab")
  env.keys.completion_back1= KeyEvent("Shift+ISO_Left_Tab")

  --env.comp_key= KeyEvent("Tab")
  --env.uncomp_key= KeyEvent("Shift+ISO_Left_Tab")
  --env.enable_key= KeyEvent(config:get_string(env.name_space .."/keybinds/toggle") or "F10")
  --context:set_option(English,false)
  env.history=List()

  env.notifier= List(
  context.commit_notifier:connect(function(ctx)
    env.history:clear()
  end),
  context.option_update_notifier:connect(function(ctx,name)
    if name == English then
      if ctx:get_option(name) then
        if not ctx:get_option(ASCII_PUNCT) then
          ctx:set_option(ASCII_PUNCT,true)
          env.save_ascii_punct= true
        end
      else
        if env.save_ascii_punct then
          ctx:set_option(ASCII_PUNCT,false)
        end
      end
    end
  end))
end

function P.fini(env)
  env.notifier:each(function(elm) elm:disconnect() end)
end

function P.func(key,env)
  local Rejected,Accepted,Noop=0,1,2
  -- 過濾 release ctrl alt key 避免 key_char 重複加入input
  local context=env.engine.context
  local status=env:get_status()
  local key_char= key.keycode >= 0x20 and key.keycode < 128 and string.char( key.keycode) or ""

  -- enable English mode
  if key:eq(env.keys.toggle) then
    env:Toggle_option(English)
    context:refresh_non_confirmed_composition()
    return Accepted
  end
  if key:release() or key:ctrl() or key:alt() then return Noop end
  if not context:get_option(English) then return Noop end

  -- reject
  -- match env.pattern
  -- english mode  and key ==  a
  if #key_char == 1  then
  local active_inp= context.input .. key_char
    if context:is_composing() and key_char:match("^[ ,]")  then
      context:commit()
      return Rejected
    elseif  active_inp:match("^[%a][%a'.?*/:_%- ]*$") then --context:is_composing() and key_char:match("^[%a'.?*/:_%-]$") or  key_char:match("^[%a]$") then
      context:push_input(key_char)
      return Accepted
    end
  end
  -- comment mode
  if key:eq(env.keys.mode) then
    env:Toggle_option("english_info_mode")
    return Accepted
  end

  -- 反回上一次 input text
  if key:eq(env.keys.completion_back) or key:eq(env.keys.completion_back1) then
    if #env.history >0 then
      context.input = env.history:pop()
      return Accepted
    else
      return Noop
    end
  end
  -- 補齊input   以cand.type "ninja" 替換部分字段 "english" 替換全字母串
  if status.has_menu  then
    local cand=context:get_selected_candidate()
    if key:eq(env.keys.completion)  then
      -- reject
      if cand.text == context.input then return Noop end

      local history = context.input
      if cand.type == "english" then
        context.input = cand.text
      elseif cand.type== "ninja" then
        context:push_input( cand.text:sub( cand._end - cand.start ) )
      elseif cand.type== "english_ext" then
        local text = cand.text
        cand.text = cand.comment:match("%[(.*)%]")
        cand.comment= "[" .. text .. "]"
      else
        return Noop
      end
      env.history:push(history)
      return Accepted
    end
  end
  return Noop
end


return P
