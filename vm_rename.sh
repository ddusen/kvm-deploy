#!/bin/bash

#author: Sen Du
#email: dusen.me@gmail.com
#created: 2023-06-18 15:00:00
#updated: 2023-06-18 15:00:00

set -e 
source 00_env

# 避免误操作，添加输入密码步骤
function identification() {
    read -s -p "请输入密码(该操作有风险，请确保清醒): " pswd
    shapswd=$(echo $pswd | sha1sum | head -c 10)
    if [[ "$shapswd" == "e6283c043a" ]]; then
        echo && true
    else
        echo -e "\033[33m密码错误，程序终止！\033[0m"
        echo && false
    fi
}

# 重命名虚拟机，根据 vm_info_renamed
function rename_vm() {
    cat config/vm_info_renamed | grep -v "^#" | grep -v "^$" | while read PhysicalIp VirtualName NewVirtualName
    do 
        echo -e "$CSTART>>>>$PhysicalIp>$VirtualName>$NewVirtualName$CEND"
        #0.关闭虚拟机
        ssh -n $PhysicalIp "virsh shutdown $VirtualName" || true
        ssh -n $PhysicalIp "virsh destroy $VirtualName" || true
        #1.修改虚拟机名称
        ssh -n $PhysicalIp "virsh domrename $VirtualName $NewVirtualName" || true
    done
}

function main() {
    echo -e "$CSTART>vm_rename.sh$CEND"

    echo -e "$CSTART>>identification$CEND"
    identification

    echo -e "$CSTART>>rename_vm$CEND"
    rename_vm || true
}

main
