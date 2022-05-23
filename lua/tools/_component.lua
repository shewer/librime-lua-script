#! /usr/bin/env lua
--
-- _component.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
-- require sub_module tools
-- M.Processor(engine, lua_processor@<module_name>@<name_space>,module_str, rescue_func)
require 'tools/string'
local puts=require 'tools/debugtool'
-- fack Ticket for component
function fake_Ticket(engine, name_space, prescription)
  local ks, ns = prescription:match("^([^@]+)@(.+)$")
  return {
    engine = engine,
    schema = engine.schema,
    klass = ks or prescription,
    name_space = ns or name_space,
  }
end
Ticket = Ticket or fake_Ticket

local function req_module(mod_name,rescue_func)
  local ok,res =  pcall(require, mod_name )
  if ok then return res end
  --[[
  puts(WARN,"require module failed ", mod_name  )
  puts(WARN,"retry require module from ", "component/" .. mod_name)
  ok , res = pcall(require, 'component/'  .. mod_name )
  if ok then return res end
  --]]
  puts(ERROR, "require module failed ", mod_name )
  return  rescue_func
end


local function fake_lua_component( obj, ticket)
  -- load modules from  name_space/modules  or _G[name_space]
  obj= obj or {}

  local module_name , name_space = ticket.name_space:split("@"):unpack()
  name_space= name_space or module_name
  local rescue = _G["Rescue_" .. ticket.klass:match("^lua_(.+)$")]

  -- init module
  if not _G[module_name] then 
    puts(WRAN, "lua module not found " , module_name )
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
  return obj:_initialize(...)
end
local function _distory(self)
  self.module.fini(self.env)
end
local function _initialize(self,ticket)
  fake_lua_component(self,ticket)
  puts(INFO,"created processor component ",self.id)
  self:init()
  puts(DEBUG,"created processor component ",self.id,self)
  --self.module.init(self.env)
  -- create delegate func   obj:init() obj:func(key) obj:finit() ...
  --for k,v in next, self.module do 
    --self[k] = function(obj,...)
      --return obj.module[k](..., obj.env)
    --end 
  --end 
  return self
end 

local B={}
B._initialize= _initialize
B.__call=New
B.__index=B

-- Lua_component functions

local function comm_init(self) 
  return self.module.init and 
  self.module.init(self.env) 
end
local function comm_fini(self) 
  return self.module.fini and self.module.fini(self.env) 
end
local function pfunc(self,key) return self.module.func(key, self.env) end
local function sfunc(self,segs) return self.module.func(segs, self.env) end
local function tfunc(self,input,seg) return self.module.func(input,seg, self.env) end
local function ffunc(self,tran) return self.module.func(tran, self.env) end
local function ftags_match(self,seg) 
  return sself.module.tags_match and elf.module.tags_match(seg) or true
end

local function lua_comp(funcs)
  local obj = {
   __gc = _distory,
   init = comm_init,
   fini = comm_fini,
  }
  for k,v in next,funcs do 
    obj[k] = v
  end
  obj.__index = obj
  return setmetatable(obj,B)
end

local LuaP=lua_comp({
  func= pfunc,
  ProcessKeyEvent=pfunc,
})

local LuaS=lua_comp({
  func = sfunc,
  Proceed = sfunc,
})

local LuaT=lua_comp({
  func = tfunc,
  Query = tfunc,
})

local LuaF=lua_comp({
  func = ffunc,
  Apply = ffunc,
  tags_match = ftags_match,
  AppliesToSegment = ftags_match,
})

--[[
local Lua_filter=setmetatable({},B)
Lua_filter.__index = Lua_filter
Lua_filter.__gc = _distory
function Lua_filter:Apply(tran)
  return self.module.func(key, self.env)
end
function Lua_filter:AppliesToSegment(seg)
  return sself.module.tags_match and elf.module.tags_match(seg) or true
end

--]]

local M={}

function M.Processor(ticket)
   if ticket.klass == "lua_processor" then 
     return  LuaP( ticket) 
   end 
end
function M.Segmentor(ticket)
   if ticket.klass == "lua_segmentor" then 
     return  LuaS( ticket) 
   end 
end
function M.Translator(ticket)
   if ticket.klass == "lua_translator" then 
     return  LuaT( ticket) 
   end 
end
function M.Filter(ticket)
   if ticket.klass == "lua_filter" then 
     return  LuaF( ticket) 
   end 
end

local comp={
  lua_processor = LuaP,
  lua_segmetor = LuaS,
  lua_translator = LuaT,
  lua_filter = LuaF,
}
function M.Require(ticket) 
  puts(DEBUG, "------debug Require ----------",ticket.klass, comp[ticket.klass],LuaP)-- , comp[ticket.klass](ticket))
  local c = comp[ticket.klass] 
  return c and c(ticket) or nil
end
return M

