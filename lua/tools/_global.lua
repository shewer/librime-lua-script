#! /usr/bin/env lua
--
-- _global.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
--  File tools
--  rpath() return current path, file
--  exists(path) return bool
--  isFile(path) return bool
--  isDir(path) return bool
--
-- trace


--- global init
-- append string.methods   split utf8_len utf8_split
require 'tools/string' -- 加入 utf8_len utf8_sub split function
require 'tools/_log'  --  _G 加入 Log(type,args.....)
require 'tools/_file' -- _G 加入 rpath() get_full_path(filename) isDir(path) isFile(path)
require 'tools/_req_api' -- _G 加入 rrequire(mod:string [gtab=_ENG [,mod_name=mod]])
-- bind  split  utf8_sub utf8_sub utf8_split
require 'tools/_ticket' -- _G 加入類 Ticket(eng,ns,prescription)
require 'tools/rime_api' -- 擴充 rime_api 及常數 (見 rime_api.lua)
-- prerequire for save to __PKG_LOADED
require 'tools/english_dict'
if LevelDb then
  require 'tools/leveldb'
end

if rime_api.Version() < 150 then
  require 'tools/_shadowcandidate'
end
-- append utf8.methods utf8.split

--append_path(...)  paths   + "/?.lua" paths + /?/init.lua
function append_path(...)
  local slash = package.config:sub(1,1)
  local paths = package.path:split(";")
  local res =false
  for i,vs in next, {...} do
    local path1 = ("%s/?.lua"):format(vs):gsub("/",slash)
    local path2 = ("%s/?/init.lua"):format(vs):gsub("/",slash)
    for i,v in next, {path1,path2} do
      if not paths:find(v) then
        paths:push(v)
        res = res or true
      end
    end
  end

  if res then
    package.path= paths:concat(";")
    return true
  end
  return false
end

--append_cpath(...) paths + /?.(dll|so|dylib)
function append_cpath(...)
  local slash = package.config:sub(1,1)
  local df = package.cpath:match('?.so')
  or package.cpath:match('?.dylib')
  or package.cpath:match('?.dll')
  local paths = package.cpath:split(";")
  local res =false

  for i,v in next, {...} do
    local path= ("%s/%s"):format(v,df):gsub("/",slash)
    if not paths:find(path) then
      paths:push(path)
      res = true
    end
  end

  if res then
    package.cpath= paths:concat(";")
    return true
  end
  return false
end




-- init_path
do
  __PKG_LOADED = {}
  for k,v in next, package.loaded do __PKG_LOADED[k] = v end
  append_path((rime_api.get_user_data_dir() or ".") .. "/lua/component")
  append_cpath((rime_api.get_user_data_dir() or ".") .. "/lua/plugins")
  -- _G 加入 Rescue
  if ENABLE_RESCUE then rrequire('Rescue') end

  -- ENABLE trace
  for opt in (os.getenv('RIME_OPT') or ""):gmatch("[^%s]+") do
    _ENV[opt] = true
    TRACE = TRACE or T00 or T01 or T02 or T03 or T04
  end

  if ENABLE_DEBUG or TRACE then
    require 'tools/debugtool'
  end
  -- pretest 在無關 engine 時測試 library
  if PRETEST then require('test/init')() end


  if T00 and GD then GD() end

end
