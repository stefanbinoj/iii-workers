#!/bin/bash
set -euxo pipefail

exec > >(tee -a /var/log/iii-api-bootstrap.log) 2>&1
echo "Starting API bootstrap at $(date -Is)"
trap 'echo "API bootstrap failed on line $LINENO at $(date -Is)"' ERR

export DEBIAN_FRONTEND=noninteractive

# Step 1: Uninstall old versions of Docker if they exist.
sudo apt remove -y $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1) || true


# Step 2: Install Docker Engine.
sudo apt -o Acquire::ForceIPv4=true update
sudo apt -o Acquire::ForceIPv4=true install -y ca-certificates curl git caddy
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
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

# Step 3: Clone the project and run the iii orchestrator/API.
mkdir -p /home/ubuntu/Developer
chown ubuntu:ubuntu /home/ubuntu/Developer
sudo -u ubuntu git clone https://github.com/stefanbinoj/iii-workers.git /home/ubuntu/Developer/iii-workers

cd /home/ubuntu/Developer/iii-workers

sudo cp infra/user_data/caddyfile /etc/caddy/Caddyfile
sudo chown root:root /etc/caddy/Caddyfile
sudo chmod 644 /etc/caddy/Caddyfile
sudo systemctl restart caddy

sudo docker compose up -d

echo "API bootstrap completed at $(date -Is)"
