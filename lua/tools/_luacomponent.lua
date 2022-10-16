#! /usr/bin/env lua
--
-- _luacomponent.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--


--
-- 這是模擬 ComponentReg api
-- librime-lua ver  < 177
--
-- require sub_module tools
-- M.Processor(engine, lua_processor@<module_name>@<name_space>,module_str, rescue_func)

-- check librime-lua version 177  return Component
--if Component and LevelDb then
  --warn("Component is already ")
  --return Component
--end

--require 'tools/string'
--local Log=require 'tools/debugtool'

--[[
local function conv_prescription(str)
  str = type(str) == "string" and str or ""
  local k,m,n= str:split("@"):unpack()
  n = n or m
  return  k,m,n
end
--]]
-- fack Ticket for component
--function fake_Ticket(engine, name_space, prescription)
require 'tools/_global'
local class= require 'tools/class'
require 'tools/_ticket'


local function New(self,...)
  local obj=setmetatable({}, self)
  obj=obj:_initialize(...)
  return obj
end
local B={}
--B._initialize= _initialize
--B.__gc = _distory
B.__call=New
B.__index=B



local function comm_fini(self)
  local fini = self._module.fini
  if type(fini) == "function" then
    local ok,res = pcall( fini, self._env)
    if not ok then
      return self.module.fini and self.module.fini(self.env)
    end
  end
end

local function get_module(mod_name)
  local mod = _ENV[mod_name]
  local tp = type(mod)
  if tp == "function" then
    return {func=mod}
  elseif tp == "table" then
    return mod
  else
    Log(ERROR, "require module failed ", mod_name )
    return {}
  end
end


local function _initialize(self,ticket)
  -- init data struct
  local tk = Ticket(ticket.engine, ticket.name_space, ticket.name_space)
  self._module_name = tk.klass
  self._addr = tostring(self):split(":")[2]
  Log(INFO,"created processor component ",ticket.klass , ticket.name_space,self)
  self._module = get_module(self._module_name)
  self._env= {
    engine = ticket.engine,
    name_space= tk.name_space,
  }
  -- call module.init(env)
  if self._module.init then
    local ok,res =pcall( self._module.init, self._env)
    if not ok then
      Log(ERROR,
      ("[%s:%s]%s@%s@%s, initialize faild  init func( %s)-"):format(__FILE__(4),__LINE__(4),self.__name, self._module_name, self._env.name_space,
      self._module and self._module.init), res)
    end
  end
  return self
end

-- Lua_component functions
local function pfunc(self,key) return self._module.func(key, self._env) end
local function sfunc(self,segs) return self._module.func(segs, self._env) end
local function tfunc(self,input,seg)  return Translation(function() self._module.func(input,seg, self._env) end) end
local function ffunc(self,tran,cands) return Translation( function() self._module.func(tran, self._env,cands) end ) end
local function ftags_match(self,seg)  local func = self._module.tages_match
  return func and func(seg,self._env) or true
end

-- generate Lua_Component class and funcs of instance
local function lua_comp(funcs)
  local obj = setmetatable({},B)
  obj.__index = obj
  obj. __gc = comm_fini
  obj._initialize = _initialize
  for k,v in next,funcs do
    obj[k] = v
  end
  return obj
end

local LuaP=lua_comp({
  process_key_event=pfunc,
  __name = "lua_processor",
})

local LuaS=lua_comp({
  proceed = sfunc,
  __name = "lua_segmentor",
})

local LuaT=lua_comp({
  query = tfunc,
  __name = "lua_translator",
})

--local LuaF=lua_comp({
  --apply = ffunc,
  --applies_to_segment = ftags_match,
  --__name = "lua_filter",
--})
local function to_s(self)
  return string.format("%s : %s  module_name: %s, name_space : %s",
  self.__name , self._addr, self._module_name,self._env and self._env.name_space
  )
end
local LuaF= class({
  _initialize = _initialize,
  __gc = comm_fini,
  __name = 'lua_filter',
  apply = ffunc,
  to_s = to_s,
  applies_to_segment = ftags_match,
})

-----
--[[
"grammar",
"xlit",
"xform",
"erase",
"derive",
"fuzz",
"abbrev",
"config_builder",
"config",
"schema",
"user_config",
"tabledb",
"stabledb",
"plain_userdb",
"userdb",
"legacy_userdb",
"corrector",
"dictionary",
"user_dictionary",
"userdb_recovery_task",
"shape_formatter",
"detect_modifications",
"installation_update",
"workspace_update",
"schema_update",
"config_file_update",
"prebuild_all_schemas",
"user_dict_upgrade",
"cleanup_trash",
"user_dict_sync",
"backup_config_files",
"clean_old_log_files",
"test_hello",
"test_morning",
"userdb",
]]


-- fack Component for librime-lua versino  < #177
local M={}
function M.Processor(...)
   local ticket = Ticket(...)
   if ticket and ticket.klass == "lua_processor" then
     return  LuaP(ticket)
   end
end
function M.Segmentor(...)
   local ticket = Ticket(...)
   if ticket and ticket.klass == "lua_segmentor" then
     return  LuaS(ticket)
   end
end
function M.Translator(...)
   local ticket = Ticket(...)
   if ticket and ticket.klass == "lua_translator" then
     return  LuaT(ticket)
   end
end
function M.Filter(...)
   local ticket = Ticket(...)
   if ticket and ticket.klass == "lua_filter" then
     return  LuaF(ticket)
   end
end

return M
