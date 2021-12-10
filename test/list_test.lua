#! /usr/bin/env lua
--
-- list_test.lua
-- Copyright (C) 2021 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--

local lu=require'tools/luaunit'
assert(lu)
assert(lu.LuaUnit)
local function addrcheck(obj1,obj2)
	return tostring(obj1) == tostring(obj2) 
end 
local List=require'tools/list'

TestList={}

function TestList:setUp()
  self.list_read_only = List(1,2,3,4)
end

function TestList:testInit()
  lu.assertEquals(#List(), 0)
  lu.assertEquals(#List(1,2,3,4), 4)
  lu.assertEquals(#List({1,2,3,4}), 4)
  lu.assertEquals(#List({1,2,3,4},2,3), 3)
end 
function TestList:test_operation__eq()
  local list=List(1,2,3,4)
  lu.assertTrue( List(1,2,3,4) == {1,2,3,4}) 
  lu.assertTrue( List(1,2,3,4) == List({1,2,3,4})) 
  lu.assertFalse( List(1,2,3,4) == {1,2,3,5} )
  lu.assertFalse( List(1,2,3,4) == {1,2,3} )
end 
function TestList:test_operation__add()
  local l1=List(1,2)
  local l2=List(3,4)
  local l3= l1 + l2 + {5,6}  
  lu.assertEquals(l3,{1,2,3,4,5,6})
  lu.assertFalse(addrcheck(l3,l1))
  lu.assertFalse(addrcheck(l3,l2))
  lu.assertTrue(addrcheck(l3:class(),l2:class()))
  lu.assertTrue(addrcheck(l3:class(),l2:class()))
end 
function TestList:test_operation__shl()
  local l1=List(1,2)
  local l2=l1
  local l3=l1 << {3,4}  << {5,6}
  lu.assertEquals(l1,{1,2,3,4,5,6})
  lu.assertTrue(addrcheck(l3,l1))
  lu.assertTrue(addrcheck(l1,l2))
  lu.assertTrue(addrcheck(l3:class(),l2:class()))
  lu.assertTrue(addrcheck(l3:class(),l2:class()))
  l1=List(1,2)
  local l3= l1 << List(3,4)+ {5,6}  <<  7<< 8
  lu.assertEquals(l1,{1,2,3,4,5,6,7,8})
  _= List() << 2 << 4 << 33
end 
function TestList:test_clear()
	local l1=List(1,2,3,4) 
	local l2 = l1
	local l3 = l1:clear() 
	lu.assertEquals(l1,{})
	lu.assertEquals(#l1,0)
	lu.assertEquals(tostring(l1),tostring(l2))
	lu.assertEquals(tostring(l1),tostring(l3))
end 

function TestList:test_insert_at()
	local l1=List(1,2,3,4) 
	local l2 = l1
	local l3 = l1:insert_at(1,0)
	lu.assertEquals(l1, {0,1,2,3,4}) -- unshift
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local l3 = l1:insert_at(6,5) --- push
	lu.assertEquals(l1, {0,1,2,3,4,5})
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local l3 = l1:insert_at(3,1.5) --- push
	lu.assertEquals(l1, {0,1,1.5,2,3,4,5})
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
end 
function TestList:test_push()
	local l1=List(1,2,3,4) 
	local l2 = l1
	local l3 = l1:push(5)
	lu.assertEquals(l1, {1,2,3,4,5}) -- unshift
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local l3 = l1:push(6) --- push
	lu.assertEquals(l1, {1,2,3,4,5,6})
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local l1=List() 
	local l2 = l1
	local l3 = l1:push(1)
	lu.assertEquals(l1, {1}) -- unshift
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
end 
function TestList:test_unshif()
	local l1=List(1,2,3,4) 
	local l2 = l1
	local l3 = l1:unshift(5)
	lu.assertEquals(l1, {5,1,2,3,4}) -- unshift
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local l3 = l1:unshift(6) --- push
	lu.assertEquals(l1, {6,5,1,2,3,4})
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local l1=List() 
	local l2 = l1
	local l3 = l1:unshift(1)
	lu.assertEquals(l1, {1}) -- unshift
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local l3 = l1:unshift(2)
	lu.assertEquals(l1, {2,1}) -- unshift
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
end 
-- obj:remove_at(index(1)  return elm, self  
function TestList:test_remove_at()
	local l1=List(1,2,3,4)
	local l2=l1 
	-- index out of range  return nil
	local elm,l3= l1:remove_at(5) 
	lu.assertEquals(l1, {1,2,3,4}) -- unshift
	lu.assertEquals(elm,nil )
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local elm,l3= l1:remove_at(0) 
	lu.assertEquals(l1, {1,2,3,4}) -- unshift
	lu.assertEquals(elm,nil )
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local elm,l3= l1:remove_at(-5) 
	lu.assertEquals(l1, {1,2,3,4}) -- unshift
	lu.assertEquals(elm,nil)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local elm,l3= l1:remove_at(-6) 
	lu.assertEquals(l1, {1,2,3,4}) -- unshift
	lu.assertEquals(elm,nil)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))


	local elm,l3= l1:remove_at(-1) 
	lu.assertEquals(l1, {1,2,3}) -- unshift
	lu.assertEquals(elm,4)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local elm,l3= l1:remove_at(3) 
	lu.assertEquals(l1, {1,2}) -- unshift
	lu.assertEquals(elm,3)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local elm,l3= l1:remove_at(1) 
	lu.assertEquals(l1, {2}) -- unshift
	lu.assertEquals(elm,1)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))

	local l1=List(1,2,3,4)
	local l2=l1 
	local elm,l3= l1:remove_at(-2) 
	lu.assertEquals(l1, {1,2,4}) -- unshift
	lu.assertEquals(elm,3)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local elm,l3= l1:remove_at(-3) 
	lu.assertEquals(l1, {2,4}) -- unshift
	lu.assertEquals(elm,1)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	l1:clear()
	local elm,l3= l1:remove_at(1) 
	lu.assertEquals(l1, {}) -- unshift
	lu.assertEquals(elm,nil)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))


