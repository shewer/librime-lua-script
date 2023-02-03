#! /usr/bin/env lua
--
-- commit_history_test.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
local lu = require 'test/luaunit'
-- check  
if not env.engine.context.commit_history then
  print( '==Warnning : not support commit_history ')
  return
end

local M={}
function M:Setup()
  self.e = env.engine
  self.c = self.e.context
  self.h = self.c.commit_history
end
function M:test_simple()
  local tab = {}
  for i,c in next , {'a','b','c'} do self.e:commit_text(c) end

  for k,v in next,self.h:to_table() do 
    table.insert(tab,v.text)
  end
  lu.assertEquals(tab, {'a','b','c'})

  --old version  for it,cr in commit_history:iter() do  
  tab={}
  for it,cr in self.h:iter() do 
    table.insert(tab,cr.text)
  end
  lu.assertEquals( #tab ,3)
  lu.assertEquals( tab,{'c','b','a'})  
end

return M


