#! /usr/bin/env lua
--
-- cal_cmd.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
-- 安裝 
-- 1 使用 librime-lua-script processor_plugin.yaml 
--  module/modules/@after 1:  
--      { prescription: "lua_processor@calculater.proc@cal_cmd" } # lua/command/proc.lua
--
-- 2 使用 librime-lua-script 環境 ，獨立使用 
--  patch:
--    engine/processors/@after 1: lua_processor@calculater.proc@cal_cmd
--
--
-- 3 無 librime-lua-script 環境下，單獨使用 手動載入 proc  & tran 
--
-- patch:
--   engine/processors/@after 1: lua_processor@calculater.proc@cal_cmd
--   engine/translators/@next: lua_translator@calculater.filter
--
--  
--  

-- 將此模組加入 recognizer 前 
--patch:
--  engine/processors/@before 2: lua_processor@calculater.proc@cal_cmd # @2(recognizer)
--  engine/translators/@next: lua_translator@calculater.tran@cal_cmd #
--
-- 沒有 librime-lua-script 單獨使用 calculater 請手動加入
--patch:
--  engine/processors/@before 2: lua_processor@calculater.proc@cal_cmd # @2(recognizer)
--  engine/translators/@next: lua_translator@calculater.tran@cal_cmd #
-- 
-- lua_processor@calculater.proc@cal_cmd
-- lua_translator@calculater.tran@cal_cmd
-- recognizer/patterns/punct: "^=.*"  -- accept  space  use Return commit
-- 
-- 輸入 '=' 即開始進入計算機,輸入 return後 才可以 commit 或繼續累計
-- commit: \n[\n\d ]   return space number
-- 其他: 繼續累計
-- 
-- ex:
-- =33+33{Return}*3{Return}/2{Return}{Return} -- ((33+33)*3)/2 
--
-- =a=1;b=2; c=3{Return}a+B+c{Return}*2{Return}{space} (a+b+c)*2 
--
-- =for i=1,10 do res=res+i end
--
-- =1+2+3{Return}res= res + 1{Return}sin(pi*res){Return}{Return}  sin( ((1+2+3)+1)*pi )
--
-- 

local Env = require 'tools/env_api'
local List = require 'tools/list'
local cmd=require 'calculater/cal_cmd'
local _NR = package.config:sub(1,1) == "/" and "\n" or "\r"

local function init_tran1(env,t_module,t_path,t_component)
  rrequire(t_module)
  assert(_ENV[t_module],'not fount module ')
  if List and not List(env:Config_get(t_path)):find(t_component) then
    env:Config_set(t_path .. "/@next", t_component)
  end
end
local function init_tran2(env,t_module,t_path,t_component)
  _ENV[t_module]= require(t_module)
  local config=env.engine.schema.config
  local trans_size=config:get_list_size(t_path)
  for i=0, trans_size-1 do
    if  t_component == config:get_string(t_path .. "/@" .. i) then
      return
    end
  end
  config:set_string(t_path .. "/@next", t_component)
end

local function component(env)
  local config = env.engine.schema.config
  -- 加入 recognizer/patterns
  local path= "recognizer/patterns/" .. env.name_space
  local pattern = "^(=.*)$"
  --local pattern = "^=.*[\\n\\r]?$"
  --local pattern = [[^=(|.|.*[^\n].|.*\n[^\n\d ])$]]
  config:set_string(path, pattern)

  -- 加入 lua_translator@<tmodule>@env.name_space
  local t_module = 'calculater.tran'
  local t_path= "engine/translators"
  local t_component=  ("%s@%s@%s"):format( "lua_translator", t_module, env.name_space)
  if env.Config_set then
    init_tran1(env,t_module,t_path,t_component)
  else 
    init_tran2(env,t_module,t_path,t_component)
  end
end

local P={}
function P.init(env)
  if false and Env then Env(env) end

  --assert(env.get_status,"check ------- get_status")
  component(env)
  env.ret1= KeyEvent("Return")
  env.ret2= KeyEvent("KP_Enter")
  --env.commit_key= KeyEvent("Control+Return")
  --assert(env.commit_key)
end
function P.fini(env)
end

local function has_tag(ctx, tag)
  local comp= ctx.composition
  local seg = not comp:empty() and comp:back()
  if seg and seg:has_tag(tag or "") then
    return true
  end
end

local function get_char(key,env)
  -- 0xff80 KP_xxx
  local kcode= key.keycode
  if key:eq(env.ret1) or key:eq(env.ret2) then
    return _NR
  elseif kcode >=0x20 and kcode< 0x7f then 
    return string.char(kcode)
  -- KP 0-9 .+-*/ Enter 
  elseif kcode >= 0xffa0 and kcode <= 0xffbf then
    return string.char(kcode ~ 0xff80 )
  else 
    return ""
  end
end

local function commit_candidate(env,mindex)
  local context= env.engine.context
  if context:has_menu() then
    mindex = tonumber(mindex)
    if mindex and mindex > 0 and mindex <=9 then
      local seg=context.composition:back()
      local pgsize= env.engine.schema.page_size
      seg.selected_index = mindex - 1 + (seg.selected_index // pgsize) * pgsize 
    end

    if context:confirm_current_selection() then
      context:commit()
      return true
    end
  end
  return false
end

function P.func(key,env)
  local Rejected,Accepted,Noop= 0,1,2
  local context = env.engine.context
  if key:release() or key:alt() or key:ctrl() then 
    return Noop 
  end
  
  if has_tag(context,'cal_cmd') then
    local ch = get_char(key,env)
    local nrchar= context.input:match("[\n\r]$") and true or false
    -- commit candidate
    if nrchar and ch:match('[%d%s]') then
      commit_candidate(env,ch)
      return Accepted
    -- commin comment 
    elseif key:repr() =="Shift+Return" or key:repr() == "Shift+KP_Enter" then
      local cand= context:get_selected_candidate()
      if cand then
        env.engine:commit_text(cand.comment)
      end
      return Accepted
    else 
      -- append input  %w%p \n\r \s 
      if ch:match('[%s%w%p]') then
        context:push_input(ch)
        return Accepted
      end
    end
  end
  return Noop
end

return P
