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








-- user define data
local pattern_str="~"
local lua_tran_ns="conjunctive"
local dict_file= 'essay.txt'
--dict_file= '/usr/share/rime-data/essay.txt'  -- debug
local switch_key="F11"



-- option conjunctive enable(false ) disable(true)
local function add_keybind(config,keybind)
  local path="key_binder/bindings"
  local keybind_list=config:get_list(path)
  for i=0, keybind_list.size-1 do
    local toggle_str =config:get_string( ("%s/@%s/%s"):format(path,i,"toggle") )
    if toggle_str == lua_tran_ns then return end
  end
  local last_index=keybind_list.size
  for k,v in pairs(keybind) do
    config:set_string( ("%s/@%s/%s"):format(path,last_index,k),v)
  end
end

local Dict = require 'tools/dict'
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
    if ctx:get_option(lua_tran_ns) or ctx.input == ctx:get_commit_text()  then return end
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
  local context = env.engine.context
  local sw = not context:get_option(lua_tran_ns)
  if not ( seg:has_tag(lua_tran_ns) and sw ) then return end

  env.dict:reduce_find_word(env.history):each(
  function(elm)
    yield( Candidate( lua_tran_ns , seg.start,seg._end, elm, ""))
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
  print("--------", "recongnizer", "-------------")
  print( "recognizer/patterns/" , config:get_string("recognizer/patterns/" .. lua_tran_ns))
end
local function add_component_tran(config,component_str)
  local tran_path= "engine/translators"
  component_str=  component_str or "lua_translator@" .. lua_tran_ns
  local punct_str= "punct_translator"
  local echo_str= "echo_translator"
  local punct_i,echo_str_i

  local trans_list = config:get_list(tran_path)
  for i=0,trans_list.size-1 do
    local tran= config:get_string( ("%s/@%s"):format(tran_path, i) ) or ""
    echo_i = tran:match(echo_str) and i or echo_i
    punct_i = tran:match(punct_str) and i or punct_i
    if tran:match(component_str) then return end
  end
  local index = echo_i and  echo_i +1 or 0  -- index < echo_i
  index = punct_i  and index >=punct_i and index or punct_i  -- index >= punct_i
  config:set_string( tran_path .. "/@before " .. index, component_str )
end

local P={}

function P.init(env)
  local config=env.engine.schema.config

  -- set module  "conjunctive"
  _G[lua_tran_ns]= _G[lua_tran_ns] or M
  -- set alphabet string
  env.alphabet= config:get_string("speller/alphabet") or "zyxwvutsrqponmlkjihgfedcba"

  -- register recognizer/patterns/conjunctive  "^" .. pattern_str
  local pattern= config:get_string("recognizer/patterns/" .. lua_tran_ns )
  or  "^" .. pattern_str
  config:set_string("recognizer/patterns/conjunctive",pattern)

  -- register keybinder {when: "always",accept: switch_key, toggle: conjunctive }
  add_keybind(config, {when= "always", accept= switch_key, toggle= lua_tran_ns } )
  -- add lua_translator after echo_translator before punct_translator
  add_component_tran(config, "lua_translator@" .. lua_tran_ns )

  print_config(config)

end

function P.fini(env)
end

function P.func(key, env)
  local context = env.engine.context
  if context:get_option("ascii_mode") then return 2 end

  -- 中斷聯想
  if context.input:match("^" .. pattern_str)
    and key:repr():match("^[" .. env.alphabet .. "]$" ) then
    context:clear()
    return 2
  end
  return 2
end

return P

