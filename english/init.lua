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

local puts = require 'tools/debugtool'
local T= require'english/english_tran'
-- filetr of command

local function component(env)
  local config = env:Config()
  -- definde prefix suffix  from name_space or local prefix suffix
  -- 加入 recognizer/patterns
  --local path= "recognizer/patterns/" .. env.name_space
  --local pattern = ("^%s[a-z]%s.*$"):format(prefix,suffix)
  --config:set_string(path, pattern)
  --puts("log",__FILE__(),__LINE__(),__FUNC__(), path, config:get_string(path),  "prefix" , prefix,"suffix" , suffix)

  -- 加入 lua_translator@english_tran@english
  local t_module = "english_tran"
  _G[t_module]= _G[t_module] or T
  local t_path= "engine/translators"
  local t_component=  ("%s@%s@%s"):format( "lua_translator", t_module, env.name_space)
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
  local context=env:Context()
  local status=env:get_status()
  

  -- reject 
  -- match env.pattern 
  if key:eq(env.uncomp_key) and #env.history > 0  then 
      context.input = env.history:pop()
      return Accepted
  end 
  if status.has_menu  then 
    local cand=context:get_selected_candidate()
    if cand.type ~= env.name_space then  return Noop end 
    if key:repr():match("^[,. ]$") then 
      context:push( key:repr() ) 
      env.engine:commit_text( context.input .. key:repr() )
      context:clear()

    end 
      
    if key:eq(env.comp_key)  then 
        env.history:push(context.input)
        context.input = cand.text
        return Accepted
    end 
  else
  end 

  return Noop
end


return P
