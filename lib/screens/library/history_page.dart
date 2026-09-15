import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_spring_transition.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:anymex/widgets/common/scroll_aware_app_bar.dart';
import 'package:anymex/widgets/header/header.dart';
import 'package:anymex/screens/library/widgets/history_model.dart';
import 'package:anymex/screens/settings/widgets/history_card_gate.dart';
import 'package:anymex/screens/settings/widgets/history_card_selector.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/media_mode_controller.dart';

class HistorySearchController extends GetxController {
  final isSearchActive = false.obs;
  final searchQuery = ''.obs;
  final searchController = TextEditingController();

  void toggleSearch() {
    isSearchActive.value = !isSearchActive.value;
    if (!isSearchActive.value) {
      searchQuery.value = '';
      searchController.clear();
    }
  }

  void search(String val) {
    searchQuery.value = val;
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}

class AnymeXHistoryPage extends StatefulWidget {
  const AnymeXHistoryPage({super.key});

  @override
  State<AnymeXHistoryPage> createState() => _AnymeXHistoryPageState();
}

class _AnymeXHistoryPageState extends State<AnymeXHistoryPage> {
  final _storage = Get.find<OfflineStorageController>();
  final _scrollController = ScrollController();
  final _isAppBarVisibleExternally = ValueNotifier<bool>(true);
  late final MediaModeController _mediaModeController;
  late final HistorySearchController _searchController;
  late Worker _mediaModeWorker;

  @override
  void initState() {
    super.initState();
    _mediaModeController = Get.put(MediaModeController());
    _searchController = Get.put(HistorySearchController());

    _mediaModeWorker = ever(_mediaModeController.rxMode, (_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  @override
  void dispose() {
    _mediaModeWorker.dispose();
    _scrollController.dispose();
    _isAppBarVisibleExternally.dispose();
    super.dispose();
  }

  void _deleteItem(OfflineMedia item, ItemType type) {
    AnymeXDialog(
      title: 'Remove from History',
      contentWidget: AnymeXText(
        'Are you sure you want to remove "${item.name}" from your history?',
        size: 14,
      ),
      onConfirm: () async {
        await _storage.clearMediaHistory(
          item.mediaId ?? '',
          mediaType: type,
        );
      },
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width > 600;
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    const appBarHeight = kToolbarHeight + 20;
    final double bottomPadding =
        isDesktop ? 20.0 : (MediaQuery.paddingOf(context).bottom + 120.0);
    final settingsController = Get.find<Settings>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Obx(() {
            final items = _mediaModeController.currentHistory;
            final query = _searchController.searchQuery.value;
            final filtered = items.where((e) {
              final name = e.name?.toLowerCase() ?? '';
              return name.contains(query.toLowerCase());
            }).toList();

            if (filtered.isEmpty) {
              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(height: statusBarHeight + appBarHeight + 10),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            IconlyLight.activity,
                            size: 64,
                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                          ),
                          const SizedBox(height: 16),
                          AnymeXText(
                            query.isNotEmpty
                                ? 'No search results'
                                : 'No history found',
                            size: 16,
                            variant: TextVariant.semiBold,
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            final currentType = _mediaModeController.mode;

            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(height: statusBarHeight + appBarHeight + 10),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isDesktop ? 4 : 1,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      mainAxisExtent: getHistoryCardHeight(
                        HistoryCardStyle.values[settingsController.historyCardStyle],
                        context,
                      ),
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = filtered[index];
                        return AnymeXSpringTransition(
                          enabled: index < 8,
                          duration: Duration(milliseconds: 350 + (index * 50).clamp(0, 250)),
                          child: GestureDetector(
                            onLongPress: () => _deleteItem(item, currentType),
                            child: HistoryCardGate(
                              data: HistoryModel.fromOfflineMedia(item, currentType),
                              cardStyle: HistoryCardStyle.values[settingsController.historyCardStyle],
                            ),
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: bottomPadding + 60),
                ),
              ],
            );
          }),
          CustomAnimatedAppBar(
            isVisible: _isAppBarVisibleExternally,
            scrollController: _scrollController,
            headerContent: Obx(
              () => Header(
                title: 'History',
                subtitle: 'Your watch & read history',
                isSearchActive: _searchController.isSearchActive.value,
                searchBar: HeaderSearchBar(
                  controller: _searchController.searchController,
                  onChanged: _searchController.search,
                  onClose: _searchController.toggleSearch,
                  hintText: 'Search in History...',
                ),
                actions: [
                  HeaderActionButton(
                    icon: IconlyLight.search,
                    onTap: _searchController.toggleSearch,
                  ),
                ],
              ),
            ),
            visibleStatusBarStyle: SystemUiOverlayStyle(
              statusBarIconBrightness:
                  Theme.of(context).brightness == Brightness.light
                      ? Brightness.dark
                      : Brightness.light,
              statusBarBrightness: Theme.of(context).brightness,
              statusBarColor: Colors.transparent,
            ),
            hiddenStatusBarStyle: SystemUiOverlayStyle(
              statusBarIconBrightness:
                  Theme.of(context).brightness == Brightness.light
                      ? Brightness.dark
                      : Brightness.light,
              statusBarBrightness: Theme.of(context).brightness,
              statusBarColor: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}
