import 'dart:ui';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

class AnymeXHeader extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final bool disablePrefix;
  final bool enableSearch;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onSearchSubmitted;
  final VoidCallback? onSearchClear;
  final String searchHint;

  const AnymeXHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.disablePrefix = false,
    this.enableSearch = false,
    this.searchController,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.onSearchClear,
    this.searchHint = 'Search...',
  });

  @override
  State<AnymeXHeader> createState() => AnymeXHeaderState();
}

class AnymeXHeaderState extends State<AnymeXHeader> {
  bool _isSearching = false;

  bool get isSearching => _isSearching;

  bool onScrollNotification(ScrollNotification notification) {
    return false;
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        widget.searchController?.clear();
        widget.onSearchClear?.call();
      }
    });
  }

  Widget _buildPill(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(30.multiplyRadius());

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding:
              padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer.opaque(0.55),
            borderRadius: radius,
            border: Border.all(
              color:
                  theme.colorScheme.onSurface.opaque(0.08, iReallyMeanIt: true),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.opaque(0.08, iReallyMeanIt: true),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width > 600;
    final h = isDesktop ? 24.0 : 16.0;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(h, 8, h, 8),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child:
              _isSearching ? _buildSearchRow(context) : _buildSplitRow(context),
        ),
      ),
    );
  }

  Widget _buildSplitRow(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = !widget.disablePrefix &&
        (ModalRoute.of(context)?.canPop == true) &&
        !(ModalRoute.of(context)?.isFirst ?? true);

    final hasActions = widget.action != null || widget.enableSearch;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxHeaderWidth = screenWidth * 0.5;

    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.title,
        style: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins-Bold',
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    final isLongTitle = textPainter.size.width > maxHeaderWidth;

    return Row(
      key: const ValueKey('split'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildPill(
          context,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canPop) ...[
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.arrow_back_ios_rounded,
                    color: theme.colorScheme.onSurface,
                    size: 16,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest
                        .opaque(0.3, iReallyMeanIt: true),
                  ),
                ),
                SizedBox(
                    width: getResponsiveSize(context,
                        mobileSize: 4, desktopSize: 10)),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: maxHeaderWidth,
                      ),
                      child: AnymeXText(
                        text: widget.title,
                        variant: TextVariant.bold,
                        size: 16.0,
                        maxLines: 1,
                        isMarquee: isLongTitle,
                      ),
                    ),
                    if (widget.subtitle != null &&
                        widget.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      AnymeXText(
                        text: widget.subtitle!,
                        variant: TextVariant.regular,
                        size: 11,
                        color: theme.colorScheme.onSurface.opaque(0.6),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              6.width()
            ],
          ),
        ),
        const Spacer(),
        if (hasActions) ...[
          const SizedBox(width: 8),
          _buildPill(
            context,
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.enableSearch)
                  IconButton(
                    onPressed: _toggleSearch,
                    icon: Icon(
                      IconlyLight.search,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  )
                else if (widget.action != null)
                  widget.action!,
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchRow(BuildContext context) {
    final theme = Theme.of(context);

    return _buildPill(
      context,
      child: Row(
        key: const ValueKey('search'),
        children: [
          IconButton(
            onPressed: _toggleSearch,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: theme.colorScheme.primary,
              size: 18,
            ),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest
                  .opaque(0.4, iReallyMeanIt: true),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.searchController,
              onChanged: widget.onSearchChanged,
              onSubmitted: widget.onSearchSubmitted,
              autofocus: true,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.transparent,
                hintText: widget.searchHint,
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.opaque(0.45),
                  fontSize: 13.5,
                  fontFamily: 'Poppins',
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          if (widget.searchController != null &&
              widget.searchController!.text.isNotEmpty)
            IconButton(
              onPressed: () {
                widget.searchController?.clear();
                widget.onSearchChanged?.call('');
              },
              icon: Icon(
                Icons.cancel_rounded,
                color: theme.colorScheme.onSurface.opaque(0.4),
                size: 18,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }
}
