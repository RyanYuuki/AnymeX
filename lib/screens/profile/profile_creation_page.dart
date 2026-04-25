import 'dart:io';

import 'package:anymex/controllers/profile/profile_manager.dart';
import 'package:anymex/controllers/services/cloud/cloud_auth_service.dart';
import 'package:anymex/controllers/services/cloud/cloud_profile_service.dart';
import 'package:anymex/screens/profile/widgets/profile_avatar.dart';
import 'package:anymex/utils/logger.dart';
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
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  String _avatarPath = '';
  bool _isCreating = false;
  bool _enablePin = false;

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
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

    if (_enablePin) {
      final pin = _pinController.text.trim();
      final confirmPin = _confirmPinController.text.trim();

      if (pin.length < 4 || pin.length > 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN must be 4-6 digits')),
        );
        return;
      }

      if (!RegExp(r'^\d+$').hasMatch(pin)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN must contain only numbers')),
        );
        return;
      }

      if (pin != confirmPin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PINs do not match')),
        );
        return;
      }
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

    if (_enablePin) {
      manager.setPin(profile.id, _pinController.text.trim());
    }

    try {
      final authService = Get.find<CloudAuthService>();
      if (authService.isLoggedIn.value) {
        final profileService = Get.find<CloudProfileService>();
        String? avatarToUpload;
        if (_avatarPath.isNotEmpty) {
          final file = File(_avatarPath);
          if (file.existsSync()) {
            avatarToUpload = _avatarPath;
          }
        }
        await profileService.createProfile(
          localProfileId: profile.id,
          displayName: profile.name,
          avatarUrl: avatarToUpload,
          pinHash: profile.pinHash,
        );
        if (avatarToUpload != null) {
          final uploadedUrl = await profileService.uploadAvatar(
            profile.id,
            File(avatarToUpload),
          );
          if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
            final mgr = Get.find<ProfileManager>();
            mgr.updateProfileAvatar(profile.id, uploadedUrl);
            await profileService.updateProfile(
              profileId: profile.id,
              avatarUrl: uploadedUrl,
            );
          }
        }
      }
    } catch (e) {
      Logger.i('Cloud profile creation error: $e');
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
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 20,
                            color: _enablePin
                                ? colorScheme.primary
                                : theme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Protect with PIN',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: theme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _enablePin,
                        onChanged: (val) {
                          setState(() {
                            _enablePin = val;
                            if (!val) {
                              _pinController.clear();
                              _confirmPinController.clear();
                            }
                          });
                        },
                        activeColor: colorScheme.primary,
                      ),
                    ],
                  ),
                  if (!_enablePin)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Profile will be unprotected. Anyone who opens the app can access it.',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ),
                  if (_enablePin) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Set a 4-6 digit PIN. You\'ll need to enter it every time you open this profile.',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        letterSpacing: 8,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: 'Create PIN',
                        labelStyle: TextStyle(
                          color: theme.onSurface.withOpacity(0.6),
                          fontFamily: 'Poppins',
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        counterText: '',
                        prefixIcon: Icon(
                          Icons.password_rounded,
                          color: colorScheme.primary.withOpacity(0.6),
                          size: 20,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_pinController.text.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Preview: ',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Poppins',
                                color: theme.onSurface.withOpacity(0.5),
                              ),
                            ),
                            Row(
                              children: List.generate(
                                _pinController.text.length,
                                (index) => Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 3),
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        letterSpacing: 8,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: 'Confirm PIN',
                        labelStyle: TextStyle(
                          color: theme.onSurface.withOpacity(0.6),
                          fontFamily: 'Poppins',
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        counterText: '',
                        prefixIcon: Icon(
                          Icons.password_rounded,
                          color: colorScheme.primary.withOpacity(0.6),
                          size: 20,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                        ),
                      ),
                    ),
                    if (_confirmPinController.text.isNotEmpty &&
                        _confirmPinController.text != _pinController.text)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: Colors.red, size: 14),
                            const SizedBox(width: 4),
                            const Text('PINs do not match',
                                style:
                                    TextStyle(color: Colors.red, fontSize: 12)),
                          ],
                        ),
                      ),
                    if (_confirmPinController.text.isNotEmpty &&
                        _confirmPinController.text == _pinController.text)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline_rounded,
                                color: Colors.green.shade400, size: 14),
                            const SizedBox(width: 4),
                            Text('PINs match',
                                style: TextStyle(
                                    color: Colors.green.shade400, fontSize: 12)),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
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
                        _enablePin ? 'Create Protected Profile' : 'Create Profile',
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
