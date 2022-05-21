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
--   recognizer/patterns/unicode: "U[a-f0-9]+"
--   engine/translators
--     - lua_translator@unicode  -- append
--

local List =require 'tools/list'
local M={}
function M.init(env)
end
function M.fini(env)
end

local function uchar(ucode)
  return utf8.char( tonumber( ucode:sub(1,5),16))
end
--{ "0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f" }
local scode = List.Range(0,15):map(function(elm) return string.format("%x",elm) end)

local function uchars(ucodestr)
  return scode:map( function(elm) return ucodestr .. elm end)
  :map(uchar)
end

-- Ucode
-- patterns:
--    unicode: "U([a-h0-9]+)"
--
function M.func(input,seg,env)
  -- split ucode from input
  local ucodes = List()
  for c in input:gmatch("U(%x+)") do 
    ucodes:push(c)
  end
  if #ucodes < 1  or input:match("U$") then return end

  -- start create candidate data
  local ucodestr = ucodes[#ucodes]
  -- append ucodes to  first candidate 
  yield( Candidate( "unicode", seg.start, seg._end
  , ucodes:map(uchar):concat(), "U" .. ucodestr  ))
  -- add 0~f candidate  ucodestr .. [0~f]
  if #ucodestr < 5 then
    uchars(ucodestr):each_with_index(function(ctext,i)
      -- create comment codestr .. [0-f][0-f]
      local ctexts = #ucodestr < 4
        and " | " .. uchars(ucodestr .. scode[i]):concat() or ""
      local comment_text = (" U%s~%x%s"):format(ucodestr,i-1,ctexts)
      yield( Candidate(
      "unicode", seg.start, seg._end, ctext,comment_text))
    end)
  end
end

return M

