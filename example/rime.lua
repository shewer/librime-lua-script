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

require 'tools._global'
-- add module

init_processor = require 'init_processor'
Log(INFO,'loaded rime.lua ')

