import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/screens/search/source_search_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:get/get.dart';

class InstalledExtensionsGridView extends StatefulWidget {
  final List<Source> sources;
  final ItemType itemType;

  const InstalledExtensionsGridView({
    super.key,
    required this.sources,
    this.itemType = ItemType.anime,
  });

  @override
  State<InstalledExtensionsGridView> createState() =>
      _InstalledExtensionsGridViewState();
}

class _InstalledExtensionsGridViewState
    extends State<InstalledExtensionsGridView> {
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _calculateCrossAxisCount(double width) {
    if (width > 1200) return 4;
    if (width > 700) return 3;
    if (width > 400) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = _calculateCrossAxisCount(screenWidth);

    final filteredSources = widget.sources.where((s) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      final name = (s.name ?? '').toLowerCase();
      final lang = (s.lang ?? '').toLowerCase();
      return name.contains(q) || lang.contains(q);
    }).toList();

    final title = widget.itemType.name.capitalizeFirst ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomSearchBar(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  onSubmitted: (val) {
                    if (val.trim().isEmpty) return;
                    final exactSource = filteredSources.firstOrNull;
                    final sourceController = Get.find<SourceController>();
                    if (exactSource != null) {
                      sourceController.setActiveSource(exactSource);
                    }
                    navigateWithAnimation(() => SourceSearchPage(
                          initialTerm: val,
                          type: widget.itemType,
                          source: exactSource,
                        ));
                  },
                  hintText: "Search $title extensions...",
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color:
                      context.colors.primary.opaque(0.12, iReallyMeanIt: true),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        context.colors.primary.opaque(0.2, iReallyMeanIt: true),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.extension_rounded,
                      size: 14,
                      color: context.colors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${filteredSources.length}',
                      style: TextStyle(
                        fontFamily: 'Poppins-Bold',
                        fontSize: 13,
                        color: context.colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (filteredSources.isEmpty)
            _buildEmptyState(context, title)
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredSources.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 110,
              ),
              itemBuilder: (context, index) {
                final source = filteredSources[index];
                return _ExtensionCard(
                  source: source,
                  itemType: widget.itemType,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 20.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.primary.opaque(0.08, iReallyMeanIt: true),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.extension_off_rounded,
                size: 44,
                color:
                    theme.colorScheme.primary.opaque(0.6, iReallyMeanIt: true),
              ),
            ),
            const SizedBox(height: 14),
            AnymexText.semiBold(
              text: _searchQuery.isEmpty
                  ? 'No $title extensions installed'
                  : 'No extensions found for "$_searchQuery"',
              textAlign: TextAlign.center,
              size: 15,
              color:
                  theme.colorScheme.onSurface.opaque(0.7, iReallyMeanIt: true),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const AnymexText.regular(
                  text: 'Clear Filter',
                  size: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExtensionCard extends StatelessWidget {
  final Source source;
  final ItemType itemType;

  const _ExtensionCard({
    required this.source,
    required this.itemType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sourceController = Get.find<SourceController>();

    return AnymexOnTap(
      scale: 0.98,
      onTap: () {
        sourceController.setActiveSource(source);
        navigateWithAnimation(() => SourceSearchPage(
              initialTerm: '',
              type: itemType,
              source: source,
            ));
      },
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest
              .opaque(0.35, iReallyMeanIt: true),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                theme.colorScheme.onSurface.opaque(0.08, iReallyMeanIt: true),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.onSurface
                      .opaque(0.08, iReallyMeanIt: true),
                  width: 0.8,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: AnymeXImage(
                  width: 48,
                  height: 48,
                  imageUrl: source.iconUrl ?? '',
                  errorImage: '',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          source.name ?? 'Unknown',
                          style: TextStyle(
                            fontFamily: 'Poppins-SemiBold',
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (source.lang != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .opaque(0.15, iReallyMeanIt: true),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            source.lang!.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Poppins-SemiBold',
                              fontSize: 10,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      if (source.lang != null) const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface
                              .opaque(0.08, iReallyMeanIt: true),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'v${source.version ?? "1.0"}',
                          style: TextStyle(
                            fontFamily: 'Poppins-Regular',
                            fontSize: 10,
                            color: theme.colorScheme.onSurface
                                .opaque(0.7, iReallyMeanIt: true),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.primary.opaque(0.12, iReallyMeanIt: true),
                shape: BoxShape.circle,
              ),
              child: Icon(
                IconlyLight.arrowRight,
                color: theme.colorScheme.primary,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
