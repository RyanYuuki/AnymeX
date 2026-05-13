import 'package:flutter/material.dart';

class PatternLock extends StatefulWidget {
  final List<int> initialPattern;
  final ValueChanged<List<int>> onPatternComplete;
  final Color? activeColor;
  final Color? dotColor;
  final Color? lineColor;
  final int minDots;
  final bool readOnly;

  const PatternLock({
    super.key,
    this.initialPattern = const [],
    required this.onPatternComplete,
    this.activeColor,
    this.dotColor,
    this.lineColor,
    this.minDots = 4,
    this.readOnly = false,
  });

  @override
  State<PatternLock> createState() => PatternLockState();
}

class PatternLockState extends State<PatternLock> {
  final List<int> _selectedDots = [];
  Offset? _currentPosition;
  bool _isDrawing = false;

  final double _dotSize = 20;
  final double _hitRadius = 30;
  static const int _gridSize = 3;

  @override
  void initState() {
    super.initState();
    _selectedDots.addAll(widget.initialPattern);
    if (widget.initialPattern.isNotEmpty) {
      _isDrawing = false;
    }
  }

  void reset() {
    setState(() {
      _selectedDots.clear();
      _currentPosition = null;
      _isDrawing = false;
    });
  }

  List<int> get currentPattern => List.unmodifiable(_selectedDots);

  List<Offset> _getDotPositions(double width, double height) {
    final positions = <Offset>[];
    final padding = width * 0.2;
    final availableWidth = width - (padding * 2);
    final availableHeight = height - (padding * 2);
    final spacingX = availableWidth / (_gridSize - 1);
    final spacingY = availableHeight / (_gridSize - 1);

    for (int row = 0; row < _gridSize; row++) {
      for (int col = 0; col < _gridSize; col++) {
        positions.add(Offset(
          padding + (col * spacingX),
          padding + (row * spacingY),
        ));
      }
    }
    return positions;
  }

  int? _getDotAtPosition(Offset position, List<Offset> dotPositions) {
    for (int i = 0; i < dotPositions.length; i++) {
      if ((position - dotPositions[i]).distance <= _hitRadius) {
        return i;
      }
    }
    return null;
  }

  void _handlePanStart(DragStartDetails details, List<Offset> dotPositions) {
    if (widget.readOnly) return;
    final dotIndex = _getDotAtPosition(details.localPosition, dotPositions);
    if (dotIndex != null) {
      setState(() {
        _selectedDots.clear();
        _selectedDots.add(dotIndex);
        _currentPosition = details.localPosition;
        _isDrawing = true;
      });
    }
  }

  void _handlePanUpdate(DragUpdateDetails details, List<Offset> dotPositions) {
    if (!_isDrawing || widget.readOnly) return;

    final dotIndex = _getDotAtPosition(details.localPosition, dotPositions);
    if (dotIndex != null && !_selectedDots.contains(dotIndex)) {
      setState(() {
        _selectedDots.add(dotIndex);
        _currentPosition = dotPositions[dotIndex];
      });
    } else {
      setState(() {
        _currentPosition = details.localPosition;
      });
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!_isDrawing || widget.readOnly) return;

    if (_selectedDots.length >= widget.minDots) {
      widget.onPatternComplete(List.from(_selectedDots));
    }

    if (!widget.readOnly) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          setState(() {
            _selectedDots.clear();
            _currentPosition = null;
            _isDrawing = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = widget.activeColor ?? colorScheme.primary;
    final dotColor = widget.dotColor ?? colorScheme.onSurface.withOpacity(0.2);
    final lineColor = widget.lineColor ?? primaryColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        final height = size;
        final dotPositions = _getDotPositions(size, height);

        return GestureDetector(
          onPanStart: (details) => _handlePanStart(details, dotPositions),
          onPanUpdate: (details) => _handlePanUpdate(details, dotPositions),
          onPanEnd: _handlePanEnd,
          child: SizedBox(
            width: size,
            height: height,
            child: CustomPaint(
              painter: _PatternPainter(
                dotPositions: dotPositions,
                selectedDots: _selectedDots,
                currentPosition: _currentPosition,
                isDrawing: _isDrawing,
                dotSize: _dotSize,
                dotColor: dotColor,
                activeColor: primaryColor,
                lineColor: lineColor,
                hasError: _selectedDots.isNotEmpty &&
                    _selectedDots.length < widget.minDots &&
                    !_isDrawing,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PatternPainter extends CustomPainter {
  final List<Offset> dotPositions;
  final List<int> selectedDots;
  final Offset? currentPosition;
  final bool isDrawing;
  final double dotSize;
  final Color dotColor;
  final Color activeColor;
  final Color lineColor;
  final bool hasError;

  _PatternPainter({
    required this.dotPositions,
    required this.selectedDots,
    this.currentPosition,
    required this.isDrawing,
    required this.dotSize,
    required this.dotColor,
    required this.activeColor,
    required this.lineColor,
    required this.hasError,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final errorColor = Colors.red.shade400;
    final effectiveActiveColor = hasError ? errorColor : activeColor;
    final effectiveLineColor = hasError ? errorColor : lineColor;

    final linePaint = Paint()
      ..color = effectiveLineColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final lineShadowPaint = Paint()
      ..color = effectiveLineColor.withOpacity(0.15)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    if (selectedDots.length >= 2) {
      for (int i = 0; i < selectedDots.length - 1; i++) {
        final start = dotPositions[selectedDots[i]];
        final end = dotPositions[selectedDots[i + 1]];
        canvas.drawLine(start, end, lineShadowPaint);
        canvas.drawLine(start, end, linePaint);
      }
    }

    if (isDrawing && currentPosition != null && selectedDots.isNotEmpty) {
      final lastDot = dotPositions[selectedDots.last];
      canvas.drawLine(lastDot, currentPosition!, lineShadowPaint);
      canvas.drawLine(lastDot, currentPosition!, linePaint);
    }

    for (int i = 0; i < dotPositions.length; i++) {
      final pos = dotPositions[i];
      final isSelected = selectedDots.contains(i);

      if (isSelected) {
        final glowPaint = Paint()
          ..color = effectiveActiveColor.withOpacity(0.2);
        canvas.drawCircle(pos, dotSize * 1.3, glowPaint);

        final bgPaint = Paint()..color = effectiveActiveColor;
        canvas.drawCircle(pos, dotSize * 0.85, bgPaint);

        final centerPaint = Paint()
          ..color = effectiveActiveColor.withOpacity(0.4);
        canvas.drawCircle(pos, dotSize * 0.45, centerPaint);
      } else {
        final borderPaint = Paint()
          ..color = dotColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(pos, dotSize * 0.55, borderPaint);

        final centerPaint = Paint()..color = dotColor;
        canvas.drawCircle(pos, dotSize * 0.18, centerPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) {
    return oldDelegate.selectedDots != selectedDots ||
        oldDelegate.currentPosition != currentPosition ||
        oldDelegate.isDrawing != isDrawing ||
        oldDelegate.hasError != hasError;
  }
}
