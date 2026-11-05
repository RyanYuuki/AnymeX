# Development Setup Guide

Looking to contribute? Great! Here's some actions that are required to get started.

## Flutter

The bread and butter! Flutter is an open source framework for building beautiful, natively compiled, multi-platform applications from a single codebase. It's also how we make AnymeX.  
Follow the installation guide based on your development platform: [Install | Flutter](https://docs.flutter.dev/get-started/install)

> [!NOTE]  
> This project currently uses Flutter SDK 3.41.6.  
> If you'd like to use multiple versions on your machine, a suggestion is to use [fvm](https://fvm.app/) to manage your different versions

## Java JDK

At the time of writing, you need to install the Java 19 JDK.  
If you maintain multiple versions, you can specify the path directly for Flutter with `flutter config --jdk-dir=/path/to/jdk`.

> [!NOTE]  
> For users of Homebrew (MacOS), you'll need to install the JDK manually  
> This is because Java 19 is EoL and the cask has been pruned  
> If you'd like to use multiple versions on your machine, a suggestion is to use [jEnv](https://github.com/jenv/jenv) to manage your different versions

## Simulators

If you're looking to test your changes on a virtual device, we recommend you get set up with [Android Studio (Android)](https://developer.android.com/studio) and/or [Xcode (iOS)](https://developer.apple.com/xcode/).

> [!NOTE]  
> Xcode and the iOS simulator is only available on MacOS (or via. VM)

## .env file

Flutter will not run/build the app if the environment file is missing.  
You can stub these values for local development purposes.  
To do so, create a `.env` file with the following content:

```env
AL_CLIENT_ID=0
AL_CLIENT_SECRET=0
SIMKL_CLIENT_ID=0
SIMKL_CLIENT_SECRET=0
MAL_CLIENT_ID=0
MAL_CLIENT_SECRET=0
CALLBACK_SCHEME=anymex://callback
COMMENTS_BASE_URL=https://whzwmfxngelicmjyxwmr.supabase.co/functions/v1
```

You can however create your own API keys and populate the values as necessary.

### AniList

| Key         | Value             |
| ------------| ----------------- |
| Name        | *any*             |
| Redirect URL| anymex://callback |

### Simlk

| Key         | Value             |
| ------------| ----------------- |
| tbd         | *tbd*             |
| tbd         | tbd               |

### My Anime List

| Key         | Value             |
| ------------| ----------------- |
| tbd         | *tbd*             |
| tbd         | tbd               |


## Run the App

Time to see your changes come to life? If you've made any changes to the packages it's best to run `clean` and then `pub get`.

```sh
flutter clean
flutter pub get
flutter run
```

## Build the App

Release builds need the `.env` file above. Each platform must be built on its own OS (macOS for iOS/macOS, Windows for Windows, Linux for Linux).

### Android

Release builds are signed with the key in `android/key.properties` (git-ignored, never commit it):

```properties
storeFile=C:/path/to/your-release.jks
storePassword=your-store-password
keyAlias=your-key-alias
keyPassword=your-key-password
```

No keystore yet? Create one with `keytool -genkey -v -keystore release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias anymex`.

```sh
flutter build apk --release                                  # universal APK
flutter build apk --release --split-per-abi                  # one APK per CPU (smaller)
flutter build apk --release --target-platform android-arm64  # modern phones only
```

Output: `build/app/outputs/flutter-apk/`.

> [!NOTE]  
> Android only lets you update an app signed with the same key. Switching keys means uninstalling first, which wipes app data.

### Windows

Needs Visual Studio with the **Desktop development with C++** workload, plus [Inno Setup 6](https://jrsoftware.org/isinfo.php) for the installer.

```sh
flutter build windows --release            # app in build/windows/x64/runner/Release
dart run inno_bundle:build --release       # generates the installer script
```

### Linux

```sh
sudo apt-get install ninja-build cmake clang mpv libgtk-3-dev libblkid-dev liblzma-dev pkg-config libmpv-dev webkit2gtk-4.1
flutter build linux --release              # app in build/linux/x64/release/bundle
```

### macOS / iOS

Needs Xcode.

```sh
flutter build macos --release
flutter build ios --release --no-codesign  # unsigned; sign or sideload the .ipa yourself
```

### Build every platform with GitHub Actions

The **Build and Release AnymeX** workflow (`.github/workflows/build.yml`) builds Android, iOS, Linux, Windows and macOS, then publishes a GitHub Release.

1. On a fork, enable Actions first: **Actions** tab → *I understand my workflows, go ahead and enable them*.
2. Add repository secrets under **Settings → Secrets and variables → Actions**:

   | Secret | Purpose |
   | --- | --- |
   | `KEYSTORE_BASE64` | Android keystore, base64-encoded (`base64 -w0 release.jks`) |
   | `KEYSTORE_PASSWORD` | Keystore password (also used as the key password) |
   | `KEY_ALIAS` | Key alias |
   | `AL_CLIENT_ID`, `AL_CLIENT_SECRET` | AniList login |
   | `MAL_CLIENT_ID`, `MAL_CLIENT_SECRET` | MyAnimeList login |
   | `SIMKL_CLIENT_ID`, `SIMKL_CLIENT_SECRET` | Simkl login |
   | `CALLBACK_SCHEME`, `COMMENTS_BASE_URL` | Same values as your `.env` |

   The Android build fails without the three keystore secrets; missing login secrets only disable those logins.
3. Run it: **Actions → Build and Release AnymeX → Run workflow → `main`**, or push a tag like `v1.2.3`.

Artifacts appear on the run page; the release appears under **Releases** once every platform succeeds. The AUR/Scoop/Chocolatey publish step fails on forks without those tokens, which doesn't affect the release.

## Troubleshooting

### Flutter Related

Your first course of action should always be `flutter doctor`.  
We'd also recommend reading and parsing the error output, as Flutter is quite verbose and helpful when it comes to the stack trace.

## Community

Feel free to reach out on Discord, we're always happy to assist someone who's trying to contribute to the project.
