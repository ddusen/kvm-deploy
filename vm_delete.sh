#!/bin/bash

#author: Sen Du
#email: dusen@gennlife.com
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

# 删除虚拟机，根据 vm_info_deleted
function delete_vm() {
    cat config/vm_info_deleted | grep -v "^#" | grep -v "^$" | while read PhysicalIp VirtualName
    do 
        echo -e "$CSTART>>>>$PhysicalIp>$VirtualName$CEND"
        #1.关闭虚拟机
        ssh -n $PhysicalIp "virsh shutdown $VirtualName" || true
        ssh -n $PhysicalIp "virsh destroy $VirtualName" || true
        sleep 3
        
        #2.删除虚拟机镜像
        img_files=$(ssh -n $PhysicalIp "grep -oP \"source file='\K[^']+\" ${VM_CONF_PATH}/${VirtualName}.xml")
        for img in ${img_files[@]}
        do
            ssh -n $PhysicalIp "echo yes | rm $img" || true
        done

        #3.解除虚拟机关联
        ssh -n $PhysicalIp "virsh undefine --domain $VirtualName" || true

    done
}

function main() {
    echo -e "$CSTART>vm_delete.sh$CEND"

    echo -e "$CSTART>>identification$CEND"
    identification

    echo -e "$CSTART>>delete_vm$CEND"
    delete_vm || true
}

main
