# librime-lua-script
## multi_reverse 主副字典反查(新版)  支持 librime-lua(新舊版)
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
## 聯想詞彙 conjunctive.lua 


利用 commit_notifier & update_notifier & engine.process_key 重送 KeyEvent(~), 觸發 lua_translator@conjunctive 產生聯想詞彙

增加聯想開關(F11) 

自動載入參數據( lua_translator@conjunctive and module ) 插入 echo_translator後   punct_translator前


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
```lua
-- conjunctive.lua 設定參數
-- user define data
local pattern_str="~"  -- 聯想觸發 keyevent
local lua_tran_ns="conjunctive" 
local dict_file= 'essay.txt'
local switch_key="F11" -- 聯想詞開闢 預設 0  on  1 off , keybinder {when:always,accept: F11, toggle: conjunctive}

```

## [tools 常用工具](https://github.com/shewer/librime-lua-script/tools/README.md)
* list.lua 提供 each map reduce select ... 
* rime_api.lua 擴充 rime_api 
* key_binder.lua 類 keybind 提供 lua_processor 熱鍵
* pattern.lua librime-lua 舊版無支援 ProjectionReg 改由 lua 實現 pattern 轉換   preedit_format commit_format
* inspect.lua -- 源自 luarocks 安裝 
* json.lua  -- 源自 luarocks 安裝
* luaunit.lua testunit  -- 源自 luarocks 安裝
     
## test luaunit 測試資料夾


