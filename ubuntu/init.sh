#!/usr/bin/env bash

# Arrêter le script en cas d'erreur
set -e

IMAGE_NAME="noble-server-cloudimg-amd64.img"
USER_DATA="user-data.yaml"
SEED_ISO="seed.iso"
VM_DISK="vm-disk.qcow2"
VM_NAME="ubuntu-fresh"

echo "=== 1. Vérification de l'image de base Ubuntu 24.04 Cloud ==="
if [[ ! -f "$IMAGE_NAME" ]]; then
  echo "Téléchargement de l'image cloud..."
  wget https://cloud-images.ubuntu.com/noble/current/$IMAGE_NAME
else
  echo "L'image cloud est déjà présente."
fi

echo "=== 2. Génération du fichier user-data.yaml ==="
# Récupération de la clé SSH locale
if [[ ! -f ~/.ssh/id_ed25519.pub ]]; then
  echo "Erreur : Clé ~/.ssh/id_ed25519.pub introuvable. Génère-en une avec ssh-keygen."
  exit 1
fi
SSH_KEY=$(cat ~/.ssh/id_ed25519.pub)

# Écriture du fichier avec une indentation YAML stricte (2 espaces)
cat >"$USER_DATA" <<EOF
#cloud-config
users:
  - name: bruce
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - $SSH_KEY
EOF

echo "=== 3. Création de l'ISO NoCloud (seed.iso) ==="
# On s'assure que l'ancien ISO est écrasé proprement
rm -f "$SEED_ISO"
cloud-localds "$SEED_ISO" "$USER_DATA"

echo "=== 4. Nettoyage de l'ancienne VM si elle existe ==="
sudo virsh destroy "$VM_NAME" 2>/dev/null || true
sudo virsh undefine "$VM_NAME" --remove-all-storage 2>/dev/null || true
rm -f "$VM_DISK"

echo "=== 5. Création du disque virtuel copy-on-write ==="
qemu-img create -f qcow2 -b "$IMAGE_NAME" -F qcow2 "$VM_DISK" 20G

echo "=== 6. Déploiement de la VM via Libvirt ==="
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
echo " VM lancée avec succès ! Étape de configuration en cours. "
echo " Attends environ 30 secondes avant de te connecter via :  "
echo "        ssh bruce@<IP_DE_LA_VM>                           "
echo "=========================================================="
sleep 30s
sudo virsh domiflist "$VM_NAME" | grep -oP '(\d{1,3}\.){3}\d{1,3}' || echo "Erreur : Impossible de récupérer l'IP de la VM. Vérifie avec 'sudo virsh domiflist $VM_NAME'."
