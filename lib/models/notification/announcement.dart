class Announcement {
  final int id;
  final String appId;
  final String title;
  final String shortDescription;
  final String fullContent;
  final String category;
  final int priority;
  final bool pinned;
  final bool featured;
  final String? authorName;
  final String status;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final int viewCount;
  final DateTime? createdAt;
  final bool isRead;

  const Announcement({
    required this.id,
    required this.appId,
    required this.title,
    required this.shortDescription,
    required this.fullContent,
    this.category = 'general',
    this.priority = 0,
    this.pinned = false,
    this.featured = false,
    this.authorName,
    this.status = 'published',
    this.publishedAt,
    this.expiresAt,
    this.viewCount = 0,
    this.createdAt,
    this.isRead = false,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    DateTime? tryDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return Announcement(
      id: json['id'] as int? ?? int.tryParse(json['id']?.toString() ?? '') ?? 0,
      appId: json['app_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      shortDescription: json['short_description'] as String? ?? '',
      fullContent: json['full_content'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      priority: json['priority'] as int? ?? 0,
      pinned: json['pinned'] as bool? ?? false,
      featured: json['featured'] as bool? ?? false,
      authorName: json['author_name'] as String?,
      status: json['status'] as String? ?? 'published',
      publishedAt: tryDate(json['published_at']) ?? tryDate(json['created_at']),
      expiresAt: tryDate(json['expires_at']),
      viewCount: json['view_count'] as int? ?? 0,
      createdAt: tryDate(json['created_at']),
      isRead: json['is_read'] as bool? ?? false,
    );
  }
}
