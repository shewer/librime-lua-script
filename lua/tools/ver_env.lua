#! /usr/bin/env lua
--
-- ver_env.lua
-- Copyright (C) 2023 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
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

local Ver = _VERSION:match("%d.%d$")
Ver = Ver and Ver or "5.1"
Ver = Ver == "5.1" and jit and "jit" or Ver
local M={}
M['5.1'] =function()
  _G['_ENV']= _G
  _G['warn']=warn
end
M['5.2'] =function ()
  _G['warn']=warn
end
M['5.3'] =function ()
  _G['warn']=warn
end
M['jit'] =function ()
  _G['_ENV']= _G
  _G['warn']=warn
end
M[Ver]()

return true


