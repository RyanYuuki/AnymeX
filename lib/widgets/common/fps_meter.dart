import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get_utils/src/extensions/context_extensions.dart';

class FpsMeter extends StatefulWidget {
  const FpsMeter({super.key});

  @override
  State<FpsMeter> createState() => _FpsMeterState();
}

class _FpsMeterState extends State<FpsMeter> {
  double _fps = 0.0;
  int _frameCount = 0;
  late int _lastTimestamp;
  
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _lastTimestamp = DateTime.now().microsecondsSinceEpoch;
      SchedulerBinding.instance.addPostFrameCallback(_onFrame);
    }
  }

  void _onFrame(Duration timestamp) {
    if (!mounted) return;
    
    final currentTimestamp = DateTime.now().microsecondsSinceEpoch;
    _frameCount++;
    
    final delta = currentTimestamp - _lastTimestamp;
    if (delta >= 1000000) {
      setState(() {
        _fps = (_frameCount * 1000000) / delta;
        _frameCount = 0;
        _lastTimestamp = currentTimestamp;
      });
    }
    
    SchedulerBinding.instance.addPostFrameCallback(_onFrame);
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return Positioned(
      top: 50,
      left: 10,
      child: IgnorePointer(
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: context.theme.colorScheme.primary.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              _fps.toStringAsFixed(1),
              style: TextStyle(
                color: context.theme.colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
