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
local M = {}

local function req_module(mod_name,rescue_func)
  local slash= package.config:sub(1,1)
  local ok,res = pcall(require, mod_name )
  if ok then return res end

  ok , res = pcall(require, 'component' .. slash .. mod_name )
  if ok then return res end
  puts(ERROR, "require module failed ", mod_name , res )
  return  rescue_func
end

local function res_pass(res) return true end
local function init_module(engine, prescription,module_str,rescue_func)
  -- load modules from  name_space/modules  or _G[name_space]
  local comp, module_name, name_space= table.unpack(prescription:split("@"))
  rescue_func = rescue_func or _G["Rescue_" .. comp:match("^lua_(.+)$")]
  name_space = name_space or module_name
  module_str = module_str or module_name

  -- init module
  local module = _G[module_name] or req_module(module_str) or  {func=rescue_func}
  module = type(module) == "function" and {func = module } or module
  -- create lua_component data
  return  {
    id = prescription,
    module_name= module_name,
    name_space = name_space,
    rescue_func = rescue_func,
    chk_res = res_pass,
    module = module,
    env={
      engine=engine,
      name_space = name_space,
    },
  }
end

local function New(self,...)
  local obj= init_module(...)
  setmetatable(obj,self)
  obj:init()
  return obj
end
local B={__call=New}
-- Lua_component functions
local L={}
setmetatable(L,B)
function L:init()
  if self.module.init then
    local ok ,res = pcall(self.module.init,self.env)
    if ok then 
      return 
    end
    puts(ERROR, "excute fint error",self.id,res)
  end
end
function L:fini()
  if self.module.fini then
    local ok ,res = pcall(self.module.fini,self.env)
    if ok then 
      return 
    end
    puts(ERROR, "excute fini error",self.id,res)
  end
  self.module = nil
  self.env=nil
  self.module_name=nil

end
function L:func(...)
  local ok,res = pcall(self.module.func,self:args(...) )
  if ok and self.chk_res(res) then return res end
  puts(ERROR, "excute func error",self.id,res)

  if self.rescue_func then
    ok,res = pcall(self.rescue_func, self:args(...) )
    if ok and self.chk_res(res) then return res end
    puts(ERROR, "excute rescue_func error",self.id,res)
  end
end
L.__index = L
L.__call = New
L.__gc = L.fini
-- lua_processor fusctions
local function process_key_event(self,key)
  return self:func(key,self.env)
end
local function proc_chk_res(res)
  return res == 0 or res == 1 or res == 2
end
local function proc_args(self,...)
  local key= ...
  return key, self.env
end
function M.Processor(engine,prescription,module_str)
  local obj=L(engine,prescription,module_str)
  obj.args = proc_args
  obj.chk_res= proc_chk_res
  obj.rescue_func = obj.rescue_func or Rescue_processor
  -- delegate func 
  obj.process_key_event=obj.func
  puts(INFO,"create processor component ",prescription)
  return obj
end






function M.Create(engine,prescription,module_str)
  local comp, module_name, name_space= table.unpack(prescription:split("@"))
  local cname = comp:match("^lua_(.+)$"):gsub("^(%a)",string.upper)
  return  M[cname] and M[cname](engine,prescription,module_str)
end
return M

