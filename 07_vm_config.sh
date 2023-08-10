#!/bin/bash

#author: Sen Du
#email: dusen@gennlife.com
#created: 2023-05-16 10:00:00
#updated: 2023-08-10 15:00:00

set -e 
source 00_env

#安装依赖基础软件
function install_base() {
    cat config/vm_info | grep -v "^#" | grep -v "^$" | while read ipaddr name passwd
    do 
        echo -e "$CSTART>>>>$ipaddr [$(date +'%Y-%m-%d %H:%M:%S')]$CEND"

        system_version=$(ssh -n $ipaddr "cat /etc/centos-release | sed 's/ //g'")
        echo -e "$CSTART>>>>$ipaddr>$system_version$CEND"

        if [[ "$system_version" == RockyLinuxrelease8* ]]; then
            # 离线安装
            if [ "$OFFLINE" == true ]; then 
                ssh -n $ipaddr "rm -rf /tmp/virt-sysprep-bundle"
                scp -r /opt/kvm-parcels/rocky8/virt-sysprep-bundle $ipaddr:/tmp/            
                ssh -n $ipaddr "yum localinstall -y /tmp/virt-sysprep-bundle/*.rpm" || true
            else # 在线安装
                ssh -n $ipaddr "yum install -y /usr/bin/virt-sysprep" || true
            fi
        elif [[ "$system_version" == CentOSLinuxrelease7* ]]; then
            # 离线安装
            if [ "$OFFLINE" == true ]; then 
                ssh -n $ipaddr "rm -rf /tmp/virt-sysprep-bundle"
                scp -r /opt/kvm-parcels/centos7/virt-sysprep-bundle $ipaddr:/tmp/            
                ssh -n $ipaddr "yum localinstall -y /tmp/virt-sysprep-bundle/*.rpm" || true
            else # 在线安装
                ssh -n $ipaddr "yum install -y /usr/bin/virt-sysprep" || true
            fi
        else 
            echo "系统版本[$system_version]超出脚本处理范围" && false
        fi

    done
}

# 关闭虚拟机（virt-sysprep修改虚拟机配置，需要保证虚拟机关闭）
function shutdown_vm() {
    cat config/vm_conf | grep -v "^#" | grep -v "^$" | while read PhysicalIp VirtualIp VirtualName VirtualCPU VirtualMem
    do 
        echo -e "$CSTART>>>>$PhysicalIp>$VirtualIp$CEND"
        # 关闭虚拟机
        ssh -n $PhysicalIp "virsh shutdown $VirtualName" || true
    done
}

# 上一步未关闭，执行强制关闭
function destroy_vm() {
    cat config/vm_conf | grep -v "^#" | grep -v "^$" | while read PhysicalIp VirtualIp VirtualName VirtualCPU VirtualMem
    do 
        echo -e "$CSTART>>>>$PhysicalIp>$VirtualIp$CEND"
        # 关闭虚拟机
        ssh -n $PhysicalIp "virsh destroy $VirtualName" || true
    done
}

# 配置虚拟机内存 cpu
function config_mem_cpu() {
    cat config/vm_conf | grep -v "^#" | grep -v "^$" | while read PhysicalIp VirtualIp VirtualName VirtualCPU VirtualMem
    do 
        echo -e "$CSTART>>>>$PhysicalIp>$VirtualIp$CEND"
        ssh -n $PhysicalIp "sed -i 's/>[0-9]*<\/memory>/>$(( $VirtualMem * 1024 * 1024 ))<\/memory>/' /etc/libvirt/qemu/$VirtualName.xml"
        ssh -n $PhysicalIp "sed -i 's/>[0-9]*<\/currentMemory>/>$(( $VirtualMem * 1024 * 1024 ))<\/currentMemory>/' /etc/libvirt/qemu/$VirtualName.xml"
        ssh -n $PhysicalIp "sed -i 's/>[0-9]*<\/vcpu>/>$VirtualCPU<\/vcpu>/' /etc/libvirt/qemu/$VirtualName.xml"
    done
    
    # 重启 virsh 服务，令配置文件生效
    ## awk '!a[$1]++{print}': 去除重复，防止频繁重启物理机服务
    cat config/vm_conf | grep -v "^#" | grep -v "^$" | awk '!a[$1]++{print}' | while read PhysicalIp VirtualIp VirtualName VirtualCPU VirtualMem
    do 
        echo -e "$CSTART>>>>$PhysicalIp$CEND"
        ssh -n $PhysicalIp "systemctl restart libvirtd"
    done
}

# 配置虚拟机（已经停止状态）
function config_network() {
    cat config/vm_conf | grep -v "^#" | grep -v "^$" | while read PhysicalIp VirtualIp VirtualName VirtualCPU VirtualMem
    do 
        echo -e "$CSTART>>>>$PhysicalIp>$VirtualIp$CEND"
        # 配置网络 ens3
        scp config/ifcfg-ens3 $PhysicalIp:/tmp/
        ssh -n $PhysicalIp "virt-sysprep -d $VirtualName --copy-in /tmp/ifcfg-ens3:/etc/sysconfig/network-scripts/"
        ssh -n $PhysicalIp "virt-sysprep -d $VirtualName --edit /etc/sysconfig/network-scripts/ifcfg-ens3:'s/TODO_IPADDR/$VirtualIp/g'"
        ssh -n $PhysicalIp "virt-sysprep -d $VirtualName --edit /etc/sysconfig/network-scripts/ifcfg-ens3:'s/TODO_GATEWAY/$GATEWAY/g'"
        # 配置网络 eth0
        scp config/ifcfg-eth0 $PhysicalIp:/tmp/
        ssh -n $PhysicalIp "virt-sysprep -d $VirtualName --copy-in /tmp/ifcfg-eth0:/etc/sysconfig/network-scripts/"
        ssh -n $PhysicalIp "virt-sysprep -d $VirtualName --edit /etc/sysconfig/network-scripts/ifcfg-eth0:'s/TODO_IPADDR/$VirtualIp/g'"
        ssh -n $PhysicalIp "virt-sysprep -d $VirtualName --edit /etc/sysconfig/network-scripts/ifcfg-eth0:'s/TODO_GATEWAY/$GATEWAY/g'"
    done
}

# 启动虚拟机
function start_vm() {
    cat config/vm_conf | grep -v "^#" | grep -v "^$" | while read PhysicalIp VirtualIp VirtualName VirtualCPU VirtualMem
    do 
        echo -e "$CSTART>>>>$PhysicalIp>$VirtualIp$CEND"
        # 关闭虚拟机
        ssh -n $PhysicalIp "virsh start $VirtualName"
    done
}

function main() {
    echo -e "$CSTART>07_vm_config.sh$CEND"

    echo -e "$CSTART>>install_base$CEND"
    install_base

    echo -e "$CSTART>>shutdown_vm$CEND"
    shutdown_vm
    
    echo -e "$CSTART>>destroy_vm$CEND"
    destroy_vm

    echo -e "$CSTART>>config_mem_cpu$CEND"
    config_mem_cpu

    echo -e "$CSTART>>config_network$CEND"
    config_network

    echo -e "$CSTART>>start_vm$CEND"
    start_vm
}

main
