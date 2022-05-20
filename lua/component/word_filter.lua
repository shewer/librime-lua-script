-- <user_data_dir>/lua/word.lua

local M={}

function M.init(env)
  local config=env.engine.schema.config
  -- default translator
    env.finals= config:get_string("speller/finals")
end
function M.fini(env)
end
-- enable func
local function func(input,env)
  local context= env.engine.context
  local tab={}
  for cand in input:iter() do
    local completion = cand.type == "completion"
    if not completion and utf8.len(cand.text) > 1 then
      yield(cand)
    else
      table.insert(tab,cand)
      if completion then break end
    end
  end
  for _,cand in next, tab do
    yield(cand)
  end
  for cand in input:iter() do
    yield(cand)
  end
end
function M.func(input,env)
  local context= env.engine.context
  if  context.input:sub(-1) ~= env.finals then
    -- bypass translation
    for cand in input:iter() do
      yield(cand)
    end
  else
    func(input,env)
  end
end

return M