end 
-- -->  obj:remove_at(1) 
function TestList:test_shift()
	local l1=List(1,2,3)
	local l2=l1

	local elm,l3= l1:shift(4) -- don't care  
	lu.assertEquals(l1, {2,3}) -- unshift
	lu.assertEquals(elm,1)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local elm,l3= l1:shift("aoeuaoeu") -- don't care  
	lu.assertEquals(l1, {3}) -- unshift
	lu.assertEquals(elm,2)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local elm,l3= l1:shift()
	lu.assertEquals(l1, {}) -- unshift
	lu.assertEquals(elm,3)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local elm,l3= l1:shift()
	lu.assertEquals(l1, {}) -- unshift
	lu.assertEquals(elm,nil)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))

end 
--  obj:remove_at(-1) 
function TestList:test_pop()
	local l1=List(1,2,3)
	local l2=l1

	local elm,l3= l1:pop(4) -- don't care  
	lu.assertEquals(l1, {1,2}) -- unshift
	lu.assertEquals(elm,3)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local elm,l3= l1:pop("aoeuaoeu") -- don't care  
	lu.assertEquals(l1, {1}) -- unshift
	lu.assertEquals(elm,2)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local elm,l3= l1:pop()
	lu.assertEquals(l1, {}) -- unshift
	lu.assertEquals(elm,1)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	local elm,l3= l1:pop()
	lu.assertEquals(l1, {}) -- unshift
	lu.assertEquals(elm,nil)
	lu.assertTrue(addrcheck(l1,l2) and addrcheck(l1,l3))
	
end 
function TestList:test_concat()
	local l1=List(1,2,3,4)
	lu.assertEquals(l1:concat(),"1234")
	lu.assertEquals(l1:concat(","),"1,2,3,4")
	lu.assertEquals(List():concat(","),"")
	lu.assertEquals(List():concat(),"")
end 

