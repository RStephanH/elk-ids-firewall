#!/usr/bin/env bash

# Stop the script on errors
set -e

IMAGE_NAME="noble-server-cloudimg-amd64.img"
USER_DATA="user-data.yaml"
META_DATA="meta-data.yaml"
SEED_ISO="seed.iso"
VM_DISK="vm-disk.qcow2"
VM_NAME="target"
VM_HOSTNAME="target"
NET_DEFAULT_MAC="52:54:00:aa:bb:01"
NET_OVS_MAC="52:54:00:aa:bb:02"

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
# This cloud-init config installs Docker CE and starts OWASP Juice Shop in a container.
# The runcmd block performs a network preflight check before contacting Docker's repo.
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
              - 192.168.100.10/24
packages:
  - ca-certificates
  - curl
  - gnupg
  - lsb-release
runcmd:
  - netplan apply
  - [bash, -lc, "for i in {1..20}; do curl -fsSL https://download.docker.com/linux/ubuntu/gpg >/dev/null && exit 0; sleep 3; done; echo 'Network check failed: cannot reach download.docker.com' >&2; exit 1"]
  - [bash, -lc, "install -m 0755 -d /etc/apt/keyrings"]
  - [bash, -lc, "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg"]
  - [bash, -lc, "chmod a+r /etc/apt/keyrings/docker.gpg"]
  - [bash, -lc, "echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \$(. /etc/os-release && echo \$VERSION_CODENAME) stable\" > /etc/apt/sources.list.d/docker.list"]
  - [bash, -lc, "apt-get update"]
  - [bash, -lc, "apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"]
  - [bash, -lc, "systemctl enable --now docker"]
  - [bash, -lc, "docker run -d --name juice-shop --restart unless-stopped -p 3000:3000 bkimminich/juice-shop"]
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
  --ram 1024 \
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
echo " OWASP Juice Shop will be available on port 3000.         "
echo "=========================================================="

echo "Waiting for VM to be ready..."
until sudo virsh domifaddr "$VM_NAME" 2>/dev/null | grep -q ipv4; do
  sleep 5
done

sudo virsh domifaddr "$VM_NAME"
