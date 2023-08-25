# 物理机虚拟自动化

- 系统版本: Centos 6* / Centos 7* / Rocky 8*

*****

## 一、KVM 安装

### 0. 配置环境变量
- 需要手动补充该文件中的配置项
- [./00_env](./00_env)

### 1. 配置集群间ssh免密
- 需要修改 `config/vm_info` 文件
- [./01_sshpass.sh](./01_sshpass.sh)

### 2. 配置所有节点的 hosts
- 需要修改 `config/hosts` 文件
- [./02_hosts.sh](./02_hosts.sh)

### 3. 初始化系统环境
- [./03_init.sh](./03_init.sh)

### 4. 安装 install_virt
- [./04_install_virt.sh](./04_install_virt.sh)

### 5. 在物理机上分发虚拟机模版
- 需要修改 `config/vm_info` 文件
- [./05_vm_template.sh](./05_vm_template.sh)

### 6. 在物理机上安装虚拟机
- 需要修改 `config/vm_conf` 文件（这个文件描述了物理机与虚拟机的拓扑关系）
- [./06_vm_clone.sh](./06_vm_clone.sh)

### 7. 配置虚拟机：cpu 内存 网络
- 需要修改 `config/vm_conf` 文件（这个文件描述了物理机与虚拟机的拓扑关系）
- [./07_vm_config.sh](./07_vm_config.sh)

## 二、其它
- 1. 手动创建KVM虚拟网络
```bash
ip='10.0.2.9'
gateway='10.0.2.1'

# 创建新网桥配置
echo "
TYPE=Bridge
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=static
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=no
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=br0
DEVICE=br0
ONBOOT=yes
IPADDR=TODO_IPADDR
NETMASK=255.255.255.0
GATEWAY=TODO_GATEWAY
DNS1="114.114.114.114"
IPV6_PRIVACY=no
" > /etc/sysconfig/network-scripts/ifcfg-br0

# 设置网桥
sed -i "s/TODO_IPADDR/$ip/g" /etc/sysconfig/network-scripts/ifcfg-br0
sed -i "s/TODO_GATEWAY/$gateway/g" /etc/sysconfig/network-scripts/ifcfg-br0

# 在网卡中添加新网桥（不同机器网卡不同，注意修改 ens3）
sed -i "/BRIDGE/d" /etc/sysconfig/network-scripts/ifcfg-em1
echo 'BRIDGE=br0' >> /etc/sysconfig/network-scripts/ifcfg-em1

# 重启网络
systemctl restart network
systemctl restart NetworkManager
```

- 2. 手动修改虚拟机网络
```bash
ip='10.0.5.19'
gateway='10.0.5.1'

echo "
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=static
DEFROUTE=yes
IPV6INIT=no
NAME=ens3
DEVICE=ens3
ONBOOT=yes
IPADDR=TODO_IPADDR
NETMASK=255.255.255.0
GATEWAY=TODO_GATEWAY
DNS1=114.114.114.114
" > /etc/sysconfig/network-scripts/ifcfg-ens3

echo "
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=static
DEFROUTE=yes
IPV6INIT=no
NAME=eth0
DEVICE=eth0
ONBOOT=yes
IPADDR=TODO_IPADDR
NETMASK=255.255.255.0
GATEWAY=TODO_GATEWAY
DNS1=114.114.114.114
" > /etc/sysconfig/network-scripts/ifcfg-eth0

sed -i "s/TODO_IPADDR/$ip/g" /etc/sysconfig/network-scripts/ifcfg-ens3
sed -i "s/TODO_GATEWAY/$gateway/g" /etc/sysconfig/network-scripts/ifcfg-ens3
sed -i "s/TODO_IPADDR/$ip/g" /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i "s/TODO_GATEWAY/$gateway/g" /etc/sysconfig/network-scripts/ifcfg-eth0

# 重启网络
systemctl restart network
systemctl restart NetworkManager
```

- 3. Linux安装图形化界面（为了使用 vnc viewer）
```bash
#安装桌面环境所需的组件
yum groupinstall -y "GNOME Desktop" "Graphical Administration Tools"

#默认启动目标为图形化界面
systemctl set-default graphical.target

#重启系统，使设置生效
reboot
```
