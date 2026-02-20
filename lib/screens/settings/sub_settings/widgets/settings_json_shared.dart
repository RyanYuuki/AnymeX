import 'dart:convert';

import 'package:anymex/screens/anime/watch/controls/themes/setup/player_control_theme_registry.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

void showJsonPlayerThemesSheet(
    BuildContext context, StateSetter parentSetState, dynamic settings) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => JsonThemesSheet(
      settings: settings,
      parentSetState: parentSetState,
    ),
  );
}

class JsonThemesSheet extends StatefulWidget {
  const JsonThemesSheet({
    super.key,
    required this.settings,
    required this.parentSetState,
  });

  final dynamic settings;
  final StateSetter parentSetState;

  @override
  State<JsonThemesSheet> createState() => JsonThemesSheetState();
}

class JsonThemesSheetState extends State<JsonThemesSheet>
    with SingleTickerProviderStateMixin {
  bool _isImporting = false;
  String? _importStatus;
  bool _importSuccess = false;

  List<dynamic> get _themes => PlayerControlThemeRegistry.jsonThemes;

  Future<void> _pickAndImportFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    setState(() {
      _isImporting = true;
      _importStatus = null;
    });

    int totalAdded = 0;
    int totalUpdated = 0;
    final allErrors = <String>[];
    final allWarnings = <String>[];

    for (final file in result.files) {
      final bytes = file.bytes;
      if (bytes == null) continue;
      String raw;
      try {
        raw = utf8.decode(bytes);
      } catch (_) {
        allErrors.add('${file.name}: not valid UTF-8.');
        continue;
      }

      final importResult =
          PlayerControlThemeRegistry.importFromRawJson(raw.trim());
      totalAdded += importResult.addedThemeIds.length;
      totalUpdated += importResult.updatedThemeIds.length;
      allErrors.addAll(importResult.errors.map((e) => '${file.name}: $e'));
      allWarnings.addAll(importResult.warnings.map((w) => '${file.name}: $w'));
    }

    setState(() {
      _isImporting = false;
      if (allErrors.isNotEmpty && totalAdded == 0 && totalUpdated == 0) {
        _importSuccess = false;
        _importStatus =
            '✗  ${allErrors.first}${allErrors.length > 1 ? ' (+${allErrors.length - 1} more)' : ''}';
      } else {
        _importSuccess = true;
        _importStatus = totalAdded + totalUpdated == 0
            ? 'No new themes found.'
            : '✓  Added $totalAdded, updated $totalUpdated theme(s)';
      }
    });

    widget.parentSetState(() {});
  }

  Future<void> _importFromUrl() async {
    final url = await _showUrlDialog(context);
    if (url == null || url.isEmpty) return;

    setState(() {
      _isImporting = true;
      _importStatus = null;
    });

    final importResult =
        await PlayerControlThemeRegistry.importFromUrl(url.trim());

    setState(() {
      _isImporting = false;
      if (importResult.hasErrors) {
        _importSuccess = false;
        _importStatus =
            '✗  ${importResult.errors.first}${importResult.errors.length > 1 ? ' (+${importResult.errors.length - 1} more)' : ''}';
      } else if (!importResult.isSuccess) {
        _importSuccess = false;
        _importStatus = '✗  No themes were imported.';
      } else {
        _importSuccess = true;
        _importStatus =
            '✓  Added ${importResult.addedThemeIds.length}, updated ${importResult.updatedThemeIds.length} theme(s)';
      }
    });

    widget.parentSetState(() {});
  }

  Future<void> _removeTheme(String id) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Remove Theme'),
            icon: const Icon(Icons.delete_forever_rounded),
            content: Text('Remove "$id"? This cannot be undone.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.errorContainer),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Remove',
                    style: TextStyle(
                        color: Theme.of(ctx).colorScheme.onErrorContainer)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    PlayerControlThemeRegistry.removeDynamicTheme(id);
    if (widget.settings.playerControlTheme == id) {
      widget.settings.playerControlTheme =
          PlayerControlThemeRegistry.defaultThemeId;
    }
    setState(() {});
    widget.parentSetState(() {});
  }

  void _selectTheme(String id) {
    widget.settings.playerControlTheme = id;
    setState(() {});
    widget.parentSetState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final mq = MediaQuery.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        context.colors.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.colors.secondaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.style_rounded,
                          color: context.colors.onSecondaryContainer, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Player Themes',
                              style: tt.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          Text('Import & manage custom JSON themes',
                              style: tt.bodySmall?.copyWith(
                                  color: context.colors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                          backgroundColor:
                              context.colors.surfaceContainerHighest),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _ImportActionsRow(
                  isImporting: _isImporting,
                  onPickFiles: _pickAndImportFiles,
                  onImportUrl: _importFromUrl,
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: _importStatus != null
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: _StatusBanner(
                          message: _importStatus!,
                          isSuccess: _importSuccess,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Installed Themes',
                      style: tt.labelMedium
                          ?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.colors.secondaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_themes.length}',
                        style: tt.labelSmall?.copyWith(
                            color: context.colors.onSecondaryContainer,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _themes.isEmpty
                    ? _EmptyState()
                    : ListView.builder(
                        controller: scrollController,
                        padding: EdgeInsets.fromLTRB(
                            16, 0, 16, mq.padding.bottom + 16),
                        itemCount: _themes.length,
                        itemBuilder: (ctx, i) {
                          final theme = _themes[i];
                          final selected =
                              widget.settings.playerControlTheme == theme.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ThemeCard(
                              theme: theme,
                              selected: selected,
                              onTap: () => _selectTheme(theme.id),
                              onDelete: () => _removeTheme(theme.id),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ImportActionsRow extends StatelessWidget {
  const _ImportActionsRow({
    required this.isImporting,
    required this.onPickFiles,
    required this.onImportUrl,
  });

  final bool isImporting;
  final VoidCallback onPickFiles;
  final VoidCallback onImportUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: FilledButton.icon(
            onPressed: isImporting ? null : onPickFiles,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            icon: isImporting
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: context.colors.onPrimary),
                  )
                : const Icon(Icons.file_open_rounded),
            label: Text(isImporting ? 'Importing…' : 'Add JSON Files'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            onPressed: isImporting ? null : onImportUrl,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.link_rounded, size: 18),
            label: const Text('From URL'),
          ),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message, required this.isSuccess});

  final String message;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final bg = isSuccess
        ? context.colors.primaryContainer
        : context.colors.errorContainer;
    final fg = isSuccess
        ? context.colors.onPrimaryContainer
        : context.colors.onErrorContainer;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.theme,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  final dynamic theme;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    final cardColor = selected
        ? context.colors.primaryContainer
        : context.colors.surfaceContainerLow;
    final borderColor = selected
        ? context.colors.primary.withValues(alpha: 0.5)
        : context.colors.outlineVariant.withValues(alpha: 0.4);
    final nameColor =
        selected ? context.colors.onPrimaryContainer : context.colors.onSurface;
    final idColor = selected
        ? context.colors.onPrimaryContainer.withValues(alpha: 0.7)
        : context.colors.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? context.colors.primary
                      : context.colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  selected ? Icons.check_rounded : Icons.palette_outlined,
                  size: 20,
                  color: selected
                      ? context.colors.onPrimary
                      : context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      theme.name as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600, color: nameColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      theme.id as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall
                          ?.copyWith(color: idColor, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: 'Remove',
                icon: Icon(Icons.delete_outline_rounded,
                    size: 20,
                    color: context.colors.error.withValues(alpha: 0.8)),
                style: IconButton.styleFrom(
                  backgroundColor:
                      context.colors.errorContainer.withValues(alpha: 0.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.style_outlined,
                size: 32, color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Text('No themes yet',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            'Add JSON files or paste a URL\nto install custom themes.',
            textAlign: TextAlign.center,
            style:
                tt.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

Future<String?> _showUrlDialog(BuildContext context) async {
  final controller = TextEditingController();
  String? error;

  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Import from URL'),
        icon: const Icon(Icons.link_rounded),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.url,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'https://example.com/themes.json',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.link_rounded),
                errorText: error,
              ),
              onChanged: (_) {
                if (error != null) setState(() => error = null);
              },
              onSubmitted: (v) {
                if (v.trim().isEmpty) {
                  setState(() => error = 'URL is empty gang.');
                  return;
                }
                Navigator.pop(ctx, v.trim());
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = controller.text.trim();
              if (v.isEmpty) {
                setState(() => error = 'URL is empty gang.');
                return;
              }
              Navigator.pop(ctx, v);
            },
            child: const Text('Import'),
          ),
        ],
      ),
    ),
  );

  controller.dispose();
  return result;
}
