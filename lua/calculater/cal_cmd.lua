--[[
files : user_data_dir/lua/cmd.lua

rime.lua
cmd = require 'cmd'

--]]
-- 生成有限環境 把 math 提至上層

local function init_env1()
  local tab = {}
  tab.res =  0
  tab.print= print
  --tab.load = load
  --tab.pcall= pcall
  for k,v in next, math do
    tab[k] = v
  end
  return tab
end
local function init_env2()
  return setmetatable({res=0},{__index=math})
end

local ENV=init_env2()

local function cmd(str,reset)
  -- reset = true new ENV
  ENV = reset and init_env2() or ENV
  --res_str= type(res)=='number' and res==0 and "( res ) " or ""
  local HRET= "return "
  local TRET= "; return res"
  local rstr


  if str:match("^%s*for") then -- loop
    rstr = str .. TRET
  elseif str:match("^%s*res=") then -- reset res
    rstr = str .. TRET
  elseif str:match("^%s*=") then --reset res
    str = 'res ' .. str
    rstr = str .. TRET
  elseif str:match("%s*%a*=") then -- set ather
    rstr = str .. TRET
  elseif str:match("^%s*[+-/*]") then -- (res) .. str
    str = "(" ..ENV.res..")" .. str
    rstr = HRET .. str
  else
    rstr= HRET .. str
  end


  local func= load( rstr,'cal','bt',ENV ) -- keep _ENV
  local ok,res  = pcall(func )
  if ok then
    ENV.res= res or ENV.res-- save res
    return tostring(ENV.res), str
  else
    return "", str
  end

end




-- test
local function test()
  local passed="...........pass"
  local faild="...........Faild"
  str = [[3+3]]
  print( str , "--> res = 3+3", cmd(str),RES, RES==6 and passed or faild )
  str = [[res + 5]]
  print(str , "--> res = res + 5",cmd(str),RES, RES==11 and passed or faild )
  str = [[ * 4]]
  print(str , "--> res = res * 4",cmd(str),RES, RES==44 and passed or faild )
  str = [[= 0]]
  print(str , "--> res = 05",cmd(str),RES, RES==0 and passed or faild )
  str= [[for i=1,10 do res = res + i end]]
  print(str , "--> res =res + 1+ ...10",cmd(str),RES, RES==55 and passed or faild )
  str = [[sin(1/2*pi)]]
  print(str , "--> res = sin(1/2pi)",cmd(str),RES, RES==1.0 and passed or faild )

  print( 'kept var ')
  str = [[ a=4;b=5]]
  print(str , "--> res = res ; a = 4 b = 5",cmd(str),RES, RES==1.0 and passed or faild )
  str = [[ a ]]
  print(str , "--> res = a (4)",cmd(str),RES, RES==4 and passed or faild )
  str = [[ + b]]
  print(str , "--> res = a (4) + b (5)",cmd(str),RES, RES==9 and passed or faild )

  print( 'new ENV')
  str = [[ a=4;b=5]]
  print(str , "--> res = 0 ;a =nil b=nil",cmd(str,true),RES, RES==0 and passed or faild )
  str = [[ a ]]
  print(str , "--> res = a (nil)",cmd(str,true),RES, RES==nil and passed or faild )
end
local TEST = false --true
if TEST then test() end
return cmd
