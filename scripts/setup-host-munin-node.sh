#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <munin_server_ip> [docker_cidr]"
  exit 1
fi

MUNIN_SERVER_IP="$1"
DOCKER_CIDR="${2:-172.16.0.0/12}"
PLUGIN_SOURCE="/usr/share/munin/plugins/docker_"

sudo apt-get update
sudo apt-get install -y munin-node python3-pip
sudo python3 -m pip install docker
sudo usermod -aG docker munin

sudo install -m 0755 "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/docker_" "${PLUGIN_SOURCE}"
sudo install -d -m 0755 /etc/munin/plugin-conf.d
sudo tee /etc/munin/plugin-conf.d/docker >/dev/null <<EOF
[docker_*]
user root
group docker
env.DOCKER_HOST unix:///var/run/docker.sock
env.EXCLUDE_CONTAINER_NAME runner
EOF

cd /etc/munin/plugins
sudo ln -sfn "${PLUGIN_SOURCE}" docker_containers
sudo ln -sfn "${PLUGIN_SOURCE}" docker_cpu
sudo ln -sfn "${PLUGIN_SOURCE}" docker_images
sudo ln -sfn "${PLUGIN_SOURCE}" docker_memory
sudo ln -sfn "${PLUGIN_SOURCE}" docker_network
sudo ln -sfn "${PLUGIN_SOURCE}" docker_size
sudo ln -sfn "${PLUGIN_SOURCE}" docker_status
sudo ln -sfn "${PLUGIN_SOURCE}" docker_volumes

ESCAPED_IP="$(printf '%s' "${MUNIN_SERVER_IP}" | sed 's/\./\\./g')"
if ! grep -q "^allow \^${ESCAPED_IP}\\\\$" /etc/munin/munin-node.conf; then
  echo "allow ^${MUNIN_SERVER_IP}\$" | sudo tee -a /etc/munin/munin-node.conf >/dev/null
fi

ESCAPED_CIDR="$(printf '%s' "${DOCKER_CIDR}" | sed 's/\./\\./g; s/\//\\\\\\//g')"
if ! grep -q "^cidr_allow ${ESCAPED_CIDR}$" /etc/munin/munin-node.conf; then
  echo "cidr_allow ${DOCKER_CIDR}" | sudo tee -a /etc/munin/munin-node.conf >/dev/null
fi

if grep -q "^host " /etc/munin/munin-node.conf; then
  sudo sed -i 's/^host .*/host 0.0.0.0/' /etc/munin/munin-node.conf
else
  echo "host 0.0.0.0" | sudo tee -a /etc/munin/munin-node.conf >/dev/null
fi

sudo systemctl enable munin-node.service
sudo systemctl restart munin-node.service

echo "munin-node setup finished."
