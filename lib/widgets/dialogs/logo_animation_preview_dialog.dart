/// Logo Animation Preview Dialog

import 'package:flutter/material.dart';
import 'package:anymex/models/logo_animation_type.dart';
import 'package:anymex/widgets/custom_widgets/anymex_animated_logo.dart';

class LogoAnimationPreviewDialog extends StatefulWidget {
  final LogoAnimationType initialAnimation;
  final Function(LogoAnimationType) onConfirm;

  const LogoAnimationPreviewDialog({
    Key? key,
    required this.initialAnimation,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<LogoAnimationPreviewDialog> createState() => _LogoAnimationPreviewDialogState();
}

class _LogoAnimationPreviewDialogState extends State<LogoAnimationPreviewDialog> {
  late LogoAnimationType _selectedAnimation;
  Key _logoKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _selectedAnimation = widget.initialAnimation;
  }

  void _replayAnimation() {
    setState(() {
      // Force rebuild with new key to restart animation
      _logoKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Logo Animation',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Preview Area
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: AnymeXAnimatedLogo(
                  key: _logoKey,
                  size: 150,
                  autoPlay: true,
                  forceAnimationType: _selectedAnimation,
                ),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Replay Button
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.replay),
                label: const Text('Replay'),
                onPressed: _replayAnimation,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Animation List
            const Text(
              'Select Animation Style',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: LogoAnimationType.values.length,
                itemBuilder: (context, index) {
                  final animationType = LogoAnimationType.values[index];
                  final isSelected = _selectedAnimation == animationType;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            _selectedAnimation = animationType;
                            _logoKey = UniqueKey(); // Restart animation
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Icon(
                                isSelected 
                                    ? Icons.radio
