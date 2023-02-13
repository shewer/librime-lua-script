#! /usr/bin/env lua
--
-- rime.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
-- for rime_api_console
--ENABLE_RESCUE=true
--T00=true
--T01=true
--T02=true
--T03=true
-- RIME_OPT="T01" ./rime_api_console
-- PRETEST 在無 engine 環境測試 library
-- ENGINE_TEST 在init_processor 中取得 engine 啓動 測試
------------- start ------------------------
-- Opencc memory leakage issue
if Opencc then
  Opencc=function(fs)
    return  {
      convert= function(self,text) return text end,
      convert_text = function(self,text) return text end,
      convert_word= function(self,text) return end,
      random_convert_text = function(self,text) return text end,
    }
  end
end
require 'tools._global'

if _TEST then
  -- add luatest_proc@luatest_proc@luatest
  luatest_proc= require 'test'
end
-- add module
--if GD and T00 then GD() end
init_processor = require 'init_processor'
log.info('------->loaded rime.lua ')

--debug_filter = require 'debug_filter'

