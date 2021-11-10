#! /usr/bin/env lua
--
-- conjunctive.lua
-- Copyright (C) 2021 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
--[[

-- rime.lua
conjunctive_proc= require 'conjunctive'


---  custom.yaml
patch:
engine/processors/@after 0: lua_processor@conjunctive_proc



這個模塊會自動建立
engine/translators: lua_translator@conjunctive --
recognizer/patterns/conjunctive:  "^" .. pattern_str  觸發 tag
--]]

local List=require 'tools/list'
function __LINE__(n) n=n or 2 return debug.getinfo(n, 'l').currentline end

local function get_tags(config,path)
  local list=List()
  for i=0,config:get_list_size(path) -1 do
    list:push( config:get_string(path .. "/@" .. i ) )
  end
  return list
end

local F={}
function F.init(env)
  local context=env.engine.context
  local config=env.engine.schema.config

  env.match_all = config:is_null(env.name_space .. "/tags")
  env.tags = env.match_all and List() or get_tags(config,path )
  env.reject_tags=  List{}
  env.match_type={history=true}

end

function F.fini(env)
end

function F.func(tran,env)
  local uniquify_key={}
  for cand in tran:iter() do
    if env.match_type[cand.type] then
      yield( cand )
    elseif  not uniquify_key[cand.text] then
      uniquify_key[cand.text]  = true
      yield(cand)
    end
  end
end
function F.tags_match(seg,env)
  if env.match_all then
    env.reject_tags:each(function(elm) seg:has_tag(elm) end  )
  else

  end
  return true

end


-- 使用者常用詞
_HISTORY=List{
  "發性進行性失語",
  "發性症狀",
  "發性行性失語症狀",
  "發性進行失語症狀",
  "發進行性失症狀",
  "發性進行失語症狀",
  "性進行失語症狀",
  "發性行性失語症狀",
  "進行性失語症狀",
}

-- user define data
local pattern_str="~~"
local lua_tran_ns="conjunctive"
local dict_file= 'essay.txt'
--dict_file= '/usr/share/rime-data/essay.txt'  -- debug
local switch_key="F11"

local path_ch= package.config:sub(1,1)

local Dict = require 'tools/dict'
_dict= Dict( "." .. path_ch .. dict_file)
or Dict( rime_api.get_user_data_dir() .. path_ch  .. dict_file)
or Dict( rime_api.get_shared_data_dir() .. path_ch .. dict_file)

local M={}
_G[lua_tran_ns]=M
function M.init(env)
  env.dict= _dict or Dict("essay.txt")
  env.history=""
  env.history_back=""

  env.commit_connect= env.engine.context.commit_notifier
  :connect(
  function(ctx)
    local conjunctive_mode = not ctx:get_option(lua_tran_ns) and not ctx:get_option("ascii_mode")
    if not conjunctive_mode then return end

    local cand=ctx:get_selected_candidate()
    local command_mode= cand and "history" == cand.type  and "" == cand.text
    -- change env.history
    if command_mode then
      env.history_back=  env.history
      env.history = cand.comment:match("^(.*)[-][-].*$") or env.history
    end

    local update_commit = ctx.input ~= ctx:get_commit_text()
    if update_commit then
      env.history = env.history .. ctx:get_commit_text() or ""
      env.history = env.history:utf8_sub(-10)
      print( env.history, ctx.input , ctx:get_commit_text() )

      env.history_commit=  not env.dict:empty(env.history)
    end
  end )

  env.update_connect= env.engine.context.update_notifier
  :connect(
  function(ctx)
    if env.history_commit then
      env.history_commit=nil
      ctx.input=pattern_str
    end
  end )
end

function M.fini(env)
  env.commit_connect:disconnect()
  env.update_connect:disconnect()
end

local function set_history(input,seg,env)

  local str = input:match("^" .. pattern_str .. "(.*)$") or ""
  if str == "C" then
    yield( Candidate("history", seg.start, seg._end, "", "--清除(" .. env.history .. ")" ))
    yield( Candidate("history", seg.start, seg._end, "", env.history_back.. "--還原" ))
    return env.history
  end
  if str == "B" then
    yield( Candidate("history", seg.start, seg._end, "", env.history_back.. "--還原" ))
    return env.history
  end
  if str == "H" then
    for i=1,#_HISTORY do
      local history_str=_HISTORY[i]
      if history_str and history_str:len()>0 then
        yield( Candidate("history", seg.start, seg._end,  history_str ,"" ..  "--選用" ))
      end
    end
    return env.history
  end
  if str:match("[<>~]+") then
    local si=1
    local ei=1
    for i=1,#str do
      local c = str:sub(i,i)
      ei =  c:match("[~<]") and ei - 1 or ei
      si =  c:match("[>]") and si + 1 or si
    end
    ei = ei < 0  and ei or nil
    local history_str = env.history:utf8_sub(si,ei) or ""
    yield( Candidate("history", seg.start, seg._end, "", history_str.. "--修改" ))

    return history_str
  end

  return env.history

