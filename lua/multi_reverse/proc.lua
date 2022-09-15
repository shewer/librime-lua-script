#! /usr/bin/env lua
--
-- processor.lua
-- Copyright (C) 2021 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
-- 自動加載 多字典反查碼filter
--
--
-- lua_processor@multi_reverse   -- create lua_filter as below
-- lua_filter@completion --  過濾 completion  switch   option: completion
-- lua_filter@multi_reverse@name_space_of_translation(script & table)  -- 使用 property: multi_reverse= name_space  轉換目的反查碼
--
-- 此模組可以獨立載入 lua_processor@multi_reverse 或是 做爲init_processor 子模組
-- function component() 自動載入 completion 且加入 engine/filter 用於過濾cand.type == "Completion"
-- 自動載入 mfilter 查找 engine/translators 中 table_translator and script_translator 且加入 engine/filters
--

--
--
local List=require'tools/list'
local Env= require 'tools/env_api'


local Keybinds={
    toggle= "Control+6",
    qcode= "Control+7",
    completion= "Control+8",
    next= "Control+9",
    prev= "Control+0",
    hold= "Shift_L",
  }

local Completion="completion"
local Multi_reverse='multi_reverse'
local Qcode="qcode"
-- Multi_reverse_hold
local Multi_reverse_hold="multi_reverse_hold"

-- get name_space of table_translator and script_translator
local function get_trans_namespace(env)
  local function ts_trans(tran)
    return tran:match("table_translator@(.+)$") or tran:match("script_translator@(.+)$")
  end
  return List(env:Config_get("engine/translators"))
  :select(ts_trans):map(ts_trans):unshift('translator')
end

local function component(env)
  local config= env:Config()
  local f_path="engine/filters"
  local mfilter='multi_reverse.filter'

  local filters_chk= List(env:Config_get(f_path))
  -- load module 
  _G[Completion] = _G[Completion] or require(Completion)
  _G[mfilter] = _G[mfilter] or require( mfilter )
  -- find match string
  local function fm(elm,mstr) return elm:match(mstr) end

  -- insert  lua_filter@completion at first
  if not filters_chk:find(fm, "lua_filter@"..Completion) then
    config:set_string( f_path .. "/@before 0" , "lua_filter@" .. Completion   )
  end
  --if T02 then GD() end

  -- return  append filter  
  get_trans_namespace(env) :each(function(elm)
    local comp= string.format("lua_filter@%s@%s",mfilter,elm)
    if not filters_chk:find(fm, comp) then
      config:set_string(f_path .. "/@next" , comp)
    end
  end)
end

local function init_keybinds(env)
  local keys= env:Config_get(env.name_space .. "/keybinds")
  for k,v in next, keys do
    keys[k]= KeyEvent(v)
  end
  return keys
end

local P={}
function P.init(env)
  Env(env)
  local context=env:Context()
  local config= env:Config()
  component(env)
  env.keys= init_keybinds(env)

  local MultiSwitch=require'multi_reverse/multiswitch'
  env.trans= MultiSwitch( get_trans_namespace(env) )
  -- load key_binder file

  -- initialize option  and property  of multi_reverse
  --context:set_option(Multi_reverse,true)
  --context:set_option(Completion,true)
  --context:set_option(Qcode, true)
  context:set_property(Multi_reverse, env.trans:status() )

  -- init notifire  option  property  : for  reflash  menu
  --local options= Set(Qcode,Multi_reverse,Completion)
  -- 取消 option reflash_non_composition  --  engine:OnOptionUpdate() 已執行
  env.notifier=List(
  {
    context.property_update_notifier:connect(function(ctx,name)
    if name == Multi_reverse then
      -- reflash cand.comment 
      local selected_index = ctx.composition:back().selected_index
      ctx:refresh_non_confirmed_composition()
      ctx.composition:back().selected_index = selected_index 
    end
    end),
  })
end

function P.fini(env)
  env.notifier:each(function(elm) elm:disconnect() end )
end

function P.func(key,env)
  local Rejected,Accepted,Noop=0,1,2
  local context= env:Context()

  local status= env:get_status()
  -- 在has_menu時才可以設定，可以減少 hot key 衝突
  if status.has_menu then
    local compos= context.composition
    local cand_index= compos:empty() and 0 or compos:back().selected_index
    if key:eq(env.keys.next)  then
      env:Set_property(Multi_reverse, env.trans:next())
    elseif key:eq(env.keys.prev) then
      env:Set_property(Multi_reverse, env.trans:prev())
    elseif key:eq(env.keys.toggle) then
      env:Toggle_option(Multi_reverse)
    elseif key:eq(env.keys.qcode) then
      env:Toggle_option(Qcode)
    elseif key:eq(env.keys.completion) then
      env:Toggle_option(Completion)
      --ctx:refresh_non_confirmed_composition()
      --env.engine:compose()
    else
      -- 使用 Shift_L 顯示字根
      if not context:get_option(Multi_reverse) then
        local state = context:get_option(Multi_reverse_hold)
        local keymatch= key:eq(env.keys.hold)
        -- xor keymatch state   set not state
        if (keymatch and not state) or (not keymatch and state)  then
          context:set_option(Multi_reverse_hold,not state)
          compos:back().selected_index= cand_index
        end
      end
      return Noop
    end
    compos:back().selected_index= cand_index
    return Accepted
  end -- has_menu
  return Noop
end

-- add module
return P
