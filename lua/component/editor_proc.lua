#! /usr/bin/env lua
--
-- editor_proc.lua
-- Copyright (C) 2023 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
-- librime-lua version >=177
--   replase editor lua_processor@editor_proc@[express_editor|fluid_editor|chor_composer]
-- librime-lua version < 177
--   insert lua_processor@editor_proc@[express_editor|fluid_editor|chor_composer] before editor
--
-- install
--
-- ex1: >= 177
-- <schema>.custom.yaml
-- patch:
--   engine/processors/@8: lua_processor@editor_proc@express_editor # replace @8 express_editor
-- ex2: < 177
-- patch:
--   engine/processors/@before 8: lua_processor@editor_proc@express_editor # insert @before 8 express_editor

local function load_editor_keybind(env)
  local config = env.engine.schema.config
  local ed_map = config:get_map('editor/bindings')
  env.keybind={}
  for _,key in ipairs(ed_map and ed_map:keys() or {}) do
    local ncmd= ed_map:get_value(key).value
    print( 'command:',ncmd, 'key_bind: ', key)
    env.keybind[ncmd] = KeyEvent(key)
  end
end
local function init(env)
  if Component then
    env.editor= Component.Processor(env.engine,"processor", env.name_space)
    env.enable = true
  end
  -- check and insert remove_filter component
  local config = env.engine.schema.config
  local clist = config:get_list("engine/filters")
  local cvalue = ConfigValue("lua_filter@remove_filter")
  local fmatch= false
  for i= 0,clist.size-1 do
    fmatch =  clist:get_value_at(i).value:match(cvalue.value) and true or false
    if fmatch then break end
  end
  if not fmatch then
    clist:insert(0,cvalue.element)
  end
  -- load remove_filter module
  local mfilter= 'remove_filter'
  if not _ENV[mfilter] then
    _ENV[mfilter]= require( mfilter)
  end

end

local P={}
local n_name='delete_candidate'
function P.init(env)
  init(env)
  load_editor_keybind(env)
  local dckey=env.keybind[n_name]
  env.keybind[n_name]= dckey and dckey or KeyEvent("Control+Delete")

  if GD and T03 then GD() end

  assert(env.keybind[n_name])
  assert(_ENV['remove_filter'])
  assert(env.editor)
end
function P.fini(env)
end

function P.func(key,env)
  local Rejected, Accepted, Noop = 0,1,2
  local context= env.engine.context
  if context:has_menu() and env.enable then
    if key:eq(env.keybind[n_name]) then
      local cand= context:get_selected_candidate()
      if cand.type ~= "usertable" and cand.type ~= "userpharse" then
        context:set_property(n_name, cand.text)
        context:refresh_non_confirmed_composition()
        return Accepted
      end
    end
  end
  return env.editor and env.editor:process_key_event(key) or Noop
end


return P
