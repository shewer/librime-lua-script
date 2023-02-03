#! /usr/bin/env lua
--
-- helper.lua
-- Copyright (C) 2023 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
--[[
helper of test module
M:reset() -- reload M.test_files
M:test(path_name,func_name,_env, format)
M:to_string(path, func_name)  name\t full_name\n ....
M:get_test(path, func_name) -- { { name , full_name}, ...}
member:
M.test_files { {item_name,full_filename }.....}
M.test_path  string

--]]
--require 'tools/debugtool'
--require 'tools/_log'
--require 'tools/profile'
--pr=newProfiler()
local function __FILE__(n) n=n or 2 return debug.getinfo(n,'S').short_src end
local function __LINE__(n) n=n or 2 return debug.getinfo(n, 'l').currentline end
local function __FUNC__(n) n=n or 2 return debug.getinfo(n, 'n').name end
local lu=require('test/luaunit').LuaUnit.new()

local M={}
M.test_path= __FILE__():match("(.+)/helper.lua$")
print("",M.test_path,__FILE__())

local function load_test_from_files(test_path)
  local tab={}
  local pattern = "^([^#]+)_test.lua$"
  for test_file in io.open(test_path .. "/".. "files"):lines() do
    local test_name =test_file:match(pattern)
    if not test_file:find("#") and test_name then
      local test_name=test_file:match(pattern)
      local full_path = test_path .. "/" .. test_file
      if test_name and full_path then
        table.insert(tab, {test_name, full_path})
      end
    end
  end
  return tab
end

local function match_func(tests,path,func_name)
  local tab = {}
  path = path or ''
  func_name = func_name or ''
  local slash= #path > 0 and package.config:sub(1,1) or ''
  local underscore= #func_name > 0 and '_' or ''
  local pattern =("^%s%s[%%a_-]*%s%s$"):format(path, slash ,underscore, func_name)
  for _,item in ipairs(tests) do
    if item[1]:match(pattern) then
      table.insert(tab, item)
    end
  end
  return tab
end
function M:reset()
  self.test_files= load_test_from_files(self.test_path)
end

function M:get_list(path,func_name)
  return path and func_name
  and match_func(self.test_files, path, func_name)
  or self.test_files
end
function M:to_string(path,func_name)
  local tab={}
  for i,item in ipairs( self:get_list(path,func_name)) do
    table.insert(tab, table.concat(item,'\t'))
  end
  return table.concat(tab,'\n')
end

function M:test(path,func_name, _env, format,_exit)
  lu:setOutputType(format or 'text')--"text")
  -- loadfile and conver test_list_tab
  print('Test from:', path, func_name)
  local test_list_tab ={}
  for i,v in ipairs( self:get_list(path,func_name) ) do
    local test_item = loadfile( v[2], 'bt',_env or _ENV)()
    print('\tload test  ',v[1],v[2],test_item)
    table.insert(test_list_tab, test_item and  { v[1], test_item} or nil)
  end
  if #test_list_tab == 0 then
    return
  end
  -- test { { test_name , test_tab },...}
  lu:runSuiteByInstances(test_list_tab or {})--,{'-q','-o',"tap"}) --{'-o','text'} )--format)
  if exit_ or lu.result.failureCount >0 or lu.result.errorCount > 0 then
    os.exit()
  end
  return lu.result
end

M:reset()

return M
