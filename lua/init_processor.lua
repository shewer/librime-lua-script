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
-- librime-lua-script env
require 'tools/string'
require 'tools/rime_api'
local puts=require'tools/debugtool'
local List = require 'tools/list'

_NR = package.config:sub(1,1):match("/") and "\n" or "\r"
do
  local function init_path()
    local slash = package.config:sub(1,1)
    local df = package.cpath:match('?.so')
    or package.cpath:match('?.dylib')
    or package.cpath:match('?.dll')
    local sf = "?.lua"

    local function append_path(paths,path)
      return paths:split(";"):find(path) and paths or paths .. ";" .. path
    end
    package.path = append_path(package.path,"./lua/component/?.lua")
    package.cpath = append_path(package.cpath, "./lua/plugin/".. df )
  end
  init_path()
end



-- init_module

local function init_modules(engine, modules)
  local Components = require 'tools/_component'
  return modules
  :map(function(elm)
    _G[elm.module_name] = _G[elm.module_name] or rime_api.req_module(elm.module)
    local pres= elm.prescription or ("%s@%s@%s"):format("lua_processor", elm.module_name, elm.name_space)
    local ticket=Ticket(engine,"processor", pres)
    return  Components.Processor(ticket) 
  end)
end

--auto_load
--[[
local function auto_load(env, tab_G)
  puts(DEBUG,"[31;45m;--------------------------------->>>>> [0m")
  env:config_path_to_str_list("engine"):each(
  function (str, tab)
    local comp_str = str:match("^.+:lua_(.+)$")
    if comp_str then
      local comp_type,module_name,name_space= comp_str:split("@"):unpack()
      name_space = name_space or module_name
      if not tab[module_name] then
        puts(WARN,"auto_load", "lua_" .. comp_str)
        tab[module_name] = rime_api.req_module(module_name, tab["Rescue_" .. comp_type])
      end
    end
  end, type(tab_G)=="table" and tab_G or _G)
end
--]]
local function auto_load(env, tab_G)
  tab_G = tab_G or _G
  local comps=List(env:Config_get("engine",4))
  :select(function(elm) return elm.value:match("^lua_(.+)@(.+)$") end)
  :map(function(elm)
    local tab = elm.value:match("^lua_(.+)"):split("@")
    return  { type=tab[1], module_name= tab[2], name_space = tab[3] or tab[2], }
  end)
  :select(function(elm) return not tab_G[ elm.module_name ] end )
  :each(function(elm)
    tab_G[elm.module_name]= rime_api.req_module(elm.module_name,tab_G["Rescue_" .. elm.type])
  end,tab_G)
end


-- append components to config_map of engine
--local function append_value_before(self,path,value,mvalue)
local function _append_value_before(elm, env, path, mvalue)
  local obj = env:Config_get(path)
  if type(obj) ~= "table" or #obj < 1 then return end
  local list = List( env:Config_get(path))
  if list:find( elm) then return end
  local index = list:find(mvalue)
  local dpath = index and path .. "/@before " .. index -1 or path .. "/@next"

  if not env:Config_set(dpath, elm) then
    puts(ERROR, "config set ver error","path", path, "value", elm)
  end
end

local function append_component(env, from_path,dist_path)
  local from = from_path and env:Config_get(from_path)
  if not from then return end
  dist_path = dist_path or "engine"

  for key, f_list in pairs(from) do
      local obj = env:Config_get(dist_path .."/"..key)
      if type(obj) == "table" and #obj >0 then
        local list = List(obj)
        local index = key == "filters" and list:find("uniquifier") 
        local path = dist_path .. "/" .. key
        -- dpath  = append component before uniquifier or append after next
        local dpath = index and path .. "/@before " .. index -1 or path .. "/@after " .. #list -1
        List(f_list):select(function(elm) return not List(env:Config_get(path)):find(elm) end)
        :reverse()
        :each(function(elm) env:Config_set(dpath, elm) end)
      end
    --List(f_list)
    --:each(_append_value_before, env, dist_path .. "/".. key, key == "filters" and "uniquifier")
  end
