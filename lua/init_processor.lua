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
-- librime-lua-script env
require 'tools/_component'
local Env = require 'tools/env_api'
local List = require 'tools/list'

_NR = package.config:sub(1,1):match("/") and "\n" or "\r"
-- init_module only for Processor

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
  --]]
  local fs = env:Get_option('full_shape')
  if fs then env:Unset_option('full_shape') end

  local str_head = context:get_selected_candidate().preedit .. "\t" .. seg.prompt .. _NR
  local strlist= List.Range(st,st+page_size-1):map(function(elm) 
    local c=seg:get_candidate_at(elm)
    local head = elm == s_index and '-->' or '   ' 
    return ("%s%s:\t%s%s"):format(head, c.text, c.comment,_NR)
  end):concat()
  env.engine:commit_text(str_head .. strlist)

  if fs then env:Set_option('full_shape') end
end

function F.modules(env)
  local fs = env:Get_option('full_shape')
  if fs then env:Unset_option('full_shape') end

  local str = env.modules:map( 
  function(elm) return ("%s: %s%s"):format( elm.name,elm.comp,_NR) end):concat()
  env.engine:commit_text(str)

  if fs then env:Set_option('full_shape') end
end

function F.comps(env)
  local fs = env:Get_option('full_shape')
  if fs then env:Unset_option('full_shape') end

  env.engine:commit_text( env:components_str():concat(_NR) )

  if fs then env:Set_option('full_shape') end
end

function F.cal(env)

  local fs = env:Get_option('full_shape')
  if fs then env:Unset_option('full_shape') end

  local cal = require 'tools/cowsay'
  local str = ('```%s%s%s```%s'):format(_NR,cal(),_NR,_NR)
  env.engine:commit_text(str)

  if fs then env:Set_option('full_shape') end
  --engine:commit_text("```" .. _NR)
  --local cal = require('tools/cowsay')
  --cal():split("\n")
  --:each(function(line)
    --engine:commit_text(line .. _NR)
  --end)
  --engine:commit_text("```" .. _NR)
end
function F.cowsay(env)
  local engine=env.engine
  engine:commit_text("```" .. _NR)
  for line in io.popen("cal |cowsay -n"):lines() do
    engine:commit_text(line .. _NR)
  end
  engine:commit_text("```" .. _NR)
end
function F.ver(env)
  env.engine:commit_text( rime_api.Ver_info() )
end
function F.reload(env)
  if rime_api.Version() < 139 then
    env.engine:process_key(env.keys.reload)
  else 
    env.engine:apply_schema(Schema(env.engine.schema.schema_id))
  end
  return 1
end
function F.menusize(env,size)
  env.engine.context:clear()
  if size > 0  and size <10 then
    env:Config_set('menu/page_size', size )
    Log(DEBUG,env,size,env:Config():get_string('menu/page_size'))

    F.reload(env)
  end
  return 1
end

-- init_processorr 
local function init_modules(env)
  local modules = List( env:Config_get(env.name_space .. "/modules"))
  return modules:map( function(elm)
    if elm.module then rrequire(elm.module,_ENV) end
    local comp=Component.Require(env.engine,"",elm.prescription)
    return comp and {name=elm.prescription,comp=comp}
  end)
  --return modules
end
local function auto_load(env, tab_G)
  tab_G = tab_G or _ENV
  List("processors","segmentors","translators","filters")
  :map(function(elm) return "engine/" .. elm end)
  :reduce(function(elm,org) return org + env:Config_get(elm) end,List())
  :select_match("^lua_")
  :each(function(elm)
    local mod_name = elm:split("@")[2]
    if not rrequire(mod_name) then
      Log(ERROR,'lua component require module failed', mod_name)
    end
  end)
end

-- append  segments, translators , filters
-- from_path, dist_path :  ConfigMap -- key->ConfigList
local function append_component(env, from_path,dist_path)
  local from = from_path and env:Config_get(from_path)
  if not from then return end
  dist_path = dist_path or "engine"

  for sub_path, f_list in pairs(from) do
    local path = dist_path .. "/" ..sub_path
    local dist_clist = List(env:Config_get(path))
    List(f_list):each(function(elm_str)
      dist_clist:append(
        not dist_clist:find(elm_str) and elm_str or nil )
    end)
    env:Config_set(path,dist_clist)
  end
end

-- init_processor

local M={}
function M.init(env)
  if ENGINE_TEST then require('testl/engine')() end
  Env(env)

  -- init self --
  --local config=env:Config()
  append_component(env, env.name_space .. "/before_modules")
  if T01 and GD then GD() end
  env.modules = init_modules(env)
  append_component(env, env.name_space .. "/after_modules")

  --auto_load_bak(config:get_map("engine"))
  auto_load(env)

  -- prtscr prtkey keyevent
  env.keys= env:get_keybinds()
  env.keys.reload = env.keys.reload and env.keys.reload or KeyEvent('F9')

  -- use key_binder reload 
  if rime_api.Version() < 139 then 
    local ckeyb= env:Config_get('key_binder/bindings/@0')
    local reload_keyb = { 
      when='always',
      accept= env.keys.reload:repr(),
      select= env.engine.schema.schema_id, 
    }
    if ckeyb.select ~= reload_keyb.select or  
      ckeyb.when ~= reload_keyb.when or
      ckeyb.accept ~= reload_keyb.accept then
      env:Config_set('key_binder/bindings/@before 0', reload_keyb)
    end
  end

  -- init end
  env:Unset_option("_reload")
  env:Unset_option("_menu_size")
  env.opt_update_notifier=env:Context().option_update_notifier:connect(function(ctx,name)
  --[[
    if name == "_reload" then 
      Log(DEBUG,'------ reload ------')
      env.engine.active_engine:apply_schema(env.engine.schema)
    elseif name == "_page_size" then
      local ms= env.engine.schema.page_size == 5 and 9 or 5
      Log(DEBUG,'------ change menu sizer ------',ms )
      env:Config_set('menu/page_size', ms)
      env.engine.active_engine:apply_schema(env.engine.schema)
    end
 --]]
  end)
  do
    ( List()
    + "---- submodules ----"
    + env.modules:map(function(elm) return string.format("%s: %s",elm.name, elm.comp) end)
    + "---- engine components ----"
    + env:components_str()
    + "---- recognize/patterns  ----"
    + List(env:Config_get_with_path("recognizer/patterns")):map(function(elm)
      return elm.path .. ": " .. elm.value end)
    ):each(function(elm,out)  Log(out,elm) end, INFO)
  end
end


function M.fini(env)
  -- modules fini
  env.modules:each(function(elm) elm=nil end)
  env.opt_update_notifier:disconnect()
  
  -- self finit --
end



function M.func(key,env)
  local Rejected,Accepted,Noop=0,1,2
  local context=env.engine.context
  local status=env:get_status()

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
  if key:repr() == 'space' and active_input and active_input:match('menusize%d') then
    local nfunc, ssize = active_input:match("(.+)(%d)")
    Log(DEBUG,'active_input',active_input,F[nfunc],nfunc,ssize)
    return F[nfunc](env,tonumber(ssize))
  end

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

return ( ConfigMap or rime_api.Version()>= 127) and M or Er
