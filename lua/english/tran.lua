

local COM = require 'english/common'
local Env= require 'tools/env_api'
local List= require 'tools/list'
local Word= require 'english/word'
local slash = package.path:sub(1,1)


local English="english"
local Ninja="ninja"

local T={}

-- ext_dict
local function load_ext_dict(ext_dict)
   --local path= string.gsub(debug.getinfo(1).source,"^@(.+/)[^/]+$", "%1")
   if T._ext_dict then
      return T._ext_dict
   end
   local path= ("%s/lua/english/%s.txt")
      :format(rime_api.get_user_data_dir(),ext_dict)
      :gsub("/", COM.NR)
   if not isFile(filename) then return end

   local dict  = {}
   for line in io.open(filename):lines() do
      if not line:match("^#") then  -- 第一字 #  不納入字典
	 local t=line:split("\t")
	 if t then
	    local key = t[1]:lower()
	    local word = EngLish_dict.Word{word=t[1], translation= t[2], definition = t[3] }
	    dict[key] = word
	 end
      end
   end
   return dict
end


-- 流行語 簡語字典
T._njdict = require 'english/wordninja' 

function T.init(env)
   local config = env.engine.schema.config
   local context = env.engine.context
   env.tag= config:get_string(env.name_space .. "/tag") or COM.tag
   env.quality = config:get_double(env.name_space .. "/quality") or 1
   local mode = config:get_int(env.name_space .. "/comment_mode_default")
      or COM.comment_mode_default
   context:set_property(COM.property_name,mode)
   --[[
      if config:get_bool(env.name_space .. "/enable_njdict") or COM.enable_ninja then
      T._njidct = T._njdict or require "english/wordninja"
      env.njdict = T._njdict
      end
      if config:get_bool(env.name_space .. "/enable_ext_dict") or COM.enable_ext_dict then
      local ext_file = config:get_string(env.name_space .. "/ext_dict") or COM.ext_dict
      T._ext_dict = T._ext_dict or load_ext_dict(ext_file)
      env.ext_dict = T._ext_dict
      end
   ]]
   if config:get_bool(env.name_space .."/enable_njdict") or COM.enable_njdict then
      T._njdict = T._njdict or require("english/wordninja")
   end
   local ext_dict_name = config:get_bool(env.name_space .. "/ext_dict") or COM.ext_dict 
   if ext_dict_name then
      T._ext_dict = T._ext_dict or load_ext_dict(ext_dict_name)
   end
   local dict_name = config:get_string(env.name_space .. "/dictionary") or "ecdict"
   env.dict = assert( rime_api.UserDb.LevelDb(dict_name), "can not Create english dict of " .. dict_name)
   env.njdict = T._njdict
   env.ext_dict = T._ext_dict

end
function T.fini(env)
end

-- 大寫轉換 ex:  Axxxxx Axxxxx  , AAxxx AAXXX
local function sync_case(cand, raw_inp)
   if raw_inp:match("^%u") then
      if raw_inp:match("^%u%u") then
	 cand.text = cand.text:upper()
      else
	 cand.text:gsub("^%l",string.upper)
      end
   end
   return cand
end

-- 處理 英文翻譯長度及格式化 (windows  \n ->\r utf8_len 40)
local function comment_format(cand,len)
   len = len or 40
   cand.comment = cand.comment:utf8_sub(1,len)
   if COM.win_os then
      cand.comment= cand.comment:gsb("\n", COM.NR)
   end
   return cand
end


local function tr_cand(translation,raw_inp)
   if not translation then return end
   for cand in translation:iter() do
      sync_case(cand,raw_inp)
      yield( COM.unix_os and cand or comment_format(cand) )
   end
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

local function tran_(inp, seg, dict)
   local prefix, pattern, pn = split_text(inp)
   return Translation(function()
	 for k,v in dict:query( prefix:lower() ):iter() do
	    local w = Word.Parse_chunk(v)
	    if w.word:match(pattern) then
	       yield(Candidate('english',seg._start, seg._end, w.word, w:get_info()))
	    end
	 end
   end)
end

function T.func(inp, seg, env)
   if not seg:has_tag(env.tag) then return end
--   if T05 and GD then GD() end
   local tran = Translation(T.order_func, inp, seg, env)
   tran = Translation(tr_cand, tran, inp)
   for cand in tran:iter() do
      yield(cand)
   end
end


function T.order_func(inp,seg,env)
   -- check inp format
   if not ( seg:has_tag(env.tag) ) then
      return
   end
   local context = env.engine.context
   local cands = List()
   local comment_mode = context:get_property(COM.property_name)

   local translation_next,tran = env.dict:query(inp, seg._start, seg._end, comment_mode,env.quality):iter() 
 
   --njcand
   local nj_commit= env.njdict and inp:match("^[%a%.%']+$")  and env.njdict:split(inp)
   local nj_cand = nj_commit and  nj_commit ~= inp and
      Candidate("ninja", seg._start, seg._end, nj_commit, "[ninja]")
   if nj_cand then
      local ww=env.dict:word(nj_cand.text)
      if ww then
	 nj_cand.comment = nj_cand.comment .. " " .. ww.translation
      end
   end
   

-- ext_cand
   local ext_cand  = env.ext_dict and env.ext_dict[inp:lower()]
      and env.ext_dict[inp:lower()]:to_cand(1, seg._start, seg._end)
   cands:push(ext_cand)
   cands:push(translation_next(tran))
   if #cands == 0 then
      cands[1] = Candidate('raw', seg._start, seg._end, inp, "RAW")
   end
   if nj_cand then
      cands:insert_at(2, nj_cand)
   end
   cands:each(yield)
   for cand in translation_next,tran do
      yield(cand)
   end
   
  -- 使用 ninja 最後一佪字查字典 type "ninja"
  --local n_word= commit[#commit]
  --[[
  local n_word = njcand.text:match("%s(%a+)$")
  if not n_word then return end
  local snjcand= Candidate("sub_ninja",njcand._end - #n_word,njcand._end, n_word,"[sninja]")
  yield(snjcand)
  for cand in env.dict:query(inp, seg._start, seg._end, comment_mode):iter() do
     cand.type = "sub_ninja"
     if quality then
	cand.quality=quality
	yield(cand)
     end
  end
--]]
end

return T
