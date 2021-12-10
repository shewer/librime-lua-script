#! /usr/bin/env lua
--
-- init.lua
-- Copyright (C) 2021 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
local prefix="/"
local suffix=":"
local List=require 'tools/list'
require 'tools/rime_api'
local funcs={}
function funcs.reload(self)
  local schema=self.engien.scheam
  self.engine:apply_schema( Schema(schema.schema_id) )
end 


local T= {}
local Command=require 'command/command_str'
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
function T.init(env)

  Env(env)
  local context= env:Context() 
  local config= env:Config()
  config:config_list_append(  "uniquifier/reject_tags", env.name_space ) 
  print("******>", __FILE__(),__LINE__(), config:get_list("uniquifier/reject_tags").size, env.name_space )

  -- load data  funcs options propertys
  load_data(env) 
  -- o:name toggle , true,false
  --
  env.commands= Command() 
  env.commands:append("o",context,"option",env.options)
  env.commands:append("p",context,"property",env.propertys)
  env.commands:append("f",env,"func",env.funcs)
  env.commands:append("c",config,"config")







  env.option=context.option_update_notifier:connect(function(ctx,name)

    env.options[name]= ctx:get_option(name)  
    print("======option_notifier",__FILE__(),__LINE__(),__FUNC__(),name,ctx:get_option(name),env.options[name] )
  end)
  env.property=context.property_update_notifier:connect(function(ctx,name)
    env.propertys[name] = ctx:get_property( name )
    print("======property_notifier",__FILE__(),__LINE__(),__FUNC__(),name,ctx:get_property(name),env.propertys[name] )
  end)
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
  print("=======>>>OOOO<<<<<<<<",__FILE__(),__LINE__(),__FUNC__())
end
function T.fini(env)
  for i,v in next, { "commit", "update","property", "option" } do
    env[v]:disconnect() 
  end 
end

function T.func(input,seg,env)
  if not seg:has_tag(env.name_space) then return end 
  print("=======>>>OOOO<<<<<<<<",__FILE__(),__LINE__(),__FUNC__(),seg:has_tag(env.name_space))
  local ative_input= input:sub(2)
  for cmd in env.commands:iter(ative_input)   do 
    yield( Candidate(env.name_space, seg.start, seg._end , "" , cmd ))
  end
end 

local F={}
function F.init(env)

  Env(env)
  print("=======>>>OOOO<<<<<<<<",__FILE__(),__LINE__(),__FUNC__())
  local config = env:Config()
  print("=======>>>OOOO<<<<<<<<",__FILE__(),__LINE__(),__FUNC__(),config)
  env.tags = config:clone_configlist(env.name_space.. "/tags") or List()
  env.tags:push(env.name_space)
end
function F.fini(env)
end

function F.tags_match(seg,env)
  if env.tags and env.tags:find(function(elm) return seg:has_tag(elm) end ) then 
    return true
  end 
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

local function load_config(env)
  config=env.engine.schema.config
  prefix = config:get_string(env.name_space .. "/prefix" ) or prefix 
  suffix = config:get_string(env.name_space .. "/suffix" ) or suffix 
end 

local function component(env)
  local config = env:Config() 
  -- 加入 recognizer/patterns 
  config:set_string("recognizer/patterns/command","^" .. prefix .. "[a-z]".. suffix ..".*$") 
  -- 加入 lua_translator@command
  _G["command_tran"]= _G["command_tran"] or T 
  print("--->",__FILE__(),__FUNC__(),__LINE__())
  config:config_list_append( "engine/translators", "lua_translator@command_tran@command" )
  print("--->",__FILE__(),__FUNC__(),__LINE__(), prefix, suffix)
  -- 替換 uniquifier filter  --> lua_filter@uniquifier 
  _G["uniquifier"] = _G["uniquifier"] or require("component/uniquifier")
  print("--->",__FILE__(),__FUNC__(),__LINE__(), prefix, suffix, _G["uniquifier"])
  config:config_list_replace("engine/filters", "uniquifier", "lua_filter@uniquifier")
  print("--->",__FILE__(),__FUNC__(),__LINE__(), prefix, suffix, _G["uniquifier"])


  -- 加入 command filter  --> lua_filter@command_filter@command
  _G["command_filter"] = _G["command_filter"] or F
  print("--->",__FILE__(),__FUNC__(),__LINE__(),config.find_index) 
  local findex= config:find_index("engine/filters","lua_filter@uniquifier" )
  print("--->",__FILE__(),__FUNC__(),__LINE__(), prefix, suffix, _G["uniquifier"])
  if findex then 
    config:config_list_insert("engine/filters", "lua_filter@command_filter@command",findex )
  end
  print("--->",__FILE__(),__FUNC__(),__LINE__(), prefix, suffix, _G["uniquifier"])

end 
local P={}
function P.init(env)
  
  Env(env)
  load_config(env)
  print("--->",__FILE__(),__FUNC__(),__LINE__())
  component(env)
  print("--->",__FILE__(),__FUNC__(),__LINE__())
  

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
