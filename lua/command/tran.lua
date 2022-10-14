#! /usr/bin/env lua
--
-- tran.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
local Env= require 'tools/env_api'
local List= require 'tools/list'
local env_funcs={}
-- self == env
function env_funcs.reload(self)
  local schema=self.engine.schema
  self.engine:apply_schema( Schema(schema.schema_id) )
  -- reset()
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
  local context = env:Context()
  local config = env:Config()
  -- init options
  local options = List("ascii_mode","ascii_punct","_debug")
  -- load switches
  for i,elm in next, env:Config_get("switches") do
    if elm.name then
      options:push(elm.name)
    elseif elm.options then
      for i,selm in ipairs(elm.options) do
        options:push(selm)
      end
    end
  end
  env.options = options:reduce( function(elm,org)
    org[elm]= context:get_option(elm) or false
    return org
  end ,{})

  -- init propertys
  env.propertys= List("command","english","_error"):reduce(function(elm,org)
    org[elm] = context:get_property(elm)
    return org
  end ,{})

  -- init funcs
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
------------>
  -- init  notifier
  env.notifiers= List(
  -- saved option and property
  context.option_update_notifier:connect(function(ctx,name)
    env.options[name]= ctx:get_option(name) or false
  end),
  context.property_update_notifier:connect(function(ctx,name)
    env.propertys[name] = ctx:get_property( name ) or ""
  end),
  --  execute command when commit
  context.commit_notifier:connect(function(ctx)
    local cand=ctx:get_selected_candidate()
    local execute_str = cand and cand.type=="command" and cand.text=="" and cand.comment:split('%-%-')[1] -- cand.comment:match("^(.*)%-%-.*$")
    if execute_str  then
      Log(INFO, "command executestr",execute_str)
      env.commands:execute( execute_str)
    end
  end ),
  context.update_notifier:connect(function(ctx)
  end )
  )
end
function T.fini(env)
  -- disconnect notifier
  env.notifiers:each(function(elm) elm:disconnect() end)
end

function T.func(input,seg,env)
  if not seg:has_tag(env.name_space) then return end
  local ative_input= input:sub(2)
  for cmd in env.commands:iter(ative_input)   do
    local text,comment= cmd:split("%-%-"):unpack()
    --Log(DEBUG,type(cmd) , cmd,text,"--",comment)
    yield( Candidate(env.name_space, seg.start, seg._end , text , comment ))
  end
end
return T
