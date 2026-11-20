import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class SliverSlideFadeTransition extends SingleChildRenderObjectWidget {
  const SliverSlideFadeTransition({
    super.key,
    required this.opacity,
    required this.position,
    Widget? sliver,
  }) : super(child: sliver);

  final Animation<double> opacity;
  final Animation<Offset> position;

  @override
  RenderSliverSlideFadeTransition createRenderObject(BuildContext context) {
    return RenderSliverSlideFadeTransition(
      opacity: opacity,
      position: position,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSliverSlideFadeTransition renderObject,
  ) {
    renderObject
      ..opacity = opacity
      ..position = position;
  }
}

class RenderSliverSlideFadeTransition extends RenderProxySliver {
  RenderSliverSlideFadeTransition({
    required Animation<double> opacity,
    required Animation<Offset> position,
    RenderSliver? sliver,
  })  : _opacity = opacity,
        _position = position {
    child = sliver;
  }

  Animation<double> get opacity => _opacity;
  Animation<double> _opacity;
  set opacity(Animation<double> value) {
    if (_opacity == value) return;
    if (attached) _opacity.removeListener(markNeedsPaint);
    _opacity = value;
    if (attached) _opacity.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  Animation<Offset> get position => _position;
  Animation<Offset> _position;
  set position(Animation<Offset> value) {
    if (_position == value) return;
    if (attached) _position.removeListener(markNeedsPaint);
    _position = value;
    if (attached) _position.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _opacity.addListener(markNeedsPaint);
    _position.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _opacity.removeListener(markNeedsPaint);
    _position.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;
    final alpha = (opacity.value.clamp(0.0, 1.0) * 255).round();
    if (alpha == 0) return;
    final dx = position.value.dx * constraints.crossAxisExtent;
    final dy = position.value.dy * (geometry?.scrollExtent ?? 0.0);

    if (alpha >= 255 && dx == 0.0 && dy == 0.0) {
      context.paintChild(child!, offset);
      return;
    }

    void painter(PaintingContext innerContext, Offset innerOffset) {
      if (dx == 0.0 && dy == 0.0) {
        innerContext.paintChild(child!, innerOffset);
      } else {
        final transform = Matrix4.translationValues(dx, dy, 0.0);
        innerContext.pushTransform(
          needsCompositing,
          innerOffset,
          transform,
          (PaintingContext transformContext, Offset transformOffset) {
            transformContext.paintChild(child!, transformOffset);
          },
        );
      }
    }

    if (alpha < 255) {
      context.pushOpacity(offset, alpha, painter);
    } else {
      painter(context, offset);
    }
  }

  @override
  bool hitTestChildren(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    if (child == null) return false;
    final alpha = (opacity.value.clamp(0.0, 1.0) * 255).round();
    if (alpha == 0) return false;
    final dx = position.value.dx * constraints.crossAxisExtent;
    final dy = position.value.dy * (geometry?.scrollExtent ?? 0.0);
    return child!.hitTest(
      result,
      mainAxisPosition: mainAxisPosition - dy,
      crossAxisPosition: crossAxisPosition - dx,
    );
  }
}
