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
local funcs={}
function funcs.reload(self)
  local schema=self.engien.scheam
  self.engine:apply_schema( Schema(schema.schema_id) )
end 


local Command=require 'command/command_str'

-- preload option and property 
local function load_data(env)
  context=env:Context()
  env.options = List("ascii_mode","ascii_punct")
  :reduce( function(elm,org)  org[elm]= context:get_option(elm) ;return org end ,{})
  env.propertys= List("command","english")
  :reduce(function(elm,org)  org[elm] = context:get_property(elm) ; return org end ,{})
  env.funcs= {
    reload = function(env) env.engine:apply_schema(Schema( engine.schema.schema_id )) end ,
  }
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
  env.commands:append("o",context,"option",env.options)
  env.commands:append("p",context,"property",env.propertys)
  env.commands:append("f",env,"func",env.funcs)
  env.commands:append("c",config,"config")






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
    env.execute_str = cand.type=="command" and cand.text=="" and cand.comment:match("^(.*)%-%-.*$")
  end )
  env.update=context.update_notifier:connect(function(ctx)
    if env.execute_str  then 
      env.commands:execute( env.execute_str)
      env.execute_str=nil
    end 
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
  _G["command_tran"]= _G["command_tran"] or T 
  config:config_list_append( "engine/translators", "lua_translator@command_tran@" .. env.name_space )

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
  

end
function P.fini(env)
end
function P.func(key,env)
  local Rejected,Accepted,Noop=0,1,2
  local context=env:Context()
  context.input:match("") 
  

  return Noop
end 


return P
