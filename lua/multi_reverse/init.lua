#! /usr/bin/env lua
--
-- init.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
require 'tools/debugtool'
local path,file= rpath()
print(path,file ,'args:',...)
local tab ={
  _modules= file == "init.lua"
}  
for i,spath in next, {'proc','segm','tran','filter'} do 
   local fpath= ("%s.%s"):format(path,spath)
   local ok,m = pcall(require,fpath)
   tab[spath] = ok and  m or nil
end

return tab
--return {"proc",'filter',}

