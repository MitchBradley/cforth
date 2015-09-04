#!/bin/bash

cd `dirname $0`

bin_file=`osascript -e 'POSIX path of ( choose file with prompt "Backspin Binary File" default location "." )'`

if [ ${bin_file##*.} != "bin" ]; then
   echo Please select a filename like backspin\*.bin
   sleep 4
   exit
fi

./forth backspin-programmer.dic -s "program-backspin: ${bin_file}"


