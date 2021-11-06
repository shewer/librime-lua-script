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
   engine/translators: lua_translator@conjunctive -- 
   recognizer/patterns/conjunctive:  "^" .. pattern_str  觸發 tag 
--]]








-- user define data
local pattern_str="~~"
local lua_tran_ns="conjunctive"
local dict_file= 'essay.txt'
--dict_file= '/usr/share/rime-data/essay.txt'  -- debug
local switch_key="F11"


local Dict = require 'tools/dict'
_dict= Dict(dict_file)

local M={}
_G[lua_tran_ns]=M
function M.init(env)
  env.dict= _dict or Dict("essay.txt")
  env.history=""
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
    ctx.input=pattern_str
  end )
end

function M.fini(env)
  env.commit_connect:disconnect()
  env.update_connect:disconnect()
end

function M.func(input,seg,env)
  local context = env.engine.context
  if context:get_option(lua_tran_ns) then return end  -- false: enable true: disable 
  if not seg:has_tag(lua_tran_ns)  then return end

  env.dict:reduce_find_word(env.history):each(
  function(elm)
    yield( Candidate( lua_tran_ns , seg.start,seg._end, elm, "聯") )
  end )
end



local function print_config(config)
  local puts = print -- log and log.info or print
  local function list_print(conf,path)
    puts( "------- " .. path .. " --------")
    for i=0, conf:get_list_size(path) -1 do 
      path_i= path .. "/@" .. i 
      puts( 
        ("%s: %s"):format(path_i, conf:get_string(path_i) )  
      )
    end 
  end 

  for i,p in ipairs{"processors","segmentors","translators","filters"} do 
    list_print(config, "engine/" .. p )
  end 
end 
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


local function add_component_tran(config,component_str)
  local tran_path= "engine/translators"
  component_str=  component_str or "lua_translator@" .. lua_tran_ns
  local punct_str= "punct_translator"
  local echo_str= "echo_translator"
  local punct_i,echo_i

  local trans_list_size = config:get_list_size(tran_path)
  for i=0,trans_list_size-1 do
    local tran= config:get_string( ("%s/@%s"):format(tran_path, i) ) or ""
    echo_i = ( not echo_i and  tran:match(echo_str) ) and i or echo_i
    punct_i = ( not punct_i and tran:match(punct_str) ) and i or punct_i
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
  config:set_string("recognizer/patterns/" .. lua_tran_ns , "^" .. pattern_str )

  -- register keybinder {when: "always",accept: switch_key, toggle: conjunctive }
  add_keybind(config, {when= "always", accept= switch_key, toggle= lua_tran_ns } )
  -- add lua_translator after echo_translator before punct_translator
  add_component_tran(config, "lua_translator@" .. lua_tran_ns )
  -- print compoments
  print_config(config)
  local pattern_p= "recognizer/patterns/" .. lua_tran_ns 
  print( pattern_p , config:get_string(pattern_p ) )

end

function P.fini(env)
end

function P.func(key, env)
  local Rejected,Accepted,Noop= 0,1,2 
  local context = env.engine.context
  if context:get_option("ascii_mode") then return Noop end
  --print("-----key repr---:", key:repr(),key.keycode, key.modifier )
  --local keyt=KeyEvent("Shift+grave")
  --print("----test-key repr---:", keyt:repr(),keyt.keycode, keyt.modifier )
  local ascii=  key.modifier == 0 and key.keycode <128 
       and string.char(key.keycode) 
      or ""

  if not context:is_composing() and ascii == "~" then 
    print("-----------in ~")
    context.input= pattern_str
    return Accepted 
  end 
  -- 中斷聯想
  if context.input:match("^" .. pattern_str) then 
    if not context:has_menu() then 
      context:clear() 
      return Noop
    else
      local cand= context:get_selected_candidate()
      if cand and cand.text == pattern_str then 
        context:clear()
        return Noop
      end 
    end 

    if ascii:match("^[" .. env.alphabet .. "]$" ) then
      context:clear()
      return Noop
    end 
  end
  return Noop
end

return P

