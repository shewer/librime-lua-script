#! /usr/bin/env lua
--
-- _rescue.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
local M={}
local E={}

--
function E:set(env,comp)
  local id= env.engine.schema.schema_id
  self[id] = self[id] or {}
  if not self[id][comp] then
    self[id][comp ]=true
    env.engine.context:set_property("_error",self:get(env))
  end
end
function E:get(env)
  local id= env.engine.schema.schema_id
  local tab={}
  for k,v in next , self[id] or {} do
    table.insert(tab,  k  )
  end
  return table.concat( tab ,",")
end

function M.proc(key,env)
  E:set(env,"P@" .. env.name_space)
  return 2 -- Noop
end

function M.segm(seg,env)
  E:set(env,"S@" .. env.name_space)
  return true
end

function M.tran(input,seg,env)
  E:set(env,"T@" .. env.name_space)
  yield(Candidate("LuaError",seg.start,seg._end, "", "Err:" .. E:get(env) ))
end

function M.filter(input, env)
  E:set(env,"F@" .. env.name_space)
  for cand in input:iter() do
    --if not cand.comment:match("- Err:") then
      --cand.comment = cand.comment .. "- Err:" .. E:get(env)
    --end
    yield(cand)
  end
end

-- rrequire('_rescue')  return _ENV['_rescue.proc'], _ENV.....
-- rrequier('_rescue',_ENV,'Rescue') return _ENV['Rescue.proc']

M.lua_processor=M.proc
M.lua_segmentor=M.segm
M.lua_translator=M.tran
M.lua_filter=M.filter
M._modules=true
return M
--Rescue_processor=M.proc
--Rescue_segmentor=M.segm
--Rescue_translator=M.tran
--Rescue_filter=M.filter
--return Rescue
