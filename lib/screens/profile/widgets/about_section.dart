import 'package:anymex/screens/profile/widgets/stats_overview_cards.dart';
import 'package:anymex/utils/al_about_me.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

class AboutSection extends StatelessWidget {
  final String aboutText;
  final bool needsPadding;
  final bool isDesktop;
  final bool isExpanded;
  final VoidCallback? onToggle;

  const AboutSection({
    super.key,
    required this.aboutText,
    this.needsPadding = true,
    this.isDesktop = false,
    this.isExpanded = true,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: needsPadding
              ? const EdgeInsets.symmetric(horizontal: 20.0)
              : EdgeInsets.zero,
          child: Row(
            children: [
              const Expanded(
                child: SectionHeader(title: 'About', icon: IconlyLight.profile),
              ),
              if (!isDesktop && onToggle != null)
                InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 24,
                        color: context.theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: needsPadding
              ? const EdgeInsets.symmetric(horizontal: 20.0)
              : EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    context.theme.colorScheme.outlineVariant.withOpacity(0.3),
              ),
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: (!isDesktop && !isExpanded)
                  ? SizedBox(
                      height: 160,
                      child: ClipRect(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: AnilistAboutMe(about: aboutText),
                        ),
                      ),
                    )
                  : AnilistAboutMe(about: aboutText),
            ),
          ),
        ),
      ],
    );
  }
}
