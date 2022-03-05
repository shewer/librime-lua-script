#! /usr/bin/env lua
--
-- command_str.lua
-- Copyright (C) 2021 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
--
require 'tools/string'
local puts = require 'tools/debugtool'
local function New(self, ... ) 
  local obj = {}
  setmetatable(obj,self)
  return obj._initialize and obj:_initialize(...) or obj
end 

local Base={}
Base.__index =Base
Base.__call=New 

local V={}
setmetatable(V,Base) 
V.__index=V
V.__call=New

local VB={}
setmetatable(VB,V)
VB.__index=VB
V.__index=New


function Base:_initialize( obj, get_func, set_func)
  self._order=key
  self._obj=obj
  self._vars=name_of_obj or {}
  self._enable=true
  self._get=get_func
  self._set=set_func
  self._pattern= pattern or ":"
  self._split= self._pattern[1]
  self._path=  self._pattern[2]
  return self 
end
function Base:set(path,value)
  self._set( self._obj,path,value)
end 
function Base:get(path)
  return self.get( self._obj,path)
end 

function Base:execute(obj,func_name,name, ... )
  return  obj[func_name] and obj[func_name](obj,name, ...)
end 
function Base:status(obj,name)
  return obj[self._status]and obj[self._status](obj,name)
end 
function Base:sets()
  local tab=List()
  for k,v in next, self do 
    tab:push(k)
  end 
  return tab:sort()
end 

function Base:select_sets(str)
  self:sets():select( function(elm)  return elm:match("^" .. str ) end )
end 


local V={}
V.__index=V
V.__call=New
setmetatable(V,Base)
function V:get(obj,name)
  return self:execute(obj,"get_" ..self._cmd , name) 
end 
function V:set(obj,name,...)
  return self:execute(obj,"set_" .. self._cmd , name, ...)
end 

local VB={}
VB.__index=VB
VB.__call=New
setmetatable(VB,V)
function VB:get(obj,name)
  return not not self:execute(obj,"get_" .. name) 
end 
function VB:set(obj,name,bool)
  bool = type(bool) == "string" and bool=="true" and true or bool 
  bool = type(bool) == "boollean" and bool 
  return self:execute(obj,"set_" ..  name, bool)
end 

local F={}
F.__index=F
F.__call=New
setmetatable(F,Base)
function F:_initialize(...)
  Base._initialize(self, ...)
  self._enable=false
  return self
end 
function F:execute(obj,name,...)
  return self._set[name] and self._set[name](obj,...)  
end 
function F:status(obj,name)
  return nil
end 

local V = {}


local VB_={}
VB.__index =function(obj,key)  end 
VB.__newindex=function(obj,key,value) end 


local B={}
B={}
B.__index=function(obj,key)
  if obj._vers[key] then 
    return obj._get_cmd(obj._obj,key)() 
  elseif key=="set" then 
    return function(obj,name) obj._vers[key]= true end 
  else 
    return nil
  end 
end 
B.__newindex=function(obj,key,value)
  obj._vars[key] = true 
  if obj.vars[key] then 
    return obj._set_cmd(obj._obj,key,value) 
  end 
end 
local Base1={}
function Base1.__index(obj,key)
  return obj:get(key) 
end
function Base1.__newindex(obj,key,value)
  puts("******>", __FILE__(),__LINE__(),obj,key,value)
  obj:set(key,value)
end 
function Base1:exec(str)
      local key,name,value = table.unpack(str:split(":"))
      self:set(name,value)
end 
Base1.__call=New

local function option_iter(self,str)
  local key,name,value = table.unpack(str:split(":") )
  return coroutine.wrap(function() 
    --if not name:match("^[%a_]+") then return end 
    local status= self.vars[name]
    -- status=  vars_value ~= nil and tostring( status) or "" 
    if not value then 
      for k,v in next , self.vars do 
        coroutine.yield( 
        ("%s:%s:%s--(%s)"):format(key,k,not v,"toggle") )
      end 
    else
      value = value or ""
      for i,elm in next,{not status ,true,false} do
        coroutine.yield( 
        ("%s:%s:%s--(%s)"):format( key,name,elm, i==1 and "toggle" or elm and "set" or "unset" ) )
      end
    end 
  end) 
end 
local function Option(ref,vars)
  local obj={}
  obj.obj=ref
  obj.vars=vars or {}
  obj.iter =option_iter  
  function obj:get(name)
    return self.obj:get_option(name) 
  end 
  function obj:set(name,value) 
    self.obj:set_option( name, value == "true") 
  end 
  obj.execute= obj.set
  setmetatable(obj, Base1) 
  return obj
end

local function property_iter(self,str)
  return coroutine.wrap( function() 
    local key,name,value = table.unpack(str:split(":") )
    local stalus= self.vars[name] 

    if not value  then 
      for k,v in next , self.vars do 
        coroutine.yield( ("%s:%s--(%s)"):format(key,k,v) )
      end 
    else   
        coroutine.yield( ("%s--(%s)" ):format(str,self.vars[name] ))
    end
  end)
