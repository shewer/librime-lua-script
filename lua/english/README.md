# Rime English輸入方案

本方案爲實現於Rime Weasel中文模式下輸入英文單詞而製作，所有功能均使用lua插件实现，請下載[Rime Weasel 0.14.3.148](https://bintray.com/rime/weasel/testing),librime-lua dll file(https://ci.appveyor.com/project/hchunhui/librime-lua/builds/35684423/artifacts) 。

![computer](demo/computer.gif)

## 功能說明：

- 在中文模式下增加 english 開關模式  {F10}
- 長字典 展開 開關 - {F9}
- comment 顯示模式 - {Control+F9}    音標  翻譯  關閉 
- 支持大小寫混合輸入，候選單詞自動匹配。輸入模式儘量符合 英打模式 
- 在輸入過程中可使用通配符查詞   ？單字母 * 多字母 ex: be*ful 
- 符號或空格直接連候選詞一齊上屏，數字選字上屏 Tab complation function ex: be*ful Tab => beautiful
- 中文輸入法使用"朙月拼音"，請自行更改
- 增加 english_plugin.yaml   可於 schema_name.custom.yaml  patch 
- 增加 熱鍵 補上 *ing *able *tion *ful *tion  ....  (可在 english_dict.lua 增加 字根 )  Tab 補齊 Shift-Tab 返迴上次 text 
- 增加 怏鍵 補上 *ing *able .....   ( ex auto/n --> auto*tion ) 
- 增加 詞類 篩選  :v :a :n :adv(ad*) pre* pro* :pl :v :vt :vi   ( ex auto:a -- auto*| filter  n. )
- 熱鍵修改  lua/english/init.lua  
- 字根是由 table key 定義 可在 lua/english/english_dict.lua  增修
- bug:  windows rime : 字典 comment 字串太長，會關閉APP ，可在 english.txt or english_tw.txt 查找中斷點 ，
把長字串   用# remark 


  

## 安裝說明.
- git clone https://github.com/shewer/librime-lua-tools $USERDATA/lua/tools
- git clone https://github.com/shewer/rime-english    $USERDATA/lua/english
- cp  lua/english  $Rime/USERDATA/lua/english
- cp  lua/tools    $Rime/USERDATA/lua/tools
- cp  lua/english/english_plugin.yaml  $Rime/USERDATA
- 
- edit rime.lua  
  ```lua 
  --  載入 function 
  --  將  { processor= { fini, init , func} ,translator={fini,init,func} .....}  載入全域
  load_module=require('tools/loadmodule')
  --  --load_module.load( 'module' , lua_component name, args ....)
  --    require 'lua/english/init.lua   ,
  --    lua_processor@english_processor ,  lua_segmentor@english_segmentor .....
  
  --    module args   'english_tw.txt'   字典檔    word\t[音標]; 翻譯  ......   \t
  load_module.load('english','english',"english_tw.txt") --  module , target_name , dict_file
  
  
  
  ```
- custom.yaml
  ```yaml
  patch:
	  __include: english_plugin:/patch
  ```

## 詞典制作：
- 詞典來源於[skywind3000 ECDICT](https://github.com/skywind3000/ECDICT)
- 提供EXCEL文件<english.dict.xlsx>用於同步ECDICT及製作yaml詞典文件

