#!/bin/bash

set -euo pipefail

### -------------------------------
### 🐷 Snort3 Installer Config
### -------------------------------
SNORT_REPO_URL="https://github.com/snort3/snort3.git"
SNORT_REPO_DIR="$HOME/snort3-src"
INSTALL_DIR="/usr/local"  # So binaries go into /usr/local

### -------------------------------
### 📦 Install Dependencies
### -------------------------------
ensure_dependencies() {
    gum spin --title "🐷 Installing build dependencies..." --spinner monkey -- \
    sudo apt update -y && sudo apt install -y git cmake g++ libpcap-dev libpcre2-dev \
        zlib1g-dev pkg-config libhwloc-dev luajit libssl-dev \
        build-essential automake autoconf libtool curl wget bison flex \
        liblzma-dev

    gum style --foreground 42 "✅ Dependencies installed."
}

### -------------------------------
### 📥 Clone Snort3 Repo
### -------------------------------
clone_snort3() {
    if [ ! -d "$SNORT_REPO_DIR" ]; then
        gum spin --title "📥 Cloning Snort3 source..." --spinner globe -- \
        git clone --depth=1 "$SNORT_REPO_URL" "$SNORT_REPO_DIR"
    else
        gum style --foreground 214 "📁 Snort3 already cloned at $SNORT_REPO_DIR"
    fi
}

### -------------------------------
### 🛠️ Build & Install
### -------------------------------
build_and_install_snort3() {
    gum style --foreground 87 "⚙️ Configuring Snort3 with prefix: $INSTALL_DIR"
    pushd "$SNORT_REPO_DIR" > /dev/null

    ./configure_cmake.sh --prefix="$INSTALL_DIR"

    mkdir -p build
    pushd build > /dev/null

    gum spin --title "🔨 Compiling Snort3 (make -j$(nproc))..." --spinner line -- \
    make -j"$(nproc)"

    gum spin --title "📦 Installing Snort3 to $INSTALL_DIR..." --spinner dot -- \
    make install

    popd > /dev/null
    popd > /dev/null

    gum style --foreground 48 "✅ Snort3 installed to $INSTALL_DIR/bin"
}

### -------------------------------
### 🛣️ Add ~/.local/bin to PATH
### -------------------------------
ensure_path_config() {
    if [[ ":$PATH:" != *":$INSTALL_DIR/bin:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        gum style --foreground 208 "📎 Added ~/.local/bin to PATH in ~/.bashrc"
        gum style --italic "🔁 Run 'source ~/.bashrc' or restart your terminal."
    else
        gum style --foreground 36 "✅ ~/.local/bin is already in PATH"
    fi
}

### -------------------------------
### 🐷 Run All
### -------------------------------
gum style --bold --foreground 205 "🐷 Snort3 Build & Installer Script"

sudo -v #to avoid password typing 
ensure_dependencies
clone_snort3
build_and_install_snort3
ensure_path_config

gum style --border double --padding "1 2" --foreground 10 "🎉 Snort3 is ready! Run: snort -V"

