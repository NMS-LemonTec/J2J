#!/usr/bin/env bash
# by https://github.com/NMS-LemonTec/J2J


rm -rf 1c384.sh
wget https://github.com/NMS-LemonTec/J2J/raw/main/1c384.sh
chmod 777 1c384.sh
apt install dos2unix -y
dos2unix 1c384.sh
./1c384.sh J2J 10
