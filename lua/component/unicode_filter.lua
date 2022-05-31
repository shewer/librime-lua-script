#! /usr/bin/env lua
--
-- unicode_filter.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
-- lua_filter@unicode_filter   : name_space default unicode
-- tags:
--
-- option : name_space
--
--
local puts = require 'tools/debugtool'

-- load <name_space>/tags to table
local function get_tags(env)
  local tags=env.engine.schema.config:get_list(env.name_space .. "/tags")
  if not tags  then return end
  local tags_tab= {}
  for i=0,tags.size-1 do
    table.insert(tags_tab, tags:get_value_at(i) )
  end
  return Set(tags_tab)
end
-- orgin tags_match
local function _tags_match( segment, env)
  assert( env.tags == nil or type(env.tags)=="table",
    "mfilter.lua:" .. __LINE__()..  " :env.tags data type error")
  local tab=  type(env.tags) == "table" and env.tags or {}
  if #tab < 1 then return true end  --  tab  size ==0  如果 無tags 表示 全符合
  for i,v in ipairs(tab) do
    if segment:has_tag( v ) then
      return true
    end
  end
  return false
end
local M={}

function M.tags_match(segment,env)
  if env.engine.context:get_option(env.name_space) then
    return not env.tags and true or (segment.tags * env.tags):empty()
  end
  return false
end

function M.init(env)
  env.name_space = env.name_space:match("^(unicode)_filter$") or env.name_space
  env.tags=get_tags(env) 
end
function M.fini(env)
end

local function ucode(text)
  if not text or #text <1 then return "" end
  local str=""
  for i,code in utf8.codes(text) do
    str = string.format("%s U%x ",str,code)
  end
  return " [".. str .."]"
end
function M.func(inp,env)
  for cand in inp:iter() do
    cand.comment = cand.comment .. ucode(cand.text) 
    yield(cand)
  end
end

return M
