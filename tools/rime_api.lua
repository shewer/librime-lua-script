#! /usr/bin/env lua
--
-- tools/rime_api.lua
-- 補足 librime_lua 接口 不便性
-- Copyright (C) 2020 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
--------------------------------------------

-- ex:
--     local api=require 'tools/rime_api'
--     api.status(env)
--
-- ex2: setmetatable in env
--     setmetatable(env,{__index= require('tools/rime_api') })
--     table env:status()
--     bool env:get_option(name)
--     bool env:set_option(name,bool)  bool default true
--     bool env:set_option(name)
--     bool env:toggle_option(name)
--     string env:set_property(name,string)
--     string env:get_property(name)
--
--

local function chk_newver()
  return Projection and true or false
end
local List = require'tools/list'
local M=rime_api

-- 取得 librime 狀態 tab { always=true ....}
-- 須要 新舊版 差異  comp.empty() -->  comp:empty()
function M.get_status(ctx)
  --local ctx= env.engine.context
  local stat={}
  local comp= ctx.composition
  stat.always=true
  stat.composing= ctx:is_composing()
  stat.empty= not stat.composing
  stat.has_menu= ctx:has_menu()
  -- old version check ( Projection userdata)
  local ok,empty
  if not chk_newver() then
    ok,empty = pcall(comp.empty)
    empty=  ok  and empty or comp:empty() --  empty=  ( ok ) ? empty : comp:empty()
  else
    empty = comp:empty()
  end
  stat.paging= not empty and comp:back():has_tag("paging")
  return stat
end

function M.get_option(env,name)
  return env.engine.context:get_option(name)
end
function M.set_option(env,name,bool)
  bool = bool and true or false
  env.engine.context:set_option(name,bool)
  return true
end
function M.unset_option(env,name)
  env.engine.context:set_option(name,false)
  return false
end
function M.toggle_option(env,name)
  local bool = env.engine.context:get_option(name)
  env.engine.context:set_option(name , not bool )
  return not bool
end
function M.set_property(env,name,string)
  string = string or ""
  if type(name) == "string" then
    env.engine.context:set_property(name,string)
    return string
  else
    return false
  end
end

function M.get_property(env,name)
  return type(name) == "string" and
    env.engine.context:get_property(name) or
    nil
end
--  filter tools
function M.load_reversedb(dict_name)
  -- loaded  ReverseDb
  local reverse_filename = "build/"  ..  dict_name .. ".reverse.bin"
  local reversedb= ReverseDb( reverse_filename )
  if not reversedb then
    log.warning( env.name_space .. ": can't load  Reversedb : " .. reverse_filename )
  end
  return reversedb
end

-- clone ConfigList of string to List

function M.clone_configlist(config,path) if not config:is_list(path) then
    log.warning( "clone_configlist: ( " .. path  ..  " ) was not a ConfigList " )
    return nil
  end

  local list=List()
  for i=0, config:get_list_size(path)-1 do
    list:push( config:get_string( path .. "/@" .. i ) )
  end
  return list
end
-- List write to Config
function M.write_configlist(config,path,list)
  list:each_with_index(
  function(config_string,i)
    config:set_string( path .. "/@" .. i-1 , config_string)
  end )
  return #list
end

--  舊的版本 使用 lua_function  轉換  且 模擬 :apply(str) 接口
function M.old_load_projection(config,path)
  local patterns=clone_configlist(config,path)
  local make_pattern=require 'tools/pattern'
  local projection = patterns:map(function(pattern) return make_pattern(pattorn) end )
  -- signtone
  function projection:apply(str)
    return self:reduce(
    function(pattern_func,org) return pattern_func(org) end , str )
  end
  return projection
end

--
function M.load_projection( config, path)
  --  old version
  if not chk_newver() then
    return M.old_projection(config,path)
  end

  local patterns= config:get_list( path )
  local projection= Projection()
  if  patterns then
    projection:load(patterns)
  else
    log.warning( "lua_filter: " .. path  ..
      " projection of comment_format could not loaded. comment_format type: " ..
      tostring(patterns) )
  end
  return projection
end

return M
