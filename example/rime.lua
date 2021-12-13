
--[[
#<方案1>.custom.yaml # 由moduel1 name_space 載入 module1  
 patch: 
   engine/processors/lua_processor@init_processor@module1 
   module1/modules:
     - { module: 'command'    , module_name: "command_proc"    , name_space: "command"}
     - { module: 'conjunctive', module_name: "conjunctive_proc", name_space: "conjunctive"}
      
#<方案2>.custom.yaml  # 由 _G[module1] 載入 module1 
patch:
   engine/processors/lua_processor@init_processor@module1

#<方案3>.custom.yaml  # 由 _G[module2] 載入 module2 
patch:
   engine/processors/lua_processor@init_processor@module2
 
--]]
module1={
  {module = "command"    , module_name = "cammand_proc"    , name_space = "command" },
  {module = "conjunctive", module_name = "conjunctive_proc", name_space = "conjunctive"},
}

init_processor= require 'init_processor' 
