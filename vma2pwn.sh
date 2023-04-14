#!/bin/zsh

#
# vma2pwn - vma2pwn.sh
# v0.1.0
#

# Fail-fast
set -e



function printUsage {
    echo 'Usage:'
    echo '\t./vma2pwn.sh help'
    echo ''
    echo '\t./vma2pwn.sh prepare <macOS version>'
    echo '\t\te.g., ./vma2pwn.sh prepare 12.0.1'
    echo ''
    echo '\t./vma2pwn.sh restore <directory>'
    echo '\t\te.g., ./vma2pwn.sh restore ./UniversalMac_12.0.1_21A559_Restore'
}



# Check if input argument length is not 3
if ! [[ $# -ne 3 ]]; then
    printUsage
    
    if [ $1 = 'help' ]; then
        exit 0
    fi
    
    exit -1
fi

# Check if first argument is 'prepare' or 'restore'
if [ "$1" = 'prepare' ]; then
    ./check-rosetta2.sh
    ./get-dependencies.sh
    ./prepare.sh "$2"
elif [ "$1" = 'restore' ]; then
    # Check for idevicerestore command
    if ! [ -x "$(command -v idevicerestore)" ]; then
        echo 'idevicerestore is required but was not found, please install it before continuing!'
        exit -1
    fi

    idevicerestore -e -y "$2"
else
    printUsage
    exit -1
fi
