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

local function Version()
  local ver
  if LevelDb then
    ver = 177
  elseif Opencc then
    ver = 147
  elseif KeySequence and KeySequence().repr then
    ver= 139
  elseif  ConfigMap and ConfigMap().keys then
    ver= 127
  elseif Projection then
    ver= 102
  elseif KeyEvent then
    ver = 100
  elseif Memory then
    ver = 80
  else
    ver= 79
  end
  return ver
end

List = require'tools/list'
Log = require 'tools/debugtool'
require 'tools/string'
Component = Version() >= 177  and Component or require('tools/_component')
local w_leveldb = LevlDb and require('tools/leveldb')

-- append  path
local function append_path(...)
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

local function append_cpath(...)
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
do
  append_path((rime_api.get_user_data_dir() or ".") .. "/lua/component")
  append_cpath((rime_api.get_user_data_dir() or ".") .. "/lua/plugin")
--print("*******************************************************")
--package.path:split(";"):each(print)
--package.cpath:split(";"):each(print)
--print("*******************************************************")
end




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


-- context warp
local C={}
function C.Set_option(self,name)
  self:set_option(name,true)
  return self:get_option(name)
end
function C.Unset_option(self,name)
  self:set_option(name,false)
  return self:get_option(name)
end
function C.Toggle_option(self,name)
  self:set_option(name, not self:get_option(name))
  return self:get_option(name)
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
      return i
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
local M={}
M.Version=Version
function M.Ver_info()
  return string.format("Ver: librime %s librime-lua %s lua %s",
  rime_api.get_rime_version() , Version() ,_VERSION )
end
-- Context method
-- Env(env):context():Set_option("test") -- set option "test" true
--                    Unset_option("test") -- set option "test" false
--                    Toggle_option("test")  -- toggle "test"
--  Projection api
local slash = package.config:sub(1,1)
M.Projection=Init_projection
--  filter tools
local function file_exists(file)
  local fn = io.open(file)
  if fn then
    fn:clone()
    return true
  end
end
function M.load_reversedb(dict_name)
  -- loaded  ReverseDb
  local reversedb = ReverseLookup
  and ReverseLookup(dict_name)
  or  ReverseDb("build/".. dict_name .. "reverse.bin")
  if not reversedb then
    log.warning( env.name_space .. ": can't load  Reversedb : " .. reverse_filename )
  end
  return reversedb
end

local function Wrap(obj,name,tab)
  local mt=getmetatable(obj)
  for k,v in next,tab do
    mt[name][k]=v
  end
  return obj
end
function M.wrap_context(env)
    local context=env.engine.context
    return Wrap(context,"methods",C)
end

function M.wrap_config(env)
    local config=env.engine.schema.config
    return Wrap(config,"methods",CN)
end

function M.req_module(mod_name,rescue_func)
  local ok,res = pcall(require, mod_name )
  if ok then return res end
  Log(ERROR, "require module failed ", mod_name )
  return  rescue_func
end

-- env metatable
local E={}
--
function E:Context()
  return rime_api.wrap_context(self)
end
function E:Config()
  return rime_api.wrap_config(self)
end
-- 取得 librime 狀態 tab { always=true ....}
-- 須要 新舊版 差異  comp.empty() -->  comp:empty()
function E:get_status()
  local ctx= self.engine.context
  local stat={}
  local comp= ctx.composition
  stat.always=true
  stat.composing= ctx:is_composing()
  stat.empty= not stat.composing
  stat.has_menu= ctx:has_menu()
  -- old version check ( Projection userdata)
  local ok,empty
  if Version() < 100 then
    ok,empty = pcall(comp.empty)
    empty=  ok  and empty or comp:empty() --  empty=  ( ok ) ? empty : comp:empty()
  else
    empty = comp:empty()
  end
  stat.paging= not empty and comp:back():has_tag("paging")
  return stat
end
function E:tab_to_str_list(obj, path,list)
  --local obj = self:Config():to_obj(path)
  path = path or ""
  list= list or List()
  local tp=type(obj)
  if tp == "string" then
    list:push( string.format("%s:%s",path,obj) )
  elseif  tp == "table"  then
    local is_list= #obj> 0
    for i,v in next, obj do
      local sub_path =  is_list and type(i) == "number"  and "@" .. i - 1 or i
      if type(v) == "table" then
        self:tab_to_str_list(v,path .. "/"  .. sub_path , list)
      else
        list:push( string.format("%s/%s:%s",path,sub_path,v))
      end
    end
  end
  return list
