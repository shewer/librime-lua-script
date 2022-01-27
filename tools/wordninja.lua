#! /usr/bin/env lua
--
-- wordninja1.lua
-- Copyright (C) 2021 Shewer Lu <shewer@gmail.com>
--
-- Distributed under terms of the MIT license.
--
-- wordninja = require('wordnija.lua')
-- wordninja.init( "./wordninja_words.txt")
--
-- wordninja.split( str ) -- return list table
-- 			.test()  test sample
--
-- 	exp:
-- 	  wordninja.split("ilovelua"):concat(" ")
--
--
--
function __FILE__(n) n=n or 2 return debug.getinfo(n,'S').source end
function __LINE__(n) n=n or 2 return debug.getinfo(n, 'l').currentline end
function __FUNC__(n) n=n or 2 return debug.getinfo(n, 'n').name end
local tab={}
local function dictload(filename)
  local tab=setmetatable({},{__index=table})
  local index=1
  --local fn=io.popen("zcat ".. filename)
  for w in io.open(filename):lines() do
    local ww=  w:gsub("%s","") or ""
    if not ww or #ww > 0 then
      tab:insert( ww )
    end
  end
  local dict={}
  local max_len=0
  local tablog= math.log(#tab)
  -- print("table size:",#tab)
  for i,w in next , tab do
    dict[w] = math.log( i * tablog )
    max_len =  ( max_len < #w and #w ) or max_len
  end
  dict[""]=0
  return dict,max_len
end

--local dict,max_len = dictload("./wordninja/wordninja_words.txt.gz")
local bast_leftword={}

local function substr(str,i,tp)   -- str,i  return   h str , t str   str,i,true return #h str , t.str
  i= ( i<0 and 0) or i
  return tp and #(str:sub(0,i)) or str:sub(0,i)  , str:sub(i+1)
end

local function _split(str)
  --- init cost list
  local cost={}
  cost[0]={c=0,k=0}

  local function best_match(s,index,minc,bestk)
    -- index= index or #s
    -- minc=minc or 9e999
    -- k= k or #s
    --	print(s,index,minc,bestk,s:sub(index),dict[s:sub(index)])
    --
    --	stop loop    max_loop == tab.maxlen
    if index<1 or index  < #s - tab.maxlen   then
      --		print("----strlen:", s:len() ,"index" ,index ,"loop=", s:len() -index, "minc", minc ,"best_token" , bestk)
      return {c=minc,k=bestk}
    end
    assert(cost[index-1], ("index:%d  -1:%s $s  c: %s k: %s"):format(
    index, index-1, cost[index-1],cost[index-1].k,cost[index-1].c))
    assert(tab.dict[s:sub(index)] or 9e999, "error"  )
    --	print( ("cost[%s].c: %s , dict[ %s]:%s "):format( index-1, cost[index-1].c , s:sub(index), dict[s:sub(index)]or 9e999 ))
    local c = cost[index-1].c  + ( tab.dict[s:sub(index)] or 9e999 )
    --  update   minc  &  token
    if c < minc then
      bestk=index-1
      minc=c
    end
    return best_match(s,index-1,minc,bestk)
  end

  local function rever_word( s,tab )
    local  h,t = substr(s,cost[#s].k)
    if #s <=0 then return tab end
    --print(s,#s ,cost[#s].k,"===" ,h.." | "..t ,"===" ,table.concat(tab ," ") )
    if t=="'s" then
      cost[#s].k= cost[#s-2].k  -- cost[#s].k  move to next k
      return rever_word(s,tab)
    end
    if t:match("^[%d]+$")  then
      local h1,t1=substr(h,cost[#h].k)
      if t1:match("^%d$") then
        cost[#s].k = cost[#s].k -1 --  cost[#s].k -1
        --print("---callback ",s,#s ,cost[#s].k,"===" ,h.." | "..t ,"===" ,table.concat(tab ," ") )
        return rever_word(s,tab)
      end
    end
    table.insert(tab,1, t ) -- unshift t
    return rever_word(h, tab)
  end
  -----   start ------

  local ss=str:lower()
  for i=1,#ss do
    cost[i] = best_match( ss:sub(1,i) ,i, 9e999, i)
  end
  return rever_word(str,{} )
end

function split(s,sp)
  sp= sp or " "
  local tab= setmetatable({},{__index=table})
  --    "abe,.p,.poeu-,a" -> {abe p poeu a}
  for w in  s:gmatch("[%a%d']+") do
    for i,ww in next , _split(w) do
      tab:insert(ww)
    end
  end
  return table.concat(tab,sp) 
end

local ss="WethepeopleoftheunitedstatesinordertoformamoreperfectunionestablishjusticeinsuredomestictranquilityprovideforthecommondefencepromotethegeneralwelfareandsecuretheblessingsoflibertytoourselvesandourposteritydoordainandestablishthisconstitutionfortheunitedstatesofAmerica"
local ss_res="We the people of the united states in order to form a more perfect union establish justice in sure domestic tranquility provide for the common defence promote the general welfare and secure the blessings of liberty to ourselves and our posterity do ordain and establish this constitution for the united states of America"

local function time_count(func,...)
  local t1=os.clock()
  local res = func(...)
  return res,(os.clock() - t1)
end
local function test(s)
  s = type(s) == "string" and s or ss 
  local res,time = time_count( split,s)
  print(("--%s--\n--%s--\n%s"):format(s,res,time) )
  return rstr
end

local function init(filename)
  local path= string.gsub(debug.getinfo(1).source,"^@(.+/)[^/]+$", "%1")
  filename =  path ..  (filename or "wordninja_words.txt" )
  tab.dict,tab.maxlen= dictload( filename)
end

tab.init=init
tab.split=split
tab.tc=time_count
tab.test=test
tab.ts=ss

return tab

