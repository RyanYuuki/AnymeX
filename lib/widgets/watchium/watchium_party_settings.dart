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
        // ── Notifications section ──
        _sectionHeader(cs, 'Notifications'),
        const SizedBox(height: 8),
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

        const SizedBox(height: 20),

        // ── On-screen overlays section ──
        _sectionHeader(cs, 'On-Screen Overlays'),
        const SizedBox(height: 8),
        _buildSettingsToggle(
          cs,
          icon: Icons.chat_bubble_outline,
          iconColor: Colors.blue,
          title: 'Live comments',
          subtitle: 'Show chat messages on the player as they come in',
          value: WatchiumKeys.commentOverlay.get<bool>(true),
          onChanged: (v) {
            WatchiumKeys.commentOverlay.set(v);
            setState(() {});
          },
        ),
        const SizedBox(height: 8),
        _buildSettingsToggle(
          cs,
          icon: Icons.emoji_emotions_outlined,
          iconColor: Colors.amber,
          title: 'Reaction overlay',
          subtitle: 'Show emoji reactions floating on the player',
          value: WatchiumKeys.reactionOverlay.get<bool>(true),
          onChanged: (v) {
            WatchiumKeys.reactionOverlay.set(v);
            setState(() {});
          },
        ),
        const SizedBox(height: 8),
        _buildPositionPicker(cs, theme),
      ],
    );
  }

  Widget _sectionHeader(ColorScheme cs, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins-SemiBold',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: cs.onSurface.withValues(alpha: 0.45),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPositionPicker(ColorScheme cs, ThemeData theme) {
    final current = WatchiumOverlayPosition.fromString(
        WatchiumKeys.overlayPosition.get<String>());

    final icons = {
      WatchiumOverlayPosition.topLeft: Icons.north_west,
      WatchiumOverlayPosition.topRight: Icons.north_east,
      WatchiumOverlayPosition.bottomLeft: Icons.south_west,
      WatchiumOverlayPosition.bottomRight: Icons.south_east,
    };

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.picture_in_picture_alt_rounded,
                    size: 20, color: Colors.purple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overlay position',
                      style: TextStyle(
                        fontFamily: 'Poppins-SemiBold',
                        fontSize: 14,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Where live comments appear on screen',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 2x2 grid of position options
          Row(
            children: [
              _positionTile(
                cs: cs,
                label: 'Top-L',
                icon: icons[WatchiumOverlayPosition.topLeft]!,
                isSelected: current == WatchiumOverlayPosition.topLeft,
                onTap: () => _setPosition(WatchiumOverlayPosition.topLeft),
              ),
              const SizedBox(width: 8),
              _positionTile(
                cs: cs,
                label: 'Top-R',
                icon: icons[WatchiumOverlayPosition.topRight]!,
                isSelected: current == WatchiumOverlayPosition.topRight,
                onTap: () => _setPosition(WatchiumOverlayPosition.topRight),
              ),
              const Spacer(),
              _positionTile(
                cs: cs,
                label: 'Bot-L',
                icon: icons[WatchiumOverlayPosition.bottomLeft]!,
                isSelected: current == WatchiumOverlayPosition.bottomLeft,
                onTap: () => _setPosition(WatchiumOverlayPosition.bottomLeft),
              ),
              const SizedBox(width: 8),
              _positionTile(
                cs: cs,
                label: 'Bot-R',
                icon: icons[WatchiumOverlayPosition.bottomRight]!,
                isSelected: current == WatchiumOverlayPosition.bottomRight,
                onTap: () => _setPosition(WatchiumOverlayPosition.bottomRight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _setPosition(WatchiumOverlayPosition pos) {
    WatchiumKeys.overlayPosition.set(pos.name);
    setState(() {});
  }

  Widget _positionTile({
    required ColorScheme cs,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? cs.primary.withValues(alpha: 0.15)
                : cs.surfaceContainerHighest.opaque(0.5, iReallyMeanIt: true),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? cs.primary.withValues(alpha: 0.5)
                  : cs.onSurface.opaque(0.08, iReallyMeanIt: true),
              width: isSelected ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.5)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'Poppins',
                  color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.6),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
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
