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

#### 🔧 AppImage Troubleshooting

If you encounter issues running the AppImage on your Linux distribution, try these solutions:

**For FUSE-related errors** (common on Arch-based distros like CachyOS):
```bash
# Install FUSE if not available
sudo pacman -S fuse2  # On Arch/CachyOS/Manjaro
sudo apt install fuse  # On Debian/Ubuntu
sudo dnf install fuse  # On Fedora/CentOS

# Load the FUSE module
sudo modprobe fuse

# If still having issues, extract and run manually
./AnymeX.AppImage --appimage-extract
./squashfs-root/AppRun
```

**For "Bad address" or "No such file or directory" errors**:
1. Try extracting the AppImage: `./AnymeX.AppImage --appimage-extract`
2. Run the extracted version: `./squashfs-root/AppRun`
3. If that works, the issue is with FUSE - consider using the ZIP version instead

**Distribution-specific notes**:
- **CachyOS/Arch Linux**: The `fuse2` package provides the required FUSE2 support for AppImages
- **Ubuntu 22.04+**: May need `libfuse2` package: `sudo apt install libfuse2`
- **Fedora**: Ensure `fuse` package is installed and the service is enabled

**Alternative installation methods**:
- **AUR (Arch Linux/CachyOS users)**: `yay -S anymex-bin`
- **ZIP version**: Download and extract the ZIP file for manual installation
- **RPM version**: For RPM-based distributions (Fedora, CentOS, openSUSE)
---
