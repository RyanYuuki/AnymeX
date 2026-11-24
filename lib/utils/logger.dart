import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum LogLevel { debug, info, warning, error }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
  });

  String get formattedTimestamp {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  String get levelPrefix => switch (level) {
        LogLevel.debug => 'DEBUG',
        LogLevel.info => 'INFO',
        LogLevel.warning => 'WARN',
        LogLevel.error => 'ERROR',
      };

  String toFormattedString() {
    final buffer =
        StringBuffer('[$formattedTimestamp][$levelPrefix][$tag] $message');
    if (error != null) {
      buffer.write('\nERROR: $error');
    }
    if (stackTrace != null) {
      buffer.write('\nSTACK: $stackTrace');
    }
    return buffer.toString();
  }
}

class Logger {
  static File? _logFile;
  static IOSink? _fileSink;
  static bool _isInitialized = false;
  static bool _writeToFileEnabled = false;
  static String? _currentCustomPath;
  static const int maxMemoryLogs = 1000;
  static const int _maxLogFileSizeBytes = 1024 * 1024;
  static final ListQueue<LogEntry> _memoryLogs = ListQueue<LogEntry>();
  static final StreamController<LogEntry> _liveStreamController =
      StreamController<LogEntry>.broadcast();
  static final StreamController<void> _clearStreamController =
      StreamController<void>.broadcast();
  static final List<String> _pendingFileLogs = <String>[];
  static Timer? _flushTimer;

