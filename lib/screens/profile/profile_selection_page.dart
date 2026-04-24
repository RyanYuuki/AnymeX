import 'package:anymex/controllers/profile/profile_manager.dart';
import 'package:anymex/models/Service/app_profile.dart';
import 'package:anymex/screens/profile/profile_creation_page.dart';
import 'package:anymex/screens/profile/widgets/profile_avatar.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ProfileSelectionPage extends StatefulWidget {
  const ProfileSelectionPage({super.key});

  @override
  State<ProfileSelectionPage> createState() => _ProfileSelectionPageState();
}

class _ProfileSelectionPageState extends State<ProfileSelectionPage> {
  RxBool autoStart = false.obs;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = context.colors;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Image.asset(
                'assets/images/logo.png',
                width: 80,
                height: 80,
                errorBuilder: (_, __, ___) => Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primaryContainer,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 40,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'AnymeX',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: theme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select a profile to continue',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: theme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 32),
              Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: autoStart.value,
                          onChanged: (val) =>
                              autoStart.value = val ?? false,
                          activeColor: colorScheme.primary,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(4)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => autoStart.value = !autoStart.value,
                        child: Text(
                          'Open selected profile automatically',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  )),
              const SizedBox(height: 24),
              Expanded(
                child: Obx(() {
                  final profiles = Get.find<ProfileManager>().profiles;
                  if (profiles.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No profiles yet',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              color: theme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: profiles.length + 1,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == profiles.length) {
                        return _buildAddProfileCard(
                            colorScheme, theme, profiles.length);
                      }
                      return _buildProfileCard(
                          context, profiles[index], colorScheme, theme);
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, AppProfile profile,
      ColorScheme colorScheme, dynamic theme) {
    return GestureDetector(
      onTap: () => _selectProfile(profile),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.onSurface.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            ProfileAvatar(
              profile: profile,
              radius: 28,
              showLocked: profile.isLocked,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        profile.name,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.onSurface,
                        ),
                      ),
                      if (profile.hasPin) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.lock_outline,
                            size: 14,
                            color: theme.onSurface.withOpacity(0.5)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last used ${_formatDate(profile.lastUsedAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (profile.anilistLinked)
                        _buildBadge('AL', Colors.blue, colorScheme),
                      if (profile.malLinked)
                        _buildBadge('MAL', Colors.blueAccent, colorScheme),
                      if (profile.simklLinked)
                        _buildBadge('Simkl', Colors.green, colorScheme),
                      if (!profile.anilistLinked &&
                          !profile.malLinked &&
                          !profile.simklLinked)
                        _buildBadge('No services linked',
                            theme.onSurface.withOpacity(0.3), colorScheme),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.onSurface.withOpacity(0.3),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAddProfileCard(
      ColorScheme colorScheme, dynamic theme, int currentCount) {
    return GestureDetector(
      onTap: () {
        if (currentCount >= kMaxProfiles) {
          snackBar('Maximum of $kMaxProfiles profiles reached');
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfileCreationPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.primary.withOpacity(0.3),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline,
                color: colorScheme.primary, size: 24),
            const SizedBox(width: 10),
            Text(
              'Create New Profile',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectProfile(AppProfile profile) async {
    if (profile.hasPin) {
      final success = await _showPinDialog(profile);
      if (success != true) return;
    }

    final manager = Get.find<ProfileManager>();
    await manager.switchToProfile(profile.id, autoStart: autoStart.value);

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<bool?> _showPinDialog(AppProfile profile) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PinEntryDialog(profile: profile),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }
}

class _PinEntryDialog extends StatefulWidget {
  final AppProfile profile;
  const _PinEntryDialog({required this.profile});

  @override
  State<_PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<_PinEntryDialog> {
  final TextEditingController _pinController = TextEditingController();
  bool _isError = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final profile = widget.profile;

    if (profile.isLocked) {
      final remaining =
          profile.lockedUntil!.difference(DateTime.now()).inMinutes + 1;
      return AlertDialog(
        backgroundColor: colorScheme.surfaceContainer,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Profile Locked',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Too many failed attempts.',
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
            ),
            const SizedBox(height: 8),
            Text(
              'Try again in $remaining minute${remaining != 1 ? 's' : ''}',
              style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('OK',
                style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      );
    }

    return AlertDialog(
      backgroundColor: colorScheme.surfaceContainer,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Enter PIN',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Enter PIN for "${profile.name}"',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            autofocus: true,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontFamily: 'Poppins',
              fontSize: 24,
              letterSpacing: 8,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: _isError
                    ? BorderSide(color: Colors.red, width: 2)
                    : BorderSide.none,
              ),
              hintText: '• • • •',
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.2),
                letterSpacing: 4,
              ),
              counterText: '',
            ),
            onChanged: (_) {
              if (_isError) {
                setState(() {
                  _isError = false;
                  _errorMessage = '';
                });
              }
            },
          ),
          if (_isError) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],
          const SizedBox(height: 4),
          Obx(() {
            final manager = Get.find<ProfileManager>();
            final attempts = manager.profiles
                    .firstWhereOrNull((p) => p.id == profile.id)
                    ?.failedPinAttempts ??
                0;
            if (attempts > 0) {
              return Text(
                '$attempts / $kMaxPinAttempts attempts',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.4),
                  fontSize: 12,
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel',
              style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.7))),
        ),
        ElevatedButton(
          onPressed: () => _verifyPin(),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Unlock'),
        ),
      ],
    );
  }

  void _verifyPin() {
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      setState(() {
        _isError = true;
        _errorMessage = 'PIN must be at least 4 digits';
      });
      return;
    }

    final manager = Get.find<ProfileManager>();
    final result = manager.verifyPin(widget.profile.id, pin);

    if (result == true) {
      Navigator.pop(context, true);
    } else if (result == false) {
      setState(() {
        _isError = true;
        final remaining = kMaxPinAttempts -
            (manager.profiles
                    .firstWhereOrNull((p) => p.id == widget.profile.id)
                    ?.failedPinAttempts ??
                0);
        _errorMessage =
            'Wrong PIN. $remaining attempt${remaining != 1 ? 's' : ''} remaining';
      });
      _pinController.clear();
    } else {
      Navigator.pop(context, false);
    }
  }
}
