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
    %S
    %S
    %S
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
%s

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

local function cal(date_str)
   date_str = str or os.date("%Y-%m-%d")
   local y,m,d = date_str:split("-"):unpack()
   local mdays = mday[tonumber(m)] + (m == 2 and cgumirs(y) and 1 or 0) 
   local first_index = os.date("%w",os.time({year= y,month =m ,day=1}))
   local str = ""
   for i= 1 ,mdays do
      str = str .. string.format( "%3d", i)
      if 0 == ((i + first_index ) % 7) then
        str = str ..  " \n"
      end
   end

   local sday= string.format(" %2d ", d)
   local tday= string.format("(%2d)", d)
   str = (" "):rep(first_index*3) .. str:gsub(sday,tday)  .. (" "):rep( (35 - mdays - first_index)*3 +1 )
   local head = " Su Mo Tu We Th Fr Sa "
   return  string.format("%6s%4d-%2d-%2d%6s\n%s\n%s","",y,m,d,"",head,str)
end

local function cowsay(str)
   str = str or cal()
   local n= cows[ cowsay_list[ math.random(#cowsay_list)]]
   local max = 0
   local strr = str:split("\n")
      :map(function(elm)
	    max = max < #elm and #elm or max
	    return "|" .. elm  .. "|"
	  end):concat("\n")
   local l_str = string.format("+%s+",("-"):rep(max) )
   return string.format( n, l_str, strr, l_str)
end

return  cowsay
   
