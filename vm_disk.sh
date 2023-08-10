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

# 挂载新磁盘，根据 vm_conf_disk
function attack_disk() {
    cat config/vm_conf_disk | grep -v "^#" | grep -v "^$" | while read PhysicalIp VirtualName VirtualDisk VirtualDiskDev
    do 
        echo -e "$CSTART>>>>$PhysicalIp>$VirtualName>$VirtualDisk>$VirtualDiskDev$CEND"
        disk_name="$VirtualName-disk-${VirtualDisk}G"
        #0.关闭虚拟机
        ssh -n $PhysicalIp "virsh shutdown $VirtualName" || true
        ssh -n $PhysicalIp "virsh destroy $VirtualName" || true
        #1.创建磁盘（该操作会覆盖已有的磁盘，请谨慎操作）
        ssh -n $PhysicalIp "qemu-img create -f qcow2 -o preallocation=full $VM_IMG_PATH/$disk_name ${VirtualDisk}G"
        #2.关联到虚拟机
        ssh -n $PhysicalIp "virsh attach-disk $VirtualName --source $VM_IMG_PATH/$disk_name --target $VirtualDiskDev --persistent"
        #3.开启虚拟机
        ssh -n $PhysicalIp "virsh start $VirtualName" || true
    done
}

function main() {
    echo -e "$CSTART>vm_disk.sh$CEND"

    echo -e "$CSTART>>identification$CEND"
    identification

    echo -e "$CSTART>>attack_disk$CEND"
    attack_disk || true
}

main
