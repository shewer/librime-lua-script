#! /usr/bin/env lua
--
-- leveldb.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
-- 
--[[
--leveldb pool 
--

--]]

local udir=rime_api.get_user_data_dir() .. "/"
local sdir=rime_api.get_shared_data_dir() .. "/"
-- return full_path
local function find_path(fn)
  local full_upath= udir .. fn
  local full_spath= sdir .. fn
  return isDir(full_upath) and full_upath
  or isDir(full_spath) and full_spath 
  or full_upath
end
-- 
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



