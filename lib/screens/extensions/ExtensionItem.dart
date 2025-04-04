import 'package:anymex/core/Eval/dart/model/source_preference.dart';
import 'package:anymex/core/Model/Source.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/language.dart';
import 'package:anymex/widgets/AlertDialogBuilder.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:isar/isar.dart';

import '../../core/Extensions/GetSourceList.dart';
import '../../core/Extensions/fetch_anime_sources.dart';
import '../../core/Extensions/fetch_manga_sources.dart';
import '../../core/extension_preferences_providers.dart';
import '../../core/get_source_preference.dart';
import '../../main.dart';
import 'ExtensionSettings/ExtensionSettings.dart';

class ExtensionListTileWidget extends ConsumerStatefulWidget {
  final Source source;
  final bool isTestSource;
  final MediaType mediaType;

  const ExtensionListTileWidget(
      {super.key,
      required this.source,
      this.isTestSource = false,
      required this.mediaType});

  @override
  ConsumerState<ExtensionListTileWidget> createState() =>
      _ExtensionListTileWidgetState();
}

class _ExtensionListTileWidgetState
    extends ConsumerState<ExtensionListTileWidget> {
  bool _isLoading = false;

  Future<void> _handleSourceAction() async {
    setState(() => _isLoading = true);

    widget.mediaType == MediaType.manga
        ? await ref.watch(
            fetchMangaSourcesListProvider(id: widget.source.id, reFresh: true)
                .future)
        : await ref.watch(
            fetchAnimeSourcesListProvider(id: widget.source.id, reFresh: true)
                .future);

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final updateAvailable = widget.isTestSource
        ? false
        : compareVersions(widget.source.version!, widget.source.versionLast!) <
            0;
    final sourceNotEmpty = widget.source.sourceCode?.isNotEmpty ?? false;

    return AnymexCard(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: theme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.shadow.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: widget.source.iconUrl!.isEmpty
                ? Icon(Icons.extension_rounded, color: theme.primary)
                : CachedNetworkImage(
                    imageUrl: widget.source.iconUrl!,
                    fit: BoxFit.cover,
                    width: 42,
                    height: 42,
                    placeholder: (context, url) => Icon(
                      Icons.extension_rounded,
                      color: theme.primary,
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.extension_rounded,
                      color: theme.primary,
                    ),
                  ),
          ),
        ),
        title: Text(
          widget.source.name!,
          style: TextStyle(
            color: theme.onSurface,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    completeLanguageName(widget.source.lang!.toLowerCase()),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 10.0,
                      color: theme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.tertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "v${widget.source.version!}",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 10.0,
                      color: theme.tertiary,
                    ),
                  ),
                ),
                if (widget.source.isNsfw!) const SizedBox(width: 6),
                if (widget.source.isNsfw!)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "18+",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 10.0,
                        color: Colors.red,
                      ),
                    ),
                  ),
                if (widget.source.isObsolete ?? false) const SizedBox(width: 6),
                if (widget.source.isObsolete ?? false)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "OBSOLETE",
                      style: TextStyle(
                        color: theme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 10.0,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: _isLoading
            ? Container(
                height: 50,
                width: 50,
                padding: const EdgeInsets.all(2),
                child: const Center(
                    child: AnymexProgressIndicator(strokeWidth: 2.0)),
              )
            : _buildButtons(sourceNotEmpty, updateAvailable, theme),
      ),
    );
  }

  Widget _buildButtons(
      bool sourceNotEmpty, bool updateAvailable, ColorScheme theme) {
    void onTap() async {
      if (updateAvailable) {
        setState(() => _isLoading = true);
        widget.mediaType == MediaType.manga
            ? await ref.watch(fetchMangaSourcesListProvider(
                    id: widget.source.id, reFresh: true)
                .future)
            : await ref.watch(fetchAnimeSourcesListProvider(
                    id: widget.source.id, reFresh: true)
                .future);
        if (mounted) {
          setState(() => _isLoading = false);
        }
      } else {
        AlertDialogBuilder(context)
          ..setTitle("Delete Extension")
          ..setMessage("Are you sure you want to delete this extension?")
          ..setPositiveButton("Yes", () async {
            final sourcePrefsIds = isar.sourcePreferences
                .filter()
                .sourceIdEqualTo(widget.source.id!)
                .findAllSync()
                .map((e) => e.id!)
                .toList();
            final sourcePrefsStringIds = isar.sourcePreferenceStringValues
                .filter()
                .sourceIdEqualTo(widget.source.id!)
                .findAllSync()
                .map((e) => e.id)
                .toList();
            isar.writeTxnSync(() {
              if (widget.source.isObsolete ?? false) {
                isar.sources.deleteSync(widget.source.id!);
              } else {
                isar.sources.putSync(widget.source
                  ..sourceCode = ""
                  ..isAdded = false
                  ..isPinned = false);
              }
              isar.sourcePreferences.deleteAllSync(sourcePrefsIds);
              isar.sourcePreferenceStringValues
                  .deleteAllSync(sourcePrefsStringIds);
            });
          })
          ..setNegativeButton("No", null)
          ..show();
      }
    }

    return !sourceNotEmpty
        ? Container(
            decoration: BoxDecoration(
              color: theme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: AnymexOnTap(
              child: IconButton(
                onPressed: () => _handleSourceAction(),
                icon: Icon(
                  Icons.download,
                  color: theme.onPrimaryContainer,
                  size: 20,
                ),
                tooltip: "Download",
              ),
            ),
          )
        : Container(
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: updateAvailable
                        ? theme.tertiaryContainer
                        : theme.errorContainer.withAlpha(122),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AnymexOnTap(
                    onTap: onTap,
                    child: IconButton(
                      onPressed: onTap,
                      icon: Icon(
                        size: 18,
                        updateAvailable ? Icons.update : Iconsax.trash,
                        color: updateAvailable
                            ? theme.onTertiaryContainer
                            : theme.onErrorContainer,
                      ),
                      tooltip: updateAvailable ? "Update" : "Delete",
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: theme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AnymexOnTap(
                    child: IconButton(
                      onPressed: () async {
                        var sourcePreference =
                            getSourcePreference(source: widget.source)
                                .map((e) => getSourcePreferenceEntry(
                                    e.key!, widget.source.id!))
                                .toList();
                        navigate(
                          () => SourcePreferenceWidget(
                            source: widget.source,
                            sourcePreference: sourcePreference,
                          ),
                        );
                      },
                      icon: Icon(
                        Iconsax.setting,
                        size: 18,
                        color: theme.onSecondaryContainer,
                      ),
                      tooltip: "Settings",
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}
