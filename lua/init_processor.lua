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
require 'tools/rime_api'
--require 'tools/string'
--local Log=require'tools/debugtool'
--local List = require 'tools/list'

_NR = package.config:sub(1,1):match("/") and "\n" or "\r"



-- init_module only for Processor

local function init_modules(env)
  local modules = List( env:Config_get(env.name_space .. "/modules"))
  :map(function(elm)
    -- 整理  modules
    elm.prescription = elm.prescription
    or ("%s@%s@%s"):format("lua_processor", elm.module_name, elm.name_space or elm.module_name )
    return elm
  end)
  --modules:each(function(elm)
  modules:select(function(elm)
    return elm.prescription:match("^lua_(.+)@(.+)")
  end)
  :each(function(elm)
    local tp,nm,ns = elm.prescription:split("@"):unpack()
    ns = ns or nm
    _G[nm] = _G[nm] or rime_api.req_module(elm.module)
  end)

  return modules:map(function(elm)
    --local ticket=Ticket(engine,"processor", pres)
    local schema = elm.schema and Schema(elm.schema) or env.engine.schema
    local comp=Component.Processor(env.engine,schema,"", elm.prescription)
    if not comp then
      Log(DEBUG,"create Component fauled", comp, elm.prescription )
    end
    return {name=elm.prescription,comp=comp}
  end)
end

local function auto_load(env, tab_G)
  tab_G = tab_G or _G
  local comps=List(env:Config_get_with_path("engine"))
  :select(function(elm) return elm.value:match("^lua_(.+)@(.+)$") end)
  :map(function(elm) return elm.value end)
  :each(function(elm)
    local ks,nm,ns= elm:split("@"):unpack()
    ns = ns or nm
    _G[nm] = _G[nm] or rime_api.req_module(nm)
  end)
end


local function append_component(env, from_path,dist_path)
  local from = from_path and env:Config_get(from_path)
  if not from then return end
  dist_path = dist_path or "engine"

  for key, f_list in pairs(from) do
      local obj = env:Config_get(dist_path .."/"..key)
      List(f_list):reverse()
      if type(obj) == "table" and #obj >0 then
        local list = List(obj)
        local index = key == "filters" and list:find("uniquifier")
        local path = dist_path .. "/" .. key
        -- dpath  = append component before uniquifier or append after next
        local dpath = index and path .. "/@before " .. index -1 or path .. "/@after " .. #list -1

        List(f_list)
        :select(function(elm) return not List(env:Config_get(path)):find(elm) end)
        :reverse()
        :each(function(elm) env:Config_set(dpath, elm) end)
      end
  end
end

-- init_processor

local M={}
function M.init(env)
  Env(env)
  -- init self --
  --local config=env:Config()
  append_component(env, env.name_space .. "/before_modules")
  env.modules = init_modules(env)
  append_component(env, env.name_space .. "/after_modules")

  --auto_load_bak(config:get_map("engine"))
  auto_load(env)

  -- prtscr prtkey keyevent
  env.keys= env:get_keybinds(env.name_space .. "/keybinds")
  -- init end

  -- print component
  do
    ( List()
    + "---- submodules ----"
    + env.modules:map(function(elm) return string.format("%s: %s",elm.name, elm.comp) end)
    + "---- engine components ----"
    + env:components_str()
    + "---- recognize/patterns  ----"
    + List(env:Config_get_with_path("recognizer/patterns")):map(function(elm)
      return elm.path .. ": " .. elm.value end)
    ):each(function(elm,out)  Log(out,elm) end, CONSOLE)
  end
end


function M.fini(env)
  -- modules fini
  env.modules:each(function(elm) elm=nil end)
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
  --[[
  engine:commit_text( context:get_selected_candidate().preedit .. "\t" .. seg.prompt .. _NR )
  for i=st , st+page_size -1  do
    local cand = seg:get_candidate_at(i)
    if not cand then return end
    local head = i == s_index and "->" or "  "
    local out = ("%s%s\t%s%s"):format(i == s_index and "->" or "  ", cand.text, cand.comment,_NR)
    engine:commit_text(out)
  end
  engine:commit_text(_NR)
  --]]
  do
    (List()
    + engine:commit_text( context:get_selected_candidate().preedit .. "\t" .. seg.prompt .. _NR )
    + List.Range(st,st+page_size -1 ):map(function(elm)
      local c= seg:get_candidate_at(elm)
      if c then
        local head = elm == s_index and "-->" or "   "
        return ("%s%s:\t%s%s"):format(head, c.text, c.comment, _NR)
      end
    end)
    ):each(function(elm) engine:commit_text(elm) end)
  end
end

function F.modules(env)
  env.modules:each( function(elm)
    local str = string.format("%s: %s%s", elm.name,elm.comp, _NR)
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
  local context=env.engine.context
  local status=env:get_status()
  -- prtkey enable/disable
  local debug_mode = context:get_option('_debug')
  if debug_mode and key:eq(env.keys.prtkey) then
    env:Toggle_option("prtkey")
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
  local res = env.modules:each(function(elm,res)
    local res =elm.comp:process_key_event(key)
    if res < 2 then return res end
  end) or Noop

  return  res or Noop
end

local Er ={}
function Er.init(env)
  Log(ERROR,"librime-lua version less #127",rime_api.Ver_info() )
end
function Er.func(key,env)
  local Rejected,Accepted,Noop= 0,1,2
  local context= env.engine.context
  if context.input:match("^/ver") and key:repr() == "space" then
    env.engine:commit_text(  rime_api.Ver_info() )
    return Accepted
  end
  return Noop
end

return (rime_api.Version()>= 127  or ConfigMap) and M or Er
