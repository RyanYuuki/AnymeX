import 'package:flutter/material.dart';
import 'package:anymex/models/logo_animation_type.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:iconly/iconly.dart';

class LogoAnimationPreviewDialog extends StatefulWidget {
  final LogoAnimationType initialAnimation;
  final Function(LogoAnimationType) onConfirm;

  const LogoAnimationPreviewDialog({
    super.key,
    required this.initialAnimation,
    required this.onConfirm,
  });

  @override
  State<LogoAnimationPreviewDialog> createState() =>
      _LogoAnimationPreviewDialogState();
}

class _LogoAnimationPreviewDialogState extends State<LogoAnimationPreviewDialog> {
  late LogoAnimationType selectedAnimation;

  @override
  void initState() {
    super.initState();
    selectedAnimation = widget.initialAnimation;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Logo Animation',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: LogoAnimationType.values.length,
                itemBuilder: (context, index) {
                  final animationType = LogoAnimationType.values[index];
                  final isSelected = selectedAnimation == animationType;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            selectedAnimation = animationType;
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
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      animationType.displayName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      animationType.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onConfirm(selectedAnimation);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
