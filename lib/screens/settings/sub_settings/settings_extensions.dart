import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/ExtensionManager.dart';
import 'package:anymex_extension_runtime_bridge/Extensions/Extensions.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:anymex_extension_runtime_bridge/AnymeXBridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:anymex/screens/settings/sub_settings/settings_extension_manager.dart';

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

  bool get _isPluginInstalled => AnymeXRuntimeBridge.isPluginInstalled;

  int _managerIndex = 0;
  ItemType _tab = ItemType.anime;
  bool _didApplyHighlightTab = false;
  final Map<String, bool> _deleting = {};

  static const _typeTabs = [
    (label: 'Anime', icon: Icons.movie_creation_outlined, type: ItemType.anime),
    (label: 'Manga', icon: Icons.menu_book_outlined, type: ItemType.manga),
    (label: 'Novel', icon: Icons.auto_stories_outlined, type: ItemType.novel),
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

    final hasAniyomi = activeManagers.any((m) => m.name.toLowerCase().contains('aniyomi'));
    final hasCloudStream = activeManagers.any((m) => m.name.toLowerCase().contains('cloudstream'));

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

      final aRequires = managerA?.requiresPlugin ?? _isMockPluginRequired(a['name'] as String);
      final bRequires = managerB?.requiresPlugin ?? _isMockPluginRequired(b['name'] as String);

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


  Future<void> _addRepos(ItemType type, List<String> urls) async {
    final currentManagerData = _displayManagers[_managerIndex];
    if (currentManagerData['isMock'] == true) return;
    final activeManager = currentManagerData['manager'] as Extension;
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
      snackBar('Failed to remove repo');
    } finally {
      if (mounted) setState(() => _deleting.remove(key));
    }
  }

  void _openAddDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => _AddRepoDialog(
        type: _tab,
        colors: context.colors,
        onAdd: (urls) async {
          await _addRepos(_tab, urls);
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
  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
        body: Obx(() {
          final displayList = _displayManagers;
          if (displayList.isEmpty) {
            return Column(children: [
              NestedHeader(
                title: 'Extensions',
                action: IconButton(
                  onPressed: () => Get.to(() => const SettingsExtensionManager()),
                  icon: const Icon(Icons.settings_suggest_rounded),
                  tooltip: 'Extension Manager',
                ),
              ),
              Expanded(
                child: Center(
                  child: Text('No extension managers found.',
                      style: TextStyle(color: context.colors.onSurfaceVariant)),
                ),
              ),
            ]);
          }

          if (_managerIndex >= displayList.length) {
            _managerIndex = 0;
          }

          return Column(children: [
            NestedHeader(
              title: 'Extensions',
              action: IconButton(
                onPressed: () => Get.to(() => const SettingsExtensionManager()),
                icon: const Icon(Icons.settings_suggest_rounded),
                tooltip: 'Extension Manager',
              ),
            ),
            const SizedBox(height: 10),
            if (displayList.length > 1) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildManagerBar(),
              ),
              const SizedBox(height: 8),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTypeBar(),
            ),
            const SizedBox(height: 4),
            Expanded(child: _buildBody()),
          ]);
        }),
        floatingActionButton: Obx(() => _buildFab() ?? const SizedBox.shrink()),
      ),
    );
  }

  Widget _buildManagerBar() {
    final colors = context.colors;
    final managers = _displayManagers;
    final total = managers.length;

    double alignX =
        total > 1 ? -1.0 + (2.0 * _managerIndex / (total - 1)) : 0.0;

    return LayoutBuilder(builder: (context, constraints) {
      const minTabWidth = 120.0;
      final naturalTabWidth = constraints.maxWidth / total;
      final tabWidth =
          naturalTabWidth < minTabWidth ? minTabWidth : naturalTabWidth;
      final totalWidth = tabWidth * total;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalWidth,
          child: Container(
            height: 46,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outline.withOpacity(0.1)),
            ),
            child: Stack(children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutQuint,
                alignment: Alignment(alignX, 0),
                child: FractionallySizedBox(
                  widthFactor: 1 / total,
                  heightFactor: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.secondary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: colors.secondary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: managers.asMap().entries.map((e) {
                  final selected = _managerIndex == e.key;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (!selected) {
                          HapticFeedback.lightImpact();
                          setState(() => _managerIndex = e.key);
                        }
                      },
                      child: AnimatedOpacity(
                        opacity: selected ? 1.0 : 0.6,
                        duration: const Duration(milliseconds: 200),
                        child: SizedBox.expand(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.extension_outlined,
                                  size: 14,
                                  color: selected
                                      ? colors.onSecondary
                                      : colors.onSurfaceVariant),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  e.value['name'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: selected
                                        ? colors.onSecondary
                                        : colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
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

  Widget _buildTypeBar() {
    final colors = context.colors;
    const tabs = _typeTabs;
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
            height: 54,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.outline.withOpacity(0.1)),
            ),
            child: Stack(children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutQuint,
                alignment: Alignment(alignX, 0),
                child: FractionallySizedBox(
                  widthFactor: 1 / total,
                  heightFactor: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: colors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
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
                          scale: selected ? 1.05 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: AnimatedOpacity(
                            opacity: selected ? 1.0 : 0.7,
                            duration: const Duration(milliseconds: 200),
                            child: SizedBox.expand(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(t.icon,
                                      size: 16,
                                      color: selected
                                          ? colors.onPrimary
                                          : colors.onSurfaceVariant),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: AnimatedDefaultTextStyle(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontFamily: 'Poppins',
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                        color: selected
                                            ? colors.onPrimary
                                            : colors.onSurfaceVariant,
                                      ),
                                      child: Text(t.label,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1),
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

  Widget _buildBody() {
    if (_managerIndex >= _displayManagers.length) return const SizedBox.shrink();
    final selectedManagerData = _displayManagers[_managerIndex];
    final bool isMock = selectedManagerData['isMock'] as bool;
    
    if (isMock) {
      if (_isPluginInstalled) {
        if (AnymeXRuntimeBridge.controller.error.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: context.colors.error,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to Start Extension Runtime',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AnymeXRuntimeBridge.controller.error.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.colors.error,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => AnymeXRuntimeBridge.checkAndInitialize(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      foregroundColor: context.colors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Starting extension runtime...',
                style: TextStyle(
                  fontSize: 15,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }
      return _buildPluginRequiredPlaceholder(selectedManagerData['name'] as String);
    }
    
    final manager = selectedManagerData['manager'] as Extension;
    final supported = _tab == ItemType.anime
        ? manager.supportsAnime
        : _tab == ItemType.manga
            ? manager.supportsManga
            : manager.supportsNovel;

    if (!supported) return _buildUnsupported();

    return Obx(() {
      final repos = manager.getReposRx(_tab).value;
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: repos.isEmpty
            ? _buildEmpty(key: ValueKey('empty_$_tab'))
            : _buildRepoList(repos, key: ValueKey('list_$_tab')),
      );
    });
  }

  Widget _buildPluginRequiredPlaceholder(String managerName) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.errorContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                size: 32,
                color: colors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Plugin Not Installed',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'To use the $managerName extension manager, you need to download and install the runtime plugin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Get.to(() => const SettingsExtensionManager()),
              icon: const Icon(Icons.download_rounded),
              label: const Text('Go to Plugin Downloader'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnsupported() {
    final colors = context.colors;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(16)),
          child: Icon(Icons.block_outlined,
              size: 28, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        Text('Not supported',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.onSurface)),
        const SizedBox(height: 4),
        Text('${_tab.name.capitalizeFirst} is not supported\nby this manager',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant)),
      ]),
    );
  }

  Widget _buildEmpty({Key? key}) {
    final colors = context.colors;
    final icon = _typeTabs.firstWhere((t) => t.type == _tab).icon;
    return Center(
      key: key,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
              color: colors.surfaceContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20)),
          child: Icon(icon, size: 30, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Text('No repositories yet',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.onSurface)),
        const SizedBox(height: 5),
        Text('Tap + to add a repository URL',
            style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant)),
      ]),
    );
  }

  Widget _buildRepoList(List<Repo> repos, {Key? key}) {
    return ListView.separated(
      key: key,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: repos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final repo = repos[i];
        final k = '${repo.url}_${_tab.name}';
        return _buildRepoCard(repo, isDeleting: _deleting[k] == true);
      },
    );
  }

  Widget _buildRepoCard(Repo repo, {required bool isDeleting}) {
    final colors = context.colors;
    final host = _host(repo.url);

    return AnimatedOpacity(
      opacity: isDeleting ? 0.4 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.outlineVariant.withOpacity(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(9)),
              child: Icon(Icons.storage_outlined,
                  size: 17, color: colors.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _path(repo.url),
                      style: TextStyle(
                          fontSize: 12.5,
                          fontFamily: 'monospace',
                          color: colors.onSurface,
                          fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (host != null) ...[
                      const SizedBox(height: 2),
                      Text(host,
                          style: TextStyle(
                              fontSize: 11, color: colors.onSurfaceVariant)),
                    ],
                  ]),
            ),
            _iconBtn(Icons.copy_outlined, colors.onSurfaceVariant, 'Copy', () {
              Clipboard.setData(ClipboardData(text: repo.url));
              snackBar('URL copied to clipboard');
            }),
            const SizedBox(width: 2),
            if (isDeleting)
              Padding(
                padding: const EdgeInsets.all(9),
                child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: colors.error)),
              )
            else
              _iconBtn(Icons.delete_outline_rounded, colors.error, 'Remove',
                  () => _removeRepo(repo, _tab)),
          ]),
        ),
      ),
    );
  }

  Widget? _buildFab() {
    if (_managerIndex >= _displayManagers.length) return null;
    final selectedManagerData = _displayManagers[_managerIndex];
    if (selectedManagerData['isMock'] == true) return null;

    final manager = selectedManagerData['manager'] as Extension;
    final supported = _tab == ItemType.anime
        ? manager.supportsAnime
        : _tab == ItemType.manga
            ? manager.supportsManga
            : manager.supportsNovel;
    if (!supported) return null;
    final colors = context.colors;
    return FloatingActionButton.extended(
      onPressed: _openAddDialog,
      icon: const Icon(Icons.add, size: 20),
      label: const Text('Add Repo',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _iconBtn(
          IconData icon, Color color, String tooltip, VoidCallback onTap) =>
      Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(icon, size: 18, color: color)),
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
  final ColorScheme colors;
  final Future<void> Function(List<String>) onAdd;

  const _AddRepoDialog(
      {required this.type, required this.colors, required this.onAdd});

  @override
  State<_AddRepoDialog> createState() => _AddRepoDialogState();
}

class _AddRepoDialogState extends State<_AddRepoDialog> {
  final _ctrl = TextEditingController();
  bool _loading = false;

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

    setState(() => _loading = true);
    try {
      await widget.onAdd(urls);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
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

    return Dialog(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: c.primaryContainer,
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, size: 18, color: c.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add Repository',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: c.onSurface)),
                        Text(label,
                            style: TextStyle(
                                fontSize: 12, color: c.onSurfaceVariant)),
                      ]),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded,
                      size: 20, color: c.onSurfaceVariant),
                  style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(32, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                ),
              ]),
              const SizedBox(height: 18),
              Text('REPOSITORY URL',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: c.onSurfaceVariant)),
              const SizedBox(height: 8),
              TextField(
                controller: _ctrl,
                autofocus: true,
                maxLines: 2,
                minLines: 1,
                style: TextStyle(
                    fontSize: 12.5,
                    fontFamily: 'monospace',
                    color: c.onSurface,
                    height: 1.5),
                decoration: InputDecoration(
                  hintText: 'https://raw.githubusercontent.com/...',
                  hintStyle: TextStyle(
                      fontSize: 12,
                      color: c.onSurfaceVariant.withOpacity(0.6),
                      height: 1.5),
                  contentPadding: const EdgeInsets.all(14),
                  filled: true,
                  fillColor: c.surfaceContainer,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: c.outlineVariant.withOpacity(0.6))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: c.primary, width: 1.5)),
                ),
              ),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                  child: TextButton(
                    onPressed:
                        _loading ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: c.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: c.outlineVariant)),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _loading
                        ? Container(
                            key: const ValueKey('loading'),
                            height: 48,
                            decoration: BoxDecoration(
                                color: c.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12)),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: c.primary)),
                                  const SizedBox(width: 10),
                                  Text('Adding…',
                                      style: TextStyle(
                                          color: c.primary,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14)),
                                ]),
                          )
                        : ElevatedButton.icon(
                            key: const ValueKey('add'),
                            onPressed: _submit,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Repository',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.primary,
                              foregroundColor: c.onPrimary,
                              elevation: 0,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                  ),
                ),
              ]),
            ]),
      ),
    );
  }
}
