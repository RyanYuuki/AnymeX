class AnimeTheme {
  final String title;
  final String artist;
  final String type;
  final int? sequence;
  final String? videoUrl;
  final String? audioUrl;
  final List<String> tags;

  AnimeTheme({
    required this.title,
    required this.artist,
    required this.type,
    this.sequence,
    this.videoUrl,
    this.audioUrl,
    this.tags = const [],
  });

  factory AnimeTheme.fromJson(Map<String, dynamic> json) {
    // Extract song title
    String title = 'Unknown Title';
    if (json['song'] != null && json['song']['title'] != null) {
      title = json['song']['title'];
    } else if (json['sequence'] != null) {
      title = '${json['type']} ${json['sequence']}';
    }

    // Extract artist
    String artist = '';
    if (json['song'] != null && json['song']['artists'] != null) {
      final artistsData = json['song']['artists'];
      if (artistsData is List) {
        final artists = artistsData;
        artist = artists
            .map((a) => a is Map ? (a['name'] ?? '') : '')
            .where((name) => name.isNotEmpty)
            .join(', ');
      }
    }

    // Extract video URL and audio URL
    String? videoUrl;
    String? audioUrl;
    List<String> tags = [];

    try {
      if (json['animethemeentries'] != null) {
        final entriesData = json['animethemeentries'];
        if (entriesData is List) {
          final entries = entriesData;
          if (entries.isNotEmpty && entries[0] is Map) {
            final entry = entries[0] as Map<String, dynamic>;
            if (entry['videos'] != null && entry['videos'] is List) {
              final videos = entry['videos'] as List;
              if (videos.isNotEmpty && videos[0] is Map) {
                final video = videos[0] as Map<String, dynamic>;

                // Extract video URL
                if (video['link'] != null) {
                  videoUrl = video['link'].toString();
                }

                // Extract tags
                if (video['tags'] != null) {
                  final tagsData = video['tags'];
                  if (tagsData is List) {
                    tags = tagsData.map((tag) => tag.toString()).toList();
                  } else if (tagsData is String) {
                    tags = [tagsData];
                  }
                }

                // Extract audio URL if available
                if (video['audio'] != null && video['audio'] is Map) {
                  final audio = video['audio'] as Map<String, dynamic>;
                  if (audio['link'] != null) {
                    audioUrl = audio['link'].toString();
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      // If there's any error in parsing video/audio data, continue with basic info
      print('Error parsing video/audio data: $e');
    }

    return AnimeTheme(
      title: title,
      artist: artist,
      type: json['type']?.toString() ?? 'Unknown',
      sequence: json['sequence'] is int ? json['sequence'] : null,
      videoUrl: videoUrl,
      audioUrl: audioUrl,
      tags: tags,
    );
  }

  @override
  String toString() {
    return 'AnimeTheme(title: $title, artist: $artist, type: $type, sequence: $sequence)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnimeTheme &&
        other.title == title &&
        other.artist == artist &&
        other.type == type &&
        other.sequence == sequence &&
        other.videoUrl == videoUrl &&
        other.audioUrl == audioUrl;
  }

  @override
  int get hashCode {
    return Object.hash(title, artist, type, sequence, videoUrl, audioUrl);
  }
}
