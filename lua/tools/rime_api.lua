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



local function Version()
  local ver
  if rime_api.get_distribution_name then
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

List = require'tools/list'
require 'tools/string'
--Component = Version() >= 177  and Component or require('tools/_component')
local w_leveldb = LevelDb and require('tools/leveldb')






--  舊的版本 使用 lua_function  轉換  且 模擬 :apply(str) 接口
local function old_Init_projection(config,path)
  local patterns=List()
  for i=0,config:get_list_size(path)-1 do
    patterns:push( config:get_string(path .. "/@" .. i ) )
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

function Init_projection( config, path)
  --  old version
  if Version() < 102 then
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


-- ConfigItem
local CI={}
function CI.Config_item_to_obj(config_item,level)
    level = level or 99
    if level <1 then return config_item end

    if not config_item or not config_item.type then return nil end
    if config_item.type == "kList" then
      local cl= config_item:get_list()
      local tab={}
      for i=0,cl.size-1 do
        table.insert(tab, CI.Config_item_to_obj( cl:get_at(i), level -1 ))
      end
      return tab
    elseif config_item.type == "kMap" then
      local cm = config_item:get_map()
      local tab={}
      for i,k in next,cm:keys() do
        tab[k] = CI.Config_item_to_obj( cm:get(k), level -1)
      end
      return tab
    elseif config_item.type == "kScalar" then
      return config_item:get_value().value
    else return nil end
end
-- Config method clone_configlist write_configlist
-- Env(env):config():clone_configlist("engine/processors") -- return list of string
-- Env(env):config():write_configlist("engine/processors",list)
--
local CN={}
-- clone ConfigList of string to List


function CN.get_obj(config,path,level)
  return CI.Config_item_to_obj( config:get_item(path or ""),level)
end
function CN.clone_configlist(config,path)
  if not config:is_list(path) then
    Log(WARN, "clone_configlist: ( " .. path  ..  " ) was not a ConfigList " )
    return nil
  end
  return List( CI.Config_item_to_obj(config:get_item(path)) )
end

-- List write to Config
function CN.write_configlist(config,path,list)
  list:each_with_index(
  function(config_string,i)
    config:set_string( path .. "/@" .. i-1 , config_string)
  end )
  return #list
end
--
function CN.find_index(config,path,str)
  if not config:is_list(path) or 1 > config:get_list_size(path)   then
    return
  end
  local size = config:get_list_size(path)
  for i=0,size -1 do
    local ipath= path .. "/@" .. i
    if config:is_value(ipath) and  config:get_string(ipath ):match(str) then
      return e
    end
  end
end
-- just for list of string for now
function CN.config_list_insert(config,path,obj,index)
  if config:is_null(path) then
    local clist= ConfigList()
    clist:append( ConfigValue(str).element )
    config:set( path, clist.element )
    return true
  end
  if not config:is_list(path) then return end
  local size = config:get_list_size(path)
  index = index and index <= size and index or size
  local ipath = path .. "/@before " ..index
  local ctype= type(obj)
  if type(obj) == "string" then
    config:set_string(ipath , obj )
    return true
  end
  return false
end

function CN.config_list_append(config ,path, str)

  if config:is_null(path) then
    local clist= ConfigList()
    clist:append( ConfigValue(str).element )
    config:set_item( path, clist.element )
    return true
  end
  local list = assert( config:get_list(path) , ("%s:%s: %s not a List"):format( __FUNC__(),__LINE__(), path))
  if list and not index then
      list:append( ConfigValue(str).element )
      return true
  else
      return false
  end
end

function CN.config_list_replace(config,path, target, replace )
  --local index=config:find_index( path, target)
  local size= config:is_list(path) and config:get_list_size(path)
  for i = 0,size - 1 do
    local ipath= path .. "/@" .. i
    local l_str= config:get_string( ipath )
    if l_str and l_str:match(target) then
      config:set_string(ipath, replace )
      return true
    end
  end
  return false
end
----- rime_api tools
local M= rime_api or _ENV['rime_api']
M.Version=Version
function M.Ver_info()
  local msg1 = rime_api.get_user_id and string.format(" %s %s %s (id:%s) ",
  rime_api.get_distribution_name(),
  rime_api.get_distribution_code_name(),
  rime_api.get_distribution_version(),
  rime_api.get_user_id()) or ""
  local msg2 = string.format(" Ver: librime %s librime-lua %s lua %s",
  rime_api.get_rime_version() , Version() ,_VERSION )
  return msg1 .. msg2
end
-- Context method
-- Env(env):context():Set_option("test") -- set option "test" true
--                    Unset_option("test") -- set option "test" false
--                    Toggle_option("test")  -- toggle "test"
--  Projection api
M.Projection=Init_projection
function M.load_reversedb(dict_name)
  -- loaded  ReverseDb
  local reversedb = ReverseLookup
  and ReverseLookup(dict_name)
  or  ReverseDb("build/".. dict_name .. ".reverse.bin")
  if not reversedb then
    log.warning( env.name_space .. ": can't load  Reversedb : " .. reverse_filename )
  end
  return reversedb
end

return M
