import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/widgets/header.dart';
import 'package:flutter/material.dart';

class GradientPoster extends StatelessWidget {
  const GradientPoster({
    super.key,
    required this.tag,
    required this.data,
    required this.posterUrl,
  });

  final Media? data;
  final String posterUrl;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: isDesktop ? 460 : 400,
          child: NetworkSizedImage(
            alignment: Alignment.topCenter,
            imageUrl: data?.cover ?? posterUrl,
            radius: 0,
            height: 300,
            width: double.infinity,
          ),
        ),
        Container(
          height: isDesktop ? 460 : 400,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withOpacity(0.5),
                Theme.of(context).colorScheme.surfaceContainer,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20.0, bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Hero(
                tag: tag,
                child: NetworkSizedImage(
                    imageUrl: posterUrl,
                    radius: 16.multiplyRoundness(),
                    width: isDesktop ? 120 : 90,
                    height: isDesktop ? 170 : 120),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 2,
                    child: Text(data?.title ?? 'Loading...',
                        style: const TextStyle(
                            fontFamily: "Poppins-Bold", fontSize: 16)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Text(data?.status ?? "Ongoing? Idk",
                        style: TextStyle(
                            fontFamily: "Poppins-Bold",
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary)),
                  )
                ],
              )
            ],
          ),
        ),
      ],
    );
  }
}
