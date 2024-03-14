#! /usr/bin/env lua
--
-- tools/rime_api.lua
-- 補足 librime_lua 接口 不便性
-- Copyright (C) 2020 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
--------------------------------------------
-- add List() Env(env)   Init_projection(config,path) in  global function
-- bool isDir(path)
-- bool isFile(path)
-- void Log(
--
-- Env(env)   wrap env table
--   env:config()  wrap config userdata
--   env:context() wrap context userdata
--   env:get_status() get_status
--
--   config: clone_configlist(path)  --return list
--           write_configlist(path, list)
--
--   context: context:Set_option(name)  set  true
--   context: context:Unset_option(name)  set false
--   context: context:Toggle_option(name)  toggle
--
--   Init_prejection(config,path) -- return projection obj
--   -- ex:
--      local projection= Init_projection(config,"preedit_format")
--      projection:apply("abcd")  -- return  preedit string
--
--   -- ex:
--     local api=require 'tools/rime_api'
--     Env(env)
--     env:get_status() -- return status of table
--

-- 2021.4
-- 2021.4 支援 ConfigList ListItem ConfigValue ConfigMap Projection Memory
--

-- add global var:
--   List  : module
--   Log   : func warp log.info ...
--   Env(env) env  : api of env
--   Component :  ver < 177  fake_Component : just for lua_xxxx
-- module:
--  List
--
-- function: Log  Env Init_projection
-- plguin: string
--      string.split(str[,char|pattern:default "%s"]) List
--      string.utf8_len(str) number
--      string.utf8_offset(index) number
--      string.utf8_sub(str, start[,end])  string

-- rime_api append api
--   Verion() number
--   Version_info() string
--
--   V177  LevelDb
--     leveldb_open(filename, dbname)  leveldb
--     leveldb_close(db)
--     leveldb_pool() status of string of db_pool table

--` add func to global  isFile( path)   , isDir(path)

local List = require'tools/list'
require 'tools/string'
if not rime_api then
  require 'test/fake/rime_api'
end
--[[
rime_api.get_user_data_dir=function()
  return io.popen('pwd'):read()
end
rime_api.get_shared_data_dir= function()
  return '/usr/shared/rime-data'
end
--]]




local M = {}
M.__index=M
M.__newindex=function(tab,key,value) end
M.Version=function() return _G["_RL_Version"] end
setmetatable(rime_api,M)




--  舊的版本 使用 lua_function  轉換  且 模擬 :apply(str) 接口
local function old_Init_projection(config,path)
  local patterns=List()
  for i=0,config:get_list_size(path)-1 do
    table.insert( patterns,  config:get_string(path .. "/@" .. i ) )
  end
  local make_pattern=require 'tools/pattern'
  local projection = patterns:map(function(pattern) return make_pattern(pattorn) end )
  -- signtone
  function projection:apply(str)
    return self:reduce(
    function(pattern_func,org) return pattern_func(org) end , str )
  end
  return projection
end
--  xform xlit ...  轉換
--  projection=Init_projection(config, "translator/preedit_format")
--  projection:apply( code )

local function Init_projection( config, path)
  --  old version
  if rime_api.Version() < 102 then
    return old_Init_projection(config,path)
  end
  local patterns= config:get_list( path )
  if not patterns then
    Log(WARN, "configlist of " .. path .. "is null" )
  elseif patterns.size <1 then
    Log(WARN, "configlist of " .. path .. "size is 0" )
  end
  local projection= Projection()
  if  patterns then
    projection:load(patterns)
  else
    Log(WARN, "ConfigList of  " .. path  ..
      " projection of comment_format could not loaded. comment_format type: " ..
      tostring(patterns) )
  end
  return projection
end


----- rime_api tools

local function Ver_info()
  GD()
  local msg1 = rime_api.get_user_id and string.format(" %s %s %s (id:%s) ",
  rime_api.get_distribution_name(),
  rime_api.get_distribution_code_name(),
  rime_api.get_distribution_version(),
  rime_api.get_user_id()) or ""

  local msg2 = string.format(" Ver: librime %s librime-lua %s lua %s",
  rime_api.get_rime_version(), _RL_VERSION, _VERSION )

  return msg1 .. msg2
end

-- librime-lua ver >=9
local udir=rime_api and rime_api.get_user_data_dir() or "."
local sdir=rime_api and rime_api.get_shared_data_dir() or "."
local function get_full_path(filename)
  local fpath = udir .. "/" .. filename
  if file_exists(fpath) then return fpath,udir,filename end
  fpath = sdir .. "/" .. filename
  if file_exists(fpath) then return fpath,sdir,filename end
end

local function load_reversedb(dict_name)
  -- loaded  ReverseDb from ReverseLookup or ReverseDb
  local reversedb = ReverseLookup and ReverseLookup(dict_name)
    or  ReverseDb( get_full_path( "build/".. dict_name .. ".reverse.bin") )

  if reversedb then return reversedb end
  log.warning( env.name_space .. ": can't load  Reversedb : " .. reverse_filename )
end

--warp LevelDb with db_pool，避免重覆開啓異常
M.UserDb= _RL_VERSION >=177 and require 'tools/_userdb' or nil

M.Ver_info=function() return M.VER_INFO end
M.Version = function() return _RL_VERSION end
M.Projection= Init_projection -- warp Projection()
M.ReverseDb= load_reversedb -- warp ReverseDb()
M.get_librime_lua_version = rime_api.Version
M.get_full_path= get_full_path
-- const var

M.VER_INFO= Ver_info()
M.LIBRIME_LUA_VER= _RL_VERSION
M.LIBRIME_VER = rime_api.get_rime_version()
M.USER_DIR = rime_api.get_user_data_dir() or "."
M.SHARED_DIR = rime_api.get_shared_data_dir() or "."
-- 棄用 warp Comonent
--Component = Version() >= 177  and Component or require('tools/_component')


return rime_api
