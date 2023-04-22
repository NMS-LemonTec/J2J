#!/usr/bin/env bash
# by https://github.com/spiritLHLS/lxc



#root权限
root_need(){
    if [[ $EUID -ne 0 ]]; then
        echo -e "${Red}Error:This script must be run as root!${Font}"
        exit 1
    fi
}

#检测ovz
ovz_no(){
    if [[ -d "/proc/vz" ]]; then
        echo -e "${Red}Your VPS is based on OpenVZ，not supported!${Font}"
        exit 1
    fi
}
apt update
apt install curl wget sudo dos2unix ufw snapd -y
ufw disable
snap install lxd
/snap/bin/lxd init
! lxc -h >/dev/null 2>&1 && echo 'alias lxc="/snap/bin/lxc"' >> /root/.bashrc && source /root/.bashrc
export PATH=$PATH:/snap/bin
