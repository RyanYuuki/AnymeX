class SauceResult {
  final String name;
  final int? episode;
  final double similarity;
  final String previewImage;
  final String videoUrl;
  final String originalFilename;

  SauceResult({
    required this.name,
    required this.episode,
    required this.similarity,
    required this.previewImage,
    required this.videoUrl,
    required this.originalFilename,
  });

  factory SauceResult.fromJson(Map<String, dynamic> data) {
    final filename = data['filename'] ?? 'Unknown';
    final regex = RegExp(r'\] (.*?) - ');
    final match = regex.firstMatch(filename);
    final animeName = match?.group(1) ?? 'Unknown';

    return SauceResult(
      name: animeName,
      episode: data['episode'],
      similarity: (data['similarity'] as num).toDouble(),
      previewImage: data['image'],
      videoUrl: data['video'],
      originalFilename: filename,
    );
  }
}
