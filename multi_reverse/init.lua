#! /usr/bin/env lua
--
-- processor.lua
-- Copyright (C) 2021 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
local List=require'tools/list'
require 'tools/rime_api'
local MultiSwitch=require'multi_reverse/multiswitch'
_G["_schema"]={}

local Multi_reverse='multi_reverse'
local Completion="completion"
local Qcode="qcode"




-- get name_space of table_translator and script_translator
local function get_trans_namespace(config)
  local path="engine/translators"
  local list= rime_api.clone_configlist(config,path)
  local ms=MultiSwitch("translator")
  return list:reduce(
    function(tran,org)
      local  tran_ns= tran:match( "^[ts].*_translator@([%a_][%w_]*)$")
      --  escape  nil  and "vcode"
      return  (tran_ns and tran_ns ~= "vcode") and
	org:push(tran_ns) or
	org
    end  , ms   )
end


local M={}
function M.init(env)
  local Rejected, Accepted, Noop = 0,1,2
  local config=env.engine.schema.config
  local context=env.engine.context
  -- namespace switch
  env.trans_namespace= get_trans_namespace(config)

  -- backup _schema[ schemd_id].filters of ConfigList of "engine/filters"
  local schema_id= env.engine.schema.schema_id
  _schema[ schema_id ] = _schema[schema_id] or {}
  _schema[schema_id].filters=
    _schema[schema_id].filters or
    rime_api.clone_configlist(config,"engine/filters")

  -- chcek filter module
  assert( _G[Multi_reverse .. "_filter"], Multi_reverse .. "_filter" .. " table not appear in global." )
  assert( _G[Completion .. "_filter"],  Completion .. "_filter" .. " table not appear in global." )
  -- add completion multi_reverse filter to "engine/filters"
  local new_filter_list =
    List( ("lua_filter@%s_filter"):format(Completion) ) +
    _schema[schema_id].filters +
    env.trans_namespace:map(
      function(name_space)
	return ("lua_filter@%s_filter@%s"):format( Multi_reverse , name_space )
      end
    )

  new_filter_list:each_with_index(
    function(elm,i)
      log.info( ("new engine/filters list of (%s): %s "):format( i , elm ) )
    end
  )
  rime_api.write_configlist(config,"engine/filters", new_filter_list)

  -- load key_binder file
  env.keybind_tab=require 'multi_reverse/keybind_cfg'
  assert(env.keybind_tab)

  -- initialize option  and property  of multi_reverse
  context:set_option(Multi_reverse,true)
  context:set_option(Completion,true)
  context:set_option("qcode", true)
  context:set_property(Multi_reverse, env.trans_namespace:status() )
end

function M.fini(env)
  local g_backup= _schema[env.engine.schema.schema_id].filters
  if g_backup and type(g_backup) == table then
    write_configlist(env.schema.config,"engine/filters",g_backup)
  end
end

function M.func(keyevent,env)
  -- 類似 key_binder 參數模式
  return   env.keybind_tab:action(keyevent,env)
end

-- add module
_G[Completion .. "_filter"] = require'multi_reverse/completion'
_G[Multi_reverse .. "_filter"]=require'multi_reverse/mfilter'
_G[Multi_reverse .. "_processor"] = M
assert( multi_reverse_processor and multi_reverse_filter and completion_filter, Multi_reverse .. "module require failed." )

return multi_reverse_processor and multi_reverse_filter and completion_filter
