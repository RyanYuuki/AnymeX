import 'package:anymex/controllers/watchium/watchium_models.dart';
import 'package:anymex/controllers/watchium/watchium_service.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tabbar.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Shows the create/join watch party sheet from inside the player.
Future<void> showWatchiumCreateSheet({
  required BuildContext context,
  required PlayerController playerController,
}) {
  return AnymeXSheet.custom(
    WatchiumCreateSheet(playerController: playerController),
    context,
    showDragHandle: true,
  );
}

class WatchiumCreateSheet extends StatefulWidget {
  final PlayerController playerController;

  const WatchiumCreateSheet({
    super.key,
    required this.playerController,
  });

  @override
  State<WatchiumCreateSheet> createState() => _WatchiumCreateSheetState();
}

class _WatchiumCreateSheetState extends State<WatchiumCreateSheet> {
  bool _isCreating = false;
  String? _error;
  String _joinCode = '';
  String _joinPassword = '';
  bool _joinMode = false;
  double _maxMembers = 10;
  String _password = '';
  bool _isPrivate = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final animeTitle = widget.playerController.anilistData.title;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(cs, animeTitle),
        const Divider(height: 1, thickness: 0.5),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.62,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTabBar(cs),
                const SizedBox(height: 16),
                if (_joinMode) _buildJoinFields(cs) else _buildCreateFields(cs),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  _buildErrorBox(cs, _error!),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ColorScheme cs, String animeTitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primaryContainer.opaque(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.live_tv_rounded, size: 20, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AnymeXText(
                  text: 'Watch Together',
                  variant: TextVariant.bold,
                  size: 16,
                ),
                AnymeXText(
                  text: animeTitle,
                  size: 12,
                  color: cs.onSurface.opaque(0.5),
                  maxLines: 1,
                ),
              ],
            ),
          ),
          AnymexOnTap(
            onTap: () => Navigator.pop(context),
            child:
                Icon(Icons.close_rounded, color: cs.onSurface.opaque(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ColorScheme cs) {
    return AnymeXTabBar(
      selectTabs: const ['Create Room', 'Join Room'],
      selectedIndex: _joinMode ? 1 : 0,
      icons: const [Icons.add_rounded, Icons.login_rounded],
      height: 46,
      activeColor: cs.primary,
      activeTextColor: cs.onPrimary,
      inactiveTextColor: cs.onSurfaceVariant,
      onTabSelected: (index) => setState(() => _joinMode = index == 1),
    );
  }

  Widget _buildJoinFields(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildField(
          cs,
          controller: null,
          label: 'Room Code',
          hint: 'e.g. ABC123',
          prefixIcon: Icons.vpn_key_rounded,
          letterSpacing: 2,
          onChanged: (v) => _joinCode = v.toUpperCase(),
          textCapitalization: TextCapitalization.characters,
          formatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
            LengthLimitingTextInputFormatter(6),
          ],
          onSubmitted: (_) => _joinRoom(),
        ),
        const SizedBox(height: 12),
        _buildField(
          cs,
          controller: null,
          label: 'Password (if required)',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          suffixIcon: _buildVisibilityToggle(cs),
          onChanged: (v) => _joinPassword = v,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isCreating ? null : _joinRoom,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
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
                : const Icon(Icons.login_rounded, size: 18),
            label: AnymeXText(
              text: _isCreating ? 'Joining...' : 'Join Room',
              variant: TextVariant.semiBold,
              size: 14,
              color: cs.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateFields(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people_alt_rounded,
                size: 18, color: cs.onSurface.opaque(0.7)),
            const SizedBox(width: 8),
            const AnymeXText(
              text: 'Max Members',
              variant: TextVariant.semiBold,
              size: 13,
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: cs.primary.opaque(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: AnymeXText(
                text: '${_maxMembers.toInt()}',
                variant: TextVariant.bold,
                size: 12,
                color: cs.primary,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: cs.primary,
            inactiveTrackColor: cs.surfaceContainerHighest,
            thumbColor: cs.primary,
            overlayColor: cs.primary.withValues(alpha: 0.15),
            trackHeight: 4,
          ),
          child: Slider(
            value: _maxMembers,
            min: 2,
            max: 50,
            divisions: 48,
            label: '${_maxMembers.toInt()}',
            onChanged: (v) => setState(() => _maxMembers = v),
          ),
        ),
        const SizedBox(height: 8),
        AnymexOnTap(
          onTap: () => setState(() {
            _isPrivate = !_isPrivate;
            if (!_isPrivate) _password = '';
          }),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outline.opaque(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline_rounded,
                    size: 18, color: cs.onSurface.opaque(0.7)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AnymeXText(
                        text: 'Private Room',
                        variant: TextVariant.semiBold,
                        size: 13,
                      ),
                      AnymeXText(
                        text: 'Friends need a password to join',
                        size: 11,
                        color: cs.onSurface.opaque(0.4),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isPrivate,
                  onChanged: (v) => setState(() {
                    _isPrivate = v;
                    if (!v) _password = '';
                  }),
                ),
              ],
            ),
          ),
        ),
        if (_isPrivate) ...[
          const SizedBox(height: 12),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: _buildField(
              cs,
              controller: null,
              label: 'Room Password',
              hint: 'Set a password for your room',
              prefixIcon: Icons.password_rounded,
              obscureText: _obscurePassword,
              suffixIcon: _buildVisibilityToggle(cs),
              onChanged: (v) => _password = v,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.primary.opaque(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.primary.opaque(0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 16, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: AnymeXText(
                  text: 'Share the code or invite link with friends.',
                  size: 12,
                  color: cs.onSurface.opaque(0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isCreating ? null : _createRoom,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
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
              text: _isCreating ? 'Creating...' : 'Create Room',
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
    required TextEditingController? controller,
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
      controller: controller,
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
        _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        size: 18,
        color: cs.onSurface.opaque(0.5),
      ),
      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
    );
  }

  Widget _buildErrorBox(ColorScheme cs, String message) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.error.opaque(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 16, color: cs.error),
          const SizedBox(width: 8),
          Expanded(
            child: AnymeXText(
              text: message,
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
        animePosterImage: anilistData.poster,
        availableServers: servers,
        maxMembers: _maxMembers.toInt(),
        password: _password.isEmpty ? null : _password,
      );

      if (code != null) {
        Logger.i('Room created: $code', 'WATCHIUM_UI');
        if (mounted) Navigator.pop(context);
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

  Future<void> _joinRoom() async {
    if (_joinCode.length != 6) {
      Logger.w(
          'Join room from dialog: invalid code length ${_joinCode.length}',
          'WATCHIUM_UI');
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
      final ok = await watchium.joinRoom(
        _joinCode,
        password: _joinPassword.isEmpty ? null : _joinPassword,
      );
      if (ok && mounted) {
        Logger.i('Join room succeeded', 'WATCHIUM_UI');
        Navigator.pop(context);
      } else if (mounted) {
        final err = watchium.error.value;
        Logger.w('Join room failed: $err', 'WATCHIUM_UI');
        setState(() => _error = err);
      }
    } catch (e) {
      Logger.e('Join room exception', error: e, loggerName: 'WATCHIUM_UI');
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _showCodeSheet(String code) {
    final watchium = Get.find<WatchiumService>();
    final shareUrl = '${watchium.serverUrl}/join/$code?anymex';
    final cs = Theme.of(Get.context!).colorScheme;

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
                    text: 'Room Created!',
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
                        Text(
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
              text: 'Share this code with friends:',
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
                      successSnackBar('Room code copied to clipboard', title: 'Copied');
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
                      text: 'Copy Code',
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
                      text: 'Copy Link',
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
      Get.context!,
      showDragHandle: true,
    );
  }
}
