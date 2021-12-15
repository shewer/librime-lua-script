local puts=require 'tools/debugtool'
local nj=require 'tools/wordninja'
local English_dict= require 'tools/english_dict'
local eng_dict=English_dict("english_tw.txt")
local English="english"
local Ninja="ninja"
nj.init()
nj.test()
local T={}
function T.init(env)
end
function T.fini(env)

end
function T.func(inp,seg,env)
  local context=env.engine.context
  local input =  seg:has_tag("lua_cmd") and inp:sub(2) or inp:sub(seg.start,seg._end)

  input = input:match("^[%a][%a_.'/*:%-]*$") and input or ""
  if #input==0 then return end

  --puts("trace",__FILE__(),__FUNC__(),__LINE__(),"----english-----", input  )
  local commit= input:match("^[%a%_%.%']+$")  and nj.split(input) or {}
  local first=Candidate(English, seg.start, seg._end, input , "[english]")
  yield(first)
  if #commit > 1 then
    yield( Candidate(Ninja, seg.start,seg._end, table.concat(commit," "), "[ninja]"))
  end
  -- 使用 context.input 杳字典 type "english"
  for w in eng_dict:iter(inp:sub(seg.start,seg._end)) do
    if input ==w.word then
      first.comment= w.info
    else
      yield( Candidate(English,seg.start,seg._end,w.word,w.info))
    end
  end
  -- 使用 ninja 最後一佪字查字典 type "ninja"
  if #commit > 1 then
    local n_word= commit[#commit]

    for w in eng_dict:iter(n_word) do
      -- seg.start =   seg.end - #m_word
      yield( Candidate(Ninja, seg._end - #n_word , seg._end,w.word,"(Ninja) " .. w.info))
    end
  end
end


return T
