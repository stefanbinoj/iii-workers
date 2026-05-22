#!/bin/bash
set -euxo pipefail

exec > >(tee -a /var/log/iii-worker-python-bootstrap.log) 2>&1
echo "Starting Python worker bootstrap at $(date -Is)"
trap 'echo "Python worker bootstrap failed on line $LINENO at $(date -Is)"' ERR

export DEBIAN_FRONTEND=noninteractive
export HF_TOKEN='${hf_token}'

sudo apt -o Acquire::ForceIPv4=true update
sudo apt -o Acquire::ForceIPv4=true install -y ca-certificates curl git netcat-openbsd python3-pip python3-venv
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt -o Acquire::ForceIPv4=true install -y nodejs

sudo npm i -g pm2

mkdir -p /home/ubuntu/Developer
chown ubuntu:ubuntu /home/ubuntu/Developer
sudo -u ubuntu git clone https://github.com/stefanbinoj/iii-workers.git /home/ubuntu/Developer/iii-workers

cd /home/ubuntu/Developer/iii-workers/workers/inference-worker

sudo -u ubuntu python3 -m venv .venv
sudo -u ubuntu .venv/bin/pip install --upgrade pip
sudo -u ubuntu .venv/bin/pip install -r requirements.txt

until nc -z ${api_private_ip} 49134; do
  sleep 5
done

sudo -u ubuntu env HF_TOKEN="$HF_TOKEN" III_URL=ws://${api_private_ip}:49134 pm2 start inference_worker.py --name worker-python --interpreter /home/ubuntu/Developer/iii-workers/workers/inference-worker/.venv/bin/python
sudo -u ubuntu pm2 save

echo "Python worker bootstrap completed at $(date -Is)"
