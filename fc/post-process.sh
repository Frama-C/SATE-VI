#!/bin/bash -eu

# Post-processes results after analyze.sh has run.
# For instance, removes the 'line' column in the report CSVs,
# and avoids absolute paths to C/testcasesupport

if [ $# -lt 1 ]; then
    echo "usage: $0 file.csv"
    exit 1
fi

if command -v gcut >/dev/null 2>/dev/null; then
    CUT=gcut
else
    CUT=cut
fi

file="$@"

mv "$file" "$file.tmp"
$CUT --complement -f3 "$file.tmp" > "$file"
rm "$file.tmp"
