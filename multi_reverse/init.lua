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
  _schema[ env.engine.schema.schema_id ] = _schema[env.engine.schema.schema_id] or {}
  local g_backup = _schema[env.engine.schema.schema_id] 
  if not g_backup.filters  then 
    g_backup.filters = rime_api.clone_configlist(config,"engine/filters")
  end 
  
  -- register  lua_filter@completion_filter module 
  _G["completion_filter"] = require'multi_reverse/completion'
  -- register  lua_filter@multi_reverse_filter module 
  local module_name="multi_reverse_filter"
  _G[module_name]=require'multi_reverse/mfilter'
  local new_filter_list = 
 		List( "lua_filter@completion_filter") + 
		g_backup.filters + 
		env.trans_namespace:map(
		function(name_space) 
			return ("lua_filter@%s@%s"):format( module_name , name_space ) 
		end )
  new_filter_list:each(print)
  env.trans_namespace:each(print)
  -- update  new filtel component  engine/filters  
  rime_api.write_configlist(config,"engine/filters", new_filter_list)

  -- load key_binder file 
  env.keybind_tab=require 'multi_reverse/keybind_cfg'
  assert(env.keybind_tab)
  -- initialize option  and property  of multi_reverse
  context:set_option(Multi_reverse,false)
  print("------->-----< ------")
  context:set_option(Completion,true)
  context:set_option("qcode", true)
  -- init property multi_reverse= "translator" 
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
print(Multi_reverse .. "_processor")
--_G[Multi_reverse .. "_processor"] = M
_G["multi_reverse_processor"] = M

--assert( multi_reverse_processor, "multi_reverse_processor not dispear")

    --- "lua_processor@multi_reverse_processor"
return processor

