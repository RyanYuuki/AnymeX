import 'package:anymex/controllers/watchium/watchium_models.dart';
import 'package:anymex/controllers/watchium/watchium_service.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/episodes_pane.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/watch_settings_pane.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/theme_extensions.dart';
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
class WatchTogetherPopup extends StatefulWidget {
  final PlayerController controller;

  const WatchTogetherPopup({super.key, required this.controller});

  @override
  State<WatchTogetherPopup> createState() => _WatchTogetherPopupState();
}

class _WatchTogetherPopupState extends State<WatchTogetherPopup> {
  String? _createdCode;
  String? _shareUrl;
  bool _createdPrivate = false;

  void _closePane() {
    _createdCode = null;
    _shareUrl = null;
    _createdPrivate = false;
    widget.controller.isWatchTogetherPaneOpened.value = false;
  }

  void _handleCreated(String code, String shareUrl, bool wasPrivate) {
    setState(() {
      _createdCode = code;
      _shareUrl = shareUrl;
      _createdPrivate = wasPrivate;
    });
  }

  void _openParty() {
    WatchiumService? watchium;
    try {
      watchium = Get.find<WatchiumService>();
    } catch (_) {
      watchium = null;
    }
    setState(() {
      _createdCode = null;
      _shareUrl = null;
      _createdPrivate = false;
    });
    widget.controller.isWatchTogetherPaneOpened.value = false;
    watchium?.isPartyPaneOpened.value = true;
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
      // Keep the pane open for the success state right after creation,
      // even though creating the room also joins it (inRoom becomes true).
      return EpisodeSidePane(
        isVisible: widget.controller.isWatchTogetherPaneOpened.value &&
            (!inRoom || _createdCode != null),
        onOverlayTap: _closePane,
        child: _WatchTogetherPopupContent(
          controller: widget.controller,
          onClose: _closePane,
          createdCode: _createdCode,
          shareUrl: _shareUrl,
          createdPrivate: _createdPrivate,
          onCreated: _handleCreated,
          onOpenParty: _openParty,
        ),
      );
    });
  }
}

class _WatchTogetherPopupContent extends StatefulWidget {
  final PlayerController controller;
  final VoidCallback onClose;
  final String? createdCode;
  final String? shareUrl;
  final bool createdPrivate;
  final void Function(String code, String shareUrl, bool wasPrivate) onCreated;
  final VoidCallback onOpenParty;

  const _WatchTogetherPopupContent({
    required this.controller,
    required this.onClose,
    required this.createdCode,
    required this.shareUrl,
    required this.createdPrivate,
    required this.onCreated,
    required this.onOpenParty,
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
    final createdCode = widget.createdCode;
    return WatchSettingsPane(
      title: createdCode == null ? 'Watch Party' : 'Room Created!',
      onClose: widget.onClose,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: createdCode == null
            ? Column(
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
              )
            : _buildSuccessView(
                context,
                createdCode,
                widget.shareUrl ?? '',
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

  Widget _buildSuccessView(
      BuildContext context, String code, String shareUrl) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildContextCard(context),
        const SizedBox(height: 20),
        Center(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.check_rounded,
                color: Colors.green, size: 28),
          ),
        ),
        const SizedBox(height: 12),
        AnymeXText(
          'Share the code below with friends to watch together',
          size: 12,
          color: cs.onSurface.opaque(0.5),
          maxLines: 2,
          textAlign: TextAlign.center,
        ),
        if (widget.createdPrivate) ...[
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded,
                      size: 12, color: Colors.orange),
                  SizedBox(width: 4),
                  AnymeXText(
                    'Private room',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: AnymeXText('ROOM CODE',
            size: 11.5,
            variant: TextVariant.bold,
            color: cs.onSurface.opaque(0.45),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: cs.surfaceContainer.opaque(0.45, iReallyMeanIt: true),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: cs.onSurface.opaque(0.08, iReallyMeanIt: true),
              width: 0.8,
            ),
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
        SizedBox(
          width: double.infinity,
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
        const SizedBox(height: 20),
        AnymeXSectionBuilder(
          margin: EdgeInsets.zero,
          title: 'Invite Link',
          children: [
            AnymeXTile(
              icon: Icons.link_rounded,
              iconColor: Colors.purple,
              title: 'Invite Link',
              subtitleWidget: AnymeXText(
                shareUrl,
                size: 12,
                color: cs.primary,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              trailing: GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: shareUrl));
                  successSnackBar('Invite link copied!', title: 'Copied');
                },
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
              ),
              onTap: () {
                Clipboard.setData(ClipboardData(text: shareUrl));
                successSnackBar('Invite link copied!', title: 'Copied');
              },
              showChevron: false,
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: widget.onOpenParty,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.people_rounded, size: 18),
            label: AnymeXText(
              'Open Party Chat',
              variant: TextVariant.semiBold,
              size: 14,
              color: cs.onPrimary,
            ),
          ),
        ),
      ],
    );
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
        final shareUrl = '${watchium.serverUrl}/join/$code?anymex';
        if (mounted) {
          setState(() => _error = null);
          widget.onCreated(code, shareUrl, _password.isNotEmpty);
        }
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
}
