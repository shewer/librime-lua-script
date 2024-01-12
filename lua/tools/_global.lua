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

local function find_ver()
  if UserDb and TableDb then
    return 240
  elseif UserDb then
    return 222
  -- 禁用觸發 opencc
  --elseif Opencc and Opencc('s2t.json').convert_word then
    --return 200
  elseif rime_api.regex_match then
    return 197
  elseif rime_api.get_distribution_name then
    return 185
  elseif LevelDb then
    return 177
  elseif Opencc then
    return 147
  elseif KeySequence and KeySequence().repr then
    return 139
  elseif  ConfigMap and ConfigMap().keys then
    return 127
  elseif Projection then
    return 102
  elseif KeyEvent then
    return 100
  elseif Memory then
    return 80
  elseif rime_api.get_user_data_dir then
    return 9
  elseif log then
    return 9
  else
    return 0
  end
end


--- global init
require 'tools/compat'   -- compat : warn  _ENV  
-- librime-lua version 
_G["_RL_VERSION"] = _G["RL_VERSION"] or find_ver()

-- append string.methods   split utf8_len utf8_split
require 'tools/string' -- 加入 utf8_len utf8_sub split function
require 'tools/_log'  --  _G 加入 Log(type,args.....)
require 'tools/_file' -- _G 加入 rpath() isDir(path) isFile(path)
--require 'tools/_req_api' -- 停用 _G 加入 rrequire(mod:string [gtab=_ENG [,mod_name=mod]])
-- bind  split  utf8_sub utf8_sub utf8_split
--require 'tools/_ticket' -- 停用 _G 加入類 Ticket(eng,ns,prescription)
require 'tools/rime_api' -- 擴充 rime_api 及常數 (見 rime_api.lua)
-- prerequire for save to __PKG_LOADED

if Component then 
  require 'tools/_component' -- 擴充 Require(...) 可以自動選定 Processor , Segmentor , Translator , Filter
end
--append_path(...)  paths   + "/?.lua" paths + /?/init.lua
function append_path(...)
  local List = require "tools/list"
  local slash = package.config:sub(1,1)
  local path = package.path:gsub(";$","")
  local paths=List(path)

  local path_set = Set( path:split(";") )

  local pattern = List("%s/?.lua", "%s/?/init.lua")
  List(...):each(function(elm)
    pattern:map(function(p) return p:format(elm):gsub("/",slash) end)
    :each(function(v)
      if not path_set[v] then 
        path_set[v]=true
        paths:push(v)
      end
    end)
  end)
  package.path= paths:concat(";")
  return #paths > 1 
end

--append_cpath(...) paths + /?.(dll|so|dylib)
function append_cpath(...)
  local List = require('tools/list')
  local slash = package.config:sub(1,1)

  local cpath = package.cpath:gsub(";$","")
  local df = cpath:match('?.so')
  or cpath:match('?.dylib')
  or cpath:match('?.dll')

  local paths=List(cpath)
  local path_set = Set(cpath:split(";"))

  List(...):map(
  function(elm) return  ("%s/%s"):format(elm,df):gsub("/",slash) end)
  :each(function(v)
    if not path_set[v] then
      path_set[v]=true
      paths:push(v)
    end
  end)

  package.cpath=  paths:concat(";")
  return #paths >1
end

require('croissant.debugger')()


-- init_path
do
  -- 環境設定
  __PKG_LOADED = {}
  for k,v in next, package.loaded do __PKG_LOADED[k] = v end
  -- 通用 component path
  append_path((rime_api.get_user_data_dir() or ".") .. "/lua/component")
  -- 放置 動態程式 path
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
  if _TEST then
    luatest_proc= require 'test'
  end


  if T00 and GD then GD() end

end
