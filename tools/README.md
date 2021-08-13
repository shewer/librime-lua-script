# librime-lua-tools
## anotifier.lua -- 
## wordninja.lua -- wordninja_word
```lua
wordninja=require("wordninja")
wordninja.init('wordninja_words.txt')
wordninja.test()
wordninja.test('Ilovelua')
wordninja.split("Ilovelua')  -- return table    :concat(" ")

```
## object.lua -- class tools
class method    Word.Parse()
obj method      Word:info()
class instance  Word._name
obj instance    Word:New()._name

    ```lua
    Word= Class("Word",extend)  -- default  Object class
    Word._count=0 -- class instance

    function Word:_initialize(word,info)
    	selfr._word=word -- object instance
    	self._info=word
    	return self
    end
    function Word:info()
    	return self._info
    end
    ```

## loadmodule -- load librime-lua module to global value

	```lua
	loadmodule= require 'tools/loadmodule'
	-- 第一參數等同  local tab= require('english')(argv3....)    { processor={ func=func, init=func,fini=func} , filter={..} , ...}
	-- 第二參數等同  local name= 'english'
	--               for  key,component in next tab do
	--                  _G[name .. "_" .. key ]= component
	--               end
	-- 第三參數以後 爲 module 參數
	
	--  argv1   requier('lua/engilsh/init.lua')
	--  argv2   create  table in global of tag name  english_ .. (processor , filter ,translator, segmentor)
	--  argv3 ... dictfile name    module args
	--
	loadmodule('english','english','english_tw.txt')
	--  argv1   requier('lua/muti_reverse/init.lua')
	--  argv2   create  table in global of tag name  mutirever_ .. (processor , filter ,translator, segmentor)
	--  argv3 ... filter  pattern  use  preedit_format      module args
	loadmodule('muti_reverse' ,'mutirever' ,'preedit_format')
	
	
	```


## schema_func.lua
   ```lua
      get_data(env.engine.schema.config, path , datatype )
      get_data(env.engine.schema.config, path , datatype , list)
	  set_data(env.engine.schema.config, path , data, datatype)   int double string
	  set_data(env.engine.schema.config, path , table, datatype)  list of datatype
	  load_user_data(env.engine.schema.config, data_table)
	  --   data_table = { engine ={
	
   ```

## notifier.lua:   Notifier class
  ```lua
     Notyfier=require 'tools/notifier'
	 function init(env)
	 	env.notifier=Notifier(env)
		env.notifier:commit( function(ctx)  end ) -- context.commit_notifier:connect(func)
		env.notifier:update( function(ctx) end )  -- context.update_notifier:connect(func)
		env.notifier:select( function(ctx) end )  -- context.select_notifier:connect(func)
		env.notifier:delete( function(ctx) end )  -- context.delete_notifier:connect(func)
		env.notifier:option( function(ctx,name) end )  -- context.option_update_notifier:connect(func)
		env.notifier:property( function(ctx,name) end )  -- context.property_update_notifier:connect(func)
		env.notifier:unhandled_key( function(ctx,keyevent ) end )  -- context.unhandled_key_notifier:connect(func)
		
		
	end
	function fini(env)
	    env.notifier:disconnect()  --  disconnect() for all connection()
	end
```
## metatable.lua:    string   table  擴充函式
table:each
table:push
table:pop
table:shift
table:unshift
table:each
tabel:map
table:find
table:reduce
table:find_all

string:split()  -- support utf-8

## debug_info.lua:   get current file name  __FILE__(level:default 2) __LINE__()   __FUNC__()
```lua
-- t.lua
local bug_info= require 'tools/debug_info'


function test()
     print(bug_info.__FILE__() , bug_info.__FUNC__() , bug_info.__LINE__() ) -- @t.lua  test   6
end
test()
```
	


