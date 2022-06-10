# librime-lua-script 是一個利用 librime-lua 擴展 rime 輸入法的集成模組
  此模組須使用 librime-lua #131以上版本[下載rime.dll](https://github.com/shewer/librime-lua/releases )
  init_processor.lua 為主要載入程式，使用者可以修改 processor_plugin.yaml 調整載入模組、設定模組熱鍵及參數(詳見該檔)；支援自載lua module 以省去再編輯rime.lua，井且支援載入失敗時提供救援程式繞過錯誤模組，錯誤模組名將存於 property:_error中(使用command module 輸入 /p:_error ) 。
  ex:
    lua_translator@date@date1 -- module_name: date  name_space: date1
    lua_translator@date -- module_name: date  name_space: date
    -- 檢查lua 環境是否存在 date 如果沒有將會試載入 date = [require](require)('date') or require('component/date')
  * 英打模組:增加 [ecdict.csv](https://github.com/skywind3000/ECDICT)字典
  * 英打模組:增加自動編譯固態字典檔以改善載入字典時間(減少90%時間)，共用字典table 減少記憶體使用及再次載入時間
  * 以詞定字: select_character [以词定字](#以词定字)上屏模组
  * 聯想詞輸入模組: 
  * 英打+英文字典模組: 
  * 主副字典反查模組: 此模組會查找 script_translator table_translator 可反杳方案內的字典
  * 命令模組: 此模組可以在輸入模式 set & get option property config 及執行function
  * 載入程序: 以上模組都可以獨立手動載入也可以利用, init_processor.lua 把需要載入模組設定於 <name_space>/modules: {list}. 預設以此模式[安裝](#安裝)。
  
  


  # 安裝
   新增簡體版本設定檔( customize_cn.recipe.yaml , processor_plugin_cn.yaml )
   window 版本請更換 rime.dll 至 librime-lua #131. 
  
  ## plum 安裝至方案中
  
  ```bash
    # plugin in cangjie5 
    rime-install shewer/librime-lua-script@main:customize:schema=cangjie5
    echo 'init_processor= require("init_processor")' >> rime.lua 
    # 簡體
    #rime-install shewer/librime-lua-script@main:customize_cn:schema=cangjie5
    #echo 'init_processor= require("init_processor")' >> rime.lua 
    
  ``` 
  
  ## 手動安裝事前準備
  ```bash
  cd  <user-data-dir>
  git clone https://github.com/shewer/librime-lua-script --depth=1
  cp librime-lua-script/lua/*  ./lua -a
  cp librime-lua-script/processor_plug* .
  cp librime-lua-script/essay_cn.txt .
  echo 'init_processor = require("init_processor")' >> rime.lua
  ```

  ## 方案設定
  將以下文稿 yaml 加入 <schema>.custom.yaml
  ```yaml
  __patch:
  # Rx: shewer/librime-lua-script:customize:schema=whaleliu_ext {
    - patch/+:
        __include: processor_plugin:/patch      # 繁體
        #__include: processor_plugin_cn:/patch  # 簡體
  # }
  ```

  # 使用說明
  ## init_processor
    init_processor 提供載入 sub_module 及 功能，詳見 init_processor name_space
    init_processor 將檢查 engine 下 lua_component 是否載入lua環境中，井嘗試載入
    
  ### 操作
    * /ver : commit_text ver 
    * /modules : commit_text 載入模組
    * /comps : commit_text engine components
    * /cal: commit_text 月曆
    * Control+F12: commit_text menu candidate 
    * Shift+F12: commit_text key:repr() ，在option "_debug" enable 時可以送出 鍵名字串
  
   
  ## command 模組
    使用 input 設定及查詢相關環境, /c + /f:reload 可以做動態設定環境
    
  ### 操作
    * "/o:" : set option  ex: toggle _debug ， /o:_debug{space}, set true /o:_deb{Tab}:true{space}
    * "/p:" : set property 同上
    * "/c:" : set config  ex: /c:eng{Tab}/tran{Tab}/@1:script_translator{space} 設定engine/translations/@1字串
    * "/f:" : execute function ex: /f:relo{space}, /f:me{Tab}:5{space} 調整menu/page_size
  
  ## 以詞定字母
    此模組 可以將詞組拆選井反查單字字根 ，用于单字不会拆时，選中詞組候選輸入 [ or ] 進入此模式 space 上屏。可以導入 lua_translator@select_character_tran 增加符號輸入
    
  ### 操作
    * "[": 由左向右選字
    * "]": 由右向左選字
    * "[1-0" "]1-0": 直接選字
    * /emj :  符號表選字 ex: /emj{Next}{Next}4 第三候選 第四字
    * /sma /smb /smc : 同上
  
  ## 英文 字典+英打模式，支援 Tab 補齊功能 及 wordninja
  
    * **注意** win10部份單字的comment 會造成崩潰，需要remark單字，linux 無此問題可以把 tools/english_tw.txt 內 "#" 移除
    *  英打模式: F10
    *  comment 格式切換: Shift+F10
    *  支援 * / 字尾字根  /i ing /n ness /l less  /t tion /s sion /a able
    *  詞類     :adv  :vt :v ....
    *  空白鍵上屏井補上 空白字元
    *  增加短語字典 lua/english/ext_dict.txt , 輸入短語字串時(cand.type == "english_ext")  按下 Tab 時交換 cand.text cand.coment
    *   ex: input: btw   candidate:  btw [by the way]  candidate: by the way [btw]
    *   english/tag 預設 english : 如果須要在 tag:abc 輸出，可以在 english/tag: abc   or  abc_segmentor/extra_tags: [ english ]
    *  english_tran.lua 增加 優先載入 wordnanja-rs  , 只要把 wordninja.(dll/so/dylib) 放入 <user_data_dir>/lua/plugin
    *  支援 camel upper case 轉換  
    *  字典初始化請提前製作 
  
  
  
```lua
-- 手動初始化固態字典 ，在<user_data_dir/lua 執行
-- lua -e 'ENG=require("tools/english_dict"); Eng("ecdict") ;Eng("english")' 
-- @ <user_data_dir>/compiler.lua   
Eng=require('tools/english_dict')
Eng('ecdict') -- 如果找不到了 ecdict.txtl  換找 .txt or .csv  製作 .txtl (固態字典)
Eng('english')
Eng('english_tw')
```
      
  
  ## 反查模組
    自動載入 table script translator 反查filter，免去設定 
  ### 操作
    * Ctrl+6 反查開關
    * ctrl+7 反查碼顯示最短碼開關 較適合table_translator
    * ctrl+8 未完成碼上屏開關 -- 過濾 completion cand
    * Ctrl+9 反查碼filter 切換(正)
    * Ctrl+0 反查碼filter 切換(負)
 
  ## 聯想詞彙
   * 增加候選字聯想: 暫時不適用( 拼音類輸入法 候選字太多 )
   * conjunctive 增加 导入switchs: simplifier 切换繁简体词库, 須要提供 詞庫文檔， 己提供預設 essay_cn.txt, 修改 processor_plugin[_cn].yaml:conjunctive/files: [ file1.txt, file2.txt] 可以使用其他詞庫
  聯想開關(F11)
   * ~ 觸發聯想
   * [><~] : 刪字 ~ < 刪字尾 > 刪字首，變更時下面聯想詞也會更新重組， 織 backspace 恢復上一字元 space 變更 env.history
      C : 清除 space 變更 env.history=""
      B : 還原上次異動 space 變更 env.history= env.history_back
      H : user 常用詞 選屏上字
 
  ## debug 模式
    提供顯示candidate info 於 comment 
    
    * "/o:_debug" : debug 開關
    * "/p:_debug" : 設定顯示項目 dtype,type,start,_end,preedit,quality,input,ainput,error 
    ```
    (鯨)木十弓	 [tags: vcode cangjie5liu newcjliu abc]
    ->檸	--Phrase|table|0|3|(鯨)木十弓|1.7018|tjk|tjk|
      柠	--Phrase|table|0|3|(新)木十弓|1.4000|tjk|tjk|
      𪜑	--Phrase|table|0|3|(倉)木十弓|1.3000|tjk|tjk|
      末了	--Phrase|table|0|3|(鯨)木十弓|1.5000|tjk|tjk|
      檸檬	[聯]--Simple|history|0|3|檸檬[聯]|0.0000|tjk|tjk|
      檸檬汁	[聯]--Simple|history|0|3|檸檬汁[聯]|0.0000|tjk|tjk|
      檸檬酸	[聯]--Simple|history|0|3|檸檬酸[聯]|0.0000|tjk|tjk|
      檸檬茶	[聯]--Simple|history|0|3|檸檬茶[聯]|0.0000|tjk|tjk|
      檸檬水	[聯]--Simple|history|0|3|檸檬水[聯]|0.0000|tjk|tjk|
      檸檬片	[聯]--Simple|history|0|3|檸檬片[聯]|0.0000|tjk|tjk|

    ```
    
  ## 筆劃數 stroke_count
    利用 stroke字典計算筆劃數井加入 comment,此功能須要stroke.reverse.db ，使用 option: "stroke_count" 開關此功能(ex: /o:stro{Tab}{space} ) 
    ```
    (鯨)木十弓	 [tags: vcode cangjie5liu newcjliu abc]
    ->檸	(總:18:18)--Phrase|table|0|3|(鯨)木十弓|1.7018|tjk|tjk|
      柠	(總:9:9)--Phrase|table|0|3|(新)木十弓|1.4000|tjk|tjk|
      𪜑	(總:6:6)--Phrase|table|0|3|(倉)木十弓|1.3000|tjk|tjk|
      末了	(總:7:5,2)--Phrase|table|0|3|(鯨)木十弓|1.5000|tjk|tjk|
      檸檬	[聯](總:35:18,17)--Simple|history|0|3|檸檬[聯]|0.0000|tjk|tjk|
      檸檬汁	[聯](總:40:18,17,5)--Simple|history|0|3|檸檬汁[聯]|0.0000|tjk|tjk|
      檸檬酸	[聯](總:49:18,17,14)--Simple|history|0|3|檸檬酸[聯]|0.0000|tjk|tjk|
      檸檬茶	[聯](總:44:18,17,9)--Simple|history|0|3|檸檬茶[聯]|0.0000|tjk|tjk|
      檸檬水	[聯](總:39:18,17,4)--Simple|history|0|3|檸檬水[聯]|0.0000|tjk|tjk|
      檸檬片	[聯](總:39:18,17,4)--Simple|history|0|3|檸檬片[聯]|0.0000|tjk|tjk|
    ```

