#! /usr/bin/env lua
--
-- _global.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
-- add Log __FILE__ __LINE__ isFile isDir
require 'tools/debugtool'
-- bind  split  utf8_sub utf8_sub utf8_split
-- append string.methods   split utf8_len utf8_split
require 'tools/string'
require 'tools/_ticket'
require 'tools/_shadowcandidate'
require 'tools/rime_api'
-- append utf8.methods utf8.split
function require_if(path)
  if package.loaded[ path ] then
    return package.loaded[path]
  else
    return require(path)
  end
end

--append_path(...)  paths   + "/?.lua" paths + /?/init.lua
function append_path(...)
  local slash = package.config:sub(1,1)
  local paths = package.path:split(";")
  local res =false
  for i,vs in next, {...} do
    local path1 = ("%s/?.lua"):format(vs):gsub("/",slash)
    local path2 = ("%s/?/init.lua"):format(vs):gsub("/",slash)
    for i,v in next, {path1,path2} do
      if not paths:find(v) then
        paths:push(v)
        res = res or true
      end
    end
  end

  if res then
    package.path= paths:concat(";")
    return true
  end
  return false
end

--append_cpath(...) paths + /?.(dll|so|dylib)
function append_cpath(...)
  local slash = package.config:sub(1,1)
  local df = package.cpath:match('?.so')
  or package.cpath:match('?.dylib')
  or package.cpath:match('?.dll')
  local paths = package.cpath:split(";")
  local res =false

  for i,v in next, {...} do
    local path= ("%s/%s"):format(v,df):gsub("/",slash)
    if not paths:find(path) then
      paths:push(path)
      res = true
    end
  end

  if res then
    package.cpath= paths:concat(";")
    return true
  end
  return false
end


-- require tools api  for Component
function req_lua_module(mod_name)
  --local ok,res = pcall(require, mod_name )
  local ok,lua_mod=xpcall(require,function(msg) return Log(ERROR,"line",__FILE__(3) ,__FUNC__(2),__FUNC__(3) "require error",mod_name) end,mod_name)
  if ok then return lua_mod end
end
function chk_lua_module(mod_name,tab)
  tab = type(tab) == "table" and tab or _ENV
  local tp = type(tab[mod_name] )
  return (tp == "table" or tp == "function") and true or false
end

function rrequire(path,tab,tpath)
  tab = tab or _ENV
  tpath = tpath or path
  local m = req_lua_module(path)
  if not m then return end
  local tp = type(m)
  if tp=="table" and m._modules then
    -- appned  tab[path .. "." .. spath ] = m[spath]
     for name,mod in next , m do
       if not name:match("_modules") then
         local fpath = ("%s.%s"):format(tpath, name)
         tab[fpath] = tab[fpath] and tab[fpath] or mod
       end
     end
  else
    -- 1module
    tab[tpath] = m
  end
  return tab
end
-- for lua_component  check-->  load or  rescue
if ENABLE_RESCUE then
  rrequire('Rescue')
end

function prepare_lua_module(lua_mod,lua_mod_name)
  lua_mod_name = lua_mod_name or lua_mod
  if not chk_lua_module(lua_mod_name) then
    rrequire(lua_mod,_ENV,lua_mod_name)
    if not chk_lua_module(lua_mod_name) then
      Log(ERROR,"prepare lua module failed ", "lua_mod:" .. lua_mod, "mod_name:" .. lua_mod_name)
      _ENV[lua_mod_name] = Rescue and Rescue[lua_mod_name] or nil
      return false
    end
  end
  return true
end




-- init_path
do
  append_path((rime_api.get_user_data_dir() or ".") .. "/lua/component")
  append_cpath((rime_api.get_user_data_dir() or ".") .. "/lua/plugin")
end
