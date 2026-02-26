#!/bin/bash
set -e

# Configuration
KERNEL_DIR="android_kernel"
TOOLCHAIN_DIR="android_kernel/toolchain"
DRIVER_DIR="rtl8192eu"
DRIVER_REPO="https://github.com/Mange/rtl8192eu-linux-driver.git"
DRIVER_COMMIT="d53a23d" # March 2019, likely compatible with 3.18

export ARCH=arm64
export CROSS_COMPILE=$(pwd)/$TOOLCHAIN_DIR/bin/aarch64-linux-android-

# Ensure kernel is built
if [ ! -f "$KERNEL_DIR/arch/arm64/boot/Image.gz-dtb" ]; then
    echo "Error: Kernel artifact not found. Please run ./build_kernel.sh first."
    exit 1
fi

echo "Setting up Driver Source..."
if [ ! -d "$DRIVER_DIR" ]; then
    echo "Cloning driver repository..."
    git clone "$DRIVER_REPO" "$DRIVER_DIR"
    cd "$DRIVER_DIR"
    echo "Checking out compatible commit..."
    git checkout "$DRIVER_COMMIT"
    cd ..
else
    echo "Driver directory exists."
fi

echo "Applying Driver Patches..."
cd "$DRIVER_DIR"
# Check if patch is already applied to avoid error
if grep -q "WLAN_CATEGORY_WNM" include/ieee80211.h; then
    echo "Patch already applied."
else
    if patch -p1 < ../rtl8192eu_3.18.patch; then
        echo "Patch applied successfully."
    else
        echo "Failed to apply patch."
        exit 1
    fi
fi

# Fix Makefile recursion issue if present
sed -i 's/EXTRA_CFLAGS += $(ccflags-y)/#EXTRA_CFLAGS += $(ccflags-y)/' Makefile

echo "Building RTL8192EU Module..."
# Clean previous builds
make clean

# Build module against the kernel source
# We need to explicitly set KSRC to point to our kernel directory
make -j$(nproc) ARCH=arm64 CROSS_COMPILE=$CROSS_COMPILE KSRC=../$KERNEL_DIR modules

if [ -f "8192eu.ko" ]; then
    echo "Module build successful!"
    ls -lh 8192eu.ko
    # Check vermagic if modinfo is available
    if command -v modinfo >/dev/null 2>&1; then
        modinfo 8192eu.ko
    else
        strings 8192eu.ko | grep "vermagic="
    fi
else
    echo "Module build failed!"
    exit 1
fi
