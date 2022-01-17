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

function CM:_update_preedit()
  if  self._index then 
    self:preedit( 
      self._projection( self:select_character() )
    )
  end
  return self._cand.preedit
end 
function CM:_update_commentt()
  if  self._index then 
    self:comment(
      self._projection( self:select_character() )
    )
  end
  return self._cand.comment
end 
function CM:_update()
  self:_update_preedit()
  --[[    Shadow Candadite can't modify 
  if self._cand:get_dynamic_type() == "Shadow" then 
    self:_update_commentt()
  else
    self:_update_preedit()
  end 
  --]]
end 

function CM:inc()
  local index= (self:index() or  0 ) + 1
  self:index( index  ) 
  self:_update()
  return self:index()
end
function CM:dec()
  local index= (self:index() or  self:size()+1 ) - 1
  self:index( index  ) 
  self:_update()
  return self:index()
end 

--- test end 


function CM:select_character(index)
  index = self:index(index)
  local word=  self._cand.text:utf8_sub(index,index) 
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
  obj._cand=cand
  obj._size=cand.text:utf8_len() 
  obj._org_preedit=cand.preedit
  obj._org_comment=cand.comment
  obj._projection=projection_func 
  obj._index=nil
  return setmetatable(obj, CM )
end 

--   env.cand =  (env.cand and env.cand== cand and env.cand)  or cand
--  set cand   set or replace env.cand 
local function set_cand(env,cand)
      --env.cand = env.cand and env.cand:eq(cand_temp) and env.cand 
      --or Warp_cand(cand_temp, env.projection_func)
      if not env.cand  then 
        -- set env.cand
        env.cand=Warp_cand(cand, env.projection_func )
      elseif not env.cand:eq(cand) then 
        -- replease env.cand
        env.cand:clear()
        env.cand=Warp_cand(cand, env.projection_func )
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
  
  -- load reversedb 
  local dictionary= config:get_string( env.name_space .. "/dictionary") or config:get_string("translator/dictionary" )
  env.reversedb= rime_api.load_reversedb(dictionary)

 -- load projection 
  local preedit_item= config:get_item(env.name_space .. "/preedit_format") 
  or config:get_item("translator/preedit_format" ) 
  or ConfigList().element
  env.projection = Projection()
  env.projection:load( preedit_item:get_list() ) 

  -- projection_func( word) return  包含 字根 preedit 
  env.projection_func = function(word) 
    return word .. " " .. 
    env.projection:apply(
    env.reversedb:lookup( word )
    )
  end 

end
function M.fini(env)
end
local function chk_cand(info,w_cand, cand) 
  print( "-----",info,"-------")
  local t= setmetatable({}, {__index=cand}) 
  print("----------------->", t.text )
  print("-----cand_temp",cand,cand.type, cand.text , cand.preedit, cand.comment, cand.quaility,cand:get_dynamic_type() ) 
  if w_cand then 
    print("-----env.cand",w_cand._cand,w_cand:type(), w_cand:text() , w_cand:preedit(teteu), w_cand:comment(), w_cand:quality(),w_cand._cand:get_dynamic_type()) 
    print("check env.cand:eq( cand_temp)" ,w_cand:eq(cand) ,w_cand == cand ,w_cand:size() , w_cand:index(), w_cand:index() and w_cand:select_character(),
    w_cand:index() and w_cand._projection( w_cand:select_character() ) )
  end 
end 
function M.func(key,env)
  local Rejected,Accepted,Noop=0,1,2
  local context=env.engine.context
  if key:release() or key:ctrl() or key:alt() then return Noop end 

  if context:has_menu() then

    -- check selected candidate
    local cand_temp= context:get_selected_candidate()
    if not cand_temp then return Noop end 
    if  cand_temp.text:utf8_len() < 2 then  return Noop end 
    -- entery  select_character  processor 

    if key:eq(env.head) then 
      -- 往下定字  -->
      --set_cand(env,cand_temp)
      env.cand = env.cand and env.cand:eq(cand_temp) and env.cand 
      or Warp_cand(cand_temp, env.projection_func)

      env.cand:inc()
      return Accepted
    elseif key:eq(env.tail) then 
      -- 往上定字  <--
      --set_cand(env,cand_temp)
      env.cand = env.cand and env.cand:eq(cand_temp) and env.cand
      or Warp_cand(cand_temp, env.projection_func)

      env.cand:dec()
      return Accepted
    elseif env.cand and key:repr() == "space" then 
      -- 以詞定字模式標 定字上屏
      env.engine:commit_text( env.cand:select_character() )

      -- clear env.cand
      env.cand:clear()
      env.cand=nil
      -- clear context.input
      context:clear()
      return Accepted
    elseif env.cand and key.keycode > 0x30 and key.keycode < 0x3a  then 
      --  以詞定字模式  數字鍵直接上屏
      env.engine:commit_text( env.cand:select_character(key.keycode - 0x30) )

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
