import 'package:anymex/l10n/l10n_extension.dart';
import 'package:anymex/controllers/discord/discord_login.dart';
import 'package:anymex/controllers/discord/discord_rpc.dart';
import 'package:anymex/controllers/services/storage/anymex_cache_manager.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/helper/scroll_wrapper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:get/get.dart';

class SettingsDiscord extends StatefulWidget {
  const SettingsDiscord({super.key});

  @override
  State<SettingsDiscord> createState() => _SettingsDiscordState();
}

class _SettingsDiscordState extends State<SettingsDiscord> {
  late bool hideNsfw;
  late bool showTimestamps;
  late String animeWatching;
  late String animeDetails;
  late String mangaReading;
  late String mangaDetails;
  late String novelReading;
  late String novelDetails;
  late String idleFormat;

  @override
  void initState() {
    super.initState();
    hideNsfw = DiscordRpcKeys.hideNsfw.get<bool>(false);
    showTimestamps = DiscordRpcKeys.showTimestamps.get<bool>(true);
    animeWatching =
        DiscordRpcKeys.animeWatchingFormat.get<String>('Watching \$anime');
    animeDetails =
        DiscordRpcKeys.animeDetailsFormat.get<String>('Viewing \$anime');
    mangaReading =
        DiscordRpcKeys.mangaReadingFormat.get<String>('Reading \$manga');
    mangaDetails =
        DiscordRpcKeys.mangaDetailsFormat.get<String>('Viewing \$manga');
    novelReading =
        DiscordRpcKeys.novelReadingFormat.get<String>('Reading \$novel');
    novelDetails =
        DiscordRpcKeys.novelDetailsFormat.get<String>('Viewing \$novel');
    idleFormat = DiscordRpcKeys.idleFormat.get<String>('Browsing \$status');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rpc = DiscordRPCController.instance;

    return AnymeXScaffold(
      showHeader: true,
      headerTitle: context.l10n.discordRpc,
      body: Builder(
        builder: (ctx) => ScrollWrapper(
          comfortPadding: false,
          customPadding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 30.0),
          children: [
            SizedBox(height: AnymeXHeaderScope.of(ctx)),
            _buildAccountCard(context, rpc, colors),
            const SizedBox(height: 16),
            AnymeXSectionBuilder(
              title: context.l10n.generalPrivacy,
              children: [
                Obx(
                  () => AnymeXTile.toggle(
                    icon: Icons.discord,
                    title: context.l10n.enableDiscordRpc,
                    subtitle: context.l10n.broadcastYourActivityToDiscord,
                    value: rpc.isEnabled,
                    onChanged: (val) => rpc.setEnabled(val),
                  ),
                ),
                AnymeXTile.toggle(
                  icon: Icons.explicit_rounded,
                  title: context.l10n.hideNsfwContent,
                  subtitle:
                      context.l10n.suppressActivityWhenWatchingOrReading,
                  value: hideNsfw,
                  onChanged: (val) {
                    setState(() {
                      hideNsfw = val;
                      DiscordRpcKeys.hideNsfw.set(val);
                    });
                  },
                ),
                AnymeXTile.toggle(
                  icon: Icons.timer_outlined,
                  title: context.l10n.showTimestamps,
                  subtitle: context.l10n.displayPlaybackOrReadingProgressTimestamps,
                  value: showTimestamps,
                  onChanged: (val) {
                    setState(() {
                      showTimestamps = val;
                      DiscordRpcKeys.showTimestamps.set(val);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnymeXSectionBuilder(
              title: context.l10n.activityPhrasing,
              children: [
                AnymeXTile(
                  icon: Icons.movie_creation_outlined,
                  title: context.l10n.watchingAnime,
                  subtitle: animeWatching,
                  onTap: () => _showPhrasingDialog(
                    title: context.l10n.watchingAnimePhrasing,
                    currentVal: animeWatching,
                    defaultVal: 'Watching \$anime',
                    hintText: 'Watching \$anime',
                    variablesHelp: 'Variables: \$anime, \$episode, \$totalEpisodes',
                    onSave: (val) {
                      setState(() {
                        animeWatching = val;
                        DiscordRpcKeys.animeWatchingFormat.set(val);
                      });
                    },
                  ),
                ),
                AnymeXTile(
                  icon: Icons.info_outline_rounded,
                  title: context.l10n.viewingAnimeDetails,
                  subtitle: animeDetails,
                  onTap: () => _showPhrasingDialog(
                    title: context.l10n.animeDetailsPhrasing,
                    currentVal: animeDetails,
                    defaultVal: 'Viewing \$anime',
                    hintText: 'Viewing \$anime',
                    variablesHelp: 'Variables: \$anime',
                    onSave: (val) {
                      setState(() {
                        animeDetails = val;
                        DiscordRpcKeys.animeDetailsFormat.set(val);
                      });
                    },
                  ),
                ),
                AnymeXTile(
                  icon: Icons.menu_book_outlined,
                  title: context.l10n.readingManga,
                  subtitle: mangaReading,
                  onTap: () => _showPhrasingDialog(
                    title: context.l10n.readingMangaPhrasing,
                    currentVal: mangaReading,
                    defaultVal: 'Reading \$manga',
                    hintText: 'Reading \$manga',
                    variablesHelp:
                        'Variables: \$manga, \$chapter, \$page, \$totalPages',
                    onSave: (val) {
                      setState(() {
                        mangaReading = val;
                        DiscordRpcKeys.mangaReadingFormat.set(val);
                      });
                    },
                  ),
                ),
                AnymeXTile(
                  icon: Icons.info_outline_rounded,
                  title: context.l10n.viewingMangaDetails,
                  subtitle: mangaDetails,
                  onTap: () => _showPhrasingDialog(
                    title: context.l10n.mangaDetailsPhrasing,
                    currentVal: mangaDetails,
                    defaultVal: 'Viewing \$manga',
                    hintText: 'Viewing \$manga',
                    variablesHelp: 'Variables: \$manga',
                    onSave: (val) {
                      setState(() {
                        mangaDetails = val;
                        DiscordRpcKeys.mangaDetailsFormat.set(val);
                      });
                    },
                  ),
                ),
                AnymeXTile(
                  icon: Icons.auto_stories_outlined,
                  title: context.l10n.readingNovel,
                  subtitle: novelReading,
                  onTap: () => _showPhrasingDialog(
                    title: context.l10n.readingNovelPhrasing,
                    currentVal: novelReading,
                    defaultVal: 'Reading \$novel',
                    hintText: 'Reading \$novel',
                    variablesHelp: 'Variables: \$novel, \$chapter',
                    onSave: (val) {
                      setState(() {
                        novelReading = val;
                        DiscordRpcKeys.novelReadingFormat.set(val);
                      });
                    },
                  ),
                ),
                AnymeXTile(
                  icon: Icons.info_outline_rounded,
                  title: context.l10n.viewingNovelDetails,
                  subtitle: novelDetails,
                  onTap: () => _showPhrasingDialog(
                    title: context.l10n.novelDetailsPhrasing,
                    currentVal: novelDetails,
                    defaultVal: 'Viewing \$novel',
                    hintText: 'Viewing \$novel',
                    variablesHelp: 'Variables: \$novel',
                    onSave: (val) {
                      setState(() {
                        novelDetails = val;
                        DiscordRpcKeys.novelDetailsFormat.set(val);
                      });
                    },
                  ),
                ),
                AnymeXTile(
                  icon: Icons.explore_outlined,
                  title: context.l10n.browsingIdle,
                  subtitle: idleFormat,
                  onTap: () => _showPhrasingDialog(
                    title: context.l10n.browsingPhrasing,
                    currentVal: idleFormat,
                    defaultVal: 'Browsing \$status',
                    hintText: 'Browsing \$status',
                    variablesHelp: 'Variables: \$status, \$title',
                    onSave: (val) {
                      setState(() {
                        idleFormat = val;
                        DiscordRpcKeys.idleFormat.set(val);
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    DiscordRPCController rpc,
    ColorScheme colors,
  ) {
    return Obx(() {
      final isDesktop = !rpc.isMobile;
      final isLoggedIn = rpc.isLoggedIn;
      final userData = isLoggedIn ? rpc.profile.value : null;

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.surfaceContainer.opaque(0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isLoggedIn
                ? colors.primary.withOpacity(0.3)
                : colors.outline.withOpacity(0.12),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _buildAvatar(
              isDesktop ? null : userData?.avatarUrl,
              isLoggedIn,
              colors,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnymeXText(
                    isDesktop
                        ? 'Discord Desktop'
                        : (isLoggedIn
                            ? (userData?.displayName ?? 'Discord User')
                            : 'Connect Discord'),
                    variant: TextVariant.bold,
                    size: 16,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isLoggedIn && rpc.isEnabled
                              ? const Color(0xFF43B581)
                              : colors.onSurfaceVariant,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      AnymeXText(
                        isDesktop
                            ? (rpc.isConnected ? 'Connected' : 'Disconnected')
                            : (isLoggedIn
                                ? (rpc.isEnabled
                                    ? 'Rich Presence Active'
                                    : 'Rich Presence Disabled')
                                : 'Not Connected'),
                        color: isLoggedIn && rpc.isEnabled
                            ? const Color(0xFF43B581)
                            : colors.onSurfaceVariant,
                        size: 12,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isDesktop && isLoggedIn)
              GestureDetector(
                onTap: () => _showLogoutDialog(context, rpc),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    IconlyBold.logout,
                    color: colors.error,
                    size: 18,
                  ),
                ),
              ),
            if (!isDesktop && !isLoggedIn)
              GestureDetector(
                onTap: () => context.showDiscordLogin(
                  (token) => rpc.onLoginSuccess(token),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5865F2).opaque(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AnymeXText(
                    context.l10n.login,
                    variant: TextVariant.bold,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildAvatar(String? url, bool isLoggedIn, ColorScheme colors) {
    if (isLoggedIn && url != null) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colors.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: CircleAvatar(
          radius: 28,
          backgroundColor: colors.surfaceContainerHighest,
          backgroundImage: CachedNetworkImageProvider(
            url,
            cacheManager: AnymeXCacheManager.instance,
          ),
        ),
      );
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF5865F2).withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.discord, color: Color(0xFF5865F2), size: 28),
    );
  }

  void _showLogoutDialog(BuildContext context, DiscordRPCController rpc) {
    AnymeXDialog(
      title: context.l10n.disconnectDiscord,
      message: context.l10n.yourRichPresenceActivityWillStop,
      confirmText: context.l10n.disconnect,
      cancelText: context.l10n.cancel,
      onConfirm: () => rpc.logout(),
    ).show(context);
  }

  void _showPhrasingDialog({
    required String title,
    required String currentVal,
    required String defaultVal,
    required String hintText,
    required String variablesHelp,
    required ValueChanged<String> onSave,
  }) {
    final controller = TextEditingController(text: currentVal);
    final colors = context.colors;

    AnymeXDialog(
      title: title,
      confirmText: context.l10n.save,
      cancelText: context.l10n.cancel,
      onConfirm: () {
        final val = controller.text.trim();
        onSave(val.isEmpty ? defaultVal : val);
      },
      contentWidget: StatefulBuilder(
        builder: (context, setDialogState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnymeXText(
              context.l10n.dynamicVariablesWillBeReplacedAutomatically,
              size: 12,
              color: colors.onSurfaceVariant,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: hintText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                helperText: variablesHelp,
                helperMaxLines: 2,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setDialogState(() {
                    controller.text = defaultVal;
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: AnymeXText(context.l10n.resetToDefault, size: 12),
              ),
            ),
          ],
        ),
      ),
    ).show(context);
  }
}
