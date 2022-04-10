
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

-- 繁體使用者 simplifier/opencc_config: t2s.json (預設)  default: 繁體詞庫 enable: 簡體詞庫
-- 
--__conjunctive_file={default="essay.txt",enable="essay_cn.txt"}
-- 簡體使用者 simplifier/opencc_config: s2t.json (預設)  default: 體簡詞庫 enable: 繁體詞庫
-- __conjunctive_file={default="eassay-zh-hans.txt",enable="essay.txt"}

module1={
  {module = "command"    , module_name = "cammand_proc"    , name_space = "command" },
  {module = "conjunctive", module_name = "conjunctive_proc", name_space = "conjunctive"},
}

init_processor= require 'init_processor' 
