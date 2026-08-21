import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/controllers/services/anilist/compatibility_controller.dart';
import 'package:anymex/screens/profile/compatibility/compatibility_result_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_button.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_icon_wrapper.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_progress.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/helper/scroll_wrapper.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class CompatibilityInputPage extends StatefulWidget {
  final String? prefillUsername;
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
      navigate(() => CompatibilityResultPage(controller: _controller));
      setState(() => _submitted = false);
    } else {
      snackBar('Could not calculate compatibility.');
      setState(() => _submitted = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnymeXScaffold(
      showHeader: true,
      headerTitle: 'Compatibility Check',
      body: Obx(() {
        final isLoggedIn = Get.find<AnilistAuth>().isLoggedIn.value;
        final loggedInName =
            isLoggedIn ? Get.find<AnilistAuth>().profileData.value?.name : null;

        return Builder(
          builder: (ctx) => Form(
            key: _formKey,
            child: ScrollWrapper(
              comfortPadding: false,
              customPadding: EdgeInsets.fromLTRB(
                16,
                AnymeXHeaderScope.of(ctx),
                16,
                28,
              ),
              children: [
                Center(
                  child: AnymeXIconWrapper(
                    child: Icon(
                      Iconsax.heart4,
                      size: 48,
                      color: context.theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AnymeXText(
                  'Check how compatible two\nAniList profiles are',
                  textAlign: TextAlign.center,
                  size: 16,
                  color: context.theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 24),

                if (isLoggedIn)
                  AnymeXSectionBuilder(
                    title: 'Options',
                    children: [
                      AnymeXTile.toggle(
                        icon: Iconsax.people,
                        title: 'Compare two different people',
                        subtitle: 'Disable to compare with your own profile',
                        value: _compareTwoPeople,
                        onChanged: (v) => setState(() => _compareTwoPeople = v),
                      ),
                    ],
                  ),

                if (isLoggedIn && !_compareTwoPeople && widget.useLoggedInUser)
                  AnymeXSectionBuilder(
                    title: 'Your Profile',
                    children: [
                      AnymeXTile(
                        icon: Iconsax.user,
                        title: loggedInName ?? 'You',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: context.theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            AnymeXText(
                              'You',
                              size: 13,
                              color: context.theme.colorScheme.primary,
                            ),
                          ],
                        ),
                        showChevron: false,
                      ),
                    ],
                  ),

                if (_compareTwoPeople || !isLoggedIn || !widget.useLoggedInUser)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnymeXText('AniList Username #1',
                            variant: TextVariant.semiBold, size: 14),
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
                  ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnymeXText('AniList Username #2',
                        variant: TextVariant.semiBold, size: 14),
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
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: AnymeXButton(
                    onTap: _submitted ? () {} : _submit,
                    child: _submitted
                        ? const AnymeXProgressIndicator(strokeWidth: 2.5)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Iconsax.heart4),
                              const SizedBox(width: 10),
                              AnymeXText('Matchmake!',
                                  variant: TextVariant.bold, size: 16),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
