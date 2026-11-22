import 'package:anymex/l10n/l10n_extension.dart';
import 'package:anymex/controllers/watchium/watchium_service.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WatchiumPartySettings extends StatefulWidget {
  final VoidCallback onBack;

  const WatchiumPartySettings({super.key, required this.onBack});

  @override
  State<WatchiumPartySettings> createState() => _WatchiumPartySettingsState();
}

class _WatchiumPartySettingsState extends State<WatchiumPartySettings> {
  @override
  Widget build(BuildContext context) {
    return _buildSettingsBody(context.colors, Theme.of(context));
  }

  Widget _buildSettingsBody(ColorScheme cs, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        AnymeXSectionBuilder(
          margin: EdgeInsets.zero,
          title: context.l10n.notifications,
          children: [
            AnymeXTile.toggle(
              icon: Icons.person_add_alt_1_rounded,
              iconColor: Colors.green.opaque(0.8, iReallyMeanIt: true),
              title: context.l10n.joinNotifications,
              subtitle: context.l10n.showANotificationWhenSomeoneJoins,
              value: WatchiumKeys.notifyOnMemberJoin.get<bool>(true),
              onChanged: (v) {
                WatchiumKeys.notifyOnMemberJoin.set(v);
                setState(() {});
              },
            ),
            AnymeXTile.toggle(
              icon: Icons.person_remove_rounded,
              iconColor: cs.error,
              title: context.l10n.leaveNotifications,
              subtitle: context.l10n.showANotificationWhenSomeoneLeaves,
              value: WatchiumKeys.notifyOnMemberLeave.get<bool>(true),
              onChanged: (v) {
                WatchiumKeys.notifyOnMemberLeave.set(v);
                setState(() {});
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        AnymeXSectionBuilder(
          margin: EdgeInsets.zero,
          title: context.l10n.onScreenOverlays,
          children: [
            AnymeXTile.toggle(
              icon: Icons.chat_bubble_outline,
              iconColor: Colors.blue,
              title: context.l10n.liveComments,
              subtitle: context.l10n.showChatMessagesOnThePlayer,
              value: WatchiumKeys.commentOverlay.get<bool>(true),
              onChanged: (v) {
                WatchiumKeys.commentOverlay.set(v);
                setState(() {});
              },
            ),
            AnymeXTile.toggle(
              icon: Icons.emoji_emotions_outlined,
              iconColor: Colors.amber,
              title: context.l10n.reactionOverlay,
              subtitle: context.l10n.showEmojiReactionsFloatingOnThe,
              value: WatchiumKeys.reactionOverlay.get<bool>(true),
              onChanged: (v) {
                WatchiumKeys.reactionOverlay.set(v);
                setState(() {});
              },
            ),
            _buildPositionTile(cs, theme),
          ],
        ),
        const SizedBox(height: 20),
        _buildSyncModeSection(cs, theme),
        _buildChatModerationSection(cs, theme),
      ],
    );
  }

  Widget _buildChatModerationSection(ColorScheme cs, ThemeData theme) {
    final watchium = Get.find<WatchiumService>();

    return Obx(() {
      if (!watchium.canModerateChat) return const SizedBox.shrink();
      final state = watchium.roomState.value;
      if (state == null) return const SizedBox.shrink();

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnymeXSectionBuilder(
            margin: EdgeInsets.zero,
            title: context.l10n.chatModeration,
            children: [
              AnymeXTile.toggle(
                icon: Icons.voice_over_off_rounded,
                iconColor: Colors.red,
                title: context.l10n.disableChat,
                subtitle: context.l10n.noOneCanSendMessagesIn,
                value: state.chatDisabled,
                onChanged: (v) {
                  // Turn off announcement mode when disabling chat
                  if (v && state.announcementMode) {
                    watchium.toggleChatSetting('announcementMode', false);
                  }
                  watchium.toggleChatSetting('chatDisabled', v);
                },
              ),
              AnymeXTile.toggle(
                icon: Icons.campaign_outlined,
                iconColor: Colors.amber,
                title: context.l10n.announcementMode,
                subtitle: context.l10n.onlyHostAndCoHostsCan,
                value: state.announcementMode,
                onChanged: (v) {
                  // Turn off chat disabled when enabling announcement mode
                  if (v && state.chatDisabled) {
                    watchium.toggleChatSetting('chatDisabled', false);
                  }
                  watchium.toggleChatSetting('announcementMode', v);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      );
    });
  }

  Widget _buildSyncModeSection(ColorScheme cs, ThemeData theme) {
    final watchium = Get.find<WatchiumService>();

    return Obx(() {
      // Only show for members (not host)
      if (watchium.isHost.value) return const SizedBox.shrink();
      if (!watchium.inRoom.value) return const SizedBox.shrink();

      final isFollowing = watchium.followHost.value;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnymeXSectionBuilder(
            margin: EdgeInsets.zero,
            title: context.l10n.syncMode,
            children: [
              AnymeXTile.toggle(
                icon: Icons.link_rounded,
                iconColor: Colors.purple,
                title: context.l10n.followHost,
                subtitle: context.l10n.playbackIsLockedToTheHost,
                value: isFollowing,
                onChanged: (v) {
                  watchium.setFollowHost(v);
                },
              ),
              AnymeXTile.toggle(
                icon: Icons.lock_open_rounded,
                iconColor: Colors.teal,
                title: context.l10n.freedomSeek,
                subtitle: context.l10n.seekAndControlPlaybackFreely,
                value: !isFollowing,
                onChanged: (v) {
                  watchium.setFollowHost(!v);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      );
    });
  }

  Widget _buildPositionTile(ColorScheme cs, ThemeData theme) {
    final current = WatchiumOverlayPosition.fromString(WatchiumKeys
        .overlayPosition
        .get<String>(WatchiumOverlayPosition.bottomRight.name));

    final icons = {
      WatchiumOverlayPosition.topLeft: Icons.north_west_rounded,
      WatchiumOverlayPosition.topRight: Icons.north_east_rounded,
      WatchiumOverlayPosition.bottomLeft: Icons.south_west_rounded,
      WatchiumOverlayPosition.bottomRight: Icons.south_east_rounded,
    };

    return AnymeXTile(
      icon: Icons.picture_in_picture_alt_rounded,
      iconColor: Colors.purple,
      title: context.l10n.overlayPosition,
      subtitle: context.l10n.whereLiveCommentsAppearOnScreen,
      showChevron: false,
      customContent: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            _positionTile(
              cs: cs,
              label: context.l10n.topL,
              icon: icons[WatchiumOverlayPosition.topLeft]!,
              isSelected: current == WatchiumOverlayPosition.topLeft,
              onTap: () => _setPosition(WatchiumOverlayPosition.topLeft),
            ),
            const SizedBox(width: 8),
            _positionTile(
              cs: cs,
              label: context.l10n.topR,
              icon: icons[WatchiumOverlayPosition.topRight]!,
              isSelected: current == WatchiumOverlayPosition.topRight,
              onTap: () => _setPosition(WatchiumOverlayPosition.topRight),
            ),
            const SizedBox(width: 8),
            _positionTile(
              cs: cs,
              label: context.l10n.botL,
              icon: icons[WatchiumOverlayPosition.bottomLeft]!,
              isSelected: current == WatchiumOverlayPosition.bottomLeft,
              onTap: () => _setPosition(WatchiumOverlayPosition.bottomLeft),
            ),
            const SizedBox(width: 8),
            _positionTile(
              cs: cs,
              label: context.l10n.botR,
              icon: icons[WatchiumOverlayPosition.bottomRight]!,
              isSelected: current == WatchiumOverlayPosition.bottomRight,
              onTap: () => _setPosition(WatchiumOverlayPosition.bottomRight),
            ),
          ],
        ),
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
                ? cs.primary.opaque(0.15, iReallyMeanIt: true)
                : cs.surfaceContainerHighest.opaque(0.5, iReallyMeanIt: true),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? cs.primary.opaque(0.5, iReallyMeanIt: true)
                  : cs.onSurface.opaque(0.08, iReallyMeanIt: true),
              width: isSelected ? 1.5 : 0.8,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 18,
                  color: isSelected
                      ? cs.primary
                      : cs.onSurface.opaque(0.5, iReallyMeanIt: true)),
              const SizedBox(height: 4),
              AnymeXText(
                label,
                size: 10,
                color: isSelected
                    ? cs.primary
                    : cs.onSurface.opaque(0.6, iReallyMeanIt: true),
                variant:
                    isSelected ? TextVariant.semiBold : TextVariant.regular,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
