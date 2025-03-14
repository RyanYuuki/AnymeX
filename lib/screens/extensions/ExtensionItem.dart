import 'package:anymex/core/Eval/dart/model/source_preference.dart';
import 'package:anymex/core/Model/Source.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/language.dart';
import 'package:anymex/widgets/AlertDialogBuilder.dart';
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

    return ListTile(
      tileColor: Colors.transparent,
      leading: Container(
        height: 37,
        width: 37,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(32),
        ),
        child: widget.source.iconUrl!.isEmpty
            ? const Icon(Icons.extension_rounded)
            : CachedNetworkImage(
                imageUrl: widget.source.iconUrl!,
                fit: BoxFit.contain,
                width: 37,
                height: 37,
                placeholder: (context, url) =>
                    const Icon(Icons.extension_rounded),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.extension_rounded),
              ),
      ),
      title: Text(widget.source.name!),
      titleTextStyle: TextStyle(
        color: theme.onSurface,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.bold,
        fontSize: 15.0,
      ),
      subtitle: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            completeLanguageName(widget.source.lang!.toLowerCase()),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 10.0,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            widget.source.version!,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 10.0,
            ),
          ),
          if (widget.source.isNsfw!) const SizedBox(width: 4),
          if (widget.source.isNsfw!)
            const Text(
              "(18+)",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 10.0,
              ),
            ),
          if (widget.source.isObsolete ?? false)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                "OBSOLETE",
                style: TextStyle(
                  color: theme.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      trailing: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: AnymexProgressIndicator(strokeWidth: 2.0),
            )
          : _BuildButtons(sourceNotEmpty, updateAvailable),
    );
  }

  Widget _BuildButtons(bool sourceNotEmpty, bool updateAvailable) {
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
        ? TVWrapper(
            child: IconButton(
                onPressed: () => _handleSourceAction(),
                icon: const Icon(Icons.download)),
          )
        : SizedBox(
            width: 84,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TVWrapper(
                  onTap: onTap,
                  child: IconButton(
                    onPressed: onTap,
                    icon: Icon(
                      size: 18,
                      updateAvailable ? Icons.update : Iconsax.trash,
                    ),
                  ),
                ),
                TVWrapper(
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
                    icon: const Icon(Iconsax.setting),
                  ),
                )
              ],
            ),
          );
  }
}
