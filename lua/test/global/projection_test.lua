#! /usr/bin/env lua
--
-- test_projection.lua
-- Copyright (C) 2023 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--


local lu = require 'test/luaunit'
local err_fmt="%s:%s %s"
local M = {}

function M:Setup()
  local data={}
  data.cl=ConfigList()
  data.str1,data.str2 ="xlit|123|一二三","xform|一|十|"
  data.res = "十二三"
  data.cl:append(ConfigValue(data.str1).element)
  data.cl:append(ConfigValue(data.str2).element)
  self.data=data
end
function M:tearDown()
  self.data=nil
end
function M:test_Projection()
  local data=self.data
  local proj1= Projection(data.cl)
  local proj2= Projection(data.str1,data.str2)
  local proj3= Projection()
  proj3:load(self.data.cl)

  lu.assertEquals(proj1:apply('123'),"十二三")
  lu.assertEquals(proj2:apply('123'),"十二三")
  lu.assertEquals(proj3:apply('123'),"十二三")
  local proj4= Projection()
  proj4:load(data.str1,data.str2)
  lu.assertEquals(proj4:apply('123'),"十二三")
end
function M:test_nonstring_error()
  local data=self.data
  local proj = Projection()
  if GD and T01 then GD() end
  -- string  algebra pattern error
  lu.assertFalse(proj:load(123)) -- format of pattern error
  lu.assertFalse(proj:load('123')) -- format of pattern error
  lu.assertFalse(proj:load('abc')) -- format of pattern error
  -- nonstring error
  lu.assertFalse(proj:load('123',nil)) -- not string
  lu.assertFalse(proj:load('123',{})) -- table not string
  lu.assertFalse(proj:load('123',ConfigValue(1))) -- userdata not string
  lu.assertFalse(proj:load('123',true)) -- boolean not string

end

return M
