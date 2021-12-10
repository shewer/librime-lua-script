#! /usr/bin/env lua
--
-- debugtool.lua
-- Copyright (C) 2021 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
-- global var  DEBUG  to enable  puts(...) 
-- 
-- puts(group,...)
--
--
-- puts("a",__FILE__(),__LINE__(),__FUNC__() , ...)
-- puts("b",__FILE__(),__LINE__(),__FUNC__() , ...)
--
-- DEBUG= ""   print all group
-- DEBUG= "a"  print "a*" group to log.error
-- INFO= "log"   print "log" group to log.info
-- CONSOLE="log" print "log" group to console
--
function __FILE__(n) n=n or 2 return debug.getinfo(n,'S').soruce end
function __LINE__(n) n=n or 2 return debug.getinfo(n, 'l').currentline end
function __FUNC__(n) n=n or 2 return debug.getinfo(n, 'n').name end


local function tran_msg(...)
  local msg=""
  for i,k in next, {...} do msg = msg .. ": " .. tostring(k)  end 
  return msg 
end 
local function puts( group , ...)
  if INFO and group:match(INFO) then 
    (log and log.info or print)("info: " .. tran_msg(...)) 
  end 
  if DEBUG and group:match(DEBUG) then 
    (log and log.error or print)( "debug: " .. tran_msg(...)) 
  end
  if  CONSOLE and group:match( CONSOLE ) then 
    ( print)( "console: " .. tran_msg(...)) 
  end
  
end 

return puts
