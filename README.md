# 增加 init_processor.lua 
  使用了 tags_match() and ConfigMap:keys() 只支援 librime-lua #131 以上版本 window版本rime.dll 可從 https://github.com/shewer/librime-lua/releases 下載
  可由 yaml name_space 或 rime.lua 載入模組(以 yaml name_space 爲優先)
  
  由 init_processor 導入模組
  可用模組 english(包含wordninja) conjunctive command
  化簡繁複 custom.yaml rime.lua 編輯
  ## conjunctive 聯想詞模組
    * 中文上屏後觸發
    * 上屏字母串編輯 ~< 字尾刪除 > 字頭刪除
    * ~~H  自定字串  ~~C 清除  ~~B 還原
  ## command 命令模組 顯示 設定 執行 命令 支援 Tab 補齊功能
   可擴充 config func 設定 達到線上重載功能，後續再增加
   
    * /<opcf>:<name>:<value>  o: option p:property c:config f:funcs
    * /o: option 顯示/設定 true/false /o:<name>:<true/false>  (toggle/set/unset)
    * /p: property 顯示/設定字串 /p:<name>:value
    * /f: function 顯示 執行 /f:<name>:<argv1,argv2,....>
    * /c: config 顯示 設定字串 /c:<path>:value  分隔符 / 
    * 範例
       * /o:as{Tab}:t{Space} --> /o:ascii-mode:t
       * /o:abcd:t --> 設定新值 option abcd= true
       * /p:test:test{Space} 設定新值 property test= "test"
       * /c:me{Tab}/p{Tab}:9{Space} 設定 menu/page_size 
       * /f:re(Tab}{Space} 重載   /f:reload execute 
       * /f:me{Tab}:5{Space} 設定meun/page_size 井重載 /f:menu_size:5
       
  ## english 英文字典模組 支援 Tab 補齊功能 及 wordninja
    * 英打模式 待增

  ## 安裝
  ```
  git clone https://github.com/shewer/librime-lua-script <userdata>/lua
  cp  lua/example/processor.yaml <userdata>
  ```
  
 ### 由 yaml module1/modules 載入
  ```yaml
  custom.yaml
  patch: 
    __include: processor_plugin:/patch
    # patch:
    #   engine/processors/@after 0: lua_processor@init_processor@module1
    #     module1/modules:
    #       - { module: 'command'    , module_name: "cammand_proc"    , name_space: "command" }
    #       - { module: 'english'    , module_name: "english_proc"    , name_space: "english" }
    #       - { module: "conjunctive", module_name: "conjunctive_proc", name_space: "conjunctive" }
    
  ```
  ```lua
  --rime.lua
  init_processor= require('init_processor')
  ```
  ### 由 rime.lua module2 載入 
  ```yaml
  #custom.yaml
  patch:
    engine/processors/@after 0: lua_processor@init_processor@module2 
  ```
  ```lua
  ---rime.lua

  module2={
  {module='command', module_name="cammand_proc",name_space="command" },
  {module='english', module_name="english_proc",name_space="english" },
  {module="conjunctive", odule_name = "conjunctive_proc",name_space="conjunctive"},
}
  init_processor=require('init_processor')
    
  ```

  
# librime-lua-script
## ~~multi_reverse 主副字典反查(新版)  支持 librime-lua(新舊版)~~  新架構可能造成失效待修正
自動導入 engine/translators/   script_translator table_translator   反查 lua_filter
### 反查字典切換
* Ctrl+6 反查開關
* ctrl+7 反查碼顯示最短碼開關
* ctrl+8 未完成碼上屏開關 
* Ctrl+9 反查碼filter 切換(正) 
* Ctrl+0 反查碼filter 切換(負)
### 安裝
* rime.lua
```lua
require 'tools/rime_api'   -- 擴充 rime_api table 接口 
require 'multi_reverse'    -- 載入 multi_reverse_processor multi_reverse_filter
assert( multi_reverse_processor) 
```
* schema_id.custom.yaml 
``` 
patch: 
   engine/processors/@after 0: lua_processor@multi_reverse_processor
```
## 聯想詞彙 conjunctive.lua (支援librime-lua Commits on Oct 11, 2020 版本)

利用 commit_notifier & update_notifier & engine.process_key context.input(~ ~)  ~~重送 KeyEvent(~)~~ , 觸發 lua_translator@conjunctive 產生聯想詞彙

增加聯想開關(F11)
 *增加 (~) 觸發聯想(~ ~)字串處理   
   * [><~] : 刪字 ~ < 刪字尾   > 刪字首，變更時下面聯想詞也會更新重組， 織 backspace 恢復上一字元  space 變更 env.history
   * C : 清除 space 變更 env.history=""
   * B : 還原上次異動 space 變更 env.history= env.history_back
   * H : user 常用詞 選屏上字  
   




自動載入參數據( lua_translator@conjunctive and module ) 插入 echo_translator後   punct_translator前

### 安裝
```
-- copy file  to user_data_dir/lua  
lua/tools/list.lua  -- list module 
lua/tools/ditc.lua  -- 聯想詞彙 module 
lua/conjunctive.lua  -- 主程式

--- rime.lua
conjunctive_proc= require('conjunctive')
---  custom.yaml
patch:
  engine/processors/@after 0: lua_processor@conjunctive_proc

```
### 設定值
```lua
-- conjunctive.lua 設定參數
 -- 使用者常用詞                             
 _HISTORY={                                   
 "發性進行性失語",                            
 "發性症狀",                                  
 "發性行性失語症狀",                          
 "發性進行失語症狀",                          
 "發進行性失症狀",                            
 "發性進行失語症狀",                          
 "性進行失語症狀",                            
 "發性行性失語症狀",                          
 "進行性失語症狀",                            
 }                                            
                                              
-- user define data
local pattern_str="~"  -- 聯想觸發 keyevent
local lua_tran_ns="conjunctive" 
local dict_file= 'essay.txt'
local switch_key="F11" -- 聯想詞開闢 預設 0  on  1 off , keybinder {when:always,accept: F11, toggle: conjunctive}

```

## [tools 常用工具](https://github.com/shewer/librime-lua-script/tools/README.md)
* list.lua 提供 each map reduce select ... 
* string 擴充 utf8.sub string.split string.utf8_sub string.utf8_len string.utf8_offset 
* rime_api.lua 擴充 rime_api globl function Env(env) Init_projection(config,path)
* dict.lua 聯想詞查表 
* key_binder.lua 類 keybind 提供 lua_processor 熱鍵
* pattern.lua librime-lua 舊版無支援 ProjectionReg 改由 lua 實現 pattern 轉換   preedit_format commit_format
* inspect.lua -- 源自 luarocks 安裝 
* json.lua  -- 源自 luarocks 安裝
* luaunit.lua testunit  -- 源自 luarocks 安裝
     
## test luaunit 測試資料夾


