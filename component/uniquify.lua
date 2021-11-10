local List=require'tools/list'
local function get_tags(config,path)
  local list=List()
  for i=0,config:get_list_size(path) -1 do 
    list:push( config:get_string(path .. "/@" .. i ) )
  end 
  return list
end 

local M={}
function M.init(env)
  local context=env.engine.context
  local config=env.engine.schema.config


  env.match_all = config:is_null(env.name_space .. "/tags")
  env.tags = env.match_all and List() or get_tags(config,path )
  env.reject_tags=  List{} 
  env.match_type={history=true}



end 

function M.fini(env)

end 

function M.func(tran,env)
  local uniquify_key={}
  for cand in tran:iter() do 
    if env.match_type[cand.type] then 
      yield( cand )
    elseif  not uniquify_key[cand.text] then 
      uniquify_key[cand.text]  = true
      yield(cand)
    end 
  end 
end 
function M.tags_match(seg,env) 
  if env.match_all then
    env.reject_tags:each(function(elm) seg:has_tag(elm) end  )
  else 

  end 
  return true

end 




return M

