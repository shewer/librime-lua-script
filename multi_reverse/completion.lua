#! /usr/bin/env lua
--
-- completion.lua
-- Copyright (C) 2021 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
-- table_translator@namespace   namespace/enable_completion: true
--

local M={}
local Completion="completion"

function M.tags_match(segment,env)
  local context=env.engine.context
  return  not context:get_option(Completion)
end

function M.init(env)
end

function M.fini(env)
end

local function func(input,env)
  for cand in input:iter() do
    if cand.type == Completion then
      break
    end
    yield(cand)
  end
end
local function old_func(input,env)
  if env.engine.context:get_option(Completion) then
    for cand in input:iter() do  yield(cand) end -- bypas
  else
    func(input, env)
  end
end

M.func = Projection and func or old_func
return M
