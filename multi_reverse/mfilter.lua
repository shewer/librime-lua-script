#! /usr/bin/env lua
--
-- mfilter.lua
-- Copyright (C) 2021 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--


------- lua_filter ---------------

-- 由 processor.init() 取得 engine/translators ConfigList中的 script_translator & table_translator
-- @name_space  轉出  lua_filter@name_filter@namespace 字串 加入 engine/filters

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

local function _tags_match( tab, segment)
  if #tab < 1 then return true end  --  tab  size ==0  如果 無tags 表示 全符合
  for i,v in ipairs(tab) do
    if secment:has_tag( v ) then
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
local Qcode="qcode"
--  env.reverdb 開檔失敗 return false
--  補足 tags match  tags_match api ，如果須要 限制 tags 範圍 將下一行取消註解
--if not _tags_match(env.tags ,segment) then  return false end
-- 以 name_space 作爲開關
function M.tags_match(segment,env)
  return  env.reverdb
    and env.engine.context:get_property(Multi_reverse) == env.name_space
    or false
end

function M.init(env)
  local config=env.engine.schema.config
  --env.tags= rime_api.clone_configlist( config, env.name_space .. "/tags" )
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
    if #code<1  and cand.text:utf8_len()> 1 and env.dictionary:match("pinyin") then
      code =  List(cand.text:split(""))
      :map(function(elm) return env.reverdb:lookup(elm) end)
      :concat(" ")
    end

    cand.comment = cand.comment .. "|" ..
    env.projection:apply(
    context:get_option(Qcode) and quick_code(code) or code )
    yield(cand)
  end
end


return M
