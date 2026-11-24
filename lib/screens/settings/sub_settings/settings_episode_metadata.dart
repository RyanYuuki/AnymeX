import 'package:anymex/core/metadata/episode_metadata_service.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
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
      headerTitle: 'Episode Metadata',
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
                  title: 'Metadata Fallback Strategy',
                  children: [
                    AnymeXTile.pills<String>(
                      title: 'Active Source Mode',
                      expand: false,
                      wrap: false,
                      subtitle:
                          'Choose whether to merge providers or force a specific service',
                      options: pillOptions,
                      value: service.selectedSource.value,
                      optionLabelTransformer: (id) {
                        if (id == 'auto') return 'Auto (Merged)';
                        if (id == 'none') return 'Off';
                        return providersMap[id]?.name ?? id;
                      },
                      onChanged: (val) {
                        service.setSelectedSource(val);
                      },
                    ),
                  ],
                ),
                AnymeXSectionBuilder(
                  title: 'Provider Priority & Toggles',
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: AnymeXText(
                        'Drag handles to change fetch priority. Top sources take precedence when resolving episode titles, thumbnails, and descriptions.',
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
                        final isEnabled = service.isProviderEnabled(providerId);

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
                            trailing: Switch(
                              value: isEnabled,
                              onChanged: (value) {
                                service.setProviderEnabled(providerId, value);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                AnymeXSectionBuilder(
                  title: 'Maintenance',
                  children: [
                    AnymeXTile(
                      icon: Icons.cleaning_services_rounded,
                      title: 'Clear Metadata Cache',
                      subtitle:
                          'Flushes in-memory episode thumbnails and titles cache',
                      onTap: () {
                        service.clearCache();
                        snackBar('Metadata cache cleared', duration: 1500);
                      },
                    ),
                    AnymeXTile(
                      icon: Icons.restore_rounded,
                      title: 'Reset to Default Order',
                      subtitle:
                          'Restore factory priority order and enable all providers',
                      onTap: () {
                        service.resetDefaults();
                        snackBar('Reset episode metadata to defaults',
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
