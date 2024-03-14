#! /usr/bin/env lua
--
-- segm.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--

local COM = require 'english/common'
local English="english"
local S={}
function S.init(env)
   local config = env.engine.schema.config
   env.tag = config:get_string(env.name_space .. "/tag")  or "english"
   --env.affix_seg= Composegment.Segmentor(env.engine,"", "affix_segmentor@english")
end
function S.fini(env)
end

function S.func(segs ,env) -- segmetation:Segmentation,env_
   local context=env.engine.context
   if not context:is_composing() then return true end
   if T06 and GD then GD() end
   if context:get_option(English) then
      --puts("log", __LINE__() ,"-----trace-----sgement" , str ,context.input )
      if not  segs.input:match("^%a[%a'?*/:_,.%-]*$") then  return true  end
      
      local sp, ep = segs:get_current_start_position(),segs:get_current_end_position()
      ep = ep > context.caret_pos and ep or context.caret_pos
      local seg=Segment(sp, ep)
      seg.tags= Set({English})
      seg.prompt="(english)"
      segs:add_segment(seg)

      return false
   else
      return true
   end
   
   -- 不是 chk_english_mode  pass 此 segmentor  由後面處理
   return true
end


return S
