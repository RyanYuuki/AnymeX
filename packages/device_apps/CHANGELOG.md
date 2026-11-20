# Changelog

## [2.2.0] - 1st April 2022

* Uninstall an application
* Fix issue #81

## [2.1.1] - 23th April 2021

* AndroidX annotations are now required as a dependency 

## [2.1.0] - 12th April 2021

* [BREAKING CHANGE] [Following Google Play change with the `QUERY_ALL_PACKAGES`](https://support.google.com/googleplay/android-developer/answer/10158779), by default this plugin won't request anymore this permission.
If you want to keep the current behavior, you have to add the permission again to the Android Manifest (cf `README`).

## [2.0.2] - 01th April 2021

* Fix bug #69

## [2.0.1] - 23th March 2021

* Fix many regressions introduced in 2.0.0

## [2.0.0] - 06th March 2021

* Null safety support

## [1.3.0] - 06th March 2021

* New feature: listen to app changes (installation, uninstallation, updates…)
* New field on the `Application` class: whether the app is enabled or not

## [1.2.1] - 06th March 2021

* Ability to open the settings screen of an app : `DeviceApps.openAppSettings(packageName)`
* New methods on the `Application` class : `openApp()` and `openAppSettings()`
* Fix for issue #61 (crash on some Android 10 devices)

## [1.2.0] - 09th August 2020

* Support for Android 11. 

Please read the README file.

## [1.1.2] - 09th August 2020

* Fix issue #49

## [1.1.1+1] - 05th August 2020

* Remove pub warning

## [1.1.1] - 05th August 2020

* Fix wrong category (productivity was recognized as a game)

## [1.1.0] - 18th July 2020

* Migration to the Plugin V2 embedding system
* Fix a crash on devices with an API level lower than 26
* Fix a NPE crash when the plugin was called in the background

## [1.0.10] - 25th June 2020

* Fix typo installTimeMilis -> installTimeMillis
* Fix typo updateTimeMilis -> updateTimeMillis
* Support for the app category (PR #37)

## [1.0.9] - 13th December 2019

* Add path to APK file (PR #16)
* Add install and update time fields (PR #18)
* Add a missing break statement when opening the app
* Fix warnings in the code

## [1.0.8] - 29th May 2019

* Fix issue #11 (>= Flutter 1.6)

## [1.0.7] - 3rd April 2019

* The version code is now available in the Dart code

## [1.0.6] - 21th February 2019

* For each application, you have now access to the "data directory" path (thanks to Ryan Gonzalez)

## [1.0.5] - 21th January 2019

* Some tests apps does not have a _version_name_. From now on, the plugin will just ignore them

## [1.0.4] - 27th December 2018

* Ability to filter only launchable apps (thanks to Damodar Lohani)

## [1.0.3] - 17th December 2018

* Some asserts added + a different class is used when an icon is passed

## [1.0.2] - 15th December 2018

* Support for the application icon (thanks to Damodar Lohani)
* Fetching the applications list is now processed in a background thread in the Android code

## [1.0.1] - 30th October 2018

* New attribute to detect whether the app is user or system

## [1.0.0] - 6th June 2018

* Initial release (support for Android only)
