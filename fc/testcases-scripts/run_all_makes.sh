#!/bin/bash -eu

exit_on_signal() {
    echo "sigint received, aborting."
    rm -f running_make_all.txt
    exit 1
}
trap exit_on_signal INT


dirs=($(find CWE* -name GNUmakefile | sed s/GNUmakefile//))
touch running_make_all.txt
(parallel --linebuffer --verbose 'cd {} && make -k -j 4' ::: ${dirs[@]} | tee output.txt; rm -f running_make_all.txt) &

count=0
while [ -f running_make_all.txt ]; do
    sleep 5
    count=$((count+5))
    printf "\n***** PROCESSING (${count} s)... tested $(grep testing output.txt | wc -l) files *****\n\n"
done
