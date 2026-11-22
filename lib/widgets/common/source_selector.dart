import 'package:anymex/l10n/l10n_extension.dart';
import 'package:anymex/utils/language.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_chip.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/anymex_pills.dart';
import 'package:anymex_extension_runtime_bridge/Services/Aniyomi/Models/Source.dart';
import 'package:anymex_extension_runtime_bridge/Services/Sora/Models/Source.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

String sourceTypeName(Source source) {
  if (source.managerId != null && source.managerId!.isNotEmpty) {
    final mid = source.managerId!;
    final em = Get.isRegistered<ExtensionManager>()
        ? Get.find<ExtensionManager>()
        : null;
    final m = em?.managers.firstWhereOrNull((mgr) =>
        mgr.id.toLowerCase() == mid.toLowerCase() ||
        mgr.name.toLowerCase() == mid.toLowerCase());
    if (m != null) return m.name;
    return mid[0].toUpperCase() + mid.substring(1);
  }
  if (source is ASource) return 'Aniyomi';
  if (source is MSource) return 'Mangayomi';
  if (source is CloudStreamSource) return 'Cloudstream';
  if (source is SSource) return 'Sora';
  if (source is KotatsuSource) return 'Kotatsu';
  return 'Other';
}

bool _matchesType(Source source, String type) {
  if (type == 'All') return true;
  return sourceTypeName(source) == type;
}

class SourceSelectorWidget extends StatelessWidget {
  final Source? activeSource;
  final List<Source> installedSources;

  final void Function(Source source) onSourceSelected;

  final void Function(Source sub)? onSubSourceSelected;

  final VoidCallback? onCloudflareBypass;

  final VoidCallback? onPreferencesTap;

  final bool isManga;

  final String? label;

  final Widget? bottomWidget;

  const SourceSelectorWidget({
    super.key,
    required this.activeSource,
    required this.installedSources,
    required this.onSourceSelected,
    this.onSubSourceSelected,
    this.onCloudflareBypass,
    this.onPreferencesTap,
    this.isManga = false,
    this.label,
    this.bottomWidget,
  });

  void _openSheet(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    final theme = Theme.of(context);
    AnymeXSheet.custom(
      Theme(
        data: theme,
        child: _SourceSheetContent(
          activeSource: activeSource,
          installedSources: installedSources,
          isManga: isManga,
          label: label,
          onSourceSelected: (source) {
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.of(context, rootNavigator: true).pop();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onSourceSelected(source);
            });
          },
          onSubSourceSelected: onSubSourceSelected != null
              ? (sub) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.of(context, rootNavigator: true).pop();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    onSubSourceSelected!(sub);
                  });
                }
              : null,
        ),
      ),
      context,
      showDragHandle: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (installedSources.isEmpty) {
      return _EmptySourceState(isManga: isManga, label: label);
    }

    final hasSource = activeSource != null;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              colors.surfaceContainerHighest.opaque(0.3, iReallyMeanIt: true),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: colors.outline.opaque(0.12, iReallyMeanIt: true)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openSheet(context),
              child: Row(
                children: [
                  _SourceIcon(source: hasSource ? activeSource! : null),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnymeXText(
                          hasSource
                              ? (activeSource!.name?.toUpperCase() ??
                                  'UNKNOWN SOURCE')
                              : 'SELECT SOURCE',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Linotte',
                            fontWeight: FontWeight.w700,
                            color: hasSource
                                ? colors.onSurface
                                : colors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (hasSource)
                          Row(
                            children: [
                              _TypeBadge(source: activeSource!),
                              const SizedBox(width: 5),
                              if ((activeSource!.lang ?? '').isNotEmpty)
                                _LangBadge(lang: activeSource!.lang!),
                              if (activeSource!.isNsfw == true) ...[
                                const SizedBox(width: 5),
                                const _NsfwBadge(),
                              ],
                            ],
                          )
                        else
                          AnymeXText(
                            'Tap to choose a source',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'Linotte',
                              color: colors.onSurfaceVariant
                                  .opaque(0.55, iReallyMeanIt: true),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (hasSource) ...[
                    Icon(
                      Icons.unfold_more_rounded,
                      size: 20,
                      color: colors.onSurfaceVariant
                          .opaque(0.7, iReallyMeanIt: true),
                    ),
                    if (onCloudflareBypass != null) ...[
                      const SizedBox(width: 4),
                      _ActionIconButton(
                        icon: Icons.shield_outlined,
                        onTap: onCloudflareBypass!,
                      ),
                    ],
                    if (onPreferencesTap != null) ...[
                      const SizedBox(width: 4),
                      _ActionIconButton(
                        icon: Icons.tune_rounded,
                        onTap: onPreferencesTap!,
                      ),
                    ],
                  ] else
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: colors.onSurfaceVariant
                          .opaque(0.55, iReallyMeanIt: true),
                    ),
                ],
              ),
            ),
            if (bottomWidget != null) ...[
              const SizedBox(height: 12),
              bottomWidget!,
            ],
          ],
        ),
      ),
    );
  }
}

