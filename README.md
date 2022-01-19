# librime-lua-script 是一個利用 librime-lua 擴展 rime 輸入法的集成模組
  此模組須使用 librime-lua #131以上版本[下載rime.dll](https://github.com/shewer/librime-lua/releases )
  * 以詞定字: select_character [以词定字](#以词定字)上屏模组
  * 聯想詞輸入模組:
  * 英打+英文字典模組:
  * 主副字典反查模組: 此模組會查找 script_translator table_translator 可反杳方案內的字典
  * 命令模組: 此模組可以在輸入模式 set & get option property config 及執行function
  * 載入程序: 以上模組都可以獨立手動載入也可以利用, init_processor.lua 把需要載入模組設定於 <name_space>/modules: {list}. 預設以此模式[安裝](#安裝)。

  # 安裝
  ## 事前準備
  ```bash
  cd  <user-data-dir>
  git clone https://github.com/shewer/librime-lua-script --depth=1
  mv librime-lua-script/*  ./lua
  cp lua/example/processor_plugin.yaml .
  cp lua/example/essay-zh-hans.txt .
  ```

  ## 設定方法一 : 使用 yaml 設置
  
  append init_processor module in rime.lua 
    
  ```lua
  -- append rime.lua
  init_processor= require('init_processor')
  ```
  add to <方案>.custom.yaml
      
  ```yaml
  #custom.yaml
  patch:
    __include: processor_plugin:/patch
  ```
    
  edit processor_plugin.yaml
    
  ```yaml
  # processor_plugin.yaml 內容
  # 可自行 remark 不要用的模組
  # select_character 以詞定字
  # command   命令模式
  # english   英打
  # conjunctive 聯想模式
  # multi_reverse 主副字典反查模組
  #
  patch:
    engine/processors/@after 0: lua_processor@init_processor@module1
      module1/modules:
        #  以詞定字  name_space: 可指定其他有 dictionary 反查 單字字根 (ex: cangjin5/dictionary)
        - { module: 'component/select_character', module_name: 'select_character', name_space: "translator" }
        - { module: 'command'      , module_name: "cammand_proc"       , name_space: "command" }
        - { module: 'english'      , module_name: "english_proc"       , name_space: "english" }
        - { module: "conjunctive"  , module_name: "conjunctive_proc"   , name_space: "conjunctive" }
        - { module: 'multi_reverse', module_name: "multi_reverse__proc", name_space: "multi_reverse" }

  ```

 ## 設定方法二: 由 rime.lua module2 載入
    
   append init_processor module in rime.lua
    
   ```lua
   -- append rime.lua
   module2={
     {module='command', module_name="cammand_proc",name_space="command" },
     {module='english', module_name="english_proc",name_space="english" },
     {module="conjunctive", odule_name = "conjunctive_proc",name_space="conjunctive"},
     { module= 'multi_reverse', module_name= "multi_reverse__proc", name_space= "multi_reverse" },
   }

   init_processor= require('init_processor')
   ```
   
   add to <方案>.custom.yaml

   ```yaml
   #custom.yaml
   patch:
     engine/processors/@after 0: lua_processor@init_processor@module2 # module2
   
   ```

# 增加 init_processor.lua
  使用了 tags_match() and ConfigMap:keys() 只支援 librime-lua #131 以上版本 window版本rime.dll 可從 https://github.com/shewer/librime-lua/releases 下載
  可由 yaml name_space 或 rime.lua 載入模組(以 yaml name_space 爲優先)

  由 init_processor 導入模組
  可用模組 english(包含wordninja) conjunctive command
  化簡繁複 custom.yaml rime.lua 編輯
  
  ## 以词定字
 此模組 可以將詞組拆選井反查單字字根 ，用于单字不会拆时~~
  ![Alt Text](https://github.com/shewer/librime-lua-script/blob/main/example/%E4%BB%A5%E8%A9%9E%E5%AE%9A%E5%AD%97.gif)


  注意: Shadow Candidate（如繁簡轉換後) 無法變更 text preedit comment 所以無法顯示，但是定字上屏仍然有效.可以用[ + number 直接選字上屏

  觸發條件  對選中的candidate 詞長>1  and  NEXT_KEY PREV_KEY

  引用資料
     * <name_space>/dictinary : 調用反查字典  預設: translator/dictionary
     * <name_space>/preedit_fromat: 單字字根轉置 預設: translator/preedit_format
     * 可以利用 name_space 選用其他反查字典及 preedit_format
     * <name_space>/next_key  NEXT_KEY  : 觸發鍵   預設: '['
     * <name_space>/prev_key  PREV_KEY  : 觸發鍵   預設: ']'
###獨立安裝

```lua
--rime.lua
-- module_name
selcet_character = require 'component/select_character'
```


```yaml
#<config>.custom.yaml
#lua_processor@<module_name>@<name_space>
patch:
   engine/processors/@after 0: lua_processor@select_character@translator
   #translator/next_key: "<" #  default: [
   #translator/prev_key: ">" #  default: ]
```


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


  ![Alt Text](https://github.com/shewer/librime-lua-script/blob/main/example/%E5%91%BD%E4%BB%A4%E6%A8%A1%E5%BC%8Fdemo.gif)


  ## english 英文字典模組 支援 Tab 補齊功能 及 wordninja
    * **注意** win10部份單字的comment 會造成崩潰，需要remark單字，linux 無此問題可以把 tools/english_tw.txt 內文
      "#" 移除
    * 英打模式 F10
    * 支援 * / 字尾字根  /i ing /n ness /l less  /t tion /s sion /a able
    * 詞類     :adv  :vt :v ....
    * 空白鍵上屏井補上 空白字元
    * 增加短語字典 lua/english/ext_dict.txt , 輸入短語字串時(cand.type == "english_ext")  按下 Tab 時交換 cand.text cand.coment
      ex: input: btw   candidate:  btw [by the way]  candidate: by the way [btw]


 ![Alt Text](https://github.com/shewer/librime-lua-script/blob/main/example/%E8%8B%B1%E6%89%93%E6%A8%A1%E5%BC%8Fdemo.gif)




## multi_reverse 主副字典反查(新版)  支持 librime-lua  新架構可能造成失效待修正
自動導入 engine/translators/   script_translator table_translator   反查 lua_filter
### 反查字典切換
* Ctrl+6 反查開關
* ctrl+7 反查碼顯示最短碼開關 較適合table_translator
* ctrl+8 未完成碼上屏開關  -- 過濾 completion cand
* Ctrl+9 反查碼filter 切換(正)
* Ctrl+0 反查碼filter 切換(負)
![Alt Text](https://github.com/shewer/librime-lua-script/blob/main/example/%E4%B8%BB%E5%89%AF%E5%AD%97%E5%85%B8%E5%8F%8D%E6%9F%A5demo.gif)
### 安裝獨立加載 模組

* rime.lua

```lua
multi_reverse_proc = require 'multi_reverse'    -- 載入 multi_reverse_processor multi_reverse_filter
assert( multi_reverse_processor)
```

* schema_id.custom.yaml

```
patch:
   engine/processors/@after 0: lua_processor@multi_reverse_proc@multi_reverse

```

## 聯想詞彙 conjunctive.lua (支援librime-lua Commits on Oct 11, 2020 版本)
   * conjunctive 增加 导入switchs: simplification 切换繁简体词库 [已修正格式 essay-zh-hans.txt ]  来源https://github.com/rime/rime-essay-simp
    简体用户 如果使用此功能注意事項:
       1 只使用簡體詞庫: 請確認 essay.txt 是簡體版 
       2 切換繁簡都要有聯想功能: essay.txt 使用原始 繁體版，把簡體版檔名: eassy-zh-hans.txt
   * 上屏後啓動聯想
   * 聯想開關(F11)
   * ~ 觸發聯想
     * [><~] : 刪字 ~ < 刪字尾   > 刪字首，變更時下面聯想詞也會更新重組， 織 backspace 恢復上一字元  space 變更 env.history
     * C : 清除 space 變更 env.history=""
     * B : 還原上次異動 space 變更 env.history= env.history_back
     * H : user 常用詞 選屏上字
![Alt Text](https://github.com/shewer/librime-lua-script/blob/main/example/%E8%81%AF%E6%83%B3%E8%A9%9Edemo.gif)

### 單獨安裝

```lua
--- rime.lua
-- <module_name> 
conjunctive_proc= require('conjunctive')
```
```yaml
---  custom.yaml
patch:
  # lua_processor@<module_name> 
  engine/processors/@after 0: lua_processor@conjunctive_proc

```
    
```bash
cp example/essay-zh-hans.txt <user_data_dir>/essay-zh-hans.txt
```

使用 option simplification 判断繁简模式

```yaml
# 请确认方案是否设定 simplifier
engine/filters:
  - simplifier
switches:
  - name: simplification
    states: [ 漢字,汉字 ]
simplifier/opencc_config: s2t.json   # 简体用户
simplifier/opencc_config: t2s.json   # 繁体用户  (預設值 可以不設)
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
local dict_file= 'essay.txt' -- 此为繁体字版  要用简体字可复制example/essay_cn.txt 到 <user_data_dir> 井修改此档名
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


