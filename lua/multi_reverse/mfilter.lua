#! /usr/bin/env lua
--
-- mfilter.lua
-- Copyright (C) 2021 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--


--[[
------- lua_filter ---------------
--
-- 由 processor.init() 取得 engine/translators ConfigList中的 script_translator & table_translator
-- @name_space  轉出  lua_filter@name_filter@namespace 字串 加入 engine/filters
--
option: qcode   -- 顯示 字根短碼
option: multi_reverse  -- tag_match 條件
property: multi_rverse  -- tags_match 條件   env.name_space

config:
  <name_space>/dictionary: -- tags_match 條件 open ReverseDb
  <name_space>/tags:  -- tags_match 條件   has_tags
  <name_space>/comment_format:  Projection pattern


-----------------------------------
-- rime.lua
mfilter= require'multi_reverse/mfilter'

--yaml
--                 <lua_compo>@module@{name_space>
engine/filters/@?: lua_filter@mfilter@translator

# option for translator
taranslator/tags:
translator/comment_format:
translator/dictionary:


--]]

--  append  rime_api  method
require'tools/rime_api'
local puts=require 'tools/debugtool'

local List= require'tools/list'

-- 簡碼處理 ex:   "abcd abc cc aa" -->  "aa cc" ,"abcd abc cc aa"
local function quick_code(text)
  local pattern="[^%s]+"
  local list=List()
  for sp in text:gmatch(pattern) do
    list:push(sp)
  end
  local min = list:reduce(
  function(elm,org)
    return #elm < org and #elm or org
  end , 100 )
  return list:select(function(elm) return #elm <= min end ):concat(" ")

end

-- load <name_space>/tags to table
local function get_tags(env)
  local tags=env.engine.schema.config:get_list(env.name_space .. "/tags")
  local tags_tab= {}
  if tags  then
    for i=0,tags.size-1 do
      table.insert(tags_tab, tags:get_value_at(i) )
    end
  end
  return tags_tab
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


--local Name = "multi_reverse"
--local Multi_reverse="multi_reverse"
--
M={}
M.Name= ...
local Multi_reverse="multi_reverse"
local Multi_reverse_hold="multi_reverse_hold"
local Qcode="qcode"
-- 以 name_space 作爲開關
-- has_tag and name_space match property  and multi_reverse == true  and reverdb not nil
function M.tags_match(segment,env)
  local context=env.engine.context
  return _tags_match( segment, env)
    and env.reverdb
    and ( context:get_option(Multi_reverse) or context:get_option(Multi_reverse_hold) )
    and context:get_property(Multi_reverse) == env.name_space
end


function M.init(env)
  local config=env.engine.schema.config
  local context=env.engine.context
  env.tags= get_tags(env)

  env.projection= rime_api.Projection( config, env.name_space .. "/comment_format")
  env.dictionary= config:get_string(env.name_space .. "/dictionary")
  env.reverdb= rime_api.load_reversedb(env.dictionary)
end

function M.fini(env)
  env.reverdb =nil
end

function M.func(input,env)
  local context=env.engine.context
  for cand in input:iter() do
    local code=env.reverdb:lookup(cand.text)
    -- cand.type == "sentence" 且反查無字 拆字反查
    if #code<1  and cand.text:utf8_len()> 1 and cand.type =="sentence" then
      code =  List(cand.text:split(""))
      :map(function(elm) return env.reverdb:lookup(elm) end)
      :concat(" ")
    end

    cand.comment = cand.comment .. "|" ..
      env.projection:apply( context:get_option(Qcode) and quick_code(code) or code ) or code
    yield(cand)
  end
end


return M
