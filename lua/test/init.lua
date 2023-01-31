#! /usr/bin/env lua
--
-- init.lua
-- Copyright (C) 2021 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
--os.exit(lu.LuaUnit.run('-q'))
--

local Helper=require 'test/helper'
--[[
測試檔案 files from ./test/**/*_test.lua
可以使用 # remark test

lua/test/*_test.lua -- pure lua test
lua/global/*_test.lua -- librime-lua test
lua/proc/*_[func_name]_test.lua -- lua_processor [init,fini,func] test
lua/segm/*_[func_name]_test.lua -- lua_segmentor [init,fini,func] test
lua/tran/*_[func_name]_test.lua -- lua_translator [init,fini,func] test
lua/filter/*_[func_name]_test.lua -- lua_filter [init,fini,tags,func] test

--]]



local S={}
function S.init(env)
  local path,func_name='segm','init'
  local var={
    env=env,
  }
  Helper:test(path,func_name,setmetatable(var,{__index=_ENV}),format, _exit )
end
function S.fini(env)
  local path,func_name='segm','fini'
  local var={
    env=env,
  }
  Helper:test(path,func_name,setmetatable(var,{__index=_ENV}),format, _exit )
end
function S.func(segs,env)
  local path,func_name='segm','func'
  local var={
    env=env,
    segs=segs
  }
  Helper:test(path,func_name,setmetatable(var,{__index=_ENV}),format, _exit )
  return true
end
local T={}
function T.init(env)
  local path,func_name='tran','init'
  local var={
    env=env,
  }
  Helper:test(path,func_name,setmetatable(var,{__index=_ENV}),format, _exit )
end
function T.fini(env)
  local path,func_name='tran','fini'
  local var={
    env=env,
  }
  Helper:test(path,func_name,setmetatable(var,{__index=_ENV}),format, _exit )
end
function T.func(input,seg,env)
  local path,func_name='tran','func'
  local var={
    env=env,
    input=input,
    seg=seg,
  }
  Helper:test(path,func_name,setmetatable(var,{__index=_ENV}),format, _exit )
end
local F={}
function F.init(env)
  local path,func_name='filter','init'
  local var={
    env=env,
  }
  Helper:test(path,func_name,setmetatable(var,{__index=_ENV}),format, _exit )
end
function F.fini(env)
  local path,func_name='filter','fini'
  local var={
    env=env,
  }
  Helper:test(path,func_name,setmetatable(var,{__index=_ENV}),format, _exit )
end
function F.tags_match(seg,env)
  local path,func_name='filter','tags'
  local var={
    env=env,
    seg=seg,
  }
  Helper:test(path,func_name,setmetatable(var,{__index=_ENV}),format, _exit )
  return true
end
function F.func(inp,env)
  local path,func_name='filter','func'
  local var={
    env=env,
    inp=inp,
    cands=cands,
  }
  Helper:test(path,func_name,setmetatable(var,{__index=_ENV}),format, _exit )
end
luatest_seg = S
luatest_tran= T
luatest_filter = F

local function init_comp(env)
  local config=env.engine.schema.config
  config:set_string("engine/segmentors/@0","abc_segmentor")
  config:set_string("engine/segmentors/@1","lua_segmentor@luatest_seg")
  config:set_string("engine/translators/@0","table_translator")
  config:set_string("engine/translators/@1","lua_translator@luatest_tran")
  config:set_string("engine/filters/@0","lua_filter@luatest_filter")
end

local function dofiles(path, func_name)
  local tab=Helper.get_filename(path, func_name)
  for i,v in next, tab do
     v[2] = dofile(v[2])
   end
  return tab
end
local P={}
local format,_exit= 'tap',nil
function P.init(env)
  print(rime_api.Ver_info())
  init_comp(env)
  local path,func_name='proc','init'
  local var={
    env=env,
  }
  local res=Helper:test(path,func_name,setmetatable(var,{__index=_ENV}),format, _exit )
end

function P.fini(env)
  local path,func_name='proc','fini'
  local var={
    env=env,
  }
  Helper:test(path,func_name,setmetatable(var,{__index=_ENV}),format, _exit )
end

function P.func(key,env)
  local path,func_name='proc','func'
  local var={
    env=env,
    key=key,
  }
  Helper:test(path,func_name,setmetatable(var,{__index=_ENV}),format, _exit )

  return 2
end
local format = 'tap' -- 'tap' 'text'
local _exit = nil  -- bool
Helper:reset()
Helper:test('global','',_ENV,format,_exti)
Helper:test('','',_ENV,format, _exit)
return P
