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


反查碼 filtera 是以 property: multi_reverse: <name_space> match 時觸發反查機制

ex:


lua_filter@multi_reverse.filter@name_space
_G['multi_reverse.filter'] = require 'multi_reverse.filter'

luafilter@reverse_filter@<name_space>
_G['reverse_filter'] = require 'multi_reverse.filter'



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
local Env = require 'tools/env_api'
local List= require'tools/list'

-- 簡碼處理 ex:   "abcd abc cc aa" -->  "cc aa"
local function quick_code(text)
  local tab=text:split("%s+")
  if #tab <=1 then return tab[1] end
  local min = tab:reduce(function(elm,min) return min < #elm and min or #elm end, 100)
  return tab:select(function(elm) return #elm <= min end):concat(" ")
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
  Env(env)
  local context=env.engine.context
  env.tags= get_tags(env)

  -- init comment_formate and reversedb
  -- default  self , S_<schema>/translatior , name_space not fund : <schema>/transltor
  local ns , config = env.name_space , env.engine.schema.config
  if ns:match("^S_(.+)$") then
    -- setup  schema_id <-- ns:match("^S_(.+)$") ns <-- 'translator'
    config =Schema(ns:match("^S_(.+)$")).config
    ns = "translator"
  elseif config:is_null(ns) then
    -- try to setup  schema_id <-- ns  ns <-- translator
    config= Schema(ns).config
    ns = "translator"
  end
  env.projection= rime_api.Projection( config, ns .. "/comment_format")
  env.dictionary= config:get_string( ns .. "/dictionary")
  env.reverdb= rime_api.ReverseDb(env.dictionary)
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

    local m_comment= env.projection:apply(env:Get_option(Qcode) and quice_code or code)
    m_comment = #m_comment == 0 and code or m_comment
    cand.comment = cand.comment .. "|" .. m_comment
    yield(cand)
  end
end


return M
