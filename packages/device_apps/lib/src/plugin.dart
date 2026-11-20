import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'model/application_category.dart';
import 'model/application_event.dart';

/// Plugin to list applications installed on an Android device
/// iOS is not supported
class DeviceApps {
  static const MethodChannel _methodChannel =
      MethodChannel('g123k/device_apps');
  static const EventChannel _eventChannel =
      EventChannel('g123k/device_apps_events');

  /// List installed applications on the device
  /// [includeSystemApps] will also include system apps (or pre-installed) like
  /// Phone, Settings...
  /// [includeAppIcons] will also include the icon for each app (be aware that
  /// this feature is memory-heaving, since it will load all icons).
  /// To get the icon you have to cast the object to [ApplicationWithIcon]
  /// [onlyAppsWithLaunchIntent] will only list applications when an entrypoint.
  /// It is similar to what a launcher will display
  static Future<List<Application>> getInstalledApplications({
    bool includeSystemApps: false,
    bool includeAppIcons: false,
    bool onlyAppsWithLaunchIntent: false,
  }) async {
    try {
      final Object apps =
          await _methodChannel.invokeMethod('getInstalledApps', <String, bool>{
        'system_apps': includeSystemApps,
        'include_app_icons': includeAppIcons,
        'only_apps_with_launch_intent': onlyAppsWithLaunchIntent
      });

      if (apps is Iterable) {
        List<Application> list = <Application>[];
        for (Object app in apps) {
          if (app is Map) {
            try {
              list.add(Application._(app));
            } catch (e, trace) {
              if (e is AssertionError) {
                print('[DeviceApps] Unable to add the following app: $app');
              } else {
                print('[DeviceApps] $e $trace');
              }
            }
          }
        }
        return list;
      } else {
        return List<Application>.empty();
      }
    } catch (err) {
      print(err);
      return List<Application>.empty();
    }
  }

  /// Provide all information for a given app by its [packageName]
  /// [includeAppIcon] will also include the icon for the app.
  /// To get it, you have to cast the object to [ApplicationWithIcon].
  static Future<Application?> getApp(
    String packageName, [
    bool includeAppIcon = false,
  ]) async {
    if (packageName.isEmpty) {
      throw Exception('The package name can not be empty');
    }
    try {
      final Object? app = await _methodChannel.invokeMethod(
          'getApp', <String, Object>{
        'package_name': packageName,
        'include_app_icon': includeAppIcon
      });

      if (app != null && app is Map<dynamic, dynamic>) {
        return Application._(app);
      } else {
        return null;
      }
    } catch (err) {
      print(err);
      return null;
    }
  }

  /// Returns whether a given [packageName] is installed on the device
  /// You will then receive in return a boolean
  static Future<bool> isAppInstalled(String packageName) {
    if (packageName.isEmpty) {
      throw Exception('The package name can not be empty');
    }

    return _methodChannel
        .invokeMethod<bool>(
          'isAppInstalled',
          <String, String>{
            'package_name': packageName,
          },
        )
        .then((bool? value) => value ?? false)
        .catchError((dynamic err) => false);
  }

  /// Launch an app based on its [packageName]
  /// You will then receive in return if the app was opened
  /// (will be false if the app is not installed, or if no "launcher" intent is
  /// provided by this app)
  static Future<bool> openApp(String packageName) {
    if (packageName.isEmpty) {
      throw Exception('The package name can not be empty');
    }

    return _methodChannel
        .invokeMethod<bool>(
          'openApp',
          <String, String>{
            'package_name': packageName,
          },
        )
        .then((bool? value) => value ?? false)
        .catchError((dynamic err) => false);
  }

  /// Launch the Settings screen of the app based on its [packageName]
  /// You will then receive in return if the app was opened
  /// (will be false if the app is not installed)
  static Future<bool> openAppSettings(String packageName) {
    if (packageName.isEmpty) {
      throw Exception('The package name can not be empty');
    }

    return _methodChannel
        .invokeMethod<bool>('openAppSettings', <String, String>{
          'package_name': packageName,
        })
        .then((bool? value) => value ?? false)
        .catchError((dynamic err) => false);
  }

