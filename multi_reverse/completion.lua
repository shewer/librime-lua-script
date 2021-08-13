#! /usr/bin/env lua
--
-- completion.lua
-- Copyright (C) 2021 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--

local M={}
local Completion="completion"
function M.tags_match(segment,env)
  local context=env.engine.context
  return  context:get_option(Completion)
end

function M.init(env)
end
function M.fini(env)
end
function M.func(input,env)
  for cand in input:iter() do 
    if cand.type == Completion then 
      break
    end 
    yield(cand)
  end
end 


return M
