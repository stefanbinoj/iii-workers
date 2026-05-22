#!/bin/bash
set -euxo pipefail

exec > >(tee -a /var/log/iii-api-bootstrap.log) 2>&1
echo "Starting API bootstrap at $(date -Is)"
trap 'echo "API bootstrap failed on line $LINENO at $(date -Is)"' ERR

export DEBIAN_FRONTEND=noninteractive
APP_DIR=/home/ubuntu/Developer/iii-workers
REPO_URL=https://github.com/stefanbinoj/iii-workers.git

sudo apt remove -y $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1) || true

sudo apt -o Acquire::ForceIPv4=true update
sudo apt -o Acquire::ForceIPv4=true install -y ca-certificates curl git caddy
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt -o Acquire::ForceIPv4=true update
sudo apt -o Acquire::ForceIPv4=true install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo install -d -o ubuntu -g ubuntu "$(dirname "$APP_DIR")"
sudo -u ubuntu git clone "$REPO_URL" "$APP_DIR"

cd "$APP_DIR"

sudo install -o root -g root -m 644 infra/user_data/caddyfile /etc/caddy/Caddyfile
sudo systemctl restart caddy

docker compose up -d

echo "API bootstrap completed at $(date -Is)"
