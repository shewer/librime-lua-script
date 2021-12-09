-- processor_init 
-- lua_processor@processor_init@module1 
-- module1 = {
  -- { modulename , namespoce }  -- require 'modulename' ,'namespace' -->lua_processor@modulename@namespace
  -- { modulename , namespace }
-- 利用engine 載入processor程序特性，在init中修改config以達到動態調整方案
-- 此模組可爭取 yaml 或者 rime.lua global name_space 載入 次模組
-- ex:   lua_processor@init_processor@module -- 
-- rime.lua 
-- init_processor = require 'init_processor'
--[[ 
module 可以從 yaml module/modules 或 rime.lua _G["module"] 
from lua 
module = {
{ module_name= "conjunctive_proc", module= "conjunctive"}, name_space= "conjunctive"},
  --   ...
  -- }
 -- from yaml
   module/modules:
     - {module: "conjunctive_proc", name_space: "conjunctive"}
     - ...

--]]

require 'tools/rime_api'
local List = require 'tools/list'

local module_key=List("module","module_name","name_space")

local function load_config(env)
  local path= env.name_space .. "/modules"
  local config= env:Config()
  print("--now-------",__FILE__(), __LINE__(),env ,env.name_space, _G[env.name_space], path ,config,config.is_list )
  print("------",__FILE__(),__LINE__(), env.engine.schema.config:is_list("engine/filters"))
  print("-------",__FILE__(),__LINE__())-- ,   config:is_list(path),path )
  ---  env:Config() error 
  if not config:is_list(path) then return end 
  local modules=List()
  for i=0 , config:get_list_size(path) -1 do 
    modules:push(  
    module_key:reduce(function(elm,org) 
      org[elm] = config:get_string( ("%s/@%s/%s"):format(path,i,elm) ) 
      return org 
    end ,{} )
    )
  end 
  return #modules > 0 and modules or nil
end 

local function init_module(env)
  print("---------",__FILE__(), __LINE__(),env ,env.name_space, _G[env.name_space])
  local config = env:Config() 
  -- load modules from  name_space/modules  or _G[name_space] 
  print("---------",__FILE__(), __LINE__(),env ,env.name_space, _G[env.name_space])
  local modules=  load_config(env) 

      or  List( _G[env.name_space] )
  print("-load_config-->" , __LINE__() , modules, #modules)
  return modules:map(function(elm)
    local proc_m={}
    proc_m.module = _G[elm.module_name] 
    or require(elm.module) 
    or require("component/" .. elm.module  )
    proc_m.module_name= elm.module_name
    proc_m.name_space = elm.name_space
    proc_m.env={}
    proc_m.env.name_space= elm.name_space
    proc_m.env.engine = env.engine
    return proc_m
  end)
end




local M={}
function M.init(env)
  local config=env.engine.schema.config
  local nitem= config:get_item("aba")
  local item= config:get_item("engine")
  Env(env)
 print("------------>" ,__FILE__(),__LINE__() , env, item, item.type ,nitem,env:Config() ) 

  -- init self --
  local config=env:Config() 
  

  -- include module 
  env.modules = List() 
  print("---------",__FILE__(), __LINE__(),env )
  env.modules = init_module( env )  
  print("---------",__FILE__(), __LINE__(),env,env.modules,#env.modules )
  env.modules:each( function(elm) 
  print("---------",__FILE__(), __LINE__(),env,elm,elm.env,elm.env.name_space, elm.module)
    for k,v in next, elm do 
      print("------>",__FILE__(),__LINE__(),k,v)
    end 

    for k,v in next, elm.module do 
      print("------>",__FILE__(),__LINE__(),k,v)
    end 
    elm.module.init( elm.env ) 
  print("---------",__FILE__(), __LINE__(),env )
  end)
  print("---------",__FILE__(), __LINE__(),env )


  List("processors", "segments", "translators", "filters" )
  :map(function(elm) return "engine/" .. elm end )
  :each(function(elm) 
    print("---------",__FILE__(), __LINE__(), elm )
    if config:get_list_size(elm) > 0 then 
      for i=0,config:get_list_size(elm) -1 do 
        print("--->",__FILE__(),__LINE__(), config:get_string(elm .."/@" .. i ) )
      end 
    end 
  end)
  print("--->>>>>><<<<<<------",__FILE__(), __LINE__() )



end 


function M.fini(env)
  -- modules fini
  env.modules:reduce( function(elm,org) return org:unshift(elm) end ,List() ) -- reverse
  :each( function(elm) elm.module.fini(elm.env) end )  -- call fini

  -- self finit --
  local function _d()
    a=1
    while true do 
      local n,v = debug.getlocal(2,a)
      if not n then break end
      print("---local -->",__FILE__(),__LINE__(), n,v)
      a=a+1
    end
  end 
  _d() 
end 

function M.func(key,env)
  local Rejected,Accepted,Noop=0,1,2
-- self func

-- module func
  env.modules:each(function(elm)
    local res= elm.module.func(key,elm.env)
    if res ~= Noop then return res  end 
  end)
  return Noop
end 


return M
