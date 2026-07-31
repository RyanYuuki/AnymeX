import 'package:anymex/controllers/watchium/watchium_service.dart';
import 'package:anymex/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WatchiumPartyPanel extends StatefulWidget {
  final WatchiumService watchium;

  const WatchiumPartyPanel({super.key, required this.watchium});

  @override
  State<WatchiumPartyPanel> createState() => _WatchiumPartyPanelState();
}

class _WatchiumPartyPanelState extends State<WatchiumPartyPanel> {
  late final TextEditingController _chatController;
  final ScrollController _chatScrollController = ScrollController();
  static const _quickReactions = ['😂', '💀', '🔥', '👍', '❤️', '😮', '👏', '😭'];

  @override
  void initState() {
    super.initState();
    _chatController = TextEditingController();
    // Scroll to bottom when new messages arrive
    ever(widget.watchium.chatMessages, (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_chatScrollController.hasClients) {
          _chatScrollController.animateTo(
            _chatScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.85,
      minChildSize: 0.3,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildMembers(context),
            const SizedBox(height: 16),
            _buildChat(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final state = widget.watchium.roomState.value;
    if (state == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.content?.animeTitle ?? 'No anime selected',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (state.content != null)
                Text(
                  'Episode ${state.content!.episodeNumber}',
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                      fontSize: 13),
                ),
              Text(
                'Room: ${state.code}  |  ${state.members.where((m) => m.online).length} online',
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                    fontSize: 12),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: () {
            Logger.i('Leave room from party panel', 'WATCHIUM_UI');
            widget.watchium.leaveRoom();
            Navigator.pop(context);
          },
          icon: const Icon(Icons.exit_to_app, size: 18),
          label: const Text('Leave'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildMembers(BuildContext context) {
    final state = widget.watchium.roomState.value;
    if (state == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Members',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: state.members.map((m) {
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: m.role == 'host'
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      )
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (m.avatarUrl != null)
                    CircleAvatar(
                      radius: 10,
                      backgroundImage: NetworkImage(m.avatarUrl!),
                    )
                  else
                    const CircleAvatar(
                      radius: 10,
                      child: Icon(Icons.person, size: 12),
                    ),
                  const SizedBox(width: 6),
                  Text(
                    m.username,
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (m.role == 'host')
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Host',
                        style: TextStyle(
                            color: Colors.white, fontSize: 9),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildChat(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chat',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          final messages = widget.watchium.chatMessages;
          if (messages.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No messages yet',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            );
          }
          return ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              controller: _chatScrollController,
              shrinkWrap: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return GestureDetector(
                  onLongPress: () => _showReactionPicker(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (msg.avatarUrl != null)
                          CircleAvatar(
                            radius: 12,
                            backgroundImage:
                                NetworkImage(msg.avatarUrl!),
                          )
                        else
                          const CircleAvatar(
                            radius: 12,
                            child: Icon(Icons.person, size: 14),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.username,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary,
                                ),
                              ),
                              Text(
                                msg.text,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }),
        const SizedBox(height: 8),
        // Quick reaction bar
        _buildQuickReactionBar(context),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _chatController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () {
                final text = _chatController.text.trim();
                if (text.isEmpty) return;
                widget.watchium.sendChat(text);
                _chatController.clear();
              },
              icon: const Icon(Icons.send, size: 18),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickReactionBar(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _quickReactions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          final emoji = _quickReactions[index];
          return GestureDetector(
            onTap: () {
              widget.watchium.sendReaction(emoji);
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          );
        },
      ),
    );
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
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
        );
      }).toList(),
    ).then((selected) {
      if (selected != null) {
        widget.watchium.sendReaction(selected);
      }
    });
  }
}
