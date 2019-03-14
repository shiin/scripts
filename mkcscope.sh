#!/bin/bash

if [ -d cscope.files ]; then
    rm cscope.files
fi

ctags -R
find . -name *.[chx] -o -name *.cpp -o -name *.cc -o -name *.hh -o -name *.S -o -name *.s > cscope.files
