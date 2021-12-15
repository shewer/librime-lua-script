#! /usr/bin/env lua
--
-- init.lua
-- Copyright (C) 2021 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
--  command/init
--  lua_processor@command_proc@command
--     key function  Tab selected and
--
--  lua_translator@command_tran@command
--
--
--  lua_filter@command_filter@command
--     keeped cand.commend match  context.input without prefix
--
--
--
--  replace uniquifier  and append tags command in  reject_tags
--
--
--
local English="english"
local puts = require 'tools/debugtool'
local T= require'english/english_tran'
-- filetr of command

-- lua segmentor
local S={}
function S.func(segs ,env) -- segmetation:Segmentation,env_
  local context=env.engine.context
  local cartpos= segs:get_current_start_position()

  -- 在chk_english_mode() 為 input 打上 english tag
  --if chk_english_mode(env) and context:is_composing() then
  if context:get_option(English) and context:is_composing() then
    local str = segs.input:sub(cartpos)
    if not  str:match("^%a[%a'?*/:_,.%-]*$") then  return true  end
    puts("log", __LINE__() ,"-----trace-----sgement" , str ,context.input )

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

function S.init_func(env)
end
function S.fini_func(env)
end



local function component(env)
  local config = env:Config()
  -- definde prefix suffix  from name_space or local prefix suffix
  -- 加入 recognizer/patterns
  --local path= "recognizer/patterns/" .. env.name_space
  --local pattern = ("^%s[a-z]%s.*$"):format(prefix,suffix)
  --config:set_string(path, pattern)
  --puts("log",__FILE__(),__LINE__(),__FUNC__(), path, config:get_string(path),  "prefix" , prefix,"suffix" , suffix)

  -- 加入 lua_sgement
  local s_module= "english_seg"
  _G[s_module] = _G[s_module] or S
  local s_path= "engine/segmentors"
  local s_component= ("%s@%s@%s"):format( "lua_segmentor", s_module, env.name_space)
  if not config:find_index( s_path, s_component) then
    config:set_string(s_path .. "/@bedore 1", s_component )
  end


  -- 加入 lua_translator@english_tran@english
  local t_module = "english_tran"
  _G[t_module]= _G[t_module] or T
  local t_path= "engine/translators"
  local t_component= ("%s@%s@%s"):format( "lua_translator", t_module, env.name_space)
  if not config:find_index( t_path, t_component) then
    config:config_list_append( t_path, t_component )
  end

  -- 替換 uniquifier filter  --> lua_filter@uniquifier 或者加入

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

end

local P={}
function P.init(env)
  Env(env)
  local context=env:Context()
  --load_config(env)
  component(env)
  --recognizer/patterns/english: "^[a-zA-Z]+[*/:'._-].*"
  env.comp_key= KeyEvent("Tab")
  env.uncomp_key= KeyEvent("Shift+Tab")
  env.enable_key= KeyEvent("F10")
  context:set_option(English,false)
  env.history=List()

  env.commit=context.commit_notifier:connect(function(ctx)
    env.history:clear()
  end )

end
function P.fini(env)
  env.commit:disconnect()
end
function P.func(key,env)
  local Rejected,Accepted,Noop=0,1,2
  if key:release() or key:ctrl() or key:alt() then return Noop end
  local context=env:Context()
  local status=env:get_status()
  local key_char= key.keycode >= 0x20 and key.keycode < 128 and string.char( key.keycode) or ""

  -- reject
  -- match env.pattern
  -- english mode  and key ==  a
  if context:get_option(English)  then
    if context:is_composing() and key_char == " " then
      env.engine:commit_text( context.input .. " " )
      context:clear()
      return Accepted
    end
    if  context:is_composing() and key_char:match("^[%a'?*/:_,.%-]$") or  key_char:match("^[%a]$") then
      context:push_input(key_char)
      puts("trace",__FILE__(),__LINE__(), "----trace ----", key_char , context.input )
      return Accepted
    end
  end
  if key:eq(env.uncomp_key) and #env.history > 0  then
    context.input = env.history:pop()
    return Accepted
  end
  if key:eq(env.enable_key) then
    context:Toggle_option(English)
    context:refresh_non_confirmed_composition()
    return Accepted
  end
  if status.has_menu  then
    local cand=context:get_selected_candidate()
    if cand.type == env.name_space and key:eq(env.comp_key)  then
      env.history:push(context.input)
      context.input = cand.text
      return Accepted
    end
  end

  return Noop
end


return P
