#!/bin/bash
set -e

# Configuration
KERNEL_REPO="https://github.com/samsungexynos7870/android_kernel_samsung_exynos7870"
KERNEL_BRANCH="simple_q_enforcing"
TOOLCHAIN_REPO="https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9"
DEFCONFIG="exynos7870-j7xelte_defconfig"
KERNEL_DIR="android_kernel"
TOOLCHAIN_DIR="toolchain"
ARTIFACT="arch/arm64/boot/Image.gz-dtb"

echo "Setting up build environment..."
# Check for dependencies (this assumes apt-get is available, but the script can be run in the sandbox)
if command -v apt-get >/dev/null; then
    sudo apt-get update
    sudo apt-get install -y bc bison flex libssl-dev libncurses5-dev
fi

# Create directory
mkdir -p "$KERNEL_DIR"

echo "Cloning Kernel Source..."
if [ ! -d "$KERNEL_DIR/.git" ]; then
    git clone "$KERNEL_REPO" -b "$KERNEL_BRANCH" "$KERNEL_DIR" --depth=1
else
    echo "Kernel source already exists."
fi

echo "Cloning Toolchain..."
if [ ! -d "$KERNEL_DIR/$TOOLCHAIN_DIR" ]; then
    git clone "$TOOLCHAIN_REPO" "$KERNEL_DIR/$TOOLCHAIN_DIR" --depth=1
else
    echo "Toolchain already exists."
fi

echo "Applying DTC patch for GCC 10+ compatibility..."
cd "$KERNEL_DIR"
if patch -p1 < ../fix_dtc.patch; then
    echo "Patch applied successfully."
else
    echo "Patch failed or already applied."
fi

echo "Configuring Kernel..."
export ARCH=arm64
export CROSS_COMPILE=$(pwd)/$TOOLCHAIN_DIR/bin/aarch64-linux-android-

# Ensure python points to python3 if not present (needed for some toolchain scripts)
if ! command -v python &> /dev/null; then
    sudo ln -s $(which python3) /usr/bin/python || true
fi

make "$DEFCONFIG"

echo "Building Kernel..."
# Disable ccache to avoid dependency issues in minimal environments
make -j$(nproc) CCACHE= Image.gz-dtb

if [ -f "$ARTIFACT" ]; then
    echo "Build Successful!"
    echo "Artifact: $KERNEL_DIR/$ARTIFACT"
    ls -lh "$ARTIFACT"
else
    echo "Build Failed!"
    exit 1
fi
