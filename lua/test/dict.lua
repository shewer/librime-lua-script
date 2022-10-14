#! /usr/bin/env lua
--
-- dict.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
local List= require 'tools/list'
local Dict = require 'tools/dict'
local lu = require 'tools/luaunit'

local t=List()
for fn in next, {'essay.txt','essay.txt','essay_cn.txt','essay_cn.txt'} do
  local t1=os.clock()
  Dict(fn)
  t:push(  os.clock() - t1)
end
print( "\ntime :", t:concat(", "))

local M = {}
function M:setUp()
  self.dict = assert(Dict('essay.txt'),"can't load dict")
  self.dict1 = assert(Dict('essay_cn.txt'),"can't load dict")
end
function M:Test_find_word()
  lu.assertEquals( self.dict:find_word("大家都"),{'是','來'})
end
function M:Test_word_iter()
  --print(self.dict:find_word('大衆'):concat("-"))
  --print( self.dict1:find_word('大众'):concat("-") )
  local l = List()
  for w in self.dict:word_iter('大家都') do
    l:push(w)
  end
  lu.assertEquals( l ,{'是','來'})
  end
function M:Test_reduce_find_word()
  local str=self.dict:reduce_find_word('天下'):reduce(function(elm,org)
    return  #org <=10 and  org:push(elm) or org  end,List()):concat("-")
  lu.assertEquals(str,'第一-人-無敵-無賊-無雙-沒有-大亂-太平-爲公-烏鴉一般黑-興亡')
end


return M
