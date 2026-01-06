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
            
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.replay),
                label: const Text('Replay'),
                onPressed: _replayAnimation,
              ),
            ),
            
            const SizedBox(height: 20),
            
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
                            _logoKey = UniqueKey();
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Icon(
                                isSelected 
                                    ? Icons.radio_button_checked 
                                    : Icons.radio_button_unchecked,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      animationType.displayName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.onPrimaryContainer
                                            : Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      animationType.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7)
                                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onConfirm(_selectedAnimation);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primaryFixed,
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: "LexendDeca",
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
