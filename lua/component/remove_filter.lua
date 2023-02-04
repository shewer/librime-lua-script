#! /usr/bin/env lua
--
-- remove_filter.lua
-- Copyright (C) 2023 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
-- 使用 text dada 建立 屏蔽 candidate
-- 屏蔽 filename:  user_data_dir/[name_space].txt
-- 透過 property "delete_candidate" 來更新 Rmdb
-- 增加 property 'delect_candidate'  'reload' 重載入檔案
-- 增加 property 'delect_candidate'  'enable' enable append() find() match()
-- 增加 property 'delect_candidate'  'disable' disable append() find() match()
-- 增加 property 'delect_candidate'  'toggle' enable or disable  append() find() match()
--
--

-- Rmdb module
-- Rmdb(filename)
-- Rmdb:load() -- reloda  text file
-- Rmdb:append() -- update text file
-- Rmdb:find(word) or Rmdb:match(word) -- return bool
-- Rmdb:enable(nil|true|false) return bool | set and return
-- Rmdb:toggle() return bool
--

-- check get_user_data_dir func
if not rime_api.get_user_data_dir then
  rime_api.get_user_data_dir = function()
    return "." -- set user_data_dir
  end
end

local Rmdb_mt={}
Rmdb_mt.__index =Rmdb_mt

function Rmdb_mt:load()
  local tab ={}
  for line in io.open(self.__filename,"a+"):lines() do
    local word = line:match("^([^#_].*)$")
    if word then
      tab[word]=true
    end
  end
  self.__db=tab
end

function Rmdb_mt:append(word)
  if self:match(word) or not self:enable() then return end

  local fn = io.open(self.__filename,"a")
  if fn then
    fn:write(word .. "\n")
    fn:close()
    self.__db[word]=true
  else
    log.error("Rmdb Error: can't open file:".. self.__filename)
  end
end

function Rmdb_mt:find(word)
  return self:enable() and self.__db[word]
end

Rmdb_mt.match=Rmdb_mt.find
function Rmdb_mt:enable(bool)
  if bool == nil then return self.__enable end
  self.__enable = bool and true or false
  return self.__enable
end
function Rmdb_mt:toggle()
  return self:enable( not self:enable() )
end

function Rmdb(name)
  local obj= setmetatable({}, Rmdb_mt)
  obj.__filename = rime_api.get_user_data_dir() .. package.config:sub(1,1) .. name .. ".txt"
  obj.__enable = true
  obj:load()
  return obj
end

local M={}

local n_name='delete_candidate'
function M.init(env)
  env.rmdb= Rmdb(env.name_space)
  env.notifiers={
    env.engine.context.property_update_notifier:connect(
    function(ctx,name)
      if name ~= n_name then return end
      local word=ctx:get_property(name)
      if word == 'reload' then
        env.rmdb:load()
      elseif word == 'enable' then
        env.rmdb:enable(true)
      elseif word == 'disable' then
        env.rmdb:enable(false)
      elseif word == 'toggle' then
        env.rmdb:toggle()
      else
        env.rmdb:append(word)
      end
    end),
    env.engine.context.option_update_notifier:connect(
    function(ctx,name)
      if name ~= n_name then return end
      env.rmdb:enable(ctx:get_option(name))
    end),
  }
end

function M.fini(env)
  for _,notifier in ipairs(env.notifiers) do notifier:disconnect() end
end

function M.tags_match(seg,env)
  return true
end

function M.func(inp,env)
  for cand in inp:iter() do
    if not env.rmdb:find(cand.text) then
      yield(cand)
    end
  end
end

return M
