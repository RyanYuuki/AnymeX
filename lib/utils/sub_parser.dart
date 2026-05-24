import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:subtitle/subtitle.dart';

class SubParser {
  static Future<List<SubtitleCue>> parseSubtitles(String content) async {
    final normalizedContent = content.replaceAll('\r\n', '\n');

    if (normalizedContent.contains('[Script Info]') ||
        normalizedContent.contains('Dialogue:')) {
      return _parseAssSubtitles(normalizedContent);
    }

    try {
      final controller = SubtitleController(
        provider: SubtitleProvider.fromString(
          data: content,
          type: SubtitleType.srt,
        ),
      );

      await controller.initial();

      if (controller.subtitles.isNotEmpty) {
        return controller.subtitles
            .map((sub) => SubtitleCue(
                  start: sub.start,
                  end: sub.end,
                  text: sub.data,
                ))
            .toList();
      } else {
        return _parseStandardSubtitles(normalizedContent);
      }
    } catch (e) {
      return _parseStandardSubtitles(normalizedContent);
    }
  }

  static List<SubtitleCue> _parseAssSubtitles(String content) {
    final cues = <SubtitleCue>[];
    final assPattern = RegExp(
        r'Dialogue:\s*[^,]*,(\d{1,2}:\d{2}:\d{2}\.\d{2}),(\d{1,2}:\d{2}:\d{2}\.\d{2}),(?:[^,]*,){6}(.*)');
    final lines = content.split('\n');

    for (final line in lines) {
      final match = assPattern.firstMatch(line);
      if (match != null) {
        final start = _parseDuration(match.group(1)!);
        final end = _parseDuration(match.group(2)!);
        final text = match.group(3)!
            .replaceAll(RegExp(r'\{[^}]*\}'), '')
            .replaceAll(RegExp(r'\\[nN]'), '\n')
            .trim();
        if (text.isNotEmpty) {
          cues.add(SubtitleCue(start: start, end: end, text: text));
        }
      }
    }
    return cues;
  }

  static List<SubtitleCue> _parseStandardSubtitles(String content) {
    final cues = <SubtitleCue>[];
    final blocks = content.split(RegExp(r'\n\s*\n'));

    final timestampPattern = RegExp(
      r'(\d{1,2}:\d{2}:\d{2}[,.]\d{3})\s*-->\s*(\d{1,2}:\d{2}:\d{2}[,.]\d{3})',
    );

    for (var block in blocks) {
      final match = timestampPattern.firstMatch(block);
      if (match != null) {
        final start = _parseDuration(match.group(1)!);
        final end = _parseDuration(match.group(2)!);

        final lines = block.split('\n');
        final timestampLineIndex = lines.indexWhere((l) => l.contains('-->'));

        if (timestampLineIndex != -1 && timestampLineIndex < lines.length - 1) {
          final text = lines
              .sublist(timestampLineIndex + 1)
              .join('\n')
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .replaceAll(RegExp(r'\{[^}]*\}'), '')
              .replaceAll(RegExp(r'\\[nN]'), '\n')
              .trim();

          if (text.isNotEmpty) {
            cues.add(SubtitleCue(start: start, end: end, text: text));
          }
        }
      }
    }
    return cues;
  }

  static Duration _parseDuration(String timestamp) {
    timestamp = timestamp.replaceAll(',', '.');
    final parts = timestamp.split(':');
    if (parts.length == 3) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      final secParts = parts[2].split('.');
      final seconds = int.tryParse(secParts[0]) ?? 0;
      final millis = int.tryParse(secParts.length > 1
              ? secParts[1].padRight(3, '0').substring(0, 3)
              : '0') ??
          0;
      return Duration(
          hours: hours,
          minutes: minutes,
          seconds: seconds,
          milliseconds: millis);
    }
    if (parts.length == 2) {
      final minutes = int.tryParse(parts[0]) ?? 0;
      final secParts = parts[1].split('.');
      final seconds = int.tryParse(secParts[0]) ?? 0;
      final millis = int.tryParse(secParts.length > 1
              ? secParts[1].padRight(3, '0').substring(0, 3)
              : '0') ??
          0;
      return Duration(minutes: minutes, seconds: seconds, milliseconds: millis);
    }
    return Duration.zero;
  }
}
