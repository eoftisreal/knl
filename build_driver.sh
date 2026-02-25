#!/bin/bash
set -e

# Configuration
KERNEL_DIR="android_kernel"
TOOLCHAIN_DIR="android_kernel/toolchain"
DRIVER_DIR="rtl8192eu"

export ARCH=arm64
export CROSS_COMPILE=$(pwd)/$TOOLCHAIN_DIR/bin/aarch64-linux-android-

echo "Building RTL8192EU Module..."
cd "$DRIVER_DIR"

# Clean previous builds
make clean

# Build module against the kernel source
# We need to explicitly set KSRC to point to our kernel directory
make -j$(nproc) ARCH=arm64 CROSS_COMPILE=$CROSS_COMPILE KSRC=../$KERNEL_DIR modules

if [ -f "8192eu.ko" ]; then
    echo "Module build successful!"
    ls -lh 8192eu.ko
    modinfo 8192eu.ko
else
    echo "Module build failed!"
    exit 1
fi
