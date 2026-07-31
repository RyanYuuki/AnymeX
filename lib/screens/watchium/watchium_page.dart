import 'package:anymex/controllers/watchium/watchium_models.dart';
import 'package:anymex/controllers/watchium/watchium_service.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex/widgets/watchium/watchium_server_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class WatchiumPage extends StatefulWidget {
  const WatchiumPage({super.key});

  @override
  State<WatchiumPage> createState() => _WatchiumPageState();
}

class _WatchiumPageState extends State<WatchiumPage> {
  final WatchiumService _watchium = Get.find<WatchiumService>();
  final _joinCodeController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    Logger.d('Loading public rooms', 'WATCHIUM_UI');
    setState(() {
      _isLoading = true;
      _error = null;
    });
    await _watchium.listRooms();
    if (mounted) setState(() => _isLoading = false);
  }


  Future<void> _joinByCode({String? password}) async {
    final code = _joinCodeController.text.trim().toUpperCase();
    Logger.i('Join by code: $code', 'WATCHIUM_UI');
    if (code.length != 6) {
      setState(() => _error = 'Room code must be 6 characters');
      Logger.w('Join by code: invalid length ${code.length}', 'WATCHIUM_UI');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final ok = await _watchium.joinRoom(code, password: password);
    if (mounted) setState(() => _isLoading = false);

    if (ok) {
      Logger.i('Join by code $code succeeded', 'WATCHIUM_UI');
      if (mounted) {
        snackBar('Joined room!');
        final roomState = _watchium.roomState.value;
        final content = roomState?.content;
        if (content != null && content.availableServers.isNotEmpty) {
          showWatchiumServerSheet(context: context, content: content);
        }
      }
    } else {
      final err = _watchium.error.value;
      Logger.w('Join by code $code failed: $err', 'WATCHIUM_UI');
      // If password incorrect, show password dialog
      if (err == 'Incorrect password' && mounted) {
        _showPasswordDialog(code);
        return;
      }
      if (mounted) {
        setState(() => _error = err);
        errorSnackBar(err.isEmpty ? 'Failed to join room' : err);
      }
    }
  }

  void _showPasswordDialog(String code) {
    final pwController = TextEditingController();
    Get.dialog(
      Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, size: 40),
              const SizedBox(height: 12),
              const Text('This room requires a password',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(
                controller: pwController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                onSubmitted: (v) {
                  Get.back();
                  _joinByCode(password: v);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Get.back();
                        _joinByCode(password: pwController.text);
                      },
                      child: const Text('Join'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Glow(
      child: Scaffold(
        body: Column(
          children: [
            NestedHeader(
              title: 'Watch Together',
              action: IconButton(
                onPressed: _loadRooms,
                icon: const Icon(Icons.refresh),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildJoinByCodeSection(theme),
                    const SizedBox(height: 24),
                    // Show current room section: either active room OR stuck/joining state
                    Obx(() {
                      if (_watchium.inRoom.value ||
                          _watchium.isJoining.value) {
                        return _buildCurrentRoomSection(theme);
                      }
                      return const SizedBox.shrink();
                    }),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        AnymexText(
                          text: 'Active Rooms',
                          size: 16,
                          variant: TextVariant.semiBold,
                        ),
                        const SizedBox(width: 8),
                        Obx(() {
                          final count = _watchium.publicRooms.length;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: AnymexText(
                              text: '$count',
                              size: 12,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildRoomsList(theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinByCodeSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.opaque(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnymexText(
            text: 'Join with Code',
            size: 14,
            variant: TextVariant.semiBold,
          ),
          const SizedBox(height: 8),
          AnymexText(
            text: 'Enter a 6-character room code to join a watch party',
            size: 12,
            color: theme.colorScheme.onSurface.opaque(0.6),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _joinCodeController,
                  onChanged: (v) => setState(() => _error = null),
                  decoration: InputDecoration(
                    hintText: 'ABC123',
                    hintStyle: TextStyle(
                      letterSpacing: 4,
                      color: theme.colorScheme.onSurface.opaque(0.3),
                    ),
                    prefixIcon: const Icon(Icons.vpn_key),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onSubmitted: (_) => _joinByCode(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _isLoading ? null : _joinByCode,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Join'),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentRoomSection(ThemeData theme) {
    return Obx(() {
      final roomState = _watchium.roomState.value;
      final isJoining = _watchium.isJoining.value;
      final roomCode = _watchium.roomCode.value;
      final errorMsg = _watchium.error.value;

      // Stuck state: inRoom is true or isJoining, but no roomState
      if (roomState == null) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.opaque(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.error.opaque(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      color: theme.colorScheme.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AnymexText(
                      text: isJoining
                          ? 'Joining room $roomCode...'
                          : 'Failed to join room $roomCode',
                      size: 14,
                      variant: TextVariant.semiBold,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
              if (errorMsg.isNotEmpty && !isJoining) ...[
                const SizedBox(height: 4),
                AnymexText(
                  text: errorMsg,
                  size: 12,
                  color: theme.colorScheme.error.opaque(0.8),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Logger.i('Force leaving from stuck state', 'WATCHIUM_UI');
                    _watchium.forceLeaveRoom();
                    setState(() => _error = null);
                    snackBar('Left room');
                  },
                  icon: const Icon(Icons.exit_to_app, size: 16),
                  label: Text(isJoining ? 'Cancel' : 'Leave / Reset'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      // Normal active room state
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.opaque(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.opaque(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people_rounded,
                    color: theme.colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                AnymexText(
                  text: 'In Room: ${roomState.code}',
                  size: 14,
                  variant: TextVariant.semiBold,
                  color: theme.colorScheme.primary,
                ),
                const Spacer(),
                if (_watchium.isHost.value)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: AnymexText(
                      text: 'HOST',
                      size: 10,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
              ],
            ),
            if (roomState.content != null) ...[
              const SizedBox(height: 8),
              AnymexText(
                text:
                    '${roomState.content!.animeTitle} - Episode ${roomState.content!.episodeNumber}',
                size: 12,
              ),
            ],
            const SizedBox(height: 8),
            // Members list with kick buttons
            if (roomState.members.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...roomState.members.map((m) {
                final isSelf = m.userId == _watchium.roomState.value?.hostUserId;
                final canKick = _watchium.isHost.value && !isSelf;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: m.avatarUrl != null
                            ? NetworkImage(m.avatarUrl!)
                            : null,
                        child: m.avatarUrl == null
                            ? Text(m.username[0].toUpperCase(),
                                style: const TextStyle(fontSize: 12))
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(m.username,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (m.role == 'host')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('HOST',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold)),
                        ),
                      if (canKick)
                        IconButton(
                          icon: const Icon(Icons.person_remove, size: 16, color: Colors.red),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            _watchium.kickMember(m.userId);
                            snackBar('Kicked ${m.username}');
                          },
                        ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                AnymexText(
                  text: '${roomState.members.length}/${roomState.maxMembers} members',
                  size: 12,
                  color: theme.colorScheme.onSurface.opaque(0.6),
                ),
                if (_watchium.hasPassword.value) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.lock, size: 12, color: Colors.orange),
                ],
                const Spacer(),
                if (roomState.content != null &&
                    roomState.content!.availableServers.isNotEmpty &&
                    !_watchium.isHost.value)
                  TextButton.icon(
                    onPressed: () {
                      showWatchiumServerSheet(
                          context: context,
                          content: roomState.content!);
                    },
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Play'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                    ),
                  ),
                TextButton.icon(
                  onPressed: () {
                    _watchium.leaveRoom();
                    snackBar('Left the room');
                  },
                  icon: const Icon(Icons.logout, size: 16),
                  label: const Text('Leave'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRoomsList(ThemeData theme) {
    return Obx(() {
      if (_isLoading && _watchium.publicRooms.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (_watchium.publicRooms.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.tv_off_rounded,
                    size: 48, color: theme.colorScheme.onSurface.opaque(0.2)),
                const SizedBox(height: 12),
                AnymexText(
                  text: 'No active rooms',
                  size: 14,
                  color: theme.colorScheme.onSurface.opaque(0.5),
                ),
                const SizedBox(height: 4),
                AnymexText(
                  text: 'Rooms will appear here when someone creates one',
                  size: 12,
                  color: theme.colorScheme.onSurface.opaque(0.3),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        children: _watchium.publicRooms.map((room) {
          return _buildRoomCard(theme, room);
        }).toList(),
      );
    });
  }

  Widget _buildRoomCard(ThemeData theme, WatchiumRoomState room) {
    final isJoinable = room.members.length < room.maxMembers;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.opaque(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isJoinable
              ? () async {
                  Logger.i('Join room from card: ${room.code}', 'WATCHIUM_UI');
                  setState(() => _isLoading = true);
                  final ok = await _watchium.joinRoom(room.code);
                  if (mounted) setState(() => _isLoading = false);
                  if (ok) {
                    snackBar('Joined room ${room.code}!');
                    final rs = _watchium.roomState.value;
                    final c = rs?.content;
                    if (c != null &&
                        c.availableServers.isNotEmpty &&
                        mounted) {
                      showWatchiumServerSheet(context: context, content: c);
                    }
                  } else {
                    errorSnackBar(
                        _watchium.error.value.isEmpty
                            ? 'Failed to join room'
                            : _watchium.error.value);
                  }
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Anime cover
                if (room.content?.animeCoverImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AnymeXImage(
                      imageUrl: room.content!.animeCoverImage!,
                      width: 48,
                      height: 64,
                      fit: BoxFit.cover,
                      radius: 8,
                    ),
                  )
                else
                  Container(
                    width: 48,
                    height: 64,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.tv,
                        color: theme.colorScheme.onSurface.opaque(0.3)),
                  ),
                const SizedBox(width: 12),
                // Room info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (room.content != null)
                        AnymexText(
                          text: room.content!.animeTitle,
                          size: 13,
                          variant: TextVariant.semiBold,
                          maxLines: 1,
                        ),
                      const SizedBox(height: 2),
                      if (room.content != null)
                        AnymexText(
                          text:
                              'Episode ${room.content!.episodeNumber}  \u2022  Room ${room.code}',
                          size: 11,
                          color: theme.colorScheme.onSurface.opaque(0.6),
                        )
                      else
                        AnymexText(
                          text: 'Room ${room.code}',
                          size: 11,
                          color: theme.colorScheme.onSurface.opaque(0.6),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.people_outline,
                              size: 14,
                              color: theme.colorScheme.onSurface.opaque(0.5)),
                          const SizedBox(width: 4),
                          AnymexText(
                            text:
                                '${room.members.length}/${room.maxMembers}',
                            size: 11,
                            color: theme.colorScheme.onSurface.opaque(0.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Join button
                if (isJoinable)
                  FilledButton.tonal(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            Logger.i(
                                'Join room from button: ${room.code}',
                                'WATCHIUM_UI');
                            setState(() => _isLoading = true);
                            final ok =
                                await _watchium.joinRoom(room.code);
                            if (mounted) setState(() => _isLoading = false);
                            if (ok) {
                              snackBar('Joined room ${room.code}!');
                              final rs = _watchium.roomState.value;
                              final c = rs?.content;
                              if (c != null &&
                                  c.availableServers.isNotEmpty &&
                                  mounted) {
                                showWatchiumServerSheet(
                                    context: context, content: c);
                              }
                            } else {
                              errorSnackBar(
                                  _watchium.error.value.isEmpty
                                      ? 'Failed to join room'
                                      : _watchium.error.value);
                            }
                          },
                    child: const Text('Join'),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: AnymexText(
                      text: 'Full',
                      size: 12,
                      color: theme.colorScheme.onSurface.opaque(0.5),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
