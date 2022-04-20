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
local puts=require'tools/debugtool'
local List=require'tools/list'
require 'tools/rime_api'


local Keybinds={
    toggle= "Control+6",
    qcode= "Control+7",
    completion= "Control+8",
    next= "Control+9",
    prev= "Control+0",
    hold= "Shift_L",
    --hold_release= nil
  }
--Keybinds.hold_release= ("%s+Release+%s"):format(Keybinds.hold:match("^(%a+)"),Keybinds.hold)
--[[
local Multi_reverse_sw="Control+6"
local Qcode_sw="Control+7"
local Completion_sw="Control+8"
local Multi_reverse_next="Control+9"
local Multi_reverse_prev="Control+0"
--]]
local Completion="completion"
local Multi_reverse='multi_reverse'
local Qcode="qcode"
-- 增加 hold key
-- Multi_reverse_hold
local Multi_reverse_hold="multi_reverse_hold"
--local Comment_enable="Shift_L"
--local Comment_disable="Shift" .. "+Release+" .. Comment_enable
--local Comment_enable="Contorl_L"
--local Comment_disable="Contorl" .. "+Release+" .. Comment_enable

-- get name_space of table_translator and script_translator
local function get_trans_namespace(config)
  local path="engine/translators"
  local t_list=config:clone_configlist(path)
  :select( function(tran)
    local ns= tran:match("table_translator@(.+)$") or tran:match("script_translator@(.+)$")
    return ns and not config:get_bool(ns .. "/reverse_disable")
  end)
  :map( function(tran)
	return  assert(tran:match("@([%a_][%a%d_]*)$"),"tran not match")
	end )
  t_list:unshift( "translator" )
  return t_list
end

local function component(env)
  local config= env:Config()
  local t_path="engine/translators"
  local f_path="engine/filters"
  -- insert  lua_filter@completion at first
  _G[Completion] = _G[Completion] or require( 'multi_reverse/completion' )
  if not config:find_index(f_path, "lua_filter@" .. Completion ) then
    config:set_string( f_path .. "/@before 0" , "lua_filter@" .. Completion   )
  end
  -- append lua_filter@multi_reverse@<name_space> before uniquifier
  _G[Multi_reverse] = _G[Multi_reverse] or require( 'multi_reverse/mfilter' )
  get_trans_namespace(config):each(function(elm)
    local comp= string.format("lua_filter@%s@%s",Multi_reverse,elm)
    if not config:find_index(f_path, comp) then
      local index = config:find_index(f_path, "uniquifier")
      if index then
        config:set_string(f_path .. "/@before " .. index , comp)
      else
        config:set_string(f_path .. "/@next" , comp)
      end
    end
  end)
end

local function reflash_candidate(ctx,index)

  if ctx.composition:empty() then return end
  local si= index  or ctx.composition:back().selected_index
  ctx:refresh_non_confirmed_composition()
  if ctx.composition:empty() then return end
  ctx.composition:back().selected_index = si
end
local function init_keybinds(env)
  local config = env:Config()
  local MultiSwitch=require'multi_reverse/multiswitch'
  env.trans= MultiSwitch( get_trans_namespace( config ))
  local keys= config:get_obj(env.name_space .. "/keybinds")
  local Func={}
  function Func.next(env)
      env:Context():set_property(Multi_reverse, env.trans:next())
      return true
  end
  function Func.prev(env)
      env:Context():set_property(Multi_reverse, env.trans:prev())
      return true
  end
  function Func.toggle(env)
    env:Context():Toggle_option(Multi_reverse)
    return true
  end
  function Func.qcode(env)
    env:Context():Toggle_option(Qcode)
    return true
  end
  function Func.completion(env)
    env:Context():Toggle_option(Completion)
    return true
  end
  function Func:hold(env)
      if not context:get_option(Multi_reverse) then
        local state = context:get_option(Multi_reverse_hold)
        local keymatch= key:eq(env.keys.hold)
        if keymatch and not state then
          context:set_option(Multi_reverse_hold,true)
          compos:back().selected_index= cand_index
        elseif not keymatch and state then
          context:set_option(Multi_reverse_hold, false )
          compos:back().selected_index= cand_index
        end
      end
  end

  --local hold= keys["hold"]
  --keys["hold_release"] = hold and ("%s+Release+%s"):format(hold:match("^(%a+)"),hold) or nil

  local list = List()
  for k,v in next, keys do
    puts(DEBUG,"----key and keyname:",k,"value : ["..v.."]")
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

  -- load key_binder file
  --env.keybind_tab=require 'multi_reverse/keybind_cfg'
  --assert(env.keybind_tab)

  local MultiSwitch=require'multi_reverse/multiswitch'
  env.trans= MultiSwitch( get_trans_namespace(config) )
  env.keys= init_keybinds(env)


--[[
  env.keys.next= KeyEvent(Multi_reverse_next)
  env.keys.prev= KeyEvent(Multi_reverse_prev)
  env.keys.m_sw= KeyEvent(Multi_reverse_sw)
  env.keys.completion= KeyEvent(Completion_sw)
  env.keys.qcode= KeyEvent(Qcode_sw)
  env.keys.shiftl=KeyEvent(Comment_enable)
  env.keys.shiftl_r=KeyEvent(Comment_disable)
--]]
  -- initialize option  and property  of multi_reverse
  context:set_option(Multi_reverse,true)
  context:set_option(Completion,true)
  context:set_option(Qcode, true)
  context:set_property(Multi_reverse, env.trans:status() )

  -- init notifire  option  property  : for  reflash  menu
  --local options= Set(Qcode,Multi_reverse,Completion)
  -- 取消 option reflash_non_composition  --  engine:OnOptionUpdate() 已執行
  env.notifier=List(
  {
    context.property_update_notifier:connect(function(ctx,name)
    if name == Multi_reverse then
      ctx:refresh_non_confirmed_composition()
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
      context:set_property(Multi_reverse, env.trans:next())
    elseif key:eq(env.keys.prev) then
      context:set_property(Multi_reverse, env.trans:prev())
    elseif key:eq(env.keys.toggle) then
      context:Toggle_option(Multi_reverse)
    elseif key:eq(env.keys.qcode) then
      context:Toggle_option(Qcode)
    elseif key:eq(env.keys.completion) then
      context:Toggle_option(Completion)
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
