# Samsung Galaxy J7 2016 (j7xelte) Custom Kernel Project

This project aims to build a custom Android 10 kernel for the Samsung Galaxy J7 2016 (SM-J710FN) with support for the Realtek RTL8192EU wireless adapter, including monitor mode and packet injection.

## Project Structure

*   `android_kernel/`: Directory where the kernel source will be cloned (not tracked in git).
*   `rtl8192eu/`: Directory where the driver source will be cloned (not tracked in git).
*   `build_kernel.sh`: Script to download dependencies, clone sources, and build the kernel.
*   `build_driver.sh`: Script to compile the RTL8192EU driver module against the built kernel.
*   `check_requirements.sh`: Script to verify critical kernel configuration options.
*   `fix_dtc.patch`: Patch for `scripts/dtc` to fix build errors on modern GCC hosts.
*   `rtl8192eu_3.18.patch`: Patch for the wireless driver to fix API compatibility with kernel 3.18.
*   `BUILD_REPORT.md`: Detailed report on the build environment, artifacts, and verification.

## Instructions

### 1. Build the Kernel

Run the `build_kernel.sh` script. This will:
1.  Install necessary build dependencies (on Debian/Ubuntu systems).
2.  Clone the kernel source (branch `simple_q_enforcing`) and the GCC 4.9 toolchain.
3.  Apply the `fix_dtc.patch` to resolve host compiler issues.
4.  Configure the kernel (`exynos7870-j7xelte_defconfig`).
5.  Build the kernel image (`Image.gz-dtb`).

```bash
./build_kernel.sh
```

**Artifact:** `android_kernel/arch/arm64/boot/Image.gz-dtb`

### 2. Verify Configuration

Run the requirements check script to ensure the kernel configuration supports module loading and wireless networking.

```bash
./check_requirements.sh
```

### 3. Build the Driver

Run the `build_driver.sh` script. This will:
1.  Clone the RTL8192EU driver source (older compatible branch).
2.  Apply `rtl8192eu_3.18.patch` to fix missing constants.
3.  Compile the driver module (`8192eu.ko`) linking against the kernel built in Step 1.

```bash
./build_driver.sh
```

**Artifact:** `rtl8192eu/8192eu.ko`

## Verification

After building, verify that the `8192eu.ko` module has the correct version magic ("vermagic") matching the kernel version (3.18.140).

```bash
modinfo rtl8192eu/8192eu.ko
# Expected: vermagic: 3.18.140-SIMPLE-KERNEL_V1.0 SMP preempt mod_unload modversions aarch64
```

## Technical Notes

*   **Kernel Source**: [samsungexynos7870/android_kernel_samsung_exynos7870](https://github.com/samsungexynos7870/android_kernel_samsung_exynos7870) (Branch: `simple_q_enforcing`)
*   **Toolchain**: [LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9](https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9)
*   **Driver Source**: [Mange/rtl8192eu-linux-driver](https://github.com/Mange/rtl8192eu-linux-driver) (Commit `d53a23d`)
*   **Patches**:
    *   `fix_dtc.patch`: Fixes `multiple definition of 'yylloc'` error in `dtc-lexer`.
    *   `rtl8192eu_3.18.patch`: Adds `WLAN_CATEGORY_WNM` and `WLAN_CATEGORY_WNM_UNPROTECTED` definitions missing in kernel 3.18 headers.
*   **CCACHE**: The build scripts explicitly disable `ccache` (`CCACHE=`) to prevent failures in environments where it is not installed or configured.
