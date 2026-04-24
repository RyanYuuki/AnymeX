import 'dart:convert';

class AppProfile {
  final String id;
  String name;
  String avatarPath;
  final DateTime createdAt;
  DateTime lastUsedAt;
  String? pinHash;
  int failedPinAttempts;
  DateTime? lockedUntil;

  AppProfile({
    required this.id,
    required this.name,
    this.avatarPath = '',
    DateTime? createdAt,
    DateTime? lastUsedAt,
    this.pinHash,
    this.failedPinAttempts = 0,
    this.lockedUntil,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastUsedAt = lastUsedAt ?? DateTime.now();

  bool get hasAniList => anilistLinked;
  bool get hasMAL => malLinked;
  bool get hasSimkl => simklLinked;

  bool anilistLinked = false;
  bool malLinked = false;
  bool simklLinked = false;

  bool get isLocked {
    if (lockedUntil == null) return false;
    return DateTime.now().isBefore(lockedUntil!);
  }

  bool get hasPin => pinHash != null && pinHash!.isNotEmpty;

  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarPath': avatarPath,
        'createdAt': createdAt.toIso8601String(),
        'lastUsedAt': lastUsedAt.toIso8601String(),
        'pinHash': pinHash,
        'failedPinAttempts': failedPinAttempts,
        'lockedUntil': lockedUntil?.toIso8601String(),
        'anilistLinked': anilistLinked,
        'malLinked': malLinked,
        'simklLinked': simklLinked,
      };

  factory AppProfile.fromJson(Map<String, dynamic> json) {
    return AppProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Profile',
      avatarPath: json['avatarPath'] as String? ??
          (json['avatarEmoji'] as String? ?? ''),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : DateTime.now(),
      pinHash: json['pinHash'] as String?,
      failedPinAttempts: json['failedPinAttempts'] as int? ?? 0,
      lockedUntil: json['lockedUntil'] != null
          ? DateTime.parse(json['lockedUntil'] as String)
          : null,
    )
      ..anilistLinked = json['anilistLinked'] as bool? ?? false
      ..malLinked = json['malLinked'] as bool? ?? false
      ..simklLinked = json['simklLinked'] as bool? ?? false;
  }

  static List<AppProfile> fromJsonList(String jsonStr) {
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((e) => AppProfile.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static String toJsonList(List<AppProfile> profiles) {
    return jsonEncode(profiles.map((e) => e.toJson()).toList());
  }

  AppProfile copyWith({
    String? name,
    String? avatarPath,
    String? pinHash,
    int? failedPinAttempts,
    DateTime? lockedUntil,
    bool? anilistLinked,
    bool? malLinked,
    bool? simklLinked,
    DateTime? lastUsedAt,
  }) {
    return AppProfile(
      id: id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      pinHash: pinHash ?? this.pinHash,
      failedPinAttempts: failedPinAttempts ?? this.failedPinAttempts,
      lockedUntil: lockedUntil ?? this.lockedUntil,
    )
      ..anilistLinked = anilistLinked ?? this.anilistLinked
      ..malLinked = malLinked ?? this.malLinked
      ..simklLinked = simklLinked ?? this.simklLinked;
  }
}
