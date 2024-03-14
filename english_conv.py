#! /usr/bin/env python3
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2022 Shewer Lu <shewer@gmail.com>
#
# Distributed under terms of the MIT license.

"""
  pip3 install leveldb luadata

"""
import os
import sys
import csv
import leveldb
import luadata
import re
def __convert_dict_(rec):
    if rec[0] == '#':
        return
    res= {}
    res['word'],data = line.strip().split('\t',1)
    ll= data.split(';',1)
    if len(ll)>1:
       res['phonetic'] = ll[0]
       res['translation']= " " + ll[1]
    else:
       res['phonetic'] = ''
       res['translation']= " " + ll[0]
    return res

def get_key_str(dict):
    key = dict and dict.get('word')
    if not key or len(key) ==0 or  key[0] == '#':
        return
    return  key  if key.islower() else key.lower() + "\t" + key

#  rec:  type   dict  or  text format
def convert_chunk(rec):
    if isinstance(rec, str):
        rec = __convert_dicti_(rce)
    if not rec:
        return

    rec['translation'] = re.sub(r'^(\w+\.\s)',' \\1', rec['translation'])
    rec['definition'] = re.sub(r'^(\w+\.\s)',' \\1', rec['definition'])
                                
    key = get_key_str(rec)
    if not key:
        return
    tmp= { k: re.sub(r'(\\[rn])+','\n',v) for k,v in rec.items()}
    if len(tmp['phonetic']) > 0:
           tmp['phonetic'] = ('[{}]').format(tmp['phonetic'])
    return key, luadata.serialize(tmp).replace('\\\n','\\n')

class LuaChunk:
  def __init__(self, name):
      self.__name = name
      self.__fn = open(self.__name,'w')
      self.__status = True
      self.__fn.write("return {\n")
  def status(self):
      return self.__status
  def name(self):
      return self.__name
  def __del__(self):
      if self.__status:
          self.close()
  def Flush(self):
      if self.__status:
          self.__fn.flush()
  def close(self):
      if self.__status:
          print('close file: ' + self.__name )
          self.__fn.write("}\n")
          self.__fn.close()
          self.__status = False
  def Put(self,key, value):
      if self.__status:
          self.__fn.write( ('{},\n').format(value.decode()))


def __main(fname,fmt):
    """TODO: Docstring for main.
    :returns: TODO
    python conv_file.py  file.[txt|csv]  [leveldb|chunk] -- default: luac compile to chunk_bin

    """
    try:
        f,ext = os.path.splitext(fname)
        db = leveldb.LevelDB(f + ".userdb") if fmt =='leveldb' else LuaChunk(f + '.txtl')
        with open(fname) as fnode:
           inf = csv.DictReader(fnode) if ext=='.csv' else fnode
           for row in inf:
               key_str, chunk_str=convert_chunk(row)
               if  key_str and chunk_str :
                   db.Put(key_str.encode('utf-8'),chunk_str.encode('utf-8'))
           del db
    except ValueError as ve:
        return str(ve)


if __name__ == '__main__' :

    print(sys.argv,len(sys.argv))
    if len(sys.argv) <2:
        print('help : python english_conv.py  filename  [chukn|lezeldb] default: chunk_bin ')
    else:
        fn= sys.argv[1]
        fmt= len(sys.argv)>2 and sys.argv[2] 
        sys.exit(__main(fn,fmt))

