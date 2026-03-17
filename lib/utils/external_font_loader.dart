import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ExternalFontLoader {
  static const String baseUrl = 'https://raw.githubusercontent.com/RyanYuuki/AnymeX/main/assets/external_assets/';
  
  static final List<String> fonts = [
    'bahnschrift.ttf',
    'cinecaption.ttf',
    'tahoma.ttf',
    'trebuchet.ttf',
    'AnimeAce3BB_Regular.otf',
    'AnimeAce3BB_Bold.otf',
    'AnimeAce3BB_Italic.otf',
    'AnimeAce3BB_BoldItalic.otf',
  ];

  static final Map<String, String> fontFamilyMapping = {
    'bahnschrift.ttf': 'Bahnschrift',
    'cinecaption.ttf': 'Cinecaption',
    'tahoma.ttf': 'Tahoma',
    'trebuchet.ttf': 'Trebuchet',
    'AnimeAce3BB_Regular.otf': 'AnimeAce',
    'AnimeAce3BB_Bold.otf': 'AnimeAce',
    'AnimeAce3BB_Italic.otf': 'AnimeAce',
    'AnimeAce3BB_BoldItalic.otf': 'AnimeAce',
  };

  static Future<void> loadAllFonts() async {
    for (String font in fonts) {
      loadFont(font); 
    }
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
    } catch (e) {
        print("external font loader broke => $e");
    }
  }
}
