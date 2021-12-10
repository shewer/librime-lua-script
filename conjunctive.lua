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

local List=require 'tools/list'
local puts = require 'tools/debugtool'



-- 使用者常用詞
local _HISTORY=List{
  "發性進行性失語",
  "發性症狀",
  "發性行性失語症狀",
  "發性進行失語症狀",
  "發進行性失症狀",
  "發性進行失語症狀",
  "性進行失語症狀",
  "發性行性失語症狀",
  "進行性失語症狀",
}

-- user define data
local pattern_str ="~~"
local rec_pattern = ("^%s%s$"):format(pattern_str,"[A-Z<>~]*$") 
local lua_tran_ns = "conjunctive"
local dict_file = 'essay.txt'
--dict_file= '/usr/share/rime-data/essay.txt'  -- debug
local switch_key ="F11"
local escape_key = "%.%-"
local path_ch= package.config:sub(1,1)

local Dict = require 'tools/dict'
_dict= Dict( "." .. path_ch .. dict_file)
or Dict( rime_api.get_user_data_dir() .. path_ch  .. dict_file)
or Dict( rime_api.get_shared_data_dir() .. path_ch .. dict_file)

local M={}

function M.init(env)
  env.dict= _dict or Dict("essay.txt")

  env.history=""
  env.history_back=""

  env.commit_connect= env.engine.context.commit_notifier
  :connect(
  function(ctx)
    local conjunctive_mode = not ctx:get_option(lua_tran_ns) and not ctx:get_option("ascii_mode")
    if not conjunctive_mode then return end

    local cand=ctx:get_selected_candidate()
    local command_mode= cand and "history" == cand.type  and "" == cand.text
    -- change env.history
    if command_mode then
      env.history_back=  env.history
      env.history = cand.comment:match("^(.*)[-][-].*$") or env.history
    end

    local commit_text= ctx:get_commit_text()
    if  #commit_text>0 and  ctx.input ~= commit_text then  
      env.history = env.history .. commit_text 
      env.history = env.history:utf8_sub(-10)
      --print( env.history, ctx.input , ctx:get_commit_text() )

      env.history_commit=  not env.dict:empty(env.history)
    end
  end )

  env.update_connect= env.engine.context.update_notifier
  :connect(
  function(ctx)
    if env.history_commit then
      env.history_commit=nil
      ctx.input=pattern_str
    end
  end )
end

function M.fini(env)
  env.commit_connect:disconnect()
  env.update_connect:disconnect()
end


function M.func(input,seg,env)
  local context = env.engine.context
  local history= env.history

  if context:get_option(lua_tran_ns) then return end  -- false: enable true: disable
  if not seg:has_tag(lua_tran_ns)  then return end

  -- start 

  local active_input = input:match("^".. pattern_str .. "(.*)$")
  if active_input == nil then return end

  if active_input == "C" then
    yield( Candidate("history", seg.start, seg._end, "", "--清除 (" .. history .. ")" ))
    yield( Candidate("history", seg.start, seg._end, "", env.history_back.. "--還原" ))

  elseif active_input == "B" then
    yield( Candidate("history", seg.start, seg._end, "", env.history_back.. "--還原" ))

  elseif active_input == "H" then
    _HISTORY:each(function(elm)
      yield( Candidate("history", seg.start, seg._end, elm, "--自選" ))
    end)

  elseif active_input:match("[<>~]+") then
    if #active_input >1 then
      active_input=active_input:sub(2)
      local si= #active_input:gsub("[^>]","") +1
      local ei= - #active_input:gsub("[^<~]","")
      history = history:utf8_sub(si,ei)
    end
    yield( Candidate("history", seg.start, seg._end, "", history .. "--修改" ))
  end

  for w ,wt in env.dict:reduce_iter(history) do
    yield( Candidate( lua_tran_ns , seg.start,seg._end, w, "(聯)") )
  end
end




-- option conjunctive enable(false ) disable(true)
local function add_keybind(config,keybind)
  local path="key_binder/bindings"
  local keybind_list_size=config:get_list_size(path)
  for i=0, keybind_list_size-1 do
    local toggle_str =config:get_string( ("%s/@%s/toggle"):format(path,i) )
    if toggle_str == lua_tran_ns then return end
  end
  local last_index=keybind_list_size
  for key,value in pairs(keybind) do
    local path =  ("%s/@%s/%s"):format(path,last_index,key)
    config:set_string(path,value)
  end
end


-- append  lua_translator@conjunctive 
local function components(env)
  local config=env:Config() 
  -- set module  "conjunctive"
  _G[lua_tran_ns]= _G[lua_tran_ns] or M
  -- add lua_translator after echo_translator before punct_translator
  local path= "engine/translators"
  local name= "lua_translator@" .. env.name_space 
  if not config:find_index(path,name) then 
    config:config_list_append(path, name)
  end 

  -- add pattern "~~"
  config:set_string("recognizer/patterns/" .. lua_tran_ns , rec_pattern) 

  -- register keybinder {when: "always",accept: switch_key, toggle: conjunctive }
  add_keybind(config, {when= "always", accept= switch_key, toggle= lua_tran_ns } )
end
local P={}



function P.component(env,name)
end 

function P.init(env)
  Env(env)
  assert(env.name_space == "conjunctive" , "name_space not match ( lua_processor@<module>@conjunctive)")
  local config= env:Config()
  -- add  lua_translator@conjunctive
  components(env)


  env.commit_select= ("^[ %s%s%s]$"):format(
     "%<%>CBHi%~", config:get_string("menu/alternative_select_keys") or "%d", escape_key )
  -- set alphabet string
  env.alphabet= config:get_string("speller/alphabet") or "zyxwvutsrqponmlkjihgfedcba"
  env.key_press=false
end

function P.fini(env)
end

function P.func(key, env)
  local Rejected,Accepted,Noop= 0,1,2
  
  local context = env.engine.context

  -- true(1) : disable  false(0) enable
  local conjunctive_mode = not context:get_option(lua_tran_ns) and not context:get_option("ascii_mode")
  if not conjunctive_mode then return Noop end

  local ascii=  key.modifier <=1 and key.keycode <128
  and string.char(key.keycode)
  or ""

  -- "~" 觸發聯想
  if not context:is_composing() and  ascii == "~" then
    context.input= pattern_str
    return Accepted
  end 
  -- 中斷聯想
  if  context.input:match("^" .. pattern_str) then
    if #ascii >0 and not ascii:match(env.commit_select) then 
      context:clear()
    end 
  end
  return Noop
end

return P
