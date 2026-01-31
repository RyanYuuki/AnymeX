import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';

class CustomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const CustomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSimkl = Get.find<ServiceHandler>().serviceType.value.isSimkl;
    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Blur(
                  blurColor: Colors.transparent,
                  child: Container(),
                )),
          ),
          Container(
            height: 60,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: context.theme.colorScheme.secondaryContainer
                  .withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: context.theme.colorScheme.outline.withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final inactiveWidth = constraints.maxWidth / 6;
                final activeWidth = 2.4 * inactiveWidth;
                final icons = [
                  IconlyBold.home,
                  Icons.movie_filter_rounded,
                  isSimkl ? Iconsax.monitor5 : Iconsax.book,
                  HugeIcons.strokeRoundedLibrary,
                ];
                final labels = [
                  'Home',
                  isSimkl ? "Movies" : 'Anime',
                  !isSimkl ? 'Manga' : 'Series',
                  'Library'
                ];
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    4,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      width:
                          selectedIndex == index ? activeWidth : inactiveWidth,
                      child: _NavItem(
                        label: labels[index],
                        icon: icons[index],
                        isActive: selectedIndex == index,
                        onTap: () => onTap(index),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.label,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.isActive) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: widget.isActive
              ? context.theme.colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Icon(
                    widget.icon,
                    size: 20,
                    color: widget.isActive
                        ? context.theme.colorScheme.onPrimary
                        : context.theme.colorScheme.onSurface.opaque(0.5),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: widget.isActive
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 4),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: AnymexText(
                                text: widget.label,
                                size: 14,
                                variant: TextVariant.bold,
                                color: context.theme.colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
