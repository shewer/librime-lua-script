-- init_processor
-- 利用engine 載入processor程序特性，在init中修改config以達到動態調整方案的組件
-- 爲了再利用已完成之組件，且方便組合組件，所以再設計上一層
-- 此模組可利用lua global 變數 _G[<mane_space>]   或是 <name_space>/modules 轉入sub_module (name_space 優先於 global )
-- init_processor 會利用 module tab 將 <module> 掛入 _G[<module_name>]
-- 井產生 假的 lua_processor@<module_name>@<name_space> 存在於 init_processor的 init fini func 內呼叫 sub_module的 init fini func
--
--
-- 組件都是利用 lua_processor的 init & fini 加入自身所需之部件組成功能模塊 ，所以可以獨立 加載入 engine/processors
--
--
--
-- ex1: custom.yaml   name_space:module1
-- rime.lua
-- init_processor= require'init_processor' -- module_name
-- modules1={
--   { module= 'command'    , module_name= "command_proc",     name_space= "command"},
--   { module= 'english'    , module_name= "english_proc",     name_space= "english"},
--   { module= 'conjunctive', module_name= "conjunctive_proc", name_space= "conjunctive"},
-- }
--
-- module2={
--   { module= 'english'    , module_name= "english_proc"    , name_space= "english"},
--   { module= 'conjunctive', module_name= "conjunctive_proc", name_space= "conjunctive"},
-- }
--
--
-- <方案1>.custom.yaml # 由moduel1 name_space 載入 module1
-- patch:
--   engine/processors/lua_processor@init_processor@module1
--   module1/modules:
--     - { module: 'command'    , module_name: "command_proc"    , name_space: "command"}
--     - { module: 'conjunctive', module_name: "conjunctive_proc", name_space: "conjunctive"}
--
--<方案2>.custom.yaml  # 由 _G[module1] 載入 module1
--patch:
--   engine/processor/lua_processor@init_processor@module1
--
--<方案3>.custom.yaml  # 由 _G[module2] 載入 module2
--patch:
--   engine/processor/lua_processor@init_processor@module2
--
--

local function init_path()
  local slash = package.config:sub(1,1)
  local df = package.cpath:match('?.so')
  or package.cpath:match('?.dylib')
  or package.cpath:match('?.dll')
  local sf = "?.lua"

  --local upath= rime_api.user_data_dir()
  local function ap(path,file,up)
    up = up or "."
    local path = string.format(";%s/%s/%s",up, path, file)
    :gsub("/",slash)
    return  path
  end
  -- append  ./lua/component/?lua to package.path
  local function path_append(path)
    path= ap(path,sf,upath)
    if package.path:match(path) then
      package.path = package.path .. path
    end
  end
  -- append  ./lua/plugin/?.(so, dll, dylib) to package.cpath
  local function cpath_append(path)
    path= ap(path,df,upath)
    if package.cpath:match(path) then
      package.cpath = package.cpath .. path
    end
  end

  --path_append("lua/component")
  --cpath_append("lua/plugin")
end
-- append cpath <user_data_dir>/lua/plugin/?.(so|dll|dylib)
init_path()

-- librime-lua-script env
require 'tools/string'
require 'tools/rime_api'
local puts=require'tools/debugtool'



local List = require 'tools/list'
local module_key=List("module","module_name","name_space")

local function req_module(mod_name,rescue_func)
  local slash= package.config:sub(1,1)
  local ok,res = pcall(require, mod_name )
  if ok then return res end

  ok , res = pcall(require, 'component' .. slash .. mod_name )
  if ok then return res end
  puts(ERROR,__LINE__(), "require module failed ", mod_name , res )
  return  rescue_func
end

local function load_config(env)
  local path= env.name_space .. "/modules"
  local config= env:Config()
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
  local config = env:Config()
  -- load modules from  name_space/modules  or _G[name_space]
  local modules=  load_config(env) or  List( _G[env.name_space] )
  local function fn(elm)
    return  {
      module_name= elm.module_name,
      name_space = elm.name_space,
      module = _G[elm.module_name] or req_module(elm.module) or { func = Rescue_processor },
      env={
        engine=env.engine,
        name_space = elm.name_space,
      },
    }
  end
  return modules:map(fn)
