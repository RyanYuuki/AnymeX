import 'dart:developer' as developer;
import 'dart:io';
import 'dart:async';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class Logger {
  static File? _logFile;
  static IOSink? _fileSink;
  static bool _isInitialized = false;
  static final _messageQueue = StreamController<String>();
  static StreamSubscription? _queueSubscription;
  static const int _maxLogFileSizeBytes = 100 * 1024;

  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      _logFile = File('${documentsDirectory.path}/app_logs.txt');

      if (await _logFile!.exists() &&
          await _logFile!.length() > _maxLogFileSizeBytes) {
        await _logFile!.delete();
      }

      if (!await _logFile!.exists()) {
        await _logFile!.create(recursive: true);
      }

      _fileSink = _logFile!.openWrite(mode: FileMode.append);

      _queueSubscription = _messageQueue.stream.listen((logEntry) {
        _fileSink?.writeln(logEntry);
      });

      _isInitialized = true;

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
    } catch (exception) {
      debugPrintSynchronously('Logger init failed: $exception');
    }
  }

  static void _writeLogEntry(String message, String loggerName, int logLevel) {
    if (!_isInitialized) return;

    final currentTime = DateTime.now();
    final formattedTimestamp = '${currentTime.hour.toString().padLeft(2, '0')}:'
        '${currentTime.minute.toString().padLeft(2, '0')}:'
        '${currentTime.second.toString().padLeft(2, '0')}';

    final logEntry = '[$formattedTimestamp][$loggerName] $message';

    _messageQueue.add(logEntry);

    developer.log(message, level: logLevel, name: loggerName);
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

    await _queueSubscription?.cancel();
    await _messageQueue.close();
    await _fileSink?.flush();
    await _fileSink?.close();
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
