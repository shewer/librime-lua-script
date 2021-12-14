#! /usr/bin/env lua
--
-- processor.lua
-- Copyright (C) 2021 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
-- 自動加載 多字典反查碼filter
--
-- lua_processor@multi_reverse   -- create lua_filter as below
-- lua_processor@multi_reverse   -- create lua_filter as below
-- lua_filter@completion --  過濾 completion  switch   option: completion
-- lua_filter@completion --  過濾 completion  switch   option: completion
-- lua_filter@multi_reverse@name_space_of_translation(script & table)  -- 使用 property: multi_reverse= name_space  轉換目的反查碼
--
--
--
--
local puts=require'tools/debugtool'
local List=require'tools/list'
require 'tools/rime_api'

local Multi_reverse='multi_reverse'
local Multi_reverse_sw="Control+6"
local Multi_reverse_next="Control+9"
local Multi_reverse_prev="Control+0"
local Completion="completion"
local Completion_sw="Control+8"
local Qcode="qcode"
local Qcode_sw="Control+7"


-- get name_space of table_translator and script_translator
local function get_trans_namespace(config)
  local path="engine/translators"

  local t_list=config:clone_configlist(path)
  :select( function(tran)
    local f=not tran:match("vcode$") and (  tran:match("^script_translator@") or tran:match("^table_translator@") )
    return  not tran:match("vcode$") and (  tran:match("^script_translator@") or tran:match("^table_translator@") )
  end )
  :map( function(tran)
    local ns= assert(tran:match("@([%a_][%a%d_]*)$"),"tran not match")
    return ns
  end )
  t_list:unshift( "translator" )
  return t_list
end

local FC= require 'multi_reverse/completion'
local FM= require 'multi_reverse/mfilter'

local function component(env)
  local config= env:Config()
  local t_path="engine/translators"
  local f_path="engine/filters"
  -- append  lua_filter@completion
  -- append  lua_filter@completion
  _G[Completion] = _G[Completion] or FC or require 'multi_reverse/completion'
  if not config:find_index(f_path, "lua_filter@" .. Completion ) then
  if not config:find_index(f_path, "lua_filter@" .. Completion ) then
    config:set_string( f_path .. "/@before 0" , "lua_filter@" .. Completion   )
  end
  end
  -- append lua_filter@multi_reverse@<name_space>
  _G[Multi_reverse] = _G[Multi_reverse] or FM or require 'multi_reverse/multi_reverse'
  _=get_trans_namespace(config)
  :map( function(elm)
    local f_multi= "lua_filter@" .. Multi_reverse .. "@" .. elm
    if not config:find_index(f_path, f_multi ) then
    if not config:find_index(f_path, f_multi ) then
      local index = config:get_list_size( f_path )
      local index = config:get_list_size( f_path )
      config:set_string( f_path .. "/@before ".. index - 1 , f_multi )
    end
    end
  end)
end

local P={}
function P.init(env)
  Env(env)
  local context=env:Context()
  local config= env:Config()
  component(env)

  -- load key_binder file
  --env.keybind_tab=require 'multi_reverse/keybind_cfg'
  --assert(env.keybind_tab)

  local MultiSwitch=require'multi_reverse/multiswitch'
  env.trans= MultiSwitch( get_trans_namespace(config) )
  env.keys={}
  env.keys.next= KeyEvent(Multi_reverse_next)
  env.keys.prev= KeyEvent(Multi_reverse_prev)
  env.keys.m_sw= KeyEvent(Multi_reverse_sw)
  env.keys.completion= KeyEvent(Completion_sw)
  env.keys.qcode= KeyEvent(Qcode_sw)

  -- initialize option  and property  of multi_reverse
  context:set_option(Multi_reverse,true)
  context:set_option(Completion,true)
  context:set_option(Qcode, true)
  context:set_property(Multi_reverse, env.trans:status() )
end

function P.fini(env)
  --[[
  local g_backup= _schema[env.engine.schema.schema_id].filters
  if g_backup and type(g_backup) == table then
    write_configlist(env.schema.config,"engine/filters",g_backup)
  end
  --]]
end

function P.func(key,env)
  local Rejected,Accepted,Noop=0,1,2
  local context= env:Context()

  local status= env:get_status()
  --if true then return Noop end
  if key:eq(env.keys.next)  then
    context:set_property(Multi_reverse, env.trans:next())
    context:refresh_non_confirmed_composition()
    return Accepted
  elseif key:eq(env.keys.prev) then
    context:set_property(Multi_reverse, env.trans:prev())
    context:refresh_non_confirmed_composition()
    return Accepted
  elseif key:eq(env.keys.m_sw) then
    context:set_property(Multi_reverse, env.trans:toggle())
    context:refresh_non_confirmed_composition()
    return Accepted
  elseif key:eq(env.keys.qcode) then
    context:Toggle_option(Qcode)
    context:refresh_non_confirmed_composition()
    return Accepted
  elseif key:eq(env.keys.completion) then
    context:Toggle_option(Completion)
    context:refresh_non_confirmed_composition()
    return Accepted
  else
    return Noop
  end
end

-- add module

return P
