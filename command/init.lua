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
local prefix="/"
local suffix=":"
local List=require 'tools/list'
local puts=require'tools/debugtool'
require 'tools/rime_api'

local env_funcs={}
-- self == env
function env_funcs.reload(self)
  local schema=self.engine.schema
  self.engine:apply_schema( Schema(schema.schema_id) )
end
function env_funcs.date(self)
  self.engine:commit_text( os.date() )
end
function env_funcs.date1(self)
  self.engine:commit_text( os.date("%Y-%m-%d") )
end
function env_funcs.menu_size(self,size)
  local config=self:Config()
  if type(size) ~= "number" then return end
  size = size < 10 and size or config:get_int("menu/page_size")
  config:set_int("menu/page_size",  size )
  env_funcs.reload(self)
end


local Command=require 'command/command_str'

-- preload option and property
local function load_data(env)
  context=env:Context()
  env.options = List("ascii_mode","ascii_punct")
  :reduce( function(elm,org)  org[elm]= context:get_option(elm) ;return org end ,{})
  env.propertys= List("command","english")
  :reduce(function(elm,org)  org[elm] = context:get_property(elm) ; return org end ,{})
  env.funcs=funcs

end
local T= {}
function T.init(env)

  Env(env)
  local context= env:Context()
  local config= env:Config()

  -- load data  funcs options propertys
  load_data(env)
  -- o:name toggle , true,false
  --
  env.commands= Command()
  env.commands:append("o", "option", context, env.options)
  env.commands:append("p", "property", context, env.propertys)
  env.commands:append("f", "func", env, env_funcs)
  env.commands:append("c", "config", config)






  -- init  notifier
  -- saved option and property
  env.option=context.option_update_notifier:connect(function(ctx,name)
    env.options[name]= ctx:get_option(name)
  end)
  env.property=context.property_update_notifier:connect(function(ctx,name)
    env.propertys[name] = ctx:get_property( name )
  end)
  --  execute command when commit
  env.commit=context.commit_notifier:connect(function(ctx)
    local cand=ctx:get_selected_candidate()
    local execute_str = cand and cand.type=="command" and cand.text=="" and cand.comment:match("^(.*)%-%-.*$")
    if execute_str  then
      puts("log", "command executestr",execute_str)
      env.commands:execute( execute_str)
    end

  end )
  env.update=context.update_notifier:connect(function(ctx)
  end )
end
function T.fini(env)
  -- disconnect notifier
  for i,v in next, { "commit", "update","property", "option" } do
    env[v]:disconnect()
  end
end

function T.func(input,seg,env)
  if not seg:has_tag(env.name_space) then return end
  local ative_input= input:sub(2)
  for cmd in env.commands:iter(ative_input)   do
    yield( Candidate(env.name_space, seg.start, seg._end , "" , cmd ))
  end
end
-- filetr of command
local F={}
function F.init(env)
  Env(env)
  local config = env:Config()
  env.tags = config:clone_configlist(env.name_space.. "/tags") or List()
  env.tags:push(env.name_space)
end
function F.fini(env)
end
function F.tags_match(seg,env)
  return  env.tags and env.tags:find(function(elm) return seg:has_tag(elm) end )
end
function F.func(inp,env)
  local context=env:Context()
  local ative_input= context.input:gsub("^" .. prefix , "" )
  for cand in inp:iter() do
    if cand.type == "command" and cand.comment:match( ative_input ) then
      yield(cand)
    end
  end
end

local function component(env)
  local config = env:Config()
  -- definde prefix suffix  from name_space or local prefix suffix
  prefix = config:get_string(env.name_space .. "/prefix" ) or prefix
  suffix = config:get_string(env.name_space .. "/suffix" ) or suffix
  -- 加入 recognizer/patterns
  local path= "recognizer/patterns/" .. env.name_space
  local pattern = ("^%s[a-z]%s.*$"):format(prefix,suffix)
  config:set_string(path, pattern)
  puts("log",__FILE__(),__LINE__(),__FUNC__(), path, config:get_string(path),  "prefix" , prefix,"suffix" , suffix)

  -- 加入 lua_translator@command
  local t_module = "command_tran"
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

  -- 加入 command filter  --> lua_filter@command_filter@command
  local c_module = "command_filter"
  local c_component= "lua_filter@" .. c_module .. "@" .. env.name_space
  _G[c_module] = _G[c_module] or F
  if not  config:find_index(f_path, c_component) then
    local findex= config:find_index(f_path, r_filter)
    if findex then
      -- insert before lua_filter@uniquifier
      config:config_list_insert(f_path,c_component, findex )
    end
  end

end
local P={}
function P.init(env)

  Env(env)
  --load_config(env)
  component(env)
  env.pattern= ("^%s%s%s.*$"):format(prefix,"[%a]", suffix )
  env.comp_key= KeyEvent("Tab")
  env.uncomp_key= KeyEvent("Shift+Tab")
  env.reload_key=KeyEvent("Control+r")



end
function P.fini(env)
end
function P.func(key,env)
  local Rejected,Accepted,Noop=0,1,2
  if key:release() or key:ctrl() or key:alt() then return Noop end
  local context=env:Context()
  local status=env:get_status()

  -- reject
  if not context.input:match(env.pattern) then return Noop end
  -- match env.pattern
  if key:eq(env.uncomp_key)  then
      context.input  = context.input:match("^(.*)[:/].*$")
      return Accepted
  end
  if status.has_menu  then
    local cand=context:get_selected_candidate()
    local comment= cand.comment:match( "^(.*)%-%-.*$")
    if key:eq(env.comp_key)  then
      context.input =  prefix .. comment
      return Accepted
    --elseif key:repr() == " " then
      --env.commonds:execute(comment)
      --return Accepted
    end
  end
  return Noop
end


return P
