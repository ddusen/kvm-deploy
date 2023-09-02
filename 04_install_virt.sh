#!/bin/bash

#author: Sen Du
#email: dusen.me@gmail.com
#created: 2023-05-12 15:00:00
#updated: 2023-08-10 15:00:00

set -e 
source 00_env

# 安装虚拟化软件
function install_virt() {
    cat config/vm_info | grep -v "^#" | grep -v "^$" | while read ipaddr name passwd
    do 
        echo -e "$CSTART>>>>$ipaddr [$(date +'%Y-%m-%d %H:%M:%S')]$CEND"

        system_version=$(ssh -n $ipaddr "cat /etc/centos-release | sed 's/ //g'")
        echo -e "$CSTART>>>>$ipaddr>$system_version$CEND"

        if [[ "$system_version" == RockyLinuxrelease8* ]]; then
            ssh -n $ipaddr "yum install -y qemu-kvm virt-manager virt-install libvirt" || true

        elif [[ "$system_version" == CentOSLinuxrelease7* ]]; then
            ssh -n $ipaddr "yum install -y qemu-kvm qemu-kvm-tools virt-manager virt-install libvirt" || true

        else 
            echo "系统版本[$system_version]超出脚本处理范围" && false
        fi

    done
}

# 安装vnc viewer
function install_vnc() {
    cat config/vm_info | grep -v "^#" | grep -v "^$" | while read ipaddr name passwd
    do 
        echo -e "$CSTART>>>>$ipaddr [$(date +'%Y-%m-%d %H:%M:%S')]$CEND"

        system_version=$(ssh -n $ipaddr "cat /etc/centos-release | sed 's/ //g'")
        echo -e "$CSTART>>>>$ipaddr>$system_version$CEND"

        if [[ "$system_version" == RockyLinuxrelease8* ]]; then
            ssh -n $ipaddr "yum install -y tigervnc-server" || true

        elif [[ "$system_version" == CentOSLinuxrelease7* ]]; then
            ssh -n $ipaddr "yum install -y tigervnc-server" || true
            
        else 
            echo "系统版本[$system_version]超出脚本处理范围" && false
        fi

    done
}

function main() {
    echo -e "$CSTART>04_virsh.sh$CEND"

    echo -e "$CSTART>>install_virt$CEND"
    install_virt

    echo -e "$CSTART>>install_vnc$CEND"
    install_vnc
}

main
