#! /usr/bin/env lua
--
-- multiswitch.lua
-- Copyright (C) 2021 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
--      MultiSwitch extend List
--  MS=require 'multi_reverse/multiswitch'
--  ms= MS("a","b","c","d")
--  ms() -- return "a"
--  ms:toggle() return ""
--  ms:toggle() return "a"
--  ms:set_status(true) "a"
--  ms:set_status(false) ""
--  ms:on() --> set_status(false)
--  ms:off() --> set_status(true)
--  ms:next() ms:next(

local M = {}
function M:size()
  return #self
end
function M:status(set)
  if set ~=nil then
    self._status = set and true or false
  end
  return self._status and self[self._index+1] or ""
end
function M:toggle()
  return self:status( not self._status )
end
function M:on()
  return self:status(true)
end
function M:off()
  return self:status(false)
end
function M:index(i)
  if type(i) == "number" then
    self._index = i % #self
  end
  return self._index
end

function M:next(i)
  self:index( self:index() + (i or 1) )
  return self:status()
end
function M:prev(i)
  self:index( self:index() - (i or 1) )
  return self:status()
end
M.__index = M


local function ms(tab)
  tab._index = 0
  tab._status= true
  return setmetatable(tab,M)
end
return ms

