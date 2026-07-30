import 'package:anymex/controllers/watchium/watchium_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WatchiumOverlay extends StatelessWidget {
  const WatchiumOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final watchium = Get.find<WatchiumService>();

    return Obx(() {
      if (!watchium.inRoom.value) return const SizedBox.shrink();
      final state = watchium.roomState.value;
      if (state == null) return const SizedBox.shrink();

      return Positioned(
        top: 8,
        left: 8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.live_tv, color: Colors.red, size: 16),
              const SizedBox(width: 6),
              Text(
                'Room ${state.code}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.people,
                color: Colors.white70,
                size: 14,
              ),
              Text(
                '${state.members.where((m) => m.online).length}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showPartyPanel(context, watchium),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Party',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showPartyPanel(BuildContext context, WatchiumService watchium) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PartyPanel(watchium: watchium),
    );
  }
}

class _PartyPanel extends StatelessWidget {
  final WatchiumService watchium;
  const _PartyPanel({required this.watchium});

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
    final state = watchium.roomState.value;
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
            watchium.leaveRoom();
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
    final state = watchium.roomState.value;
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
    final chatController = TextEditingController();

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
          final messages = watchium.chatMessages;
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
              shrinkWrap: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return Padding(
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
                );
              },
            ),
          );
        }),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: chatController,
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
                final text = chatController.text.trim();
                if (text.isEmpty) return;
                watchium.sendChat(text);
                chatController.clear();
              },
              icon: const Icon(Icons.send, size: 18),
            ),
          ],
        ),
      ],
    );
  }
}
