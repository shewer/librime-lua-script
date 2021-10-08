#! /usr/bin/env lua
--
-- init.lua
-- Copyright (C) 2021 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
lu=require 'tools/luaunit'
TestList= require 'test/list_test'
TestObject= require 'test/object_test'
--TestListNEW= require 'test/list_new_test'
TestMS= require 'test/multiswitch_test'
TestPT= require 'test/pattern_test'

os.exit( lu.LuaUnit.run() )
