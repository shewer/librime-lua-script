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
def load_csv(csvf):
    l = []
    with open(csvf, newline='') as csvfile:
        rows= csv.DictReader(csvfile)
        for row in rows:
            if row['word'][0] == '#':
                continue
            if row['phonetic'] != "":
                row['phonetic'] = '[' + row['phonetic'] +  ']'
            l.append(row)

    return l

def load_text(textf):
    l=[]
    with open(textf,newline='') as textfile:
        for line in textfile.readlines():
            if line[0] == '#':
                continue
            row = {}
            word,data = line.split('\t',1)
            row['word']=word
            ll= data.split(';',1)
            if len(ll)>1:
                row['phonetic'] = ll[0]
                row['translation']= ll[1]
            else:
                row['translation']= ll[0]
            l.append(row )

    return l

def write_chunk(filename,rows):
    with open(filename,'w') as fn:
        fn.write('return {\n')
        for row in rows:
            value= luadata.serialize(row) #.replace('\\n','\n').replace('\\r','\r')
            fn.write(value + ',\n')
        fn.write('}\n')

def write_leveldb(filename,rows):
    db = leveldb.LevelDB(filename,create_if_missing=True)
    for row in rows:
        key = row['word']
        if not key:
            continue

        if re.findall('[A-Z]',key):
            key = key.lower() + '\t' + key

        value= luadata.serialize(row).replace('\\n','\n').replace('\\r','\r')
        db.Put(key.encode('utf-8'),value.encode('utf-8'))






def main(fn,fmt):
    """TODO: Docstring for main.
    :returns: TODO
    python conv_file.py  file.[txt|csv]  [leveldb|chunk] -- default: luac compile to chunk_bin

    """
    try:

        f,ext = os.path.splitext(fn)
        rows = ext == ".csv" and  load_csv(fn) or load_text(fn)
        if fmt== 'leveldb':
            write_leveldb(f,rows)
        elif fmt == 'chunk':
            write_chunk(f + '.txtl', rows)
        else:
            write_chunk(f + '.txtll',rows)
            print("compile to bin ")
            os.system( 'luac -o '+ f + ".txtl " + f + ".txtll && rm " + f +".txtll" )


    except ValueError as ve:
        return str(ve)



if __name__ == '__main__' :

    print(sys.argv,len(sys.argv))
    if len(sys.argv) <2:
        print('help : python english_conv.py  filename  [chukn|lezeldb] default: chunk_bin ')
    else:
        fn= sys.argv[1]
        fmt= len(sys.argv)>2 and sys.argv[2] 
        sys.exit(main(fn,fmt))

