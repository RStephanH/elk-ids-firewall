#!/bin/bash

set -euo pipefail

### -------------------------------
### 🔧 Configuration
### -------------------------------
SNORT_REPO_URL="https://github.com/snort3/snort3.git"
SNORT_REPO_DIR="$HOME/snort3-src"
INSTALL_DIR="/opt/snort3"
LINK_PATH="/usr/local/bin/snort"

### -------------------------------
### 📦 Ensure required packages
### -------------------------------
ensure_dependencies() {
    echo "🔍 Installing required packages..."
    sudo apt update -y
    sudo apt install -y git cmake g++ libpcap-dev libpcre2-dev \
        zlib1g-dev pkg-config libhwloc-dev luajit libssl-dev \
        build-essential automake autoconf libtool curl wget bison flex \
        liblzma-dev
}

### -------------------------------
### 📥 Clone Snort3 repo
### -------------------------------
clone_snort3() {
    if [ ! -d "$SNORT_REPO_DIR" ]; then
        echo "📥 Cloning Snort3 into $SNORT_REPO_DIR..."
        git clone --depth=1 "$SNORT_REPO_URL" "$SNORT_REPO_DIR"
    else
        echo "📁 Snort3 already cloned at $SNORT_REPO_DIR"
    fi
}

### -------------------------------
### 🛠️ Build and install
### -------------------------------
build_and_install_snort3() {
    echo "⚙️  Configuring Snort3 build..."
    pushd "$SNORT_REPO_DIR" > /dev/null

    ./configure_cmake.sh --prefix="$INSTALL_DIR"

    echo "🔨 Building Snort3..."
    pushd build > /dev/null
    make -j"$(nproc)"
    echo "📦 Installing to $INSTALL_DIR..."
    sudo mkdir -p "$INSTALL_DIR"
    sudo make install
    popd > /dev/null
    popd > /dev/null
}

### -------------------------------
### 🔗 Add to PATH via symlink
### -------------------------------
add_snort_to_path() {
    SNORT_BIN="$INSTALL_DIR/bin/snort"

    if [ ! -f "$SNORT_BIN" ]; then
        echo "❌ Error: $SNORT_BIN does not exist."
        exit 1
    fi

    echo "🔗 Linking Snort to $LINK_PATH..."
    sudo ln -sf "$SNORT_BIN" "$LINK_PATH"
    echo "✅ You can now run Snort from anywhere: type 'snort -V'"
}

### -------------------------------
### 🚀 Main
### -------------------------------
echo "🚀 Starting Snort3 build and install..."
ensure_dependencies
clone_snort3
build_and_install_snort3
add_snort_to_path
echo "🎉 Done! Run: snort -V"

