import 'package:anymex/controllers/watchium/watchium_models.dart';
import 'package:anymex/controllers/watchium/watchium_service.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/episodes_pane.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/watch_settings_pane.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Watch Party room creation as a player sidebar.
///
/// Mirrors [SourcePopup] / [AudioPopup]: an [EpisodeSidePane] hosting a
/// [WatchSettingsPane] for creating a room. All creation logic is preserved
/// from the previous bottom-sheet implementation.
class WatchTogetherPopup extends StatelessWidget {
  final PlayerController controller;

  const WatchTogetherPopup({super.key, required this.controller});

  void _closePane() {
    controller.isWatchTogetherPaneOpened.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      WatchiumService? watchium;
      try {
        watchium = Get.find<WatchiumService>();
      } catch (_) {
        watchium = null;
      }
      final inRoom = watchium?.inRoom.value ?? false;
      return EpisodeSidePane(
        isVisible: controller.isWatchTogetherPaneOpened.value && !inRoom,
        onOverlayTap: _closePane,
        child: _WatchTogetherPopupContent(
          controller: controller,
          onClose: _closePane,
        ),
      );
    });
  }
}

class _WatchTogetherPopupContent extends StatefulWidget {
  final PlayerController controller;
  final VoidCallback onClose;

  const _WatchTogetherPopupContent({
    required this.controller,
    required this.onClose,
  });

  @override
  State<_WatchTogetherPopupContent> createState() =>
      _WatchTogetherPopupContentState();
}

