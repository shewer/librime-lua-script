#! /usr/bin/env lua
--
-- _test.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
-- 
-- _TEST.pre_test() , 可以放入與 engine 無關的測試
-- _TEST.init_test(env) 利用 env.engine 可以測試 engine context config 
--

local puts=require 'tools/debugtool'
local M = {}
local function debug_filter_test()
  puts(DEBUG,__LINE__(), "-------debug_filter test ")
  local schema= Schema("whaleliu_ext")
  local config = schema.config
  assert(schema and tostring(schema):match("Schema") )
  assert(config and tostring(config):match("Config") )

  local l1=config:get_item("debug_filte")
  assert(li == nil) 
  puts(DEBUG,__LINE__(), l1)
  local l1=config:get_list("debug_filte")
  assert(li == nil) 
  puts(DEBUG,__LINE__(), l1)
  local l1=config:get_item("debug_filter")
  puts(DEBUG,__LINE__(), l1,l1 and l1.type, l)

  local l1=config:get_item("debug_filter/output_format_str")
  puts(DEBUG,__LINE__(), l1,l1 and l1.type,l1:get_value().value:gsub("%s",""))
  local l1=config:get_item("debug_filter/output_format")
  puts(DEBUG,__LINE__(), l1,l1 and l1.type,l1:get_list().size)
  puts(DEBUG,__LINE__(), "-------debug_filter test ")
  assert(false)
end
function M.pre_test()
  puts(DEBUG,__LINE__(),"----------------pre_test start -----------------------")
  local keys=KeySequence()
  keys:parse("abcde")
  assert(keys:repr() == "abcde")
  assert(#keys:toKeyEvent() == 5)
  local keys=KeySequence("abcde")
  assert(keys:repr() == "abcde")
  keys:parse("abcdef")
  assert(keys:repr() == "abcdef")

  debug_filter_test()
  puts(DEBUG,__LINE__(),"----------------pre_test end -----------------------")
end
function M.jjj()
  kkk.a=3
end

function M.init_test(...)
end
return M