class _SourceIcon extends StatelessWidget {
  final Source? source;
  const _SourceIcon({this.source});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (source == null) {
      return Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: colors.primaryContainer.opaque(0.5, iReallyMeanIt: true),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.extension_rounded, size: 20, color: colors.primary),
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnymeXImage(
          radius: 10,
          imageUrl: source!.iconUrl ?? source!.managerIcon,
          height: 36,
          width: 36,
        ),
        Positioned(
          bottom: -4,
          right: -4,
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.all(1),
            child: AnymeXImage(
              radius: 4,
              imageUrl: source!.managerIcon,
              height: 16,
              width: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final Source source;
  const _TypeBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _Badge(
      label: sourceTypeName(source),
      bgColor: colors.primaryContainer.opaque(0.55, iReallyMeanIt: true),
      textColor: colors.primary,
    );
  }
}

class _LangBadge extends StatelessWidget {
  final String lang;
  const _LangBadge({required this.lang});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _Badge(
      label: lang.toUpperCase(),
      bgColor: colors.secondaryContainer.opaque(0.55, iReallyMeanIt: true),
      textColor: colors.secondary,
    );
  }
}

class _NsfwBadge extends StatelessWidget {
  const _NsfwBadge();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _Badge(
      label: '18+',
      bgColor: colors.error.opaque(0.14, iReallyMeanIt: true),
      textColor: colors.error,
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  const _Badge({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: AnymeXText(
        label,
        style: TextStyle(
          fontSize: 10,
          fontFamily: 'Linotte',
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon,
                size: 18,
                color: colors.primary.opaque(0.8, iReallyMeanIt: true)),
          ),
        ),
      ),
    );
  }
}

