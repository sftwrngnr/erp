#!/bin/sh

# Create new up/down SQL files with a timestamp and a name. This is mostly
# equivalent to:
#
#   migrate create -dir deploy/k8s/kernos/sql -ext sql NAME
#
# But it's preconfigured and doesn't require migrate to be installed.

if [ -z "$1" ]; then
    echo "Usage: $0 NAME"
    exit 1
fi

BASE=$(dirname $(readlink -f $0))/$(TZ=UTC date +%Y%m%d%H%M%S)_$1

set -x
touch $BASE.up.sql
touch $BASE.down.sql
