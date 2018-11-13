#!/bin/bash -eu

if [ $# -gt 0 ]; then
    if [ $1 = "-h" ]; then
        echo "usage: $0 [ -q ]"
        echo "  -q: 'quiet' mode; report only unsoundness"
        echo ""
        exit 0
    fi
fi

quiet=0
if [ $# -gt 0 ]; then
    if [ $1 = "-q" ]; then
        quiet=1
    fi
fi

dirs=($(find CWE* -name GNUmakefile | sed s/GNUmakefile// | sort))

for d in ${dirs[@]}; do
    if compgen -G "$d/*.res" > /dev/null; then
        num_c_tests=$(ls $d/*.res | wc -l)
        echo "${d%/}: $num_c_tests tests"
        if [ $quiet -eq 1 ]; then
            cat $d/*.res | cut -d: -f2 | sort | uniq -c | grep unsound || true
        else
            cat $d/*.res | cut -d: -f2 | sort | uniq -c
        fi
    else
        echo "${d%/}: 0 tests"
    fi
done
