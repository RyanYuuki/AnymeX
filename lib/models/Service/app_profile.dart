import 'dart:convert';

enum ProfileLockType {
  none('none'),
  pin('pin'),
  password('password'),
  pattern('pattern');

  const ProfileLockType(this.value);
  final String value;

  static ProfileLockType fromString(String? value) {
    switch (value) {
      case 'pin':
        return ProfileLockType.pin;
      case 'password':
        return ProfileLockType.password;
      case 'pattern':
        return ProfileLockType.pattern;
      default:
        return ProfileLockType.none;
    }
  }
}

class AppProfile {
  final String id;
  String name;
  String avatarPath;
  final DateTime createdAt;
  DateTime lastUsedAt;
  String? lockHash;
  String lockType;
  int failedAttempts;
  DateTime? lockedUntil;

  AppProfile({
    required this.id,
    required this.name,
    this.avatarPath = '',
    DateTime? createdAt,
    DateTime? lastUsedAt,
    this.lockHash,
    this.lockType = 'none',
    this.failedAttempts = 0,
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

  bool get hasLock => lockHash != null && lockHash!.isNotEmpty;

  bool get isPinLocked => hasLock && lockType == 'pin';
  bool get isPasswordLocked => hasLock && lockType == 'password';
  bool get isPatternLocked => hasLock && lockType == 'pattern';

  ProfileLockType get profileLockType => ProfileLockType.fromString(lockType);

  String get lockLabel {
    switch (profileLockType) {
      case ProfileLockType.none:
        return 'None';
      case ProfileLockType.pin:
        return 'PIN';
      case ProfileLockType.password:
        return 'Password';
      case ProfileLockType.pattern:
        return 'Pattern';
    }
  }

  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  String toString() => name;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarPath': avatarPath,
        'createdAt': createdAt.toIso8601String(),
        'lastUsedAt': lastUsedAt.toIso8601String(),
        'lockHash': lockHash,
        'lockType': lockType,
        'failedAttempts': failedAttempts,
        'lockedUntil': lockedUntil?.toIso8601String(),
        'anilistLinked': anilistLinked,
        'malLinked': malLinked,
        'simklLinked': simklLinked,
      };

  factory AppProfile.fromJson(Map<String, dynamic> json) {
    final pinHash = json['pinHash'] as String?;
    final lockHash = json['lockHash'] as String? ?? pinHash;
    final lockType = json['lockType'] as String?;
    final effectiveLockType = (lockType != null && lockType != 'none')
        ? lockType
        : (pinHash != null && pinHash.isNotEmpty ? 'pin' : 'none');

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
      lockHash: lockHash,
      lockType: effectiveLockType,
      failedAttempts: json['failedAttempts'] as int? ??
          json['failedPinAttempts'] as int? ??
          0,
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
      return list
          .map((e) => AppProfile.fromJson(e as Map<String, dynamic>))
          .toList();
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
    String? lockHash,
    String? lockType,
    int? failedAttempts,
    DateTime? lockedUntil,
    bool? anilistLinked,
    bool? malLinked,
    bool? simklLinked,
    DateTime? lastUsedAt,
    bool clearLock = false,
  }) {
    return AppProfile(
      id: id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      lockHash: clearLock ? null : (lockHash ?? this.lockHash),
      lockType: clearLock ? 'none' : (lockType ?? this.lockType),
      failedAttempts: clearLock
          ? 0
          : (failedAttempts ?? this.failedAttempts),
      lockedUntil: clearLock
          ? null
          : (lockedUntil ?? this.lockedUntil),
    )
      ..anilistLinked = anilistLinked ?? this.anilistLinked
      ..malLinked = malLinked ?? this.malLinked
      ..simklLinked = simklLinked ?? this.simklLinked;
  }
}
