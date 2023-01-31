#! /usr/bin/env lua
--
-- config_test.lua
-- Copyright (C) 2023 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--


local lu = require 'test/luaunit'
local err_fmt="%s:%s %s"
local M = {}

-- Config(type, filename)
--    type:'config'  [user_dir|shared]/build/[filename].yaml
--    type:'user_config'  [user_dir|shared]/[filename].yaml
--    type:'schema'  [user_dir|shared]/build/[filename].schema.yaml
--    type:'config_builder'  [user_dir|shared]/build/[filename].yaml and patch custom.yaml
--
function M:test_init()
  local c1=Config('user_config','cangjie5.schema') --[shard_dir|user_dir]/cangjie5.yaml
  local c2=Config('user_config','cangjie5.custom') --[shard_dir|user_dir]/cangjie5.yaml
  local c3=Config('config','cangjie5.schema') -- [shard_dir|user_dir]/build/cangjie5.yaml
  local c4=Config('schema','cangjie5') --[shard_dir|user_dir]/build/cangjie5.schema.yaml
  local c5=Config('config_builder','cangjie5.schema') -- [shard_dir|user_dir]/build/cangjie5.schema.yaml and patch form custom.yaml
  lu.assertIsUserdata(c1)
  lu.assertIsUserdata(c2)
  lu.assertIsUserdata(c3)
  lu.assertIsUserdata(c4)
  lu.assertIsUserdata(c5)

end

return M
