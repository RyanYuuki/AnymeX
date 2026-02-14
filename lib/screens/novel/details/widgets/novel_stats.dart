// ignore_for_file: prefer_const_constructors
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/home_page.dart';
import 'package:anymex/utils/fallback/fallback_anime.dart';
import 'package:anymex/utils/fallback/fallback_manga.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter_html/flutter_html.dart';

class NovelStats extends StatelessWidget {
  final Media data;
  const NovelStats({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final covers = [...trendingAnimes, ...trendingMangas]
        .where((e) => e.cover != null && (e.cover?.isNotEmpty ?? false))
        .toList();
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final colorScheme = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CollapsibleBox(
          colorScheme: colorScheme,
          isInitiallyExpanded: true,
          header: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.opaque(0.15, iReallyMeanIt: true),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  size: 24,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              const AnymexText(
                text: "Statistics",
                variant: TextVariant.bold,
                size: 20,
              ),
            ],
          ),
          content: Column(
            children: [
              StateItem(label: "Type", value: 'NOVEL'),
              StateItem(label: "Status", value: data.status),
              StateItem(
                  label: "Total Chapters", value: data.totalChapters ?? '??'),
            ],
          ),
          padding: const EdgeInsets.all(24),
        ),
        const SizedBox(height: 16),
        _CollapsibleBox(
          colorScheme: colorScheme,
          isInitiallyExpanded: true,
          header: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.opaque(0.15, iReallyMeanIt: true),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.description_outlined,
                  size: 18,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              const AnymexText(
                text: "Synopsis",
                variant: TextVariant.bold,
                size: 16,
              ),
            ],
          ),
          content: Html(
              data: data.description,
              style: {
                "body": Style(
                  fontSize: FontSize(14.0),
                  color:
                      context.colors.onSurface.opaque(0.9),
                ),
                "b": Style(fontWeight: FontWeight.bold),
                "i": Style(fontStyle: FontStyle.italic),
              },
            ),
        ),
        const SizedBox(height: 16),
        const AnymexText(
          text: "Genres",
          variant: TextVariant.bold,
          size: 17,
        ),
        GridView.builder(
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.only(top: 15),
          shrinkWrap: true,
          itemCount: data.genres.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              childAspectRatio: 1,
              crossAxisCount: getResponsiveCrossAxisCount(context,
                  baseColumns: 2, maxColumns: 4),
              mainAxisSpacing: 10,
              mainAxisExtent: isDesktop ? 80 : 60,
              crossAxisSpacing: 10),
          itemBuilder: (context, index) {
            final e = data.genres[index];
            return ImageButton(
                buttonText: e,
                height: 80,
                width: 1000,
                onPressed: () {},
                backgroundImage: covers[index].cover!);
          },
        ),
      ],
    );
  }
}

class StateItem extends StatelessWidget {
  final String label;
  final String value;
  const StateItem({
    super.key,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AnymexText(
          text: label,
          variant: TextVariant.semiBold,
          color: context.colors.onSurface.opaque(0.9),
        ),
        Expanded(
          child: AnymexText(
            text: value,
            variant: TextVariant.semiBold,
            color: context.colors.primary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class AdaptationInfoColumn extends StatelessWidget {
  final String input;

  const AdaptationInfoColumn({super.key, required this.input});

  @override
  Widget build(BuildContext context) {
    List<String> chapters = input
        .replaceAllMapped(RegExp(r'\s*/\s*'), (match) => ' / ')
        .split(' / ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: chapters
          .map((chapter) => Text(
                chapter,
                style: TextStyle(color: context.colors.primary),
              ))
          .toList(),
    );
  }
}

class _CollapsibleBox extends StatefulWidget {
  final Widget header;
  final Widget content;
  final bool isInitiallyExpanded;
  final ColorScheme colorScheme;
  final EdgeInsetsGeometry padding;

  const _CollapsibleBox({
    required this.header,
    required this.content,
    required this.colorScheme,
    this.isInitiallyExpanded = false,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  State<_CollapsibleBox> createState() => _CollapsibleBoxState();
}

class _CollapsibleBoxState extends State<_CollapsibleBox> with SingleTickerProviderStateMixin {
  late bool isExpanded;
  late AnimationController _controller;
  late Animation<double> _iconTurns;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.isInitiallyExpanded;
    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _iconTurns = Tween<double>(begin: 0.0, end: 0.5).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    if (isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      isExpanded = !isExpanded;
      if (isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.colorScheme.surfaceContainerHighest.opaque(0.35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.colorScheme.outline.opaque(0.15, iReallyMeanIt: true),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: widget.header),
                RotationTransition(
                  turns: _iconTurns,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: widget.colorScheme.primary,
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Column(
                children: [
                  const SizedBox(height: 20),
                  widget.content,
                ],
              ),
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
              sizeCurve: Curves.easeInOut,
            ),
          ],
        ),
      ),
    );
  }
}
