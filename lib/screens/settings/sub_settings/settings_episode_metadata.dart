import 'package:anymex/core/metadata/episode_metadata_service.dart';
import 'package:anymex/core/metadata/models/episode_metadata.dart';
import 'package:anymex/l10n/l10n_extension.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsEpisodeMetadata extends StatefulWidget {
  const SettingsEpisodeMetadata({super.key});

  @override
  State<SettingsEpisodeMetadata> createState() =>
      _SettingsEpisodeMetadataState();
}

class _SettingsEpisodeMetadataState extends State<SettingsEpisodeMetadata> {
  final service = EpisodeMetadataService.instance;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final cs = theme.colorScheme;

    return AnymeXScaffold(
      showHeader: true,
      headerTitle: context.l10n.episodeMetadata,
      body: Builder(
        builder: (ctx) => SingleChildScrollView(
          padding:
              EdgeInsets.fromLTRB(16.0, AnymeXHeaderScope.of(ctx), 16.0, 30.0),
          child: Obx(() {
            final activeOrder = service.providerOrder.toList();
            final providersMap = {
              for (final p in service.registeredProviders) p.id: p
            };

            final pillOptions = [
              'auto',
              ...service.registeredProviders.map((p) => p.id),
              'none',
            ];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnymeXSectionBuilder(
                  title: context.l10n.metadataFallbackStrategy,
                  children: [
                    AnymeXTile.pills<String>(
                      title: context.l10n.activeSourceMode,
                      expand: false,
                      wrap: false,
                      subtitle:
                          context.l10n.chooseWhetherToMergeProviders,
                      options: pillOptions,
                      value: service.selectedSource.value,
                      optionLabelTransformer: (id) {
                        if (id == 'auto') return context.l10n.autoMerged;
                        if (id == 'none') return context.l10n.labelOff;
                        return providersMap[id]?.name ?? id;
                      },
                      onChanged: (val) {
                        service.setSelectedSource(val);
                      },
                    ),
                  ],
                ),
                AnymeXSectionBuilder(
                  title: context.l10n.providerPriorityToggles,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: AnymeXText(
                        context.l10n.dragHandlesToChangeFetchPriority,
                        variant: TextVariant.regular,
                        size: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activeOrder.length,
                      buildDefaultDragHandles: false,
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) newIndex--;
                        final updated = List<String>.from(activeOrder);
                        final item = updated.removeAt(oldIndex);
                        updated.insert(newIndex, item);
                        service.updateOrder(updated);
                      },
                      itemBuilder: (context, index) {
                        final providerId = activeOrder[index];
                        final provider = providersMap[providerId];

                        return Container(
                          key: ValueKey(providerId),
                          margin: const EdgeInsets.only(bottom: 8.0),
                          decoration: BoxDecoration(
                            color:
                                cs.surfaceContainerHigh.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            leading: ReorderableDragStartListener(
                              index: index,
                              child: Icon(
                                Icons.drag_indicator_rounded,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            title: AnymeXText(
                              provider?.name ?? providerId,
                              variant: TextVariant.bold,
                              size: 15,
                            ),
                            subtitle: AnymeXText(
                              provider?.description ?? '',
                              variant: TextVariant.regular,
                              size: 12,
                              color: cs.onSurfaceVariant,
                            ),
                            trailing: Obx(
                              () => Switch(
                                value:
                                    !service.disabledProviders.contains(providerId),
                                onChanged: (value) {
                                  service.setProviderEnabled(providerId, value);
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                AnymeXSectionBuilder(
                  title: context.l10n.maintenance,
                  children: [
                    AnymeXTile(
                      icon: Icons.cleaning_services_rounded,
                      title: context.l10n.clearMetadataCache,
                      subtitle:
                          context.l10n.flushesInMemoryEpisodeThumbnails,
                      onTap: () {
                        service.clearCache();
                        snackBar(context.l10n.metadataCacheCleared, duration: 1500);
                      },
                    ),
                    AnymeXTile(
                      icon: Icons.restore_rounded,
                      title: context.l10n.resetToDefaultOrder,
                      subtitle:
                          context.l10n.restoreFactoryPriorityOrder,
                      onTap: () {
                        service.resetDefaults();
                        snackBar(context.l10n.resetEpisodeMetadataToDefaults,
                            duration: 1500);
                      },
                    ),
                    if (kDebugMode)
                      AnymeXTile(
                        icon: Icons.science_rounded,
                        title: 'Test All Metadata APIs',
                        subtitle:
                            'Calls all metadata providers and logs raw JSON responses',
                        onTap: () async {
                          snackBar('Testing all metadata APIs...',
                              duration: 1500);
                          await service.testAllProvidersRaw(
                            MetadataTargetIds(
                              anilistId: '16498',
                              malId: '16498',
                              title: 'Attack on Titan',
                            ),
                          );
                          snackBar('Metadata API responses logged',
                              duration: 1500);
                        },
                      ),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
