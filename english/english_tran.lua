local puts=require 'tools/debugtool'
local nj=require 'tools/wordninja'
local English= require 'tools/english_dict'
local eng_dict=English("english_tw.txt")
nj.init()
nj.test()
local T={}
function T.init(env)
  env.notifier= env.engine.context.commit_notifier:connect(
  function(ctx)
    if ctx:get_option("english") then 
      ctx:set_option("english",false)
    end 
  end)
end
function T.fini(env)
  env.notifier:disconnect()

end
function T.func(inp,seg,env)
  local context=env.engine.context
  local input =  seg:has_tag("lua_cmd") and inp:sub(2) or inp:sub(seg.start,seg._end)
  input = input:match("^[%a][%a%_%-%.%'/*:]*$") and input or ""
  if #input==0 then return end 

  puts("trace",__FILE__(),__FUNC__(),__LINE__() )
  local commit= input:match("^[%a%_%.%']+$")  and nj.split(input) or {}
  local first=Candidate("english", seg.start, seg._end, input , "[english]")
  yield(first)
  if #commit > 1 then 
    yield( Candidate("english",seg.start,seg._end, table.concat(commit," "), "[ninja]"))
  end 
  for w in eng_dict:iter(inp:sub(seg.start,seg._end)) do
    if input ==w.word then 
      first.comment= w.info
    else 
      yield( Candidate("english",seg.start,seg._end,w.word,w.info))
    end 
  end
  if #commit > 1 then 
    for w in eng_dict:iter(commit[#commit]) do
      yield( Candidate("english",seg.start,seg._end,w.word,"(Ninja) " .. w.info))
    end
  end 
end


return T
