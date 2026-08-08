class SocialUser {
  final int id;
  final String name;
  final String? avatarUrl;
  final String? bannerImage;

  SocialUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.bannerImage,
  });

  factory SocialUser.fromJson(Map<String, dynamic> json) {
    return SocialUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatar']?['large'] as String?,
      bannerImage: json['bannerImage'] as String?,
    );
  }
}
