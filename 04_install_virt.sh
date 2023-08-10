#!/bin/bash

#author: Sen Du
#email: dusen@gennlife.com
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
            # 离线安装
            if [ "$OFFLINE" == true ]; then 
                ssh -n $ipaddr "rm -rf /tmp/virt-bundle"
                scp -r /opt/kvm-parcels/rocky8/virt-bundle $ipaddr:/tmp/            
                ssh -n $ipaddr "yum localinstall -y /tmp/virt-bundle/*.rpm" || true
            else # 在线安装
                ssh -n $ipaddr "yum install -y qemu-kvm virt-manager virt-install libvirt" || true
            fi
        elif [[ "$system_version" == CentOSLinuxrelease7* ]]; then
            # 离线安装
            if [ "$OFFLINE" == true ]; then 
                ssh -n $ipaddr "rm -rf /tmp/virt-bundle"
                scp -r /opt/kvm-parcels/centos7/virt-bundle $ipaddr:/tmp/            
                ssh -n $ipaddr "yum localinstall -y /tmp/virt-bundle/*.rpm" || true
            else # 在线安装
                ssh -n $ipaddr "yum install -y qemu-kvm qemu-kvm-tools virt-manager virt-install libvirt" || true
            fi
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
            ssh -n $ipaddr "rm -rf /tmp/tigervnc-bundle"
            scp -r /opt/kvm-parcels/rocky8/tigervnc-bundle $ipaddr:/tmp/            
            ssh -n $ipaddr "yum localinstall -y /tmp/tigervnc-bundle/*.rpm" || true

        elif [[ "$system_version" == CentOSLinuxrelease7* ]]; then
            # 离线安装
            if [ "$OFFLINE" == true ]; then 
                ssh -n $ipaddr "rm -rf /tmp/tigervnc-bundle"
                scp -r /opt/kvm-parcels/centos7/tigervnc-bundle $ipaddr:/tmp/            
                ssh -n $ipaddr "yum localinstall -y /tmp/tigervnc-bundle/*.rpm" || true
            else # 在线安装
                ssh -n $ipaddr "yum install -y tigervnc-selinux tigervnc-server" || true
            fi
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
