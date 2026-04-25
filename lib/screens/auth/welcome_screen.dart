import 'package:anymex/controllers/profile/profile_manager.dart';
import 'package:anymex/controllers/services/cloud/cloud_auth_service.dart';
import 'package:anymex/controllers/services/cloud/cloud_profile_service.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/utils/cloud_encryption.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoginMode = true;
  bool _showPassword = false;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final authService = Get.find<CloudAuthService>();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.length < 3) {
      _setError('Username must be at least 3 characters');
      return;
    }
    if (password.length < 8) {
      _setError('Password must be at least 8 characters');
      return;
    }

    setState(() => _isLoading = true);
    _errorMessage = '';

    bool success;
    if (_isLoginMode) {
      success = await authService.login(username: username, password: password);
    } else {
      final confirm = _confirmPasswordController.text;
      if (confirm != password) {
        setState(() => _isLoading = false);
        _setError('Passwords do not match');
        return;
      }
      success = await authService.register(
        username: username,
        password: password,
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      _setError(authService.errorMessage.value);
    } else {
      _ensureEncryptionSalt();
      final authService = Get.find<CloudAuthService>();
      if (authService.cloudPassword.value.isEmpty) {
        authService.cloudPassword.value = _passwordController.text;
      }
      await _fetchCloudProfiles();
    }
  }

  Future<void> _fetchCloudProfiles() async {
    try {
      final profileService = Get.find<CloudProfileService>();
      final manager = Get.find<ProfileManager>();

      final cloudProfiles = await profileService.listProfiles();
      if (cloudProfiles != null && cloudProfiles.isNotEmpty) {
        await manager.importFromCloud(cloudProfiles);
      }
    } catch (e) {
      Logger.i('Error fetching cloud profiles after auth: $e');
    }
  }

  void _ensureEncryptionSalt() {
    final existingSalt = CloudKeys.encryptionSalt.get<String?>();
    if (existingSalt == null || existingSalt.isEmpty) {
      final salt = CloudEncryption.generateSaltBase64();
      CloudKeys.encryptionSalt.set(salt);
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
  }

  void _skip() {
    final authService = Get.find<CloudAuthService>();
    authService.skipCloud();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = context.colors;

    return Glow(
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 60),
                Image.asset(
                  'assets/images/logo.png',
                  width: 90,
                  height: 90,
                  errorBuilder: (_, __, ___) => Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primaryContainer,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 44,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'AnymeX',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    color: theme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your anime & manga companion',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: theme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.onSurface.withOpacity(0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isLoginMode ? 'Welcome Back' : 'Create Account',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: theme.onSurface,
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() {
                              _isLoginMode = !_isLoginMode;
                              _errorMessage = '';
                            }),
                            child: Text(
                              _isLoginMode ? 'Register' : 'Login',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isLoginMode
                            ? 'Sign in to sync your profiles across devices'
                            : 'Create an account to get started with cloud profiles',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: theme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _usernameController,
                        style: TextStyle(
                          color: theme.onSurface,
                          fontFamily: 'Poppins',
                        ),
                        decoration: InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(
                            Icons.person_outline_rounded,
                            color: theme.onSurface.withOpacity(0.5),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      if (!_isLoginMode) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(
                            color: theme.onSurface,
                            fontFamily: 'Poppins',
                          ),
                          decoration: InputDecoration(
                            labelText: 'Email (optional)',
                            prefixIcon: Icon(
                              Icons.mail_outline_rounded,
                              color: theme.onSurface.withOpacity(0.5),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        style: TextStyle(
                          color: theme.onSurface,
                          fontFamily: 'Poppins',
                        ),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(
                            Icons.lock_outline_rounded,
                            color: theme.onSurface.withOpacity(0.5),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: theme.onSurface.withOpacity(0.5),
                            ),
                            onPressed: () => setState(
                              () => _showPassword = !_showPassword,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      if (!_isLoginMode) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: !_showPassword,
                          style: TextStyle(
                            color: theme.onSurface,
                            fontFamily: 'Poppins',
                          ),
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: Icon(
                              Icons.lock_outline_rounded,
                              color: theme.onSurface.withOpacity(0.5),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                      if (_errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: Colors.red.shade400,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: TextStyle(
                                  color: Colors.red.shade400,
                                  fontSize: 13,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : Text(
                                  _isLoginMode ? 'Sign In' : 'Create Account',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: theme.onSurface.withOpacity(0.1))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: theme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: theme.onSurface.withOpacity(0.1))),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _skip,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: colorScheme.onSurface.withOpacity(0.15),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Skip - Use Without Account',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: theme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'You can sign in later from Settings > Cloud Sync',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: theme.onSurface.withOpacity(0.35),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
