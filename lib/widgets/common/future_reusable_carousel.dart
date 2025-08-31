import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter/material.dart';
import 'package:dartotsu_extension_bridge/Models/Source.dart';

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
          return widget.errorWidget ??
              ReusableCarousel(
                data: const [],
                title: '${widget.title} (Error)',
                type: widget.type,
                variant: widget.variant,
                isLoading: false,
                source: widget.source,
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
