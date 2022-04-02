require 'tools/string'
local List = require 'tools/list'
local cows={   }
cows.name={'cow','armadillo','bearface','cat','cat2'}
cows.cow=[[
%s
%s
%s
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
]]
cows.armadillo = [[
%s
%s
%s

               ,.-----__
            ,:::://///,:::-.
           /:''/////// ``:::`;/|/
          /'   ||||||     :://'`\\
        .' ,   ||||||     `/(  e \\
  -===~__-'\\__X_`````\\_____/~`-._ `.
              ~~        ~~       `~-'
]]
cows.bearface= [[
%s
%s
%s
     .--.              .--.
    : (\\ ". _......_ ." /) :
     '.    `        `    .'
      /'   _        _   `\\
     /     $eye}      {$eye     \\
    |       /      \\       |
    |     /'        `\\     |
     \\   | .  .==.  . |   /
      '._ \\.' \\__/ './ _.'
      /  ``'._-''-_.'``  \\
]]
cows.cat= [[
%s
%s
%s

                          / )      
                         / /       
      //|                \\ \\       
   .-`^ \\   .-`````-.     \\ \\      
 o` {|}  \\_/         \\    / /      
 '--,  _ //   .---.   \\  / /       
   ^^^` )/  ,/     \\   \\/ /        
        (  /)      /\\/   /         
        / / (     / (   /          
    ___/ /) (  __/ __\\ (           
   (((__)((__)((__(((___)          
]]

cows.cat2 = [[
%s
%s
%s

          |\\___/|
         =) .  . |   
          \\  ^  /
           )=*=(       
          /     \\
          |     |
         /| | | |\\
         \\| | |_|/\\
         //_// ___/
             \\_) 
]]
local function cgumirs(y)
   local y4 = y % 4 == 0
   local y100 = y % 100 == 0
   local y400 = y % 400 ==0
   return y4 and not y100 or y400
end
local mday={31,28,31,30,31,30,31,31,30,31,30,31}

local function cal()
   local y,m,d,w = os.date("%Y %m %d %w"):split():unpack()
   local mdays = mday[tonumber(m)] + (m == 2 and cgumirs(y) and 1 or 0) 
   local first_index = os.date("%w",os.time({year= y,month =m ,day=1}))
   local head = " 日 一 二 三 四 五 六 "
   local str = string.format("        %s-%s-%s\n %s \n",y,m,d,head)
   str = str .. ("   "):rep(first_index)
   for i= 1 ,mdays do
      --print(i , string.format("%3d",i))
      str = str .. string.format( "%3d", i)
      --print(str)
      
      if 0 == ((i + first_index ) % 7) then
	str = str ..  " \n"
      end
   end
   
   print(str)
   local sday= string.format(" %2d " ,d)
   local tday= string.format("(%2d)",d)
   return str:gsub(sday,tday)
end
local function cowsay(str)
   str = str or cal()
   local n= cows[ cows.name[ math.random(#cows.name)]]
   local max = 0
   local strr = str:split("\n")
      :map(function(elm)
	    max = max < #elm and #elm or max
	    return "| " .. elm  
	  end)
      :map(function(elm)
	    return elm  .. (" "):rep(max +3-#elm) .."|" 
	  end):concat("\n")

   return string.format( n, ("-"):rep(max + 4) , strr , ("-"):rep(max + 4) )
end

return cowsay
   