end 
local function Property(ref,vars)
  local obj={}
  obj.obj= ref 
  obj.vars= vars or {}
  obj.iter= property_iter
  function obj:get(name)
    return self.obj:get_option(name) 
  end 
  function obj:set(name,value) 
    if  value and #value >0 and value ~= self.vars[name] then 
      self.obj:set_property( name, value) 
    end 
  end 
  obj.execute= obj.set
  setmetatable(obj,Base1)
  return obj
end 
local function get_configs(self,path)
  local item= self:get(path)  --- self.obj.get_item(path)
  local list_c=List() 
  if item then 
    if item.type== "kScalar" then 
      list_c:push( { path , item:get_value().value} ) 
    elseif item.type== "kList" then 
        local list= item:get_list() 
        for i=0,list.size-1 do 
          local iitem= list:get_at(i)
          list_c:push{ #path>0 and path .."/@" .. i, iitem.type== "kScalar" and iitem:get_value().value or iitem.type  }
        end 
    elseif item.type == "kMap" then 
      local map = item:get_map() 
      for i,key in next,map:keys() do 
        local mitem =  map:get(key)
        list_c:push{  (#path>0 and path .."/" or "") ..  key , mitem.type == "kScalar" and mitem:get_value().value or mitem.type }
      end 
    end 
  -------------------------------------
  else 
    local t_path,sub_str = path:match("^(.*)%/(.*)$")
    if not t_path then 
      sub_str,path = path,""
    else 
      path=t_path
    end 
    list_c = get_configs(self,path)
  end 
  return list_c 
end 
  
local function config_iter(self,str)
  local key,path,value= table.unpack( str:split(":") )
  return coroutine.wrap(function() 
    local list= get_configs(self,path) 
    value = value and ":" .. value or ""
    list:each(function(elm) 
      coroutine.yield( ("%s:%s%s--(%s)"):format(key,elm[1],value,elm[2] ) )
    end)
  end )
end 

local function _Config(ref,vars)
  local obj={}
  obj.vars= vars or {}
  obj.obj= ref 
  obj.iter= config_iter
  function obj:get(name)
    return self.obj:get_item(name) 
  end 
  function obj:set(name,value) 
    if not value then return end 
    name = name:gsub("/+$","")
    local item = self:get(name) 
    --  change value 
    if  item then 
      if  item.type == "kScalar" then 
        self.obj:set_string( name, value ) 
      end 
    else 
      path,sub_name=  name:match("^(.*)/(.*)$")
      if not path then 
        path , sub_name = "", name
      end 
      local item= self:set(path) 
      if item and item.type == "kMap" then 
        self.obj:set_string(name,value)
      end 
    end 
  end 
  obj.execute= obj.set
  setmetatable(obj,Base1)
  return obj
end

-- Func
local function func_iter(self,str)
  return coroutine.wrap( function() 
    local key,name,value = table.unpack(str:split(":") )
    local stalus= self.vars[name] 
    --puts("trace1", __FILE__(),__FUNC__(),__LINE__(), str , key,name,value, status)
    --if not value  then 
    value = value and ":" .. value or ""
    for k,v in pairs(self.vars)  do 
      coroutine.yield( ("%s:%s%s--(%s)"):format(key,k,value,v) )
    end 
    -- else   
    --   coroutine.yield( ("%s--(%s)" ):format(str,self.vars[name] ))
  end)
end 
local function Func(ref,vars)
  local obj={}
  obj.vars= vars or {}
  obj.obj= ref 
  obj.iter= func_iter
  function obj:get(name)
    return self.vars[ name ]
  end 
  function obj:execute(name,value)  -- 
       
    value = value~= nil and value  or ""
    if self.vars[name] then 
      local func = self.vars[name]
      func( self.obj, load( 'return ' .. tostring(value) )() )
      --, load( 'return ' .. value)() )
    end 
  end 
  --obj.execute = obj.set
  setmetatable(obj,Base1)
  return obj
end 

-- Command
local Command={}
Command.__index=Command
Command.__call = New 
setmetatable(Command,{__call=New})
function Command:execute(str)
  local key,name,value= table.unpack(str:split(":"))
  self[key]:execute(name,value)
end 

function Command:iter(str)
  local key,name,value= table.unpack(str:split(":"))
  return  self[key]:iter(str) 
end 

function Command:append(key, m_name, obj, set)
  if m_name == "option" then 
    self[key] = Option(obj,set) 
  elseif m_name == "property" then 
    self[key] = Property(obj,set) 
  elseif m_name == "func" then 
    self[key] = Func(obj,set) -- functions 
  elseif m_name == "config" then 
    self[key] = _Config(obj)
  elseif m_name == "global" then 
    self[key] = Global(obj) 
  else 
      return false
  end 
  return true
end 

return Command 
