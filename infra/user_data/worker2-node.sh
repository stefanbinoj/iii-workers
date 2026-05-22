#!/bin/bash
set -euxo pipefail

exec > >(tee -a /var/log/iii-worker-node-bootstrap.log) 2>&1
echo "Starting Node worker bootstrap at $(date -Is)"
trap 'echo "Node worker bootstrap failed on line $LINENO at $(date -Is)"' ERR

export DEBIAN_FRONTEND=noninteractive

sudo apt -o Acquire::ForceIPv4=true update
sudo apt -o Acquire::ForceIPv4=true install -y ca-certificates curl git netcat-openbsd
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt -o Acquire::ForceIPv4=true install -y nodejs

sudo npm i -g pm2

mkdir -p /home/ubuntu/Developer
chown ubuntu:ubuntu /home/ubuntu/Developer
sudo -u ubuntu git clone https://github.com/stefanbinoj/iii-workers.git /home/ubuntu/Developer/iii-workers

cd /home/ubuntu/Developer/iii-workers/workers/caller-worker

sudo -u ubuntu npm install

until nc -z ${api_private_ip} 49134; do
  sleep 5
done

sudo -u ubuntu env III_URL=ws://${api_private_ip}:49134 pm2 start npm --name worker-node -- run dev
sudo -u ubuntu pm2 save

echo "Node worker bootstrap completed at $(date -Is)"