  /// Uninstall an application by giving its [packageName]
  /// Note: It will only open the Android's screen
  static Future<bool> uninstallApp(String packageName) {
    if (packageName.isEmpty) {
      throw Exception('The package name can not be empty');
    }

    return _methodChannel
        .invokeMethod<bool>('uninstallApp', <String, String>{
          'package_name': packageName,
        })
        .then((bool? value) => value ?? false)
        .catchError((dynamic err) => false);
  }

  /// Listen to app changes: installations, uninstallations, updates, enabled or
  /// disabled. As it is a [Stream], don't hesite to filter data if the content
  /// is too verbose for you
  static Stream<ApplicationEvent> listenToAppsChanges() {
    return _eventChannel
        .receiveBroadcastStream()
        .map(((dynamic event) =>
            ApplicationEvent._(event as Map<dynamic, dynamic>)))
        .handleError((Object err) => null);
  }
}

/// The Base class to reprend an application (= a package name)
class _BaseApplication {
  /// Name of the package
  final String packageName;

  _BaseApplication._fromMap(Map<dynamic, dynamic> map)
      : packageName = map['package_name'] as String;
}

/// An application installed on the device
/// Depending on the Android version, some attributes may not be available
class Application extends _BaseApplication {
  /// Displayable name of the application
  final String appName;

  /// Full path to the base APK for this application
  final String apkFilePath;

  /// Public name of the application (eg: 1.0.0)
  /// The version name of this package, as specified by the <manifest> tag's
  /// `versionName` attribute
  final String? versionName;

  /// Unique version id for the application
  final int versionCode;

  /// Full path to the default directory assigned to the package for its
  /// persistent data
  final String? dataDir;

  /// Whether the application is installed in the device's system image
  /// An application downloaded by the user won't be a system app
  final bool systemApp;

  /// The time at which the app was first installed
  final int installTimeMillis;

  /// The time at which the app was last updated
  final int updateTimeMillis;

  /// The category of this application
  /// The information may come from the application itself or the system
  final ApplicationCategory category;

  /// Whether the app is enabled (installed and visible)
  /// or disabled (installed, but not visible)
  final bool enabled;

  factory Application._(Map<dynamic, dynamic> map) {
    if (map.length == 0) {
      throw Exception('The map can not be null!');
    }
    if (map.containsKey('app_icon')) {
      return ApplicationWithIcon._fromMap(map);
    } else {
      return Application._fromMap(map);
    }
  }

  Application._fromMap(Map<dynamic, dynamic> map)
      : appName = map['app_name'] as String,
        apkFilePath = map['apk_file_path'] as String,
        versionName = map['version_name'] as String?,
        versionCode = map['version_code'] as int,
        dataDir = map['data_dir'] as String,
        systemApp = map['system_app'] as bool,
        installTimeMillis = map['install_time'] as int,
        updateTimeMillis = map['update_time'] as int,
        enabled = map['is_enabled'] as bool,
        category = _parseCategory(map['category']),
        super._fromMap(map);

  /// Mapping of Android categories
  /// [https://developer.android.com/reference/kotlin/android/content/pm/ApplicationInfo]
  /// [category] is null on Android < 26
  static ApplicationCategory _parseCategory(Object? category) {
    if (category is num && category < 0) {
      return ApplicationCategory.undefined;
    } else if (category == 0) {
      return ApplicationCategory.game;
    } else if (category == 1) {
      return ApplicationCategory.audio;
    } else if (category == 2) {
      return ApplicationCategory.video;
    } else if (category == 3) {
      return ApplicationCategory.image;
    } else if (category == 4) {
      return ApplicationCategory.social;
    } else if (category == 5) {
      return ApplicationCategory.news;
    } else if (category == 6) {
      return ApplicationCategory.maps;
    } else if (category == 7) {
      return ApplicationCategory.productivity;
    } else {
      return ApplicationCategory.undefined;
    }
  }

