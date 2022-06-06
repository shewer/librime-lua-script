#! /usr/bin/env lua
--
-- csvtotab.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--

-- Used to escape "'s by toCSV
local function escapeCSV(s)
  if string.find(s, '[,"]') then
    s = '"' .. string.gsub(s, '"', '""') .. '"'
  end
  return s
end
-- cancel then function
-- Convert from CSV string to table (converts a single line of a CSV file)
local function fromCSV(s)
  s = s .. ','        -- ending comma
  local t = {}        -- table to collect fields
  local fieldstart = 1
  repeat
    -- next field is quoted? (start with `"'?)
    if string.find(s, '^"', fieldstart) then
      local a, c
      local i  = fieldstart
      repeat
        -- find closing quote
        a, i, c = string.find(s, '"("?)', i+1)
      until c ~= '"'    -- quote not followed by quote?
      if not i then error('unmatched "') end
      local f = string.sub(s, fieldstart+1, i-1)
      table.insert(t, (string.gsub(f, '""', '"')))
      fieldstart = string.find(s, ',', i) + 1
    else                -- unquoted; find next comma
      local nexti = string.find(s, ',', fieldstart)
      table.insert(t, string.sub(s, fieldstart, nexti-1))
      fieldstart = nexti + 1
    end
  until fieldstart > string.len(s)
  return t
end



-- Convert from table to CSV string
local function toCSV(tt)
  local s = ""
-- ChM 23.02.2014: changed pairs to ipairs
-- assumption is that fromCSV and toCSV maintain data as ordered array
  for _,p in ipairs(tt) do
    s = s .. "," .. escapeCSV(p)
  end
  return string.sub(s, 2)      -- remove first comma
end
local line_no
local function tomap(head,list)
      if #head == #list then
        local map={}
        for i=1,#list do
          map[head[i]] = list[i]
        end
        return map
      else
        warn(" filed not match :", line_no)
      end
end



--[[
--]]
local token_head = [[^(.*)]]
local token_p1 = token_head .. [[,(.*)$]]
local token_p2 = token_head .. [[,"("".*)"$]]
local token_p3 = token_head .. [[,"([^"].*)"$]]

local function token(str)
  local h,t
  if not str:match[["$]] then
    h,t = str:match(  token_p1)
  else
    h,t = str:match(  token_p2)
    if not h then
      h,t = str:match( token_p3)
    end
  end
  t = (t and  t or str):gsub('""','"')
  return t,h
end


local function reverse(tab)
  local t={}
  for i=#tab,1,-1 do
    table.insert(t,tab[i])
  end
  return t
end
local function csvline(str,tab)
  if str:match([[^#]]) then return end
  str = str:gsub("\r","")
  tab= tab or {}
  local t ,h = token(str)
  if not t then return tab end
  table.insert(tab,1,t)
  if h then
    csvline(h,tab)
  end
  return tab -- reverse(tab)
end

function load_csv(filename, with_header)
  local fn = io.open(filename)
  print("load_csv", fn)
  if not fn then return end
  local tab = {}
  local head = with_header  and csvline(fn:read() )
  line_no = head and 1 or 0
  warn("@on")
  for line in fn:lines() do
    line_no = line_no +1
    if not line:match([[^#]]) then
      table.insert(tab,
        with_header and tomap( head,csvline(line)) or csvline(line) )
      --head and tomap( head,csvline(line) ) or csvline(line) )
    end
  end
  warn("@off")
  fn:close()
  return tab
end
local Base={}
function Base:__call(...)
  local obj = setmetatable({},self)
  return obj:_initialize(...)
end
local M=setmetatable({},Base)
M.__index = M
function M:_initialize(lines,with_header)
end
function M:header(...)
  local tab = ...
  if not tab then return self._header end
  tab =  type(chk) ~= "table" and {...} or tab
  tab = {...}
  local header = {}
  for i,v in ipairs(tab) do
    header[v] = i
  end
  self._header = header
  return self._header
end

-- CSV  function
function M.Parse(lines,with_header)
   if with_header then
      self:header( csvline(lines[1]) )
   end
   local st = with_header and 2 or 1
   for i = st , #lines do
     table.insert(self, csvline( lines[i] ) )
   end
   M()
end
function M.File(filename,with_header)
  local rec = locad_csv(filename,with_header)
end

M.Line_to_tab = csvline
M.Load_csv=load_csv


--[[  debug

M._token_p1= token_p1
M._token_p2= token_p2
M._token_p2= token_p3
M.token = token
--]] -- debug

return M



