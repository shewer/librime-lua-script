#! /usr/bin/env lua
--
-- stroke_count.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--[[
# custom.yaml
patch:
  engine/filters/@next: lua_filter@stroke_count@translator

-- rime.lua
stroke_count = require 'stroke_count'

# cp stroke_count.lua  <user_data_dir>/lua/. 
--]]

require 'tools/string'
local List=require 'tools/list'
--  h,s,p,n,z 代表橫、豎、撇、捺、折
local str_fmt=": %s (總:%s)"
local M={}
local slash= package.config:sub(1,1)
function M.init(env)
  local context=env.engine.context
  local config=env.engine.schema.config
  local dict= config:get_string( env.name_space .. "/dictionary" ) or config:get_string("translator/dictionary")
  env.reverdb= ReverseDb( "build"  .. slash .. dict .. ".reverse.bin" )
end
function M.fini(env)
end


local function conver_comment(cand)
end 
function M.func(input,env)
  local context=env.engine.context
  for cand in input:iter() do 
    local count_str=cand.text:split("")
    :map( function(elm) 
      return  env.reverdb:lookup(elm):split()
      :reduce( function(elm,org) return #elm > org and #elm or org end,0 )
    end)
    :concat(",")
    cand.comment = cand.comment ..  str_fmt:format( #context.input , count_str)
    yield(cand)
  end 
end
return M