  // Open the app default screen
  // Will return [true] is the app is installed and the screen visible
  // Will return [false] otherwise
  Future<bool> openApp() {
    return DeviceApps.openApp(packageName);
  }

  // Open the app settings screen
  // Will return [true] is the app is installed and the screen visible
  // Will return [false] otherwise
  Future<bool> openSettingsScreen() {
    return DeviceApps.openAppSettings(packageName);
  }

  // Uninstall app
  // Will return [true] is the screen to uninstall the app is visible
  // Will return [false] otherwise
  Future<bool> uninstallApp() {
    return DeviceApps.uninstallApp(packageName);
  }

  @override
  String toString() {
    return 'Application{'
        'appName: $appName, '
        'apkFilePath: $apkFilePath, '
        'packageName: $packageName, '
        'versionName: $versionName, '
        'versionCode: $versionCode, '
        'dataDir: $dataDir, '
        'systemApp: $systemApp, '
        'installTimeMillis: $installTimeMillis, '
        'updateTimeMillis: $updateTimeMillis, '
        'category: $category, '
        'enabled: $enabled'
        '}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Application &&
          runtimeType == other.runtimeType &&
          appName == other.appName &&
          apkFilePath == other.apkFilePath &&
          packageName == other.packageName &&
          versionName == other.versionName &&
          versionCode == other.versionCode &&
          dataDir == other.dataDir &&
          systemApp == other.systemApp &&
          installTimeMillis == other.installTimeMillis &&
          updateTimeMillis == other.updateTimeMillis &&
          category == other.category &&
          enabled == other.enabled;

  @override
  int get hashCode =>
      appName.hashCode ^
      apkFilePath.hashCode ^
      packageName.hashCode ^
      versionName.hashCode ^
      versionCode.hashCode ^
      dataDir.hashCode ^
      systemApp.hashCode ^
      installTimeMillis.hashCode ^
      updateTimeMillis.hashCode ^
      category.hashCode ^
      enabled.hashCode;
}

/// If the [includeAppIcons] attribute is provided, this class will be used.
/// To display an image simply use the [Image.memory] widget.
/// Example:
///
/// ```
/// Image.memory(app.icon)
/// ```
class ApplicationWithIcon extends Application {
  final String _icon;

  ApplicationWithIcon._fromMap(Map<dynamic, dynamic> map)
      : _icon = map['app_icon'] as String,
        super._fromMap(map);

  /// Icon of the application to use in conjunction with [Image.memory]
  Uint8List get icon => base64.decode(_icon);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is ApplicationWithIcon &&
          runtimeType == other.runtimeType &&
          _icon == other._icon;

  @override
  int get hashCode => super.hashCode ^ _icon.hashCode;
}

/// Represent an event relative to an application, which can be:
/// - installation
/// - update (from V1 to V2)
/// - uninstallation
/// - (re)enabled by the user
/// - disabled by the user (not visible, but still installed)
///
/// Note: an [Application] is not available directly in this object, as it would
/// be null in the case of an uninstallation
abstract class ApplicationEvent {
  final DateTime time;

  factory ApplicationEvent._(Map<dynamic, dynamic> map) {
    Object? eventType = map['event_type'];

    if (eventType is! String) {
      throw Exception('Event type \"$eventType\" can not be empty!');
    }

    switch (eventType) {
      case 'installed':
        return ApplicationEventInstalled._fromMap(map);
      case 'updated':
        return ApplicationEventUpdated._fromMap(map);
      case 'uninstalled':
        return ApplicationEventUninstalled._fromMap(map);
      case 'enabled':
        return ApplicationEventEnabled._fromMap(map);
      case 'disabled':
        return ApplicationEventDisabled._fromMap(map);
    }

    throw Exception('Unknown event type $eventType!');
  }

