<div align="center">
  <h1>🐉 NetHunter Custom Kernel 🐉</h1>
  <h3>for Realme 9 Pro 5G (oscar)</h3>
  
  <p>
    <a href="https://github.com/sirt-sirt/oscar-nethunter-custom_kernel/actions/workflows/build-kernel.yml">
      <img src="https://github.com/sirt-sirt/oscar-nethunter-custom_kernel/actions/workflows/build-kernel.yml/badge.svg" alt="Build Status">
    </a>
  </p>
</div>

---

## 📱 Supported Devices
* **Device:** Realme 9 Pro 5G
* **Codename:** `oscar` (RMX3471 / RMX3472)
* **SoC:** Qualcomm Snapdragon 695 5G (`sm6375` / `holi`)
* **Base ROM:** LineageOS 21 (Android 14)
* **Kernel Version:** Linux 5.4.280-qgki

---

## ⚡ Features (NetHunter Patches)

This kernel has been heavily patched and customized specifically for **Kali NetHunter** penetration testing.

### 🛡️ Kali Chroot Support
* **System V IPC (`SYSVIPC`)**: Fully enabled for PostgreSQL and Metasploit database operation.
* **Linux Namespaces**: Full isolation support enabled (`PID_NS`, `NET_NS`, `USER_NS`, `IPC_NS`, `UTS_NS`) to allow rootless execution and proper NetHunter chroot environments.

### 📡 Wireless & Packet Injection (Monitor Mode)
* **Wireless Extensions (`CFG80211_WEXT`)**: Enabled to support legacy tools like `airodump-ng` and `aireplay-ng`.
* **Realtek Vendor Support**: Activated staging drivers for external Wi-Fi adapters.
* **Compiled Modules**: `r8188eu.ko` (TP-Link TL-WN722N v2/v3), `rtl8xxxu.ko`, and required crypto libraries (`lib80211`) are built inline and flashed automatically via AnyKernel3.

### 🔌 USB OTG & External Hardware
* **USB Serial / ACM**: Enabled `CONFIG_USB_ACM`, `CONFIG_USB_SERIAL` for SDRs and RFID tools (Proxmark3, HackRF One).
* **Serial Adapters**: Support for `PL2303`, `FTDI_SIO`, `CH341`, and `CP210X` chips (covers 90% of external wireless adapters and hacking dongles).
* **Bluetooth**: `CONFIG_BT_HCIBTUSB` enabled for external USB Bluetooth adapters (e.g. CSR8510) and `BT_BNEP` for Bluetooth network encapsulation and attacks.

### 🛠️ Engineering Fixes
* **LTO & CFI Removed**: Disabled `CONFIG_LTO_CLANG` and `CONFIG_CFI_CLANG` to fix critical `ld.lld: R_AARCH64_ABS32` relocation linking errors and bypass rigid Control Flow Integrity checks that conflict with packet injection.
* **Windows File-System Fix**: Resolved critical git clone case-sensitivity collisions in the `net/netfilter` subsystem (e.g. `xt_dscp.c` vs `xt_DSCP.c`) which previously broke compilation of `iptables` and VPN functions.
* **Proton Clang**: Compiled using modern Proton Clang 13.0.0 with forced LLVM linker and assembler.

---

## 📦 Installation

This kernel is packaged with **AnyKernel3** and installs perfectly over LineageOS without replacing your vendor partitions or `ocdt`.

1. Go to the **[Actions](https://github.com/sirt-sirt/oscar-nethunter-custom_kernel/actions)** tab.
2. Click on the latest successful **Build NetHunter Kernel (oscar)** run.
3. Download the `NetHunter-Kernel-oscar.zip` artifact at the bottom of the page.
4. Extract the downloaded ZIP **once** to get the actual flashable `NetHunter-Kernel-oscar.zip`.
5. Flash via:
   * **Lineage Recovery / TWRP:** `Apply Update` -> `Choose from SD card` (or `adb sideload`).
   * **Magisk:** Modules -> Install from Storage.
6. Reboot and enjoy!

---

## ⚙️ Compilation (GitHub Actions)

You don't need a local Linux machine to build this. Just use GitHub Actions!
1. Fork this repository.
2. Go to the `Actions` tab and enable workflows.
3. Select `Build NetHunter Kernel (oscar)` and click **Run workflow**.
4. The `.ko` modules and the kernel `Image` will be automatically packaged into an AnyKernel3 zip.

> **Note:** The AnyKernel script has `do.modules=1` which automatically pushes the Realtek Wi-Fi modules to your device during flashing.

---
*Built with ❤️ for the cybersec community.*