end

function M.func(input,seg,env)
  local context = env.engine.context
  if context:get_option(lua_tran_ns) then return end  -- false: enable true: disable
  if not seg:has_tag(lua_tran_ns)  then return end

  -- change env.history string
  local history_str = set_history(input,seg,env)

  for w ,wt in env.dict:reduce_iter(history_str) do
    yield( Candidate( lua_tran_ns , seg.start,seg._end, w, "(聯)") )
  end
end



local function print_config(config)
  local puts = print -- log and log.info or print
  local function list_print(conf,path)
    puts( "------- " .. path .. " --------")
    for i=0, conf:get_list_size(path) -1 do
      path_i= path .. "/@" .. i
      puts( path_i ..":\t" .. conf:get_string(path_i) )
    end
  end
  List({"processors","segmentors","translators","filters"})
  :map(function(elm) return "engine/" .. elm end )
  :each(function(elm) list_print(config,elm) end)
end

-- option conjunctive enable(false ) disable(true)
local function add_keybind(config,keybind)
  local path="key_binder/bindings"
  local keybind_list_size=config:get_list_size(path)
  for i=0, keybind_list_size-1 do
    local toggle_str =config:get_string( ("%s/@%s/toggle"):format(path,i) )
    if toggle_str == lua_tran_ns then return end
  end
  local last_index=keybind_list_size
  for key,value in pairs(keybind) do
    local path =  ("%s/@%s/%s"):format(path,last_index,key)
    config:set_string(path,value)
  end
end


local function add_component_tran(config,component_str)
  component_str=  component_str or "lua_translator@" .. lua_tran_ns
  local punct_str= "punct_translator"
  local echo_str= "echo_translator"
  local punct_i,echo_i
  local tran_path= "engine/translators"
  -- find index  of echo and punct
  local trans_list_size = config:get_list_size(tran_path)
  for i=0,trans_list_size-1 do
    local tran= config:get_string( ("%s/@%s"):format(tran_path, i) ) or ""
    echo_i = ( not echo_i and  tran:match(echo_str) ) and i or echo_i
    punct_i = ( not punct_i and tran:match(punct_str) ) and i or punct_i
    -- conjunctive already in translators
    if tran:match(component_str) then return end
  end
  -- insert  lua_translator  of conjunctive into translators
  local index = echo_i and  echo_i +1 or 0  -- index < echo_i
  index = punct_i  and index >=punct_i and index or punct_i  -- index >= punct_i
  config:set_string( tran_path .. "/@before " .. index, component_str )
end

local function replase_filter(config)
  local path= "engine/filters"
  local refilter= "uniquifier"
  for i=0, config:get_list_size(path)-1 do
    local filter=config:get_string(path .. "/@" .. i )
    if filter == refilter then
      config:set_string(path .. "/@" .. i, "lua_filter@".. refilter  )
    end
  end
end

local P={}

function P.init(env)
  local config=env.engine.schema.config

  -- set module  "conjunctive"
  _G[lua_tran_ns]= _G[lua_tran_ns] or M
  _G["uniquifier"]= F -- require 'component/uniquify'

  -- set alphabet string
  env.alphabet= config:get_string("speller/alphabet") or "zyxwvutsrqponmlkjihgfedcba"

  config:set_string("recognizer/patterns/" .. lua_tran_ns ,
  "^" .. pattern_str .."[BCH<>~]*$" )

  -- register keybinder {when: "always",accept: switch_key, toggle: conjunctive }
  add_keybind(config, {when= "always", accept= switch_key, toggle= lua_tran_ns } )
  -- add lua_translator after echo_translator before punct_translator
  add_component_tran(config, "lua_translator@" .. lua_tran_ns )
  -- replease uniquifire
  replase_filter(config)
  -- print compoments
  print_config(config)
  local pattern_p= "recognizer/patterns/" .. lua_tran_ns
  print( pattern_p , config:get_string(pattern_p ) )

end

function P.fini(env)
end

function P.func(key, env)
  local Rejected,Accepted,Noop= 0,1,2
  local context = env.engine.context

  -- true(1) : disable  false(0) enable
  local conjunctive_mode = not context:get_option(lua_tran_ns) and not context:get_option("ascii_mode")
  if not conjunctive_mode then return Noop end

  local ascii=  key.modifier <=1 and key.keycode <128
  and string.char(key.keycode)
  or ""

  -- "~" 觸發聯想
  if not context:is_composing() and  ascii == "~" then
    context.input= pattern_str
    return Accepted
  elseif context.input:match("^" .. pattern_str) then
    -- "~~~" 聯想工作狀態
    -- lua_translator@conjunctive 處理 env.history
    if ascii:match("^[BCH<>~]$") then
      context:push_input(ascii)
      return Accepted
    end
    -- 中斷聯想
    if ascii:match("^[" .. env.alphabet .. "]$" ) then
      context:clear()
      return Noop
    end
  end
  return Noop
end

return P
