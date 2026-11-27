import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Returns the application documents directory.
///
/// On Linux, path_provider asks the `xdg-user-dir` executable for the
/// Documents folder and throws [MissingPlatformDirectoryException] when it is
/// not installed (common on minimal distros, containers and WSL). Everything
/// that stores data under Documents — the database above all — then fails
/// during startup and the app never gets past a black window. In that case
/// this falls back to the XDG `user-dirs.dirs` entry, then `$HOME/Documents`,
/// which is where `xdg-user-dir` would normally point.
Future<Directory> getAppDocumentsDirectory() async {
  try {
    return await getApplicationDocumentsDirectory();
  } on MissingPlatformDirectoryException {
    if (!Platform.isLinux) rethrow;
    final fallback = _linuxDocumentsFallback();
    if (fallback == null) rethrow;
    await fallback.create(recursive: true);
    return fallback;
  }
}

Directory? _linuxDocumentsFallback() {
  final home = Platform.environment['HOME'];
  if (home == null || home.isEmpty) return null;

  final configHome = Platform.environment['XDG_CONFIG_HOME'];
  final userDirsFile = File(p.join(
    configHome != null && configHome.isNotEmpty
        ? configHome
        : p.join(home, '.config'),
    'user-dirs.dirs',
  ));

  try {
    if (userDirsFile.existsSync()) {
      final entry = RegExp(r'^\s*XDG_DOCUMENTS_DIR\s*=\s*"?([^"]*)"?\s*$');
      for (final line in userDirsFile.readAsLinesSync()) {
        final match = entry.firstMatch(line);
        if (match == null) continue;
        final value = match.group(1)!.replaceFirst(r'$HOME', home).trim();
        if (value.isNotEmpty && p.isAbsolute(value) && value != home) {
          return Directory(value);
        }
      }
    }
  } catch (_) {
    // Unreadable config: use the default below.
  }

  return Directory(p.join(home, 'Documents'));
}
