import 'package:anymex/l10n/l10n_extension.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/ExtensionManager.dart';
import 'package:anymex_extension_runtime_bridge/Extensions/Extensions.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:anymex_extension_runtime_bridge/AnymeXBridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:anymex/screens/settings/sub_settings/settings_extension_manager.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_header.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';

class SettingsExtensions extends StatefulWidget {
  final Function()? onSave;
  const SettingsExtensions({super.key, this.onSave});

  @override
  State<SettingsExtensions> createState() => _SettingsExtensionsState();

  static void push(BuildContext context, {Function()? onSave}) =>
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SettingsExtensions(onSave: onSave)),
      );
}

class _SettingsExtensionsState extends State<SettingsExtensions> {
  final em = Get.find<ExtensionManager>();
  final controller = Get.find<SourceController>();

  bool get _isPluginInstalled =>
      AnymeXRuntimeBridge.isPluginInstalled ||
      AnymeXRuntimeBridge.controller.isReady.value;

  ItemType _tab = ItemType.anime;
  bool _didApplyHighlightTab = false;
  final Map<String, bool> _deleting = {};

  static List<({String label, IconData icon, ItemType type})> get _typeTabs => [
    (label: Get.context!.l10n.anime, icon: Icons.movie_creation_outlined, type: ItemType.anime),
    (label: Get.context!.l10n.manga, icon: Icons.menu_book_outlined, type: ItemType.manga),
    (label: Get.context!.l10n.novel, icon: Icons.auto_stories_outlined, type: ItemType.novel),
  ];

  List<Map<String, dynamic>> get _displayManagers {
    final List<Map<String, dynamic>> list = [];
    final activeManagers = em.managers;

    for (final m in activeManagers) {
      list.add({
        'name': m.name,
        'manager': m,
        'isMock': false,
      });
    }

    final hasAniyomi =
        activeManagers.any((m) => m.name.toLowerCase().contains('aniyomi'));
    final hasCloudStream =
        activeManagers.any((m) => m.name.toLowerCase().contains('cloudstream'));

    if (!hasAniyomi) {
      list.add({
        'name': 'Aniyomi',
        'manager': null,
        'isMock': true,
      });
    }
    if (!hasCloudStream) {
      list.add({
        'name': 'CloudStream',
        'manager': null,
        'isMock': true,
      });
    }

    list.sort((a, b) {
      final managerA = a['manager'] as Extension?;
      final managerB = b['manager'] as Extension?;

      final aRequires = managerA?.requiresPlugin ??
          _isMockPluginRequired(a['name'] as String);
      final bRequires = managerB?.requiresPlugin ??
          _isMockPluginRequired(b['name'] as String);

      if (aRequires != bRequires) {
        return aRequires ? 1 : -1;
      }

      final aName = (a['name'] as String).toLowerCase();
      final bName = (b['name'] as String).toLowerCase();
      if (aName.contains('mangayomi')) return -1;
      if (bName.contains('mangayomi')) return 1;

      return aName.compareTo(bName);
    });

    return list;
  }

  bool _isMockPluginRequired(String name) {
    final lower = name.toLowerCase();
    return lower.contains('aniyomi') || lower.contains('cloudstream');
  }

  bool _managerSupports(Map<String, dynamic> entry, ItemType type) {
    final manager = entry['manager'] as Extension?;
    if (manager != null) {
      return type == ItemType.anime
          ? manager.supportsAnime
          : type == ItemType.manga
              ? manager.supportsManga
              : manager.supportsNovel;
    }
    final name = (entry['name'] as String).toLowerCase();
    if (name.contains('cloudstream')) {
      return type == ItemType.anime;
    }
    if (name.contains('aniyomi')) {
      return type == ItemType.anime || type == ItemType.manga;
    }
    return false;
  }

