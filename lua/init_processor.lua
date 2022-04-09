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
_NR = package.config:sub(1,1):match("/") and "\n" or "\r"
_NR = "\r"
do
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

    ---
    --path_append("lua/component")
    --cpath_append("lua/plugin")
  end
  -- append cpath <user_data_dir>/lua/plugin/?.(so|dll|dylib)
  init_path()
end

-- librime-lua-script env
require 'tools/string'
require 'tools/rime_api'
local puts=require'tools/debugtool'
local List = require 'tools/list'


-- init_module
-- -- remove load_config
local function load_config(mod_configs)

  if not mod_configs or mod_configs.type ~= "kList" then return end
  local modules=List()

  local function map_to_table(cmap_item)
    if not cmap_item or  cmap_item.type ~= "kMap" then return end
    local cmap = cmap_item:get_map()
    local tab={}
    for i,key in next, cmap:keys() do
      tab[key] = cmap:get_value(key).value
    end
    return tab
  end
  for i=0 , mod_configs.size - 1 do
    modules:push( map_to_table(mod_configs:get_at(i) ) or {} )
  end
  return modules
end

local function init_modules(engine, modules)
  local Components = require 'tools/_component'
  return modules
  :map(function(elm)
    local ns = elm.name_space and "@" .. elm.name_space or ""
    local mn = elm.module_name and "@" .. elm.module_name or ""
    local p = "lua_processor" ..  mn ..  ns
    local obj= Components.Processor(engine, p, elm.module )
    return obj
  end)
end

--auto_load
local function auto_load(env, tab_G)
  tab_G= type(tab_G)=="table" and tab_G or _G
  local function req_mod(comp_str,tab_G)
    puts(WARN,"auto_load", "lua_" .. comp_str)
    local comp_type, module_name, name_space = comp_str:split("@"):unpack()
    name_space = name_space or module_name
    local ok,res = pcall(require, module_name)
    if ok then
      tab_G[module_name]= res
      return
    end
    ok,res = pcall(require, "component/" .. module_name)
    if ok then
      tab_G[module_name] = res
      return
    else
      puts(ERROR, "require module failed ",comp_str, res)
      local context= env:Context()
      tab_G[module_name] = _G["Rescue_" .. comp_type]
    end
  end
  local function find_lua_comp(elm) return  elm:match("^.+:lua_(.+)$") end
  local function chk_mod(elm,tab) return tab[ elm:split("@")[2] ]  end

  env:config_path_to_str_list("engine")
  :select(find_lua_comp)
  :map(find_lua_comp)
  :select_delete(chk_mod,tab_G)
  :each(req_mod,tab_G)
end

-- append components to config_map of engine
local function check_duplicate_value(dist_list,config_value)
  for i=0 ,dist_list.size -1 do
    if dist_list:get_value_at(i).value == config_value.value then
      return true
    end
  end
  return false
end

local function append_config_list(dist_list, from_list)
  if not dist_list or not from_list
    or dist_list.type ~="kList" or from_list.type ~= "kList" then
    return
  end
  for i=0 , from_list.size -1 do
    local c_value  = from_list:get_value_at(i)
    if not check_duplicate_value(dist_list, c_value ) then
      dist_list:append( c_value.element )
      puts(INFO, "append component", dist_list.size, c_value.value )
    else
      puts(WARNING, "cancel append duplicate component", c_value.value )
    end
  end
end
local function append_component(config, dist_path, from_path)
  dist = dist_path and config:get_map(dist_path)
  from = from_path and config:get_map(from_path)
  if not dist or not from or dist.type ~="kMap" or from.type ~= "kMap" then return end
  for i,key in next , from:keys() do
    local dist_list=dist:get(key):get_list()
    local from_list= from:get(key):get_list()
    if dist_list and from_list then
      append_config_list(dist_list, from_list)
    end
  end
end

-- init_processor

local M={}
function M.init(env)
  Env(env)
  -- init self --
  local config=env:Config()
  append_component(config, "engine", env.name_space .. "/before_modules")
  env.modules = init_modules(env.engine,
  List( config:get_obj( env.name_space .. "/modules") or _G[env.name_space] ))
  append_component(config, "engine",env.name_space .. "/after_modules")

  --auto_load_bak(config:get_map("engine"))
  auto_load(env)

  local prtscr=config:get_string(env.name_space .. "/prtscr_key") or "Control+F10"
  env.prtscr_key = KeyEvent(prtscr)
  -- init end
  -- print component

  -- print component
  do
    local list=List()
    local function fn(elm) list:push(elm) end
    list:push( "---- submodules ----" )
    env.modules:each(function(elm) list:push(elm.id) end)
    list:push("---- engine components ----" )
    env:components_str():each(fn)
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

  -- self func
  -- /ver /modules /comps /cal /cowsay
  local active_input= context.input:match("^/(.+)$")
  if key:repr() == "space" and  F[active_input] then
    F[active_input](env)
    context:clear()
    return Accepted
  end
  if status.has_menu and key:eq(env.prtscr_key) then
    F["screen_print"](env)
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