end
--]]
-- init_processor

local M={}
function M.init(env)
  Env(env)
  -- init self --
  local config=env:Config()
  append_component(env, env.name_space .. "/before_modules")
  local mods= List(env:Config_get(env.name_space .. "/modules") or _G[env.name_space])
  env.modules = init_modules(env.engine, mods)
  --env.modules = List()--init_modules(env.engine, mods)
  puts(DEBUG,"[31;45m;--------------------------------->>>>> [0m",Ticket)
  append_component(env, env.name_space .. "/after_modules")


  --auto_load_bak(config:get_map("engine"))
  auto_load(env)

  -- prtscr prtkey keyevent
  env.keys= env:get_keybinds(env.name_space .. "/keybinds")
  -- init end
  -- print component

  -- print component
  do
    local list=List()
    local function fn(elm) list:push(elm) end
    list:push( "---- submodules ----" )
    env.modules:each(function(elm) list:push(elm.id) end)
    list:push("---- engine components ----" )
    env:print_components(INFO)--:each(fn)
    local pattern_p= "recognizer/patterns"
    list:push( "---- " ..  pattern_p .. " ----" )
    env:config_path_to_str_list(pattern_p):each(fn)

    list:each(function(elm)  puts(INFO,elm) end)
  end
end


function M.fini(env)
  -- modules fini
  env.modules:each( function(elm)
    elm:fini()
  end)
  -- self finit --
end


local F={}
function F.screen_print(env)
  local engine = env.engine
  local page_size = engine.schema.page_size
  local context = engine.context
  local seg = context.composition:back()
  local s_index = seg.selected_index
  local st = s_index - s_index % page_size

  engine:commit_text( context:get_selected_candidate().preedit .. "\t" .. seg.prompt .. _NR )
  for i=st , st+page_size do
    local cand = seg:get_candidate_at(i)
    if not cand then return end
    local head = i == s_index and "->" or "  "
    local out = head .. cand.text .. "\t" .. cand.comment .. _NR
    engine:commit_text(out)
  end
  engine:commit_text(_NR)
end
function F.modules(env)
  env.modules:each( function(elm)
    local str = string.format("%s: %s%s", elm.id, elm.env.engine, _NR)
    env.engine:commit_text(str )
  end)
end
function F.comps(env)
  env:components_str():each(function(elm)
    env.engine:commit_text( elm .. _NR)
  end)
end

function F.cal(env)
  local engine=env.engine
  engine:commit_text("```" .. _NR)
  local cal = require('tools/cowsay')
  cal():split("\n")
  :each(function(line)
    engine:commit_text(line .. _NR)
  end)
  engine:commit_text("```" .. _NR)
end
function F.cowsay(env)
  local engine=env.engine
  engine:commit_text("```" .. _NR)
  for line in io.popen("al |cowsay -n"):lines() do
    engine:commit_text(line .. _NR)
  end
  engine:commit_text("```" .. _NR)
end
function F.ver(env)
  env.engine:commit_text( rime_api.Ver_info() )
end

function M.func(key,env)
  local Rejected,Accepted,Noop=0,1,2
  local context=env:Context()
  local status=env:get_status()
  -- prtkey enable/disable
  local debug_mode = context:get_option('_debug')
  if debug_mode and key:eq(env.keys.prtkey) then
    context:Toggle_option("prtkey")
    return Accepted
  elseif debug_mode and context:get_option("prtkey") then
    env.engine:commit_text(key:repr().. " ")
    return Accepted
  -- commit_text key:repr()
  elseif status.has_menu and key:eq(env.keys.prtscr) then
    F["screen_print"](env)
    return Accepted
  end
  -- self func
  -- /ver /modules /comps /cal /cowsay
  local active_input= context.input:match("^/(.+)$")
  if key:repr() == "space" and  F[active_input] then
    F[active_input](env)
    context:clear()
    return Accepted
  end
  -- sub_module func
  local res = env.modules:each(function(elm,...)
    local res =elm:func(...)
    if res < 2 then return res end
  end,key)
  --
  return res  or Noop
end


return M