  // ignore: empty_constructor_bodies, avoid_unused_constructor_parameters
  ApplicationEvent._fromMap(Map<dynamic, dynamic> map) : time = DateTime.now();

  /// The package name of the application related to this event
  String get packageName;

  /// The event type will help check if the app is installed or not
  ApplicationEventType get event;

  @override
  String toString() {
    return 'event: $event, time: $time';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApplicationEvent &&
          runtimeType == other.runtimeType &&
          event == other.event;

  @override
  int get hashCode => event.hashCode;
}

class ApplicationEventInstalled extends ApplicationEvent {
  final Application application;

  ApplicationEventInstalled._fromMap(Map<dynamic, dynamic> map)
      : application = Application._(map),
        super._fromMap(map);

  @override
  ApplicationEventType get event => ApplicationEventType.installed;

  @override
  String get packageName => application.packageName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is ApplicationEventInstalled &&
          runtimeType == other.runtimeType &&
          application == other.application;

  @override
  int get hashCode => super.hashCode ^ application.hashCode;

  @override
  String toString() {
    return 'ApplicationEventInstalled{application: $application, ${super.toString()}';
  }
}

class ApplicationEventUpdated extends ApplicationEvent {
  final Application application;

  ApplicationEventUpdated._fromMap(Map<dynamic, dynamic> map)
      : application = Application._(map),
        super._fromMap(map);

  @override
  ApplicationEventType get event => ApplicationEventType.updated;

  @override
  String get packageName => application.packageName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is ApplicationEventInstalled &&
          runtimeType == other.runtimeType &&
          application == other.application;

  @override
  int get hashCode => super.hashCode ^ application.hashCode;

  @override
  String toString() {
    return 'ApplicationEventUpdated{application: $application, ${super.toString()}';
  }
}

class ApplicationEventUninstalled extends ApplicationEvent {
  final _BaseApplication _application;

  ApplicationEventUninstalled._fromMap(Map<dynamic, dynamic> map)
      : _application = _BaseApplication._fromMap(map),
        super._fromMap(map);

  @override
  String get packageName => _application.packageName;

  @override
  ApplicationEventType get event => ApplicationEventType.uninstalled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is ApplicationEventInstalled &&
          runtimeType == other.runtimeType &&
          _application == other.application;

  @override
  int get hashCode => super.hashCode ^ _application.hashCode;

  @override
  String toString() {
    return 'ApplicationEventUninstalled{packageName: $packageName, ${super.toString()}';
  }
}

class ApplicationEventEnabled extends ApplicationEvent {
  final Application application;

  ApplicationEventEnabled._fromMap(Map<dynamic, dynamic> map)
      : application = Application._(map),
        super._fromMap(map);

  @override
  ApplicationEventType get event => ApplicationEventType.enabled;

  @override
  String get packageName => application.packageName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is ApplicationEventInstalled &&
          runtimeType == other.runtimeType &&
          application == other.application;

  @override
  int get hashCode => super.hashCode ^ application.hashCode;

  @override
  String toString() {
    return 'ApplicationEventEnabled{application: $application, ${super.toString()}';
  }
}

class ApplicationEventDisabled extends ApplicationEvent {
  final Application application;

  ApplicationEventDisabled._fromMap(Map<dynamic, dynamic> map)
      : application = Application._(map),
        super._fromMap(map);

  @override
  ApplicationEventType get event => ApplicationEventType.disabled;

  @override
  String get packageName => application.packageName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is ApplicationEventInstalled &&
          runtimeType == other.runtimeType &&
          application == other.application;

  @override
  int get hashCode => super.hashCode ^ application.hashCode;

  @override
  String toString() {
    return 'ApplicationEventDisabled{application: $application, ${super.toString()}';
  }
}
