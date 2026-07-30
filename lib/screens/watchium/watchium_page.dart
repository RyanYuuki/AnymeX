import 'package:anymex/controllers/watchium/watchium_models.dart';
import 'package:anymex/controllers/watchium/watchium_service.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
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
    setState(() => _isLoading = false);
  }

  Future<void> _joinByCode() async {
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

    final ok = await _watchium.joinRoom(code);
    setState(() => _isLoading = false);

    if (ok) {
      Logger.i('Join by code $code succeeded', 'WATCHIUM_UI');
      if (mounted) {
        snackBar('Joined room! Open the anime to start watching.');
      }
    } else {
      final err = _watchium.error.value;
      Logger.w('Join by code $code failed: $err', 'WATCHIUM_UI');
      setState(() => _error = err);
    }
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
                    Obx(() {
                      if (_watchium.inRoom.value) {
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
      if (roomState == null) return const SizedBox.shrink();

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
            Row(
              children: [
                AnymexText(
                  text: '${roomState.members.length} member(s)',
                  size: 12,
                  color: theme.colorScheme.onSurface.opaque(0.6),
                ),
                const Spacer(),
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
                  setState(() => _isLoading = false);
                  if (ok) {
                    snackBar('Joined room ${room.code}!');
                  } else {
                    errorSnackBar(_watchium.error.value);
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
                              'Episode ${room.content!.episodeNumber}  •  Room ${room.code}',
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
                            Logger.i('Join room from button: ${room.code}', 'WATCHIUM_UI');
                            setState(() => _isLoading = true);
                            final ok =
                                await _watchium.joinRoom(room.code);
                            setState(() => _isLoading = false);
                            if (ok) {
                              snackBar('Joined room ${room.code}!');
                            } else {
                              errorSnackBar(_watchium.error.value);
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
