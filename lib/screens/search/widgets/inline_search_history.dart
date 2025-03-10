import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_icon_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:iconsax/iconsax.dart';

class InlineSearchHistory extends StatelessWidget {
  final RxList<String> searchTerms;
  final Function(String) onTermSelected;
  final Function(List<String>) onHistoryUpdated;
  final bool isManga;

  const InlineSearchHistory({
    super.key,
    required this.searchTerms,
    required this.onTermSelected,
    required this.onHistoryUpdated,
    this.isManga = false,
  });

  void _deleteTerm(String term) {
    List<String> updatedTerms = List.from(searchTerms);
    updatedTerms.remove(term);
    _saveToDatabase(updatedTerms);
    onHistoryUpdated(updatedTerms);
  }

  void _clearAllHistory() {
    _saveToDatabase([]);
    onHistoryUpdated([]);
  }

  void _saveToDatabase(List<String> terms) {
    Hive.box('preferences').put(
        isManga
            ? 'manga_searched_queries_${serviceHandler.serviceType.value.name}'
            : 'anime_searched_queries__${serviceHandler.serviceType.value.name}',
        terms);
  }

  @override
  Widget build(BuildContext context) {
    if (searchTerms.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Search History',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Poppins-SemiBold',
              ),
            ),
            Container(
              padding: const EdgeInsets.all(5),
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withAlpha(100),
                  borderRadius: BorderRadius.circular(12)),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _clearAllHistory,
                  child: Row(children: [
                    Icon(
                      Iconsax.trash,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 5),
                    AnymexText(
                      text: "Clear All",
                      variant: TextVariant.semiBold,
                      color: Theme.of(context).colorScheme.primary,
                      size: 12,
                    ),
                    const SizedBox(width: 5),
                  ]),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            // padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: searchTerms.length,
            itemBuilder: (context, index) {
              final term = searchTerms[index];
              final hue = (term.hashCode % 360).abs().toDouble();
              final color = Get.isDarkMode
                  ? HSLColor.fromAHSL(0.08, hue, 0.6, 0.85).toColor()
                  : Theme.of(context).colorScheme.primary;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color,
                    width: 1,
                  ),
                  boxShadow: [glowingShadow(context)],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTermSelected(term),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Iconsax.search_normal,
                              size: 22,
                              color: color.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AnymexText(
                              text: term,
                              variant: TextVariant.semiBold,
                            ),
                          ),
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: AnymexIcon(
                                Iconsax.close_circle,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _deleteTerm(term),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Container _buildTIleV1(BuildContext context, Color color, String term) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color:
            Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTermSelected(term),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Iconsax.search_normal,
                    size: 16,
                    color: color.withOpacity(0.8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnymexText(
                    text: term,
                    variant: TextVariant.semiBold,
                  ),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Iconsax.close_circle,
                      size: 16,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _deleteTerm(term),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
