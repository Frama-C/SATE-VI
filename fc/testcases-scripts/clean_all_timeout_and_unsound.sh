#!/bin/bash -u

for f in $(find . -name "*.res"); do
    grep -q 'unsound\|timeout' "$f"
    if [ $? -eq 0 ]; then
        echo "rm $f"
        rm "$f"
    fi
done
