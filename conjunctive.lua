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
local rec_pattern = ("^%s%s$"):format(pattern_str,"[A-Z<>~]*$") 
local lua_tran_ns = "conjunctive"
local dict_file = 'essay.txt'
--dict_file= '/usr/share/rime-data/essay.txt'  -- debug
local switch_key ="F11"
local escape_key = "%.%-"
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

    local commit_text= ctx:get_commit_text()
    if  #commit_text>0 and  ctx.input ~= commit_text then  
      env.history = env.history .. commit_text 
      env.history = env.history:utf8_sub(-10)
      --print( env.history, ctx.input , ctx:get_commit_text() )

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


function M.func(input,seg,env)
  local context = env.engine.context
  local history= env.history

  if context:get_option(lua_tran_ns) then return end  -- false: enable true: disable
  if not seg:has_tag(lua_tran_ns)  then return end

  local active_input = input:match("^".. pattern_str .. "(.*)$")
  if active_input == nil then return end

  if active_input == "C" then
    yield( Candidate("history", seg.start, seg._end, "", "--清除 (" .. history .. ")" ))
    yield( Candidate("history", seg.start, seg._end, "", env.history_back.. "--還原" ))

  elseif active_input == "B" then
    yield( Candidate("history", seg.start, seg._end, "", env.history_back.. "--還原" ))

  elseif active_input == "H" then
    _HISTORY:each(function(elm)
      yield( Candidate("history", seg.start, seg._end, elm, "--自選" ))
    end)

  elseif active_input:match("[<>~]+") then
    if #active_input >1 then
      active_input=active_input:sub(2)
      local si= #active_input:gsub("[^>]","") +1
      local ei= - #active_input:gsub("[^<~]","")
      history = history:utf8_sub(si,ei)
    end
    yield( Candidate("history", seg.start, seg._end, "", history .. "--修改" ))
  end

  for w ,wt in env.dict:reduce_iter(history) do
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

  local pattern_p= "recognizer/patterns" 
  local config_map=config:get_map( pattern_p)
  List( config_map:keys() ):each(function(elm) 
    puts( pattern_p .. "/" .. elm .. ":\t" ..  config_map:get_value(elm).value ) 
  end )




  puts ( pattern_p .. ":\t" .. ( config:get_string(pattern_p ) or "") )
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

local function find_index(config,path,after,before)
  local index, after_i,before_i= nil,nil,nil
  for i=0,config:get_list_size(path) -1 do 
    local str= config:get_string(path .. "/@" .. i )
    after_i =  after_i or (  str:match(after) and i or nil )
    before_i = before_i or ( str:match(before) and i or nil )
  end 

  index = after_i and  after_i  or 0  -- index < echo_i
  index = before_i  and index >=before_i and before_i or index +1   -- index >= punct_i
  return index, after_i,before_i
end 
local function find_component(config,path,name)
  for i=0,config:get_list_size(path) -1 do 
    if config:get_string(path .. "/@" .. i ):match(name) then 
      return true
    end 
  end 
end 
-- add lua_translator@conjunctive between echo_translator and punct_translator
local function add_component_tran(config,name)
  name=  name or "lua_translator@" .. lua_tran_ns
  local path= "engine/translators"
  local after,before= "echo_translator","punct_translator"
  
  if not find_component(config,name) then 
    local index, after_i , before_i = find_index(config,path,after,before)
    config:set_string( path .. "/@before " .. index, name ) 
  end 
end

-- repleace uniquifier to lua_filter@uniquifier 
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

local function get_tags(config,path)
  local list=List()
  for i=0,config:get_list_size(path) -1 do
    list:push( config:get_string(path .. "/@" .. i ) )
  end
  return #list >0 and list or nil 
end

-- lua_filter@uniquifier
--[[
local F={}
function F.init(env)
  local context=env.engine.context
  local config=env.engine.schema.config
  local path= env.name_space .. "/tags"
  env.tags = get_tags(config,path )
  env.unmatch_type={history=true}
end

function F.fini(env)
end

function F.tags_match(seg,env)
  if not env.tags  then  --  
    return env.unmatch_tag and not env.reject_tags:find(function(elm) return seg:has_tag(elm) end )
  else
    return not not env.tags:find(function(elm) return seg:has_tag(elm) end )
  end
end

function F.func(tran,env)
  local uniquify_key={}
  for cand in tran:iter() do
    if env.match_type[cand.type] then
   ;   yield( cand )
    elseif  not uniquify_key[cand.text] then
      uniquify_key[cand.text]  = true
      yield(cand)
    end
  end
end
--]]
F= require 'component/uniquifier' 

-- add lua_translator@conjunctive , lua_filter@uniquifier 
--
local function components(env)
  local config=env.engine.schema.config
  
  -- set module  "conjunctive"
  _G[lua_tran_ns]= _G[lua_tran_ns] or M
  _G["uniquifier"]= F -- require 'component/uniquify'


  config:set_string("recognizer/patterns/" .. lua_tran_ns , rec_pattern) 

  -- register keybinder {when: "always",accept: switch_key, toggle: conjunctive }
  add_keybind(config, {when= "always", accept= switch_key, toggle= lua_tran_ns } )
  -- add lua_translator after echo_translator before punct_translator
  local path= "engine/translators"
  local name= "lua_translator@" .. lua_tran_ns 
  local after,before= "echo_translator","punct_translator" 
  if not find_component( config, path, name ) then 
    local index,after_i,before_i = find_index(config,path,after,before)
    config:set_string(path .. "/@before " .. index , name )
  end 
  --add_component_tran(config, "lua_translator@" .. lua_tran_ns )
  -- replease uniquifire
  replase_filter(config)
  -- print compoments
  print_config(config)
end
local P={}

function P.component(env,name)
  name = name or  "lua_processor@" .. lua_tran_ns .. "_proc"
  _G[lua_tran_ns .. "_proc"] = P 
  local config=env.engine.schema.config
  -- between  processor_init and recognizer 
  local path= "engine/processors"
  if find_component(config,path,name) then 
    return false
  else 
    local after, before = "lua_processor@processor_init", "recognizer"
    local index,after_i,before_i=find_index(config,path,after,before)
    -- insert  lua_translator  of conjunctive into translators
    local index,after_i, before_i = find_index(config,path,after,before)
    config:set_string( path .. "/@before " .. index, name )
    print_config(config)
    return true
  end 
end 

function P.init(env)
  local config= env.engine.schema.config
  env.commit_select= ("^[ %s%s%s]$"):format(
     "%<%>CBHi%~", config:get_string("menu/alternative_select_keys") or "%d", escape_key )
  components(env)
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

  local ascii=  key.modifier <=1 and key.keycode <128
  and string.char(key.keycode)
  or ""

  -- "~" 觸發聯想
  if not context:is_composing() and  ascii == "~" then
    context.input= pattern_str
    return Accepted
  end 
  -- 中斷聯想
  if  context.input:match("^" .. pattern_str) then
    if #ascii >0 and not ascii:match(env.commit_select) then 
      context:clear()
    end 
  end
  return Noop
end

return P