function TestList:test_each()
	local l1=List(1,2,3,4)
	local l2=l1
	local count=0
	local sum=0
	l1:reduce( function(elm) count = count +1 ; sum=sum+elm  end  )
	lu.assertTrue( addrcheck(l1,l2))  
	lu.assertEquals( count, 4)
	lu.assertEquals(sum, 10)
end 
function TestList:test_each_with_index()
	local l1=List(1,2,3,4)
	local l2=l1
	local count=0
	local sum=0
	local isum=0
	local chk=true
	l1:each_with_index( function(elm,i) 
		count = count +1
		chk= chk and i== count 
		isum=isum + i 
		sum=sum + elm 
	end  )
	lu.assertTrue( addrcheck(l1,l2))  
	lu.assertEquals( count, 4)
	lu.assertEquals(sum, 10)
	lu.assertEquals(isum, 10)
	lu.assertTrue( chk)

end 

function TestList:test_map()
	local l1 = List(1,2,3,4) 
	local l2 = l1:map() --  clone obj
	lu.assertEquals(l1,l2)
	lu.assertEquals(l2,{1,2,3,4})
	lu.assertTrue(l1 == l2 )
	lu.assertTrue(l2 == {1,2,3,4})
	lu.assertTrue(l1:class() == l2:class() )
	lu.assertFalse( addrcheck(l1,l2) )

	lu.assertEquals(l1:map(function(elm) return elm end ) , {1,2,3,4} )
	lu.assertEquals(l1:map(function(elm) return {elm ,elm} end  ), {{1,1},{2,2},{3,3},{4,4}} )
	lu.assertEquals(l1:map(function(elm) return elm * 2 end ) , {2,4,6,8} )

	--  lua  nil  特性
	lu.assertEquals(l1:map(function(elm,i) return (elm & 1)==1  and elm or nil end ) , {1,3} )
end 

function TestList:test_map_with_index()
	local l1 = List(1,2,3,4) 
	local l2 = l1:map_with_index() --  clone obj
	lu.assertEquals(l1,l2)
	lu.assertEquals(l2,{1,2,3,4})
	lu.assertTrue(l1 == l2 )
	lu.assertTrue(l2 == {1,2,3,4})
	lu.assertTrue(l1:class() == l2:class() )
	lu.assertFalse( addrcheck(l1,l2) )

	lu.assertEquals(l1:map_with_index(function(elm) return elm end ) , {1,2,3,4} )
	lu.assertEquals(l1:map_with_index(function(elm,i) return elm end ) , {1,2,3,4} )
	lu.assertEquals(l1:map_with_index(function(elm,i) return (i & 1)== 1  and elm end ) , {1,false,3,false} )
	lu.assertEquals(l1:map_with_index(function(elm,i) return {i ,elm} end  ), {{1,1},{2,2},{3,3},{4,4}} )
	lu.assertEquals(l1:map_with_index(function(elm,i) return elm * 2 end ) , {2,4,6,8} )

	--  lua  nil  特性
	lu.assertEquals(l1:map_with_index(function(elm,i) return (i & 1)== 1  and elm or nil end ) , {1,3} )
end 
function TestList:test_select()
	local l1 = List(1,2,3,4) 
	local l2 = l1:select(function(elm) return true end ) --  clone obj
	lu.assertEquals(l1,l2)
	lu.assertEquals(l2,{1,2,3,4})
	lu.assertTrue(l1 == l2 )
	lu.assertTrue(l2 == {1,2,3,4})
	lu.assertTrue(l1:class() == l2:class() )
	lu.assertFalse( addrcheck(l1,l2) )


    lu.assertEquals(l1:select(function(elm) return elm end ), {1,2,3,4})
    lu.assertEquals(l1:select(function(elm) return (elm & 1) == 0 end ), {2,4})
    lu.assertEquals(l1:select(function(elm) return elm >2  end ), {3,4})

end 

