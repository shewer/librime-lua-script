#! /bin/sh
#
# complie_dict.sh
# Copyright (C) 2022 Shewer Lu <shewer@gmail.com>
#
# Distributed under terms of the MIT license.
#
echo help: compile_dict file1 file2 .....
stty -echo
function dict_compile(){
  echo === cimpile $1 ===
  if [ -f $1 ]; then 
    # sort  k1 column -f ignor case 
    echo sorting $1 .........
    LC_ALL=C sort -k 1 -f -o $1 $1

    LUA_CODE="
    package.path= package.path .. \";../?.lua\"
    E=require \"english_dict\"
    chunk_bin=true
    e=E(\"${1%.*}\")
    e:make_chunk()
    "
    
    lua -e "$LUA_CODE"
    return $?
  fi 
  return 1
}
for a in $* ;do dict_compile $a ; done

stty echo
