#! /usr/bin/env lua
--
-- _component.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.

-- ver <#177 : 只能建立 lua_component
-- 增加 Component.Require(...) 以 component_name 自動區別 processor segmentor translator filter
--

local processors= Set{
 "lua_processor",
"ascii_composer",
"chord_composer",
"express_editor",
"fluid_editor",
"fluency_editor",
"key_binder",
"navigator",
"punctuator",
"recognizer",
"selector",
"speller",
"shape_processor"
 }
local segmentors= Set{
"lua_segmentor",
"abc_segmentor",
"affix_segmentor",
"ascii_segmentor",
"matcher",
"punct_segmentor",
"fallback_segmentor"
}
local translators= Set{
"lua_translator",
"echo_translator",
"punct_translator",
"table_translator",
"script_translator",
"schema_list_translator",
"switch_translator",
"history_translator",
"codepoint_translator",
"trivial_translator"
}
local filters=Set{
"lua_filter",
"simplifier",
"uniquifier",
"charset_filter",
"cjk_minifier",
"reverse_lookup_filter",
"single_char_filter",
"charset_filter"
}

local group_components={
  Processor = processors,
  Segmentor = segmentors,
  Translator  = translators,
  Filter = filters,
}
-- return string : 'Processor' 'Segmentor' ...
local function get_comp_name(comp_name)
  for group_name, group_mods in next, group_components do
    if group_mods[comp_name] then
      return group_name
    end
  end
end

-- ver > 176 Component  add Require
-- ver <= 176 Fake Component
if not LevelDb or not Component then
  print(' fake component wrap- require')
  Component = require 'tools._luacomponent'
end

local function _delegate_func(comp_tab)
  --clone tab
  local m ={}
  for k,v in next, comp_tab do
    m[k] = v
  end
  for k,v in next,m do
    -- add  component to  _component ...
    comp_tab["_"..k]= m[k]
    --  replace and delegate
    comp_tab[k]= function(...)
      local t = Ticket(...)
      if t and t.klass:match("^lua_") then
        rrequire( t.name_space:split("@")[1])
      end
      return comp_tab["_"..k](...)
    end
  end
end
-- add Component.Require
_delegate_func(Component)
function Component.Require(...)
  local t = Ticket(...)
  local gmod_name = get_comp_name(Ticket(...).klass)
  return Component[ gmod_name ](...)
end

return Compoment
