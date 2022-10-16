#! /usr/bin/env lua
--
-- _req_api.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
-- lua_mod (string): require(lua_mod)    func ,mod_tab , mods_tab( proc=lua_mod,segm=lua_mod, tran=... , filter=...}
-- gtab 掛入目標table ( _G , _ENV(預設) , 自訂 table)
-- lua_mod_name 目標模組名 預設同 lua_mod
-- 1 type func:  rrequire( 'mod_func' )  -- _ENV['mod_func'] = require('mod_func')
--   同mod_tab:  rrequire( 'mmod_func.proc')  -- _ENV['mod_func.proc'] = require('mod_func/proc')
--               rrequire( 'mod_func',_G, 'mmod_func') -- _G['mmod_func'] = require('mod_func')
--
--
-- 2 type mods_tab:  rrequire('mods_tab') -- _ENV['mods_tab.proc'] = require('mods_tab/proc') ,_ENV['...segm'] = require('....segm')....
--                   rrequire('mods_tab',_G,'mmods_tab') -- _G['mmods_tab.proc']=require('mods_tab/proc') ... ... 同上式
--
--return(args 2) :  bool, require('mod_name')
--
require 'tools/_log' -- Log
require 'tools/_file' -- rpath


function rrequire(lua_mod,gtab,lua_mod_name)
  local gtab = gtab or _ENV
  lua_mod_name = lua_mod_name or lua_mod
  ok, m = pcall(require, lua_mod)
  if not ok then
    Log(ERROR,'require failed :',lua_mod )
    return false
  end


  local tp = type(m)
  if tp == "table" and tp._module then
    for k,v in next, m do
      local vtp = type(v)
      if not k:match("^_") and  (vtp =="function" or vtp == "table") then
        local mname= ("%s.%s"):format(lua_mod_name, k)
        gtab[mname] = gtab[mname] or  v
      end
    end
  elseif (tp == "table" or tp == "function") then
    gtab[lua_mod_name] = gtab[lua_mod_name] or m
  else
    Log(WARN,'require type not match',lua_mod, tp,m)
    return false
  end
  return true,m
end


