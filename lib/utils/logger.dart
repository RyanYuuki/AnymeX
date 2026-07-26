import 'dart:developer' as developer;
import 'dart:io';
import 'dart:async';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';

class Logger {
  static File? _logFile;
  static IOSink? _fileSink;
  static bool _isInitialized = false;
  static bool _writeToFileEnabled = false;
  static StreamController<String>? _messageQueue;
  static StreamSubscription? _queueSubscription;
  static const int _maxLogFileSizeBytes = 100 * 1024;

  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      _messageQueue = StreamController<String>();
      _queueSubscription = _messageQueue!.stream.listen((logEntry) {
        try {
          _fileSink?.writeln(logEntry);
        } catch (exception) {
          _writeToFileEnabled = false;
          _fileSink = null;
          developer.log(
              'Logger: Error writing to log file, disabled file logging: $exception',
              level: 900,
              name: 'LOGGER');
        }
      });

      _isInitialized = true;
      _initMethodChannelHandler();
    } catch (exception) {
      developer.log('Logger init failed: $exception',
          level: 900, name: 'LOGGER');
    }
  }

  static bool get isFileLoggingEnabled => _writeToFileEnabled;
  static bool get isInitialized => _isInitialized;

  static Future<void> setFileLoggingEnabled(bool enabled,
      {String? customPath}) async {
    if (!_isInitialized) {
      await init();
    }

    if (enabled == _writeToFileEnabled && customPath == null) return;

    if (enabled) {
      await _ensureLogFileReady(customPath: customPath);
      _writeToFileEnabled = true;
      await _logInitializationDetails();
      return;
    }

    _writeToFileEnabled = false;
    try {
      await _fileSink?.flush();
      await _fileSink?.close();
    } catch (_) {}
    _fileSink = null;
  }

  static Future<void> _ensureLogFileReady({String? customPath}) async {
    try {
      final documentsDirectory = customPath != null && customPath.isNotEmpty
          ? Directory(customPath)
          : await getApplicationDocumentsDirectory();

      if (!await documentsDirectory.exists()) {
        await documentsDirectory.create(recursive: true);
      }

      _logFile = File('${documentsDirectory.path}/app_logs.txt');

      if (await _logFile!.exists() &&
          await _logFile!.length() > _maxLogFileSizeBytes) {
        await _logFile!.delete();
      }

      if (!await _logFile!.exists()) {
        await _logFile!.create(recursive: true);
      }

      try {
        await _fileSink?.flush();
        await _fileSink?.close();
      } catch (_) {}
      _fileSink = _logFile!.openWrite(mode: FileMode.append);
    } catch (e) {
      developer.log('Logger: Failed to initialize log file at $customPath: $e',
          level: 900, name: 'LOGGER');
      _logFile = null;
      _fileSink = null;
      _writeToFileEnabled = false;
      if (customPath != null) {
        await _ensureLogFileReady(customPath: null);
      }
    }
  }

  static Future<void> _logInitializationDetails() async {
    try {
      final pkg = await PackageInfo.fromPlatform();

      final deviceInfo = DeviceInfoPlugin();
      String deviceDetails = '';

      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        deviceDetails = '''
Device: ${info.manufacturer} ${info.model}
Brand: ${info.brand}
Device ID: ${info.id}
Android Version: ${info.version.release} (SDK ${info.version.sdkInt})
Fingerprint: ${info.fingerprint}
''';
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        deviceDetails = '''
Device: ${info.name}
Model: ${info.model}
System: ${info.systemName} ${info.systemVersion}
Identifier: ${info.identifierForVendor}
''';
      } else if (Platform.isWindows) {
        final info = await deviceInfo.windowsInfo;
        deviceDetails = '''
Computer Name: ${info.computerName}
Number of Cores: ${info.numberOfCores}
System Memory: ${info.systemMemoryInMegabytes} MB
OS: Windows ${info.displayVersion} (Build ${info.buildNumber})
''';
      } else if (Platform.isMacOS) {
        final info = await deviceInfo.macOsInfo;
        deviceDetails = '''
Model: ${info.model}
CPU: ${info.arch}
OS: macOS ${info.osRelease}
Kernel: ${info.kernelVersion}
''';
      } else if (Platform.isLinux) {
        final info = await deviceInfo.linuxInfo;
        deviceDetails = '''
Name: ${info.name}
Version: ${info.version}
ID: ${info.id}
Architecture: ${info.machineId}
Pretty Name: ${info.prettyName}
''';
      }

      _writeLogEntry(
        '=== Logger initialized ===\n'
            'App Info:\n'
            'Name: ${pkg.appName}\n'
            'Package: ${pkg.packageName}\n'
            'Version: ${pkg.version} (Build ${pkg.buildNumber})\n'
            '\nDevice Info:\n$deviceDetails'
            '==========================',
        'SYSTEM',
        500,
      );
    } catch (e) {
      developer.log('Logger: Failed to log initialization details: $e',
          level: 900, name: 'LOGGER');
    }
  }

  static void _writeLogEntry(String message, String loggerName, int logLevel) {
    final currentTime = DateTime.now();
    final formattedTimestamp = '${currentTime.hour.toString().padLeft(2, '0')}:'
        '${currentTime.minute.toString().padLeft(2, '0')}:'
        '${currentTime.second.toString().padLeft(2, '0')}';

    final logEntry = '[$formattedTimestamp][$loggerName] $message';

    if (_isInitialized && _writeToFileEnabled && _fileSink != null) {
      try {
        _messageQueue?.add(logEntry);
      } catch (e) {
        developer.log('Logger: Failed to add log to queue: $e',
            level: 900, name: 'LOGGER');
      }
    }

    developer.log(message, level: logLevel, name: loggerName);
  }

  static void _initMethodChannelHandler() {
    const channel = MethodChannel('anymexLogger');
    channel.setMethodCallHandler((call) async {
      if (call.method == 'log') {
        final args = call.arguments as Map;
        final level = args['level'] as String? ?? 'INFO';
        final tag = args['tag'] as String? ?? 'NATIVE';
        final msg = args['message'] as String? ?? '';
        final fullMsg = '[NATIVE] [$tag] $msg';

        switch (level) {
          case 'DEBUG':
          case 'VERBOSE':
            d(fullMsg, 'NATIVE');
            break;
          case 'WARNING':
            w(fullMsg, 'NATIVE');
            break;
          case 'ERROR':
            e(fullMsg, loggerName: 'NATIVE');
            break;
          default:
            i(fullMsg, 'NATIVE');
            break;
        }
      }
    });

    // Notify native that we are ready to receive logs
    channel.invokeMethod('ready').catchError((e) {
      developer.log('Logger: Failed to send ready signal: $e',
          level: 500, name: 'LOGGER');
    });
  }

  static void d(String message, [String? loggerName]) {
    _writeLogEntry(message, loggerName ?? 'DEBUG', 300);
  }

  static void i(String message, [String? loggerName]) {
    _writeLogEntry(message, loggerName ?? 'INFO', 500);
  }

  static void w(String message, [String? loggerName]) {
    _writeLogEntry(message, loggerName ?? 'WARNING', 800);
  }

  static void e(String message,
      {Object? error, StackTrace? stackTrace, String? loggerName}) {
    final errorLoggerName = loggerName ?? 'ERROR';
    _writeLogEntry(message, errorLoggerName, 900);

    if (error != null) {
      _writeLogEntry('ERROR: $error', errorLoggerName, 900);
    }
    if (stackTrace != null) {
      _writeLogEntry('STACK: $stackTrace', errorLoggerName, 900);
    }

    developer.log(
      message,
      level: 900,
      name: errorLoggerName,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void p(Object? object, [String? loggerName]) {
    final messageContent = object?.toString() ?? 'null';
    _writeLogEntry(messageContent, loggerName ?? 'PRINT', 0);
  }

  static Future<String> getLogs() async {
    if (_logFile == null || !await _logFile!.exists()) return '';

    await _fileSink?.flush();
    return await _logFile!.readAsString();
  }

  static Future<void> clearLogs() async {
    if (_logFile != null && await _logFile!.exists()) {
      await _fileSink?.flush();
      await _logFile!.writeAsString('');
    }
  }

  static Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      await _queueSubscription?.cancel();
      _queueSubscription = null;
      await _messageQueue?.close();
      _messageQueue = null;
      await _fileSink?.flush();
      await _fileSink?.close();
    } catch (_) {}
    _fileSink = null;
    _writeToFileEnabled = false;
    _isInitialized = false;
  }

  static Future<int> getLogFileSize() async {
    if (_logFile == null || !await _logFile!.exists()) return 0;
    return await _logFile!.length();
  }

  static Future<void> flush() async {
    await _fileSink?.flush();
  }

  static Future<void> share() async {
    if (_logFile == null || !await _logFile!.exists()) {
      snackBar('Enable "Write log to a file" and reproduce the issue first');
      return;
    }

    await _fileSink?.flush();

    if (Platform.isAndroid) {
      await SharePlus.instance.share(ShareParams(
        files: [XFile(_logFile!.path)],
      ));
    } else {
      Clipboard.setData(ClipboardData(text: await getLogs()));
      snackBar('Logs copied to clipboard');
    }
  }
}
