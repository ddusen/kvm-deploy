# 物理机虚拟自动化

- 系统版本: Centos 6* / Centos 7* / Rocky 8*

*****

## 前提

1. 从公司云盘下载软件包 kvm-parcels.20230810.tar.gz 到脚本执行机器中。
- http://119.254.145.21:12225/owncloud/index.php/s/mZg3SpfHsLkMKa0
- 如果网盘链接失效，去网盘目录下找该包：07-软件/00-KVM/kvm-parcels.20230810.tar.gz
```bash
wget -O /opt/kvm-parcels.20230810.tar.gz http://119.254.145.21:12225/owncloud/index.php/s/mZg3SpfHsLkMKa0/download
```

2. 把压缩包解压到 /var/www/html 目录下
```bash
tar -zxvf /opt/kvm-parcels.20230810.tar.gz -C /opt/
```

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
ip='10.0.2.8'
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

- 4. kvm-parcels 
```bash
[root@localhost opt]# tree /opt/kvm-parcels
/opt/kvm-parcels
|-- centos7
|   |-- tigervnc-bundle
|   |   |-- libfontenc-1.1.3-3.el7.x86_64.rpm
|   |   |-- libXdmcp-1.1.2-6.el7.x86_64.rpm
|   |   |-- libXfont2-2.0.3-1.el7.x86_64.rpm
|   |   |-- libxkbfile-1.0.9-3.el7.x86_64.rpm
|   |   |-- llvm-private-7.0.1-1.el7.x86_64.rpm
|   |   |-- mesa-dri-drivers-18.3.4-12.el7_9.x86_64.rpm
|   |   |-- mesa-filesystem-18.3.4-12.el7_9.x86_64.rpm
|   |   |-- tigervnc-license-1.8.0-25.el7_9.noarch.rpm
|   |   |-- tigervnc-server-1.8.0-25.el7_9.x86_64.rpm
|   |   |-- tigervnc-server-minimal-1.8.0-25.el7_9.x86_64.rpm
|   |   `-- xorg-x11-xkb-utils-7.7-14.el7.x86_64.rpm
|   |-- virt-bundle
|   |   |-- adwaita-cursor-theme-3.28.0-1.el7.noarch.rpm
|   |   |-- adwaita-icon-theme-3.28.0-1.el7.noarch.rpm
|   |   |-- atk-2.28.1-2.el7.x86_64.rpm
|   |   |-- at-spi2-atk-2.26.2-1.el7.x86_64.rpm
|   |   |-- at-spi2-core-2.28.0-1.el7.x86_64.rpm
|   |   |-- augeas-libs-1.4.0-10.el7.x86_64.rpm
|   |   |-- autogen-libopts-5.18-5.el7.x86_64.rpm
|   |   |-- avahi-libs-0.6.31-20.el7.x86_64.rpm
|   |   |-- boost-iostreams-1.53.0-28.el7.x86_64.rpm
|   |   |-- boost-random-1.53.0-28.el7.x86_64.rpm
|   |   |-- boost-system-1.53.0-28.el7.x86_64.rpm
|   |   |-- boost-thread-1.53.0-28.el7.x86_64.rpm
|   |   |-- bridge-utils-1.5-9.el7.x86_64.rpm
|   |   |-- bzip2-1.0.6-13.el7.x86_64.rpm
|   |   |-- cairo-1.15.12-4.el7.x86_64.rpm
|   |   |-- cairo-gobject-1.15.12-4.el7.x86_64.rpm
|   |   |-- cdparanoia-libs-10.2-17.el7.x86_64.rpm
|   |   |-- celt051-0.5.1.3-8.el7.x86_64.rpm
|   |   |-- colord-libs-1.3.4-2.el7.x86_64.rpm
|   |   |-- cups-libs-1.6.3-51.el7.x86_64.rpm
|   |   |-- cyrus-sasl-2.1.26-24.el7_9.x86_64.rpm
|   |   |-- cyrus-sasl-gssapi-2.1.26-24.el7_9.x86_64.rpm
|   |   |-- cyrus-sasl-lib-2.1.26-24.el7_9.x86_64.rpm
|   |   |-- dbus-x11-1.10.24-15.el7.x86_64.rpm
|   |   |-- dconf-0.28.0-4.el7.x86_64.rpm
|   |   |-- dejavu-fonts-common-2.33-6.el7.noarch.rpm
|   |   |-- dejavu-sans-fonts-2.33-6.el7.noarch.rpm
|   |   |-- dnsmasq-2.76-17.el7_9.3.x86_64.rpm
|   |   |-- flac-libs-1.3.0-5.el7_1.x86_64.rpm
|   |   |-- fontconfig-2.13.0-4.3.el7.x86_64.rpm
|   |   |-- fontpackages-filesystem-1.44-8.el7.noarch.rpm
|   |   |-- fribidi-1.0.2-1.el7_7.1.x86_64.rpm
|   |   |-- fuse-libs-2.9.2-11.el7.x86_64.rpm
|   |   |-- gdk-pixbuf2-2.36.12-3.el7.x86_64.rpm
|   |   |-- genisoimage-1.1.11-25.el7.x86_64.rpm
|   |   |-- glib-networking-2.56.1-1.el7.x86_64.rpm
|   |   |-- glusterfs-6.0-61.el7.x86_64.rpm
|   |   |-- glusterfs-api-6.0-61.el7.x86_64.rpm
|   |   |-- glusterfs-cli-6.0-61.el7.x86_64.rpm
|   |   |-- glusterfs-client-xlators-6.0-61.el7.x86_64.rpm
|   |   |-- glusterfs-libs-6.0-61.el7.x86_64.rpm
|   |   |-- gnome-icon-theme-3.12.0-1.el7.noarch.rpm
|   |   |-- gnutls-3.3.29-9.el7_6.x86_64.rpm
|   |   |-- gnutls-dane-3.3.29-9.el7_6.x86_64.rpm
|   |   |-- gnutls-utils-3.3.29-9.el7_6.x86_64.rpm
|   |   |-- gperftools-libs-2.6.1-1.el7.x86_64.rpm
|   |   |-- graphite2-1.3.10-1.el7_3.x86_64.rpm
|   |   |-- gsettings-desktop-schemas-3.28.0-3.el7.x86_64.rpm
|   |   |-- gsm-1.0.13-11.el7.x86_64.rpm
|   |   |-- gssproxy-0.7.0-30.el7_9.x86_64.rpm
|   |   |-- gstreamer1-1.10.4-2.el7.x86_64.rpm
|   |   |-- gstreamer1-plugins-base-1.10.4-2.el7.x86_64.rpm
|   |   |-- gtk3-3.22.30-8.el7_9.x86_64.rpm
|   |   |-- gtk-update-icon-cache-3.22.30-8.el7_9.x86_64.rpm
|   |   |-- gtk-vnc2-0.7.0-3.el7.x86_64.rpm
|   |   |-- gvnc-0.7.0-3.el7.x86_64.rpm
|   |   |-- harfbuzz-1.7.5-2.el7.x86_64.rpm
|   |   |-- hicolor-icon-theme-0.12-7.el7.noarch.rpm
|   |   |-- ipxe-roms-qemu-20180825-3.git133f4c.el7.noarch.rpm
|   |   |-- iscsi-initiator-utils-6.2.0.874-22.el7_9.x86_64.rpm
|   |   |-- iscsi-initiator-utils-iscsiuio-6.2.0.874-22.el7_9.x86_64.rpm
|   |   |-- iso-codes-3.46-2.el7.noarch.rpm
|   |   |-- jasper-libs-1.900.1-33.el7.x86_64.rpm
|   |   |-- jbigkit-libs-2.0-11.el7.x86_64.rpm
|   |   |-- json-glib-1.4.2-2.el7.x86_64.rpm
|   |   |-- keyutils-1.5.8-3.el7.x86_64.rpm
|   |   |-- lcms2-2.6-3.el7.x86_64.rpm
|   |   |-- libarchive-3.1.2-14.el7_7.x86_64.rpm
|   |   |-- libasyncns-0.8-7.el7.x86_64.rpm
|   |   |-- libbasicobjects-0.1.1-32.el7.x86_64.rpm
|   |   |-- libcacard-2.7.0-1.el7.x86_64.rpm
|   |   |-- libcgroup-0.41-21.el7.x86_64.rpm
|   |   |-- libcollection-0.7.0-32.el7.x86_64.rpm
|   |   |-- libepoxy-1.5.2-1.el7.x86_64.rpm
|   |   |-- libevent-2.0.21-4.el7.x86_64.rpm
|   |   |-- libglvnd-1.0.1-0.8.git5baa1e5.el7.x86_64.rpm
|   |   |-- libglvnd-egl-1.0.1-0.8.git5baa1e5.el7.x86_64.rpm
|   |   |-- libglvnd-glx-1.0.1-0.8.git5baa1e5.el7.x86_64.rpm
|   |   |-- libgusb-0.2.9-1.el7.x86_64.rpm
|   |   |-- libibverbs-22.4-6.el7_9.x86_64.rpm
|   |   |-- libICE-1.0.9-9.el7.x86_64.rpm
|   |   |-- libini_config-1.3.1-32.el7.x86_64.rpm
|   |   |-- libiscsi-1.9.0-7.el7.x86_64.rpm
|   |   |-- libjpeg-turbo-1.2.90-8.el7.x86_64.rpm
|   |   |-- libmodman-2.0.1-8.el7.x86_64.rpm
|   |   |-- libnfsidmap-0.25-19.el7.x86_64.rpm
|   |   |-- libogg-1.3.0-7.el7.x86_64.rpm
|   |   |-- libosinfo-1.1.0-5.el7.x86_64.rpm
|   |   |-- libpath_utils-0.2.1-32.el7.x86_64.rpm
|   |   |-- libpcap-1.5.3-13.el7_9.x86_64.rpm
|   |   |-- libproxy-0.4.11-11.el7.x86_64.rpm
|   |   |-- librados2-10.2.5-4.el7.x86_64.rpm
|   |   |-- librbd1-10.2.5-4.el7.x86_64.rpm
|   |   |-- librdmacm-22.4-6.el7_9.x86_64.rpm
|   |   |-- libref_array-0.1.5-32.el7.x86_64.rpm
|   |   |-- libseccomp-2.3.1-4.el7.x86_64.rpm
|   |   |-- libSM-1.2.2-2.el7.x86_64.rpm
|   |   |-- libsndfile-1.0.25-12.el7_9.1.x86_64.rpm
|   |   |-- libsoup-2.62.2-2.el7.x86_64.rpm
|   |   |-- libthai-0.1.14-9.el7.x86_64.rpm
|   |   |-- libtheora-1.1.1-8.el7.x86_64.rpm
|   |   |-- libtiff-4.0.3-35.el7.x86_64.rpm
|   |   |-- libtirpc-0.2.4-0.16.el7.x86_64.rpm
|   |   |-- libusal-1.1.11-25.el7.x86_64.rpm
|   |   |-- libusbx-1.0.21-1.el7.x86_64.rpm
|   |   |-- libverto-libevent-0.2.5-4.el7.x86_64.rpm
|   |   |-- libvirt-4.5.0-36.el7_9.5.x86_64.rpm
|   |   |-- libvirt-bash-completion-4.5.0-36.el7_9.5.x86_64.rpm
|   |   |-- libvirt-client-4.5.0-36.el7_9.5.x86_64.rpm
|   |   |-- libvirt-daemon-4.5.0-36.el7_9.5.x86_64.rpm
|   |   |-- libvirt-daemon-config-network-4.5.0-36.el7_9.5.x86_64.rpm
|   |   |-- libvirt-daemon-config-nwfilter-4.5.0-36.el7_9.5.x86_64.rpm
|   |   |-- libvirt-daemon-driver-interface-4.5.0-36.el7_9.5.x86_64.rpm
|   |   |-- libvirt-daemon-driver-lxc-4.5.0-36.el7_9.5.x86_64.rpm
|   |   |-- libvirt-daemon-driver-network-4.5.0-36.el7_9.5.x86_64.rpm
|   |   |-- libvirt-daemon-driver-nodedev-4.5.0-36.el7_9.5.x86_64.rpm
|   |   |-- libvirt-daemon-driver-nwfilter-4.5.0-36.el7_9.5.x86_64.rpm
|   |   |-- libvirt-daemon-driver-qemu-4.5.0-36.el7_9.5.x86_64.rpm
|   |   |-- libvirt-daemon-driver-secret-4.5.0-36.el7_9.5.x86_64.rpm
|   |   |-- libvirt-daemon-driver-storage-4.5.0-36.el7_9.5.x86_64.rpm
|   |   |-- libvirt-daemon-driver-storage-core-4.5.0-36.el7_9.5.x86_64.rpm
|   |   |-- libvirt-daemon-driver-storage-disk-4.5.0-36.el7_9.5.x86_64.rpm
|   |   |-- libvirt-daemon-driver-storage-gluster-4.5.0-36.el7_9.5.x86_64.rpm
|   |   |-- libvirt-daemon-driver-storage-iscsi-4.5.0-36.el7_9.5.x86_64.rpm
|   |   |-- libvirt-daemon-driver-storage-logical-4.5.0-36.el7_9.5.x86_64.rpm
|   |   |-- libvirt-daemon-driver-storage-mpath-4.5.0-36.el7_9.5.x86_64.rpm
|   |   |-- libvirt-daemon-driver-storage-rbd-4.5.0-36.el7_9.5.x86_64.rpm
|   |   |-- libvirt-daemon-driver-storage-scsi-4.5.0-36.el7_9.5.x86_64.rpm
|   |   |-- libvirt-glib-1.0.0-1.el7.x86_64.rpm
|   |   |-- libvirt-libs-4.5.0-36.el7_9.5.x86_64.rpm
|   |   |-- libvirt-python-4.5.0-1.el7.x86_64.rpm
|   |   |-- libvisual-0.4.0-16.el7.x86_64.rpm
|   |   |-- libvorbis-1.3.3-8.el7.1.x86_64.rpm
|   |   |-- libwayland-client-1.15.0-1.el7.x86_64.rpm
|   |   |-- libwayland-cursor-1.15.0-1.el7.x86_64.rpm
|   |   |-- libwayland-egl-1.15.0-1.el7.x86_64.rpm
|   |   |-- libwayland-server-1.15.0-1.el7.x86_64.rpm
|   |   |-- libX11-1.6.7-4.el7_9.x86_64.rpm
|   |   |-- libX11-common-1.6.7-4.el7_9.noarch.rpm
|   |   |-- libXau-1.0.8-2.1.el7.x86_64.rpm
|   |   |-- libxcb-1.13-1.el7.x86_64.rpm
|   |   |-- libXcomposite-0.4.4-4.1.el7.x86_64.rpm
|   |   |-- libXcursor-1.1.15-1.el7.x86_64.rpm
|   |   |-- libXdamage-1.1.4-4.1.el7.x86_64.rpm
|   |   |-- libXext-1.3.3-3.el7.x86_64.rpm
|   |   |-- libXfixes-5.0.3-1.el7.x86_64.rpm
|   |   |-- libXft-2.3.2-2.el7.x86_64.rpm
|   |   |-- libXi-1.7.9-1.el7.x86_64.rpm
|   |   |-- libXinerama-1.1.3-2.1.el7.x86_64.rpm
|   |   |-- libxkbcommon-0.7.1-3.el7.x86_64.rpm
|   |   |-- libxml2-2.9.1-6.el7_9.6.x86_64.rpm
|   |   |-- libxml2-python-2.9.1-6.el7_9.6.x86_64.rpm
|   |   |-- libXmu-1.1.2-2.el7.x86_64.rpm
|   |   |-- libXrandr-1.5.1-2.el7.x86_64.rpm
|   |   |-- libXrender-0.9.10-1.el7.x86_64.rpm
|   |   |-- libxshmfence-1.2-1.el7.x86_64.rpm
|   |   |-- libxslt-1.1.28-6.el7.x86_64.rpm
|   |   |-- libXt-1.1.5-3.el7.x86_64.rpm
|   |   |-- libXtst-1.2.3-1.el7.x86_64.rpm
|   |   |-- libXv-1.0.11-1.el7.x86_64.rpm
|   |   |-- libXxf86misc-1.0.3-7.1.el7.x86_64.rpm
|   |   |-- libXxf86vm-1.1.4-1.el7.x86_64.rpm
|   |   |-- lzop-1.03-10.el7.x86_64.rpm
|   |   |-- mesa-libEGL-18.3.4-12.el7_9.x86_64.rpm
|   |   |-- mesa-libgbm-18.3.4-12.el7_9.x86_64.rpm
|   |   |-- mesa-libGL-18.3.4-12.el7_9.x86_64.rpm
|   |   |-- mesa-libglapi-18.3.4-12.el7_9.x86_64.rpm
|   |   |-- netcf-libs-0.2.8-4.el7.x86_64.rpm
|   |   |-- nettle-2.7.1-9.el7_9.x86_64.rpm
|   |   |-- nfs-utils-1.3.0-0.68.el7.2.x86_64.rpm
|   |   |-- nmap-ncat-6.40-19.el7.x86_64.rpm
|   |   |-- numad-0.5-18.20150602git.el7.x86_64.rpm
|   |   |-- opus-1.0.2-6.el7.x86_64.rpm
|   |   |-- orc-0.4.26-1.el7.x86_64.rpm
|   |   |-- osinfo-db-20200529-1.el7.noarch.rpm
|   |   |-- osinfo-db-tools-1.1.0-1.el7.x86_64.rpm
|   |   |-- pango-1.42.4-4.el7_7.x86_64.rpm
|   |   |-- pciutils-3.5.1-3.el7.x86_64.rpm
|   |   |-- pcre2-10.23-2.el7.x86_64.rpm
|   |   |-- pixman-0.34.0-1.el7.x86_64.rpm
|   |   |-- pulseaudio-libs-10.0-6.el7_9.x86_64.rpm
|   |   |-- pulseaudio-libs-glib2-10.0-6.el7_9.x86_64.rpm
|   |   |-- pycairo-1.8.10-8.el7.x86_64.rpm
|   |   |-- python-backports-1.0-8.el7.x86_64.rpm
|   |   |-- python-backports-ssl_match_hostname-3.5.0.1-1.el7.noarch.rpm
|   |   |-- python-chardet-2.2.1-3.el7.noarch.rpm
|   |   |-- python-gobject-3.22.0-1.el7_4.1.x86_64.rpm
|   |   |-- python-ipaddr-2.1.11-2.el7.noarch.rpm
|   |   |-- python-ipaddress-1.0.16-2.el7.noarch.rpm
|   |   |-- python-requests-2.6.0-10.el7.noarch.rpm
|   |   |-- python-six-1.9.0-2.el7.noarch.rpm
|   |   |-- python-urllib3-1.10.2-7.el7.noarch.rpm
|   |   |-- qemu-img-1.5.3-175.el7_9.6.x86_64.rpm
|   |   |-- qemu-kvm-1.5.3-175.el7_9.6.x86_64.rpm
|   |   |-- qemu-kvm-common-1.5.3-175.el7_9.6.x86_64.rpm
|   |   |-- qemu-kvm-tools-1.5.3-175.el7_9.6.x86_64.rpm
|   |   |-- quota-4.01-19.el7.x86_64.rpm
|   |   |-- quota-nls-4.01-19.el7.noarch.rpm
|   |   |-- radvd-2.17-3.el7.x86_64.rpm
|   |   |-- rdma-core-22.4-6.el7_9.x86_64.rpm
|   |   |-- rest-0.8.1-2.el7.x86_64.rpm
|   |   |-- rpcbind-0.2.0-49.el7.x86_64.rpm
|   |   |-- seabios-bin-1.11.0-2.el7.noarch.rpm
|   |   |-- seavgabios-bin-1.11.0-2.el7.noarch.rpm
|   |   |-- sgabios-bin-0.20110622svn-4.el7.noarch.rpm
|   |   |-- spice-glib-0.35-5.el7_9.1.x86_64.rpm
|   |   |-- spice-gtk3-0.35-5.el7_9.1.x86_64.rpm
|   |   |-- spice-server-0.14.0-9.el7_9.1.x86_64.rpm
|   |   |-- tcp_wrappers-7.6-77.el7.x86_64.rpm
|   |   |-- trousers-0.3.14-2.el7.x86_64.rpm
|   |   |-- unbound-libs-1.6.6-5.el7_8.x86_64.rpm
|   |   |-- usbredir-0.7.1-3.el7.x86_64.rpm
|   |   |-- virt-install-1.5.0-7.el7.noarch.rpm
|   |   |-- virt-manager-1.5.0-7.el7.noarch.rpm
|   |   |-- virt-manager-common-1.5.0-7.el7.noarch.rpm
|   |   |-- vte291-0.52.4-1.el7.x86_64.rpm
|   |   |-- vte-profile-0.52.4-1.el7.x86_64.rpm
|   |   |-- xkeyboard-config-2.24-1.el7.noarch.rpm
|   |   |-- xml-common-0.6.3-39.el7.noarch.rpm
|   |   |-- xorg-x11-server-utils-7.7-20.el7.x86_64.rpm
|   |   |-- xorg-x11-xauth-1.0.9-1.el7.x86_64.rpm
|   |   |-- xorg-x11-xinit-1.3.4-2.el7.x86_64.rpm
|   |   `-- yajl-2.0.4-4.el7.x86_64.rpm
|   `-- virt-sysprep-bundle
|       |-- hexedit-1.2.13-5.el7.x86_64.rpm
|       |-- hivex-1.3.10-6.12.el7_9.x86_64.rpm
|       |-- libguestfs-1.40.2-10.el7.x86_64.rpm
|       |-- libguestfs-tools-c-1.40.2-10.el7.x86_64.rpm
|       |-- perl-hivex-1.3.10-6.12.el7_9.x86_64.rpm
|       |-- scrub-2.5.2-7.el7.x86_64.rpm
|       |-- squashfs-tools-4.3-0.21.gitaae0aff4.el7.x86_64.rpm
|       |-- supermin5-5.1.19-1.el7.x86_64.rpm
|       |-- syslinux-4.05-15.el7.x86_64.rpm
|       `-- syslinux-extlinux-4.05-15.el7.x86_64.rpm
`-- rocky8
    |-- tigervnc-bundle
    |   |-- tigervnc-selinux-1.12.0-7.el8.noarch.rpm
    |   `-- tigervnc-server-1.12.0-7.el8.x86_64.rpm
    |-- virt-bundle
    |   |-- libvirt-8.0.0-10.module+el8.7.0+1084+97b81f61.x86_64.rpm
    |   |-- libvirt-client-8.0.0-10.module+el8.7.0+1084+97b81f61.x86_64.rpm
    |   |-- libvirt-daemon-config-nwfilter-8.0.0-10.module+el8.7.0+1084+97b81f61.x86_64.rpm
    |   |-- python3-argcomplete-1.9.3-6.el8.noarch.rpm
    |   |-- python3-libvirt-8.0.0-2.module+el8.7.0+1084+97b81f61.x86_64.rpm
    |   |-- virt-install-3.2.0-4.el8.noarch.rpm
    |   |-- virt-manager-3.2.0-4.el8.noarch.rpm
    |   `-- virt-manager-common-3.2.0-4.el8.noarch.rpm
    `-- virt-sysprep-bundle
        |-- bind-export-libs-9.11.36-5.el8_7.2.x86_64.rpm
        |-- dhcp-client-4.3.6-48.el8.x86_64.rpm
        |-- dhcp-common-4.3.6-48.el8.noarch.rpm
        |-- dhcp-libs-4.3.6-48.el8.x86_64.rpm
        |-- hexedit-1.2.13-12.el8.x86_64.rpm
        |-- hivex-1.3.18-23.module+el8.7.0+1084+97b81f61.x86_64.rpm
        |-- ipcalc-0.2.4-4.el8.x86_64.rpm
        |-- libguestfs-1.44.0-9.module+el8.7.0+1084+97b81f61.rocky.x86_64.rpm
        |-- libguestfs-appliance-1.44.0-9.module+el8.7.0+1084+97b81f61.rocky.x86_64.rpm
        |-- libguestfs-tools-c-1.44.0-9.module+el8.7.0+1084+97b81f61.rocky.x86_64.rpm
        |-- libguestfs-xfs-1.44.0-9.module+el8.7.0+1084+97b81f61.rocky.x86_64.rpm
        |-- scrub-2.5.2-16.el8.x86_64.rpm
        |-- supermin-5.2.1-2.module+el8.7.0+1084+97b81f61.x86_64.rpm
        |-- syslinux-6.04-6.el8.x86_64.rpm
        |-- syslinux-extlinux-6.04-6.el8.x86_64.rpm
        |-- syslinux-extlinux-nonlinux-6.04-6.el8.noarch.rpm
        `-- syslinux-nonlinux-6.04-6.el8.noarch.rpm

8 directories, 271 files
```
