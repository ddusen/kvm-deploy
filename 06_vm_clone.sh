#!/bin/bash

#author: Sen Du
#email: dusen@gennlife.com
#created: 2023-06-01 10:00:00
#updated: 2023-06-01 10:00:00

set -e 
source 00_env

#基于模版克隆虚拟机
function clone_vm() {
    cat config/vm_conf | grep -v "^#" | grep -v "^$" | while read PhysicalIp VirtualIp VirtualName VirtualCPU VirtualMem
    do 
        echo -e "$CSTART>>>>$PhysicalIp>$VirtualIp$CEND"
        # 1.验证物理机剩余内存，避免超分配
        ## 物理机总内存
        total_mem=$(ssh -n $PhysicalIp "export LANG='en_US.UTF-8' && export LC_ALL='en_US.UTF-8' && export LANGUAGE='en_US:en' && cat /proc/meminfo | grep 'MemTotal' | sed 's/[^0-9]//g'")
        ### 允许超分配的内存总量
        total_mem=$(echo "${total_mem} * ${MEMORY_OVERALLOCATION:-1}" | bc | awk '{print int($1)}')
        ## 已经分配的内存
        allocated_mem=$(ssh -n $PhysicalIp "export LANG='en_US.UTF-8' && export LC_ALL='en_US.UTF-8' && export LANGUAGE='en_US:en' && virsh list --name | xargs -l virsh dominfo | grep 'Max memory' | sed 's/[^0-9]//g' | paste -sd+ | bc")
        ## 需要分配的内存
        tobe_allocated_mem=$(( $VirtualMem * 1024 * 1024 ))
        ## 系统安全余量
        safety_mem=$(( 4 * 1024 * 1024))
        ## 物理机剩余可用内存
        remaining_mem=$(( $total_mem - $allocated_mem - $safety_mem ))

        if [[ $remaining_mem -lt $tobe_allocated_mem ]]; then 
            ## 内存单位从 KB 转成 GB
            total_mem=$(( ${total_mem} / 1024 / 1024 ))
            allocated_mem=$(( ${allocated_mem} / 1024 / 1024 ))
            remaining_mem=$(( ${remaining_mem} / 1024 / 1024 ))
            tobe_allocated_mem=$(( ${tobe_allocated_mem} / 1024 / 1024 ))
            echo -e "\033[33m物理机可分配内存不足，无法创建新虚拟机，请调整后再进行！！！\033[0m"
            echo -e "\033[33m总内存(GB):[$(( $total_mem ))] 已分配内存:[$(( $allocated_mem ))] 待分配内存:[$(( $tobe_allocated_mem ))] 剩余内存:[$(( $remaining_mem ))]\033[0m"
            exit 128
        fi

        # 2.开始分配虚拟机
        ssh -n $PhysicalIp "virsh destroy $TEMPLATE_NAME" || true
        ssh -n $PhysicalIp "virt-clone --original $TEMPLATE_NAME --name $VirtualName --auto-clone"
    done
}

function main() {
    echo -e "$CSTART>06_vm_clone.sh$CEND"

    echo -e "$CSTART>>clone_vm$CEND"
    clone_vm
}

main
