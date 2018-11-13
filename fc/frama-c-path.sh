#!/bin/bash -eu
# This script must be sourced by the scripts running Frama-C

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# comment out this line to use Frama-C from the path
# you can also directly export FRAMAC_DIR from the shell to override it
if [ ! ${FRAMAC_DIR:+1} ]; then
    FRAMAC_DIR=$SCRIPT_DIR/frama-c/build/bin
fi

if [ -d $FRAMAC_DIR ]; then
    export FRAMAC=$FRAMAC_DIR/frama-c
    export FRAMAC_GUI=$FRAMAC_DIR/frama-c-gui
    export FRAMAC_CONFIG=$FRAMAC_DIR/frama-c-config
fi
