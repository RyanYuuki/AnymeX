import 'package:anymex/database/comments/model/discord_badge.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

class CommentumRoleConfig {
  static Color getRoleColor(BuildContext context, String? role) {
    final colors = context.colors;
    switch (role?.toLowerCase()) {
      case 'owner':
      case 'app_owner':
      case 'appowner':
        return const Color(0xFFFFB300); // Gold
      case 'super_admin':
      case 'superadmin':
        return colors.error;
      case 'admin':
        return const Color(0xFFFB8C00); // Orange
      case 'moderator':
        return const Color(0xFF26A69A); // Teal
      default:
        return colors.onSurfaceVariant;
    }
  }

  static String getRoleLabel(String? role) {
    switch (role?.toLowerCase()) {
      case 'app_owner':
      case 'appowner':
        return 'Creator';
      case 'owner':
        return 'Owner';
      case 'super_admin':
      case 'superadmin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      case 'moderator':
        return 'Mod';
      default:
        return role ?? 'User';
    }
  }

  static DiscordBadge? getRoleBadge(String? role) {
    return DiscordBadge.getRoleBadge(role);
  }
}
