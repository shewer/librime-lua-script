#! /usr/bin/env lua
--
-- pattern_test.lua
-- Copyright (C) 2021 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
local lu=require 'tools/luaunit'
local pattern_func=require 'tools/pattern'

local TestPattern={}
function TestPattern:setUp()
  self.xlit= pattern_func("xlit|abc|xyz|")
  self.xlit2= pattern_func("xlit|abc|日月金|")
  self.derive=pattern_func("derive|abc|xyz|")
  self.derive2=pattern_func("derive|abc|日月金|")
  self.xform=pattern_func("xform|abc|xyz|")
  self.xform2=pattern_func("xform|abc|日月金|")
  self.erase=pattern_func("erase|abc|")
end 
function TestPattern:test_xlit()
  lu.assertEquals(self.xlit("abc") ,"xyz")
  lu.assertEquals(self.xlit("afc") ,"xfz")
  lu.assertEquals(self.xlit2("abc") ,"日月金")
  lu.assertEquals(self.xlit2("afc") ,"日f金")
end

function TestPattern:test_derive()
  lu.assertEquals(self.derive("abc") ,"abc xyz")
  lu.assertEquals(self.derive("ggabcgg") ,"ggabcgg ggxyzgg")
  lu.assertEquals(self.derive2("abc") ,"abc 日月金")
  lu.assertEquals(self.derive2("ggabcgg") ,"ggabcgg gg日月金gg")
end

function TestPattern:test_xform()
  lu.assertEquals(self.xform("abc") ,"xyz")
  lu.assertEquals(self.xform("abcgg") ,"xyzgg")
  lu.assertEquals(self.xform("abgg") ,"abgg")
  lu.assertEquals(self.xform2("abc") ,"日月金")
  lu.assertEquals(self.xform2("abcgg") ,"日月金gg")
  lu.assertEquals(self.xform2("abgg") ,"abgg")
end

function TestPattern:test_erase()
  lu.assertEquals(self.erase("abc") ,"")
  lu.assertEquals(self.erase("ab") ,"ab")
end 

return TestPattern

