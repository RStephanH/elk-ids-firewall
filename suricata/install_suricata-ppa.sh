#!/bin/bash

# Suricata Installation Script (Debian/Ubuntu-based systems)

set -e

echo "[*] Checking if Suricata is already installed..."
if command -v suricata &>/dev/null; then
    echo "[✓] Suricata is already installed. Skipping installation."
else
    echo "[*] Installing Suricata dependencies and stable version..."

    # Install required packages
    sudo apt-get update
    sudo apt-get install -y software-properties-common

    # Add the stable Suricata PPA
    sudo add-apt-repository -y ppa:oisf/suricata-stable

    # Update again after adding the new PPA
    sudo apt-get update

    # Install Suricata
    sudo apt-get install -y suricata

    echo "[✓] Suricata installed successfully."
fi

