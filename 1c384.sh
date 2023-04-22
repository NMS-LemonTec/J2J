#!/bin/bash
# by https://github.com/spiritLHLS/lxc 由NMS-LemonTec进行了等于没有的修改
# by Hostloc @WZ-Software
# cd /root
# ./init.sh NAT服务器前缀 数量
# 2023.04.22

rm -rf log
lxc init images:debian/11 "$1" -c limits.cpu=1 -c limits.memory=384MiB
# 硬盘大小
lxc config device override "$1" root size=2GB
lxc config device set "$1" root limits.max 2GB
# IO
lxc config device set "$1" root limits.read 20MB
lxc config device set "$1" root limits.write 20MB
lxc config device set "$1" root limits.read 20iops
lxc config device set "$1" root limits.write 20iops
# 网速
lxc config device override "$1" eth0 limits.egress=100Mbit limits.ingress=100Mbit
# cpu
lxc config set "$1" limits.cpu.priority 0
lxc config set "$1" limits.cpu.allowance 10%
lxc config set "$1" limits.cpu.allowance 100ms/400ms
# 内存
lxc config set "$1" limits.memory.swap true
lxc config set "$1" limits.memory.swap.priority 1
# 支持docker虚拟化
lxc config set "$1" security.nesting true
# 安全性防范设置 - 只有Ubuntu支持
# if [ "$(uname -a | grep -i ubuntu)" ]; then
#   # Set the security settings
#   lxc config set "$1" security.syscalls.intercept.mknod true
#   lxc config set "$1" security.syscalls.intercept.setxattr true
# fi
# 屏蔽端口
blocked_ports=( 3389 8888 54321 65432 )
for port in "${blocked_ports[@]}"; do
  iptables --ipv4 -I FORWARD -o eth0 -p tcp --dport ${port} -j DROP
  iptables --ipv4 -I FORWARD -o eth0 -p udp --dport ${port} -j DROP
done
# 批量创建容器
for ((a=1;a<="$2";a++)); do
  lxc copy "$1" "$1"$a
  name="$1"$a
  # 容器SSH端口 20000起  外网nat端口 30000起 每个25个端口
  sshn=$(( 20000 + a ))
  nat1=$(( 30000 + (a-1)*25 + 1))
  nat2=$(( 30000 + a*25 ))
  ori=$(date | md5sum)
  passwd=${ori: 2: 9}
  lxc start "$1"$a
  sleep 1
  lxc exec "$1"$a -- apt update -y
  lxc exec "$1"$a -- sudo dpkg --configure -a
  lxc exec "$1"$a -- sudo apt-get update
  lxc exec "$1"$a -- sudo apt-get install dos2unix curl -y
  lxc exec "$1"$a -- curl -L https://raw.githubusercontent.com/spiritLHLS/lxc/main/ssh.sh -o ssh.sh
  lxc exec "$1"$a -- chmod 777 ssh.sh
  lxc exec "$1"$a -- dos2unix ssh.sh
  lxc exec "$1"$a -- sudo ./ssh.sh $passwd
  lxc exec "$1"$a -- curl -L https://raw.githubusercontent.com/spiritLHLS/lxc/main/config.sh -o config.sh
  lxc exec "$1"$a -- chmod +x config.sh
  lxc exec "$1"$a -- bash config.sh
  lxc config device add "$1"$a ssh-port proxy listen=tcp:0.0.0.0:$sshn connect=tcp:127.0.0.1:22
  lxc config device add "$1"$a nattcp-ports proxy listen=tcp:0.0.0.0:$nat1-$nat2 connect=tcp:127.0.0.1:$nat1-$nat2
  lxc config device add "$1"$a natudp-ports proxy listen=udp:0.0.0.0:$nat1-$nat2 connect=udp:127.0.0.1:$nat1-$nat2
  echo "$name $sshn $passwd $nat1 $nat2" >> log
done
