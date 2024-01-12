#! /usr/bin/env lua
--
-- ver_env.lua
-- Copyright (C) 2023 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
-- wrap  function warn()
-- compat lua 5.1 5.2 5.3 jit :  wran
-- compat lua 5.1 jit :  _G = _ENV
--
local _warn_enable=false
local function warn(...)
  local msgs= {...}
  if #msgs == 1 and msgs[1] == '@on' then
    _warn_enable=true
  elseif #msgs==1 and  msgs[1] == "@off" then
      _warn_enable=false
  else
    if _warn_enable then
    io.stderr:write( table.concat(msgs).. "\n")
    end
  end
end

_G['warn'] = _G['warn'] or warn
_G['_ENV'] = _G['_ENV'] or _G

return true


