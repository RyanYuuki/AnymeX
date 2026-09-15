import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AppFontItem {
  final String name;
  final String label;
  final List<String> urls;
  final List<String> fileNames;

  const AppFontItem({
    required this.name,
    required this.label,
    required this.urls,
    required this.fileNames,
  });
}

class ExternalFontLoader {
  static const String baseUrl =
      'https://raw.githubusercontent.com/RyanYuuki/AnymeX/main/assets/external_assets/';

  static const List<AppFontItem> appFonts = [
    AppFontItem(
      name: 'Outfit',
      label: 'Outfit (Google Sans)',
      urls: [
        'https://raw.githubusercontent.com/google/fonts/main/ofl/outfit/Outfit%5Bwght%5D.ttf',
      ],
      fileNames: ['Outfit.ttf'],
    ),
    AppFontItem(
      name: 'SF Pro',
      label: 'SF Pro (Apple / iOS)',
      urls: [
        'https://raw.githubusercontent.com/sahibjotsaggu/San-Francisco-Pro-Fonts/master/SF-Pro-Display-Regular.otf',
        'https://raw.githubusercontent.com/sahibjotsaggu/San-Francisco-Pro-Fonts/master/SF-Pro-Display-Medium.otf',
        'https://raw.githubusercontent.com/sahibjotsaggu/San-Francisco-Pro-Fonts/master/SF-Pro-Display-Semibold.otf',
        'https://raw.githubusercontent.com/sahibjotsaggu/San-Francisco-Pro-Fonts/master/SF-Pro-Display-Bold.otf',
      ],
      fileNames: [
        'SF-Pro-Display-Regular.otf',
        'SF-Pro-Display-Medium.otf',
        'SF-Pro-Display-Semibold.otf',
        'SF-Pro-Display-Bold.otf',
      ],
    ),
    AppFontItem(
      name: 'Inter',
      label: 'Inter',
      urls: [
        'https://raw.githubusercontent.com/google/fonts/main/ofl/inter/Inter%5Bopsz%2Cwght%5D.ttf',
      ],
      fileNames: ['Inter.ttf'],
    ),
    AppFontItem(
      name: 'Poppins',
      label: 'Poppins',
      urls: [
        'https://raw.githubusercontent.com/google/fonts/main/ofl/poppins/Poppins-Regular.ttf',
        'https://raw.githubusercontent.com/google/fonts/main/ofl/poppins/Poppins-SemiBold.ttf',
        'https://raw.githubusercontent.com/google/fonts/main/ofl/poppins/Poppins-Bold.ttf',
      ],
      fileNames: [
        'Poppins-Regular.ttf',
        'Poppins-SemiBold.ttf',
        'Poppins-Bold.ttf',
      ],
    ),
    AppFontItem(
      name: 'Montserrat',
      label: 'Montserrat',
      urls: [
        'https://raw.githubusercontent.com/google/fonts/main/ofl/montserrat/Montserrat%5Bwght%5D.ttf',
      ],
      fileNames: ['Montserrat.ttf'],
    ),
    AppFontItem(
      name: 'Lato',
      label: 'Lato',
      urls: [
        'https://raw.githubusercontent.com/google/fonts/main/ofl/lato/Lato-Regular.ttf',
      ],
      fileNames: ['Lato-Regular.ttf'],
    ),
    AppFontItem(
      name: 'Lexend',
      label: 'Lexend',
      urls: [
        'https://raw.githubusercontent.com/google/fonts/main/ofl/lexend/Lexend%5Bwght%5D.ttf',
      ],
      fileNames: ['Lexend.ttf'],
    ),
    AppFontItem(
      name: 'Ubuntu',
      label: 'Ubuntu',
      urls: [
        'https://raw.githubusercontent.com/google/fonts/main/ufl/ubuntu/Ubuntu-Regular.ttf',
      ],
      fileNames: ['Ubuntu-Regular.ttf'],
    ),
    AppFontItem(
      name: 'JetBrains Mono',
      label: 'JetBrains Mono',
      urls: [
        'https://raw.githubusercontent.com/google/fonts/main/ofl/jetbrainsmono/JetBrainsMono%5Bwght%5D.ttf',
      ],
      fileNames: ['JetBrainsMono.ttf'],
    ),
  ];

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
    await loadAllDownloadedAppFonts();
  }

  static Future<Directory> getAppFontsDirectory() async {
    final directory = await getApplicationSupportDirectory();
    final appFontsDir = Directory(p.join(directory.path, 'fonts', 'app_fonts'));
    if (!await appFontsDir.exists()) {
      await appFontsDir.create(recursive: true);
    }
    return appFontsDir;
  }

  static AppFontItem? _findAppFont(String fontName) {
    for (final font in appFonts) {
      if (font.name == fontName) return font;
    }
    return null;
  }

  static Future<bool> isAppFontDownloaded(String fontName) async {
    if (fontName.isEmpty) return true;
    final item = _findAppFont(fontName);
    if (item == null) {
      final customDir = await getCustomFontsDirectory();
      for (final ext in ['.ttf', '.otf']) {
        if (await File(p.join(customDir.path, '$fontName$ext')).exists()) {
          return true;
        }
      }
      return false;
    }
    final dir = await getAppFontsDirectory();
    for (final fileName in item.fileNames) {
      if (!await File(p.join(dir.path, fileName)).exists()) {
        return false;
      }
    }
    return true;
  }

  static Future<bool> downloadAppFont(String fontName) async {
    final item = _findAppFont(fontName);
    if (item == null) return false;
    final dir = await getAppFontsDirectory();
    try {
      for (var i = 0; i < item.urls.length; i++) {
        final url = item.urls[i];
        final fileName = item.fileNames[i];
        final file = File(p.join(dir.path, fileName));
        if (!await file.exists()) {
          final res = await http.get(Uri.parse(url));
          if (res.statusCode == 200) {
            await file.writeAsBytes(res.bodyBytes, flush: true);
          } else {
            return false;
          }
        }
      }
      await loadAppFont(fontName);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> loadAppFont(String fontName) async {
    final item = _findAppFont(fontName);
    if (item == null) return false;
    final dir = await getAppFontsDirectory();
    try {
      final fontLoader = FontLoader(fontName);
      for (final fileName in item.fileNames) {
        final file = File(p.join(dir.path, fileName));
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
        } else {
          return false;
        }
      }
      await fontLoader.load();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> loadAllDownloadedAppFonts() async {
    for (final item in appFonts) {
      if (await isAppFontDownloaded(item.name)) {
        await loadAppFont(item.name);
      }
    }
  }

  static Future<void> deleteAppFont(String fontName) async {
    final item = _findAppFont(fontName);
    if (item == null) return;
    final dir = await getAppFontsDirectory();
    for (final fileName in item.fileNames) {
      final file = File(p.join(dir.path, fileName));
      if (await file.exists()) {
        await file.delete();
      }
    }
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
        final response = await http
            .get(Uri.parse('$baseUrl$fontName'))
            .timeout(const Duration(seconds: 5));
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
