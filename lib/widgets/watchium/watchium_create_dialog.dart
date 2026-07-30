import 'dart:io';

import 'package:anymex/controllers/watchium/watchium_models.dart';
import 'package:anymex/controllers/watchium/watchium_service.dart';
import 'package:anymex/database/isar_models/video.dart' as anymex_model;
import 'package:anymex/models/Media/media.dart' as anymex;
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class WatchiumCreateDialog extends StatefulWidget {
  final PlayerController playerController;
  final anymex.Media anilistData;

  const WatchiumCreateDialog({
    super.key,
    required this.playerController,
    required this.anilistData,
  });

  @override
  State<WatchiumCreateDialog> createState() => _WatchiumCreateDialogState();
}

class _WatchiumCreateDialogState extends State<WatchiumCreateDialog> {
  bool _isCreating = false;
  String? _error;
  String _joinCode = '';
  bool _joinMode = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.live_tv, size: 40, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'Watch Together',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.anilistData.title?.userPreferred ?? 'Unknown Anime',
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),

            // Tab switch
            Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: 'Create Room',
                    selected: !_joinMode,
                    onTap: () => setState(() => _joinMode = false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TabButton(
                    label: 'Join Room',
                    selected: _joinMode,
                    onTap: () => setState(() => _joinMode = true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_joinMode) ...[
              TextField(
                onChanged: (v) => _joinCode = v.toUpperCase(),
                decoration: InputDecoration(
                  labelText: 'Room Code',
                  hintText: 'e.g. ABC123',
                  prefixIcon: const Icon(Icons.vpn_key),
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                  LengthLimitingTextInputFormatter(6),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isCreating ? null : _joinRoom,
                  icon: _isCreating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.login),
                  label: Text(_isCreating ? 'Joining...' : 'Join Room'),
                ),
              ),
            ] else ...[
              // Show room will be created info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'A room will be created. Share the code with friends.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isCreating ? null : _createRoom,
                  icon: _isCreating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add),
                  label: Text(_isCreating ? 'Creating...' : 'Create Room'),
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createRoom() async {
    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      final watchium = Get.find<WatchiumService>();
      final episode = widget.playerController.currentEpisode.value;

      // Build available servers from video tracks
      final servers = widget.videoTracks.map((v) {
        return WatchiumAnimeServer(
          serverId: v.quality?.replaceAll(' ', '-') ?? 'server-${v.quality ?? "0"}',
          serverName: v.quality ?? 'Server',
          quality: v.quality,
          type: 'hls', // default
        );
      }).toList();

      final code = await watchium.createRoom(
        animeTitle:
            widget.anilistData.title?.userPreferred ?? 'Unknown',
        episodeNumber: int.tryParse(episode.number) ?? 1,
        anilistId: widget.anilistData.id is int
            ? widget.anilistData.id as int
            : int.tryParse(widget.anilistData.id?.toString() ?? ''),
        malId: widget.anilistData.idMal,
        animeCoverImage: widget.anilistData.cover?.extraLarge ??
            widget.anilistData.cover?.large,
        availableServers: servers,
      );

      if (code != null) {
        if (mounted) Navigator.pop(context);
        _showCodeDialog(code);
      } else {
        setState(() => _error = watchium.error.value);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isCreating = false);
    }
  }

  Future<void> _joinRoom() async {
    if (_joinCode.length != 6) {
      setState(() => _error = 'Room code must be 6 characters');
      return;
    }

    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      final watchium = Get.find<WatchiumService>();
      final ok = await watchium.joinRoom(_joinCode);
      if (ok && mounted) {
        Navigator.pop(context);
      } else {
        setState(() => _error = watchium.error.value);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isCreating = false);
    }
  }

  void _showCodeDialog(String code) {
    Get.dialog(
      Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Room Created!',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              Text(
                'Share this code with friends:',
                style: TextStyle(
                    color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(Get.context!)
                      .colorScheme
                      .surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  code,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  Get.snackbar('Copied', 'Room code copied to clipboard');
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy Code'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Get.back(closeOverlays: true),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context)
              .colorScheme
              .surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context)
                        .colorScheme
                        .onSurface,
                fontWeight: selected ? FontWeight.w600 : null,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
