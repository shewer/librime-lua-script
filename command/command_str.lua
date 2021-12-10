#! /usr/bin/env lua
--
-- command_str.lua
-- Copyright (C) 2021 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
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
  print("******>", __FILE__(),__LINE__(),obj,key,value)
  obj:set(key,value)
end 
function Base1:exec(str)
      local key,name,value = table.unpack(str:split(":"))
      self:set(name,value)
end 
Base1.__call=New

local function option_iter(self,str)
  print("******>", __FILE__(),__LINE__(),self,str,type(str))
  local key,name,value = table.unpack(str:split(":") )
  print("******>", __FILE__(),__LINE__(),self,str,type(str),key,name,value)
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
  print("******>", __FILE__(),__LINE__(),value,type(value) ,status,type(status) ) 
  --if (value and not status ) then 
  --if (value and true ) then 
  print("******>", __FILE__(),__LINE__(),self,str,type(str),key,name,value)
    --coroutine.yield( 
    --("%s:%s:%s--(%s)"):format(key, name, not status, "toggle"  ) )
    value = value or ""
    for i,elm in next,{not status ,true,false} do
  print("******>", __FILE__(),__LINE__(),self,str,type(str),key,name,value)
       print(("%s:%s:%s--(%s)"):format( key,name,elm, i==1 and "toggle" or elm and "set" or "unset" ) )
        coroutine.yield( 
        ("%s:%s:%s--(%s)"):format( key,name,elm, i==1 and "toggle" or elm and "set" or "unset" ) )
    end
  end 
end) 
end 
local function property_iter(self,str)
  return coroutine.wrap( function() 
    local key,name,value = table.unpack(str:split(":") )
    local stalus= self.vars[name] 

    if not value  then 
      for k,v in next , self.vars do 
        coroutine.yield( 
        ("%s:%s--(%s)"):format(key,k,v) )
      end 
    else   
        coroutine.yield( 
        ("%s--(%s)" ):format(str,self.vars[name] ))
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
    print("=======>",__FILE__(),__LINE__() , self, self.obj,self.set,name,value,type(value),obj.vars[name] )
    self.obj:set_option( name, value == "true") 
    print("=======>",__FILE__(),__LINE__() , self, self.obj,self.set,name,value,type(value) )

  end 
  obj.execute= obj.set
  setmetatable(obj, Base1) 
  return obj
end

local function Property(ref,vars)
  local obj={}
  obj.vars= vars or {}
  obj.obj= ref 
  obj.iter= property_iter
  function obj:get(name)
    return self.obj:get_option(name) 
  end 
  function obj:set(name,value) 
    print("=======>",__FILE__(),__LINE__() , self, self.obj,self.set,name,value )
    if  value and #value >0 and value ~= self.vars[name] then 
    print("=======>",__FILE__(),__LINE__() , self, self.obj,self.set,name,value )
      self.obj:set_property( name, value) 
    end 
  end 
  obj.execute= obj.set
  setmetatable(obj,Base1)
  return obj
end 
local function get_configs(self,path)
  print("------get_configs-->",__FILE__(),__LINE__(),self,path )

  local item= self:get_item(path or "" ) 
  print("------get_configs-->",__FILE__(),__LINE__(),self,path,item)
  local list_c=List() 
  if item then 
    print("------get_configs-->",__FILE__(),__LINE__(),self,path,item,item.type)
    if item.type== "kScalar" then 
      list_c:push( { path , item:get_value().value} ) 
      print("------get_configs-->",__FILE__(),__LINE__(),self,path,item:get_value().value ,item,item.value,item.type,#list_c, list_c[1][1],list_c[1][2])
      
    elseif item.type== "kList" then 
        local list= item:get_list() 
        for i=0,list.size-1 do 
          local iitem= list:get_at(i)
          list_c:push{ path .."/@" .. i, iitem.type== "kScalar" and iitem:get_value().value or iitem.type  }
        end 
    elseif item.type == "kMap" then 
      local map = item:get_map() 
      for i,key in next,map:keys() do 
        local mitem =  map:get(key)
        list_c:push{  (#path>0 and path .."/" or "") ..  key , mitem.type == "kScalar" and mitem:get_value().value or mitem.type }
      end 
    end 
  else 
    local h,l = path:match("^([%a%.%/_%d]+)%/?(%/.*)$")
      print("------get_configs-->",__FILE__(),__LINE__(),self,path,h,l )
      local list_l = get_configs(self,h or "")
      list_c = list_l and list_l:select(function(elm) return elm[1]:match("^".. path ) end ) 
  end 
  
  return #list_c > 0 and list_c or nil 
end 
  
local function config_iter(self,str)
  local key,path,value= table.unpack( str:split(":") )
  local h,l = path:match("^([%a%.%/_%d]+)%/?(%/.*)$")
  local l = not h and path 
  local item= self:get_item(path) 
  
  return coroutine.wrap(function() 
   
   local item = not config:is_null() and config:get_item(path) or nil 
   local item_str = item and item.type == "kSclcar" and item:to_value().value or ""
  if value or not item then 
    coroutine.yield( ("m%s--(%s)"):format(str,item_str))
    ------------------------------
  elseif item.type == m then 
  print("---->",__FILE_a_(),__LINE__(), self,self.obj, key,path, value )
    self:get_config(path):each(function(elm)
      print("---->",__FILE__(),__LINE__(), self,self.obj, key,path, value or "" , #config,elm[1],elm[2] )
      coroutine.yield( ("%s%s--(%s)"):format(str,elm[1],elm[2]))
    end)

  end 
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

    print("=======>",__FILE__(),__LINE__() , self, self.obj,self.set )
    name = name:gsub("/+$","")
    --local config= self.obj
    if value and self.obj:get_item( name ).type == "kScalar" then 
      self.obj:set_string( name, value ) 
    end 
  end 
  setmetatable(obj,Base1)
  return obj
end
local function Func(obj,vars)
  local obj={}
  obj.vars= vars or {}
  obj.obj= ref 
  obj.iter= config_iter
  function obj:get(name)
    return self.obj:get_item(name) 
  end 
  function obj:set(name,value) 

    print("=======>",__FILE__(),__LINE__() , self, self.obj,self.set )
    name = name:gsub("/+$","")
    --local config= self.obj
    if value and self.obj:get_item( name ).type == "kScalar" then 
      self.obj:set_string( name, value ) 
    end 
  end 
  setmetatable(obj,Base1)
  return obj
end 


local Command={}
Command.__index=Command
Command.__call = New 
setmetatable(Command,{__call=New})
function Command:execute(str)
  local key,name,value= table.unpack(str:split(":"))
  self[key]:execute(name,value)
end 

function Command:iter(str)
  local cmd_key,name,value= table.unpack(str:split(":"))

  print("---->",__FILE__(),__LINE__(),self,self[cmd_key], cmd_key, name,value )
  return  self[cmd_key]:iter(str) 
end 

function Command:append(key,obj, m_name, set)
  
  print("---->",__FILE__(),__LINE__(), key,obj,m_name,set,name_of_set )
  if m_name == "option" then 
    self[key] = Option(obj,set) 
  elseif m_name == "property" then 
    self[key] = Property(obj,set) 
  elseif m_name == "func" then 
    self[key] = Func(obj,set) -- functions 
  elseif m_name == "config" then 
    self[key] = _Config(obj)
  elseif m_name == "global" then 
  else 
      return false
  end 
  return true
end 


return Command 
