-- create metatable 
orgtype=type

function type(obj)
  local _type=orgtype(obj)
  if "table" == _type and obj._cname then 
    return obj._cname
  end 
  return _type
end 



function metatable(...)
  if ... and type(...) == "table" then 
    return setmetatable( ... , {__index=table})
  else 
    return setmetatable( {...} , {__index=table})
  end 
end 
-- chech metatble
function metatable_chk(tab)
  if "table" == type(tab) 
  then return   (tab.each and tab)  or metatable(tab) 
  else 
    return tab 
  end
end 

table.eachi=function(tab,func)
  for i=1,#tab   do
    func(tab[i],i)
  end
  return tab
end
table.eacha=function(tab,func)
  for i,v in ipairs(tab) do
    func(v,i)
  end 
  return tab
end 
table.each=function(tab,func)
  for k,v in pairs(tab) do
    func(v,k)
  end
  return tab
end
table.find_index=function(tab,elm, ...) 
  local _ ,i =table.find(tab,elm,...)
  return i
end 
table.find=function(tab,elm,func)
  for i,v in ipairs(tab) do
    if elm == v then 
      return v,i
    end 
  end 
end 

table.find_with_func=function(tab,elm,...)
  local i,v = table.find(tab,elm) 
end 
table.delete= function(tab,elm, ...)
  local index=table.find_index(tab,elm)
  return  index and table.remove(tab,index) 
end 

table.find_all=function(tab,elm,...)
  local tmptab=setmetatable({} , {__index=table} )
  local _func=  (type(elm) == "function" and elm ) or  function(v,k, ... ) return  v == elm  end 
  for k,v in pairs(tab) do 
    if _func(v,k,...) then 
      tmptab:insert(v)
    end 
  end 
  return tmptab
end 
table.select= table.find_all  

table.reduce=function(tab,func,arg)
  local new,old=arg,arg
  for i,v in ipairs(tab) do
    new,old= func(v,new)
  end
  return new ,arg
end 

table.map=function(tab,func)
  local newtab=setmetatable({} , {__index=table}) 
  func= func or function(v,i) return v,i end 
  for i,v in ipairs(tab) do
    newtab[i]= func(v,i)
  end 
  return newtab
end 
table.map_hash=function(tab,func) --  table to   list of array  { key, v} 
  local newtab=setmetatable({} , {__index=table}) 
  func= func or function(k,v) return {k, v} end 
  for k,v in pairs(tab) do
    newtab:insert( func(k,v) )
  end 
  return newtab
end 
function table:push(elm)
  self:insert(elm)
end
table.append = table.push 
function table:pop()
  return self:remove(#self)
end
function table:shift()
  self:remove(1)
end
function table:unshift(elm)
  self:insert(1,elm)
end




setmetatable(string,{__index=table})

function string:filter(filter,...)
  local _filter = filter or FILTER
  if _filter then 
    local _type= type(_filter)
    if _type == "function" then 
      return _filter( self, ... )
    elseif _type == "table"  or _filter:is_a(Filter) then
      return _filter:filter(self, ...)
    end 
  end 
  return str,str
end 

function string.split( str, sp,sp1)
  if   type(sp) == "string"  then     
    if sp:len() == 0 then
      sp= "([%z\1-\127\194-\244][\128-\191]*)"
    elseif sp:len() > 1 then 
      sp1= sp1 or "^"
      _,str= pcall(string.gsub,str ,sp,sp1)
      sp=  "[^".. sp1.. "]*"

    else 
      if sp =="%" then 
	sp= "%%"
      end 
      sp=  "[^" .. sp  .. "]*"
    end 
  else 
    sp= "[^" .. " " .."]+"
  end

  local tab= setmetatable( {} , {__index=table} )
  flag,res= pcall( string.gmatch,str,sp)
  for  v  in res   do
    tab:insert(v)
  end 
  return tab 
end 

