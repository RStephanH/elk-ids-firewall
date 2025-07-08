#!/bin/bash

set -euo pipefail

# --------------------------
# Snort 3 Dependency Installer
# --------------------------

WORKDIR="$HOME/snort3-deps"
FLEX_VERSION_REQUIRED="2.6.0"

echo "🚀 Updating APT package list..."
sudo apt update -y

echo "📦 Installing base build dependencies..."
sudo apt install -y \
    cmake g++ flex bison libpcap-dev libpcre2-dev zlib1g-dev \
    pkg-config libhwloc-dev luajit libssl-dev git build-essential \
    automake autoconf libtool curl wget texinfo gettext autopoint check

mkdir -p "$WORKDIR"
pushd "$WORKDIR" > /dev/null

# Function to clone or pull a Git repo
clone_or_pull() {
    local repo_url="$1"
    local dir_name="$2"
    if [ -d "$dir_name" ]; then
        echo "🔄 Updating $dir_name..."
        git -C "$dir_name" pull
    else
        echo "📥 Cloning $dir_name..."
        git clone "$repo_url" "$dir_name"
    fi
}

# ---- libdaq ----
echo "🔧 Building libdaq..."
clone_or_pull https://github.com/snort3/libdaq.git libdaq
pushd libdaq > /dev/null
./bootstrap
./configure
make -j"$(nproc)"
sudo make install
popd > /dev/null

# ---- libdnet ----
echo "🔧 Building libdnet..."
clone_or_pull https://github.com/dugsong/libdnet.git libdnet
pushd libdnet > /dev/null
./configure
make -j"$(nproc)"
sudo make install
popd > /dev/null

# ---- Flex ----
echo "🔧 Building Flex (required >= $FLEX_VERSION_REQUIRED)..."
clone_or_pull https://github.com/westes/flex.git flex
pushd flex > /dev/null
./autogen.sh
./configure
make -j"$(nproc)"
sudo make install
popd > /dev/null

# ---- LuaJIT ----
if ! command -v luajit &> /dev/null; then
    echo "🔧 LuaJIT not found. Building from source..."
    clone_or_pull https://luajit.org/git/luajit.git luajit
    pushd luajit > /dev/null
    make -j"$(nproc)"
    sudo make install
    popd > /dev/null
else
    echo "✅ LuaJIT is already installed."
fi

popd > /dev/null

echo "✅ All Snort 3 dependencies are installed!"
echo "📁 Ready to build Snort 3 in a clean environment."

# Optional cleanup
echo "🧹 Cleaning up unnecessary build-time packages..."
sudo apt remove -y flex || true

echo "🎉 Done!"

