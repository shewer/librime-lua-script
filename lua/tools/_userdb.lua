#! /usr/bin/env lua
--
-- userdb.lua
-- Copyright (C) 2024 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
--[[
example:
local userdb = require 'userdb'
local ldb=userdb.LevelDb('ecdict')
ldb:open()
for k,v in ldb:query('a'):iter() do print(k,v) end

--]]
local db_pool_ = {}
local methods = {
  update = true,
  open_read_only = true,
  query = true,
  disable = true,
  open = true,
  enable = true,
  close = true,
  loaded = true,
  erase = true,
  fetch = true,
}
local vars_get= {
  _loaded=true,
  read_only=true,
  disabled=true,
  name=true,
  file_name=true,
  }
local vars_set= {}
local userdb_mt = {}
userdb_mt._db_pool = {}
function userdb_mt.__newindex(tab,key,value)
  local db = userdb_mt._db_pool[tab._db_key]
  if vars_set[key] and db then
    db[key]= value
  end
end
  
function userdb_mt.__index(tab,key)
  local db = userdb_mt._db_pool[tab._db_key]
  if not db then return end
  if vars_get[key] then
    return db[key]
  elseif methods[key] then
    return function (tab, ...)
      return db[key](db,...)
    end
  else
     return userdb_mt[key]
  end
end

function userdb_mt:has_db()
   return getmetatable(self)._db_pool[self._db_key] and true or false
end


local userdb= {}

function userdb.UserDb(db_name, db_class)
  local db_key = db_name .. "." .. db_class
  print('-tract------------>', db_key, userdb_mt._db_pool, userdb_mt._db_pool[db_key])
  if not userdb_mt._db_pool[db_key] then
     userdb_mt._db_pool[db_key] = UserDb(db_name, db_class)
     print( 'trace -------->' ,userdb_mt._db_pool[db_key] )
  end
  return setmetatable({
    _db_key = db_key,
    _db_name= db_name,
    _db_class = db_class,
  }, userdb_mt)
end

function userdb.LevelDb(db_name)
  return userdb.UserDb(db_name, "userdb")
end
function userdb.TableDb(db_name)
  return userdb.UserDb(db_name, "plain_userdb")
end
  
return userdb
