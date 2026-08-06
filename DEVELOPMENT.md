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

## Windows: First-time libtorrent setup

The `libtorrent_flutter` plugin ships prebuilt native binaries for every
platform. On Windows, the plugin's auto-download step fails through
Flutter's `.plugin_symlinks/` junction (`CMake Error: Cannot extract
through symlink`), which then cascades into a `find_package(LibtorrentRasterbar REQUIRED)`
failure because libtorrent-rasterbar isn't installed.

To work around this, run **once** after `flutter pub get` and before
`flutter build windows`:

```powershell
pwsh ./scripts/setup_libtorrent_windows.ps1
```

This drops the prebuilt `libtorrent_flutter.dll` into the plugin's
`prebuilt/windows/x64/` directory in your pub cache, so CMake's
download block is skipped entirely. Re-run it only when the plugin
version changes (i.e. after a `flutter pub upgrade` that bumps
libtorrent_flutter).

> [!NOTE]
> Linux and macOS don't need this — their plugin CMake/CocoaPods
> download paths work out of the box.

## Run the App

Time to see your changes come to life? If you've made any changes to the packages it's best to run `clean` and then `pub get`.

```sh
flutter clean
flutter pub get
flutter run
```

## Troubleshooting

### Flutter Related

Your first course of action should always be `flutter doctor`.  
We'd also recommend reading and parsing the error output, as Flutter is quite verbose and helpful when it comes to the stack trace.

## Community

Feel free to reach out on Discord, we're always happy to assist someone who's trying to contribute to the project.
