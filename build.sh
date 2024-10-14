#!/bin/bash
# 制作 atrust 镜像
set -e

# https://zta.iwhalecloud.com/resource/client/linux/uos/amd64/aTrustInstaller_amd64.deb
build_args="
--build-arg VPN_URL=http://172.17.0.1/aTrustInstaller_amd64-uos.deb
--build-arg VPN_TYPE=ATRUST
--build-arg MIRROR_URL=http://mirrors.ustc.edu.cn/debian/
"

docker build $build_args -f Dockerfile.build -t hagb/docker-easyconnect:build .
docker build $build_args --tag hagb/atrust:2.2.16 -f Dockerfile .
