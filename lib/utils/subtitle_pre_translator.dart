import 'dart:convert';
import 'package:anymex/utils/logger.dart';
import 'package:http/http.dart' as http;


class SubtitlePreTranslator {
 
  static final Map<String, String> _translationCache = {};
  

  static String _cachedTargetLang = '';
  static String _currentUrl = '';
  

  static bool isPreTranslating = false;
  static int totalEntries = 0;
  static int translatedEntries = 0;
  

  static void clearCache() {
    _translationCache.clear();
    _cachedTargetLang = '';
    totalEntries = 0;
    translatedEntries = 0;
  }
  

  static String? lookup(String originalText) {
    final normalized = originalText.trim();
    return _translationCache[normalized];
  }
  
  static void manualAdd(String original, String translated) {
    if (original.isNotEmpty) {
      _translationCache[original] = translated;
    }
  }

 
  static Future<bool> preTranslateFromUrl(String url, String targetLang) async {
    try {
      if (isPreTranslating && _currentUrl == url) {
        Logger.i('[PreTranslator] Already translating this URL, resuming...');
        return true;
      }
      _currentUrl = url;
      
      if (_cachedTargetLang != targetLang) {
        clearCache();
        _cachedTargetLang = targetLang;
      }
      
      isPreTranslating = true;
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        Logger.e('[PreTranslator] Failed to download subtitle: ${response.statusCode}');
        isPreTranslating = false;
        return false;
      }
      
      final content = utf8.decode(response.bodyBytes);
      
      final entries = _parseSubtitleFile(content, url);
      
      if (entries.isEmpty) {
        isPreTranslating = false;
        return false;
      }
      
      totalEntries = entries.length;
      translatedEntries = 0;
      
      
     
      const batchSize = 30;
      for (var i = 0; i < entries.length; i += batchSize) {
        final batch = entries.skip(i).take(batchSize).toList();
        await _translateBatch(batch, targetLang);
        translatedEntries = (i + batch.length).clamp(0, entries.length);

      }
      
      isPreTranslating = false;
      Logger.i('[PreTranslator] Pre-translation complete! Cached ${_translationCache.length} entries');
      return true;
      
    } catch (e) {
      Logger.e('[PreTranslator] Error: $e');
      isPreTranslating = false;
      return false;
    }
  }
  

  static List<String> _parseSubtitleFile(String content, String url) {
    final entries = <String>[];
    final lowerUrl = url.toLowerCase();
    
    if (lowerUrl.endsWith('.srt') || lowerUrl.contains('.srt')) {
      entries.addAll(_parseSrt(content));
    } else if (lowerUrl.endsWith('.vtt') || lowerUrl.contains('.vtt')) {
      entries.addAll(_parseVtt(content));
    } else if (lowerUrl.endsWith('.ass') || lowerUrl.contains('.ass')) {
      entries.addAll(_parseAss(content));
    } else {
      
      entries.addAll(_parseSrt(content));
    }
    
  
    return entries
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }
  
  static final _srtIndexRx = RegExp(r'^\d+$');
  static final _srtTimeRx = RegExp(r'^\d{2}:\d{2}:\d{2}');
  static final _htmlRx = RegExp(r'<[^>]*>');

  /// SRT format
  static List<String> _parseSrt(String content) {
    final entries = <String>[];
    final lines = content.split('\n');
    final buffer = StringBuffer();
    
    for (final line in lines) {
      final trimmed = line.trim();
      
      
      if (_srtIndexRx.hasMatch(trimmed)) continue;
      if (_srtTimeRx.hasMatch(trimmed)) continue;
      
      if (trimmed.isEmpty) {
        
        if (buffer.isNotEmpty) {
          entries.add(buffer.toString().trim());
          buffer.clear();
        }
      } else {
       
        final cleanText = trimmed.replaceAll(_htmlRx, '');
        if (buffer.isNotEmpty) buffer.write('\n');
        buffer.write(cleanText);
      }
    }
    
   
    if (buffer.isNotEmpty) {
      entries.add(buffer.toString().trim());
    }
    
    return entries;
  }
  
  /// VTT format
  static List<String> _parseVtt(String content) {
  
    final noHeader = content.replaceFirst(RegExp(r'^WEBVTT[^\n]*\n*'), '');
    return _parseSrt(noHeader);
  }
  

  static List<String> _parseAss(String content) {
    final entries = <String>[];
    final lines = content.split('\n');
    
    for (final line in lines) {
      if (line.startsWith('Dialogue:')) {

        final parts = line.split(',');
        if (parts.length >= 10) {
       
          final text = parts.sublist(9).join(',');
         
          final cleanText = text
              .replaceAll(RegExp(r'\{[^}]*\}'), '')
              .replaceAll(RegExp(r'\\[nN]'), '\n')
              .trim();
          if (cleanText.isNotEmpty) {
            entries.add(cleanText);
          }
        }
      }
    }
    
    return entries;
  }
  
 /// bunch translate
  static Future<void> _translateBatch(List<String> entries, String targetLang) async {
  
    await Future.wait(entries.map((entry) async {
     
      if (_translationCache.containsKey(entry)) return;
      
      try {
        final translated = await _translateText(entry, targetLang);
        if (translated.isNotEmpty) {
          _translationCache[entry] = translated;
        }
      } catch (e) {
        Logger.e('[PreTranslator] Failed to translate entry: $e');
      }
    }));
  }
  
  /// pre-translate subtitle text 
  static Future<String> _translateText(String text, String targetLang) async {
    final uri = Uri.parse(
      'https://translate.googleapis.com/translate_a/single'
      '?client=gtx&sl=auto&tl=$targetLang&dt=t&q=${Uri.encodeComponent(text)}',
    );
    
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List && data.isNotEmpty && data[0] is List) {
        final translations = data[0] as List;
        final result = StringBuffer();
        for (final t in translations) {
          if (t is List && t.isNotEmpty && t[0] is String) {
            result.write(t[0]);
          }
        }
        return result.toString();
      }
    }
    
    return '';
  }
}
