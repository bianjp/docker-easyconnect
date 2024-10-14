#!/bin/bash
# 启动 atrust 容器
set -e
cd "$(dirname "$0")"

# 获取 sudo 权限
sudo ls / > /dev/null

# 容器名称
container_name=atrust
# 内网网段
subnets=(
  "10.0.0.0/8"
  "172.16.0.0/16"
  "172.21.0.0/16"
)

# 停止
if [[ "$1" == "stop" ]]; then
  docker stop "$container_name"
  echo "Stopped container"
  # 删除路由
  for subnet in "${subnets[@]}"; do
    sudo ip route del $subnet table 3
  done
  sudo ip rule del iif lo table 3
  echo "Removed routes"
  exit
fi

# 启动容器
if docker ps -a --format json | grep -q "\"Names\":\"$container_name\""; then
  docker start "$container_name"
  echo "Started container"
else
  docker run -d --name "$container_name" \
    --device /dev/net/tun --cap-add NET_ADMIN \
    -e CLIP_TEXT=https://zta.iwhalecloud.com \
    -e PASSWORD=atrust \
    -e URLWIN=1 \
    -e NODANTED=1 \
    -e USE_NOVNC=1 \
    -p 127.0.0.1:7080:8080 \
    --sysctl net.ipv4.conf.default.route_localnet=1 \
    hagb/atrust:2.2.16
  echo "Created container"
fi

# 等待容器启动
echo "Sleep 5s ..."
sleep 5

# 浏览器打开 登录
# https://zta.iwhalecloud.com
xdg-open 'http://127.0.0.1:7080/?password=atrust&autoconnect=true'
busctl --user call org.gnome.Shell /de/lucaswerkmeister/ActivateWindowByTitle de.lucaswerkmeister.ActivateWindowByTitle activateByWmClass s 'firefox' &> /dev/null

# 容器 IP。无法设置固定 IP
container_ip="$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container_name)"
if [[ -z "$container_ip" ]]; then
  echo "Container IP not found"
  exit 1
fi
echo "Container IP: $container_ip"

# 配置路由
if ip route list table 3 | grep -q '10.0.0.0/8'; then
  for subnet in "${subnets[@]}"; do
    sudo ip route change $subnet via $container_ip table 3
  done
  echo "Updated routes"
else
  for subnet in "${subnets[@]}"; do
    sudo ip route add $subnet via $container_ip table 3
  done
  echo "Created routes"
fi
if ! ip rule list | grep -q 'lookup 3'; then
  sudo ip rule add iif lo table 3
fi

# 重启 DNS
sudo systemctl restart smartdns
