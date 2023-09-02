#!/bin/bash

#author: Sen Du
#email: dusen.me@gmail.com
#created: 2023-05-16 10:00:00
#updated: 2023-05-16 10:00:00

set -e 
source 00_env


#复制虚拟机模版到其它物理机
function copy_template() {
    cat config/vm_info | grep -v "^#" | grep -v "^$" | while read ipaddr name passwd
    do 
        # 当前机器不用复制模版
        if [[ "$ipaddr" == "$LOCAL_IP" ]]; then
            continue
        fi
        echo -e "$CSTART>>>>$ipaddr [$(date +'%Y-%m-%d %H:%M:%S')]$CEND"
        # 1.创建镜像存储目录
        ssh -n $ipaddr "mkdir -p $VM_IMG_PATH"
        ssh -n $ipaddr "mkdir -p $VM_CONF_PATH"

        # 2.关闭模版机器
        virsh destroy $TEMPLATE_NAME || true
        ssh -n $ipaddr "virsh destroy $TEMPLATE_NAME" || true

        # 3.模版镜像文件名称：TEMPLATE_NAME or TEMPLATE_NAME.img
        local_img_file="$TEMPLATE_NAME"
        if [ ! -f "$local_img_file" ];then
            local_img_file="$TEMPLATE_NAME.img"
        fi

        # 4.传输新的模版
        if [ "$BACKGROUND_SCP" == true ]; then 
            # 后台传输大文件，节约时间
            nohup scp $VM_IMG_PATH/$local_img_file $ipaddr:$VM_IMG_PATH/$TEMPLATE_NAME.img &
            echo "在后台传输: $TEMPLATE_NAME.img, 传输进度请通过: ps -ef | grep scp 查看！"
        else
            # 串行
            scp $VM_IMG_PATH/$local_img_file $ipaddr:$VM_IMG_PATH/$TEMPLATE_NAME.img
        fi
        scp $VM_CONF_PATH/$TEMPLATE_NAME.xml $ipaddr:$VM_CONF_PATH/$TEMPLATE_NAME.xml
        
        # 5.重启 libvirtd，以更新虚拟机列表
        ssh -n $ipaddr "service libvirtd restart"
    done
}

function main() {
    echo -e "$CSTART>05_vm_template.sh$CEND"
    
    echo -e "$CSTART>>copy_template$CEND"
    copy_template
}

main
