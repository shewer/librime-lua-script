#! /usr/bin/env lua
--
-- tran.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--


local List=require 'tools/list'
local Env=require 'tools/env_api'
local function convert_excape_char(str,escape_chars)
-- string:gsub(ESCAPECH, "%%%1")      -- ("abc.?*("):gsub(ESCAPECH,"%%%1")
  escape_chars = escape_chars or '%-.?()[*'
  escape_chars = '([' .. escape_chars .. '])'

  return str:gsub(escape_chars,"%%%1")
end
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
--    ^"~~[BCH<>~]*$"
local rec_pattern = ("^%s[%s]*$"):format( convert_excape_char(pattern_str),
convert_excape_char(rec_char) )
local MODNAME="conjunctive"

-- 词库设定 : 如果不需要 繁简转换 remark dict_file_cn
--local dict_file = __conjunctive_file and __conjunctive_file.default or 'essay.txt'
--local dict_file_cn = __conjunctive_file and __conjunctive_file.enable or 'essay_cn.txt'
--dict_file= '/usr/share/rime-data/essay.txt'  -- debug
local switch_key ="F11"
--local ESCAPE_KEY = ".-"
local path_ch= package.config:sub(1,1)


local Dict = require 'tools/dict'
local function load_dict( filename)
  local fpath,path,filename = get_full_path(filename)
  if not fpath then 
    Log(ERROR,'not found file from user_data or sharded_data',filename)
    return 
  end
  Log(INFO,"load dict .........",filename)
  local t1=os.clock()
  local dict=  Dict( filename,path)
  Log(INFO,"loaded dict .........",os.clock() - t1 )
  if not dict then
      Log(WARNING, __FILE__(),__LINE__(), "open dict faild",  filename)
      return
  end
  return dict
end

-- lua_translator@conjunctive
local M={}


function M.init(env)
  env = Env(env)
  local config=env:Config()
  local context=env:Context()
  local files = env:Config_get(env.name_space .. "/files")
  local files = type(files) == "table" and files or {"essay.txt","essay_cn.txt"}
  env.dict= load_dict( files[1] )

  env.keys_name = env:Config_get(env.name_space .. "/keybinds")
  -- remove non ascii key code
  for k, v in next, env.keys_name do 
    env.keys_name[k] = #v == 1 and v or nil
  end
  

  env.history=""
  env.history_back=""

  env.notifiers=List(
  env.engine.context.commit_notifier:connect(
  function(ctx)
    local conjunctive_mode = ctx:get_option(MODNAME) and not ctx:get_option("ascii_mode")
    if not conjunctive_mode then return end

    local cand=ctx:get_selected_candidate()
    local command_mode= cand and "history" == cand.type  and "" == cand.text
    -- change env.history
    if command_mode then
      env.history_back=  env.history
      env.history = cand.comment:match("^(.*)[-][-].*$") or env.history
    end

    -- update history cand:get_genuine().text 
    --local cand = ctx:get_selected_candidate()
    local commit_text= cand and cand:get_genuine().text or ctx:get_commit_text()
    if  #commit_text>0 and  ctx.input ~= commit_text then
      env.history = env.history .. commit_text
      context:set_property(env.name_space,env.history)
      env.history = env.history:utf8_sub(-10)
      env.commit_trigger =  not env.dict:empty(env.history)
    end
  end),
  env.engine.context.update_notifier:connect(
  function(ctx)
    if env.commit_trigger then
      env.commit_trigger =nil
      ctx.input=pattern_str
    end
  end )
  )
end

function M.fini(env)
  env.notifiers:each(function(elm) elm:disconnect() end)
end


function M.func(input,seg,env)
  local context = env.engine.context
  local history= env.history
  if not context:get_option(MODNAME) then return end  -- false: disenable true: enable
  if not seg:has_tag(MODNAME)  then return end

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
      active_input=active_input:sub(3)
      local si= #active_input:gsub("[^>]","") +1
      local ei= history:utf8_len()  - #active_input:gsub("[^<~]","")
      history = history:utf8_sub(si,ei)
    end
    local cand3= Candidate(cand_type, seg.start, seg._end, "", history .. "--修改" )
    cand3.preedit= "[修]" .. history
    yield(cand3)
  end

  for w ,wt in env.dict:reduce_iter(history) do
    local cand= Candidate( MODNAME , seg.start,seg._end, w, "(聯)")
    cand.preedit=w .. preedit
    yield(cand)
  end
end

return M
