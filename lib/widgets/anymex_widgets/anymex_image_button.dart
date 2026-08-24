import 'package:flutter/material.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/utils/theme_extensions.dart';

class ImageButton extends StatelessWidget {
  final String buttonText;
  final String? subText;
  final IconData? tagIcon;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final String backgroundImage;
  final double width;
  final double height;
  final double borderRadius;
  final TextStyle? textStyle;
  final double margin;
  final double imageProportion;

  const ImageButton({
    super.key,
    required this.buttonText,
    this.subText,
    this.tagIcon,
    required this.onPressed,
    this.onLongPress,
    required this.backgroundImage,
    this.width = 160,
    this.height = 60,
    this.borderRadius = 18,
    this.textStyle,
    this.margin = 0,
    this.imageProportion = 0.4,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final backgroundColor = theme.brightness == Brightness.dark
        ? colors.primaryContainer.withOpacity(0.2)
        : colors.surfaceContainerLowest;

    final icon = tagIcon ?? Icons.auto_awesome;
    final hasSubText = subText != null && subText!.isNotEmpty;
    final radius = borderRadius.multiplyRadius();

    return Container(
      width: width,
      height: height,
      margin: EdgeInsets.symmetric(vertical: margin),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.opaque(0.06, iReallyMeanIt: true),
            blurRadius: 8,
            spreadRadius: -2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(
              width: 0.8,
              color: colors.onSurface.opaque(0.08, iReallyMeanIt: true),
            ),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final actualWidth = constraints.maxWidth;
              return GestureDetector(
                onTap: onPressed,
                onLongPress: onLongPress,
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 0,
                      width: actualWidth * imageProportion,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onPressed,
                          onLongPress: onLongPress,
                          splashColor: colors.onSurface
                              .opaque(0.08, iReallyMeanIt: true),
                          highlightColor: colors.onSurface
                              .opaque(0.05, iReallyMeanIt: true),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                right: 1,
                                top: 1,
                                bottom: 1,
                                left: 0,
                                child: AnymeXImage(
                                  imageUrl: backgroundImage,
                                  fit: BoxFit.cover,
                                  borderRadius: BorderRadius.horizontal(
                                      left: const Radius.circular(0),
                                      right: Radius.circular(radius)),
                                ),
                              ),
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        backgroundColor,
                                        backgroundColor.withOpacity(0.6),
                                        backgroundColor.withOpacity(0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      top: 8,
                      bottom: 8,
                      right: actualWidth * (imageProportion - 0.05) + 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasSubText) ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  icon,
                                  size: 10,
                                  color: colors.onSurface.withOpacity(0.55),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: AnymeXText(
                                    subText!,
                                    size: 9.5,
                                    variant: TextVariant.semiBold,
                                    color: colors.onSurface.withOpacity(0.55),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    autoResize: true,
                                    minFontSize: 7,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 10,
                                  color: colors.onSurface.withOpacity(0.35),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                          ],
                          Flexible(
                            child: AnymeXText(
                              buttonText,
                              size: hasSubText ? 13.5 : 14.5,
                              variant: TextVariant.bold,
                              color: colors.onSurface,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              autoResize: true,
                              minFontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
