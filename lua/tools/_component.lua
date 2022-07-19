#! /usr/bin/env lua
--
-- _component.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
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


local function conv_prescription(str)
  str = type(str) == "string" and str or ""
  local k,m,n= str:split("@"):unpack()
  n = n or m
  return  k,m,n
end
-- fack Ticket for component
--function fake_Ticket(engine, name_space, prescription)

local function fake_Ticket(...)
  local args = {...}
  if #args == 2 then
    return {
      schema=args[1],
      name_space=args[2],
    }
  elseif #args == 3 then
    return falk_Ticket(args[1],args[1].schema,args[2],args[3])
  elseif #args == 4 then
      local ks,m,ns= args[4]:split("@"):unpack()
    return {
      engine = args[1],
      schema = args[2],
      klass = ks,
      name_space = ns or args[3],
    }
  end
end

Ticket = Ticket or fake_Ticket

local function req_module(mod_name,rescue_func)
  local ok,res =  pcall(require, mod_name )
  if ok then return res end
  Log(ERROR, "require module failed ", mod_name )
  return  rescue_func
end


local function fake_lua_component( obj, ticket)
  -- load modules from  name_space/modules  or _G[name_space]
  local module_name , name_space = ticket.name_space:split("@"):unpack()
  name_space= name_space or module_name
  local rescue = _G["Rescue_" .. ticket.klass:match("^lua_(.+)$")]

  -- init module
  if not _G[module_name] then
    Log(WRAN, "lua module not found " , module_name )
    _G[module_name] = req_module(module_name) --or rescue
    if not _G[module_name] then
      _G[module_name] = rescue
    end
  end
  local module = _G[module_name]
  module = type(module) == "function" and {func = module } or module
  -- create lua_component data
  obj.id = ticket.klass .. "@" .. ticket.name_space
  obj.module_name= module_name
  obj.name_space = name_space
  obj.rescue_func = rescue_func
  obj.chk_res = res_pass
  obj.module = module
  obj.env={
    engine=ticket.engine,
    name_space = name_space,
  }
  return obj
end

local function New(self,...)
  local obj=setmetatable({}, self)
  obj=obj:_initialize(...)

  return obj
end
local function comm_init(self)
  local ok,res =pcall( self.module and self.module.init and  self.module.init,self.env)
  if not ok then
    Log(ERROR,
    ("component: %s, module: %s, init.func( %s)"):format(self.id,self.module,
    self.module and self.module.init), res)
  end
end
local function _initialize(self,ticket)
  fake_lua_component(self,ticket)
  Log(INFO,"created processor component ",self.id,self)
  comm_init(self)
  --self.module.init(self.env)
  -- create delegate func   obj:init() obj:func(key) obj:finit() ...
  --for k,v in next, self.module do
    --self[k] = function(obj,...)
      --return obj.module[k](..., obj.env)
    --end
  --end
  return self
end

local function _distory(self)
  self.module.fini(self.env)
end
local B={}
B._initialize= _initialize
B.__gc = _distory
B.__call=New
B.__index=B

-- Lua_component functions


local function comm_fini(self)
  return self.module.fini and self.module.fini(self.env)
end


local function pfunc(self,key) return self.module.func(key, self.env) end
local function sfunc(self,segs) return self.module.func(segs, self.env) end
local function tfunc(self,input,seg) return self.module.func(input,seg, self.env) end
local function ffunc(self,tran,cands) return self.module.func(tran, self.env,cands) end
local function ftags_match(self,seg)
  return sself.module.tags_match and elf.module.tags_match(seg) or true
end

-- generate Lua_Component class and funcs of instance
local function lua_comp(funcs)
  local obj = {}
  obj. __gc = comm_fini
  obj.__index = obj
  for k,v in next,funcs do
    obj[k] = v
  end
  return setmetatable(obj,B)
end

local LuaP=lua_comp({
  --func=pfunc,
  process_key_event=pfunc,
})

local LuaS=lua_comp({
  proceed = sfunc,
})

local LuaT=lua_comp({
  query = tfunc,
})

local LuaF=lua_comp({
  apply = ffunc,
  applies_to_segment = ftags_match,
})

local comp={
  lua_processor = LuaP,
  lua_segmetor = LuaS,
  lua_translator = LuaT,
  lua_filter = LuaF,
}
-- fack Component for librime-lua versino  < #177
local M={}

function M.Processor(...)
   local ticket = Ticket(...)
   if ticket and ticket.klass == "lua_processor" then
     return  comp[ticket.klass](ticket)
   end
end
function M.Segmentor(...)
   local ticket = Ticket(...)
   if ticket and ticket.klass == "lua_segmentor" then
     return  comp[ticket.klass](ticket)
   end
end
function M.Translator(...)
   local ticket = Ticket(...)
   if ticket and ticket.klass == "lua_translator" then
     return  comp[ticket.klass](ticket)
   end
end
function M.Filter(...)
   local ticket = Ticket(...)
   if ticket and ticket.klass == "lua_filter" then
     return  comp[ticket.klass](ticket)
   end
end


function M.Require(ticket)
  local c = comp[ticket.klass]
  return c and c(ticket) or nil
end

return M

