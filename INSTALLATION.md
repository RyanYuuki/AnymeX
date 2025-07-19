# Installation Guide for AnymeX

## 📌 Which Version Should You Download?

| Platform | Use this if... |
|----------|----------------|
| **Android (ARM64)** | You're using a modern phone (2016+). |
| **Android (ARMEABI-v7a)** | You're on an older or budget Android device. |
| **Android (Universal)** | You're unsure about your device—works on all. |
| **Android (x86_64)** | You use a tablet or emulator with a 64-bit Intel chip. |
| **iOS** | You want to install on iPhone or iPad (via AltStore/sideload). |
| **Linux (AppImage)** | You want a standalone, click-to-run file. |
| **Linux (RPM)** | You're on Fedora, CentOS, or another RPM-based distro. |
| **Linux (ZIP)** | You prefer manual setup or portable use. |
| **Linux ([AUR](https://aur.archlinux.org/))** | You're on Arch Linux — use [`anymex-bin`](https://aur.archlinux.org/packages/anymex-bin). |
| **Windows (ZIP)** | You want a portable version (no installer). |
| **Windows (Installer)** | You prefer the standard install process. |

---

## ✅ Tips for Installation

### 🔹 Android

Use [CPU-Z](https://play.google.com/store/apps/details?id=com.cpuid.cpu_z) or [Droid Info](https://play.google.com/store/apps/details?id=com.inkwired.droidinfo) to check your device's architecture.

---

### 🔹 Windows (via Chocolatey)

**Install using Chocolatey (recommended for package management):**

1. **Install Chocolatey (if not already):**
   Open Command Prompt (`cmd`) or PowerShell (`pwsh`) as Administrator and run:
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
   ```
2. **Install AnymeX:**
   In Command Prompt or PowerShell, run:
   ```powershell
   choco install com.ryan.anymex
   ```
3. **Update later with:**
   In Command Prompt or PowerShell, run:
   ```powershell
   choco upgrade com.ryan.anymex
   ```
---

### 🔹 Windows (via Scoop)
**Install using Scoop (recommended for power users):**

1. **Install Scoop (if not already):**
   Open Command Prompt (`cmd`) or PowerShell (`pwsh`) and run:
   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   irm get.scoop.sh | iex
   ```
2. **Add the Anymex bucket:**
   In Command Prompt or PowerShell, run:
   ```powershell
   scoop bucket add Anymex https://github.com/MiraiEnoki/Anymex_Scoop
   ```
3. **Install the app:**
   In Command Prompt or PowerShell, run:
   ```powershell
   scoop install anymex
   ```
4. **Update later with:**
   In Command Prompt or PowerShell, run:
   ```powershell
   scoop update anymex
   ```
---

### 🔹 Windows (ZIP or Installer)
- **ZIP**: Download `AnymeX-Windows.zip`, extract, and run `anymex.exe`.
- **Installer**: Use `AnymeX-x86_64-<version>-Installer.exe` for full setup.
---

### 🔹 Linux
- **AppImage**: Make it executable and run:
  ```bash
  chmod +x AnymeX.AppImage
  ./AnymeX.AppImage
  ```
- **RPM/ZIP**: Choose based on your distro or install style.
---
