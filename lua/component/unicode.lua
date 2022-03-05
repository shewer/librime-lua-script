#! /usr/bin/env lua
--
-- unicode.lua
-- Copyright (C) 2021 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--

-- 1 copy this file in  lua/component/uincode.lua
-- 2 rime.lua
--   uincode = require('component/unicode')
--
-- 3 schema.yaml
--   recognizer/patterns/unicode: "U[a-h0-9]+"
--   engine/translators
--     - lua_translator@unicode  -- append
--


--[[
--  unicode(number)  to utf8 (char)
local function unicode(u)
  if u >>7 == 0 then return string.char(u) end
  local count = 0x80
  local tab={}
  repeat
    count = count >> 1 | 0x80
    table.insert(tab,1, u & 0x3f |0x80 )
    u = u >> 6
  until u < 0xc0
  table.insert(tab,1,count | u )
  for i,v in ipairs(tab) do print(i,v) end
  return string.char( table.unpack(tab)  )
end

--]]


local function init(env)
end
local function fini(env)
end
-- Ucode,code,code....
-- patterns:
--    unicode: "U([a-h0-9]+,?)+"
local function func1(input,seg,env)
  if seg:has_tag("unicode") then
    local ucodestr=  input:sub( seg.start+1+1, seg._end) -- lua index=1 , skip "U"
    local comment= string.format("%s,%d,%d",ucodestr,seg.start,seg._end)

    local codes={}
    for item in ucodestr:gmatch("([a-f0-9]+),?") do
      table.insert(codes,tonumber(item,16) )
    end

    local text = utf8.char(table.unpack(codes) )
    yield(
      Candidate( "unicode", seg.start, seg._end, text,comment ) )
  end
end
-- Ucode
-- patterns:
--    unicode: "U([a-h0-9]+)"
local function func2(input,env)
  if seg:has_tag("unicode") then
    local ucodestr=  input:sub( seg.start+1+1, seg._end) -- lua index=1 , skip "U"
    local comment= string.format("%s,%d,%d",ucodestr,seg.start,seg._end)
    local text = utf8.char( tonumber(uncodestr,16) )
    yield(
      Candidate( "unicode", seg.start, seg._end, text,comment ) )
  end
end

return {init=init,fini=fini,func=func1 }

