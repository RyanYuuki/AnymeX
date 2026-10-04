import 'dart:io';
import 'package:archive/archive.dart';
import 'proto/BackupAniyomi.pb.dart';
import 'proto/BackupMihon.pb.dart';

enum ExternalBackupType {
  anymex,
  kotatsu,
  aniyomi,
  mihon,
  unknown,
}

class BackupFormatDetector {
  static ExternalBackupType detectFromBytes(List<int> bytes, {String? filePath}) {
    final lowerPath = filePath?.toLowerCase() ?? '';

    if (bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
      try {
        final content = const GZipDecoder().decodeBytes(bytes);
        try {
          final aniyomi = BackupAniyomi.fromBuffer(content);
          if (aniyomi.backupAnime.isNotEmpty ||
              aniyomi.legacyBackupAnime.isNotEmpty ||
              aniyomi.backupAnimeCategories.isNotEmpty ||
              aniyomi.legacyBackupAnimeCategories.isNotEmpty) {
            return ExternalBackupType.aniyomi;
          }
        } catch (_) {}

        if (lowerPath.contains('aniyomi') || lowerPath.contains('xyz.jmir.tachiyomi.mi')) {
          return ExternalBackupType.aniyomi;
        }

        try {
          final mihon = BackupMihon.fromBuffer(content);
          if (mihon.backupManga.isNotEmpty || mihon.backupCategories.isNotEmpty) {
            return ExternalBackupType.mihon;
          }
        } catch (_) {}

        return ExternalBackupType.mihon;
      } catch (_) {
        return ExternalBackupType.unknown;
      }
    }

    if (bytes.length >= 4 &&
        bytes[0] == 0x50 &&
        bytes[1] == 0x4b &&
        (bytes[2] == 0x03 || bytes[2] == 0x05 || bytes[2] == 0x07) &&
        (bytes[3] == 0x04 || bytes[3] == 0x06 || bytes[3] == 0x08)) {
      try {
        final archive = ZipDecoder().decodeBytes(bytes);
        return detectFromArchive(archive, filePath: filePath);
      } catch (_) {
        return ExternalBackupType.unknown;
      }
    }

    return ExternalBackupType.unknown;
  }

  static ExternalBackupType detectFromArchive(Archive archive, {String? filePath}) {
    final lowerPath = filePath?.toLowerCase() ?? '';

    final hasCategories = archive.any((f) => f.name == 'categories');
    final hasFavourites = archive.any((f) => f.name == 'favourites');
    if (hasCategories && hasFavourites) {
      return ExternalBackupType.kotatsu;
    }

    final hasBackupJson = archive.any((f) => f.name == 'backup.json');
    final hasManifestJson = archive.any((f) => f.name == 'manifest.json');
    if (hasBackupJson || hasManifestJson) {
      return ExternalBackupType.anymex;
    }

    if (lowerPath.endsWith('.tachibk') || lowerPath.endsWith('.proto.gz')) {
      if (lowerPath.contains('xyz.jmir.tachiyomi.mi') || lowerPath.contains('aniyomi.mi')) {
        return ExternalBackupType.aniyomi;
      }
      return ExternalBackupType.mihon;
    }

    return ExternalBackupType.unknown;
  }

  static Future<ExternalBackupType> detectFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return ExternalBackupType.unknown;
    final bytes = await file.readAsBytes();
    return detectFromBytes(bytes, filePath: filePath);
  }
}
