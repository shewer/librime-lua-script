#! /usr/bin/env lua
--
-- _log.lua
-- Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
-- Log(INFO, ...) -->  log.info( "[file:func:line] : ...")
-- Log(WARN, ...)
-- Log(ERROR, ...)
-- Log(DEBUG, ...)
-- Log(CONSOLE, ...)
--
-- Log_data(tag, obj, msg) --
--
-- fake log
if not log then
  log={
    info= function(msg) io.stdout:write(msg) end,
    warning= function(msg) io.stdout:write(msg) end,
    error = function(msg) io.stderr:write(msg) end,
  }
end

INFO="info"
WARN="warn"
ERROR="error"
DEBUG="trace"
CONSOLE="console"
log_type_func={
  info= log.info,
  warn = log.warning,
  error  = log.error,
  trace = log.error,
  console = print,
}

function Log( tag , ...)
  local info= debug.getinfo(2,'Sln')
  info.short_src = info.short_src:match("lua/(.*.lua)$")
  local tab= {...}
  for i=1,#tab  do
    tab[i]=tostring( tab[i])
  end
  local tab_str = table.concat(tab, " : ")
  local head_str = string.format( "%s [%s:%s:%s] : ",
   tag, info.short_src, info.name, info.currentline)

  local func= (log_type_func[tag] or print)
  func(head_str .. tab_str)
end

local function tab_to_s(tab,str,depth)
  str = str or ""
  depth = depth or 0
  if #str >4000 then return str end
  local CT = "\t"
  local RN= "\n"
  local ot = type(tab)
  if ot == "table" then
    str = str .. "{\n"
    for k,v in next, tab do
      if v ~= _G and  v ~= _ENV then
        str = ("%s%s%s : "):format(str,CT:rep(depth+1),k)
        str= tab_to_s(v,str, depth +1 )
      end
    end
    return str .. CT:rep(depth) .. "}\n"
  else
    return  str .. tostring(tab) .. "\n"
  end
end
function Log_data(tag,obj,msg,enab_mt)
  local info= debug.getinfo(2,'Sln')
  info.short_src = info.short_src:match("lua/(.*.lua)$")

  info_str=("%s [%s:%s:%s] : ---inspect: %s--- : %s"):format(tag,info.short_src,info.name,info.currentline, msg or "", obj)
  local str = ""
  if type(obj)== "table" then
    str = str .. "\n"
    for k,v in next,obj do
      str = ("%s\t %s : %s \n"):format(str, k,v )
    end
  end
  if enab_mt then
    local mt = getmetatable(obj)
    if mt then
      str = str .. "\n metatable :\n"
      for k,v in next, mt do
        str = ("%s\t %s : %s \n"):format(str, k,v )
      end
    end
  end


  local log_func = log_type_func[tag] or print
  log_func(info_str .. str )
end
