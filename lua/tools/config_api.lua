#! /usr/bin/env lua
--
-- config_api.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
--[[
config_api.lua 
提供 lua_base type  and table  ConfigItem ConfigData( Value,Map,List)
互換功能 和  map {path= string , value= string}  of array 
以便於操作 config  configdata  lua_obj 之間的轉換

-- return lua type 0 , ConfigItem 1, Configdata 2 , nul 3
M.conver_type = conver_type -- return obj args: obj ,type
M.to_obj = function(obj) return conver_type(obj,0) end
M.to_item = function(obj) return conver_type(obj,1) end
M.to_cdata = function(obj) return conver_type(obj,2) end
M.to_list_with_path= function(obj,path) -- obj , path

--]]
-- return lua type 0 , ConfigItem 1, Configdata 2 , nul 3
local function ctype(cobj)
  if cobj == nil then return 3
  elseif type(cobj) ~= "userdata" then return 0
  elseif cobj.element then return 2
  elseif cobj.get_list and cobj.type then return 1
  end
end

local _base_type={number= true, boolean = true, string = true }
local function base_type(obj)
  return _base_type[type(obj)]
end

-- data to data  
local ctype_funcn= {kList="get_list", kMap="get_map",kScalar="get_value"}
local function _item_to_cdata(citem)
  local func= ctype_funcn[citem.type]
  if func then return citem[func](citem) end
end

 


local function item_to_obj(config_item,level)
    level = level or 99
    if level <1 then return config_item end
    if config_item.type == "kScalar" then
      return config_item:get_value().value
    elseif config_item.type == "kList" then
      local cl= config_item:get_list()
      local tab={}
      for k=1,cl.size do
        tab[k]= item_to_obj( cl:get_at(k-1), level -1)
        --table.insert(tab, item_to_obj( cl:get_at(i), level -1 ))
      end
      return tab
    elseif config_item.type == "kMap" then
      local cm = config_item:get_map()
      local tab={}
      for i,k in next,cm:keys() do
        tab[k] = item_to_obj( cm:get(k), level -1)
      end
      return tab
    else return nil end
end


local function obj_to_item(lua_obj)
  local ct = ctype(lua_obj)
  if  base_type(lua_obj) then 
    return ConfigValue( tostring(lua_obj) ).element
  elseif type(lua_obj) == "table" then 
    if #lua_obj > 0 then
      local cobj=ConfigList()
      for i,v in ipairs(lua_obj) do
        local o = obj_to_item(v)
        if o then cobj:append(o) end
      end
      return cobj.element
    else
      local cobj = ConfigMap()
      for k,v in pairs(lua_obj) do
        if type(k) == "string" then 
          local o = obj_to_item(v)
          if o then cobj:Set(k, M.to_item(v)) end
        end
      end
      return cobj.element
    end
  -- ConfigList ConfigValue ConfigMap
  elseif ct == 2 then 
    return lua_obj.element
  -- ConfigItem 
  elseif ct == 1 then
    return lua_obj
  end
end

--  check base_type
--  conver ConfigItem of obj  to list { {path= string, value= string} ...}
--  ex:
--   { 1,{a=2,b=4},2,3,4} , "test" --> { {path= "test/@0" , value = "1" } ,{path="test/@2/a", value="2" ... }
local function _obj_to_list_with_path(obj,path,tab,loopchk)
  loopchk = loopchk or {}
  tab = tab or {}
  path  = path or ""
  if loopchk[obj] or base_type(obj) then 
    table.insert(tab , {path = path, value=obj})
    return tab
  end
  loopchk[obj] = true
  if type(obj) == "table" then 
    local is_list = #obj > 0
    local lpath = #path > 0 and path .. "/" or path
    lpath = is_list and lpath .. "@" or lpath

    for k,v in  (is_list and ipairs or pairs)(obj) do 
      _obj_to_list_with_path(v, lpath .. k , tab,loopchk)
    end
    return tab
  end
end
local puts = require 'tools/debugtool'
local function conver_type(cobj,_type,...) -- cobj ,type:0  1 2 
  _type = _type and _type or 0
  local t = ctype(cobj)
  if t == 3 then return nil end
  if _type == t then return cobj end
  -- conver to lua_data
  if _type == 0 then 
    return item_to_obj( t == 1 and cobj or conver_type(cobj, 1) )
  -- conver to item
  elseif _type == 1 then
    return t == 2 and cobj.element or obj_to_item( cobj)
  -- conver to configdata
  elseif _type == 2 then
    return _item_to_cdata( t == 1 and cobj or conver_type(cobj,1))
  -- onw way conver to {path=string, value=string} of list
  elseif _type == 4 then 
    local path = ...
    return _obj_to_list_with_path( 
    (t == 0 and cobj or conver_type(cobj,0)), path)
  end
end



local M={}
M.ctype= ctype
M.conver_type = conver_type
M.to_obj = function(obj) return conver_type(obj,0) end
M.to_item = function(obj) return conver_type(obj,1) end
M.to_cdata = function(obj) return conver_type(obj,2) end
M.to_list_with_path = function(obj,path) return conver_type(obj,4,path) end
M.to_list_with_path= function(obj)
  return _obj_to_list_with_path( conver_type(obj,0),path)
end

return M
