#! /usr/bin/env lua
--
-- set.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--


local function __Set(...)
  local tab={}
  for _,v in next , {...} do 
    tab[v] = true
  end
  return tab
end
Set = Set or __Set

