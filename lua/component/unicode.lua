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

local M={}
function M.init(env)
end
function M.fini(env)
end
-- Ucode
-- patterns:
--    unicode: "U([a-h0-9]+)"
function M.func(input,seg,env)
  local ucodestr = seg:has_tag("unicode") and input:match("U(%x+)")
  if ucodestr and #ucodestr>1 then
    local code= tonumber(ucodestr,16)
    local text = utf8.char( code )
    yield(
    Candidate( "unicode", seg.start, seg._end, text, string.format("U%x",code) ))
    if #ucodestr < 5 then
      for i=0,15 do
        local text = utf8.char( code * 16 + i)
        yield(
        Candidate( "unicode", seg.start, seg._end, text, string.format("U%x~%x",code,i) ))
      end
    end
  end
end

return M

