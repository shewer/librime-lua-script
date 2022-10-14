#! /usr/bin/env lua
--
-- debugtool.lua
-- Copyright (C) 2021 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
-- puts(tag,...)
-- DEBUG --> log.error
-- WARN  --> log.warning
-- INFO  --> log.info
-- CONSOLE --> print
--
-- ex:
-- test.lua
--
-- local puts = require 'tools/debugtool'
-- --set tag D103 C102
-- local D103= DEBUG .. "103"
-- local C102= CONSOLE .. "102"
-- local C103= nil
--
--
-- puts(ERROR,__FILE__(),__LINE__(),__FUNC__(), 1, 2 , 3 )
--    --> log.error( "error" .. tran_msg(...))
--
-- puts(DEBUG,__FILE__(),__LINE__(),__FUNC__(), 1, 2 , 3 )
--    --> log.error( DEBUG .. tran_msg(...))
--
-- puts(D103,__FILE__(),__LINE__(),__FUNC__(), 1 2 3)
--    --> log.error("trace103" .. tran_msg(...)
--
-- puts(C102,__FILE__(),__LINE__(),__FUNC__(), 1 2 3)
--    --> print("console103" .. tran_msg(...)
--
-- puts(C103,__FILE__(),__LINE__(),__FUNC__(), 1 2 3)
--   -->  pass
--
--
--
-- puts(DEBUG,__FILE__(),__LINE__(),__FUNC__() , ...)
-- puts(INFO,__FILE__(),__LINE__(),__FUNC__() , ...)
--
-- global variable
function __FILE__(n) n=n or 2 return debug.getinfo(n,'S').short_src end
function __LINE__(n) n=n or 2 return debug.getinfo(n, 'l').currentline end
function __FUNC__(n) n=n or 2 return debug.getinfo(n, 'n').name end
local ok,res= pcall( require ,'croissant.debugger')
GD = ok and res or nil

