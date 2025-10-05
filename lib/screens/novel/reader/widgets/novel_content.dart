import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/novel/reader/controller/reader_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get/get.dart';
import 'package:html/dom.dart' as dom;

class NovelContentWidget extends StatelessWidget {
  final NovelReaderController controller;

  const NovelContentWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        controller.toggleControls();
      },
      child: Container(
        color: Colors.transparent,
        child: SafeArea(
          child: Obx(() {
            if (controller.loadingState.value == LoadingState.loading) {
              return _buildLoadingState(context);
            }

            if (controller.loadingState.value == LoadingState.error ||
                controller.novelContent.value.isEmpty) {
              return _buildEmptyState(context);
            }

            return _buildContent(context);
          }),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ExpressiveLoadingIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading chapter...',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No content available',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return CustomScrollView(controller: controller.scrollController, slivers: [
      Obx(() {
        return HtmlWidget(
          controller.novelContent.value,
          rebuildTriggers: [controller.showControls.value],
          renderMode: RenderMode.sliverList,
          textStyle: _getBaseTextStyle(context),
          customWidgetBuilder: (element) => _getCustomWidget(element, context),
          enableCaching: true,
          customStylesBuilder: (element) => _getCustomStyles(element, context),
        );
      }),
    ]);
  }

  Widget? _getCustomWidget(dom.Element element, BuildContext context) {
    if (element.localName?.toLowerCase() == 'img') {
      return CachedNetworkImage(
          imageUrl: element.attributes['src']!, fit: BoxFit.contain);
    }
    return null;
  }

  TextStyle _getBaseTextStyle(BuildContext context) {
    return TextStyle(
      fontSize: controller.fontSize.value,
      height: controller.lineHeight.value,
      color: Theme.of(context).textTheme.bodyLarge?.color,
      fontFamily:
          controller.fontFamilyName.isEmpty ? null : controller.fontFamilyName,
      letterSpacing: controller.letterSpacing.value,
      wordSpacing: controller.wordSpacing.value,
    );
  }

  Map<String, String>? _getCustomStyles(
      dom.Element element, BuildContext context) {
    final Map<String, String> styles = {};

    switch (element.localName?.toLowerCase()) {
      case 'body':
        styles['margin'] = '0';
        styles['padding'] = '0';
        break;
      case 'p':
        styles['margin-bottom'] = '${controller.paragraphSpacing.value}px';
        styles['text-align'] = _getTextAlignmentString();
        break;
      case 'div':
        styles['margin-bottom'] = '${controller.paragraphSpacing.value / 2}px';
        styles['text-align'] = _getTextAlignmentString();
        break;
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        styles['margin-top'] = '${controller.paragraphSpacing.value * 1.5}px';
        styles['margin-bottom'] = '${controller.paragraphSpacing.value}px';
        styles['font-weight'] = 'bold';
        styles['text-align'] = _getTextAlignmentString();
        break;
      case 'br':
        styles['margin-bottom'] = '8px';
        break;
      case 'span':
        styles['margin'] = '0';
        styles['padding'] = '0';
        break;
    }

    return styles.isNotEmpty ? styles : null;
  }

  String _getTextAlignmentString() {
    switch (controller.textAlignment) {
      case TextAlign.left:
        return 'left';
      case TextAlign.right:
        return 'right';
      case TextAlign.center:
        return 'center';
      case TextAlign.justify:
        return 'justify';
      default:
        return 'left';
    }
  }
}
