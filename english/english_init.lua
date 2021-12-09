#! /usr/bin/env lua
--
-- english_init.lua
-- Copyright (C) 2020 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
--[[
OS="win"

if OS=="win" then  
	USERDIR=os.getenv("APPDATA") or ""
	USERDIR= USERDIR .. "\\Rime"
else 
	USERDIR=os.getenv("APPDATA") or ""
	USERDIR= USERDIR .. "/Rime"
end 
--]]

--USERDIR= USERDIR .. "\\Rime"



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

table.each=function(tab,func)
	for i,v in ipairs(tab) do
		func(v,i)
	end
	return tab
end
table.find_all=function(tab,elm,...)
	local tmptab=setmetatable({} , {__index=table} )
	local _func=  (type(elm) == "function" and elm ) or  function(v,k, ... ) return  v == elm  end
	for k,v in pairs(tab) do
		if _func(v,...) then
			tmptab:insert(v)
		end
	end
	return tmptab
end
table.find=function(tab,elm,...)
	local _func=  (type(elm) == "function" and elm ) or  function(v, ... ) return  v == elm  end
	for k,v in pairs(tab) do
		if  _func(v,...)  then
			return v,k
		end
	end
	return nil
end

