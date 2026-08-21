import 'package:flutter/material.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/utils/theme_extensions.dart';

class ImageButton extends StatelessWidget {
  final String buttonText;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final String backgroundImage;
  final double width;
  final double height;
  final double borderRadius;
  final TextStyle? textStyle;
  final double margin;

  const ImageButton({
    super.key,
    required this.buttonText,
    required this.onPressed,
    this.onLongPress,
    required this.backgroundImage,
    this.width = 160,
    this.height = 60,
    this.borderRadius = 18,
    this.textStyle,
    this.margin = 0,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = Theme.of(context).brightness == Brightness.dark
        ? [
            Colors.black.withOpacity(0.5),
            Colors.black.withOpacity(0.5),
          ]
        : [Colors.transparent, Colors.transparent];
    return Container(
      width: width,
      height: height,
      margin: EdgeInsets.symmetric(vertical: margin),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius.multiplyRadius()),
        border: Border.all(
          width: 1,
          color: context.colors.inverseSurface.withOpacity(0.3),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(borderRadius.multiplyRadius()),
              child: AnymeXImage(
                height: height,
                width: width,
                imageUrl: backgroundImage,
                fit: BoxFit.cover,
                radius: 0,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                onLongPress: onLongPress,
                borderRadius: BorderRadius.circular(borderRadius.multiplyRadius()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnymeXText(
                      buttonText.toUpperCase(),
                      style: textStyle ??
                          const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins-SemiBold',
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 3),
                    Container(
                      color: context.colors.primary,
                      height: 2,
                      width: 6 * buttonText.length.toDouble(),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
