import 'package:anymex/controllers/services/underrated_service.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/widgets/non_widgets/recommend_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RecommendIconButton extends StatelessWidget {
  final Media media;
  final ItemType mediaItemType;

  final Widget Function(VoidCallback onTap, Widget child)? buttonBuilder;

  const RecommendIconButton({
    super.key,
    required this.media,
    required this.mediaItemType,
    this.buttonBuilder,
  });

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: RecommendSheet(
          media: media,
          mediaItemType: mediaItemType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!UnderratedService.votingEnabled) return const SizedBox.shrink();

    final sh = Get.find<ServiceHandler>();
    if (!sh.isLoggedIn.value) return const SizedBox.shrink();

    final icon = Icon(
      Icons.recommend_rounded,
      size: 20,
      color: Theme.of(context).colorScheme.onSurface,
    );

    if (buttonBuilder != null) {
      return buttonBuilder!(() => _openSheet(context), icon);
    }

    return IconButton(
      onPressed: () => _openSheet(context),
      icon: icon,
      tooltip: 'Recommend',
    );
  }
}
