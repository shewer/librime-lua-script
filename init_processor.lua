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



require 'tools/rime_api'

local List = require 'tools/list'
local puts=require'tools/debugtool'

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

local function init_module(env)
  local config = env:Config()
  -- load modules from  name_space/modules  or _G[name_space]
  local modules=  load_config(env)
      or  List( _G[env.name_space] )
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
  Env(env)
  -- init self --
  local config=env:Config()

  -- include module
  env.modules = init_module( env )

  -- call sub_processor
  env.modules:each( function(elm)
    elm.module.init( elm.env )
  end)

  -- init end
  -- print component
  puts(INFO,"---submodules---" )
  env.modules:each( function(elm)
  puts(INFO, elm.module, elm.module_name .."@" .. elm.name_space)
  end )
  env:print_components()
  do
    local pattern_p= "recognizer/patterns"
    puts( INFO, "---------" ..  pattern_p .. "-----------" )
    List( config:get_map(pattern_p):keys())
    :each(function(elm)
      puts(INFO, pattern_p .. "/" .. elm .. ":\t" ..  config:get_string( pattern_p .. "/" .. elm  ) )
    end )
  end
end


function M.fini(env)
  -- modules fini
  env.modules:reverse()
  :each( function(elm) elm.module.fini(elm.env) end )  -- call fini

  -- self finit --
end

function M.func(key,env)
  local Rejected,Accepted,Noop=0,1,2
  local context=env:Context()
  -- self func
  -- sub_module func
  if context.input =="/ver" and key:repr() == "space" then
    env.engine:commit_text( rime_api.Version() )
    context:clear()
    return Accepted
  end
  local res = env.modules:each(function(elm)
    local res= elm.module.func(key,elm.env)
    if res ~= Noop then return res  end
  end)
  --
  return res  or Noop
end


return M
