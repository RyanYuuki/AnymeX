import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';

class FutureReusableCarousel extends StatefulWidget {
  final Future<List<dynamic>> future;
  final String title;
  final DataVariant variant;
  final ItemType type;
  final Source? source;
  final Widget? errorWidget;
  final Widget? emptyWidget;

  const FutureReusableCarousel({
    super.key,
    required this.future,
    required this.title,
    this.variant = DataVariant.regular,
    this.type = ItemType.anime,
    this.source,
    this.errorWidget,
    this.emptyWidget,
  });

  @override
  State<FutureReusableCarousel> createState() => _FutureReusableCarouselState();
}

class _FutureReusableCarouselState extends State<FutureReusableCarousel> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: widget.future,
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ReusableCarousel(
            data: const [],
            title: widget.title,
            type: widget.type,
            variant: widget.variant,
            isLoading: true,
            source: widget.source,
          );
        }

        // Error state
        if (snapshot.hasError) {
          final theme = Theme.of(context);
          return widget.errorWidget ??
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.opaque(0.2, iReallyMeanIt: true),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.error.opaque(0.3, iReallyMeanIt: true),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: theme.colorScheme.error,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontFamily: 'Poppins-SemiBold',
                                fontSize: 14,
                                color: theme.colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${snapshot.error}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Poppins-Regular',
                                fontSize: 12,
                                color: theme.colorScheme.onSurface
                                    .opaque(0.7, iReallyMeanIt: true),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
        }

        // Success state
        final data = snapshot.data ?? [];

        // Empty state
        if (data.isEmpty) {
          return widget.emptyWidget ??
              ReusableCarousel(
                data: const [],
                title: '${widget.title} (No Data)',
                type: widget.type,
                variant: widget.variant,
                isLoading: false,
                source: widget.source,
              );
        }

        // Data loaded successfully
        return ReusableCarousel(
          data: data,
          title: widget.title,
          type: widget.type,
          variant: widget.variant,
          isLoading: false,
          source: widget.source,
        );
      },
    );
  }
}

// Convenience function to create FutureReusableCarousel
Widget buildFutureSection(
  String title,
  Future<List<dynamic>> future, {
  DataVariant variant = DataVariant.regular,
  ItemType type = ItemType.anime,
  Source? source,
  Widget? errorWidget,
  Widget? emptyWidget,
}) {
  return FutureReusableCarousel(
    future: future,
    title: title,
    variant: variant,
    type: type,
    source: source,
    errorWidget: errorWidget,
    emptyWidget: emptyWidget,
  );
}
