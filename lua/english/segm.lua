#! /usr/bin/env lua
--
-- segm.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--


local English="english"
local S={}
function S.func(segs ,env) -- segmetation:Segmentation,env_
  local context=env.engine.context
  local cartpos= segs:get_current_start_position()

  -- 在chk_english_mode() 為 input 打上 english tag
  --if chk_english_mode(env) and context:is_composing() then
  local str = segs.input:sub(cartpos)
  if not  str:match("^%a[%a'?*/:_,.%-]*$") then  return true  end
  if context:get_option(English) and context:is_composing() then
    --puts("log", __LINE__() ,"-----trace-----sgement" , str ,context.input )

    local str= segs.input:sub(segs:get_current_start_position() )
    local seg=Segment(cartpos,segs.input:len())
    seg.tags=  Set({English})
    seg.prompt="(english)"
    segs:add_segment(seg)

    -- 終止 後面 segmentor   打tag
    return false
  end
  -- 不是 chk_english_mode  pass 此 segmentor  由後面處理
  return true
end

function S.init(env)
end
function S.fini(env)
end

return S
