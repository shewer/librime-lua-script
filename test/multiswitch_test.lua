#! /usr/bin/env lua
--
-- multiswitch_test.lua
-- Copyright (C) 2021 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
-- package.path add :

local lu=require'tools/luaunit'
assert(lu)
assert(lu.LuaUnit)
local function addrcheck(obj1,obj2)
	return tostring(obj1) == tostring(obj2) 
end 
local List_=require'tools/list'
local MList =require'multi_reverse/multiswitch'
TestMSList={}

function TestMSList:setUp()
  self.list_read_only = MList(1,2,3,4)
end

function TestMSList:testInit()
  lu.assertEquals(#MList(), 0)
  lu.assertEquals(#MList(1,2,3,4), 4)
  lu.assertEquals(#MList({1,2,3,4}), 4)
  lu.assertEquals(#MList({1,2,3,4},2,3), 3)
end 
function TestMSList:test_operation__eq()
  local list=MList(1,2,3,4)
  lu.assertTrue( MList(1,2,3,4) == {1,2,3,4}) 
  lu.assertTrue( MList(1,2,3,4) == MList({1,2,3,4})) 
  lu.assertFalse( MList(1,2,3,4) == {1,2,3,5} )
  lu.assertFalse( MList(1,2,3,4) == {1,2,3} )
end 
function TestMSList:test_operation__add()
  local l1=MList(1,2)
  local l2=MList(3,4)
  local l3= l1 + l2 + {5,6}  
  lu.assertTrue(l3=={1,2,3,4,5,6})
  lu.assertFalse(addrcheck(l3,l1))
  lu.assertFalse(addrcheck(l3,l2))
  lu.assertEquals( l3:class(),l2:class() )
  lu.assertTrue(addrcheck(l3:class(),l2:class()))
end 
function TestMSList:test_operation__shl()
  local l1=MList(1,2)
  local l2=l1
  local l3=l1 << {3,4}  << {5,6}
  lu.assertTrue(l1=={1,2,3,4,5,6})
  lu.assertTrue(addrcheck(l3,l1))
  lu.assertTrue(addrcheck(l1,l2))
  lu.assertTrue(addrcheck(l3:class(),l2:class()))
  lu.assertTrue(addrcheck(l3:class(),l2:class()))
  l1=MList(1,2)
  local l3= l1 << MList(3,4)+ {5,6}  <<  7<< 8
  lu.assertTrue(l1=={1,2,3,4,5,6,7,8})
  _= MList() << 2 << 4 << 33
end 
function TestMSList:test_clear()
	local l1=MList(1,2,3,4) 
	local l2 = l1
	local l3 = l1:clear() 
	lu.assertTrue(l1,{})
	lu.assertEquals(#l1,0)
	lu.assertEquals(tostring(l1),tostring(l2))
	lu.assertEquals(tostring(l1),tostring(l3))
end 

function TestMSList:test_insert_at()
	local l1=MList(1,2,3,4) 
	local l2 = l1
	local l3 = l1:insert_at(1,0)
	lu.assertTrue(l1== {0,1,2,3,4}) -- unshift
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local l3 = l1:insert_at(6,5) --- push
	lu.assertTrue(l1== {0,1,2,3,4,5})
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local l3 = l1:insert_at(3,1.5) --- push
	lu.assertTrue(l1== {0,1,1.5,2,3,4,5})
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
end 
function TestMSList:test_push()
	local l1=MList(1,2,3,4) 
	local l2 = l1
	local l3 = l1:push(5)
	lu.assertTrue(l1== {1,2,3,4,5}) -- unshift
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local l3 = l1:push(6) --- push
	lu.assertTrue(l1== {1,2,3,4,5,6})
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local l1=MList() 
	local l2 = l1
	local l3 = l1:push(1)
	lu.assertTrue(l1== {1}) -- unshift
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
end 
function TestMSList:test_unshif()
	local l1=MList(1,2,3,4) 
	local l2 = l1
	local l3 = l1:unshift(5)
	lu.assertTrue(l1== {5,1,2,3,4}) -- unshift
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local l3 = l1:unshift(6) --- push
	lu.assertTrue(l1== {6,5,1,2,3,4})
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local l1=MList() 
	local l2 = l1
	local l3 = l1:unshift(1)
	lu.assertTrue(l1== {1}) -- unshift
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local l3 = l1:unshift(2)
	lu.assertTrue(l1=={2,1}) -- unshift
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
end 
-- obj:remove_at(index(1)  return elm, self  
function TestMSList:test_remove_at()
	local l1=MList(1,2,3,4)
	local l2=l1 
	-- index out of range  return nil
	local elm,l3= l1:remove_at(5) 
	lu.assertTrue(l1== {1,2,3,4}) -- unshift
	lu.assertEquals(elm,nil )
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local elm,l3= l1:remove_at(0) 
	lu.assertTrue(l1== {1,2,3,4}) -- unshift
	lu.assertEquals(elm,nil )
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local elm,l3= l1:remove_at(-5) 
	lu.assertTrue(l1== {1,2,3,4}) -- unshift
	lu.assertEquals(elm,nil)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local elm,l3= l1:remove_at(-6) 
	lu.assertTrue(l1== {1,2,3,4}) -- unshift
	lu.assertEquals(elm,nil)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))


	local elm,l3= l1:remove_at(-1) 
	lu.assertTrue(l1== {1,2,3}) -- unshift
	lu.assertEquals(elm,4)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local elm,l3= l1:remove_at(3) 
	lu.assertTrue(l1== {1,2}) -- unshift
	lu.assertTrue(elm,3)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local elm,l3= l1:remove_at(1) 
	lu.assertTrue(l1== {2}) -- unshift
	lu.assertEquals(elm,1)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))

	local l1=MList(1,2,3,4)
	local l2=l1 
	local elm,l3= l1:remove_at(-2) 
	lu.assertTrue(l1== {1,2,4}) -- unshift
	lu.assertEquals(elm,3)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local elm,l3= l1:remove_at(-3) 
	lu.assertTrue(l1== {2,4}) -- unshift
	lu.assertEquals(elm,1)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	l1:clear()
	local elm,l3= l1:remove_at(1) 
	lu.assertTrue(l1== {}) -- unshift
	lu.assertEquals(elm,nil)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))


