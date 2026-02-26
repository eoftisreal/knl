#!/bin/bash
set -e

# Configuration
KERNEL_DIR="android_kernel"
TOOLCHAIN_DIR="android_kernel/toolchain"
DRIVER_DIR="rtl8192eu"
DRIVER_REPO="https://github.com/Mange/rtl8192eu-linux-driver.git"
DRIVER_BRANCH="realtek-4.4.x"
DRIVER_COMMIT="d53a23d" # March 2019, likely compatible with 3.18

export ARCH=arm64
export CROSS_COMPILE=$(pwd)/$TOOLCHAIN_DIR/bin/aarch64-linux-android-

# Ensure kernel is built
if [ ! -f "$KERNEL_DIR/arch/arm64/boot/Image.gz-dtb" ]; then
    echo "Error: Kernel artifact not found. Please run ./build_kernel.sh first."
    exit 1
fi

echo "Setting up Driver Source..."

# Validation: If directory exists but is not a git repo, wipe it.
if [ -d "$DRIVER_DIR" ] && [ ! -d "$DRIVER_DIR/.git" ]; then
    echo "Warning: $DRIVER_DIR exists but is not a valid git repository. Removing..."
    rm -rf "$DRIVER_DIR"
fi

# Clone if missing
if [ ! -d "$DRIVER_DIR" ]; then
    echo "Cloning driver repository..."
    git clone "$DRIVER_REPO" "$DRIVER_DIR"
else
    echo "Driver directory exists. Checking state..."
fi

# Go into driver dir
cd "$DRIVER_DIR"

# Ensure we are on the right commit and clean
echo "Resetting to compatible commit..."
# Fetch the specific branch to ensure we have the commit history
# Use --quiet to reduce noise
git fetch origin "$DRIVER_BRANCH" || git fetch origin

if ! git checkout "$DRIVER_COMMIT"; then
    echo "Commit not found. Attempting full fetch..."
    git fetch --unshallow || true
    git fetch --all
    git checkout "$DRIVER_COMMIT"
fi

git reset --hard "$DRIVER_COMMIT"
git clean -fdx

echo "Applying Driver Patches..."
# We are inside DRIVER_DIR now, patch is in parent dir
if patch -p1 < ../rtl8192eu_3.18.patch; then
    echo "Patch applied successfully."
else
    echo "Failed to apply patch."
    exit 1
fi

# Fix Makefile recursion issue
sed -i 's/EXTRA_CFLAGS += $(ccflags-y)/#EXTRA_CFLAGS += $(ccflags-y)/' Makefile

echo "Building RTL8192EU Module..."
# Clean previous builds (redundant after git clean but good practice)
make clean

# Build module against the kernel source
# We need to explicitly set KSRC to point to our kernel directory
# DRIVER_DIR is cwd, KERNEL_DIR is ../$KERNEL_DIR
# Disable ccache to avoid dependency issues
make -j$(nproc) ARCH=arm64 CROSS_COMPILE=$CROSS_COMPILE KSRC=../$KERNEL_DIR CCACHE= modules

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
