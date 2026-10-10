import 'package:anymex/controllers/watchium/watchium_models.dart';
import 'package:anymex/controllers/watchium/watchium_service.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/episodes_pane.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/watch_settings_pane.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tabbar.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/watchium/watchium_party_settings.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';

class WatchiumPartyPopup extends StatelessWidget {
  const WatchiumPartyPopup({super.key});

  void _closePane() {
    Get.find<WatchiumService>().isPartyPaneOpened.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final watchium = Get.find<WatchiumService>();

    return Obx(() {
      if (!watchium.inRoom.value) return const SizedBox.shrink();
      return EpisodeSidePane(
        isVisible: watchium.isPartyPaneOpened.value,
        onOverlayTap: _closePane,
        child: _WatchiumPartyPopupContent(
          watchium: watchium,
          onClose: _closePane,
        ),
      );
    });
  }
}

enum _PartyTab { chat, members, info }

class _WatchiumPartyPopupContent extends StatefulWidget {
  final WatchiumService watchium;
  final VoidCallback onClose;

  const _WatchiumPartyPopupContent({
    required this.watchium,
    required this.onClose,
  });

  @override
  State<_WatchiumPartyPopupContent> createState() =>
      _WatchiumPartyPopupContentState();
}

class _WatchiumPartyPopupContentState
    extends State<_WatchiumPartyPopupContent> {
  _PartyTab _currentTab = _PartyTab.chat;
  bool _showSettings = false;
  late final TextEditingController _chatController;
  final FocusNode _chatFocusNode = FocusNode();
  final ScrollController _chatScrollController = ScrollController();
  Worker? _chatWorker;
  Worker? _reactionWorker;
  Timer? _durationTicker;
  bool _showJumpToBottom = false;
  static const _quickReactions = ['😂', '💀', '🔥', '👍', '❤️', '😮', '👏', '😭'];

  @override
  void initState() {
    super.initState();
    _chatController = TextEditingController();
    // Scroll to bottom when new messages/reactions arrive
    _chatWorker = ever(widget.watchium.chatMessages, _scrollChatToBottom);
    _reactionWorker = ever(widget.watchium.reactions, _scrollChatToBottom);
    _chatScrollController.addListener(_onChatScroll);
    _jumpToBottomAfterFrame();
    _durationTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _currentTab == _PartyTab.info) {
        setState(() {});
      }
    });
  }

  void _scrollChatToBottom(_) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
  }

  void _jumpToBottom({bool animate = true}) {
    if (!_chatScrollController.hasClients) return;
    final pos = _chatScrollController.position;
    if (!pos.hasContentDimensions) return;
    if (animate) {
      _chatScrollController.animateTo(
        pos.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      pos.jumpTo(pos.maxScrollExtent);
    }
  }

  void _jumpToBottomAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chatScrollController.hasClients) return;
      if (_chatScrollController.position.hasContentDimensions) {
        _jumpToBottom(animate: false);
      } else {
        _jumpToBottomAfterFrame();
      }
    });
  }

  void _onChatScroll() {
    if (!_chatScrollController.hasClients) return;
    final pos = _chatScrollController.position;
    final show = pos.hasContentDimensions &&
        pos.maxScrollExtent > 0 &&
        pos.pixels < pos.maxScrollExtent - 80;
    if (show != _showJumpToBottom) {
      setState(() => _showJumpToBottom = show);
    }
  }

  @override
  void dispose() {
    _durationTicker?.cancel();
    _chatWorker?.dispose();
    _reactionWorker?.dispose();
    _chatScrollController.removeListener(_onChatScroll);
    _chatController.dispose();
    _chatFocusNode.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSettings) {
      return WatchSettingsPane(
        title: 'Party Settings',
        onClose: widget.onClose,
        actions: [
          IconButton(
            onPressed: () => setState(() => _showSettings = false),
            style: IconButton.styleFrom(
              backgroundColor: context.colors.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(Icons.arrow_back_rounded,
                color: context.colors.onSurface),
          ),
        ],
        child: WatchiumPartySettings(
          onBack: () => setState(() => _showSettings = false),
        ),
      );
    }

    final cs = context.colors;
    return WatchSettingsPane(
      title: 'Watch Party',
      subtitle: _buildHeaderSubtitle(cs),
      onClose: widget.onClose,
      actions: [
        IconButton(
          onPressed: () => setState(() => _showSettings = true),
          style: IconButton.styleFrom(
            backgroundColor: cs.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: Icon(Icons.settings_rounded, color: cs.primary),
        ),
        IconButton(
          onPressed: _leaveRoom,
          style: IconButton.styleFrom(
            backgroundColor: cs.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: Icon(Icons.exit_to_app_rounded, color: cs.error),
        ),
      ],
      tabBar: _buildTabBar(),
      child: _currentTab == _PartyTab.chat
          ? _buildChat(cs, context.theme)
          : _currentTab == _PartyTab.members
              ? _buildMembersList(cs, context.theme)
              : _buildInfo(cs, context.theme),
    );
  }

  /// Room code + online count shown directly under the "Watch Party" title,
  /// matching the pre-redesign header placement.
  Widget _buildHeaderSubtitle(ColorScheme cs) {
    return Obx(() {
      final state = widget.watchium.roomState.value;
      if (state == null) return const SizedBox.shrink();
      final online = state.members.where((m) => m.online).length;
      return GestureDetector(
        onTap: () => _copyToClipboard(state.code, 'Room code'),
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: AnymeXText(
                'Room ${state.code}  ·  $online online',
                size: 12,
                color: cs.onSurface.opaque(0.5, iReallyMeanIt: true),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      );
    });
  }

  void _leaveRoom() {
    Logger.i('Leave room from party popup', 'WATCHIUM_UI');
    _showLeaveConfirmDialog();
  }

  Future<void> _showLeaveConfirmDialog() async {
    final ctx = context;
    if (!ctx.mounted) return;
    final result = await showDialog<bool>(
      context: ctx,
      builder: (ctx) => AlertDialog(
        title: const AnymeXText('Leave Watch Together?'),
        content: const AnymeXText(
            'You will leave the room and stop watching with everyone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const AnymeXText('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const AnymeXText('Leave'),
          ),
        ],
      ),
    );
    if (result == true) {
      widget.watchium.leaveRoomAndClosePlayer();
    }
  }

  Widget _buildTabBar() {
    final activeIndex = switch (_currentTab) {
      _PartyTab.chat => 0,
      _PartyTab.members => 1,
      _PartyTab.info => 2,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: AnymeXTabBar(
        selectTabs: const ['Chat', 'Members', 'Info'],
        selectedIndex: activeIndex,
        icons: const [
          Icons.chat_bubble_rounded,
          Icons.people_rounded,
          Icons.info_outline_rounded,
        ],
        onTabSelected: (index) {
          setState(() {
            _currentTab = switch (index) {
              1 => _PartyTab.members,
              2 => _PartyTab.info,
              _ => _PartyTab.chat,
            };
          });
          if (_currentTab == _PartyTab.chat) {
            _jumpToBottomAfterFrame();
          }
        },
      ),
    );
  }

  Widget _buildChat(ColorScheme cs, ThemeData theme) {
    return Column(
      children: [
        Obx(() => _buildChatModerationBanner(cs)),
        Expanded(
          child: Obx(() {
            final messages = widget.watchium.chatMessages;
            final reactions = widget.watchium.reactions;
            final items = <Object>[
              ...messages,
              ...reactions,
            ]..sort((a, b) {
                final aTs = a is WatchiumChatMessage
                    ? a.ts
                    : (a as WatchiumReaction).ts;
                final bTs = b is WatchiumChatMessage
                    ? b.ts
                    : (b as WatchiumReaction).ts;
                return aTs.compareTo(bTs);
              });
            if (items.isEmpty) {
              return _buildEmpty(
                  cs, theme, Icons.chat_bubble_outline_rounded, 'No messages yet');
            }
            return Stack(
              children: [
                ListView.builder(
                  controller: _chatScrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (item is WatchiumReaction) {
                      return _buildReactionBubble(cs, item);
                    }
                    final msg = item as WatchiumChatMessage;
                    final isSelf = msg.userId == widget.watchium.currentUserId;
                    final prevIsSameUser = index > 0 &&
                        items[index - 1] is WatchiumChatMessage &&
                        (items[index - 1] as WatchiumChatMessage).userId ==
                            msg.userId;
                    final nextIsSameUser =
                        index < items.length - 1 &&
                            items[index + 1] is WatchiumChatMessage &&
                            (items[index + 1] as WatchiumChatMessage).userId ==
                                msg.userId;
                    final isFirstInGroup = !prevIsSameUser;
                    final isLastInGroup = !nextIsSameUser;
                    final isSingle = isFirstInGroup && isLastInGroup;
                    // Constrain bubbles to the pane width so they stay
                    // comfortable on both narrow phones and wide desktop panes.
                    final screenWidth = MediaQuery.of(context).size.width;
                    final isWide = screenWidth > 600;
                    final maxBubbleWidth =
                        screenWidth * (isWide ? 0.28 : 0.42);
                    return GestureDetector(
                      onLongPress: () => _showReactionPicker(context),
                      child: Padding(
                        padding: EdgeInsets.only(
                            top: isFirstInGroup ? 8 : 1, bottom: 1),
                        child: Align(
                          alignment: isSelf
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: isSelf
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (!isSelf && isFirstInGroup)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 10,
                                        backgroundColor: cs.surfaceContainer
                                            .opaque(0.45, iReallyMeanIt: true),
                                        backgroundImage: msg.avatarUrl != null
                                            ? NetworkImage(msg.avatarUrl!)
                                            : null,
                                        child: msg.avatarUrl == null
                                            ? Icon(Icons.person,
                                                size: 12,
                                                color: cs.onSurface.opaque(
                                                    0.5,
                                                    iReallyMeanIt: true))
                                            : null,
                                      ),
                                      const SizedBox(width: 6),
                                      AnymeXText(
                                        msg.username,
                                        size: 10,
                                        variant: TextVariant.semiBold,
                                        color: cs.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth: maxBubbleWidth,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelf
                                      ? cs.primary.opaque(0.18,
                                          iReallyMeanIt: true)
                                      : cs.surfaceContainer.opaque(0.45,
                                          iReallyMeanIt: true),
                                  borderRadius: _bubbleRadius(
                                    isSelf: isSelf,
                                    isFirst: isFirstInGroup,
                                    isLast: isLastInGroup,
                                    isSingle: isSingle,
                                  ),
                                  border: Border.all(
                                    color: isSelf
                                        ? cs.primary.opaque(0.3,
                                            iReallyMeanIt: true)
                                        : cs.onSurface.opaque(0.08,
                                            iReallyMeanIt: true),
                                    width: 0.8,
                                  ),
                                ),
                                child: AnymeXText(
                                  msg.text,
                                  size: 13,
                                  color: cs.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: IgnorePointer(
                    ignoring: !_showJumpToBottom,
                    child: AnimatedOpacity(
                      opacity: _showJumpToBottom ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 150),
                      child: Center(
                        child: GestureDetector(
                          onTap: _jumpToBottom,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.opaque(0.3,
                                      iReallyMeanIt: true),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(Icons.keyboard_arrow_down_rounded,
                                color: cs.onPrimary, size: 22),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _buildQuickReactionBar(cs, theme),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _buildChatInput(cs),
        ),
      ],
    );
  }

  Widget _buildEmpty(ColorScheme cs, ThemeData theme, IconData icon,
      String message,
      {String? subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: cs.onSurface.opaque(0.3, iReallyMeanIt: true)),
          const SizedBox(height: 16),
          AnymeXText(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: cs.onSurface.opaque(0.5, iReallyMeanIt: true),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            AnymeXText(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.opaque(0.35, iReallyMeanIt: true),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickReactionBar(ColorScheme cs, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: AnymeXText(
            'QUICK REACTIONS',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: cs.primary,
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _quickReactions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final emoji = _quickReactions[index];
              return GestureDetector(
                onTap: () {
                  widget.watchium.sendReaction(emoji);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.opaque(0.5,
                        iReallyMeanIt: true),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color:
                            cs.outline.opaque(0.2, iReallyMeanIt: true)),
                  ),
                  alignment: Alignment.center,
                  child: AnymeXText(
                    emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Shows a banner when chat is disabled or in announcement mode.
  Widget _buildChatModerationBanner(ColorScheme cs) {
    final state = widget.watchium.roomState.value;
    if (state == null) return const SizedBox.shrink();

    if (state.chatDisabled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: cs.error.opaque(0.1, iReallyMeanIt: true),
          border: Border(
            bottom: BorderSide(
                color: cs.error.opaque(0.2, iReallyMeanIt: true)),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.voice_over_off_rounded, size: 14, color: cs.error),
            const SizedBox(width: 8),
            Expanded(
              child: AnymeXText(
                'Chat has been disabled by the host',
                size: 11,
                color: cs.error,
              ),
            ),
          ],
        ),
      );
    }

    if (state.announcementMode && !widget.watchium.canModerateChat) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.opaque(0.1, iReallyMeanIt: true),
          border: Border(
            bottom: BorderSide(
                color: Colors.amber.opaque(0.2, iReallyMeanIt: true)),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.campaign_outlined,
                size: 14, color: Colors.amber.opaque(0.9, iReallyMeanIt: true)),
            const SizedBox(width: 8),
            Expanded(
              child: AnymeXText(
                'Announcement mode — only host and co-hosts can send messages',
                size: 11,
                color: Colors.amber.opaque(0.9, iReallyMeanIt: true),
              ),
            ),
          ],
        ),
      );
    }

    if (state.announcementMode && widget.watchium.canModerateChat) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.opaque(0.08, iReallyMeanIt: true),
          border: Border(
            bottom: BorderSide(
                color: Colors.amber.opaque(0.2, iReallyMeanIt: true)),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.campaign_outlined,
                size: 14, color: Colors.amber.opaque(0.8, iReallyMeanIt: true)),
            const SizedBox(width: 8),
            Expanded(
              child: AnymeXText(
                'Announcement mode active — members can only read',
                size: 11,
                color: Colors.amber.opaque(0.8, iReallyMeanIt: true),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildChatInput(ColorScheme cs) {
    return Obx(() {
      final state = widget.watchium.roomState.value;
      final chatDisabled = state?.chatDisabled ?? false;
      final announcementMode = state?.announcementMode ?? false;
      final isModerator = widget.watchium.canModerateChat;
      final isMuted = chatDisabled || (announcementMode && !isModerator);

      String hintText = 'Type a message...';
      if (chatDisabled) {
        hintText = 'Chat is disabled by host';
      } else if (announcementMode && !isModerator) {
        hintText = 'Announcement mode — only staff can chat';
      }

      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              focusNode: _chatFocusNode,
              enabled: !isMuted,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: isMuted
                    ? cs.onSurface.opaque(0.4, iReallyMeanIt: true)
                    : cs.onSurface,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: cs.onSurface.opaque(0.35, iReallyMeanIt: true),
                ),
                filled: true,
                fillColor: cs.surfaceContainerLow,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.primary, width: 1.5),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: cs.outline.opaque(0.2, iReallyMeanIt: true)),
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: isMuted ? null : (_) => _sendChat(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: isMuted ? null : _sendChat,
            style: IconButton.styleFrom(
              backgroundColor:
                  isMuted ? cs.surfaceContainerHigh : cs.primary,
              disabledBackgroundColor: cs.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              fixedSize: const Size(46, 46),
            ),
            icon: Icon(
              Icons.send_rounded,
              color: isMuted
                  ? cs.onSurface.opaque(0.35, iReallyMeanIt: true)
                  : cs.onPrimary,
              size: 20,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildReactionBubble(ColorScheme cs, WatchiumReaction r) {
    final isSelf = r.userId == widget.watchium.currentUserId;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: cs.primary.opaque(0.12, iReallyMeanIt: true),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cs.primary.opaque(0.25, iReallyMeanIt: true),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnymeXText(r.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              AnymeXText(
                r.username,
                size: 11,
                variant: TextVariant.semiBold,
                color: cs.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  BorderRadius _bubbleRadius({
    required bool isSelf,
    required bool isFirst,
    required bool isLast,
    required bool isSingle,
  }) {
    const large = Radius.circular(16);
    const small = Radius.circular(4);

    if (isSelf) {
      return BorderRadius.only(
        topLeft: large,
        bottomLeft: large,
        topRight: isSingle || isFirst ? large : small,
        bottomRight: isSingle || isLast ? large : small,
      );
    }
    return BorderRadius.only(
      topRight: large,
      bottomRight: large,
      topLeft: isSingle || isFirst ? large : small,
      bottomLeft: isSingle || isLast ? large : small,
    );
  }

  void _sendChat() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    if (!widget.watchium.canSendChat) return;
    widget.watchium.sendChat(text);
    _chatController.clear();
    _chatFocusNode.requestFocus();
  }

  Widget _buildMembersList(ColorScheme cs, ThemeData theme) {
    return Obx(() {
      final state = widget.watchium.roomState.value;
      if (state == null) return const SizedBox.shrink();

      if (state.members.isEmpty) {
        return _buildEmpty(
            cs, theme, Icons.people_outline_rounded, 'No members yet');
      }

      final isHost = widget.watchium.isHost.value;

      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: state.members.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final member = state.members[index];
          final isSelf = member.userId == widget.watchium.currentUserId;
          final title =
              isSelf ? '${member.username} (You)' : member.username;
          final subtitle = member.online ? 'Online' : 'Offline';

          return Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainer.opaque(0.45, iReallyMeanIt: true),
              borderRadius: BorderRadius.circular(18.0),
              border: Border.all(
                color: cs.onSurface.opaque(0.08, iReallyMeanIt: true),
                width: 0.8,
              ),
            ),
            child: AnymeXTile(
              title: title,
              subtitle: subtitle,
              leading: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        cs.primary.opaque(0.15, iReallyMeanIt: true),
                    backgroundImage: member.avatarUrl != null
                        ? NetworkImage(member.avatarUrl!)
                        : null,
                    child: member.avatarUrl == null
                        ? Icon(Icons.person,
                            size: 18,
                            color: cs.primary.opaque(0.7, iReallyMeanIt: true))
                        : null,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: member.online
                            ? Colors.green
                            : cs.onSurface.opaque(0.4, iReallyMeanIt: true),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: cs.surfaceContainerHighest, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              trailing: _buildMemberTrailing(cs, member, isHost, isSelf),
              onTap: () {},
              showChevron: false,
              borderRadius: BorderRadius.circular(18.0),
            ),
          );
        },
      );
    });
  }

  Widget _buildMemberTrailing(
    ColorScheme cs,
    WatchiumMember member,
    bool isHost,
    bool isSelf,
  ) {
    final isCohost = member.role == 'cohost';
    final canKick =
        (isHost || isCohost) && !isSelf && member.role != 'host';
    final canManage = isHost && !isSelf && member.role != 'host';

    final List<Widget> badges = [];
    if (member.role == 'host') {
      badges.add(const Icon(
        Iconsax.crown5,
        color: Colors.amber,
        size: 16,
      ));
    }
    if (isCohost) {
      badges.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange.opaque(0.12, iReallyMeanIt: true),
          borderRadius: BorderRadius.circular(6),
          border:
              Border.all(color: Colors.orange.opaque(0.3, iReallyMeanIt: true)),
        ),
        child: const AnymeXText(
          'CO-HOST',
          size: 9,
          variant: TextVariant.semiBold,
          color: Colors.orange,
        ),
      ));
    }

    Widget? action;
    if (canManage) {
      action = PopupMenuButton<String>(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.more_vert, size: 18, color: cs.onSurface),
        ),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'kick',
            child: Row(
              children: [
                Icon(Icons.person_remove_rounded,
                    color: Colors.red, size: 18),
                SizedBox(width: 10),
                AnymeXText('Remove Member'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'transfer',
            child: Row(
              children: [
                Icon(Icons.workspace_premium,
                    color: Colors.amber, size: 18),
                SizedBox(width: 10),
                AnymeXText('Transfer Host'),
              ],
            ),
          ),
          PopupMenuItem(
            value: member.role == 'cohost' ? 'demote' : 'promote',
            child: Row(
              children: [
                Icon(
                  member.role == 'cohost'
                      ? Icons.remove_circle_outline
                      : Icons.shield,
                  color: Colors.orange,
                  size: 18,
                ),
                const SizedBox(width: 10),
                AnymeXText(
                  member.role == 'cohost'
                      ? 'Remove Co-host'
                      : 'Make Co-host',
                ),
              ],
            ),
          ),
        ],
        onSelected: (value) => _handleMemberAction(value, member),
      );
    } else if (canKick) {
      action = GestureDetector(
        onTap: () => _confirmKick(member),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.error.opaque(0.1, iReallyMeanIt: true),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: cs.error.opaque(0.2, iReallyMeanIt: true)),
          ),
          child: Icon(Icons.person_remove_rounded,
              size: 18, color: cs.error),
        ),
      );
    }

    if (badges.isEmpty && action == null) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...badges.map((b) => Padding(
              padding: const EdgeInsets.only(left: 6),
              child: b,
            )),
        if (action != null) ...[
          const SizedBox(width: 4),
          action,
        ],
      ],
    );
  }

  void _handleMemberAction(String action, WatchiumMember member) {
    switch (action) {
      case 'kick':
        _confirmKick(member);
        break;
      case 'transfer':
        _confirmTransferHost(member);
        break;
      case 'promote':
        widget.watchium.promoteCohost(member.userId);
        break;
      case 'demote':
        widget.watchium.demoteCohost(member.userId);
        break;
    }
  }

  Future<void> _confirmTransferHost(WatchiumMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const AnymeXText('Transfer host'),
        content: AnymeXText(
            'Make ${member.username} the new host? You\'ll become a regular member.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const AnymeXText('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const AnymeXText('Transfer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      widget.watchium.transferHost(member.userId);
    }
  }

  Future<void> _confirmKick(WatchiumMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const AnymeXText('Remove member'),
        content:
            AnymeXText('Remove ${member.username} from this watch party?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const AnymeXText('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ctx.theme.colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const AnymeXText('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      widget.watchium.kickMember(member.userId);
    }
  }

  void _showReactionPicker(BuildContext context) {
    final RenderBox? overlay = context.findRenderObject() as RenderBox?;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        overlay?.localToGlobal(Offset.zero).dx ?? 0,
        (overlay?.localToGlobal(Offset.zero).dy ?? 0) - 50,
        0,
        0,
      ),
      items: _quickReactions.map((emoji) {
        return PopupMenuItem<String>(
          value: emoji,
          height: 40,
          child: Center(
            child: AnymeXText(emoji, style: const TextStyle(fontSize: 24)),
          ),
        );
      }).toList(),
    ).then((selected) {
      if (selected != null) {
        widget.watchium.sendReaction(selected);
      }
    });
  }

  Widget _buildInfo(ColorScheme cs, ThemeData theme) {
    return Obx(() {
      final state = widget.watchium.roomState.value;
      if (state == null) return const SizedBox.shrink();

      final createdAt = DateTime.fromMillisecondsSinceEpoch(state.createdAt);
      final now = DateTime.now();
      final duration = now.difference(createdAt);
      final durationStr = _formatDuration(duration);
      final code = state.code;
      final watchium = widget.watchium;
      final inviteUrl = '${watchium.serverUrl}/join/$code?anymex';
      final onlineCount = state.members.where((m) => m.online).length;

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          AnymeXSectionBuilder(
            margin: EdgeInsets.zero,
            title: 'Room Access',
            children: [
              AnymeXTile(
                icon: Icons.vpn_key_rounded,
                title: 'Room Code',
                subtitleWidget: AnymeXText(
                  code,
                  size: 14,
                  variant: TextVariant.semiBold,
                  color: cs.onSurface,
                  style: const TextStyle(letterSpacing: 2),
                ),
                trailing: _buildCopyButton(
                  cs,
                  onTap: () => _copyToClipboard(code, 'Room code'),
                ),
                onTap: () => _copyToClipboard(code, 'Room code'),
                showChevron: false,
              ),
              AnymeXTile(
                icon: Icons.link_rounded,
                iconColor: Colors.purple,
                title: 'Invite Link',
                subtitleWidget: AnymeXText(
                  inviteUrl,
                  size: 12,
                  color: cs.primary,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                trailing: _buildCopyButton(
                  cs,
                  onTap: () => _copyToClipboard(inviteUrl, 'Invite link'),
                ),
                onTap: () => _copyToClipboard(inviteUrl, 'Invite link'),
                showChevron: false,
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnymeXSectionBuilder(
            margin: EdgeInsets.zero,
            title: 'Activity',
            children: [
              AnymeXTile(
                icon: Icons.schedule_rounded,
                iconColor: Colors.blue,
                title: 'Room Duration',
                subtitle: durationStr,
                showChevron: false,
              ),
              AnymeXTile(
                icon: Icons.people_rounded,
                iconColor: Colors.green.opaque(0.8, iReallyMeanIt: true),
                title: 'Watching Now',
                subtitle: '$onlineCount / ${state.maxMembers} members',
                showChevron: false,
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnymeXSectionBuilder(
            margin: EdgeInsets.zero,
            title: 'Details',
            children: [
              AnymeXTile(
                icon: Icons.calendar_today_rounded,
                iconColor: Colors.amber,
                title: 'Created',
                subtitle: _formatDateTime(createdAt),
                showChevron: false,
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildCopyButton(ColorScheme cs, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.copy_rounded,
          size: 18,
          color: cs.onSurface.opaque(0.7, iReallyMeanIt: true),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    snackBar('$label copied');
  }
}
