#! /usr/bin/env lua
--
-- objtest.lua
-- Copyright (C) 2021 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--

require 'tools/object_new'
lu= require 'tools/luaunit'

local List = Class("List")
function List:each(func)
  for i,v in pairs(self) do 
    func(v)
  end 
end 
function List:_init(...)
  local tab= {...}
  tab=  #tab == 1 and tab[1] == "table" and tab[1] or tab
  for i,v in ipairs(tab) do 
    self:push(v)
  end
  return self 
end 
function List:insert_chk(v)
  return v ~= nil 
end 
function List:push(v)
  if self:insert_chk(v) then 
    table.insert(self,v)
    return self,true 
  end 
  return self, false
end 
local T={}
function T:Setup()
  --self.obj1=Object()
  self.obj2=Object:New() 
end 
function T:tearDown()
  self.obj1=nil
  self.obj2=nil
end  
function T:test_Object()
  lu.assertIsNil(Class:Superclass() )
  lu.assertIsNil(Object:Superclass() )
  lu.assertEquals(Object():class() ,Object )
  lu.assertEquals(Object():class(), Object )
end 
function T:test_superclass()

  local NC= Class("NC",Object)
  local NC1=Class("NC1")
  lu.assertEquals( NC:Superclass() , Object )
  lu.assertEquals( NC1:Superclass() , Object )
  lu.assertIsNil(Object():class():Superclass()  )
  lu.assertError( NC():name() == "#NC" )


end 
function T:test_Class()
  lu.assertEquals(Object:class() , Class )
  lu.assertEquals(Object:class() , Class)
  lu.assertEquals(Class:class() , Class )
end 

function T:test_error()
  --lu.assertError( self.obj1() )
  --lu.assertError( self.obj1:New() )
  --lu.assertError(obj:New() )
  --lu.assertError(self.obj1:Superclass() )
end 
function T:test_NewClass()



  local ll=List(1,2,3,4)
  lu.assertEquals(#ll, 4)
  ll:push(5)
  lu.assertError(#ll,5)
  ll:each(print)
  lu.assertEquals(ll , {1,2,3,4,5})

end 
function T:test_super()
  -- self:super( method_name  , ...)  -- __FUNC__()
  local M=Class("M", List)
  function M:push(elm)
    self:super(__FUNC__(), elm +10)
  end 
  m=M(1,2,3)
  m:push(3)
  lu.assertEquals(m, {11,12,13,13})
end 

Test=T
--os.exit( lu.LuaUnit.run() ) 
return T
