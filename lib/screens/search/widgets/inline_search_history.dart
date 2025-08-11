// ignore_for_file: deprecated_member_use

import 'package:anymex/controllers/service_handler/service_handler.dart';
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Iconsax.clock,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnymexText(
                      text: 'Recent Searches',
                      variant: TextVariant.semiBold,
                      size: 15,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.9),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _clearAllHistory,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.trash,
                          size: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .error
                              .withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        AnymexText(
                          text: "Clear",
                          size: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .error
                              .withOpacity(0.8),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search terms
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: searchTerms.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final term = searchTerms[index];

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onTermSelected(term),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceVariant
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withOpacity(0.05),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Search icon
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Iconsax.search_normal_1,
                                size: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.7),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Search term
                            Expanded(
                              child: AnymexText(
                                text: term,
                                size: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.8),
                              ),
                            ),

                            // Delete button
                            GestureDetector(
                              onTap: () => _deleteTerm(term),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .error
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Iconsax.close_circle,
                                  size: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .error
                                      .withOpacity(0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
