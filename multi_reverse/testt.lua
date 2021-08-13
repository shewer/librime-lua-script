#! /usr/bin/env lua
--
-- testt.lua
-- Copyright (C) 2021 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
local lu=require'luaunit'
function Test_1()
  lu.assertTrue(true)
end 

local function add(v1,v2)
    -- add positive numbers
    -- return 0 if any of the numbers are 0
    -- error if any of the two numbers are negative
    if v1 < 0 or v2 < 0 then
        error('Can only add positive or null numbers, received '..v1..' and '..v2)
    end
    if v1 == 0 or v2 == 0 then
        return 0
    end
    return v1+v2
end


function testAddPositive()
    lu.assertEquals(add(1,1),2)
end

function testAddZero()
    lu.assertEquals(add(1,0),0)
    lu.assertEquals(add(0,5),0)
    lu.assertEquals(add(0,0),0)
end

os.exit( lu.LuaUnit.run() )
