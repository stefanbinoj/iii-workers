#!/bin/bash
set -euxo pipefail

exec > >(tee -a /var/log/iii-worker-node-bootstrap.log) 2>&1
echo "Starting Node worker bootstrap at $(date -Is)"
trap 'echo "Node worker bootstrap failed on line $LINENO at $(date -Is)"' ERR

export DEBIAN_FRONTEND=noninteractive
APP_DIR=/home/ubuntu/Developer/iii-workers
REPO_URL=https://github.com/stefanbinoj/iii-workers.git
III_URL=ws://${api_private_ip}:49134

sudo apt -o Acquire::ForceIPv4=true update
sudo apt -o Acquire::ForceIPv4=true install -y ca-certificates curl git netcat-openbsd
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt -o Acquire::ForceIPv4=true install -y nodejs

sudo npm i -g pm2

sudo install -d -o ubuntu -g ubuntu "$(dirname "$APP_DIR")"
sudo -u ubuntu git clone "$REPO_URL" "$APP_DIR"

cd "$APP_DIR/workers/caller-worker"

sudo -u ubuntu npm install

until nc -z ${api_private_ip} 49134; do
  sleep 5
done

sudo -u ubuntu env III_URL="$III_URL" pm2 start npm --name worker-node -- run dev
sudo -u ubuntu pm2 save

echo "Node worker bootstrap completed at $(date -Is)"
