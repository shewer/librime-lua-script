-- uniquify
-- yaml
-- uniquify:
--   tags:
--   reject_tags: 
--  uniquify 不支援 tags 此部件可以使用 tags or reject_tags 設定
--  tags == Set 就沒有 reject_tags 二擇一
--
--
--  lua_filter@uniquify 只支援 match_tags() 功能  2021/07/17 更新
--  未設定 tags 表示 all tags 此時 可用 reject_tags  來reject 包含 reject_tags 的 segment
--  所以 要被reject 的segment 要只能一佪 tag 否則會 連同 其他 tags 也 reject 此 filter
--  
--  也可以動態增減 tags 
--  context:set_property( name_space, "+abc") 
--  context:set_property( name_space, "-abc") 
--  context:set_property( name_space, "+ENABLE")  -- set env.enable = true (default true)
--  context:set_property( name_space, "-ENABLE")  -- set env.enable = false 
--  context:set_property( name_space, "+ALL")  -- set env.all= true
--  context:set_property( name_space, "-ALL")  -- set env.all = false 
--  
--  env.tags == nil   +tag  -tag  只會增減 reject_tags
--  env.tags == Set   +tag  -tag  會增減 tags 
--
--
--


-- version check for lua_filter { tags_match= function(seg,env)  }
if not ConfigMap().keys then  
  log.warning( "lua_filter@uniquify not support this version"  )
end 

local List=require'tools/list'
local function get_tags(config,path)
  local list=List()
  for i=0,config:get_list_size(path) -1 do 
    list:push( config:get_string(path .. "/@" .. i ) )
  end 
  return #list > 0 and Set( list ) or nil
end 


local function set_tags(env, ptag_str)
  local opt,tag_str = ptag_str:match("^([+-])([%a_]+)$")
  if not opt then return end 
  if tag_str == "ENABLE" then 
    env.enable = opt == "+" 
    return 
  elseif tag_star == "ALL" then
    env.all  = opt == "+"
  else
    local tag = Set({tag_str})
    -- env.tags == nil  all tags is match
    if env.tags then 
      env.tags = opt== "-" and env.tags - tag or env.tags + tag
    else 
      env.reject_tags =  opt == "-"  and env.reject_tags  + tag or  env.reject_tags - tag
    end 
  end 
end 


local M={}
function M.init(env)
  local context=env.engine.context
  local config=env.engine.schema.config
  env.enable = true
  env.all = false 
  env.tags =  get_tags(config, env.name_space .. "/tags")  
  env.reject_tags =  env.tags == nil  and get_tags(config, env.name_space .. "/reject_tags") or Set({}) 
  env.property= context.property_update_notifier:connect(
  function(ctx,name) 
    if name=="uniquify" then 
      set_tags(env,ctx:get_property(env.name_space) )
    end
  end)
end 

function M.fini(env)
  env.property:disconnect()
end 
function M.tags_match(seg,env) 
  env.version_chk= true -- check version 
  -- ENABLE 
  if not env.enable then return false end 
  -- ALL 
  if env.all then return true end 
  -- NORMAL 
  if not env.tags then
    for k,v in next ,env.reject_tags do 
      if seg:has_tag(k) then return false end  
    end 
    return true
  else 
    for k,v in next, env.tags do 
      if seg:has_tag(k) then return true end 
    end
    return false 
  end 
  return true
end 

function M.func(tran,env)
  if not env.version_chk then 
    log.warning( "lua_filter@uniquify not support this version"  )
  end 
  local uniquify_key={}
  for cand in tran:iter() do 
    if  not uniquify_key[cand.text] then 
      uniquify_key[cand.text]  = true
      yield(cand)
    end 
  end 
end 




return M

