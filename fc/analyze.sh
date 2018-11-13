#!/bin/bash -eu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TESTCASESUPPORT_DIR=$(realpath "$SCRIPT_DIR/../C/testcasesupport")

if [ -e $SCRIPT_DIR/frama-c-path.sh ]; then
    source $SCRIPT_DIR/frama-c-path.sh
fi

# if FRAMAC is defined, use it; otherwise, try frama-c in the path
FRAMAC=${FRAMAC:-$(which frama-c)}
if [ ! -x "$FRAMAC" ]; then
    echo "error: could not execute frama-c binary."
    echo "       Make sure frama-c is in the path, or define variable FRAMAC."
    exit 1
fi

FRAMAC_SHARE="$(${FRAMAC}-config -print-share-path)"

# Search for '-gui' in the command line and remove it if present,
# replacing the frama-c command with frama-c-gui
cur_arg=0
use_gui=0
while [ $cur_arg -le "$#" ]; do
    if [ "${!cur_arg}" = "-gui" ] ; then
        if [ $cur_arg -eq 0 ]; then
            shift
        else
            set -- "${@:1:cur_arg-1}" "${@:cur_arg+1}"
        fi
        FRAMAC="${FRAMAC}-gui"
        use_gui=1
        break
    fi
    cur_arg=$((cur_arg+1))
done

CPPFLAGS="\
  -I$TESTCASESUPPORT_DIR \
  -nostdinc \
  -I$FRAMAC_SHARE/libc \
  -include$FRAMAC_SHARE/libc/alloca.h \
  -include$SCRIPT_DIR/fc_stubs.h \
"

# disable unused plug-ins to speed up analysis
FCFLAGS="-no-autoload-plugins -load-module from,inout,report,scope,eva,variadic -kernel-warn-key parser:decimal-float=inactive -kernel-warn-key typing:no-proto=inactive  -kernel-warn-key typing:implicit-conv-void-ptr=inactive -eva-warn-key locals-escaping=inactive -add-symbolic-path TESTCASESUPPORT_DIR:$TESTCASESUPPORT_DIR"

EVAFLAGS="\
  -eva-msg-key=-initial-state \
  -eva-no-show-progress \
  -eva-print-callstacks \
  -slevel 300 \
  -eva-builtin alloca:Frama_C_vla_alloc_by_stack \
  -warn-special-float none \
  -warn-signed-downcast \
  -warn-unsigned-overflow \
  -eva-warn-copy-indeterminate=-@all \
  -eva-equality-domain \
  -eva-sign-domain \
"

if [ $use_gui -eq 1 ]; then
    TIMEOUT=""
else
    TIMEOUT="timeout 30s "
fi

# detect if we are being run via make, with flag VERBOSE
set +e
env | grep '^MAKEFLAGS=' | grep -q '\bVERBOSE='
RES=$?
set -e
if [ $RES -eq 0 ]; then
    set -x
fi
$TIMEOUT$FRAMAC -cpp-extra-args="$CPPFLAGS" \
                $FCFLAGS \
                -val $EVAFLAGS \
                $SCRIPT_DIR/fc_runtime.c \
                $TESTCASESUPPORT_DIR/io.c \
                "$@"
