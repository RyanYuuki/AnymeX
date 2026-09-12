class CustomLogo {
  final String id;
  final String name;
  final String filePath;
  final int fileSizeBytes;
  final DateTime createdAt;

  final bool useOriginalSize;

  const CustomLogo({
    required this.id,
    required this.name,
    required this.filePath,
    required this.fileSizeBytes,
    required this.createdAt,
    this.useOriginalSize = false,
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

  CustomLogo copyWith({
    String? id,
    String? name,
    String? filePath,
    int? fileSizeBytes,
    DateTime? createdAt,
    bool? useOriginalSize,
  }) {
    return CustomLogo(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      createdAt: createdAt ?? this.createdAt,
      useOriginalSize: useOriginalSize ?? this.useOriginalSize,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'filePath': filePath,
        'fileSizeBytes': fileSizeBytes,
        'createdAt': createdAt.toIso8601String(),
        'useOriginalSize': useOriginalSize,
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
      useOriginalSize: json['useOriginalSize'] as bool? ?? false,
    );
  }
}
