#! /usr/bin/env lua
--
-- tools/rime_api.lua
-- 補足 librime_lua 接口 不便性
-- Copyright (C) 2020 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
--------------------------------------------
local List = require 'tools/list'
---------------  Lua component ---------------
--
local Name = "multi_reverse"
local Multi_reverse="multi_reverse" 
local Completion ="completion"
--   keybinder function 
local function update_property(ctx,name,data)
  ctx:set_property( name , data)
  ctx:refresh_non_confirmed_composition()
end 
local function mnext(action,env)
  update_property( env.engine.context,
  	Multi_reverse, 
    env.trans_namespace:next())
end 
local function mprev(action,env)
  update_property(  env.engine.context,
	  Multi_reverse, 
	  env.trans_namespace:prev())
end 
local function mtoggle(action,env)
  update_property(  env.engine.context,
    Multi_reverse,
    env.trans_namespace:toggle())
end 
-- keybinders 
local keybinder_tab=  {
    {when= "always" ,accept= "Control+9" ,call_func=mnext},
    {when= "always" ,accept= "Control+0" ,call_func= mprev}, -- ret default Accepted
    {when= "always" ,accept= "Control+6" ,call_func= mtoggle,ret=Accepted}, -- 1 == Accepted
    {when= "always" ,accept= "Control+7" , toggle= "qcode" },
    {when= "always" ,accept= "Control+8" , toggle= Completion },
  }


local KeyBinders= require 'tools/key_binder'
return KeyBinders(keybinder_tab)
