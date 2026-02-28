import 'package:anymex/screens/novel/reader/controller/reader_controller.dart';
import 'package:anymex/screens/novel/reader/widgets/dictionary_popup.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
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

  void _handleSelection(BuildContext context, SelectionChangedEvent? selection) {
    if (selection != null) {
      final selectedText = selection.plainText;
      if (selectedText.isNotEmpty && selectedText.length < 50) { // Limit to reasonable word length
        final renderBox = context.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);
        
        showDialog(
          context: context,
          barrierColor: Colors.transparent,
          builder: (context) => Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(color: Colors.transparent),
                ),
              ),
              DictionaryPopup(
                selectedText: selectedText.trim(),
                tapPosition: position,
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (details) {
        HapticFeedback.lightImpact();
        if (controller.tapToScroll.value) {
          controller.handleTap(details.localPosition);
        } else {
          controller.toggleControls();
        }
      },
      onVerticalDragEnd: (details) {
        if (controller.swipeGestures.value) {
          controller.handleSwipe(details, false);
        }
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
            color: context.colors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading chapter...',
            style: TextStyle(
              color: context.colors.onSurface.opaque(0.7),
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
            color: context.colors.onSurface.opaque(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No content available',
            style: TextStyle(
              fontSize: 18,
              color: context.colors.onSurface.opaque(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Update progress on scroll
        if (notification is ScrollUpdateNotification) {
          // Progress is handled by controller's scroll listener
        }
        return false;
      },
      child: SelectionArea(
        onSelectionChanged: (selection) => _handleSelection(context, selection),
        child: CustomScrollView(
          controller: controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            Obx(() {
              return HtmlWidget(
                controller.novelContent.value,
                rebuildTriggers: [
                  controller.showControls.value,
                  controller.fontSize.value,
                  controller.lineHeight.value,
                  controller.letterSpacing.value,
                  controller.wordSpacing.value,
                  controller.paragraphSpacing.value,
                  controller.fontFamily.value,
                  controller.textAlign.value,
                  controller.removeExtraSpacing.value,
                  controller.bionicReading.value,
                ],
                renderMode: RenderMode.sliverList,
                textStyle: _getBaseTextStyle(context),
                customWidgetBuilder: (element) => _getCustomWidget(element, context),
                enableCaching: true,
                customStylesBuilder: (element) => _getCustomStyles(element, context),
                onLoadingBuilder: (context, element, loadingProgress) =>
                    const SizedBox.shrink(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget? _getCustomWidget(dom.Element element, BuildContext context) {
    if (element.localName?.toLowerCase() == 'img') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: AnymeXImage(
          imageUrl: element.attributes['src']!,
          fit: BoxFit.contain,
          radius: 8,
        ),
      );
    }
    return null;
  }

  TextStyle _getBaseTextStyle(BuildContext context) {
    return TextStyle(
      fontSize: controller.fontSize.value,
      height: controller.lineHeight.value,
      color: Theme.of(context).textTheme.bodyLarge?.color,
      fontFamily: controller.fontFamilyName.isEmpty ? null : controller.fontFamilyName,
      letterSpacing: controller.letterSpacing.value,
      wordSpacing: controller.wordSpacing.value,
    );
  }

  Map<String, String>? _getCustomStyles(dom.Element element, BuildContext context) {
    final Map<String, String> styles = {};

    switch (element.localName?.toLowerCase()) {
      case 'body':
        styles['margin'] = '0';
        styles['padding'] = '0';
        break;
        
      case 'p':
        styles['margin-bottom'] = '${controller.paragraphSpacing.value}px';
        styles['margin-top'] = '0';
        styles['margin-left'] = '0';
        styles['margin-right'] = '0';
        styles['padding'] = '0';
        styles['text-align'] = _getTextAlignmentString();
        break;
        
      case 'div':
        styles['margin-bottom'] = '${controller.paragraphSpacing.value / 2}px';
        styles['margin-top'] = '0';
        styles['padding'] = '0';
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
        styles['display'] = 'block';
        styles['content'] = '""';
        styles['margin'] = '${controller.paragraphSpacing.value / 4}px 0';
        break;
        
      case 'span':
        styles['margin'] = '0';
        styles['padding'] = '0';
        break;
        
      case 'ul':
      case 'ol':
        styles['margin-bottom'] = '${controller.paragraphSpacing.value}px';
        styles['padding-left'] = '24px';
        break;
        
      case 'li':
        styles['margin-bottom'] = '${controller.paragraphSpacing.value / 3}px';
        styles['text-align'] = _getTextAlignmentString();
        break;
        
      case 'blockquote':
        styles['margin'] = '${controller.paragraphSpacing.value}px 24px';
        styles['padding'] = '8px 16px';
        styles['border-left'] = '4px solid ${context.colors.primary.value.toRadixString(16)}';
        styles['background'] = context.colors.surfaceContainerHighest.opaque(0.3).value.toRadixString(16);
        styles['font-style'] = 'italic';
        break;
        
      case 'pre':
      case 'code':
        styles['margin'] = '${controller.paragraphSpacing.value}px 0';
        styles['padding'] = '16px';
        styles['background'] = context.colors.surfaceContainerHighest.opaque(0.5).value.toRadixString(16);
        styles['border-radius'] = '8px';
        styles['font-family'] = 'monospace';
        styles['overflow-x'] = 'auto';
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
