
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

  local tab= {}
  for v in str:gmatch(sp) do
    table.insert(tab,v)
  end 
  return tab 
end

return true
