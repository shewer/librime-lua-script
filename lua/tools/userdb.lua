#! /usr/bin/env lua
--
-- leveldb.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
--
--support userdb pool
-- ldb = require'tools/leveldb'
-- leveldb = ldb.open(fn,dbname) -- return instance of LevelDb

require 'tools/_file'


local M = {}
M._db_pool={}
function M:pool_status()
  local tab = {}
  for k,v in next, self._db_pool do
    table.insert(tab, ("%s:%s(%s)"):format(k,v,v:loaded() and "opening" or "closed" ))
  end
  return tab
end
function M:get_db(fn)
  return self._db_pool[fn]
end

function M:Open(fn,dbname)
  local name = fn .. "." .. dbname
  if self._db_pool[name] then
    return self._db_pool[name]
  end
  if _RL_VERSION >=240 and (dbname == "userdb" or dbname == "plain_userdb") then
    self._db_pool[name] = UserDb(fn,dbname)
  elseif _RL_VERSION >=177 and (dbname == "userdb") then
    self._db_pool[name] = LevelDb(name, dbname)
  end

  local db = self._db_pool[name]
  if db then
    db:open()
    return db
  else 
    log.error("failed to open file : " .. name)
  end
end

M.UserDb= M.Open
function M:LevelDb(fn) return self:Open(fn,"userdb") end 
function M:TableDb(fn) return self:Open(fn, "plain_userdb") end 

-- M:Open(fn,dbname) -- return db   ver>= 177
-- M:UserDb(fn, dbname) -- same as Open
-- M:LevelDb(fn) -- >= 177
-- M:TableDb(fn) -- >= 240
-- M:pool_status() -- return status of table
-- M:get_db(fn) -- return db or nil
return M