end
function E:config_path_to_str_list(path,list)
  list= list or List()
  local tab=self:Config():get_obj(path)
  return self:tab_to_str_list(tab,path,list)
end


local Config_api =require 'tools/config_api'

-- Config_get_obj(path[,type])  return obj , args: path , type( i
--    type( 1 : ConfigItem 2 : Config of Value or List or Map )
--    type 4 只能單向轉換
function E:Config_conver(obj,_type,path)
  return Config_api.conver_type(obj,_type,path)
end
function E:Config_data_with_path(obj, path)
  return Config_api.to_list_with_path(obj,path)
end
function E:Config_get(path, _type, tpath)
  local pp = _type == 4 and ( tpath or path) or nil
  local o =Config_api.conver_type(
    self.engine.schema.config:get_item(path),
    _type,
    _type == 4 and (tpath or path ) or nil )
  return o
end
function E:Config_set(path, obj)
  return self.engine.schema.config:set_item(path,
  Config_api.to_item(obj))
end

function E:config_path_to_str_list(path)
  return List( self:Config_get(path) )
  :map(function(elm) return elm.path .. ": " .. elm.value end)
end
-- Get_tag  args :  ()  , (nil, "translator") ,("date")
function E:Get_tag(def_tag , ns)
  def_tag = def_tag or "abc" -- default "abc"
  ns = ns or self.name_space -- default env.name_space
  return self.engine.schema.config:get_string( ns .. "/tag") or def_tag
end
function E:Get_tags(ns)
  ns = ns or self.name_space
  return Set(
    self:Config_get( ns .. "/tags"))
end

function E:append_value_before(path, elm, mvalue)
  local obj = self:Config_get(path)
  if type(obj) ~= "table" or #obj < 1 then return end
  local list = List(self:Config_get(path))
  if list:find( elm) then return end
  local index = list:find(mvalue)
  local dpath = index and path .. "/@before " .. index -1 or path .. "/@next"

  if not self:Config_set(dpath, elm) then
    Log(ERROR, "config set ver error","path", path, "value", elm)
  end
end
-- option function

function E:Set_option(name)
  self.engine.context:set_option(name,true)
  return true
end
function E:Unset_option(name)
  self.engine.context:set_option(name,false)
  return false
end
function E:Toggle_option(name)
  local context= self.engine.context
  context:set_option(name, not context:get_option(name))
  return context:get_option(name)
end
function E:Get_option(name)
  return self.engine.context:get_option(name)
end
-- property function
function E:Get_property(name)
  return self.engine.context:get_property(name)
end
function E:Set_property(name,str)
  self.engine.context:set_property(name,str)
  return str
end

-- processor function  config
function E:get_keybinds(path)
  path = path or self.name_space .. "/keybinds"
  local tab = self:Config_get(path)
  tab = type(tab) == "table" and tab or {}
  for key,name in next, tab do
    tab[key] = KeyEvent(name)
  end
  return tab
end
function E:components_str()
  return List("processors","segmentors","translators","filters")
  :map(function(elm) return "engine/" .. elm end)
  :reduce(function(path,list)
    return list + self:Config_get(path, 4)
  end,List())
  :map(function(elm) return elm.path .. ": " .. elm.value end)
end

function E:print_components(out)
  Log(out,  string.format("----- %s : %s ----", self.engine.schema.schema_id,self.name_space) )
  self:components_str():each(function(elm)
    Log(out,elm)
  end)
end
---  delete
function E:components(path)
  return self:Config_get(path or "engine")
end
E.__index=E


-- wrap env
-- Env(env):get_status()
-- Env(env):config() -- return config with new methods
-- Env(env):context() -- return context with new methods
function Env(env)
  return setmetatable(env,E)
end
--append_path(...)  paths   + "/?.lua" paths + /?/init.lua
M.append_path = append_path
--append_cpath(...) paths + /?.(dll|so|dylib)
M.append_cpath = append_cpath

--append rime_api tools
local function warp_api(mod,target)
  if not mod then return end
  for k,v in next , mod do
    target[k] = target[k] or v
  end
end
warp_api(M,rime_api)
warp_api(w_leveldb, rime_api)