end 
-- -->  obj:remove_at(1) 
function TestMSList:test_shift()
	local l1=MList(1,2,3)
	local l2=l1

	local elm,l3= l1:shift(4) -- don't care  
	lu.assertTrue(l1 ==  {2,3}) -- unshift
	lu.assertEquals(elm,1)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local elm,l3= l1:shift("aoeuaoeu") -- don't care  
	lu.assertTrue(l1 == {3}) -- unshift
	lu.assertEquals(elm,2)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local elm,l3= l1:shift()
	lu.assertTrue(l1== {}) -- unshift
	lu.assertEquals(elm,3)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local elm,l3= l1:shift()
	lu.assertTrue(l1== {}) -- unshift
	lu.assertEquals(elm,nil)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))

end 
--  obj:remove_at(-1) 
function TestMSList:test_pop()
	local l1=MList(1,2,3)
	local l2=l1

	local elm,l3= l1:pop(4) -- don't care  
	lu.assertTrue(l1== {1,2}) -- unshift
	lu.assertEquals(elm,3)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local elm,l3= l1:pop("aoeuaoeu") -- don't care  
	lu.assertTrue(l1== {1}) -- unshift
	lu.assertEquals(elm,2)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local elm,l3= l1:pop()
	lu.assertTrue(l1== {}) -- unshift
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

function TestMSList:test_each()
	local l1=MList(1,2,3,4)
	local l2=l1
	local count=0
	local sum=0
	l1:reduce( function(elm) count = count +1 ; sum=sum+elm  end  )
	lu.assertTrue( addrcheck(l1,l2))  
	lu.assertEquals( count, 4)
	lu.assertEquals(sum, 10)
end 
function TestMSList:test_each_with_index()
	local l1=MList(1,2,3,4)
	local l2=l1
	local count=0
	local sum=0
	local isum=0
	local chk=true
	l1:each_with_index( function(elm,i) 
		count = count +1
		chk = chk and i == count 
		isum=isum + i 
		sum=sum + elm 
	end  )
	lu.assertTrue( addrcheck(l1,l2))  
	lu.assertEquals( count, 4)
	lu.assertEquals(sum, 10)
	lu.assertEquals(isum, 10)
	lu.assertTrue( chk)

end 

function TestMSList:test_map()
	local l1 = MList(1,2,3,4) 
	local l2 = l1:map() --  clone obj
	lu.assertEquals(l1,l2)
	lu.assertTrue(l2,{1,2,3,4})
	lu.assertTrue(l1 == l2 )
	lu.assertTrue(l2 == {1,2,3,4})
	lu.assertTrue(l1:class() == l2:class() )
	lu.assertFalse( addrcheck(l1,l2) )

	lu.assertTrue(l1:map(function(elm) return elm end ) == {1,2,3,4} )

	lu.assertEquals(l1:map(function(elm) return {elm ,elm} end  ) , {{1,1},{2,2},{3,3},{4,4},_index=1, _status=true} )
	lu.assertTrue(l1:map(function(elm) return elm * 2 end ) == {2,4,6,8} )

	--  lua  nil  特性
	lu.assertTrue(l1:map(function(elm,i) return (elm & 1)==1  and elm or nil end ) == {1,3} )
