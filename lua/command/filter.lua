#! /usr/bin/env lua
--
-- filter.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--

local prefix="/"
local suffix=":"
local Env=require 'tools/env_api'
local List = require 'tools/list'
-- filetr of command
local F={}
function F.init(env)
  Env(env)
  local config = env:Config()
  env.tags = env:Get_tags() or List()
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
    if cand.type == "command" and cand.text:match( ative_input ) then
      local gcand = cand:get_genuine()
      gcand.comment= gcand.text .. "--" .. gcand.comment
      gcand.text=""
      yield(cand)
    end
  end
end
return F
