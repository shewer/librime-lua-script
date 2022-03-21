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

local function init_cpath()
  local path= ("./lua/plugin/"):gsub("/",package.config:sub(1,1) )
  local pattern = path:gsub("([.?/%\\])","%%%1")
  --  pattern --> "%.%/lua%/plugin%/"  or "%.%\\lua%\\plugin%\\"
  if not package.cpath:match( pattern ) then
    local cp=package.cpath
    local df= cp:match('?.so') or cp:match('?.dylib') or cp:match('?.dll')
    package.cpath= package.cpath .. (df and ";" .. path .. df or "")
  end
end
-- append cpath <user_data_dir>/lua/plugin/?.(so|dll|dylib)
init_cpath()

-- librime-lua-script env
require 'tools/string'
require 'tools/rime_api'
local puts=require'tools/debugtool'
package.path= package.path .. ";./lua/component/?.lua"



local List = require 'tools/list'
local module_key=List("module","module_name","name_space")

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
local function req_module( module, rescue_func)
  local ok, res = pcall( require, module)
  if ok then return res end

  local slash = package.config:sub(1,1)
  ok, res = pcall( require, "component/" .. module )
  if ok then return res end

  puts(ERROR, __LINE__(), "require module failed ", mod_name, res )
  return coscue_func
end

local function init_module(_env)
  local config = _env:Config()
  -- load modules from  name_space/modules  or _G[name_space]
  local modules_cfg = load_config(_env) or List( _G[_env.name_space] )
  local function fn(elm)
    return {
      module = _G[elm.module_name] or req_module(elm.module) or {func=Rescue_processor},
      module_name = elm.module_name,
      name_space = elm.name_space,
      env = {
        name_space = elm.name_space,
        engine = _env.engine,
      },
    }
  end
  return modules_cfg:map(fn)
end

local function auto_load(env)
  local config=env.engine.schema.config
  local lua_components = List("processors","segments","translators","filters")
  :map(function(elm) return config:get_list("engine/" .. elm) end)
  :reduce(function(elm,org)
    for i=0,elm.size-1 do
        org:push( elm:get_value_at(i).value:match("^lua_%a+@.*$") )
    end
    return org
  end, List() )
  :each(function(elm)
     local comp_name=elm:split("@")[2]
     if not _G[ comp_name] then
        local ok,res= pcall(require, comp_name)
        if ok then
          _G[comp_name] = res
        else
          puts(WARN,__FILE__(),__LINE__(), "failed require component of ", elm, comp_name )
        end
     end
  end )

end

local M={}
function M.init(env)
  Env(env)
  auto_load(env)
  -- init self --
  local config=env:Config()

  -- include module
  env.modules = init_module( env )

  -- call sub_processor
  env.modules:each( function(elm,fn)
    if elm.module[fn] and not xpcall( elm.module[fn],debug.traceback,( elm.env )) then
      puts(ERROR,__LINE__(), elm.env.name_space,res)
    end
  end,"init")

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
