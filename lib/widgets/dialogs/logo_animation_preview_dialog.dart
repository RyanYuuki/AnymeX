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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape = screenWidth > screenHeight;
    
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isLandscape ? 800 : 600,
          maxHeight: screenHeight * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              child: Row(
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
            ),
            
            // Content
            Expanded(
              child: isLandscape ? _buildLandscapeLayout() : _buildPortraitLayout(),
            ),
            
            // Buttons
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Preview Section (Fixed height, not scrollable)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: AnymeXAnimatedLogo(
                    key: _logoKey,
                    size: 120,
                    autoPlay: true,
                    forceAnimationType: _selectedAnimation,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.replay, size: 18),
                label: const Text('Replay'),
                onPressed: _replayAnimation,
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Animation Style',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        
        // Animation List (Scrollable)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildAnimationList(),
          ),
        ),
        
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Preview
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: AnymeXAnimatedLogo(
                      key: _logoKey,
                      size: 140,
                      autoPlay: true,
                      forceAnimationType: _selectedAnimation,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.replay, size: 18),
                  label: const Text('Replay'),
                  onPressed: _replayAnimation,
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 20),
          
          // Right side - List
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Animation Style',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildAnimationList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimationList() {
    return ListView.builder(
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
                      size: 20,
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
                              fontSize: 14,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            animationType.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7)
                                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
    );
  }
}
