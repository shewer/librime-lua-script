#! /usr/bin/env lua
--
-- multiswitch.lua
-- Copyright (C) 2021 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
MultiSwitch={}


function MultiSwitch:_init(...)
	self:reset()
	return self
end 

-- object method
function MultiSwitch:reset()
	self._index=1
end 

function MultiSwitch:status()
  return self[ self._index ]
end 
function MultiSwitch:next(i)
  i= i or 1
  self._index = (self._index + i )% #self
  self._index = self._index == 0 and #self or self._index
  return self:status()
end
function MultiSwitch:prev(i)
  i= -( i or 1)
  self:next(i)
  return self:status()
end 


-- make metatable  
local List=require'tools/list'
-- add  object  operation function 
MultiSwitch.__add=List.__add    --     a=List(1,2) ; b={3,4} ; newlist =  a + b   newlist= {1,2,3,4}(List) 
MultiSwitch.__shl=List.__shl    --     a=List(1,2,3) ; a  << MultiSwitch(9,8)<< 1 << 3 << { 4,5,6} ; i
							    --         a= {1,2,3,9,8,1,3,4,5,6}(List) 
								--     a=MultiSwitch(1,2) ; a << List(3,4) << 1 << 2 <<{5,6} 
								--         a= {1,2,3,4,1,2,5,6} (Multiswitch)
MultiSwitch.__eq=List.__eq      --     a=List(1,2) ;b=MultiSwitch(1,2) ;c={1,2} ; a == b ; b== a b==c ;a == c



MultiSwitch.__index=MultiSwitch 
MultiSwitch=setmetatable(MultiSwitch, {__index=List,__call=List.New})
--setmetatable(MultiSwitch,{ __call=MultiSwitch.New})
return MultiSwitch

