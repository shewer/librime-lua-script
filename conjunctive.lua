#! /usr/bin/env lua
--
-- conjunctive.lua
-- Copyright (C) 2021 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
--[[

-- rime.lua
conjunctive_proc= require 'conjunctive'


---  custom.yaml
patch:
  engine/processors/@after 0: lua_processor@conjunctive_proc 



這個模塊會自動建立 
   engine/translators: lua_translator@conjunctive   
   recognizer/patterns/conjunctive:  "^" .. pattern_str 
--]]








local Dict = require 'tools/dict'
--print(rime_api.get_user_data_dir(), "essay.txt" )
--print(rime_api.get_shared_data_dir(), "essay.txt" )
--_dict= Dict('/usr/share/rime-data/essay.txt')
-- user define data 
local pattern_str="Z"
local lua_tran_ns="conjunctive"
local dict_file= 'essay.txt'



_dict= Dict(dict_file)

local M={}
_G[lua_tran_ns]=M
function M.init(env)
  env.dict= _dict or Dict("essay.txt")
  env.history=""
  env.send_key= KeyEvent(pattern_str)
  env.commit=nil

  env.commit_connect= env.engine.context.commit_notifier
  :connect(
  function(ctx)
    if ctx.input == ctx:get_commit_text()  then return end 
    env.commit=true
    local hstr= (env.history .. ctx:get_commit_text() or "" )
    env.history= hstr:sub( utf8.offset(hstr,-10) or 1  )
  end )

  env.update_connect= env.engine.context.update_notifier
  :connect(
  function(ctx)
    if not env.commit then return end 
    env.commit=nil
    env.engine:process_key( env.send_key )
  end )
end 

function M.fini(env)
  env.commit_connect:disconnect()
  env.update_connect:disconnect()
end

function M.func(input,seg,env)
  if not seg:has_tag( lua_tran_ns ) then return end 
  env.dict:reduce_find_word(env.history):each(
  function(elm)
    yield( Candidate( "--", seg.start,seg._end, elm, ""))
  end )
  --env.engine.context.input=""
  --env.engine.context:clear()
end



local function print_config(config)
  local procs_p="engine/processors"
  local trans_p ="engine/translators"

  print("--------", procs_p, "-------------")
  local processor = config:get_list(procs_p)
  for i=0,processor.size-1 do 
    print( processor:get_value_at(i).value)
  end
  print("--------", trans_p, "-------------")
  local translator= config:get_list(trans_p)
  for i=0,translator.size-1 do
    print(translator:get_value_at(i).value)
  end 
  print( "recognizer/patterns/" , config:get_string("recognizer/patterns/" .. lua_tran_ns)) 
end 

local P={}

function P.init(env)
  local config=env.engine.schema.config

  -- set module  "conjunctive"
  _G[lua_tran_ns]= _G[lua_tran_ns] or M 
  -- set alphabet string 
  env.alphabet=
  config:get_string("speller/alphabet") 
  or "zyxwvutsrqponmlkjihgfedcba"

  -- set recognizer/patterns/conjunctive  "^" .. pattern_str
  local pattern= config:get_string("recognizer/patterns/" .. lua_tran_ns )
  or  "^" .. pattern_str 
  config:set_string("recognizer/patterns/conjunctive",pattern)

  -- check   "lua_translator@" .. lua_tran_ns in engine/translators 
  local trans_list = config:get_list("engine/translators")

  for i=0,trans_list.size-1 do 
    local tran= trans_list:get_value_at(i).value:match( "lua_translator@" .. lua_tran_ns ) 
    if tran then 
      return 
    end 
  end 
  -- if not then append  "lua_translator@" .. lua_tran_ns in engine/translators 
  config:set_string( 
  "engine/translators/@" .. tostring(trans_list.size),
  "lua_translator@" .. lua_tran_ns )

end

function P.fini(env)
end

function P.func(key, env)
  local context = env.engine.context
  if context:get_option("ascii_mode") then return 2 end 
  --if context.input == context:get_commit_text() then 
  --  context:clear() 
  --  return 2
  --end 
  if context.input== pattern_str and env.alphabet:match(key:repr() ) then 

    context:clear()
    return 2
  end 
  --if context:get_option("ascii_mode") then return 2 end

  --if context.input== "Z" and not context:has_menu() then 
  --context:clear()
  --return 2
  --end 
  return 2

end
return P

