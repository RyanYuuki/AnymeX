import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/utils/theme_extensions.dart';

import 'dart:io' show Platform;

import 'package:flutter/material.dart';

class WatchiumPartySettings extends StatefulWidget {
  final VoidCallback onBack;

  const WatchiumPartySettings({super.key, required this.onBack});

  @override
  State<WatchiumPartySettings> createState() => _WatchiumPartySettingsState();
}

class _WatchiumPartySettingsState extends State<WatchiumPartySettings> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      children: [
        _buildSettingsHeader(cs, theme),
        Expanded(child: _buildSettingsBody(cs, theme)),
      ],
    );
  }

  Widget _buildSettingsHeader(ColorScheme cs, ThemeData theme) {
    final isDesktop = !Platform.isAndroid && !Platform.isIOS;

    return Container(
      padding: EdgeInsets.fromLTRB(16, isDesktop ? 16 + 40 : 16, 16, 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: cs.outline.withOpacity(0.15)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back_rounded,
                  size: 20, color: cs.onSurface.withOpacity(0.7)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Party Settings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'Poppins-SemiBold',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsBody(ColorScheme cs, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingsToggle(
          cs,
          icon: Icons.person_add_alt_1_rounded,
          iconColor: Colors.green.withValues(alpha: 0.8),
          title: 'Join notifications',
          subtitle: 'Show a notification when someone joins the party',
          value: WatchiumKeys.notifyOnMemberJoin.get<bool>(true),
          onChanged: (v) {
            WatchiumKeys.notifyOnMemberJoin.set(v);
            setState(() {});
          },
        ),
        const SizedBox(height: 8),
        _buildSettingsToggle(
          cs,
          icon: Icons.person_remove_rounded,
          iconColor: cs.error,
          title: 'Leave notifications',
          subtitle: 'Show a notification when someone leaves the party',
          value: WatchiumKeys.notifyOnMemberLeave.get<bool>(true),
          onChanged: (v) {
            WatchiumKeys.notifyOnMemberLeave.set(v);
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildSettingsToggle(
    ColorScheme cs, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.opaque(0.35, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.onSurface.opaque(0.08, iReallyMeanIt: true),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins-SemiBold',
                    fontSize: 14,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
