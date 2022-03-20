#! /usr/bin/env lua
--
-- debug_filter.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
--[[
<schema_name>.custom.yaml
  engine/filters/@next: lua_filter@debug_filter

enable switch:
   option_name: _debug   disable / enable
data output :
   property _debug
   cand data_name: type start _end comment quality preedit , dtype

ex:
  context:set_option("_debug", true)
  context:set_property("_debug", "dtype,comment,_end,start,quality")

--
--]]

local output_fmt="dtype,type,start,_end,preedit,quality"

require 'tools/string'
local List=require 'tools/list'
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

local M={}
function M.init(env)
  local context= env.engine.context
  local config= env.engine.schema.config
  output_fmt= config:get_string(env.name_space .. "/output_format") or output_fmt
  --init option property
  env.option= "_debug"
  context:set_option(env.option, context:get_option(env.option) or false)
  context:set_property("_debug", output_fmt )
  env.tags = config_list_to_set( config:get_list( env.name_space .. "/tags"))

end
function M.fini(env)
end

function M.tags_match(seg,env)
  --  tags all : env.tags == nil or faile
  local tags_match=  not env.tags or not (seg.tags * env.tags):empty()
  return tags_match and env.engine.context:get_option(env.option)
end

function M.func(input, env)
   local items = List(env.engine.context:get_property(env.option):gsub(" ",""):split(","))
   for cand in input:iter() do
      if cand.type ~= "command" then
       cand.comment = cand.comment  ..
       items:reduce( function(elm,org)
         return  org .. ( elm == "dtype" and cand.get_dynamic_type(cand)
         or ( cand[elm] or ""  ))  .. "|"
       end, "--")
      end
      yield(cand)
   end
end
return M

