-- wrap utf8.sub(str,head_index, tail_index)
-- wrap string.split(str,sp,sp1)
--      string.utf8_len = utf8.len
--      string.utf8_offset= utf8.offset
--      string.utf8_sub= utf8.sub
local List = require 'tools/list'
function string.split( str, sp,sp1)
  sp =type(sp) == "string"  and sp or " "
  if #sp == 0 then
    sp= "([%z\1-\127\194-\244][\128-\191]*)"
  elseif #sp == 1 then
    sp= "[^" ..  (sp=="%" and "%%" or sp) .. "]*"
  else
    sp1= sp1 or "^"
    str=str:gsub(sp,sp1)
    sp=  "[^".. sp1 .. "]*"
  end

  local tab= List()
  for v in str:gmatch(sp) do
    table.insert(tab,v)
  end
  return tab
end

function utf8.sub(str,si,ei)
  local si_type= type(si)
  if si_type ~= "number" then
    local info=debug.getinfo(2,'Sln')
    local error_msg= string.format("%s:%s bad argument #1 (number expected, get %s)",
    info.short_src, info.currentline, si_type)
    assert(nil, error_msg)
  end

  local len= utf8.len(str)
  if si <0 then
    si = si < -len and 1 or len + si + 1
  end

  ei = (not ei or ei >len ) and len or ei
  if ei < 0 then
    ei = ei < -len and 0 or len + ei +1
  end
  if si > ei then return "" end

  local u_si= utf8.offset(str,si)
  local u_ei= utf8.offset(str,ei+1) - 1
  return str:sub(u_si,u_ei)
end

string.utf8_len= utf8.len
string.utf8_offset=utf8.offset
string.utf8_sub= utf8.sub

return true
