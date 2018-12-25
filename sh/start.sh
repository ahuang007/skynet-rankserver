#!/bin/bash

CUR_DIR=$(dirname $(readlink -f $0))

if [ ! -f "$CUR_DIR/server_dependency.sh" ]; then
  echo "Lack of file $CUR_DIR/server_dependency.sh" && exit -1
fi

. $CUR_DIR/server_dependency.sh

$RANK_ON       && bash "$CUR_DIR/rank.sh"     start release config.rank
