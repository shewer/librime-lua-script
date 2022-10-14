#! /usr/bin/env lua
--
-- rime.api.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--

print('----------------->>>',rime_api)
if  rime_api  then return end

local _user_data_dir="."
local _shared_data_dir="."


_G['rime_api'] = {}
print('----------------->>>',rime_api)
function rime_api.get_user_data_dir()
  return _user_data_dir
end
function rime_api.get_shared_data_dir()
  return _shared_data_dir
end