end 

function TestMSList:test_map_with_index()
	local l1 = MList(1,2,3,4) 
	local l2 = l1:map_with_index() --  clone obj
	lu.assertEquals(l1,l2)
	lu.assertTrue(l2=={1,2,3,4})
	lu.assertTrue(l1 == l2 )
	lu.assertTrue(l2 == {1,2,3,4})
	lu.assertTrue(l1:class() == l2:class() )
	lu.assertFalse( addrcheck(l1,l2) )

	lu.assertTrue(l1:map_with_index(function(elm) return elm end ) == {1,2,3,4} )
	lu.assertTrue(l1:map_with_index(function(elm,i) return elm end ) == {1,2,3,4} )
	lu.assertEquals(l1:map_with_index(function(elm,i) return (i & 1)== 1  and elm end ) ,{1,false,3,false,_index=1, _status=true} )
	lu.assertEquals(l1:map(function(elm) return {elm ,elm} end  ) , {{1,1},{2,2},{3,3},{4,4},_index=1, _status=true} )
	lu.assertTrue(l1:map_with_index(function(elm,i) return elm * 2 end ) == {2,4,6,8} )

	--  lua  nil  特性
	lu.assertTrue(l1:map_with_index(function(elm,i) return (i & 1)== 1  and elm or nil end ) == {1,3} )
end 
function TestMSList:test_select()
	local l1 = MList(1,2,3,4) 
	local l2 = l1:select(function(elm) return true end ) --  clone obj
	lu.assertEquals(l1,l2)
	lu.assertTrue(l2=={1,2,3,4})
	lu.assertTrue(l1 == l2 )
	lu.assertTrue(l2 == {1,2,3,4})
	lu.assertTrue(l1:class() == l2:class() )
	lu.assertFalse( addrcheck(l1,l2) )


    lu.assertTrue(l1:select(function(elm) return elm end )== {1,2,3,4})
    lu.assertTrue(l1:select(function(elm) return (elm & 1) == 0 end )== {2,4})
    lu.assertTrue(l1:select(function(elm) return elm >2  end )== {3,4})

end 

function TestMSList:test_select_withe_index()
	local l1 = MList(1,2,3,4) 
	local l2 = l1:select_with_index(function(elm) return true end ) --  clone obj
	lu.assertEquals(l1,l2)
	lu.assertTrue(l2=={1,2,3,4})
	lu.assertTrue(l1 == l2 )
	lu.assertTrue(l2 == {1,2,3,4})
	lu.assertTrue(l1:class() == l2:class() )
	lu.assertFalse( addrcheck(l1,l2) )


    lu.assertTrue(l1:select_with_index(function(elm,i) return elm end )== {1,2,3,4})
    lu.assertTrue(l1:select_with_index(function(elm,i) return (i & 1) == 0 end ) == {2,4})
    lu.assertTrue(l1:select_with_index(function(elm,i) return i >2  end )=={3,4})

end 
--- test MultiSwitch 
function TestMSList:test_status()
  local l1=MList("a","b","c","d" )
  lu.assertEquals(l1(), "a")
  lu.assertEquals(l1:status(), "a")
  lu.assertEquals(l1:status(false), "")
  lu.assertEquals(l1(), "")
  lu.assertEquals(l1:status(true), "a")
  lu.assertEquals(l1(), "a")
  lu.assertEquals(l1:off(), "")
  lu.assertEquals(l1:on(), "a")
  lu.assertEquals(l1:toggle(), "")
  lu.assertEquals(l1:toggle(), "a")
end 

function TestMSList:test_chang_index()
  local l1=MList("a","b","c","d" )
  lu.assertEquals(l1:next(),  "b")
  lu.assertEquals(l1(), "b")
  lu.assertEquals(l1:status(), "b")
  lu.assertEquals(l1:next(1),  "c")
  lu.assertEquals(l1:index() , 3)
  lu.assertEquals(l1:index(1), 1)
  lu.assertEquals(l1:index(0), 4)
  lu.assertEquals(l1:index(4), 4)
  lu.assertEquals(l1:index(-4), 4)
  lu.assertEquals(l1:index(-1), 3)
  lu.assertEquals(l1:index(), 3)
  lu.assertEquals(l1:next(2), "a")
  lu.assertEquals(l1:next(-2), "c")
  lu.assertEquals(l1:prev(2), "a")
  lu.assertEquals(l1:prev(-2), "c")


end


assert(  lu.LuaUnit )
assert(  lu.LuaUnit.run)
--os.exit( lu.LuaUnit.run() )


return TestMSList

