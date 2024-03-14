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
-- add Component.Require

function Component.Require(...)
  local t = Ticket(...)
  local gmod_name = get_comp_name(Ticket(...).klass)
  return Component[ gmod_name ](...)
end

return Component
