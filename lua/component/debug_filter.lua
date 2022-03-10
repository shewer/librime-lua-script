#! /usr/bin/env lua
--
-- debug_filter.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
--[[
option  _debug   disable / enable
property _debug   "type,quality"    key1,key2,key3
key:  CandidateReg get    
key:  dtype  get_dynamic_type

--
--]]
require 'tools/string'
local List=require 'tools/list'
local M={}
function M.init(env)
  local context= env.engine.context
  context:set_property("_debug", "dtype,type,start,_end,preedit,quality" )
end
function M.fini(env)
end

function M.tags_match(seg,env)
   return env.engine.context:get_option("_debug")
end

function M.func(input, env)
   local items = List(env.engine.context:get_property("_debug"):split(","))
   items:each(print)
   for cand in input:iter() do
      if cand.type ~= "command" then
       cand.comment = cand.comment  ..
       items:reduce(
       function(elm,org) 
         return  org .. ( elm == "dtype" and cand.get_dynamic_type(cand) or cand[elm] ) .. "|"
       end
         , "--")
      end
      yield(cand)
   end
end 
return M

