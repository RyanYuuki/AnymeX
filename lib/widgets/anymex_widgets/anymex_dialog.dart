import 'dart:async';
import 'dart:ui';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:get/get.dart';

class AnymeXDialog extends StatefulWidget {
  final String? title;
  final String? message;
  final Widget? contentWidget;
  final VoidCallback onConfirm;
  final bool enableV2;
  final EdgeInsets padding;
  final bool showCancelButton;
  final String confirmText;
  final bool translucent;
  final dynamic Function()? confirmResultGetter;
  final bool forceAction;
  final bool isConfirmEnabled;
  final VoidCallback? onCancel;
  final dynamic Function()? cancelResultGetter;
  final String cancelText;
  final bool autoDismiss;
  final double? width;

  const AnymeXDialog({
    super.key,
    this.title,
    this.message,
    this.contentWidget,
    required this.onConfirm,
    this.enableV2 = false,
    this.padding = const EdgeInsets.all(24),
    this.showCancelButton = true,
    this.confirmText = 'Confirm',
    this.translucent = true,
    this.confirmResultGetter,
    this.forceAction = false,
    this.isConfirmEnabled = true,
    this.onCancel,
    this.cancelResultGetter,
    this.cancelText = 'Cancel',
    this.autoDismiss = true,
    this.width,
  });

  Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: !forceAction,
      builder: (context) => AnymeXDialog(
        title: title,
        message: message,
        contentWidget: contentWidget,
        onConfirm: onConfirm,
        enableV2: enableV2,
        translucent: translucent,
        showCancelButton: showCancelButton,
        confirmText: confirmText,
        forceAction: forceAction,
        isConfirmEnabled: isConfirmEnabled,
        padding: padding,
        onCancel: onCancel,
        cancelText: cancelText,
        confirmResultGetter: confirmResultGetter,
        cancelResultGetter: cancelResultGetter,
        autoDismiss: autoDismiss,
        width: width,
      ),
    );
  }

  @override
  State<AnymeXDialog> createState() => _AnymeXDialogState();
}

class _AnymeXDialogState extends State<AnymeXDialog> {
  Animation<double>? _routeAnimation;
  bool _isRouteAnimating = false;
  bool _isLayoutMoving = false;
  double? _lastBottomInset;
  Size? _lastScreenSize;
  Timer? _layoutSettleTimer;

  bool get _isMoving => _isRouteAnimating || _isLayoutMoving;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final routeAnim = ModalRoute.of(context)?.animation;
    if (routeAnim != _routeAnimation) {
      _routeAnimation?.removeStatusListener(_onRouteStatusChanged);
      _routeAnimation = routeAnim;
      if (routeAnim != null) {
        _isRouteAnimating =
            routeAnim.status == AnimationStatus.forward ||
            routeAnim.status == AnimationStatus.reverse;
        routeAnim.addStatusListener(_onRouteStatusChanged);
      } else {
        _isRouteAnimating = false;
      }
    }

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenSize = MediaQuery.sizeOf(context);
    if ((_lastBottomInset != null && _lastBottomInset != bottomInset) ||
        (_lastScreenSize != null && _lastScreenSize != screenSize)) {
      _markLayoutMoving();
    }
    _lastBottomInset = bottomInset;
    _lastScreenSize = screenSize;
  }

  void _onRouteStatusChanged(AnimationStatus status) {
    final animating =
        status == AnimationStatus.forward || status == AnimationStatus.reverse;
    if (animating != _isRouteAnimating && mounted) {
      setState(() => _isRouteAnimating = animating);
    }
  }

  void _markLayoutMoving() {
    _layoutSettleTimer?.cancel();
    if (!_isLayoutMoving && mounted) {
      setState(() => _isLayoutMoving = true);
    }
    _layoutSettleTimer = Timer(const Duration(milliseconds: 180), () {
      if (mounted && _isLayoutMoving) {
        setState(() => _isLayoutMoving = false);
      }
    });
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteStatusChanged);
    _layoutSettleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = 50.multiplyRadius();
    final buttonRadius = 30.multiplyRadius();
    final enableBlur = widget.translucent && !_isMoving;

    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final dialogBody = Padding(
      padding: widget.padding == const EdgeInsets.all(24)
          ? (isLandscape
              ? const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
              : widget.padding)
          : widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.title != null) ...[
            AnymeXText(
              widget.title!,
              size: 20,
              variant: TextVariant.semiBold,
              color: context.colors.onSurface,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: widget.message != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: AnymeXText(
                        widget.message!,
                        size: 14,
                        color: context.colors.onSurfaceVariant,
                        textAlign: TextAlign.center,
                        maxLines: 100,
                      ),
                    )
                  : (widget.contentWidget ?? const SizedBox.shrink()),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (widget.showCancelButton) ...[
                Expanded(
                  child: AnymexOnTap(
                    onTap: () {
                      final result = widget.cancelResultGetter?.call();
                      Get.back(result: result);
                      widget.onCancel?.call();
                    },
                    scale: 0.95,
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.horizontal(
                          right: const Radius.circular(2),
                          left: Radius.circular(buttonRadius),
                        ),
                        border: Border.all(
                          color: context.colors.onSurface.withOpacity(0.04),
                          width: 1,
                        ),
                      ),
                      child: AnymeXText(
                        widget.cancelText,
                        size: 14,
                        color: context.colors.onSurface,
                        variant: TextVariant.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: AnymexOnTap(
                  onTap: widget.isConfirmEnabled
                      ? () {
                          if (widget.autoDismiss) {
                            final result = widget.confirmResultGetter?.call();
                            Get.back(result: result);
                          }
                          widget.onConfirm.call();
                        }
                      : () {},
                  scale: 0.95,
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.isConfirmEnabled
                          ? context.colors.primary
                          : context.colors.surfaceContainerHighest
                              .withOpacity(0.4),
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(
                            widget.showCancelButton ? 2 : buttonRadius),
                        right: Radius.circular(buttonRadius),
                      ),
                      boxShadow: widget.isConfirmEnabled
                          ? [
                              BoxShadow(
                                color:
                                    context.colors.primary.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: AnymeXText(
                      widget.confirmText,
                      size: 14,
                      color: widget.isConfirmEnabled
                          ? context.colors.onPrimary
                          : context.colors.onSurface.withOpacity(0.4),
                      variant: TextVariant.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return PopScope(
      canPop: !widget.forceAction,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetAnimationDuration: Duration.zero,
        insetPadding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: isLandscape ? 8 : 24,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (!widget.forceAction) {
              Navigator.of(context).pop();
            }
          },
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: widget.width ??
                    getResponsiveValue(
                      context,
                      mobileValue: Get.width * 0.9,
                      desktopValue: 440.0,
                    ),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height *
                      (isLandscape ? 0.95 : 0.85),
                ),
                decoration: BoxDecoration(
                  color: widget.translucent
                      ? context.colors.surfaceContainer
                          .withOpacity(enableBlur ? 0.5 : 0.88)
                      : context.colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: context.colors.onSurface.withOpacity(0.08),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 25,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: enableBlur
                      ? BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 20,
                            sigmaY: 20,
                          ),
                          child: dialogBody,
                        )
                      : dialogBody,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
