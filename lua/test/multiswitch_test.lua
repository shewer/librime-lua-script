#! /usr/bin/env lua
--
-- multiswitch_test.lua
-- Copyright (C) 2021 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
-- package.path add :

local lu=require'test/luaunit'
assert(lu)
assert(lu.LuaUnit)

local function addrcheck(obj1,obj2)
	return tostring(obj1) == tostring(obj2)
end
local List_=require'tools/list'
local MList =require'multi_reverse/multiswitch'
local TestMSList={}

function TestMSList:setUp()
  self.list_read_only = MList(1,2,3,4)
end

function TestMSList:testInit()
  lu.assertEquals(#MList(), 0)
  lu.assertEquals(#MList(1,2,3,4), 4)
  lu.assertEquals(#MList({1,2,3,4}), 4)
  lu.assertEquals(#MList({1,2,3,4},2,3), 3)
end
function TestMSList:test_clear()
	local l1=MList(1,2,3,4)
	local l2 = l1
  l1:clear()
	local l3 = l1
	lu.assertTrue(l1,{})
	lu.assertEquals(#l1,0)
	lu.assertEquals(tostring(l1),tostring(l2))
	lu.assertEquals(tostring(l1),tostring(l3))
end

function TestMSList:test_insert_at()
	local l1=MList(1,2,3,4)
	local l2 = l1
	local l3 = l1:insert_at(0,0)
	lu.assertEquals(l1:concat(), "01234") -- unshift
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local l3 = l1:insert_at(5,5) --- push
	lu.assertEquals(l1:concat(), "012345") -- unshift
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local l3 = l1:insert_at(1.5,2) --- push
	lu.assertEquals(l1:concat(),"011.52345")
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
end
function TestMSList:test_push()
	local l1=MList(1,2,3,4)
	local l2 = l1
	local l3 = l1:push(5)
	lu.assertEquals(l1:concat(), "12345") -- unshift
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local l3 = l1:push(6) --- push
	lu.assertEquals(l1:concat(), "123456") -- unshift
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local l1=MList()
	local l2 = l1
	local l3 = l1:push(1)
	lu.assertTrue(l1[1]== 1) -- unshift
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
end

function TestMSList:test_pop()
	local l1=MList(1,2,3)
	local l2=l1

	local elm,l3= l1:pop(4) -- don't care
	lu.assertEquals(l1:concat(),"12") -- unshift
	lu.assertEquals(elm,3)
	local elm,l3= l1:pop("aoeuaoeu") -- don't care
	lu.assertEquals(l1:concat(),"1") -- unshift
	lu.assertEquals(elm,2)
	local elm,l3= l1:pop()
	lu.assertTrue(l1:size() == 0 ) -- unshift
	lu.assertEquals(elm,1)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local elm,l3= l1:pop()
	lu.assertTrue(l1, {}) -- unshift
	lu.assertEquals(elm,nil)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	
end
function TestMSList:test_concat()
	local l1=MList(1,2,3,4)
	lu.assertEquals(l1:concat(),"1234")
	lu.assertEquals(l1:concat(","),"1,2,3,4")
	lu.assertEquals(MList():concat(","),"")
	lu.assertEquals(MList():concat(),"")
end

--- test MultiSwitch
function TestMSList:test_status()
  local l1=MList("a","b","c","d" )
  lu.assertEquals(l1:status(), "a")
  lu.assertEquals(l1:status(false), "")
  lu.assertEquals(l1:status(true), "a")
  lu.assertEquals(l1:off(), "")
  lu.assertEquals(l1:on(), "a")
  lu.assertEquals(l1:toggle(), "")
  lu.assertEquals(l1:toggle(), "a")
end

function TestMSList:test_chang_index()
  -- index start from 0
  local l1=MList("a","b","c","d" )
  lu.assertEquals(l1:next(),  "b")
  --lu.assertEquals(l1(), "b")
  lu.assertEquals(l1:status(), "b")
  lu.assertEquals(l1:next(1),  "c")
  lu.assertEquals(l1:index() , 2)
  lu.assertEquals(l1:index(1), 1)
  lu.assertEquals(l1:index(0), 0)
  lu.assertEquals(l1:index(4), 0)
  lu.assertEquals(l1:index(-4), 0)
  lu.assertEquals(l1:index(-1), 3)
  lu.assertEquals(l1:index(), 3)
  lu.assertEquals(l1:next(2), "b")
  lu.assertEquals(l1:next(-2), "d")
  lu.assertEquals(l1:prev(2), "b")
  lu.assertEquals(l1:prev(-2), "d")


end


--assert(  lu.LuaUnit )
--assert(  lu.LuaUnit.run)
--os.exit( lu.LuaUnit.run() )


return TestMSList

