#!/usr/bin/env bash

# Stop the script on errors
set -e

IMAGE_NAME="noble-server-cloudimg-amd64.img"
USER_DATA="user-data.yaml"
META_DATA="meta-data.yaml"
SEED_ISO="seed.iso"
VM_DISK="vm-disk.qcow2"
VM_NAME="ids"
VM_HOSTNAME="ids"
NET_DEFAULT_MAC="52:54:00:aa:bb:03"
NET_OVS_MAC="52:54:00:aa:bb:04"

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
hostname: $VM_HOSTNAME
manage_etc_hosts: true
users:
  - name: bruce
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - $SSH_KEY
write_files:
  - path: /etc/netplan/51-ovs.yaml
    permissions: '0600'
    content: |
      network:
        version: 2
        ethernets:
          ovs-iface:
            match:
              macaddress: "$NET_OVS_MAC"
            dhcp4: false
            addresses:
              - 192.168.100.20/24
runcmd:
  - netplan apply
  - [bash, -lc, "apt-get update"]
  - [bash, -lc, "apt-get install -y software-properties-common"]
  - [bash, -lc, "add-apt-repository -y ppa:oisf/suricata-stable"]
  - [bash, -lc, "apt-get update"]
  - [bash, -lc, "apt-get install -y suricata jq"]
EOF

echo "=== 3. Generating the meta-data.yaml file ==="
# Add minimal metadata so the VM has a stable hostname and fresh instance-id.
cat >"$META_DATA" <<EOF
instance-id: ${VM_NAME}-$(date +%s)
local-hostname: $VM_HOSTNAME
EOF

echo "=== 4. Creating the NoCloud ISO (seed.iso) ==="
# Ensure the old ISO is cleanly overwritten
rm -f "$SEED_ISO"
cloud-localds "$SEED_ISO" "$USER_DATA" "$META_DATA"

echo "=== 5. Cleaning up the old VM if it exists ==="
sudo virsh destroy "$VM_NAME" 2>/dev/null || true
sudo virsh undefine "$VM_NAME" --remove-all-storage 2>/dev/null || true
rm -f "$VM_DISK"

echo "=== 6. Creating the copy-on-write virtual disk ==="
qemu-img create -f qcow2 -b "$IMAGE_NAME" -F qcow2 "$VM_DISK" 10G

echo "=== 7. Deploying the VM via Libvirt ==="
sudo virt-install \
  --name "$VM_NAME" \
  --ram 2048 \
  --vcpus 1 \
  --disk path="$VM_DISK",format=qcow2 \
  --disk path="$SEED_ISO",device=cdrom \
  --os-variant ubuntu24.04 \
  --network network=default,model=virtio,mac="$NET_DEFAULT_MAC" \
  --network bridge=br0,virtualport_type=openvswitch,model=virtio,mac="$NET_OVS_MAC" \
  --noautoconsole \
  --import

echo "=========================================================="
echo " VM launched successfully! Configuration is in progress. "
echo " Wait about 30 seconds before connecting via:            "
echo "        ssh bruce@<VM_IP>                                 "
echo " Suricata will be installed from the PPA repository.     "
echo "=========================================================="

echo "Waiting for VM to be ready..."
until sudo virsh domifaddr "$VM_NAME" 2>/dev/null | grep -q ipv4; do
  sleep 5
done

sudo virsh domifaddr "$VM_NAME"
