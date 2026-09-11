import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ExternalFontLoader {
  static const String baseUrl =
      'https://raw.githubusercontent.com/RyanYuuki/AnymeX/main/assets/external_assets/';

  static final List<String> fonts = [
    'bahnschrift.ttf',
    'cinecaption.ttf',
    'tahoma.ttf',
    'AnimeAce3BB_Regular.otf',
    'AnimeAce3BB_Bold.otf',
    'AnimeAce3BB_Italic.otf',
    'AnimeAce3BB_BoldItalic.otf',
  ];

  static final Map<String, String> fontFamilyMapping = {
    'bahnschrift.ttf': 'Bahnschrift',
    'cinecaption.ttf': 'Cinecaption',
    'tahoma.ttf': 'Tahoma',
    'AnimeAce3BB_Regular.otf': 'AnimeAce',
    'AnimeAce3BB_Bold.otf': 'AnimeAce',
    'AnimeAce3BB_Italic.otf': 'AnimeAce',
    'AnimeAce3BB_BoldItalic.otf': 'AnimeAce',
  };

  static Future<void> loadAllFonts() async {
    for (String font in fonts) {
      await loadFont(font);
    }
    await loadAllCustomFonts();
  }

  static Future<Directory> getCustomFontsDirectory() async {
    final directory = await getApplicationSupportDirectory();
    final customDir = Directory(p.join(directory.path, 'fonts', 'custom'));
    if (!await customDir.exists()) {
      await customDir.create(recursive: true);
    }
    return customDir;
  }

  static Future<List<String>> getCustomFontNames() async {
    try {
      final dir = await getCustomFontsDirectory();
      final files = dir.listSync();
      final fontNames = <String>[];
      for (final file in files) {
        if (file is File) {
          final ext = p.extension(file.path).toLowerCase();
          if (ext == '.ttf' || ext == '.otf') {
            final name = p.basenameWithoutExtension(file.path);
            if (name.isNotEmpty && !fontNames.contains(name)) {
              fontNames.add(name);
            }
          }
        }
      }
      fontNames.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return fontNames;
    } catch (_) {
      return [];
    }
  }

  static Future<bool> loadCustomFontFromFile(File file) async {
    try {
      final fontName = p.basenameWithoutExtension(file.path);
      final fontData = await file.readAsBytes();
      final fontLoader = FontLoader(fontName);
      fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
      await fontLoader.load();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> loadAllCustomFonts() async {
    try {
      final dir = await getCustomFontsDirectory();
      final files = dir.listSync();
      for (final file in files) {
        if (file is File) {
          final ext = p.extension(file.path).toLowerCase();
          if (ext == '.ttf' || ext == '.otf') {
            await loadCustomFontFromFile(file);
          }
        }
      }
    } catch (_) {}
  }

  static Future<String?> importCustomFont(String sourcePath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) return null;
      final fileName = p.basename(sourcePath);
      final fontName = p.basenameWithoutExtension(sourcePath);
      final dir = await getCustomFontsDirectory();
      final targetFile = File(p.join(dir.path, fileName));
      await sourceFile.copy(targetFile.path);
      final success = await loadCustomFontFromFile(targetFile);
      if (success) {
        return fontName;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteCustomFont(String fontName) async {
    try {
      final dir = await getCustomFontsDirectory();
      final files = dir.listSync();
      for (final file in files) {
        if (file is File) {
          if (p.basenameWithoutExtension(file.path) == fontName) {
            await file.delete();
          }
        }
      }
    } catch (_) {}
  }

  static Future<void> loadFont(String fontName) async {
    try {
      final directory = await getApplicationSupportDirectory();
      final localPath = p.join(directory.path, 'fonts', fontName);
      final localFile = File(localPath);

      Uint8List fontData;

      if (await localFile.exists()) {
        fontData = await localFile.readAsBytes();
      } else {
        final response = await http.get(Uri.parse('$baseUrl$fontName'));
        if (response.statusCode == 200) {
          fontData = response.bodyBytes;
          await localFile.parent.create(recursive: true);
          await localFile.writeAsBytes(fontData);
        } else {
          return;
        }
      }

      final fontLoader = FontLoader(fontFamilyMapping[fontName]!);
      fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
      await fontLoader.load();
    } catch (_) {}
  }
}
