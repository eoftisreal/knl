#!/bin/bash
set -e

CONFIG_FILE="android_kernel/.config"

check_config() {
    if grep -q "$1" "$CONFIG_FILE"; then
        echo "PASS: $1 found"
    else
        echo "FAIL: $1 missing"
        exit 1
    fi
}

check_config "CONFIG_MODULES=y"
check_config "CONFIG_MODULE_UNLOAD=y"
check_config "CONFIG_MODVERSIONS=y"
check_config "CONFIG_CFG80211=y"
check_config "CONFIG_WIRELESS=y"
check_config "CONFIG_PACKET=y"
check_config "CONFIG_NETFILTER=y"
check_config "CONFIG_FW_LOADER=y"

echo "All critical kernel configuration flags verified."