class _WatchTogetherPopupContentState
    extends State<_WatchTogetherPopupContent> {
  bool _isCreating = false;
  String? _error;
  double _maxMembers = 10;
  String _password = '';
  bool _isPrivate = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return WatchSettingsPane(
      title: 'Watch Party',
      onClose: widget.onClose,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildContextCard(context),
            const SizedBox(height: 16),
            _buildCreateFields(context),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _buildErrorBox(context, _error!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContextCard(BuildContext context) {
    final animeTitle = widget.controller.anilistData.title;
    return Obx(() {
      final episode = widget.controller.currentEpisode.value;
      final epLabel = 'Episode ${episode.number}';
      return AnymeXSectionBuilder(
        margin: EdgeInsets.zero,
        children: [
          AnymeXTile(
            icon: Icons.live_tv_rounded,
            title: animeTitle,
            subtitle: epLabel,
            showChevron: false,
          ),
        ],
      );
    });
  }

  Widget _buildCreateFields(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnymeXSectionBuilder(
          margin: EdgeInsets.zero,
          title: 'Room Settings',
          children: [
            AnymeXTile.slider(
              icon: Icons.people_alt_rounded,
              title: 'Max Members',
              subtitle: 'How many friends can join',
              value: _maxMembers,
              min: 2,
              max: 50,
              divisions: 48,
              valueTransformer: (v) => v.toInt().toString(),
              onChanged: (v) => setState(() => _maxMembers = v),
            ),
            AnymeXTile.toggle(
              icon: Icons.lock_outline_rounded,
              title: 'Private Room',
              subtitle: 'Friends need a password to join',
              value: _isPrivate,
              onChanged: (v) => setState(() {
                _isPrivate = v;
                if (!v) _password = '';
              }),
              child: _buildField(
                cs,
                label: 'Room Password',
                hint: 'Set a password for your room',
                prefixIcon: Icons.password_rounded,
                obscureText: _obscurePassword,
                suffixIcon: _buildVisibilityToggle(cs),
                onChanged: (v) => _password = v,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isCreating ? null : _createRoom,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _isCreating
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.onPrimary,
                    ),
                  )
                : const Icon(Icons.add_rounded, size: 18),
            label: AnymeXText(
              _isCreating ? 'Creating...' : 'Create Room',
              variant: TextVariant.semiBold,
              size: 14,
              color: cs.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField(
    ColorScheme cs, {
    required String label,
    String? hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? formatters,
    bool obscureText = false,
    double letterSpacing = 0,
  }) {
    return TextField(
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      inputFormatters: formatters,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: cs.onSurface,
        letterSpacing: letterSpacing,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: cs.onSurfaceVariant,
        ),
        hintStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: cs.onSurface.opaque(0.35),
          letterSpacing: letterSpacing,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: cs.onSurface.opaque(0.5))
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: cs.surfaceContainerLow,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
      ),
    );
  }

  Widget _buildVisibilityToggle(ColorScheme cs) {
    return IconButton(
      icon: Icon(
        _obscurePassword
            ? Icons.visibility_off_rounded
            : Icons.visibility_rounded,
        size: 18,
        color: cs.onSurface.opaque(0.5),
      ),
      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
    );
  }

  Widget _buildErrorBox(BuildContext context, String message) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.error.opaque(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.error.opaque(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 16, color: cs.error),
          const SizedBox(width: 8),
          Expanded(
            child: AnymeXText(
              message,
              size: 12,
              color: cs.error,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createRoom() async {
    Logger.i('Create room from player pane', 'WATCHIUM_UI');
    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      final watchium = Get.find<WatchiumService>();
      final episode = widget.controller.currentEpisode.value;
      final anilistData = widget.controller.anilistData;
      final episodeTracks = widget.controller.episodeTracks;

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
        episodeNumber: int.tryParse(episode.number.toString()) ?? 1,
        anilistId: int.tryParse(anilistData.id),
        malId: int.tryParse(anilistData.idMal),
        animeCoverImage: anilistData.cover,
        animePosterImage: anilistData.poster,
        availableServers: servers,
        maxMembers: _maxMembers.toInt(),
        password: _password.isEmpty ? null : _password,
      );

      if (code != null) {
        Logger.i('Room created: $code', 'WATCHIUM_UI');
        widget.onClose();
        _showCodeSheet(code);
      } else if (mounted) {
        final err = watchium.error.value;
        Logger.w('Room creation failed: $err', 'WATCHIUM_UI');
        setState(() => _error = err);
      }
    } catch (e) {
      Logger.e('Room creation exception', error: e, loggerName: 'WATCHIUM_UI');
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  String _detectVideoType(dynamic video) {
    final url = (video.url ?? '').toString().toLowerCase();
    if (url.contains('.m3u8')) return 'hls';
    if (url.contains('.mpd')) return 'dash';
    if (url.contains('.mp4') || url.contains('.mkv')) return 'mp4';
    return 'other';
  }

  void _showCodeSheet(String code) {
    final watchium = Get.find<WatchiumService>();
    final shareUrl = '${watchium.serverUrl}/join/$code?anymex';
    final ctx = Get.context;
    if (ctx == null) return;
    final cs = Theme.of(ctx).colorScheme;

    AnymeXSheet.custom(
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.green, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: AnymeXText(
                    'Room Created!',
                    variant: TextVariant.bold,
                    size: 16,
                  ),
                ),
                if (_password.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded,
                            size: 12, color: Colors.orange),
                        SizedBox(width: 4),
                        AnymeXText(
                          'Private',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            AnymeXText(
              'Share this code with friends:',
              size: 12,
              color: cs.onSurface.opaque(0.5),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outline.opaque(0.15)),
              ),
              child: SelectableText(
                code,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins-Bold',
                  fontSize: 30,
                  letterSpacing: 6,
                  color: cs.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      successSnackBar('Room code copied to clipboard',
                          title: 'Copied');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.primary,
                      side: BorderSide(color: cs.primary.opaque(0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const AnymeXText(
                      'Copy Code',
                      variant: TextVariant.semiBold,
                      size: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: shareUrl));
                      successSnackBar('Invite link copied!', title: 'Copied');
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.link_rounded, size: 16),
                    label: const AnymeXText(
                      'Copy Link',
                      variant: TextVariant.semiBold,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ctx,
      showDragHandle: true,
    );
  }
}