end
--auto_load
require '_rescue'
local function auto_load(eng_config, tab_G)

  local function req_component(item, tab_G)
    if item.type ~= "kScalar" then return end
    tab_G = type(tab_G) == "table" and tab_G or _G
    local tab = item:get_value().value:split("@")
    if tab[1]:match("^lua_(.+)$") and not tab_G [ tab[2]] then
      tab[1] = tab[1]:match("^lua_(.+)$")
      tab[3] = tab[3] or tab[2]
      puts(DEBUG,__LINE__(), "=== engine compos list:", tab[1],tab[2],tab[3],
      tab_G == _G, tab_G[ tab[2]], _G["Rescue_" .. tab[3]])
      tab_G[ tab[2] ] =  req_module(tab[2], _G["Rescue_" .. tab[1]] )
    end
  end

  local function item_to_list(cl)
    local clist= cl:get_list()
    local l = List()
    if clist then
      for i=0,clist.size-1 do
        l:push( clist:get_at(i) )
      end
    end
    return l
  end
  List( eng_config:keys() )
  :map(function(elm) return eng_config:get(elm) end)
  :select(function(elm) return elm.type == "kList" end)
  :map(item_to_list)
  :each(function(items)
    items:each( req_component, tab_G)
  end)
end
-----]]
local function check_duplicate_value(dest_list,config_value)
  for i=0 ,dest_list.size -1 do
    if  dest_list:get_value_at(i).value == config_value.value then
      puts(WARNING,__LINE__(), "cancel append duplicate component", config_value.value )
      return true
    end
  end
  return false
end
local function config_list_append(dest_list,config_value)
  -- check match component
  if check_duplicate_value(dest_list,config_value) then
      puts(WARNING,__LINE__(), "cancel append duplicate component", config_value.value )
  else
    -- append component
    dest_list:append( config_value.element )
    puts(INFO,__LINE__(), "append component",config_value.value )
  end
end

local function append_component(env,path)
  local config=env:Config()
  local context=env:Context()
  for _,v in next ,{"segments", "translators", "filters"} do
    local dest_list= config:get_list("engine/" .. v)
    local from_list= config:get_list(path .. "/" .. v)
    if from_list then
      for i=0,from_list.size-1 do
        config_list_append(dest_list, from_list:get_value_at(i) )
      end
    end
  end
end
local function append_component(env,path)
  local config=env:Config()
  local dest_config= config:get_map("engine")
  local from_config= config:get_map(path)
  List( from_config:keys() ):each(function(key)
    local dest_list=dest_config:get(key):get_list()
    local from_list=from_config:has_key(key) and from_config:get(key):get_list() or ConfigList()
    for i=0,from_list.size -1 do
      config_list_append(dest_list, from_list:get_value_at(i) )
    end
  end)
end

local M={}
function M.init(env)
  Env(env)
  -- init self --
  local config=env:Config()

  append_component(env, env.name_space .. "/before_modules")
  env.modules = init_module( env )

  --  init sub_processors
  env.modules:each( function(elm,fn)
    if elm.module[fn] and not xpcall( elm.module[fn],debug.traceback, elm.env ) then
      puts(ERROR,__LINE__(), elm.env.name_space,res)
    end
  end,"init")

  append_component(env, env.name_space .. "/after_modules")
  auto_load(config:get_map("engine"))
  -- init end
  -- print component

-- print component
  local function log_out(out)
    out = out or INFO
    do
      puts(out,"---submodules---" )
      env.modules:each( function(elm)
        puts(out, elm.module, elm.module_name .."@" .. elm.name_space)
      end )
      env:print_components(out)
      local pattern_p= "recognizer/patterns"
      puts(out, "---------" ..  pattern_p .. "-----------" )
      List( config:get_map(pattern_p):keys())
      :each(function(elm)
        puts(out, pattern_p .. "/" .. elm .. ":\t" ..  config:get_string( pattern_p .. "/" .. elm  ) )
      end )
    end
  end
  log_out(CONSOLE)
  log_out(INFO)
end


function M.fini(env)
  -- modules fini
  env.modules:each( function(elm,fn)
    if elm.module[fn] and not xpcall( elm.module[fn],debug.traceback,( elm.env )) then
      puts(ERROR,__LINE__(), elm.env.name_space,res)
    end
  end,"fini")
  -- self finit --
end

function M.func(key,env)
  local Rejected,Accepted,Noop=0,1,2
  local context=env:Context()
  -- self func
  -- sub_module func
  if context.input =="/ver" and key:repr() == "space" then
    env.engine:commit_text( "Version: " .. _VERSION .. " librime-lua Version: " .. rime_api.Version() )
    context:clear()
    return Accepted
  end
  if context.input == "/modules" and key:repr() == "space" then
    env.modules:each( function(elm)
      local str = string.format("%s:%s:%s\n",elm.module_name, elm.env.name_space, elm.env.engine)
      env.engine:commit_text(str )
    end)
    context:clear()
    return Accepted
  end
  local res = env.modules:each(function(elm,fn)
    --local ret= elm.module.func(key,elm.env)
    --if ret ~= 2  then return  ret end
    if elm.module[fn] then
      local ok,res=xpcall( elm.module[fn],debug.traceback,key, elm.env )
      if not ok then
        puts(ERROR,__LINE__(), elm.env.name_space,res )
      else
        if res ~= Noop then return res  end
      end
    end
  end,"func")
  --
  return res  or Noop
end


return M
