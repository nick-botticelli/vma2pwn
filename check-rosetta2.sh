#!/bin/zsh

#
# vma2pwn - check-rosetta2.sh
# v0.1.0
#

# Fail-fast
set -e

if [[ $(/usr/bin/pgrep -q oahd)? -eq 1 ]]; then
    echo 'Rosetta2 is not installed! Please install it before continuing.'
    exit -1
fi
