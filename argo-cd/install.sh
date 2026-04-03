#!/bin/bash
set -e
source .env

# === Install k3s with CRI (Docker runtime) ===
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode 644 --disable traefik --docker" sh -

# === Verify cluster ===
echo "Waiting for k3s to start..."
sleep 10
sudo kubectl get nodes

# === Configure kubeconfig ===
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
chmod 600 ~/.kube/config

echo "k3s installation complete with CRI support."
