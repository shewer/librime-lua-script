#! /usr/bin/env lua
--
-- stroke_count.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--[[
# custom.yaml
patch:
  # engine/filters@next: lua_filter@<module>@<name_space>
  engine/filters/@next: lua_filter@stroke_count@translator
  <name_space>/tags: [abc]
  <name_space>/stroke_format: "(總:%s - %s)"

-- rime.lua
stroke_count = require 'stroke_count'

# cp stroke_count.lua  <user_data_dir>/lua/.
--  h,s,p,n,z 代表橫、豎、撇、捺、折
--]]

require 'tools/string'
local List=require 'tools/list'
local str_fmt="(總:%s:%s)"

local function config_list_to_set(config_list)
  if not config_list then return config_list end
  if config_list then
    local tab ={}
    for i=0,config_list.size-1 do
      table.insert(tab, config_list:get_value_at(i).value)
    end
    return Set(tab)
  end
end

local function strock_count_to_str(reversedb,text,out_fmt,ch)
  out_fmt= out_fmt or "(%s : %s)"
  local list= List( text:split("")):map(
  function(word)  return #(reversedb:lookup(word):split()[1] or "")  end)

  local sum= list:reduce(function(elm,org) return elm + org end , 0)

  return out_fmt:format(sum,list:concat(ch or ",") )
end

local slash= package.config:sub(1,1)
local M={}
function M.init(env)
  local context=env.engine.context
  local config=env.engine.schema.config
  -- init option
  env.option= "stroke_count"
  context:set_option(env.option, context:get_option(env.option) or false)

  env.str_fmt= config:get_string(env.name_space .. "/stroke_format" ) or str_fmt
  env.reversedb= ReverseDb( "build"  .. slash ..  "stroke.reverse.bin" )

  --  config_list to Set
  env.tags =  config_list_to_set( config:get_list(env.name_space .. "./tags"))
end
function M.fini(env)
end

function M.tags_match(seg,env)
  --  tags all : env.tags == nil or faile
  local tags_match=  not env.tags or not (seg.tags * env.tags):empty()
  return tags_match and env.engine.context:get_option(env.option)
end

function M.func(input,env)
  local context=env.engine.context
  for cand in input:iter() do
    cand.comment = cand.comment ..  strock_count_to_str(env.reversedb, cand.text,env.str_fmt)
    yield(cand)
  end
end

return M

