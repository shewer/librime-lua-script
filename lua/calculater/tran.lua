#! /usr/bin/env lua
--
-- tran.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--


local cmd=require 'calculater/cal_cmd'
local _NR = package.config:sub(1,1) == "/" and "\n" or "\r"
local T={}

function T.init(env)
  local context = env.engine.context
 -- select func
  T.func = false and string.split and T.func or T.func1
end

function T.fini(env)
end

function T.func(input, seg, env)
  if not seg:has_tag("cal_cmd") then return end
  cmd('0',true)
  input:sub(2):split(_NR)
  :map(function(elm)
    local text,comment = cmd(elm)
    return  #elm>0 and
      Candidate("cal_cmd",seg.start,seg._end, text, comment .." = "..text ) or nil
  end)
  :reverse()
  :each(yield)
end

-- 沒有 tools/list 的版本
function T.func1(input, seg, env)
  if not seg:has_tag("cal_cmd") and input:len() < 2 then return end
  -- reset res = 0
  cmd('0',true)
  local tab={}
  for elm in input:sub(2):gmatch("[^".._NR.."]+") do
    local text,comment = cmd(elm)
    table.insert(tab,
      Candidate("cal_cmd",seg.start,seg._end, text ,comment.." = "..text ) )
  end

  for i=#tab,1,-1 do
    yield(tab[i])
  end
end

--T.func = T.func1
return T
