#! /usr/bin/env lua
--
-- init.lua
-- Copyright (C) 2021 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
require 'tools/profile'
pr=newProfiler()
pr:start()
lu=require 'tools/luaunit'
--Test_Dict= require 'test/dict'
TestList= require 'test/list_test'
--TestObject= require 'test/object_test'
--TestListNEW= require 'test/list_new_test'
--TestMS= require 'test/multiswitch_test'
TestPT= require 'test/pattern_test'
--runner = lu.LuaUnit.new()
--runner:setOutputType('tap')
--os.exit( runner:runSuite()  )
lu.LuaUnit.run('-q')
pr:stop()
local outfile = io.open( "profile.txt", "w+" )
pr:report( outfile )
--os.exit(lu.LuaUnit.run('-q'))
