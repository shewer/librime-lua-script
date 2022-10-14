#! /usr/bin/env lua
--
-- init.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
require 'tools/_file'
local path,file= rpath()
local tab ={}
for i,spath in next, {'proc','segm','tran','filter'} do
  tab._module = tab._module or true
  local fpath= ("%s.%s"):format(path,spath)
  local ok,m = pcall(require,fpath)
  tab[spath] = ok and  m or nil
end

return tab
--return {"proc",'filter',}

