class CustomLogo {
  final String id;
  final String name;
  final String filePath;
  final int fileSizeBytes;
  final DateTime createdAt;

  const CustomLogo({
    required this.id,
    required this.name,
    required this.filePath,
    required this.fileSizeBytes,
    required this.createdAt,
  });

  String get formattedSize {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'filePath': filePath,
        'fileSizeBytes': fileSizeBytes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CustomLogo.fromJson(Map<String, dynamic> json) {
    return CustomLogo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Custom Logo',
      filePath: json['filePath'] as String? ?? '',
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
