#!/usr/bin/env bash



set -e

PROJECT=hashcrack

# pushd cuda-ssl
#     make md5.o
# popd 

pushd crunch-3.6
    make
    ./crunch 1 1 -f charset.lst lalpha-numeric -o ../wordlist.txt
popd 

make "$PROJECT.run"
./"$PROJECT.run"