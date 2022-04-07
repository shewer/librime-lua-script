require 'tools/string'
local List = require 'tools/list'
local cows={   }
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
     /     e}      {e     \\
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

cows.eye= [[
    $thoughts
     $thoughts
                                   .::!!!!!!!:.
  .!!!!!:.                        .:!!!!!!!!!!!!
  ~~~~!!!!!!.                 .:!!!!!!!!!UWWW\$\$\$
      :\$\$NWX!!:           .:!!!!!!XUWW\$\$\$\$\$\$\$\$\$P
      \$\$\$\$\$##WX!:      .<!!!!UW\$\$\$\$"  \$\$\$\$\$\$\$\$#
      \$\$\$\$\$  \$\$\$UX   :!!UW\$\$\$\$\$\$\$\$\$   4\$\$\$\$\$*
      ^\$\$\$B  \$\$\$\$\\     \$\$\$\$\$\$\$\$\$\$\$\$   d\$\$R"
        "*\$bd\$\$\$\$      '*\$\$\$\$\$\$\$\$\$\$\$o+#"
             """"          """""""
]]

cows.kitten= [[
%s
%s
%s
       ("`-'  '-/") .___..--' ' "`-._
         ` *_ *  )    `-.   (      ) .`-.__. `)
         (_Y_.) ' ._   )   `._` ;  `` -. .-'
      _.. `--'_..-_/   /--' _ .' ,4
   ( i l ),-''  ( l i),'  ( ( ! .-'
 ]]
cows.tux= [[
%s
%s
%s
        .--.
       |o_o |
       |:_/ |
      //   \\ \\
     (|     | )
    /'\\_   _/`\\
    \\___)=(___/

]]
cows.koala = [[
%s
%s
%s
             .
     .---.  //
    Y|o o|Y//
   /_(i=i)K/
   ~()~*~()~
    (_)-(_)

     Darth
     Vader
     koala
]]

cows.stimpy = [[
%s
%s
%

         .    _  .
         |\\_|/__/|
       / / \\/ \\  \\
      /__|O||O|__ \\
     |/_ \\_/\\_/ _\\ |
     | | (____) | ||
     \\/\\___/\\__/  //
     (_/         ||
      |          ||
      |          ||\\
       \\        //_/
        \\______//
       __ || __||
      (____(____)
]]
local function cgumirs(y)
   local y4 = y % 4 == 0
   local y100 = y % 100 == 0
   local y400 = y % 400 ==0
   return y4 and not y100 or y400
end

local cowsay_list={}
for k,v in next,cows do table.insert(cowsay_list,k) end 

local mday={31,28,31,30,31,30,31,31,30,31,30,31}

local function cal()
   local y,m,d,w = os.date("%Y %m %d %w"):split():unpack()
   local mdays = mday[tonumber(m)] + (m == 2 and cgumirs(y) and 1 or 0) 
   local first_index = os.date("%w",os.time({year= y,month =m ,day=1}))
   local head = " Su Mo Tu We Th Fr Sa "
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
   local n= cows[ cowsay_list[ math.random(#cowsay_list)]]
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
   
