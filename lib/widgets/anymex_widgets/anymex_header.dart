import 'dart:ui';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
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
  bool _isScrollVisible = true;

  bool onScrollNotification(ScrollNotification notification) {
    if (_isSearching) return false;
    if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;
      if (metrics.axis == Axis.vertical) {
        final delta = notification.scrollDelta ?? 0;
        if (metrics.pixels <= 10) {
          if (!_isScrollVisible) {
            setState(() => _isScrollVisible = true);
          }
        } else if (delta > 3 && metrics.pixels > 25) {
          if (_isScrollVisible) {
            setState(() => _isScrollVisible = false);
          }
        } else if (delta < -3) {
          if (!_isScrollVisible) {
            setState(() => _isScrollVisible = true);
          }
        }
      }
    }
    return false;
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        _isScrollVisible = true;
      } else {
        widget.searchController?.clear();
        if (widget.onSearchClear != null) {
          widget.onSearchClear!();
        }
      }
    });
  }

  Widget _buildFloatingBox(
    BuildContext context, {
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(24.multiplyRadius());

    return Container(
      key: key,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: theme.colorScheme.onSurface.opaque(0.08, iReallyMeanIt: true),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.opaque(0.08, iReallyMeanIt: true),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: theme.colorScheme.primary.opaque(0.03, iReallyMeanIt: true),
            blurRadius: 30,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer.opaque(0.55),
              borderRadius: borderRadius,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = !widget.disablePrefix &&
        (ModalRoute.of(context)?.canPop == true) &&
        !(ModalRoute.of(context)?.isFirst ?? true);

    final isVisible = _isScrollVisible || _isSearching;

    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      child: isVisible
          ? DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _isSearching
                        ? _buildExpandedSearchHeader(context, theme)
                        : _buildStandardHeader(context, theme, canPop),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildStandardHeader(
    BuildContext context,
    ThemeData theme,
    bool canPop,
  ) {
    return Row(
      key: const ValueKey('standard_header'),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              _buildFloatingBox(
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
                          backgroundColor: theme
                              .colorScheme.surfaceContainerHighest
                              .opaque(0.3, iReallyMeanIt: true),
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(30, 30),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnymeXText(
                          text: widget.title,
                          variant: TextVariant.bold,
                          size: 16.5,
                        ),
                        if (widget.subtitle != null &&
                            widget.subtitle!.isNotEmpty)
                          AnymeXText(
                            text: widget.subtitle!,
                            variant: TextVariant.regular,
                            size: 11,
                            color: theme.colorScheme.onSurface.opaque(0.6),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (widget.enableSearch) ...[
          const SizedBox(width: 10),
          _buildFloatingBox(
            context,
            padding: const EdgeInsets.all(4),
            child: IconButton(
              onPressed: _toggleSearch,
              icon: Icon(
                IconlyLight.search,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(8),
                minimumSize: const Size(36, 36),
              ),
            ),
          ),
        ] else if (widget.action != null) ...[
          const SizedBox(width: 10),
          _buildFloatingBox(
            context,
            child: widget.action!,
          ),
        ],
      ],
    );
  }

  Widget _buildExpandedSearchHeader(BuildContext context, ThemeData theme) {
    return _buildFloatingBox(
      context,
      key: const ValueKey('search_header'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
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
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(34, 34),
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
                if (widget.onSearchChanged != null) {
                  widget.onSearchChanged!('');
                }
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
