#! /usr/bin/env lua
--
-- memory_tran.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--

local Env = require 'tools/env_api'
local List = require 'tools/list'

local function memoryCallback(memory,commit)
  for i, dictentry in ipairs(commit:get()) do
    memory:update_userdict(dictentry,1,"")
  end
end
local M = {}


function M.init(env)
  Env(env)
  env.mem = Memory(env.engine,env.engine.schema,env.name_space)
  env.mem:memorize(function(commit) memoryCallback(env.mem, commit) end)
  env.tag=env:Get_tag('abc')
  env.quality = tonumber(env:Config_get(env.name_space .. "/quality") ) or 0
  
end

function M.fini(env)
end

function M.func(inp,seg,env)
  if not seg:has_tag( env.tag ) then return end
  local active_inp = inp:sub(seg.start +1 , seg._end)
  --if T03 and GD then GD() end
  env.mem:dict_lookup(active_inp,true, 100)
  for dictentry in env.mem:iter_dict() do
    local code = env.mem:decode(dictentry.code)
    local codeComment = table.concat(code, ", ")
    local ph = Phrase(env.mem, "expand_translator", seg.start, seg._end, dictentry)
    local cand = ph:toCandidate()
    cand.Comment =codeComment .. " memory"
    cand.quality = cand.quality  + env.quality
    cand.type = "exp"
  --if T03 and GD then GD() end
    yield(cand)
  end
end
return M
