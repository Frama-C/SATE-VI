#!/bin/bash -eu

dirs=($(find CWE* -name GNUmakefile | sed s/GNUmakefile//))
parallel --linebuffer --verbose 'cd {} && make clean' ::: ${dirs[@]}