  static Stream<LogEntry> get liveStream => _liveStreamController.stream;
  static Stream<void> get onClear => _clearStreamController.stream;
  static List<LogEntry> get recentLogs => _memoryLogs.toList(growable: false);
  static bool get isFileLoggingEnabled => _writeToFileEnabled;
  static bool get isInitialized => _isInitialized;

  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      _isInitialized = true;
      _initMethodChannelHandler();
    } catch (exception) {
      developer.log('Logger init failed: $exception',
          level: 900, name: 'LOGGER');
    }
  }

  static Future<void> setFileLoggingEnabled(bool enabled,
      {String? customPath}) async {
    if (!_isInitialized) {
      await init();
    }

    _currentCustomPath = customPath ?? _currentCustomPath;

    if (enabled == _writeToFileEnabled && customPath == null) return;

    if (enabled) {
      await _ensureLogFileReady(customPath: _currentCustomPath);
      _writeToFileEnabled = true;
      await _logInitializationDetails();
      return;
    }

    _writeToFileEnabled = false;
    await flush();
    try {
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

      if (await _logFile!.exists()) {
        final length = await _logFile!.length();
        if (length > _maxLogFileSizeBytes) {
          await _rotateLogFile(documentsDirectory.path);
        }
      } else {
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

  static Future<void> _rotateLogFile(String dirPath) async {
    try {
      await _fileSink?.flush();
      await _fileSink?.close();
      _fileSink = null;

      final oldFile = File('$dirPath/app_logs.old.txt');
      if (await oldFile.exists()) {
        await oldFile.delete();
      }
      if (_logFile != null && await _logFile!.exists()) {
        await _logFile!.rename(oldFile.path);
      }
      _logFile = File('$dirPath/app_logs.txt');
      await _logFile!.create(recursive: true);
      _fileSink = _logFile!.openWrite(mode: FileMode.append);
    } catch (e) {
      developer.log('Logger: Error rotating log file: $e',
          level: 900, name: 'LOGGER');
    }
  }

  static Future<void> _flushPendingToFile() async {
    _flushTimer?.cancel();
    _flushTimer = null;

    if (_pendingFileLogs.isEmpty || _fileSink == null) return;

    final toWrite = List<String>.from(_pendingFileLogs);
    _pendingFileLogs.clear();

    try {
      final content = '${toWrite.join('\n')}\n';
      _fileSink?.write(content);
      if (_logFile != null && await _logFile!.exists()) {
        final length = await _logFile!.length();
        if (length > _maxLogFileSizeBytes) {
          final parentDir = _logFile!.parent.path;
          await _rotateLogFile(parentDir);
        }
      }
    } catch (e) {
      developer.log('Logger: Error flushing pending logs: $e',
          level: 900, name: 'LOGGER');
    }
  }

  static void _writeLogEntry(
    String message,
    String loggerName,
    LogLevel level, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final currentTime = DateTime.now();
    final entry = LogEntry(
      timestamp: currentTime,
      level: level,
      tag: loggerName,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );

    if (_memoryLogs.length >= maxMemoryLogs) {
      _memoryLogs.removeFirst();
    }
    _memoryLogs.addLast(entry);

    if (_liveStreamController.hasListener) {
      _liveStreamController.add(entry);
    }

    if (_isInitialized && _writeToFileEnabled && _fileSink != null) {
      _pendingFileLogs.add(entry.toFormattedString());
      if (_pendingFileLogs.length >= 50) {
        _flushPendingToFile();
      } else {
        _flushTimer ??= Timer(const Duration(seconds: 2), _flushPendingToFile);
      }
    }

    final devLogLevel = switch (level) {
      LogLevel.debug => 300,
      LogLevel.info => 500,
      LogLevel.warning => 800,
      LogLevel.error => 900,
    };

    developer.log(
      message,
      level: devLogLevel,
      name: loggerName,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void d(String message, [String? loggerName]) {
    _writeLogEntry(message, loggerName ?? 'DEBUG', LogLevel.debug);
  }

  static void i(String message, [String? loggerName]) {
    _writeLogEntry(message, loggerName ?? 'INFO', LogLevel.info);
  }

  static void w(String message, [String? loggerName]) {
    _writeLogEntry(message, loggerName ?? 'WARNING', LogLevel.warning);
  }

  static void e(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? loggerName,
  }) {
    final errorLoggerName = loggerName ?? 'ERROR';
    _writeLogEntry(
      message,
      errorLoggerName,
      LogLevel.error,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void p(Object? object, [String? loggerName]) {
    final messageContent = object?.toString() ?? 'null';
    _writeLogEntry(messageContent, loggerName ?? 'PRINT', LogLevel.info);
  }

  static String getFormattedLogs({LogLevel? filterLevel, String? searchQuery}) {
    final query = searchQuery?.toLowerCase().trim();
    final filtered = _memoryLogs.where((entry) {
      if (filterLevel != null && entry.level != filterLevel) return false;
      if (query != null && query.isNotEmpty) {
        return entry.message.toLowerCase().contains(query) ||
            entry.tag.toLowerCase().contains(query) ||
            (entry.error?.toString().toLowerCase().contains(query) ?? false);
      }
      return true;
    });
    return filtered.map((e) => e.toFormattedString()).join('\n\n');
  }

  static Future<String> getLogs() async {
    await flush();
    if (_logFile != null && await _logFile!.exists()) {
      return await _logFile!.readAsString();
    }
    return getFormattedLogs();
  }

  static Future<void> copyLogs(
      {LogLevel? filterLevel, String? searchQuery}) async {
    final text =
        getFormattedLogs(filterLevel: filterLevel, searchQuery: searchQuery);
    if (text.isEmpty) {
      snackBar('No logs to copy');
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    snackBar('Logs copied to clipboard');
  }

  static Future<void> clearLogs() async {
    _memoryLogs.clear();
    _pendingFileLogs.clear();
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_logFile != null && await _logFile!.exists()) {
      await _fileSink?.flush();
      await _logFile!.writeAsString('');
    }
    _clearStreamController.add(null);
  }

  static Future<void> flush() async {
    await _flushPendingToFile();
    await _fileSink?.flush();
  }

  static Future<int> getLogFileSize() async {
    if (_logFile == null || !await _logFile!.exists()) return 0;
    return await _logFile!.length();
  }

  static Future<void> share() async {
    await flush();
    File? fileToShare = _logFile;

    if (fileToShare == null ||
        !await fileToShare.exists() ||
        await fileToShare.length() == 0) {
      try {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/app_logs.txt');
        final logs = getFormattedLogs();
        if (logs.isEmpty) {
          snackBar('No logs available to share');
          return;
        }
        await tempFile.writeAsString(logs);
        fileToShare = tempFile;
      } catch (e) {
        developer.log('Logger: Failed to write temp log file for sharing: $e',
            name: 'LOGGER');
      }
    }

    if (fileToShare != null && await fileToShare.exists()) {
      if (Platform.isAndroid || Platform.isIOS) {
        await SharePlus.instance.share(ShareParams(
          files: [XFile(fileToShare.path)],
        ));
      } else {
        await Clipboard.setData(ClipboardData(text: await fileToShare.readAsString()));
        snackBar('Logs copied to clipboard');
      }
    } else {
      await copyLogs();
    }
  }

  static Future<void> dispose() async {
    if (!_isInitialized) return;
    try {
      await flush();
      await _fileSink?.close();
    } catch (_) {}
    _fileSink = null;
    _writeToFileEnabled = false;
    _isInitialized = false;
  }

  static void _initMethodChannelHandler() {
    const channel = MethodChannel('anymexLogger');
    channel.setMethodCallHandler((call) async {
      try {
        if (call.method == 'log') {
          final args = call.arguments as Map;
          final level = args['level'] as String? ?? 'INFO';
          final tag = args['tag'] as String? ?? 'NATIVE';
          final msg = args['message'] as String? ?? '';
          final fullMsg = '[$tag] $msg';

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
      } catch (e) {
        developer.log('Logger: Error handling method call: $e', name: 'LOGGER');
      }
      return null;
    });

    channel.invokeMethod('ready').catchError((e) {
      developer.log('Logger: Failed to send ready signal: $e',
          level: 500, name: 'LOGGER');
    });
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
        LogLevel.info,
      );
    } catch (e) {
      developer.log('Logger: Failed to log initialization details: $e',
          level: 900, name: 'LOGGER');
    }
  }
}
