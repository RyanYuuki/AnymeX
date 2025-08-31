import 'package:flutter/material.dart';

class AnymexDropdown extends StatefulWidget {
  final List<DropdownItem> items;
  final DropdownItem? selectedItem;
  final Function(DropdownItem) onChanged;
  final String label;
  final IconData icon;
  final IconData? actionIcon;
  final VoidCallback? onActionPressed;

  const AnymexDropdown({
    super.key,
    required this.items,
    this.selectedItem,
    required this.onChanged,
    required this.label,
    required this.icon,
    this.actionIcon,
    this.onActionPressed,
  });

  @override
  State<AnymexDropdown> createState() => _AnymexDropdownState();
}

class _AnymexDropdownState extends State<AnymexDropdown>
    with TickerProviderStateMixin {
  bool _isOpen = false;
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

  void _openDropdown() {
    setState(() {
      _isOpen = true;
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
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 8,
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 8),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _expandAnimation,
              alignment: Alignment.topCenter,
              child: Material(
                elevation: 12,
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context).colorScheme.surface,
                shadowColor: Theme.of(context).shadowColor.withOpacity(0.15),
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
                          .withOpacity(0.15),
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
                            .withOpacity(0.1),
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
                                .withOpacity(0.1),
                            highlightColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.05),
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
                                        .withOpacity(0.08)
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  // Leading icon
                                  if (item.leadingIcon != null) ...[
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                            .withOpacity(0.3),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: item.leadingIcon!,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                  ],

                                  // Text content
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
                                              fontWeight: FontWeight.w400,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Extra widget (if any)
                                  if (item.extra != null) ...[
                                    const SizedBox(width: 8),
                                    item.extra!,
                                  ],

                                  // Trailing icon or check
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
                                        borderRadius: BorderRadius.circular(10),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: widget.items.isNotEmpty ? _toggleDropdown : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isOpen
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              width: _isOpen ? 2 : 1,
            ),
            boxShadow: _isOpen
                ? [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
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
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  RotationTransition(
                    turns: _rotateAnimation,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // Leading icon in main display
                        if (widget.selectedItem?.leadingIcon != null) ...[
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: widget.selectedItem!.leadingIcon!,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.selectedItem?.text ?? "No item selected",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: widget.selectedItem != null
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                ),
                              ),
                              if (widget.selectedItem?.subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  widget.selectedItem!.subtitle!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
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
                                  .withOpacity(0.8),
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
