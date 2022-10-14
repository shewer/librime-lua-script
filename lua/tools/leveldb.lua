#! /usr/bin/env lua
--
-- leveldb.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
--
--support leveldb pool
-- ldb = require'tools/leveldb'
-- leveldb = ldb.open(fn,dbname) -- return instance of LevelDb

require 'tools/_file'

local function find_path(fn)
  local full_path = get_full_path(fn)
  return full_path and isDir(full_path) and full_path or rime_api.get_user_data_dir() .. "/" .. fn
end

function opendb(fn,dbname)
  local filename = find_path(fn)
  local db=LevelDb(filename,dbname or "") or nil
  if db and not db:loaded() then
    db:open()
  end
  return db
end

local M = {}
M._db_pool={}

function M.open(fn,dbname)
  if not M._db_pool[fn] then
    M._db_pool[fn] = opendb(fn,dbname) or nil
  end
  return M._db_pool[fn]
end

function M.pool_status()
  local tab = {}
  for k,v in next,M._db_pool do
    table.insert(tab, ("%s:%s(%s)"):format(k,v,v:loaded() and "opening" or "closed" ))
  end
  return tab
end
-- M.open(fn,dbname) -- return db
-- M.pool_status() -- return status of table
return M



