#!/usr/bin/env lua
--
-- filter.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
local Env= require 'tools/env_api'
local List = require 'tools/list'
local Dict= require 'tools/dict'
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

local F={}
function F.init(env)
  Env(env)
  local files = env:Config_get(env.name_space .. "/files")
  local files = type(files) == "table" and files or {"essay.txt","essay_cn.txt"}
  env.dict= load_dict( files[1] )
  env.preedit= "[聯]"
  env.max=8
  env.weight=100
end
function F.fini(env)
end
function F.tags_match(seg,env)
  return env.engine.context:get_option(env.name_space)
end
function F.func(input,env)
  local context= env.engine.context
  local history=context:get_property(env.name_space)
  local list=List()
  local comp_cand
  for cand in input:iter() do
    if cand.type == "completion" then
      comp_cand= cand
      break
    end
    if cand.type ~= "history" and #cand.text > 0 then list:push(cand) end
    yield(cand)
  end
  -- conjunctive filter
  list:each(function(elm)
    local count = 0
    for w,wt in env.dict:reduce_iter( history .. elm.text ) do
      count = count +1
      if wt >= env.weight and count < env.max then -- weight
        local cand= Candidate( "history" , elm.start,elm._end, elm.text .. w, env.preedit )
        if cand then
          cand.preedit=elm.text .. w .. env.preedit
          yield(cand)
        end
      end
    end
  end)
  -- campletion cand
  if comp_cand then yield(comp_cand) end
  for ccand in input:iter() do
    yield(ccand)
  end


end
return F
