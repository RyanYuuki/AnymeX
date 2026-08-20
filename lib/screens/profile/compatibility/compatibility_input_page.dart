import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/controllers/services/anilist/compatibility_controller.dart';
import 'package:anymex/screens/profile/compatibility/compatibility_result_page.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class CompatibilityInputPage extends StatefulWidget {
  /// Pre-fill the "other user" field (e.g. when opening from another user's profile).
  final String? prefillUsername;
  /// Pre-fill user1 as logged-in user.
  final bool useLoggedInUser;

  const CompatibilityInputPage({
    super.key,
    this.prefillUsername,
    this.useLoggedInUser = true,
  });

  @override
  State<CompatibilityInputPage> createState() => _CompatibilityInputPageState();
}

class _CompatibilityInputPageState extends State<CompatibilityInputPage> {
  final _controller = Get.put(CompatibilityController());
  final _username1Controller = TextEditingController();
  final _username2Controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _compareTwoPeople = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    if (widget.useLoggedInUser) {
      _controller.initWithLoggedInUser();
    }
    if (widget.prefillUsername != null) {
      _username2Controller.text = widget.prefillUsername!;
    }
  }

  @override
  void dispose() {
    _username1Controller.dispose();
    _username2Controller.dispose();
    if (Get.isRegistered<CompatibilityController>()) {
      Get.delete<CompatibilityController>();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name1 = _username1Controller.text.trim();
    final name2 = _username2Controller.text.trim();

    if (name2.isEmpty) {
      snackBar('Please enter a username to compare with.');
      return;
    }

    setState(() => _submitted = true);

    await _controller.runMatch(
      userName1: _compareTwoPeople ? name1 : null,
      userName2: name2,
      useLoggedInUser: !_compareTwoPeople && widget.useLoggedInUser,
    );

    if (!mounted) return;

    if (_controller.errorMessage.value.isNotEmpty) {
      snackBar(_controller.errorMessage.value);
      setState(() => _submitted = false);
      return;
    }

    if (_controller.result.value != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CompatibilityResultPage(
            controller: _controller,
          ),
        ),
      );
      setState(() => _submitted = false);
    } else {
      snackBar('Could not calculate compatibility.');
      setState(() => _submitted = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = Get.find<AnilistAuth>().isLoggedIn.value;
    final loggedInName =
        isLoggedIn ? Get.find<AnilistAuth>().profileData.value.name : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Compatibility Check',
          style: TextStyle(fontFamily: 'Poppins-SemiBold'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header illustration
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.theme.colorScheme.primaryContainer
                            .withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Iconsax.heart4,
                        size: 48,
                        color: context.theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Check how compatible two\nAniList profiles are',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Poppins-SemiBold',
                        color: context.theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Toggle: Compare two different people
              if (isLoggedIn)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Switch(
                        value: _compareTwoPeople,
                        onChanged: (v) => setState(() => _compareTwoPeople = v),
                        activeColor: context.theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(
                              () => _compareTwoPeople = !_compareTwoPeople),
                          child: Text(
                            'Compare two different people',
                            style: TextStyle(
                              fontFamily: 'Poppins-SemiBold',
                              fontSize: 14,
                              color: context.theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // User 1 field
              if (_compareTwoPeople || !isLoggedIn || !widget.useLoggedInUser)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AniList Username #1',
                        style: TextStyle(
                          fontFamily: 'Poppins-SemiBold',
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _username1Controller,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: 'Enter first username',
                          prefixIcon: const Icon(Icons.person_outline),
                          filled: true,
                          fillColor: context
                              .theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter a username';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: context
                          .theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundImage: loggedInName != null
                              ? NetworkImage(Get.find<AnilistAuth>()
                                      .profileData
                                      .value
                                      .avatar ??
                                  '')
                              : null,
                          backgroundColor:
                              context.theme.colorScheme.surfaceContainerHigh,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          loggedInName ?? 'You',
                          style: const TextStyle(
                            fontFamily: 'Poppins-SemiBold',
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: context.theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'You',
                          style: TextStyle(
                            fontFamily: 'Poppins-SemiBold',
                            fontSize: 13,
                            color: context.theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // User 2 field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AniList Username #2',
                    style: TextStyle(
                      fontFamily: 'Poppins-SemiBold',
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _username2Controller,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: 'Enter username to compare with',
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: context
                          .theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter a username';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _submitted ? null : _submit,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _submitted
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.heart4),
                            SizedBox(width: 10),
                            Text(
                              'Matchmake!',
                              style: TextStyle(
                                fontFamily: 'Poppins-Bold',
                                fontSize: 16,
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
    );
  }
}
