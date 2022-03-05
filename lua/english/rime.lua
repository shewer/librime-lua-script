--require 'tools/log'
--log.info("PATH:" .. package.path)
--log.info("CPATH:" .. package.cpath) 

--if type(jit) == "table" then 
	--require 'ffi'
--end 










load_module=require('tools/loadmodule')


--date_translator = require("date")
--time_translator = require("time")


--
--load_module.load( 'module' , lua_component name, args ....)
--    require 'lua/english/init.lua   , 
--    lua_processor@english_processor ,  lua_segmentor@english_segmentor .....
--    args   'english_tw.txt'   字典檔    word\t[音標]; 翻譯  ......   \t
load_module.load('english','english',"english_tw.txt") --  module , target_name , dict_file 




