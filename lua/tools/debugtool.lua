#! /usr/bin/env lua
--
-- debugtool.lua
-- Copyright (C) 2021 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
-- puts(tag,...)
-- DEBUG --> log.error
-- WARN  --> log.warning
-- INFO  --> log.info
-- CONSOLE --> print
--
-- ex:
-- test.lua
--
-- local puts = require 'tools/debugtool'
-- --set tag D103 C102
-- local D103= DEBUG .. "103"
-- local C102= CONSOLE .. "102"
-- local C103= nil
--
--
-- puts(ERROR,__FILE__(),__LINE__(),__FUNC__(), 1, 2 , 3 )
--    --> log.error( "error" .. tran_msg(...))
--
-- puts(DEBUG,__FILE__(),__LINE__(),__FUNC__(), 1, 2 , 3 )
--    --> log.error( DEBUG .. tran_msg(...))
--
-- puts(D103,__FILE__(),__LINE__(),__FUNC__(), 1 2 3)
--    --> log.error("trace103" .. tran_msg(...)
--
-- puts(C102,__FILE__(),__LINE__(),__FUNC__(), 1 2 3)
--    --> print("console103" .. tran_msg(...)
--
-- puts(C103,__FILE__(),__LINE__(),__FUNC__(), 1 2 3)
--   -->  pass
--
--
--
-- puts(DEBUG,__FILE__(),__LINE__(),__FUNC__() , ...)
-- puts(INFO,__FILE__(),__LINE__(),__FUNC__() , ...)
--
-- global variable
function __FILE__(n) n=n or 2 return debug.getinfo(n,'S').soruce end
function __LINE__(n) n=n or 2 return debug.getinfo(n, 'l').currentline end
function __FUNC__(n) n=n or 2 return debug.getinfo(n, 'n').name end
INFO="log"
WARN="warn"
ERROR="error"
DEBUG="trace"
CONSOLE="console"




local function tran_msg(...)
  local msg="\t"
  for i,k in next, {...} do msg = msg .. ": " .. tostring(k)  end
  return msg
end
local function  push_error_log(msg)
  __ERROR_LIST_TAB = __ERROR_LIST_TAB or List()
  __ERROR_LIST_TAB:push(msg)
  local rm_size = #__ERROR_LIST_TAB - __ERROR_LIST
  if rm_size >0 then
    for i=1, rm_size do
      __ERROR_LIST_TAB:shift()
    end
  end

end
local function puts( tag , ...)
  if type(tag) ~= "string" then return end
  local func = print
  local f_info=false

  if INFO and tag:match("^" .. INFO) then
    func = log and log.info or print
  elseif WARN and tag:match("^" .. WARN) then
    func = log and log.warning or print
    f_info=true
  elseif ERROR and tag:match("^" .. ERROR) then
    func = log and log.error or print
    f_info=true
    if __ERROR_LIST then
      push_error_log(msg)
    end
  elseif DEBUG and tag:match("^" .. DEBUG) then
    func = log and log.error or print
    f_info=true
    if __ERROR_LIST then
      push_error_log(msg)
    end
  elseif  CONSOLE and tag:match( "^" .. CONSOLE ) then
    func = print
  else
    return
  end
  local msg = tran_msg(...)
  if f_info then
    local n=2
    local info= debug.getinfo(n,'nSl')
    msg = string.format("%s %s[%s](%s)",
    tag, info.short_src:match(".?(lua[\\/].+)$"), info.name, info.currentline)
    .. msg
  end
  func( msg )
end

return puts
