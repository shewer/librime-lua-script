local Log=require 'tools/debugtool'

local English_dict= require 'tools/english_dict'


local function njload()
  -- try to load wordninja-lua
  -- https://github.com/BlindingDark/wordninja-rs-lua
  -- rime.lua append
  -- cp wordninja.so  <user_data_dir>/lua/plugin
  --
  -- window lua 版本不符將造成暫時取消 window版本 載入 wordnanja-rs
  local nj = require 'tools/wordninja'
  return nj
end

local English="english"
local Ninja="ninja"

local function load_ext_dict(ext_dict)
  local path= string.gsub(debug.getinfo(1).source,"^@(.+/)[^/]+$", "%1")
  filename =  path ..  ( ext_dict or "ext_dict" ) .. ".txt"
  local tab = {}
  for line in io.open(filename):lines() do
    if not line:match("^#") then  -- 第一字 #  不納入字典
      local t=line:split("\t")
      if t then
        tab[t[1]] = t[2]
      end
    end
  end
  return tab
end

local T={}
T._nj= T._nj or njload()
T._ext_dict= T._ext_dict or load_ext_dict("ext_dict")

function T.init(env)
  Env(env)
  local config= env.engine.schema.config
  env.tag= config:get_string(env.name_space .. "/tag") or English
  local dict_name= config:get_string(env.name_space .. "/dictionary") or "english_tw"
  env.gsub_fmt =  package.config:sub(1,1) == "/" and "\n" or "\r"
  env.dict = assert( English_dict(dict_name), 'can not Create english dict of ' .. dict_name)

  env.notifiers=List(
  env.engine.context.option_update_notifier:connect(
  function(ctx,name)
    if name=="english_info_mode" then
      env.mode= env.mode and (env.mode+1) or 0
    end
  end) )
end
function T.fini(env)
  env.notifiers:each(function(elm) elm:disconnect() end)
end

-- 大寫轉換 ex:  Axxxxx Axxxxx  , AAxxx AAXXX
local function sync_case(input, candidate_word)
  if input:match("^%u%u") then
    return candidate_word:upper()
  elseif input:match("^%u") then
    return candidate_word:gsub("^%a",string.upper)
  else
    return candidate_word
  end
end

-- 處理 英文翻譯長度及格式化 (windows  \n ->\r utf8_len 40)
local function system_format(comment)
  local unix = package.config:sub(1,1) == "/"
  if not unix then
    comment = comment:utf8_sub(1,40):gsub("\n","\r")
  else
  end
  return comment
end


-- return Translation
local function eng_tran(dict,mode,prefix_comment,cand)

  return Translation(function()
    -- 使用 context.input 杳字典 type "english"
    local inp = cand.text
    for w in dict:iter(inp) do
      -- system_format 處理 comment 字串長度 格式
      local comment = system_format(  prefix_comment..w:get_info(mode) )
      local commit = sync_case(inp,w.word)
      -- 如果 與 字典相同 替換 first_cand cand.comment
      if cand.text:lower() == commit:lower() then
        cand.comment= comment
      else
        yield( ShadowCandidate(cand,cand.type,commit,comment) )
      end
    end
  end)
end

function T.func(inp,seg,env)
  if not ( seg:has_tag(env.tag) or env:Get_option(English) )  then return end

  local input = inp:sub(seg.start+1,seg._end)
  input = input:match("^[%a][%a_.'/*:%-]*$") and input or ""
  if #input==0 then return end

  -- first_cand
  local first_comment = T.ext_dict and T._ext_dict[input:lower()]
  first_comment = first_comment and ' abbr. ('.. first_comment..')' or '[English]'
  local first_cand = assert( Candidate(English,seg.start,seg._end,input,first_comment ))
  yield(first_cand)

  -- njcand
  local nj_commit= input:match("^[%a%_%.%']+$")  and T._nj and T._nj.split(input)
  local njcand = nj_commit and Candidate(Ninja, seg.start,seg._end, nj_commit, "[ninja]")
  if njcand  then yield(njcand) end


  -- 使用 context.input 杳字典 type "english"
  for cand in eng_tran(env.dict,env.mode,"",first_cand):iter() do
    yield(cand)
  end

  -- ecdict 字典支援子句
  -- 使用ninja cand 展開字句查字典
  for cand in eng_tran(env.dict,env.mode,"(Ninja) ",njcand):iter() do
    yield(cand)
  end

  -- 使用 ninja 最後一佪字查字典 type "ninja"
  --local n_word= commit[#commit]
  if not njcand then return end
  local n_word = njcand.text:match("%s(%a+)$")
  if not n_word then return end
  local snjcand= Candidate("sub_ninja",njcand._end - #n_word,njcand._end, n_word,"")
  yield(snjcand)
  for cand in eng_tran(env.dict,env.mode,"(Ninja) ",snjcand):iter() do
     yield(cand)
  end

end


return T
