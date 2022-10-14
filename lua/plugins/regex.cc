#include <boost/regex.hpp>
#include <iostream>
using namespace std;

#ifdef __cplusplus
extern "C" {
#endif

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
typedef void Register(lua_State*);

  static int regex_match(lua_State* L){
    if (2 > lua_gettop(L)) return 0;
    const string target( lua_tostring(L,1) );
    boost::regex reg( lua_tostring(L, 2) ) ;
    bool res = boost::regex_match( target, reg );
    lua_pushboolean(L, res);
    return 1;
  }

  static int regex_replace(lua_State* L) {
    if (3 > lua_gettop(L)) return 0;
    const string target( lua_tostring(L, 1) );
    boost::regex reg( lua_tostring(L, 2) );
    const string fmt( lua_tostring(L,3) );
    string res = boost::regex_replace(target, reg, fmt);
    lua_pushstring(L, res.c_str());
    return 1;
  }

  static int regex_search(lua_State *L) {
    if (2 > lua_gettop(L)) return 0;
    const string target( lua_tostring(L, 1));
    boost::regex reg( lua_tostring(L, 2) );
    boost::smatch what;
    if (boost::regex_search(target,what, reg)) {
      lua_newtable(L);
      for (int i=0; i< what.size(); i++) {
        lua_pushstring(L, what[i].str().c_str() );
        lua_rawseti(L, -2,i+1);
      }
      return 1;
    }
    return 0;

  }

  static const struct luaL_Reg funcs[] =
  {
    {"match", regex_match},
    {"replace", regex_replace},
    {"search", regex_search},
    {NULL, NULL},
  };

  int luaopen_regex(lua_State* L){
    luaL_newlib(L, funcs );
    return 1;
  }

#ifdef __cplusplus
}
#endif
