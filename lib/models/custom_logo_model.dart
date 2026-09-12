enum CustomLogoSizeMode {
  defaultSize,
  originalSize,
  customScale;

  String get displayName {
    switch (this) {
      case CustomLogoSizeMode.defaultSize:
        return 'Default';
      case CustomLogoSizeMode.originalSize:
        return 'Original';
      case CustomLogoSizeMode.customScale:
        return 'Custom';
    }
  }
}

class CustomLogo {
  final String id;
  final String name;
  final String filePath;
  final int fileSizeBytes;
  final DateTime createdAt;
  final CustomLogoSizeMode sizeMode;
  final double customScale;

  const CustomLogo({
    required this.id,
    required this.name,
    required this.filePath,
    required this.fileSizeBytes,
    required this.createdAt,
    this.sizeMode = CustomLogoSizeMode.defaultSize,
    this.customScale = 1.0,
  });

  bool get useOriginalSize => sizeMode == CustomLogoSizeMode.originalSize;
  bool get isCustomScale => sizeMode == CustomLogoSizeMode.customScale;

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
    CustomLogoSizeMode? sizeMode,
    double? customScale,
  }) {
    return CustomLogo(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      createdAt: createdAt ?? this.createdAt,
      sizeMode: sizeMode ?? this.sizeMode,
      customScale: customScale ?? this.customScale,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'filePath': filePath,
        'fileSizeBytes': fileSizeBytes,
        'createdAt': createdAt.toIso8601String(),
        'sizeMode': sizeMode.name,
        'customScale': customScale,
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
      sizeMode: json['sizeMode'] != null
          ? CustomLogoSizeMode.values.firstWhere(
              (m) => m.name == json['sizeMode'],
              orElse: () => CustomLogoSizeMode.defaultSize,
            )
          : ((json['useOriginalSize'] as bool? ?? false)
              ? CustomLogoSizeMode.originalSize
              : CustomLogoSizeMode.defaultSize),
      customScale: (json['customScale'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
