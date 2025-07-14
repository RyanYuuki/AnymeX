## 📌 How to Choose the Right Version?  

| Platform  | Description |
|-----------|-------------|
| **Android (ARM64)** | For most modern smartphones and tablets (2016 and later). |
| **Android (ARMEABI-v7a)** | For older or budget Android devices (before 2016). |
| **Android (Universal)** | Works on all architectures but may have a larger file size. |
| **Android (x86_64)** | For newer devices with 64-bit Intel processors, typically some tablets. |
| **iOS** | For iPhone and iPad users (install via AltStore or sideloading). |
| **Linux (AppImage)** | Standalone executable for Linux users. |
| **Linux (RPM)** | For RPM-based Linux distributions like Fedora and CentOS. |
| **Linux (ZIP)** | Compressed package for manual installation. |
| **Linux ([AUR](https://aur.archlinux.org/))** | [Binary package](https://aur.archlinux.org/packages/anymex-bin) for Arch Linux. |
| **Windows (ZIP)** | Portable version for Windows. |
| **Windows (Installer)** | Standard Windows installer for easy setup. |


✅ **Android Users:** Check your device’s architecture using *CPU-Z* or *Droid Hardware Info*.  
✅ **Windows Users**:
- **Scoop**: For a portable, auto-updating installation, use the Scoop package manager:
  ```powershell
  scoop bucket add Anymex https://github.com/MiraiEnoki/Anymex_Scoop
  scoop install RyanYuuki/Anymex
  ```
  Run `anymex` to launch the app. Updates are handled automatically via Scoop.
- **ZIP**: Download and extract `AnymeX-Windows.zip` for a portable version.
- **Installer**: Use `AnymeX-x86_64-<version>-Installer.exe` for a standard Windows setup.

✅ **Linux Users:** Choose between installer or portable versions based on your preference.  

---
