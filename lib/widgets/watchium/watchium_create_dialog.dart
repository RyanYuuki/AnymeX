import 'package:anymex/controllers/watchium/watchium_models.dart';
import 'package:anymex/controllers/watchium/watchium_service.dart';
import 'package:anymex/database/isar_models/video.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class WatchiumCreateDialog extends StatefulWidget {
  final PlayerController playerController;

  const WatchiumCreateDialog({
    super.key,
    required this.playerController,
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
    final theme = Theme.of(context);
    final animeTitle = widget.playerController.anilistData.title;

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
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              animeTitle,
              style: theme.textTheme.bodySmall,
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'A room will be created. Share the code or link with friends.',
                        style: TextStyle(fontSize: 12),
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
    Logger.i('Create room from dialog', 'WATCHIUM_UI');
    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      final watchium = Get.find<WatchiumService>();
      final episode = widget.playerController.currentEpisode.value;
      final anilistData = widget.playerController.anilistData;
      final episodeTracks = widget.playerController.episodeTracks;

      // Build server list with full video data
      final servers = episodeTracks.asMap().entries.map((entry) {
        final video = entry.value;
        return WatchiumAnimeServer(
          serverId: entry.key.toString(),
          serverName: video.quality ?? 'Server ${entry.key + 1}',
          quality: video.quality,
          type: _detectVideoType(video),
          url: video.url,
          originalUrl: video.originalUrl,
          headers: video.headers,
          subtitles: video.subtitles
              ?.where((t) => t.file != null && t.label != null)
              .map((t) => WatchiumTrack(file: t.file!, label: t.label!))
              .toList(),
          audios: video.audios
              ?.where((t) => t.file != null && t.label != null)
              .map((t) => WatchiumTrack(file: t.file!, label: t.label!))
              .toList(),
        );
      }).toList();

      final code = await watchium.createRoom(
        animeTitle: anilistData.title,
        episodeNumber: int.tryParse(episode.number) ?? 1,
        anilistId: int.tryParse(anilistData.id),
        malId: int.tryParse(anilistData.idMal),
        animeCoverImage: anilistData.cover,
        availableServers: servers,
      );

      if (code != null) {
        Logger.i('Room created: $code', 'WATCHIUM_UI');
        if (mounted) Navigator.pop(context);
        _showCodeDialog(code);
      } else {
        final err = watchium.error.value;
        Logger.w('Room creation failed: $err', 'WATCHIUM_UI');
        setState(() => _error = err);
      }
    } catch (e) {
      Logger.e('Room creation exception', error: e, loggerName: 'WATCHIUM_UI');
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isCreating = false);
    }
  }

  String _detectVideoType(dynamic video) {
    final url = (video.url ?? '').toString().toLowerCase();
    if (url.contains('.m3u8')) return 'hls';
    if (url.contains('.mpd')) return 'dash';
    if (url.contains('.mp4') || url.contains('.mkv')) return 'mp4';
    return 'other';
  }

  Future<void> _joinRoom() async {
    if (_joinCode.length != 6) {
      Logger.w('Join room from dialog: invalid code length ${_joinCode.length}', 'WATCHIUM_UI');
      setState(() => _error = 'Room code must be 6 characters');
      return;
    }

    Logger.i('Join room from dialog: $_joinCode', 'WATCHIUM_UI');
    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      final watchium = Get.find<WatchiumService>();
      final ok = await watchium.joinRoom(_joinCode);
      if (ok && mounted) {
        Logger.i('Join room succeeded', 'WATCHIUM_UI');
        Navigator.pop(context);
      } else {
        final err = watchium.error.value;
        Logger.w('Join room failed: $err', 'WATCHIUM_UI');
        setState(() => _error = err);
      }
    } catch (e) {
      Logger.e('Join room exception', error: e, loggerName: 'WATCHIUM_UI');
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isCreating = false);
    }
  }

  void _showCodeDialog(String code) {
    final deepLink = 'anymex://watchium/join/$code';

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
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              const Text(
                'Share this code with friends:',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        Get.snackbar('Copied', 'Room code copied to clipboard');
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy Code'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: deepLink));
                        Get.snackbar('Copied', 'Invite link copied!');
                      },
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Copy Link'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Get.back(),
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
          : Theme.of(context).colorScheme.surfaceContainerHighest,
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
                    : Theme.of(context).colorScheme.onSurface,
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
