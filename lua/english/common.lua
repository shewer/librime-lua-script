local is_unix = package.config:sub(1,1) == "/"

return {
  component_config= true, --自動設定 segment translato ... 
  -- user setting
  keys_binding= {
    toggle="F10",
    comment_mode="Control+F10",
    completion="Tab",
    completion_back="Shift+Tab",
    completion_back1="Shift+ISO_Left_Tab",
  },     
  comment_mode_default = 0,--comment 顯示模式
  prefix_pattern = "![a-zA-z?*-_/:]*$",
  prefix= "!", -- 使用前綴碼觸發
  splite_char1 = "/", -- 字身碼
  splite_char2 = ":", -- 詞類碼
  tag = "english",
  enable_njdict = true, -- 啓用 word_ninja
  enable_ext_dict = true, -- 啓用 user 字典
  ext_dict = "ext_dict", -- 

  -- cosnst var 
  unix_os = is_unix,
  win_os = not is_unix,
  property_name = "english_comment_mode",
  NR = is_unix  and "\n" or "\r"



}
