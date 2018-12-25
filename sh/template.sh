#!/bin/bash
# 服务器部署时把template文件去掉
#

if [ $# -lt 1 ]; then
    echo "Usage $0 [ip addr]"
    exit 2
fi

template_file=(                         \
    common/settings_template.lua        \
    common/clustername_template.lua     \
    sh/server_dependency_template.sh    \
)

CUR_DIR=$(dirname $(readlink -f $0))
GAME_DIR=$CUR_DIR/../
IP=$1

function cpsettings(){
    content="local M = require\"settings_template\"\n\nM.gate_host = \"$IP\"\nM.login_conf.login_ip = \"$IP\"\n\nreturn M"
    echo -e $content > $2
}

function cpothers(){
    cp -f $1 $2
}

for file in ${template_file[*]} ; do
    ori_name=$GAME_DIR${file/_template/}
    name=${ori_name##*/}
    if [ "$name" == "settings.lua" ]; then
        if [ ! -f $ori_name ]; then
            cpsettings $GAME_DIR$file $ori_name
        fi
    else
        if [ ! -f $ori_name ]; then
            cpothers $GAME_DIR$file $ori_name
        fi
    fi
done



