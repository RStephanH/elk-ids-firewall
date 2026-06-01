#!/usr/bin/env bash

# Stop the script on errors
set -e

IMAGE_NAME="noble-server-cloudimg-amd64.img"
USER_DATA="user-data.yaml"
SEED_ISO="seed.iso"
VM_DISK="vm-disk.qcow2"
VM_NAME="ubuntu-fresh"

echo "=== 1. Checking the Ubuntu 24.04 Cloud base image ==="
if [[ ! -f "$IMAGE_NAME" ]]; then
  echo "Downloading the cloud image..."
  wget https://cloud-images.ubuntu.com/noble/current/$IMAGE_NAME
else
  echo "The cloud image is already present."
fi

echo "=== 2. Generating the user-data.yaml file ==="
# Retrieve the local SSH key
if [[ ! -f ~/.ssh/id_ed25519.pub ]]; then
  echo "Error: ~/.ssh/id_ed25519.pub not found. Generate one with ssh-keygen."
  exit 1
fi
SSH_KEY=$(cat ~/.ssh/id_ed25519.pub)

# Write the file with strict YAML indentation (2 spaces)
cat >"$USER_DATA" <<EOF
#cloud-config
users:
  - name: bruce
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - $SSH_KEY
EOF

echo "=== 3. Creating the NoCloud ISO (seed.iso) ==="
# Ensure the old ISO is cleanly overwritten
rm -f "$SEED_ISO"
cloud-localds "$SEED_ISO" "$USER_DATA"

echo "=== 4. Cleaning up the old VM if it exists ==="
sudo virsh destroy "$VM_NAME" 2>/dev/null || true
sudo virsh undefine "$VM_NAME" --remove-all-storage 2>/dev/null || true
rm -f "$VM_DISK"

echo "=== 5. Creating the copy-on-write virtual disk ==="
qemu-img create -f qcow2 -b "$IMAGE_NAME" -F qcow2 "$VM_DISK" 20G

echo "=== 6. Deploying the VM via Libvirt ==="
sudo virt-install \
  --name "$VM_NAME" \
  --ram 2048 \
  --vcpus 2 \
  --disk path="$VM_DISK",format=qcow2 \
  --disk path="$SEED_ISO",device=cdrom \
  --os-variant ubuntu24.04 \
  --network network=default \
  --noautoconsole \
  --import

echo "=========================================================="
echo " VM launched successfully! Configuration is in progress. "
echo " Wait about 30 seconds before connecting via:            "
echo "        ssh bruce@<VM_IP>                                 "
echo "=========================================================="
sleep 30s
sudo virsh domiflist "$VM_NAME" | grep -oP '(\d{1,3}\.){3}\d{1,3}' || echo "Error: Unable to retrieve the VM IP. Check with 'sudo virsh domiflist $VM_NAME'."
