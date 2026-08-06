import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/widgets/comments/controller/comments_controller.dart';
import 'package:get/get.dart';

class CommentPreloader extends GetxService {
  static CommentPreloader get to => Get.find();

  final RxMap<String, CommentSectionController> _preloadedControllers =
      <String, CommentSectionController>{}.obs;

  Future<void> preloadComments(Media media) async {
    if (media.uniqueId.isEmpty ||
        _preloadedControllers.containsKey((media.uniqueId))) {
      return;
    }

    print('Preloading comments for media: ${media.uniqueId}');

    try {
      final controller = Get.put(
        CommentSectionController(media: media),
        tag: media.uniqueId,
        permanent: false,
      );

      _preloadedControllers[media.uniqueId] = controller;

      controller.loadComments();

      print('Started preloading comments for media: ${media.uniqueId}');
    } catch (e) {
      print('Error preloading comments for media ${media.uniqueId}: $e');
    }
  }

  CommentSectionController? getPreloadedController(String mediaId) {
    return _preloadedControllers[mediaId];
  }

  void removePreloadedController(String mediaId) {
    _preloadedControllers.remove(mediaId);

    try {
      Get.delete<CommentSectionController>(tag: mediaId);
      print('Removed preloaded controller for media: $mediaId');
    } catch (e) {
      print('Error removing controller for media $mediaId: $e');
    }
  }

  void clearAll() {
    for (final controller in _preloadedControllers.values) {
      controller.onClose();
    }
    _preloadedControllers.clear();
    print('Cleared all preloaded comment controllers');
  }

  bool isPreloaded(String mediaId) {
    return _preloadedControllers.containsKey(mediaId);
  }

  List<String> get preloadedMediaIds => _preloadedControllers.keys.toList();
}
