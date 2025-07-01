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
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and clear button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Iconsax.clock,
                      size: 18,
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnymexText(
                    text: 'Recent Searches',
                    variant: TextVariant.semiBold,
                    size: 16,
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
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .errorContainer
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          Theme.of(context).colorScheme.error.withOpacity(0.5),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Iconsax.trash,
                        size: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .error
                            .withOpacity(0.8),
                      ),
                      const SizedBox(width: 6),
                      AnymexText(
                        text: "Clear",
                        size: 12,
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

          const SizedBox(height: 16),

          // Search terms list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: searchTerms.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final term = searchTerms[index];

              return GestureDetector(
                onTap: () => onTermSelected(term),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.5),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Search icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Iconsax.search_normal_1,
                          size: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.8),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Search term text
                      Expanded(
                        child: AnymexText(
                          text: term,
                          size: 14,
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
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .errorContainer
                                .withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Iconsax.close_circle,
                            size: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .error
                                .withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
