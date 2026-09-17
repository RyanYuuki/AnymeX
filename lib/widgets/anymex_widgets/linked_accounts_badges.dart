import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkedAccountsBadges extends StatelessWidget {
  final Map<String, dynamic>? linkedAccounts;
  final double fontSize;
  final double iconSize;
  final bool interactive;

  const LinkedAccountsBadges({
    super.key,
    required this.linkedAccounts,
    this.fontSize = 9.0,
    this.iconSize = 12.0,
    this.interactive = true,
  });

  @override
  Widget build(BuildContext context) {
    if (linkedAccounts == null || linkedAccounts!.isEmpty) {
      return const SizedBox.shrink();
    }

    final anilist = linkedAccounts!['anilist'];
    final mal = linkedAccounts!['mal'];
    final simkl = linkedAccounts!['simkl'];

    final anilistUsername = anilist is Map ? anilist['username']?.toString() : null;
    final malUsername = mal is Map ? mal['username']?.toString() : null;
    final simklUsername = simkl is Map ? simkl['username']?.toString() : null;

    final badges = <Widget>[];

    if (anilistUsername != null && anilistUsername.isNotEmpty) {
      badges.add(_buildBadge(
        label: 'AL',
        username: anilistUsername,
        bgColor: const Color(0xFF02A9FF).withOpacity(0.18),
        textColor: const Color(0xFF02A9FF),
        borderColor: const Color(0xFF02A9FF).withOpacity(0.4),
        url: 'https://anilist.co/user/$anilistUsername',
      ));
    }

    if (malUsername != null && malUsername.isNotEmpty) {
      badges.add(_buildBadge(
        label: 'MAL',
        username: malUsername,
        bgColor: const Color(0xFF2E51A2).withOpacity(0.18),
        textColor: const Color(0xFF4C75D6),
        borderColor: const Color(0xFF2E51A2).withOpacity(0.4),
        url: 'https://myanimelist.net/profile/$malUsername',
      ));
    }

    if (simklUsername != null && simklUsername.isNotEmpty) {
      badges.add(_buildBadge(
        label: 'SIMKL',
        username: simklUsername,
        bgColor: const Color(0xFFE5A00D).withOpacity(0.18),
        textColor: const Color(0xFFFFAE19),
        borderColor: const Color(0xFFE5A00D).withOpacity(0.4),
        url: 'https://simkl.com/$simklUsername',
      ));
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAlignment.center,
      children: badges
          .expand((w) => [w, const SizedBox(width: 4)])
          .take(badges.length * 2 - 1)
          .toList(),
    );
  }

  Widget _buildBadge({
    required String label,
    required String username,
    required Color bgColor,
    required Color textColor,
    required Color borderColor,
    required String url,
  }) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );

    if (!interactive) return badge;

    return Tooltip(
      message: '$label: @$username (Tap to open profile)',
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        borderRadius: BorderRadius.circular(4),
        child: badge,
      ),
    );
  }
}
