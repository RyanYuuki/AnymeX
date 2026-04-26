import 'dart:io';

import 'package:anymex/controllers/profile/profile_manager.dart';
import 'package:anymex/controllers/services/backup_restore/backup_restore_service.dart';
import 'package:anymex/models/Service/app_profile.dart';
import 'package:anymex/screens/profile/widgets/pattern_lock.dart';
import 'package:anymex/screens/profile/widgets/profile_avatar.dart';
import 'package:anymex/screens/settings/sub_settings/widgets/backup_and_restore_widgets.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_animated_logo.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileCreationPage extends StatefulWidget {
  final bool isFirstLaunch;

  const ProfileCreationPage({super.key, this.isFirstLaunch = false});

  @override
  State<ProfileCreationPage> createState() => _ProfileCreationPageState();
}

class _ProfileCreationPageState extends State<ProfileCreationPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String _avatarPath = '';
  bool _isCreating = false;
  bool _isRestoring = false;
  bool _showSetupForm = false;
  bool get _showWelcome => widget.isFirstLaunch && !_showSetupForm;
  ProfileLockType _lockType = ProfileLockType.none;
  List<int> _pattern = [];
  bool _patternConfirmed = false;
  List<int> _firstPattern = [];

  late final AnimationController _animController;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    if (!widget.isFirstLaunch) {
      _showSetupForm = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animController.value = 1.0;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _toggleSetupForm() {
    setState(() => _showSetupForm = true);
    _animController.forward();
  }

  Future<void> _pickImage() async {
    final path = await pickAndSaveProfileImage();
    if (path != null) {
      setState(() => _avatarPath = path);
    }
  }

  bool _validateLock() {
    switch (_lockType) {
      case ProfileLockType.none:
        return true;
      case ProfileLockType.pin:
        final pin = _pinController.text.trim();
        final confirmPin = _confirmPinController.text.trim();
        if (pin.length < 4 || pin.length > 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN must be 4-6 digits')),
          );
          return false;
        }
        if (!RegExp(r'^\d+$').hasMatch(pin)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN must contain only numbers')),
          );
          return false;
        }
        if (pin != confirmPin) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PINs do not match')),
          );
          return false;
        }
        return true;
      case ProfileLockType.password:
        final password = _passwordController.text;
        final confirmPassword = _confirmPasswordController.text;
        if (password.length < 4 || password.length > 32) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password must be 4-32 characters')),
          );
          return false;
        }
        if (password != confirmPassword) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Passwords do not match')),
          );
          return false;
        }
        return true;
      case ProfileLockType.pattern:
        if (!_patternConfirmed || _pattern.length < 4) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please draw and confirm a pattern with at least 4 dots')),
          );
          return false;
        }
        return true;
    }
  }

  void _resetLockInputs() {
    _pinController.clear();
    _confirmPinController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _pattern.clear();
    _firstPattern.clear();
    _patternConfirmed = false;
  }

  Future<void> _createProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a profile name')),
      );
      return;
    }

    if (!_validateLock()) return;

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

    switch (_lockType) {
      case ProfileLockType.none:
        break;
      case ProfileLockType.pin:
        manager.setPin(profile.id, _pinController.text.trim());
        break;
      case ProfileLockType.password:
        manager.setPassword(profile.id, _passwordController.text);
        break;
      case ProfileLockType.pattern:
        manager.setPattern(profile.id, _pattern);
        break;
    }

    await manager.switchToProfile(profile.id);

    if (mounted) {
      Navigator.of(context).pop(profile);
    }
  }

  Future<void> _skipAndCreateDefault() async {
    final manager = Get.find<ProfileManager>();
    await manager.skipMultiProfileSetup();
  }

  Future<void> _restoreFromBackup() async {
    setState(() => _isRestoring = true);
    try {
      final controller = Get.put(BackupRestoreService());
      final path = await controller.pickBackupFile();
      if (path == null || path.isEmpty) {
        setState(() => _isRestoring = false);
        return;
      }

      final isEncrypted = await controller.isBackupEncrypted(path);
      String? password;

      if (isEncrypted) {
        if (!mounted) return;
        final pwController = TextEditingController();
        password = await showDialog<String>(
          context: context,
          builder: (context) => PasswordInputDialog(controller: pwController),
        );
        pwController.dispose();
        if (password == null) {
          setState(() => _isRestoring = false);
          return;
        }
      }

      final info = await controller.getBackupInfo(path, password: password);
      if (info == null) {
        if (mounted) snackBar('Invalid backup file or incorrect password');
        setState(() => _isRestoring = false);
        return;
      }

      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => RestorePreviewSheet(
          info: info,
          isEncrypted: isEncrypted,
          onConfirm: (restoreSettings, restoreAuthTokens, createNew) async {
            Navigator.pop(context);
            try {
              await controller.restoreBackup(
                path,
                password: password,
                merge: false,
                restoreSettings: restoreSettings,
                restoreAuthTokens: restoreAuthTokens,
                createNewProfile: createNew,
              );
              if (mounted) {
                snackBar('Profile restored successfully!');
              }
            } catch (e) {
              if (mounted) snackBar('Restore failed: $e');
            }
          },
        ),
      );
      Get.delete<BackupRestoreService>();
    } catch (e) {
      if (mounted) snackBar('Error: $e');
    }
    setState(() => _isRestoring = false);
  }

  IconData _getLockIcon(ProfileLockType type) {
    switch (type) {
      case ProfileLockType.none:
        return Icons.lock_open_rounded;
      case ProfileLockType.pin:
        return Icons.dialpad_rounded;
      case ProfileLockType.password:
        return Icons.password_rounded;
      case ProfileLockType.pattern:
        return Icons.grid_3x3_rounded;
    }
  }

  String _getLockLabel(ProfileLockType type) {
    switch (type) {
      case ProfileLockType.none:
        return 'None';
      case ProfileLockType.pin:
        return 'PIN';
      case ProfileLockType.password:
        return 'Password';
      case ProfileLockType.pattern:
        return 'Pattern';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  if (_showWelcome)
                    const SizedBox(width: 48)
                  else
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: theme.onSurface),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    if (_showWelcome) ...[
                      const SizedBox(height: 40),
                      AnymeXAnimatedLogo(
                        size: 120,
                        autoPlay: true,
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Welcome to AnymeX',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                          color: theme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Set up separate profiles to keep your watch history, accounts, and settings organized — or skip and start using the app right away.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: theme.onSurface.withOpacity(0.55),
                          height: 1.5,
                        ),
                      ),
                    ],

                    SizeTransition(
                      sizeFactor: _expandAnimation,
                      axisAlignment: -1.0,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            const SizedBox(height: 24),
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
                                      color:
                                          colorScheme.primary.withOpacity(0.3),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_a_photo_rounded,
                                            size: 32,
                                            color: colorScheme.primary
                                                .withOpacity(0.7),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Add Photo',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _avatarPath.isNotEmpty
                                  ? 'Tap to change photo'
                                  : 'Tap to add avatar',
                              style: TextStyle(
                                color: theme.onSurface.withOpacity(0.5),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _nameController,
                              autofocus: false,
                              textCapitalization: TextCapitalization.words,
                              maxLength: 20,
                              style: TextStyle(
                                  color: theme.onSurface,
                                  fontFamily: 'Poppins'),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.lock_outline_rounded,
                                        size: 20,
                                        color: _lockType != ProfileLockType.none
                                            ? colorScheme.primary
                                            : theme.onSurface.withOpacity(0.5),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Protection',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: theme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children:
                                        ProfileLockType.values.map((type) {
                                      final isSelected = _lockType == type;
                                      return ChoiceChip(
                                        avatar: Icon(
                                          _getLockIcon(type),
                                          size: 16,
                                          color: isSelected
                                              ? colorScheme.onPrimary
                                              : theme.onSurface
                                                  .withOpacity(0.6),
                                        ),
                                        label: Text(
                                          _getLockLabel(type),
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 13,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                        ),
                                        selected: isSelected,
                                        selectedColor: colorScheme.primary,
                                        onSelected: (val) {
                                          setState(() {
                                            _lockType = type;
                                            _resetLockInputs();
                                          });
                                        },
                                        labelStyle: TextStyle(
                                          color: isSelected
                                              ? colorScheme.onPrimary
                                              : theme.onSurface,
                                        ),
                                        side: BorderSide(
                                          color: isSelected
                                              ? colorScheme.primary
                                              : colorScheme.outline
                                                  .withOpacity(0.3),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  if (_lockType == ProfileLockType.none)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        'Profile will be unprotected. Anyone who opens the app can access it.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              theme.onSurface.withOpacity(0.4),
                                        ),
                                      ),
                                    ),
                                  if (_lockType == ProfileLockType.pin) ...[
                                    const SizedBox(height: 16),
                                    _buildPinSetup(colorScheme, theme),
                                  ],
                                  if (_lockType ==
                                      ProfileLockType.password) ...[
                                    const SizedBox(height: 16),
                                    _buildPasswordSetup(colorScheme, theme),
                                  ],
                                  if (_lockType == ProfileLockType.pattern) ...[
                                    const SizedBox(height: 16),
                                    _buildPatternSetup(colorScheme, theme),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed:
                                    _isCreating ? null : _createProfile,
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
                                        _lockType == ProfileLockType.none
                                            ? 'Create Profile'
                                            : 'Create Protected Profile',
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
                    ),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 16, 32, 12),
                child: Column(
                  children: [
                    if (_showWelcome) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _toggleSetupForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Set Up Profiles',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _isRestoring ? null : _restoreFromBackup,
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                theme.onSurface.withOpacity(0.7),
                            side: BorderSide(
                              color: colorScheme.outline.withOpacity(0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: _isRestoring
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: AnymexProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  Icons.restore_rounded,
                                  size: 18,
                                  color: theme.onSurface.withOpacity(0.7),
                                ),
                          label: Text(
                            'Restore from Backup',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: theme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          onPressed: _skipAndCreateDefault,
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                theme.onSurface.withOpacity(0.7),
                            side: BorderSide(
                              color: colorScheme.outline.withOpacity(0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Skip for Now',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: theme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You can always enable profiles later in Settings.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: theme.onSurface.withOpacity(0.35),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinSetup(ColorScheme colorScheme, dynamic theme) {
    return Column(
      children: [
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      margin: const EdgeInsets.symmetric(horizontal: 3),
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
    );
  }

  Widget _buildPasswordSetup(ColorScheme colorScheme, dynamic theme) {
    return Column(
      children: [
        Text(
          'Set a password (4-32 characters) for this profile.',
          style: TextStyle(
            fontSize: 12,
            color: theme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          maxLength: 32,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontFamily: 'Poppins',
            fontSize: 16,
          ),
          decoration: InputDecoration(
            labelText: 'Create Password',
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
              Icons.lock_rounded,
              color: colorScheme.primary.withOpacity(0.6),
              size: 20,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          maxLength: 32,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontFamily: 'Poppins',
            fontSize: 16,
          ),
          decoration: InputDecoration(
            labelText: 'Confirm Password',
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
              Icons.lock_rounded,
              color: colorScheme.primary.withOpacity(0.6),
              size: 20,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
            ),
          ),
        ),
        if (_confirmPasswordController.text.isNotEmpty &&
            _confirmPasswordController.text != _passwordController.text)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.red, size: 14),
                const SizedBox(width: 4),
                const Text('Passwords do not match',
                    style:
                        TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ),
          ),
        if (_confirmPasswordController.text.isNotEmpty &&
            _confirmPasswordController.text == _passwordController.text)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    color: Colors.green.shade400, size: 14),
                const SizedBox(width: 4),
                Text('Passwords match',
                    style: TextStyle(
                        color: Colors.green.shade400, fontSize: 12)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPatternSetup(ColorScheme colorScheme, dynamic theme) {
    return Column(
      children: [
        Text(
          _firstPattern.isEmpty
              ? 'Draw a pattern by connecting at least 4 dots.'
              : 'Draw the pattern again to confirm.',
          style: TextStyle(
            fontSize: 12,
            color: theme.onSurface.withOpacity(0.6),
          ),
        ),
        if (_patternConfirmed)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    color: Colors.green.shade400, size: 14),
                const SizedBox(width: 4),
                Text('Pattern confirmed',
                    style: TextStyle(
                        color: Colors.green.shade400, fontSize: 12)),
              ],
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: 240,
          height: 240,
          child: PatternLock(
            onPatternComplete: (pattern) {
              if (_firstPattern.isEmpty) {
                setState(() {
                  _firstPattern = pattern;
                });
              } else {
                if (pattern.length >= 4) {
                  final matches =
                      pattern.length == _firstPattern.length;
                  bool samePattern = false;
                  if (matches) {
                    samePattern = true;
                    for (int i = 0; i < pattern.length; i++) {
                      if (pattern[i] != _firstPattern[i]) {
                        samePattern = false;
                        break;
                      }
                    }
                  }
                  if (samePattern) {
                    setState(() {
                      _pattern = pattern;
                      _patternConfirmed = true;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Patterns do not match. Try again.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    setState(() {
                      _firstPattern.clear();
                    });
                  }
                }
              }
            },
          ),
        ),
        if (_firstPattern.isNotEmpty && !_patternConfirmed)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _firstPattern.clear();
                  _pattern.clear();
                });
              },
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Reset pattern'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
              ),
            ),
          ),
        if (_patternConfirmed)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _firstPattern.clear();
                  _pattern.clear();
                  _patternConfirmed = false;
                });
              },
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Redraw pattern'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}
