class M3u8ParserResult {
  final List<String> variants;
  final List<String> segments;

  const M3u8ParserResult({
    required this.variants,
    required this.segments,
  });

  bool get isMasterPlaylist => variants.isNotEmpty;
  String? get firstVariant => variants.isNotEmpty ? variants.first : null;
  String? get firstSegment => segments.isNotEmpty ? segments.first : null;
}

M3u8ParserResult? parseM3u8Playlist(String text) {
  final lines = text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);

  if (lines.isEmpty || lines.first != '#EXTM3U') {
    return null;
  }

  final variants = <String>[];
  final segments = <String>[];
  var previousWasStreamInf = false;

  for (final line in lines) {
    if (line.startsWith('#EXT-X-STREAM-INF')) {
      previousWasStreamInf = true;
      continue;
    }

    if (line.startsWith('#')) {
      previousWasStreamInf = false;
      continue;
    }

    if (previousWasStreamInf) {
      variants.add(line);
      previousWasStreamInf = false;
      continue;
    }

    segments.add(line);
  }

  return M3u8ParserResult(variants: variants, segments: segments);
}
