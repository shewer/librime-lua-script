#! /usr/bin/env lua
--
-- find_word.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
-- 以詞定字 + 反查字根
-- 注意: Shadow Candidate 無法變更 text preedit comment 所以無法顯示，但是定字上屏仍然有效
--       可以用[<number> 選字上屏
-- 此模組只有一佪 component  lua_processor
-- 觸發條件  對選中的candidate 詞長>1  and  NEXT_KEY PREV_KEY
-- 引用資料
-- name_space/dictinary : 調用反查字典  預設: translator/dictionary
-- name_space/preedit_fromat: 單字字根轉置 預設: translator/preedit_format
--    可以利用 name_space 選用其他反查字典及 preedit_format
-- name_space/next_key  NEXT_KEY  : 觸發鍵   預設: "["
-- name_space/prev_key  PREV_KEY  : 觸發鍵   預設: " ]"
-- name_space/use_reverse:  booleand default nil
-- 如果要反查 須要 dictionary 和 projection pattern 配合
-- dictionary:  name_space/dictionary or translator/dictionary
--select_preedit_path: 設定 選用
-- 可以設定 pattern 使用 以下路逕依序嘗試取得 ConfigList
--   name_space: user_define  comment_format preedit_format
--   translator: user_define  comment_format preedit_format
--   ConfigList()

--[[
install 1
-------------------------------------------------------------------------
rime.lua
selcet_character = require 'component/select_character'
<config>.yaml
   engine/processors/@after 0: lua_processor@select_character@<name_space>
-------------------------------------------------------------------------

install 2
-------------------------------------------------------------------------
append to processor_plugin.yaml
module1/modules:
  - { module: 'component/select_character', module_name: 'select_character' , name_space: 'translator' }
  - ......
  - .....

-------------------------------------------------------------------------

local C01=""
--]]
--  require 'tools/string' -- utf8 module
-- local List=require 'tools/list'
require 'tools/string'
local puts = require 'tools/debugtool'
-- default  keybinds
local NEXT_KEY="["
local PREV_KEY="]"

-- warp  candidate module
-- Warp_cand( cand )
-- api of warp_cand
-- obj:size(), object:len() -- return number
-- obj:text(), obj:preedit(), obj:select_character() -- return character self:index()
-- obj:preedit(text), obj:select_character(index ) -- set and get
--
-- obj:index(number)
-- obj:dec(), obj:inc()  -- set self:index +1 or -1
-- obj:eq(canddidate) or obj == candidate
-- obj:clear() -- reset warp_cand
--

local CM={}
CM.__index=CM
function CM.eq(self,cand)
  return  type(cand) == "userdata" and cand.text and cand.text == self._cand.text
end
CM.__eq=CM.eq

function CM:len()
  return self._size
end
CM.size= CM.len

function CM:text()
  return self._cand.text
end
function CM:type()
  return self._cand.type
end
function CM:quality()
  return self._cand.quality
end

function CM:comment(text)
  if text then
    self._org_comment = self._org_comment and self._org_comment or self._cand.comment
    self._cand.comment= text
  end
  return self._cand.comment
end
function CM:preedit(text)
  if text then
    self._org_preedit = self._org_preedit and self._org_preedit or self._cand.preedit
    self._cand.preedit= text
  end
  return self._cand.preedit
end

------ test
function CM:index(index)
  if type(index) == "number" then
    self._index = (index -1) % self:size()
  end
  return self._index and self._index +1 or nil
end

function CM:_update()
  if self:index() then
    self:preedit(
      self:_projection()
    )
  end
end

function CM:inc()
  local index= self:index() or  0
  puts(C01,__LINE__(), "----------inc index" , self:index(),self._cand:get_dynamic_type(),self._org_cand:get_dynamic_type() )
  self:index( index +1  )
  puts(C01,__LINE__(), "----------inc index after " , self:index() )
  self:_update()
  return self:index()
end
function CM:dec()
  puts(C01,__LINE__(), "----------dec index" , self:index(),self._cand:get_dynamic_type(),self._org_cand:get_dynamic_type() )
  local index= self:index() or  self:size()+1
  self:index( index -1 )
  puts(C01,__LINE__(), "----------dec index after " , self:index() )
  self:_update()
  return self:index()
end

--- test end


function CM:select_character(index)
  index = self:index(index)
  local word=  self._cand.text:utf8_sub(index,index)
  return word
end
function CM:select_org_character(index)
  index = self:index(index)
  local word=  self._org_cand.text:utf8_sub(index,index)
  return word
end

function CM:clear()
  self._cand.preedit= self._org_preedit
  self._cand.comment= self._org_comment
  self._cand=nil
  self._index=nil
  self._size=nil
  self._projection=nil
end


local function Warp_cand(cand, projection_func, index )
  if type(cand) ~= "userdata" or not  cand.text then
    return nil
  end
  local obj={}
  obj._org_cand=cand
  obj._cand=cand:get_genuine()
  obj._size=cand.text:utf8_len()
  obj._org_preedit=obj._cand.preedit
  obj._org_comment=obj._cand.comment
  obj._projection=projection_func
  obj._index= index
  return setmetatable(obj, CM )
end

--
--
--
local function load_project_func(env)
  local config= env.engine.schema.config
  local use_reverse= config:get_int(env.name_space .. '/use_reverse') or  true

  if use_reverse then
    -- load reversedb
    local dictionary= config:get_string( env.name_space .. "/dictionary") or config:get_string("translator/dictionary" )
    reversedb= rime_api.load_reversedb(dictionary)

    select_preedit_path= config:get_string(env.name_space .. '/select_preedit_format') or "comment_format"
    -- load projection
      local configlist = List(env.name_space, "translator"):each(function(ns)
        local _item= List(select_preedit_path, "comment_format","preedit_format"):each(function(path)
          path = ns .. "/" .. path
          if config:get_list_size( path ) > 0  then
            return config:get_list( path )
          end
        end )
        if _item then return _item end
      end) or ConfigList()
    projection = Projection()
    projection:load( configlist )
    -- update use_reverse
    use_reverse = projection and reversedb and use_reverse
  end
  return  function(warp_cand)
      local org_word= warp_cand:select_org_character()
      local word= warp_cand:select_character()
      return org_word .. (  org_word ~= word and  "[" .. word .."]" or "")
      .. ( use_reverse  and projection:apply( reversedb:lookup( word ) ) or "" )
  end
end
local M={}
function M.init(env)
  local config=env.engine.schema.config
  local context=env.engine.context

  -- load  bindings
  local nk=config:get_string(env.name_space .. "/next_key" ) or NEXT_KEY
  env.head= KeyEvent(nk )
  local pk=config:get_string(env.name_space .. "/prev_key" ) or PREV_KEY
  env.tail= KeyEvent(pk )
  -- load preedit_mode  default
  env.projection_func= load_project_func(env)

end

function M.fini(env)
end

function M.func(key,env)
  local Rejected,Accepted,Noop=0,1,2
  local context=env.engine.context
  if key:release() or key:ctrl() or key:alt() then return Noop end

  if context:has_menu() then

    -- check selected candidate
    local cand= context:get_selected_candidate()
    if not cand  then return Noop end
    if cand.text:utf8_len() < 2 then  return Noop end
    -- entery  select_character  processor

    if key:eq(env.head) then
      -- 往下定字  -->
      env.cand = env.cand and env.cand or Warp_cand(cand, env.projection_func)
      env.cand:inc()
      return Accepted
    elseif key:eq(env.tail) then
      -- 往上定字  <--
      env.cand = env.cand and env.cand or Warp_cand(cand, env.projection_func)
      env.cand:dec()
      return Accepted
    elseif  env.cand and (key.keycode> 0x30 and key.keycode < 0x3a or key.keycode == 0x20) then
      local n= key.keycode - 0x30
      -- 以詞定字模式標 定字上屏
      env.engine:commit_text( env.cand:select_org_character( n >0 and n or nil ) )

      -- clear env.cand
      env.cand:clear()
      env.cand=nil
      -- clear context.input
      context:clear()
      return Accepted
    end
  end

  if env.cand then
    -- clear env.cand
    env.cand:clear()
    env.cand=nil
  end
  return Noop
end


return M
