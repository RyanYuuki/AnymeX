import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

class AnymexDropdown extends StatefulWidget {
  final List<DropdownItem> items;
  final DropdownItem? selectedItem;
  final Function(DropdownItem) onChanged;
  final String label;
  final IconData icon;
  final IconData? actionIcon;
  final VoidCallback? onActionPressed;
  final bool compact;

  const AnymexDropdown({
    super.key,
    required this.items,
    this.selectedItem,
    required this.onChanged,
    required this.label,
    required this.icon,
    this.actionIcon,
    this.onActionPressed,
    this.compact = false,
  });

  @override
  State<AnymexDropdown> createState() => _AnymexDropdownState();
}

class _AnymexDropdownState extends State<AnymexDropdown>
    with TickerProviderStateMixin {
  bool _isOpen = false;
  bool _openUpwards = false;
  late AnimationController _animationController;
  late AnimationController _fadeController;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotateAnimation;

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fadeController.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  bool _shouldOpenUpwards() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    final double screenHeight = MediaQuery.of(context).size.height;

    const double dropdownMaxHeight = 320;
    const double spacing = 8;

    final double spaceBelow = screenHeight - (offset.dy + size.height);
    final double spaceAbove = offset.dy;

    if (spaceBelow >= dropdownMaxHeight + spacing) {
      return false;
    }

    if (spaceAbove > spaceBelow) {
      return true;
    }

    return false;
  }

  void _openDropdown() {
    setState(() {
      _isOpen = true;
      _openUpwards = _shouldOpenUpwards();
    });

    _animationController.forward();
    _fadeController.forward();

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeDropdown() {
    setState(() {
      _isOpen = false;
    });

    _animationController.reverse();
    _fadeController.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeDropdown,
        child: Stack(
          children: [
            Positioned(
              left: offset.dx,
              top: _openUpwards ? null : offset.dy + size.height + 8,
              bottom: _openUpwards
                  ? MediaQuery.of(context).size.height - offset.dy + 8
                  : null,
              width: size.width,
              child: GestureDetector(
                onTap: () {},
                child: CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  offset: Offset(0.0,
                      (_openUpwards ? -(320 + 8) : size.height + 8).toDouble()),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _expandAnimation,
                      alignment: _openUpwards
                          ? Alignment.bottomCenter
                          : Alignment.topCenter,
                      child: Material(
                        elevation: 12,
                        borderRadius: BorderRadius.circular(20),
                        color: context.colors.surface,
                        shadowColor: Theme.of(context)
                            .shadowColor
                            .opaque(0.15, iReallyMeanIt: true),
                        child: Container(
                          constraints: const BoxConstraints(
                            maxHeight: 320,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .opaque(0.15, iReallyMeanIt: true),
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: widget.items.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                thickness: 0.5,
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .opaque(0.1, iReallyMeanIt: true),
                                indent: 16,
                                endIndent: 16,
                              ),
                              itemBuilder: (context, index) {
                                final item = widget.items[index];
                                final isSelected =
                                    widget.selectedItem?.value == item.value;

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      widget.onChanged(item);
                                      _closeDropdown();
                                    },
                                    splashColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .opaque(0.1, iReallyMeanIt: true),
                                    highlightColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .opaque(0.05, iReallyMeanIt: true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .opaque(0.08,
                                                    iReallyMeanIt: true)
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          if (item.leadingIcon != null) ...[
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primaryContainer
                                                    .opaque(0.3,
                                                        iReallyMeanIt: true),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: item.leadingIcon!,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                          ],
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.text,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.w500,
                                                    color: isSelected
                                                        ? Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                        : Theme.of(context)
                                                            .colorScheme
                                                            .onSurface,
                                                  ),
                                                ),
                                                if (item.subtitle != null) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    item.subtitle!,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface
                                                          .opaque(0.6,
                                                              iReallyMeanIt:
                                                                  true),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          if (item.extra != null) ...[
                                            const SizedBox(width: 8),
                                            item.extra!,
                                          ],
                                          if (item.trailingIcon != null) ...[
                                            const SizedBox(width: 8),
                                            item.trailingIcon!,
                                          ] else if (isSelected) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Icon(
                                                Icons.check,
                                                size: 14,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double paddingSize = widget.compact ? 10 : 20;
    final double borderRadius = widget.compact ? 12 : 16;
    final double labelSize = widget.compact ? 10 : 13;
    final double titleSize = widget.compact ? 13 : 16;
    final double iconSize = widget.compact ? 16 : 20;
    final double arrowSize = widget.compact ? 18 : 24;
    final double verticalGap = widget.compact ? 6 : 12;
    final double leadingSize = widget.compact ? 20 : 24;
    final double leadingRadius = widget.compact ? 5 : 6;

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: widget.items.isNotEmpty ? _toggleDropdown : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(paddingSize),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer.opaque(0.3),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: _isOpen
                  ? context.colors.primary
                  : context.colors.outline.opaque(0.3, iReallyMeanIt: true),
              width: _isOpen ? 2 : 1,
            ),
            boxShadow: _isOpen
                ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.opaque(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    widget.icon,
                    size: iconSize,
                    color: context.colors.primary,
                  ),
                  SizedBox(width: widget.compact ? 8 : 12),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: labelSize,
                      fontWeight: FontWeight.w600,
                      color: context.colors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  RotationTransition(
                    turns: _rotateAnimation,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: context.colors.primary,
                      size: arrowSize,
                    ),
                  ),
                ],
              ),
              SizedBox(height: verticalGap),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (widget.selectedItem?.leadingIcon != null) ...[
                          Container(
                            width: leadingSize,
                            height: leadingSize,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(leadingRadius),
                            ),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(leadingRadius),
                              child: widget.selectedItem!.leadingIcon!,
                            ),
                          ),
                          SizedBox(width: widget.compact ? 8 : 10),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.selectedItem?.text ?? "No item selected",
                                style: TextStyle(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w500,
                                  color: widget.selectedItem != null
                                      ? context.colors.onSurface
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .opaque(0.6, iReallyMeanIt: true),
                                ),
                              ),
                              if (widget.selectedItem?.subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  widget.selectedItem!.subtitle!,
                                  style: TextStyle(
                                    fontSize: widget.compact ? 11 : 12,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .opaque(0.6, iReallyMeanIt: true),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (widget.selectedItem?.extra != null) ...[
                          const SizedBox(width: 8),
                          widget.selectedItem!.extra!,
                        ],
                      ],
                    ),
                  ),
                  if (widget.actionIcon != null &&
                      widget.onActionPressed != null &&
                      widget.selectedItem != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: widget.onActionPressed,
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Icon(
                              widget.actionIcon,
                              size: 20,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .opaque(0.8, iReallyMeanIt: true),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DropdownItem {
  final String value;
  final String text;
  final String? subtitle;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final Widget? extra;

  const DropdownItem({
    required this.value,
    required this.text,
    this.subtitle,
    this.leadingIcon,
    this.trailingIcon,
    this.extra,
  });
}
