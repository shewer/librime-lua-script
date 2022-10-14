#! /usr/bin/env lua
--
-- calss.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--

local B={}
B.__index = B
function B:_initialize(...)
  return self
end
function B:_New_obj(...)
  local obj=setmetatable({}, self)
  obj._addr = tostring(obj):match("0x%x+$")
  obj = obj:_initialize(...)
  return obj
end
function B:_New_class(...)
  local obj=setmetatable({}, self)
  obj._addr = tostring(obj):split(":")[2]
  self.__call = self.__call or B._New_obj

  obj=obj:_initialize(...)
  return obj
end
B.__call = B._New_obj
B.__name = 'Class'


local function class(klass, super)
  klass = klass or {}
  super = super or B
  klass.__index = klass.__index or klass
  klass.__call = klass.__call or super._New_obj
  setmetatable(klass,super)
  return klass
end


return class
