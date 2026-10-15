import 'package:flutter/material.dart';

class DiscordBadge {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final bool isSvg;
  final Color badgeColor;
  final int priority;

  const DiscordBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    this.isSvg = true,
    required this.badgeColor,
    this.priority = 10,
  });

  factory DiscordBadge.fromMap(Map m) {
    Color parsedColor = const Color(0xFF5865F2);
    if (m['color'] != null) {
      final hex = m['color'].toString().replaceAll('#', '');
      if (hex.length == 6) {
        parsedColor = Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        parsedColor = Color(int.parse(hex, radix: 16));
      }
    }

    final type = m['type']?.toString().toLowerCase() ?? 'svg';
    final isSvg = type == 'svg' || (m['icon_url']?.toString().endsWith('.svg') ?? false);

    return DiscordBadge(
      id: m['id']?.toString() ?? '',
      name: m['name']?.toString() ?? '',
      description: m['description']?.toString() ?? '',
      iconUrl: m['icon_url']?.toString() ?? '',
      isSvg: isSvg,
      badgeColor: parsedColor,
      priority: m['priority'] is int ? m['priority'] : int.tryParse(m['priority']?.toString() ?? '10') ?? 10,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_url': iconUrl,
      'type': isSvg ? 'svg' : 'png',
      'color': '#${badgeColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
      'priority': priority,
    };
  }

  // Dynamic context badge for reply threads (client-only thread context)
  static const DiscordBadge opBadge = DiscordBadge(
    id: 'op',
    name: 'Original Poster',
    description: 'The creator of this comment discussion thread.',
    iconUrl: 'https://cdn.jsdelivr.net/gh/mezotv/discord-badges@main/assets/special/original-poster.svg',
    isSvg: true,
    badgeColor: Color(0xFF5865F2),
    priority: 0,
  );

  static DiscordBadge? getRoleBadge(String? role) {
    if (role == null) return null;
    switch (role.toLowerCase()) {
      case 'owner':
        return const DiscordBadge(
          id: 'owner',
          name: 'Commentum Owner',
          description: 'Owner and creator of the Commentum community platform.',
          iconUrl: 'https://cdn.jsdelivr.net/gh/mezotv/discord-badges@main/assets/server/crown.svg',
          isSvg: true,
          badgeColor: Color(0xFFFFD700),
          priority: 1,
        );
      case 'app_owner':
      case 'appowner':
        return const DiscordBadge(
          id: 'app_owner',
          name: 'App Creator',
          description: 'Creator and developer of AnymeX.',
          iconUrl: 'https://cdn.jsdelivr.net/gh/mezotv/discord-badges@main/assets/server/crown.svg',
          isSvg: true,
          badgeColor: Color(0xFFFFD700),
          priority: 2,
        );
      case 'super_admin':
      case 'superadmin':
        return const DiscordBadge(
          id: 'super_admin',
          name: 'Super Administrator',
          description: 'Super Administrator with system-wide management authority.',
          iconUrl: 'https://cdn.jsdelivr.net/gh/mezotv/discord-badges@main/assets/discord-staff.svg',
          isSvg: true,
          badgeColor: Color(0xFF5865F2),
          priority: 3,
        );
      case 'admin':
        return const DiscordBadge(
          id: 'admin',
          name: 'Administrator',
          description: 'Community administrator overseeing moderation and policies.',
          iconUrl: 'https://cdn.jsdelivr.net/gh/mezotv/discord-badges@main/assets/discord-staff.svg',
          isSvg: true,
          badgeColor: Color(0xFFED4245),
          priority: 4,
        );
      case 'moderator':
        return const DiscordBadge(
          id: 'moderator',
          name: 'Moderator',
          description: 'Verified moderator keeping comments respectful and safe.',
          iconUrl: 'https://cdn.jsdelivr.net/gh/mezotv/discord-badges@main/assets/discord-mod.svg',
          isSvg: true,
          badgeColor: Color(0xFF57F287),
          priority: 5,
        );
      default:
        return null;
    }
  }
}