class _EmptySourceState extends StatelessWidget {
  final bool isManga;
  final String? label;
  const _EmptySourceState({required this.isManga, this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer.opaque(0.3, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: colors.outline.opaque(0.15, iReallyMeanIt: true)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.extension_off_rounded,
            size: 22,
            color: colors.onSurfaceVariant.opaque(0.45, iReallyMeanIt: true),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnymeXText(
                  label ??
                      (isManga
                          ? 'No Manga Sources Installed'
                          : 'No Anime Sources Installed'),
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'Linotte',
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                AnymeXText(
                  context.l10n.goToExtensionsToGetStarted,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'Linotte',
                    color: colors.onSurfaceVariant
                        .opaque(0.55, iReallyMeanIt: true),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceSheetContent extends StatefulWidget {
  final Source? activeSource;
  final List<Source> installedSources;
  final bool isManga;
  final String? label;
  final void Function(Source) onSourceSelected;
  final void Function(Source)? onSubSourceSelected;

  const _SourceSheetContent({
    required this.activeSource,
    required this.installedSources,
    required this.isManga,
    required this.onSourceSelected,
    this.onSubSourceSelected,
    this.label,
  });

  @override
  State<_SourceSheetContent> createState() => _SourceSheetContentState();
}

class _SourceSheetContentState extends State<_SourceSheetContent> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  int _tabIndex = 0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> _tabs() {
    final types = <String>{};
    for (final s in widget.installedSources) {
      types.add(sourceTypeName(s));
    }
    return ['All', ...types.toList()..sort()];
  }

  List<Source> _filtered(List<String> tabs) {
    final type = _tabIndex < tabs.length ? tabs[_tabIndex] : 'All';
    final q = _query.toLowerCase();
    return widget.installedSources.where((s) {
      final matchType = _matchesType(s, type);
      final matchQuery = q.isEmpty ||
          (s.name?.toLowerCase().contains(q) ?? false) ||
          (s.lang?.toLowerCase().contains(q) ?? false) ||
          sourceTypeName(s).toLowerCase().contains(q);
      return matchType && matchQuery;
    }).toList();
  }

  String? _getManagerIcon(String type) {
    if (type.toLowerCase() == 'all') return null;
    final lower = type.toLowerCase();
    if (Get.isRegistered<ExtensionManager>()) {
      final em = Get.find<ExtensionManager>();
      final manager = em.managers.firstWhereOrNull(
        (m) =>
            m.name.toLowerCase() == lower ||
            m.id.toLowerCase() == lower ||
            m.name.toLowerCase().contains(lower) ||
            lower.contains(m.name.toLowerCase()),
      );
      if (manager != null && manager.icon.isNotEmpty) {
        return manager.icon;
      }
    }
    final match = widget.installedSources.firstWhereOrNull((s) {
      if (s.managerId != null && s.managerId!.isNotEmpty) {
        if (s.managerId!.toLowerCase() == lower) return true;
      }
      return sourceTypeName(s).toLowerCase() == lower;
    });
    if (match != null && match.managerIcon.isNotEmpty) {
      return match.managerIcon;
    }
    return null;
  }

  Widget? _buildManagerAvatar(
      String type, bool isSelected, BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final iconUrl = _getManagerIcon(type);
    if (iconUrl != null && iconUrl.isNotEmpty) {
      return AnymeXImage(
        imageUrl: iconUrl,
        width: 16,
        height: 16,
        radius: 4,
      );
    }
    if (type.toLowerCase() == 'all') {
      return Icon(
        Icons.apps_rounded,
        size: 16,
        color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
      );
    }
    return Icon(
      Icons.extension_rounded,
      size: 16,
      color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
    );
  }

  bool get _hasLangs {
    final src = widget.activeSource;
    if (src is! ASource) return false;
    return (src.langs?.isNotEmpty) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tabs = _tabs();
    final filtered = _filtered(tabs);
    final showTabs = tabs.length > 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
          child: Row(
            children: [
              Icon(Icons.extension_rounded, size: 20, color: colors.primary),
              const SizedBox(width: 10),
              AnymeXText(
                widget.label ??
                    (widget.isManga
                        ? 'Select Manga Source'
                        : 'Select Anime Source'),
                size: 16,
                variant: TextVariant.bold,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      colors.primaryContainer.opaque(0.4, iReallyMeanIt: true),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AnymeXText(
                  '${widget.installedSources.length} installed',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'Linotte',
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _query = v),
          style: TextStyle(
            fontSize: 14,
            color: colors.onSurface,
            fontFamily: 'Linotte',
          ),
          decoration: InputDecoration(
            hintText: context.l10n.searchSources,
            hintStyle: TextStyle(
              fontSize: 14,
              fontFamily: 'Linotte',
              color: colors.onSurfaceVariant.opaque(0.5, iReallyMeanIt: true),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: colors.onSurfaceVariant.opaque(0.5, iReallyMeanIt: true),
            ),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      size: 18,
                      color: colors.onSurfaceVariant,
                    ),
                    onPressed: () => setState(() {
                      _query = '';
                      _searchCtrl.clear();
                    }),
                  )
                : null,
            filled: true,
            fillColor:
                colors.surfaceContainerHighest.opaque(0.4, iReallyMeanIt: true),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: colors.primary.opaque(0.4, iReallyMeanIt: true),
                width: 1.5,
              ),
            ),
          ),
        ),
        if (showTabs) ...[
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: AnymeXPills(
              items: tabs
                  .map((tab) => PillItem(
                        label: tab,
                        isSelected: _tabIndex == tabs.indexOf(tab),
                        iconUrl: _getManagerIcon(tab),
                        onTap: () {
                          setState(() {
                            _tabIndex = tabs.indexOf(tab);
                          });
                        },
                      ))
                  .toList(),
            ),
          ),
        ],
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.38,
          ),
          child: filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 38,
                        color: colors.onSurfaceVariant
                            .opaque(0.35, iReallyMeanIt: true),
                      ),
                      const SizedBox(height: 8),
                      AnymeXText(
                        context.l10n.noSourcesFound,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Linotte',
                          color: colors.onSurfaceVariant
                              .opaque(0.55, iReallyMeanIt: true),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (ctx, i) {
                    final s = filtered[i];
                    final isSelected = s.id == widget.activeSource?.id &&
                        s.runtimeType == widget.activeSource?.runtimeType;
                    return _SourceTile(
                      source: s,
                      isSelected: isSelected,
                      onTap: () => widget.onSourceSelected(s),
                    );
                  },
                ),
        ),
        if (_hasLangs && widget.onSubSourceSelected != null) ...[
          Divider(
            color: colors.outline.opaque(0.1, iReallyMeanIt: true),
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
          _LangSubPicker(
            activeSource: widget.activeSource! as ASource,
            onSubSelected: widget.onSubSourceSelected!,
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}

class _SourceTile extends StatelessWidget {
  final Source source;
  final bool isSelected;
  final VoidCallback onTap;

  const _SourceTile({
    required this.source,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.opaque(0.10, iReallyMeanIt: true)
                : colors.surfaceContainerHighest
                    .opaque(0.3, iReallyMeanIt: true),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? colors.primary.opaque(0.35, iReallyMeanIt: true)
                  : colors.surface.opaque(0, iReallyMeanIt: true),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnymeXImage(
                    radius: 10,
                    imageUrl: source.iconUrl ?? '',
                    height: 40,
                    width: 40,
                  ),
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: AnymeXImage(
                        radius: 4,
                        imageUrl: source.managerIcon,
                        height: 15,
                        width: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnymeXText(
                      source.name?.toUpperCase() ?? 'UNKNOWN',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'Linotte',
                        fontWeight: FontWeight.w600,
                        color: isSelected ? colors.primary : colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _TypeBadge(source: source),
                        if ((source.lang ?? '').isNotEmpty) ...[
                          const SizedBox(width: 4),
                          _LangBadge(lang: source.lang!),
                        ],
                        if (source.isNsfw == true) ...[
                          const SizedBox(width: 4),
                          const _NsfwBadge(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isSelected
                    ? Icon(
                        Icons.check_circle_rounded,
                        key: const ValueKey('chk'),
                        size: 22,
                        color: colors.primary,
                      )
                    : Icon(
                        Icons.radio_button_unchecked_rounded,
                        key: const ValueKey('emp'),
                        size: 22,
                        color: colors.onSurfaceVariant
                            .opaque(0.28, iReallyMeanIt: true),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangSubPicker extends StatelessWidget {
  final ASource activeSource;
  final void Function(Source sub) onSubSelected;

  const _LangSubPicker({
    required this.activeSource,
    required this.onSubSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final langs = activeSource.langs ?? [];

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.language_rounded,
                size: 15,
                color: colors.onSurfaceVariant.opaque(0.7, iReallyMeanIt: true),
              ),
              const SizedBox(width: 6),
              AnymeXText(
                context.l10n.languageVariant,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Linotte',
                  fontWeight: FontWeight.w600,
                  color:
                      colors.onSurfaceVariant.opaque(0.7, iReallyMeanIt: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: langs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (ctx, i) {
                final lang = langs[i];
                final isActive = lang.id == activeSource.id;
                return GestureDetector(
                  onTap: () => onSubSelected(lang),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? colors.primary
                          : colors.surfaceContainerHighest
                              .opaque(0.5, iReallyMeanIt: true),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? colors.primary
                            : colors.outline.opaque(0.2, iReallyMeanIt: true),
                      ),
                    ),
                    child: AnymeXText(
                      extensionLanguageName(lang.lang),
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Linotte',
                        fontWeight: FontWeight.w600,
                        color: isActive ? colors.onPrimary : colors.onSurface,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
