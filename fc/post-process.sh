#!/bin/bash -eu

# Post-processes results after analyze.sh has run.
# For instance, removes the 'line' column in the report CSVs,
# and avoids absolute paths to C/testcasesupport

if [ $# -lt 1 ]; then
    echo "usage: $0 file.csv"
    exit 1
fi

# (for macOS) check if `cut` has option --complement (GNU extension);
# otherwise try using `gcut`. Note: ffmpeg has a `gcut` binary which
# may lead to errors.
if echo -n "" | cut --complement -f1 >/dev/null 2>/dev/null; then
    CUT=cut
else
    CUT=gcut
fi

file="$@"

mv "$file" "$file.tmp"
$CUT --complement -f3 "$file.tmp" > "$file"
rm "$file.tmp"
