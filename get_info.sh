#!/bin/bash

#author: Sen Du
#email: dusen.me@gmail.com
#created: 2023-06-02 15:00:00
#updated: 2023-06-02 15:00:00

set -e 
source 00_env

#接收用户参数
OPT="$1"

#物理机内存情况
function phy_mem_overview() {
    cat config/vm_info | grep -v "^#" | grep -v "^$" | while read ipaddr name passwd
    do 
        echo -e "$CSTART>>>>$ipaddr [$(date +'%Y-%m-%d %H:%M:%S')]$CEND"
        ## 物理机总内存
        total_mem=$(ssh -n $PhysicalIp "export LANG='en_US.UTF-8' && export LC_ALL='en_US.UTF-8' && export LANGUAGE='en_US:en' && cat /proc/meminfo | grep 'MemTotal' | sed 's/[^0-9]//g'")
        ## 已经分配的内存
        allocated_mem=$(ssh -n $PhysicalIp "export LANG='en_US.UTF-8' && export LC_ALL='en_US.UTF-8' && export LANGUAGE='en_US:en' && virsh list --name | xargs -l virsh dominfo | grep 'Max memory' | sed 's/[^0-9]//g' | paste -sd+ | bc")
        ## 需要分配的内存
        tobe_allocated_mem=$(( $VirtualMem * 1024 * 1024 ))
        ## 系统安全余量
        safety_mem=$(( 4 * 1024 * 1024))
        ## 物理机剩余可用内存
        remaining_mem=$(( $total_mem - $allocated_mem - $safety_mem ))

        echo "物理机总内存(MB):[$(( $total_mem / 1024 ))] 已分配内存:[$(( $allocated_mem / 1024 ))] 剩余内存:[$(( $remaining_mem / 1024 ))]"
        echo "物理机总内存(GB):[$(( $total_mem / 1024 / 1024 ))] 已分配内存:[$(( $allocated_mem / 1024 / 1024 ))] 剩余内存:[$(( $remaining_mem / 1024 / 1024 ))]"
    done
}

#物理机的cpu情况
function phy_cpu_overview() {
    cat config/vm_info | grep -v "^#" | grep -v "^$" | while read ipaddr name passwd
    do 
        echo -e "$CSTART>>>>$ipaddr [$(date +'%Y-%m-%d %H:%M:%S')]$CEND"
        ssh -n $ipaddr "lscpu"
    done
}

#物理机的disk情况
function phy_disk_overview() {
    cat config/vm_info | grep -v "^#" | grep -v "^$" | while read ipaddr name passwd
    do 
        echo -e "$CSTART>>>>$ipaddr [$(date +'%Y-%m-%d %H:%M:%S')]$CEND"
        ssh -n $ipaddr "df -h"
    done
}

#物理机的虚拟机情况
function phy_vm_overview() {
    cat config/vm_info | grep -v "^#" | grep -v "^$" | while read ipaddr name passwd
    do 
        echo -e "$CSTART>>>>$ipaddr [$(date +'%Y-%m-%d %H:%M:%S')]$CEND"
        ssh -n $ipaddr "virsh list --all"
    done
}

function main() {
    echo -e "$CSTART>get_info.sh$CEND"

    case "$OPT" in 
        'mem') 
            echo -e "$CSTART>>phy_mem_overview$CEND"
            phy_mem_overview
            ;;
        'cpu') 
            echo -e "$CSTART>>phy_cpu_overview$CEND"
            phy_cpu_overview
            ;;
        'disk') 
            echo -e "$CSTART>>phy_disk_overview$CEND"
            phy_disk_overview
            ;;
        'vm') 
            echo -e "$CSTART>>phy_vm_overview$CEND"
            phy_vm_overview
            ;;
    esac
}

main
