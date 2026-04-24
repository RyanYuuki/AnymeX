import 'dart:io';

import 'package:anymex/controllers/profile/profile_manager.dart';
import 'package:anymex/screens/profile/widgets/profile_avatar.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileCreationPage extends StatefulWidget {
  const ProfileCreationPage({super.key});

  @override
  State<ProfileCreationPage> createState() => _ProfileCreationPageState();
}

class _ProfileCreationPageState extends State<ProfileCreationPage> {
  final TextEditingController _nameController = TextEditingController();
  String _avatarPath = '';
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final path = await pickAndSaveProfileImage();
    if (path != null) {
      setState(() => _avatarPath = path);
    }
  }

  Future<void> _createProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a profile name')),
      );
      return;
    }

    setState(() => _isCreating = true);

    final manager = Get.find<ProfileManager>();
    final profile = manager.createProfile(
      name: name,
      avatarPath: _avatarPath,
    );

    if (profile == null) {
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum of 5 profiles reached')),
        );
      }
      return;
    }

    await manager.switchToProfile(profile.id);

    if (mounted) {
      Navigator.of(context).pop(profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Create Profile',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: theme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primaryContainer,
                  border: Border.all(
                    color: colorScheme.primary,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: _avatarPath.isNotEmpty
                    ? ClipOval(
                        child: Image.file(
                          File(_avatarPath),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_rounded,
                            size: 32,
                            color: colorScheme.primary.withOpacity(0.7),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add Photo',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _avatarPath.isNotEmpty ? 'Tap to change photo' : 'Tap to add avatar',
              style: TextStyle(
                color: theme.onSurface.withOpacity(0.5),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              maxLength: 20,
              style: TextStyle(color: theme.onSurface, fontFamily: 'Poppins'),
              decoration: InputDecoration(
                labelText: 'Profile Name',
                labelStyle: TextStyle(
                  color: theme.onSurface.withOpacity(0.7),
                  fontFamily: 'Poppins',
                ),
                hintText: 'Enter a name...',
                hintStyle: TextStyle(
                  color: theme.onSurface.withOpacity(0.3),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                counterStyle: TextStyle(
                  color: theme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Obx(() {
              final count = Get.find<ProfileManager>().profiles.length;
              return Text(
                '$count / $kMaxProfiles profiles',
                style: TextStyle(
                  color: count >= kMaxProfiles
                      ? Colors.red
                      : theme.onSurface.withOpacity(0.5),
                  fontSize: 13,
                ),
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isCreating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: AnymexProgressIndicator(
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Create Profile',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colorScheme.onPrimary,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
