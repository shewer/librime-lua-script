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
local Env = require 'tools/env_api'
local List=require 'tools/list'


local function component(env)
  local config = env.engine.schema.config
  -- definde prefix suffix  from name_space or local prefix suffix
  prefix = config:get_string(env.name_space .. "/prefix" ) or prefix
  suffix = config:get_string(env.name_space .. "/suffix" ) or suffix
  -- 加入 recognizer/patterns
  local path= "recognizer/patterns/" .. env.name_space
  local pattern = ("^%s[a-z]%s.*$"):format(prefix,suffix)
  config:set_string(path, pattern)

  -- 加入 lua_translator@command
  config:set_string("engine/translators/@next", "lua_translator@command.tran@".. env.name_space)

  do
    local flist=List(env:Config_get("engine/filters"))
    local uindex= flist:find_index("uniquifier") or 1
    local luindex= flist:find_index('lua_filter@uniquifier') or 1
    local uindex = math.max(uindex,luindex)
    table.insert(flist,uindex +1 ,"lua_filter@command.filter@" .. env.name_space)
    env:Config_set('engine/filters',flist)
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
    if comment and key:eq(env.comp_key)  then
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
