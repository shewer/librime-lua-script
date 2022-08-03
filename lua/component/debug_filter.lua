#! /usr/bin/env lua
--
-- debug_filter.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
--[[

lua_filter@debug_filter 提供顯示 candidate 訊息和 tags
可以在 方案中 添加
  name_space/output_format: # 設置 順序
         - dtype # candidate type
         - type  # candidate.type
         - start # candidate.start
         - _end  #
         - text
         - comment
         - quality
         - input # context.input
         - ainput  # active_input  context.input:sub(_start +1 , _end)
         - error  lua component error
  name_space/tags: 設置同 filter

  option: _debug  開關此功能
  property:   :可以重設定 顯示資料和順序  以逗號分隔


<schema_name>.custom.yaml

  # module_name: debug_filter name_space: debug_filter
  engine/filters/@next: lua_filter@debug_filter

  # item_name  dtype type start _end preedit, quality input ainput  comment
  debug_filter/output_format: [dtype,type,start,_end,preedit,quality]



enable switch:
   option_name: _debug   disable / enable

candidate.comment output :
   property: _debug
   cand data_name: type start _end comment quality preedit , dtype
   input_str:  input  ainput

ex:
  context:set_option("_debug", true)
  context:set_property("_debug", "dtype,comment,_end,start,quality")


--
--]]

local output_fmt="dtype,type,start,_end,preedit,quality"
local name = "_debug"
local puts = require 'tools/debugtool'


require 'tools/rime_api'
require 'tools/string'
local List=require 'tools/list'
local function item_to_list(item)
  if item and item.type == "kList" then
    local cl = item:get_list()
    local l = List()
    for i=0,cl.size-1 do
      l:push( cl:get_value_at(i).value or "" )
    end
    return l
  end
end

local function get_output_fmt(config,path)
  local item=config:get_item(path)
  if not item then return end
  if item.type == "kList" then
    local l = item_to_list(item)
    return l and l:concat(",")
  elseif item.type == "kScalar" then
    return item:get_value().value:gsub("%s","")
  end
end
local function get_tags(config,path)
  return Set(
    item_to_list( config:get_item(path) ))
end

local M={}
function M.init(env)
  Env(env)
  local context= env:Context()
  local config= env:Config()
  env.tags = get_tags( config,env.name_space .. "/tags")

  --init option property
  env.option= "_debug"
  context:set_option( env.option , context:get_option(env.option) or false)

  local output_fmt= get_output_fmt(config, env.name_space .. "/output_format") or output_fmt
  context:set_property(env.option, output_fmt )
end

function M.fini(env)
end

-- M.tags_match
local function tags_str(seg)
  local tab={}
  for k, _ in next, seg.tags do table.insert(tab,k) end
  return string.format(" [tags: %s]", table.concat(tab," ") )
end
function M.tags_match(seg,env)
  --  tags all : env.tags == nil or faile
  local context = env:Context()
  local enable = context:get_option(env.option)
  if enable then
    seg.prompt = seg.prompt .. tags_str(seg)
  end
  -- all: not env.tags  match tags: not (seg.tags * env.tags):empty()
  -- if enable then
  --   if not env.tags then return true end
  --   if not (seg.tags * env.tags):empty() then return true end
  -- end
  return enable  and ( not env.tags or not (seg.tags * env.tags):empty())
end

-- M.func
local function debug_comment(items,cand,tab)
  tab = tab or { }
  tab.ainput= tab.input and tab.input:sub(cand.start +1,cand._end) or ""
  tab.dtype= cand:get_dynamic_type()
  tab.quality = string.format("%6.4f",cand.quality)
  local function fn(elm) return tab[elm] or cand[elm]  or "" end
  return "--" ..  items:gsub(" ",""):split(","):map(fn):concat("|")
end

--warp ShadowCandidate
local ShadownCandidate = ShadowCandidate or function (cand,type,text,commment)
  return Candidate(type,cand.start,cand._end,text,comment)
end
function M.func(input, env)
   local context = env:Context()
   local items = context:get_property(env.option)
   local ext_data= {
     input = context.input,
     error = context:get_property("_error")
   }

   for cand in input:iter() do
      local comment = cand.type == "command"
      and cand.comment
      or cand.comment ..  debug_comment(items,cand,ext_data )
      yield( ShadowCandidate( cand, cand.type,cand.text, comment) )
   end
end
return M

