#!/usr/bin/env bash
set -euo pipefail

ln -sfn /usr/share/munin/plugins/docker_ /etc/munin/plugins/docker_containers
ln -sfn /usr/share/munin/plugins/docker_ /etc/munin/plugins/docker_cpu
ln -sfn /usr/share/munin/plugins/docker_ /etc/munin/plugins/docker_images
ln -sfn /usr/share/munin/plugins/docker_ /etc/munin/plugins/docker_memory
ln -sfn /usr/share/munin/plugins/docker_ /etc/munin/plugins/docker_network
ln -sfn /usr/share/munin/plugins/docker_ /etc/munin/plugins/docker_size
ln -sfn /usr/share/munin/plugins/docker_ /etc/munin/plugins/docker_status
ln -sfn /usr/share/munin/plugins/docker_ /etc/munin/plugins/docker_volumes

su -s /bin/bash munin -c /usr/bin/munin-cron

