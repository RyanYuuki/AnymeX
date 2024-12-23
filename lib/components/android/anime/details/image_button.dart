import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageButton extends StatelessWidget {
  final String buttonText;
  final VoidCallback onPressed;
  final String backgroundImage;
  final double width;
  final double height;
  final double borderRadius;
  final Color textColor;
  final TextStyle? textStyle;

  const ImageButton({
    super.key,
    required this.buttonText,
    required this.onPressed,
    required this.backgroundImage,
    this.width = 160,
    this.height = 60,
    this.borderRadius = 18,
    this.textColor = Colors.white,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            width: 1,
            color:
                Theme.of(context).colorScheme.inverseSurface.withOpacity(0.3)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
              child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: CachedNetworkImage(
              imageUrl: backgroundImage,
              fit: BoxFit.cover,
            ),
          )),
          Container(
            width: width,
            height: height,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.black.withOpacity(0.5),
                Colors.black.withOpacity(0.5),
              ]),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          // Elevated Button
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              fixedSize: Size(width, height),
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              elevation: 0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  buttonText,
                  style: textStyle ??
                      TextStyle(
                          color: textColor, fontFamily: 'Poppins-SemiBold'),
                ),
                const SizedBox(height: 3),
                Container(
                  color: Theme.of(context).colorScheme.primary,
                  height: 2,
                  width: 50,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