  IconData _managerIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('cloudstream')) return Icons.cloud_outlined;
    if (lower.contains('aniyomi')) return Icons.play_circle_outline_rounded;
    if (lower.contains('mangayomi')) return Icons.extension_outlined;
    return Icons.widgets_outlined;
  }

  String? _getManagerIconUrl(Map<String, dynamic> entry) {
    final manager = entry['manager'] as Extension?;
    if (manager != null && manager.icon.isNotEmpty) {
      return manager.icon;
    }
    final name = (entry['name'] as String).toLowerCase();
    if (name.contains('aniyomi')) {
      return 'https://aniyomi.org/img/logo-128px.png';
    }
    if (name.contains('cloudstream')) {
      return 'https://static.everythingmoe.com/icons/cloudstream.png';
    }
    if (name.contains('mangayomi')) {
      return 'https://raw.githubusercontent.com/kodjodevf/mangayomi/main/assets/app_icons/icon-red.png';
    }
    return null;
  }

  Widget _buildManagerIcon(String name, String? iconUrl) {
    final colors = context.colors;
    final fallbackIcon = _managerIcon(name);

    final iconContent = (iconUrl != null && iconUrl.isNotEmpty)
        ? ClipRRect(
            borderRadius: BorderRadius.circular(6.multiplyRoundness()),
            child: AnymeXImage(
              imageUrl: iconUrl,
              width: 22,
              height: 22,
              fit: BoxFit.cover,
              radius: 6.multiplyRoundness(),
            ),
          )
        : Icon(fallbackIcon, size: 16, color: colors.primary);

    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10.multiplyRoundness()),
        border: Border.all(
          color: colors.outlineVariant.withOpacity(0.25),
          width: 0.8,
        ),
      ),
      child: iconContent,
    );
  }

  Future<void> _addRepos(
      ItemType type, List<String> urls, Extension activeManager) async {
    await em.addRepos(urls, type, activeManager.id);
    widget.onSave?.call();
    if (mounted) setState(() {});
  }

  Future<void> _removeRepo(Repo repo, ItemType type) async {
    final key = '${repo.url}_${type.name}';
    setState(() => _deleting[key] = true);
    try {
      await em.removeRepo(repo, type);
      widget.onSave?.call();
    } catch (_) {
      snackBar(Get.context!.l10n.failedToRemoveRepo);
    } finally {
      if (mounted) setState(() => _deleting.remove(key));
    }
  }

  void _openAddDialog(Extension targetManager) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => _AddRepoDialog(
        type: _tab,
        manager: targetManager,
        colors: context.colors,
        onAdd: (urls) async {
          await _addRepos(_tab, urls, targetManager);
          if (mounted) {
            snackBar('${urls.length} repo${urls.length > 1 ? 's' : ''} added');
          }
        },
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didApplyHighlightTab) return;
    _didApplyHighlightTab = true;

    final highlight = SettingsHighlightProvider.of(context)?.highlightTitle;
    final nextTab = switch (highlight) {
      'Anime' => ItemType.anime,
      'Manga' => ItemType.manga,
      'Novel' => ItemType.novel,
      _ => null,
    };

    if (nextTab != null && _tab != nextTab) {
      setState(() => _tab = nextTab);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width > 600;
    final hPad = isDesktop ? 24.0 : 16.0;

    return AnymeXScaffold(
      showHeader: false,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnymeXHeader(
              title: context.l10n.extensions,
              action: IconButton(
                onPressed: () =>
                    navigate(() => const SettingsExtensionManager()),
                icon: const Icon(Icons.settings_rounded),
                tooltip: context.l10n.extensionManager,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: _buildTypeBar(),
            ),
            const SizedBox(height: 18),
            _buildBody(hPad),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBar() {
    final colors = context.colors;
    final tabs = _typeTabs;
    final total = tabs.length;
    final currentIndex = tabs.indexWhere((t) => t.type == _tab);
    final alignX = -1.0 + (2.0 * currentIndex / (total - 1));

    return LayoutBuilder(builder: (context, constraints) {
      const minTabWidth = 100.0;
      final naturalTabWidth = constraints.maxWidth / total;
      final tabWidth =
          naturalTabWidth < minTabWidth ? minTabWidth : naturalTabWidth;
      final totalWidth = tabWidth * total;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalWidth,
          child: Container(
            height: 52,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withOpacity(0.35),
              borderRadius: BorderRadius.circular(18.multiplyRoundness()),
              border: Border.all(
                  color: colors.outlineVariant.withOpacity(0.35), width: 1),
            ),
            child: Stack(children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutQuint,
                alignment: Alignment(alignX, 0),
                child: FractionallySizedBox(
                  widthFactor: 1 / total,
                  heightFactor: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius:
                          BorderRadius.circular(14.multiplyRoundness()),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: tabs.map((t) {
                  final selected = _tab == t.type;
                  return Expanded(
                    child: HighlightDecorator(
                      title: t.label,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (!selected) {
                            HapticFeedback.lightImpact();
                            setState(() => _tab = t.type);
                          }
                        },
                        child: AnimatedScale(
                          scale: selected ? 1.03 : 1.0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          child: AnimatedOpacity(
                            opacity: selected ? 1.0 : 0.7,
                            duration: const Duration(milliseconds: 200),
                            child: SizedBox.expand(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    t.icon,
                                    size: 16,
                                    color: selected
                                        ? colors.onPrimary
                                        : colors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: AnymeXText(
                                      t.label,
                                      variant: selected
                                          ? TextVariant.bold
                                          : TextVariant.regular,
                                      size: 13,
                                      color: selected
                                          ? colors.onPrimary
                                          : colors.onSurfaceVariant,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ]),
          ),
        ),
      );
    });
  }

  Widget _buildBody(double hPad) {
    final allManagers = _displayManagers;
    final supportedManagers =
        allManagers.where((m) => _managerSupports(m, _tab)).toList();

    if (supportedManagers.isEmpty) {
      return _buildEmptyTypeState();
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 40),
      child: Column(
        children: supportedManagers
            .map((entry) => _buildManagerInsetGroup(entry))
            .toList(),
      ),
    );
  }

  Widget _buildEmptyTypeState() {
    final colors = context.colors;
    final tabInfo = _typeTabs.firstWhere((t) => t.type == _tab);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20.multiplyRoundness()),
                border:
                    Border.all(color: colors.outlineVariant.withOpacity(0.3)),
              ),
              child:
                  Icon(tabInfo.icon, size: 30, color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            AnymeXText(
              'No ${tabInfo.label} Managers Available',
              variant: TextVariant.bold,
              size: 15,
              color: colors.onSurface,
            ),
            const SizedBox(height: 6),
            AnymeXText(
              'No extension managers currently support ${tabInfo.label.toLowerCase()} content.',
              variant: TextVariant.regular,
              size: 12.5,
              textAlign: TextAlign.center,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagerInsetGroup(Map<String, dynamic> entry) {
    final colors = context.colors;
    final name = entry['name'] as String;
    final bool isMock = entry['isMock'] as bool;
    final Extension? manager = entry['manager'] as Extension?;
    final iconUrl = _getManagerIconUrl(entry);

    if (isMock) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Row(
                children: [
                  _buildManagerIcon(name, iconUrl),
                  const SizedBox(width: 8),
                  AnymeXText(
                    name,
                    variant: TextVariant.bold,
                    size: 13.5,
                    color: colors.onSurface,
                  ),
                  const Spacer(),
                  if (!_isPluginInstalled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.errorContainer.withOpacity(0.2),
                        borderRadius:
                            BorderRadius.circular(8.multiplyRoundness()),
                        border:
                            Border.all(color: colors.error.withOpacity(0.25)),
                      ),
                      child: AnymeXText(
                        'Plugin Required',
                        variant: TextVariant.bold,
                        size: 10,
                        color: colors.error,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(18.multiplyRoundness()),
                border: Border.all(
                  color: colors.outlineVariant.withOpacity(0.35),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildMockManagerContent(entry, name),
            ),
          ],
        ),
      );
    }

    if (manager == null) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final repos = manager.getReposRx(_tab).value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Row(
                children: [
                  _buildManagerIcon(name, iconUrl),
                  const SizedBox(width: 8),
                  AnymeXText(
                    name,
                    variant: TextVariant.bold,
                    size: 13.5,
                    color: colors.onSurface,
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withOpacity(0.4),
                      borderRadius:
                          BorderRadius.circular(8.multiplyRoundness()),
                      border: Border.all(
                          color: colors.outlineVariant.withOpacity(0.25)),
                    ),
                    child: AnymeXText(
                      '${repos.length} installed',
                      variant: TextVariant.semiBold,
                      size: 10,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(18.multiplyRoundness()),
                border: Border.all(
                  color: colors.outlineVariant.withOpacity(0.35),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildRealManagerContent(manager, repos),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMockManagerContent(Map<String, dynamic> entry, String name) {
    final colors = context.colors;

    if (!_isPluginInstalled) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 18, color: colors.error),
                const SizedBox(width: 8),
                AnymeXText(
                  'Runtime Plugin Required',
                  variant: TextVariant.bold,
                  size: 13,
                  color: colors.onSurface,
                ),
              ],
            ),
            const SizedBox(height: 6),
            AnymeXText(
              'To use $name repositories and extensions, please download and install the runtime plugin.',
              variant: TextVariant.regular,
              size: 12,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => navigate(() => const SettingsExtensionManager()),
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const AnymeXText(
                'Open Plugin Downloader',
                variant: TextVariant.bold,
                size: 12,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.multiplyRoundness()),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Obx(() {
      if (AnymeXRuntimeBridge.controller.error.value.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 18, color: colors.error),
                  const SizedBox(width: 8),
                  AnymeXText(
                    'Runtime Error',
                    variant: TextVariant.bold,
                    size: 13,
                    color: colors.onSurface,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              AnymeXText(
                AnymeXRuntimeBridge.controller.error.value,
                variant: TextVariant.regular,
                size: 12,
                color: colors.error,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => AnymeXRuntimeBridge.checkAndInitialize(),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const AnymeXText('Retry',
                    variant: TextVariant.bold, size: 12),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.multiplyRoundness()),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: colors.primary),
            ),
            const SizedBox(width: 10),
            AnymeXText(
              'Starting extension runtime...',
              variant: TextVariant.regular,
              size: 12.5,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRealManagerContent(Extension manager, List<Repo> repos) {
    final colors = context.colors;

    return Column(
      children: [
        if (repos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.layers_clear_outlined,
                  size: 20,
                  color: colors.onSurfaceVariant.withOpacity(0.5),
                ),
                const SizedBox(width: 8),
                AnymeXText(
                  'No repositories added yet',
                  variant: TextVariant.regular,
                  size: 12.5,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          )
        else
          ...repos.asMap().entries.map((entry) {
            final idx = entry.key;
            final repo = entry.value;
            final k = '${repo.url}_${_tab.name}';
            final isDeleting = _deleting[k] == true;

            return Column(
              children: [
                if (idx > 0)
                  Divider(
                    height: 1,
                    indent: 52,
                    endIndent: 12,
                    color: colors.outlineVariant.withOpacity(0.2),
                  ),
                _buildRepoCell(repo, isDeleting),
              ],
            );
          }),
        Divider(
          height: 1,
          color: colors.outlineVariant.withOpacity(0.25),
        ),
        ClipRRect(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(18.multiplyRoundness()),
          ),
          child: InkWell(
            onTap: () => _openAddDialog(manager),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(18.multiplyRoundness()),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_rounded,
                    size: 17,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 6),
                  AnymeXText(
                    'Add Repository to ${manager.name}',
                    variant: TextVariant.bold,
                    size: 12.5,
                    color: colors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRepoCell(Repo repo, bool isDeleting) {
    final colors = context.colors;
    final host = _host(repo.url);

    return AnimatedOpacity(
      opacity: isDeleting ? 0.4 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8.multiplyRoundness()),
              ),
              child: Icon(
                Icons.storage_rounded,
                size: 16,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnymeXText(
                    _path(repo.url),
                    variant: TextVariant.semiBold,
                    size: 12,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: colors.onSurface,
                    ),
                  ),
                  if (host != null) ...[
                    const SizedBox(height: 2),
                    AnymeXText(
                      host,
                      variant: TextVariant.regular,
                      size: 10.5,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
            ),
            _iconBtn(Icons.copy_rounded, colors.onSurfaceVariant, 'Copy URL',
                () {
              Clipboard.setData(ClipboardData(text: repo.url));
              snackBar(context.l10n.urlCopiedToClipboard);
            }),
            const SizedBox(width: 2),
            if (isDeleting)
              Padding(
                padding: const EdgeInsets.all(8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.error,
                  ),
                ),
              )
            else
              _iconBtn(Icons.delete_outline_rounded, colors.error, 'Remove',
                  () => _removeRepo(repo, _tab)),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(
          IconData icon, Color color, String tooltip, VoidCallback onTap) =>
      Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.multiplyRoundness()),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(icon, size: 17, color: color),
          ),
        ),
      );

  String _path(String url) {
    try {
      final p = Uri.parse(url).path;
      return p.isEmpty ? url : p;
    } catch (_) {
      return url;
    }
  }

  String? _host(String url) {
    try {
      final h = Uri.parse(url).host;
      return h.isEmpty ? null : h;
    } catch (_) {
      return null;
    }
  }
}

class _AddRepoDialog extends StatefulWidget {
  final ItemType type;
  final Extension manager;
  final ColorScheme colors;
  final Future<void> Function(List<String>) onAdd;

  const _AddRepoDialog({
    required this.type,
    required this.manager,
    required this.colors,
    required this.onAdd,
  });

  @override
  State<_AddRepoDialog> createState() => _AddRepoDialogState();
}

class _AddRepoDialogState extends State<_AddRepoDialog> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final urls = _ctrl.text
        .trim()
        .split(RegExp(r'[\n,]'))
        .map((u) => u.trim())
        .where((u) => u.isNotEmpty)
        .toList();
    if (urls.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onAdd(urls);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
        snackBar('Failed to add repo: $_error');
      }
    } finally {
      if (mounted && _error == null) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final icon = switch (widget.type) {
      ItemType.anime => Icons.movie_creation_outlined,
      ItemType.manga => Icons.menu_book_outlined,
      _ => Icons.auto_stories_outlined,
    };
    final label = widget.type.name.capitalizeFirst!;

    return AnymeXDialog(
      title: context.l10n.addRepository,
      confirmText: _loading ? 'Adding...' : 'Add Repository',
      onConfirm: _loading ? () {} : _submit,
      isConfirmEnabled: !_loading,
      forceAction: _loading,
      showCancelButton: !_loading,
      autoDismiss: false,
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: c.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: c.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnymeXText(
                      '${widget.manager.name} • $label',
                      variant: TextVariant.bold,
                      size: 13,
                      color: c.onSurface,
                    ),
                    const SizedBox(height: 2),
                    AnymeXText(
                      'Enter one or more repository URLs',
                      variant: TextVariant.regular,
                      size: 11,
                      color: c.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AnymeXText(
            context.l10n.repositoryUrlUpper,
            variant: TextVariant.bold,
            size: 10,
            style: TextStyle(
              letterSpacing: 1.1,
              color: c.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            enabled: !_loading,
            autofocus: true,
            maxLines: 2,
            minLines: 1,
            style: TextStyle(
              fontSize: 12.5,
              fontFamily: 'monospace',
              color: c.onSurface,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: 'https://raw.githubusercontent.com/...',
              hintStyle: TextStyle(
                fontSize: 12,
                color: c.onSurfaceVariant.withOpacity(0.6),
                height: 1.5,
              ),
              contentPadding: const EdgeInsets.all(14),
              filled: true,
              fillColor: c.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: c.outlineVariant.withOpacity(0.6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.primary, width: 1.5),
              ),
            ),
          ),
          if (_loading) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.primary,
                  ),
                ),
                const SizedBox(width: 12),
                AnymeXText(
                  context.l10n.addingRepositoryFetchingExtensions,
                  variant: TextVariant.regular,
                  size: 12,
                  color: c.onSurfaceVariant,
                ),
              ],
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            AnymeXText(
              _error!,
              variant: TextVariant.regular,
              size: 12,
              color: c.error,
            ),
          ],
        ],
      ),
    );
  }
}