function TestList:test_select_withe_index()
	local l1 = List(1,2,3,4) 
	local l2 = l1:select_with_index(function(elm) return true end ) --  clone obj
	lu.assertEquals(l1,l2)
	lu.assertEquals(l2,{1,2,3,4})
	lu.assertTrue(l1 == l2 )
	lu.assertTrue(l2 == {1,2,3,4})
	lu.assertTrue(l1:class() == l2:class() )
	lu.assertFalse( addrcheck(l1,l2) )


    lu.assertEquals(l1:select_with_index(function(elm,i) return elm end ), {1,2,3,4})
    lu.assertEquals(l1:select_with_index(function(elm,i) return (i & 1) == 0 end ), {2,4})
    lu.assertEquals(l1:select_with_index(function(elm,i) return i >2  end ), {3,4})

end 

function TestList:testEditdata()
  local list=List()
  local l1 = list:push(1)
  lu.assertEquals(l1,list)
  lu.assertEquals(#l1,1)

  l1=List(1,2,3,4)
  l2=l1
  lu.assertTrue( l1:push(5) == {1,2,3,4,5} )
  lu.assertEquals(tostring(l1),tostring(l2)) lu.assertTrue( l1:append(5) == {1,2,3,4,5,5} )
  lu.assertEquals(tostring(l1),tostring(l2))
  lu.assertTrue( l1:unshift(0) == {0,1,2,3,4,5,5} )
  lu.assertEquals(tostring(l1),tostring(l2))
  lu.assertTrue( l1:insert_at(1,0)=={0,0,1,2,3,4,5,5} )
  lu.assertEquals(tostring(l1),tostring(l2))

  
  l1=List(1,2,3,4)
  l2=l1
  local elm,obj = l1:remove_at(3) 
  lu.assertTrue(obj == {1,2,4} )
  lu.assertEquals(tostring(l1),tostring(obj))
  lu.assertEquals(tostring(l1),tostring(l2))
  lu.assertTrue(elm == 3 )

  lu.assertTrue( List(1,2,3,4):push(5) == {1,2,3,4,5} )
  lu.assertTrue( List(1,2,3,4):append(5) == {1,2,3,4,5} )
  lu.assertTrue( List(1,2,3,4):unshift(0) == {0,1,2,3,4} )
  --- alise from table
  lu.assertTrue( List(1,2,3,4):insert_at(1,0)=={0,1,2,3,4} )


  local elm,obj = List(1,2,3,4):remove_at(3) 
  lu.assertTrue(obj == {1,2,4} )
  lu.assertTrue(elm == 3 )

  lu.assertTrue( List(1,2,3,4):push(5) == {1,2,3,4,5} )
  lu.assertTrue( List(1,2,3,4):append(5) == {1,2,3,4,5} )
  lu.assertTrue( List(1,2,3,4):unshift(0) == {0,1,2,3,4} )
  --- alise from table
  lu.assertTrue( List(1,2,3,4):insert_at(1,0)=={0,1,2,3,4} )


  local elm,obj = List(1,2,3,4):remove_at(3) 
  lu.assertTrue(obj == {1,2,4} )
  lu.assertTrue(elm == 3 )

  local elm,obj = List(1,2,3,4):pop()
  lu.assertTrue( obj == {1,2,3} )
  lu.assertTrue(elm == 4 )
  local elm,obj = List(1,2,3,4):shift()
  lu.assertTrue(obj == {2,3,4} )
  lu.assertTrue(elm == 1)

end

function TestList:testFind()
  local l1=List(1,2,3,4)
  lu.assertEquals( l1:find(3),3)
  lu.assertEquals( l1:find(5),nil)
  lu.assertEquals( l1:find(function(elm,arg) return elm == arg end , 4), 4)
  local l1=List({1,2},{3,4},{5,6})
  lu.assertEquals( l1:find(function(elm,arg) return elm[1] == arg[1] and elm[2]==arg[2] end ,
      {3,4} ),{3,4} )
  -- test List.__eq 
  local l1=List(List(1,2),List(3,4),List(5,6))
  lu.assertEquals( l1:find(function(elm,arg) return elm==arg end ,
      {3,4} ),{3,4} )
  lu.assertEquals( l1:find({3,4}), {3,4})

  

  

end


assert(  lu.LuaUnit )
assert(  lu.LuaUnit.run)
--os.exit( lu.LuaUnit.run() )
return TestList
