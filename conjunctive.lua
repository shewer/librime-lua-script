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
local puts = require 'tools/debugtool'



-- 使用者常用詞
local _HISTORY=List{
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
local pattern_str ="~~"
local rec_char= "BCH<>~"
local rec_pattern = ("^%s[%s]*$"):format(pattern_str, rec_char)
local lua_tran_ns = "conjunctive"

-- 词库设定 : 如果不需要 繁简转换 remark dict_file_cn
-- 繁简转换原则以 simplifier 工作原则 以 option simplification 切换繁简约
local dict_file = 'essay.txt'
local dict_file_cn = 'essay-zh-hans.txt'

--dict_file= '/usr/share/rime-data/essay.txt'  -- debug
local switch_key ="F11"
local escape_key = "%.%-"
local path_ch= package.config:sub(1,1)

local Dict = require 'tools/dict'
local M={}
puts(CONSOLE,__FILE__(),"load dict .........")
local t1=os.clock()
M._dict=M._dict or  Dict( "." .. path_ch .. dict_file)
  or Dict( rime_api.get_user_data_dir() .. path_ch  .. dict_file)
  or Dict( rime_api.get_shared_data_dir() .. path_ch .. dict_file)
if not M._dict then 
  puts("trace", __FILE__(),__LINE__(), "open dict faild", dict_file_cn )
end 
puts(CONSOLE,__FILE__(),"loaded dict .........",os.clock() - t1 )


puts(CONSOLE,__FILE__(),"load dict .........")
local t1=os.clock()
if dict_file_cn then
  M._dict_cn =  M._dict_cn
  or  Dict( "." .. path_ch .. dict_file_cn)
  or Dict( rime_api.get_user_data_dir() .. path_ch  .. dict_file_cn)
  or Dict( rime_api.get_shared_data_dir() .. path_ch .. dict_file_cn)
  if not M._dict_cn then 
    puts("trace", __FILE__(),__LINE__(), "open dict faild", dict_file_cn )
  end 
end
puts(CONSOLE,__FILE__(),"loaded dict .........",os.clock() - t1 )

function M.init(env)
  env.dict= M._dict or Dict("essay.txt")
  env.dict_cn= M._dict_cn or M._dict

  env.history=""
  env.history_back=""

  env.commit_connect= env.engine.context.commit_notifier:connect(
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

      local commit_text= ctx:get_commit_text()
      if  #commit_text>0 and  ctx.input ~= commit_text then
        env.history = env.history .. commit_text
        env.history = env.history:utf8_sub(-10)
        --print( env.history, ctx.input , ctx:get_commit_text() )

        env.history_commit=  not env.dict:empty(env.history)
      end
  end  )



  env.update_connect= env.engine.context.update_notifier:connect(
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


function M.func(input,seg,env)
  local context = env.engine.context
  local history= env.history
  if context:get_option(lua_tran_ns) then return end  -- false: enable true: disable
  if not seg:has_tag(lua_tran_ns)  then return end

  -- start

  local active_input = input:match("^".. pattern_str .. "(.*)$")
  if active_input == nil then return end
  local preedit= "[聯]"
  local cand_type="history"

  if active_input == "C" then
    local cand1= Candidate(cand_type, seg.start, seg._end, "", "--清除 (" .. history .. ")" )
    local cand2= Candidate(cand_type, seg.start, seg._end, "", env.history_back.. "--還原" )
    cand1.preedit= preedit .. "clear"
    cand2.preedit= preedit .. "restory"
    yield(cand1)
    yield(cand2)

  elseif active_input == "B" then
    local cand2= Candidate(cand_type, seg.start, seg._end, "", env.history_back.. "--還原" )
    cand2.preedit= preedit .. "restory"
    yield(cand2)

  elseif active_input == "H" then
    _HISTORY:each(function(elm)
	local cand1=  Candidate(cand_type, seg.start, seg._end, elm, "--自選" )
	cand1.preedit= "[選]".. elm
	yield(cand1)
    end)

  elseif active_input:match("[<>~]+") then
    if #active_input >1 then
      active_input=active_input:sub(2)
      local si= #active_input:gsub("[^>]","") +1
      local ei= - #active_input:gsub("[^<~]","")
      history = history:utf8_sub(si,ei)
    end
    local cand3= Candidate(cand_type, seg.start, seg._end, "", history .. "--修改" )
    cand3.preedit= "[修]" .. history
    yield(cand3)
  end

  local dict = context:get_option("simplification") and env.dict_cn or env.dict
  for w ,wt in dict:reduce_iter(history) do
    local cand= Candidate( lua_tran_ns , seg.start,seg._end, w, "(聯)")
    cand.preedit=w .. preedit
    yield(cand)
  end
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


-- append  lua_translator@conjunctive
local function components(env)
  local config=env:Config()
  -- set module  "conjunctive"
  _G[lua_tran_ns]= _G[lua_tran_ns] or M
  -- add lua_translator after echo_translator before punct_translator
  local path= "engine/translators"
  local name= "lua_translator@" .. env.name_space
  if not config:find_index(path,name) then
    config:config_list_append(path, name)
  end

  -- add pattern "~~"
  config:set_string("recognizer/patterns/" .. lua_tran_ns , rec_pattern)

  -- register keybinder {when: "always",accept: switch_key, toggle: conjunctive }
  add_keybind(config, {when= "always", accept= switch_key, toggle= lua_tran_ns } )
end
local P={}



function P.component(env,name)
end

function P.init(env)
  Env(env)
  assert(env.name_space == "conjunctive" , "name_space not match ( lua_processor@<module>@conjunctive)")
  local config= env:Config()
  -- add  lua_translator@conjunctive
  components(env)


  env.commit_select= ("^[%s%s%s]$"):format(
    rec_char .. " " , config:get_string("menu/alternative_select_keys") or "%d", escape_key )
  -- set alphabet string
  env.alphabet= config:get_string("speller/alphabet") or "zyxwvutsrqponmlkjihgfedcba"
  env.key_press=false
end

function P.fini(env)
end

function P.func(key, env)
  local Rejected,Accepted,Noop= 0,1,2

  local context = env.engine.context

  -- true(1) : disable  false(0) enable
  local conjunctive_mode = not context:get_option(lua_tran_ns) and not context:get_option("ascii_mode")
  if not conjunctive_mode then return Noop end

  local status= env:get_status()
  local ascii=  key.modifier <=1 and key.keycode <128
    and string.char(key.keycode)
    or ""

  if status.empty and ascii == "~" then
    -- "~" 觸發聯想
    context.input= pattern_str
    return Accepted
  end

  -- 中斷聯想: 清除input  ~~ 不處理key
  if  context.input:match("^" .. pattern_str)
    and not   ascii:match(env.commit_select)
    and ( #ascii > 0 or key:repr() == "Return" ) then
    context:clear()
    return Noop
  end

  return Noop
end

return P
