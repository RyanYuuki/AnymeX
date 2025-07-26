class SauceResult {
  final String anilistId;
  final String name;
  final int? episode;
  final double similarity;
  final String previewImage;
  final String videoUrl;
  final String originalFilename;

  SauceResult({
    required this.anilistId,
    required this.name,
    required this.episode,
    required this.similarity,
    required this.previewImage,
    required this.videoUrl,
    required this.originalFilename,
  });

  factory SauceResult.fromJson(Map<String, dynamic> data) {
    final filename = data['filename'] ?? 'Unknown';
    final List<RegExp> regexPatterns = [
      RegExp(r'\] (.*?) - '),
      RegExp(r'(?:\[[^\]]*\])\s*\[([^\]]+)\]'),
      RegExp(r'^(.*?)\s*-')
    ];
    String? extractAnimeName(String filename) {
      for (final regex in regexPatterns) {
        final match = regex.firstMatch(filename);
        if (match != null && match.group(1) != null) {
          return match.group(1)!;
        }
      }
      return null;
    }

    final animeName = extractAnimeName(filename) ?? filename;

    return SauceResult(
      anilistId: data['anilist']?.toString() ?? '',
      name: animeName,
      episode: data['episode'],
      similarity: (data['similarity'] as num).toDouble(),
      previewImage: data['image'],
      videoUrl: data['video'],
      originalFilename: filename,
    );
  }
}
