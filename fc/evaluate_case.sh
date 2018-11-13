#!/bin/bash -eu

# requires the following environment variables to be set:
# BASE: filename to be tested
# DIR: directory containing
# GB: "good" or "bad"

post_processed=0
BASE=$(basename $BASE .c)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Prevent a Ctrl+C from killing a Frama-C process and making the caller script
# think that analysis was finished
exit_on_signal() {
    echo "sigint received, aborting."
    if [ $post_processed -eq 0 ]; then
        rm -f $DIR/${BASE}_${GB}.csv
    fi
    exit 1
}
trap exit_on_signal INT

set +e
$SCRIPT_DIR/analyze.sh \
    -main ${BASE}_${GB} $DIR/$BASE*.c "$@" \
    -report-no-proven -report-csv $DIR/${BASE}_${GB}.csv > $DIR/${BASE}_${GB}
RES=$?
if [ "$RES" -eq 124 ]; then
    # script got timeout
    printf " timeout\n" | tee "$DIR/${BASE}_${GB}.res"
    exit 1
fi
$SCRIPT_DIR/post-process.sh $DIR/${BASE}_${GB}.csv
post_processed=1

# some sanity checks to ensure the test is 'supported' by Frama-C/Eva; used later
grep -q "assigns clause\s\+Unknown" $DIR/${BASE}_${GB}.csv
no_missing_assigns=$?
grep -q "from\s\+Unknown" $DIR/${BASE}_${GB}.csv
no_missing_from=$?

grep -q "Invalid\|Unknown" $DIR/${BASE}_${GB}.csv
no_alarms=$?

# Filter other kinds of warnings
grep -q "[wW]arning:\|WARNING:" $DIR/${BASE}_${GB}
no_warnings=$?

grep -q "NON TERMINATING" $DIR/${BASE}_${GB}
terminates=$?

exit_code=0
(printf "${BASE}_${GB}: "
 if [ $no_missing_assigns -eq 0 -o $no_missing_from -eq 0 ]; then
     printf "missing spec\n"
     exit_code=1
 elif [ "$GB" = "good" ]; then
     if [ $no_alarms -ne 0 -a $no_warnings -ne 0 ]; then
         if [ $terminates -ne 0 ]; then
             printf "ok\n"
         else
             printf "unsound (non-termination)\n"
             exit_code=1
         fi
     else
         printf "imprecise"
         if [ $terminates -ne 0 ]; then
             printf "\n"
         else
             printf " and unsound (non-termination)\n"
             exit_code=1
         fi
     fi
 else # "$GB" = "bad"
     if [ $no_alarms -ne 0 -a $no_warnings -ne 0 ]; then
         if [ $terminates -ne 0 ]; then
             printf "unsound\n"
             exit_code=1
         else
             printf "non-terminating (and no grepped alarms/warnings)\n"
             exit_code=1
         fi
     else
         printf "ok\n"
     fi
 fi
) | tee "$DIR/${BASE}_${GB}.res"
set -e
exit $exit_code
