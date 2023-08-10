#!/bin/bash

#author: Sen Du
#email: dusen@gennlife.com
#created: 2023-04-16 21:00:00
#updated: 2023-04-16 21:00:00

set -e 
source 00_env

# 重启机器
function reboot() {
    cat config/vm_info | grep -v "^#" | grep -v "^$" | while read ipaddr name passwd
    do
        echo -e "$CSTART>>>>$ipaddr [$(date +'%Y-%m-%d %H:%M:%S')]$CEND";
        ssh -n $ipaddr "reboot" || true;
    done
}

function main() {
    echo -e "$CSTART>reboot.sh$CEND"
    echo -e "$CSTART>>reboot$CEND"
    reboot
}

main
