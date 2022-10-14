#! /usr/bin/env lua
--
-- proc.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
local List=require 'tools/list'
local Env = require 'tools/env_api'
local function convert_excape_char(str,escape_chars)
-- string:gsub(ESCAPECH, "%%%1")      -- ("abc.?*("):gsub(ESCAPECH,"%%%1")
  escape_chars = escape_chars or '%-.?()[*'
  escape_chars = '([' .. escape_chars .. '])'

  return str:gsub(escape_chars,"%%%1")
end

local MODNAME="conjunctive"
local pattern_str ="~~"
local rec_char= "BCH<>~"
--    ^"~~[BCH<>~]*$"
local rec_pattern = ("^%s[%s]*$"):format( convert_excape_char(pattern_str),
  convert_excape_char(rec_char) )

local function add_keybind(config,keybind)
  local path="key_binder/bindings"
  local keybind_list_size=config:get_list_size(path)
  for i=0, keybind_list_size-1 do
    local toggle_str =config:get_string( ("%s/@%s/toggle"):format(path,i) )
    if toggle_str == MODNAME then return end
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
  -- init lua_translator@conjunctive.tran@[env.name_space]
  local path= "engine/translators"
  local mod_name = MODNAME .. ".tran"
  rrequire(mod_name )
  local comp_name= ("lua_%s@%s@%s"):format("translator",mod_name,env.name_space)
  if not List(env:Config_get(path)):find_match(comp_name) then
    config:get_list(path):append(
      ConfigValue(comp_name).element 
      )
  end
  -- init lua_filter@conjunctive.filter@[env.name_space]
  local path= "engine/filters"
  local mod_name = MODNAME .. ".filter"
  rrequire(mod_name )
  local comp_name= ("lua_%s@%s@%s"):format("filter",mod_name,env.name_space)
  local flist=List(env:Config_get(path))
  if not flist:find_match(comp_name) then
    -- insert comp before  simplifire and uniquifier
    local index =flist:find_index(function(elm) 
      return elm:match("uniquifier") or elm:match('simplifier') 
    end) or #flist+1
    config:get_list(path):insert(index-1, 
      ConfigValue(comp_name).element 
    )
  end
end
local P={}



function P.component(env,name)
end

function P.init(env)
  Env(env)
  local config= env:Config()
  -- add  lua_translator@conjunctive
  components(env)

  -- add pattern "~~"
  config:set_string("recognizer/patterns/" .. MODNAME , rec_pattern)
  env.keys= env:get_keybinds(env.name_space)

  env.select_key= convert_excape_char( config:get_string("menu/alternative_select_keys") or "" )

  local escape_key = config:get_string(env.name_space .. "/escape_key") or ""
  env.escape_regex = ("^[%s%s ]$"):format(
    convert_excape_char( rec_char .. env.select_key .. " " .. escape_key) , "%d" )
  -- set alphabet string
  env.alphabet_regex= ("^[%s%s]$"):format(
   convert_excape_char( config:get_string("speller/alphabet") or "zyxwvutsrqponmlkjihgfedcba") )

  env.key_press=false
end

function P.fini(env)
end

function P.func(key, env)
  print()
  local Rejected,Accepted,Noop= 0,1,2

  local context = env.engine.context
  -- conjunctive enable / disable
  if key:eq(env.keys.toggle) then
    local con_state env:Toggle_option(MODNAME)
    if not con_state and context.input:match("^~~") then
      context:clear()
    end
    context:refresh_non_confirmed_composition()
    return Accepted
  end
  -- true(1) : disable  false(0) enable
  local conjunctive_mode = context:get_option(MODNAME) and not context:get_option("ascii_mode")
  if not conjunctive_mode then return Noop end

  local status= env:get_status()
  -- ascii  : #ascii == 1  or  ""
  local ascii=  key.modifier <=1  and key.keycode <128
    and string.char(key.keycode)
    or ""

  if status.empty and ascii == "~" then
    -- "~" 觸發聯想
    context.input= pattern_str
    return Accepted
  end
  -- 中斷聯想: 清除input  ~~ 不處理key
  if  context.input:match("^" .. pattern_str) then
    -- pass ~<>HBC  select_commit char and  escape_key
    if ascii:match(env.escape_regex) then
      --pass
    elseif ascii:match(env.alphabet_regex) or  ascii:match("^%p$") then
      context:clear()
    --
    elseif key:repr() == "Return" or key:repr() == "BackSpace" then
      context:clear()
      return Accepted
    -- elseif ascii:match(env.escape_regex) then
    else

    end
  end

  return Noop
end

return P
