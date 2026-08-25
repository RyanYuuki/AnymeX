import 'dart:async';
import 'dart:ui';

import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/controllers/services/anilist/compatibility_controller.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/models/Anilist/social_user.dart';
import 'package:anymex/screens/profile/compatibility/compatibility_result_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_button.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_progress.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tabbar.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/helper/scroll_wrapper.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class CompatibilityInputPage extends StatefulWidget {
  final String? prefillUsername;
  final Profile? prefillProfile;
  final bool useLoggedInUser;

  const CompatibilityInputPage({
    super.key,
    this.prefillUsername,
    this.prefillProfile,
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

  List<SocialUser> _followingList = [];
  Profile? _user1Profile;
  Profile? _user2Profile;
  String? _user1Avatar;
  String? _user2Avatar;
  Timer? _debounceUser1;
  Timer? _debounceUser2;

  @override
  void initState() {
    super.initState();
    final isLoggedIn = Get.find<AnilistAuth>().isLoggedIn.value;
    if (widget.useLoggedInUser && isLoggedIn) {
      _controller.initWithLoggedInUser();
      _loadFollowing();
    } else {
      _compareTwoPeople = true;
    }
    if (widget.prefillProfile != null) {
      _user2Profile = widget.prefillProfile;
      _user2Avatar = widget.prefillProfile!.avatar;
      _username2Controller.text = widget.prefillProfile!.name ?? widget.prefillUsername ?? '';
    } else if (widget.prefillUsername != null && widget.prefillUsername!.isNotEmpty) {
      final name = widget.prefillUsername!;
      _username2Controller.text = name;
      Get.find<AnilistAuth>().fetchUserDetails(name).then((p) {
        if (mounted && _username2Controller.text.trim().toLowerCase() == name.toLowerCase()) {
          setState(() {
            _user2Profile = p;
            if (p?.avatar != null) _user2Avatar = p!.avatar;
          });
        }
      });
    }
  }

  void _loadFollowing() async {
    final auth = Get.find<AnilistAuth>();
    if (!auth.isLoggedIn.value) return;
    final idStr = auth.profileData.value.id;
    if (idStr == null) return;
    final userId = int.tryParse(idStr);
    if (userId == null) return;
    try {
      final (following, _, _) = await auth.fetchFollowingPage(userId);
      if (mounted && following.isNotEmpty) {
        setState(() {
          _followingList = following;
        });
      
        if (_user2Avatar == null && _username2Controller.text.isNotEmpty) {
          final match = following.firstWhereOrNull(
            (u) => u.name.toLowerCase() == _username2Controller.text.trim().toLowerCase(),
          );
          if (match != null && match.avatarUrl != null) {
            setState(() => _user2Avatar = match.avatarUrl);
          }
        }
      }
    } catch (_) {}
  }

  void _onUserChanged(String value, bool isUser1) {
    setState(() {});
    if (isUser1) {
      _debounceUser1?.cancel();
    } else {
      _debounceUser2?.cancel();
    }
    final name = value.trim();
    if (name.isEmpty) {
      setState(() {
        if (isUser1) {
          _user1Avatar = null;
        } else {
          _user2Avatar = null;
        }
      });
      return;
    }
    final match = _followingList.firstWhereOrNull(
      (u) => u.name.toLowerCase() == name.toLowerCase(),
    );
    if (match != null && match.avatarUrl != null && match.avatarUrl!.isNotEmpty) {
      setState(() {
        if (isUser1) {
          _user1Avatar = match.avatarUrl;
        } else {
          _user2Avatar = match.avatarUrl;
        }
      });
      Get.find<AnilistAuth>().fetchUserDetails(match.name).then((p) {
        if (mounted && (isUser1 ? _username1Controller : _username2Controller).text.trim().toLowerCase() == match.name.toLowerCase()) {
          setState(() {
            if (isUser1) {
              _user1Profile = p;
            } else {
              _user2Profile = p;
            }
          });
        }
      });
      return;
    }
    final timer = Timer(const Duration(milliseconds: 250), () async {
      final auth = Get.find<AnilistAuth>();
      final profile = await auth.fetchUserDetails(name);
      final avatar = profile?.avatar ?? await auth.fetchUserAvatar(name);
      final currentCtrl = isUser1 ? _username1Controller : _username2Controller;
      if (mounted && currentCtrl.text.trim().toLowerCase() == name.toLowerCase()) {
        setState(() {
          if (isUser1) {
            _user1Avatar = avatar;
            _user1Profile = profile;
          } else {
            _user2Avatar = avatar;
            _user2Profile = profile;
          }
        });
      }
    });
    if (isUser1) {
      _debounceUser1 = timer;
    } else {
      _debounceUser2 = timer;
    }
  }

  void _onUser1Changed(String value) => _onUserChanged(value, true);
  void _onUser2Changed(String value) => _onUserChanged(value, false);

  @override
  void dispose() {
    _debounceUser1?.cancel();
    _debounceUser2?.cancel();
    _username1Controller.dispose();
    _username2Controller.dispose();
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

    final isUsingLoggedIn = !_compareTwoPeople && widget.useLoggedInUser;
    if (isUsingLoggedIn) {
      final loggedInName = Get.find<AnilistAuth>().profileData.value.name?.toLowerCase().trim();
      if (loggedInName != null && loggedInName.isNotEmpty && name2.toLowerCase() == loggedInName) {
        snackBar('Cannot compare your profile with yourself! Please enter a different username.');
        return;
      }
    } else {
      if (name1.toLowerCase() == name2.toLowerCase()) {
        snackBar('Cannot compare a user with themselves! Please enter two different usernames.');
        return;
      }
    }

    setState(() => _submitted = true);

    await _controller.runMatch(
      userName1: _compareTwoPeople ? name1 : null,
      userName2: name2,
      profile1: (_compareTwoPeople && _user1Profile != null && _user1Profile!.name?.toLowerCase().trim() == name1.toLowerCase())
          ? _user1Profile
          : null,
      profile2: (_user2Profile != null && _user2Profile!.name?.toLowerCase().trim() == name2.toLowerCase())
          ? _user2Profile
          : null,
      useLoggedInUser: isUsingLoggedIn,
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

  Widget _buildAvatarSlot({
    required BuildContext context,
    required String? name,
    required String? avatar,
    required String placeholderName,
    required IconData placeholderIcon,
    required Color borderColor,
    required Color shadowColor,
    required Color iconColor,
    required double avatarSize,
    required bool isLargeScreen,
  }) {
    final hasName = name != null && name.trim().isNotEmpty;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2.5),
              boxShadow: [
                if (avatar != null && avatar.isNotEmpty)
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: ClipOval(
              child: avatar != null && avatar.isNotEmpty
                  ? AnymeXImage(
                      imageUrl: avatar,
                      fit: BoxFit.cover,
                      width: avatarSize,
                      height: avatarSize,
                    )
                  : Center(
                      child: Icon(
                        placeholderIcon,
                        size: isLargeScreen ? 34 : 28,
                        color: iconColor,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          AnymeXText(
            hasName ? name : placeholderName,
            variant: TextVariant.bold,
            size: isLargeScreen ? 14 : 13,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            color: hasName ? null : context.colors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildMatchupHero(
    BuildContext context,
    String? user1Name,
    String? user1Avatar,
    String user2Name,
    String? user2Avatar, {
    bool isLargeScreen = false,
  }) {
    final colorScheme = context.theme.colorScheme;
    final hasUser1 = user1Name != null && user1Name.trim().isNotEmpty;
    final hasUser2 = user2Name.trim().isNotEmpty;
    final isMatched = hasUser1 && hasUser2;
    final avatarSize = isLargeScreen ? 84.0 : 68.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(
        horizontal: isLargeScreen ? 32 : 16,
        vertical: isLargeScreen ? 26 : 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceContainerHighest.opaque(0.45),
            isMatched
                ? colorScheme.primary.opaque(0.08)
                : colorScheme.surfaceContainerHigh.opaque(0.25),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isMatched
              ? colorScheme.primary.opaque(0.3)
              : colorScheme.outline.opaque(0.12),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAvatarSlot(
            context: context,
            name: user1Name,
            avatar: user1Avatar,
            placeholderName: 'User 1',
            placeholderIcon: Iconsax.user,
            borderColor: colorScheme.primary.opaque(0.8),
            shadowColor: colorScheme.primary.opaque(0.25),
            iconColor: colorScheme.primary,
            avatarSize: avatarSize,
            isLargeScreen: isLargeScreen,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? 20 : 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isLargeScreen ? 52 : 46,
                  height: isLargeScreen ? 52 : 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isMatched
                        ? colorScheme.primary.opaque(0.25)
                        : colorScheme.primary.opaque(0.12),
                    border: Border.all(
                      color: isMatched
                          ? colorScheme.primary.opaque(0.6)
                          : colorScheme.primary.opaque(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.opaque(isMatched ? 0.35 : 0.15),
                        blurRadius: isMatched ? 16 : 8,
                        spreadRadius: isMatched ? 2 : 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Iconsax.heart5,
                      size: isLargeScreen ? 26 : 24,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.opaque(0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.outline.opaque(0.08),
                    ),
                  ),
                  child: AnymeXText(
                    'VS',
                    size: 10,
                    variant: TextVariant.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          _buildAvatarSlot(
            context: context,
            name: user2Name,
            avatar: user2Avatar,
            placeholderName: 'Target User',
            placeholderIcon: hasUser2 ? Iconsax.user_tick : Iconsax.user_search,
            borderColor: hasUser2
                ? colorScheme.secondary.opaque(0.8)
                : colorScheme.outline.opaque(0.25),
            shadowColor: colorScheme.secondary.opaque(0.25),
            iconColor: hasUser2
                ? colorScheme.secondary
                : colorScheme.onSurfaceVariant,
            avatarSize: avatarSize,
            isLargeScreen: isLargeScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildUserInputSection(
    BuildContext context, {
    required String title,
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required bool isUser1,
    required ValueChanged<String> onChanged,
    TextInputAction textInputAction = TextInputAction.next,
    String? Function(String?)? validator,
  }) {
    final c = context.colors;
    return AnymeXSectionBuilder(
      title: title,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextFormField(
            controller: controller,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            textInputAction: textInputAction,
            onChanged: onChanged,
            onFieldSubmitted: textInputAction == TextInputAction.done ? (_) => _submit() : null,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: Icon(prefixIcon, color: c.primary, size: 20),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: c.surfaceContainerHigh.opaque(0.35),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: c.outline.opaque(0.12)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: c.outline.opaque(0.12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: c.primary, width: 1.5),
              ),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildFirstUserInput(BuildContext context) {
    return _buildUserInputSection(
      context,
      title: 'First User',
      controller: _username1Controller,
      hintText: 'Enter first AniList username',
      prefixIcon: Iconsax.user,
      isUser1: true,
      onChanged: _onUser1Changed,
      textInputAction: TextInputAction.next,
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a username' : null,
    );
  }

  Widget _buildSecondUserInput(BuildContext context, bool isLoggedIn) {
    return _buildUserInputSection(
      context,
      title: (_compareTwoPeople || !isLoggedIn || !widget.useLoggedInUser)
          ? 'Second User'
          : 'Compare With',
      controller: _username2Controller,
      hintText: 'Enter AniList username',
      prefixIcon: Iconsax.user_search,
      isUser1: false,
      onChanged: _onUser2Changed,
      textInputAction: TextInputAction.done,
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'Please enter a username';
        }
        if (!_compareTwoPeople && widget.useLoggedInUser) {
          final loggedIn = Get.find<AnilistAuth>().profileData.value.name?.toLowerCase().trim();
          if (loggedIn != null && loggedIn.isNotEmpty && v.trim().toLowerCase() == loggedIn) {
            return 'Cannot compare with yourself';
          }
        }
        if (_compareTwoPeople && _username1Controller.text.trim().toLowerCase() == v.trim().toLowerCase()) {
          return 'Please enter two different usernames';
        }
        return null;
      },
    );
  }

  Widget _buildCalculateButton() {
    return SizedBox(
      height: 52,
      child: AnymeXButton(
        onTap: () {
          HapticFeedback.lightImpact();
          _submit();
        },
        borderRadius: BorderRadius.circular(16),
        child: _submitted || _controller.isLoading.value
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: AnymeXProgressIndicator(strokeWidth: 2.5),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.heart5, size: 20),
                  SizedBox(width: 8),
                  AnymeXText(
                    'Calculate Compatibility',
                    variant: TextVariant.bold,
                    size: 15,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFollowingCard(BuildContext context, SocialUser friend, bool isSelected) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _username2Controller.text = friend.name;
          _user2Avatar = friend.avatarUrl;
        });
        Get.find<AnilistAuth>().fetchUserDetails(friend.name).then((p) {
          if (mounted && _username2Controller.text.trim().toLowerCase() == friend.name.toLowerCase()) {
            setState(() => _user2Profile = p);
          }
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.primary.opaque(0.2)
              : context.colors.surfaceContainerHighest.opaque(0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? context.colors.primary
                : context.colors.outline.opaque(0.1),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: context.colors.primary.opaque(0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: ClipOval(
                    child: friend.avatarUrl != null && friend.avatarUrl!.isNotEmpty
                        ? AnymeXImage(
                            imageUrl: friend.avatarUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.person, size: 20),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: context.colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        size: 10,
                        color: context.colors.onPrimary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 65,
              child: AnymeXText(
                friend.name,
                size: 11,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                variant: isSelected ? TextVariant.bold : TextVariant.regular,
                color: isSelected ? context.colors.primary : null,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildDesktopFollowingGrid(BuildContext context) {
    return AnymeXSectionBuilder(
      title: 'Quick Select (Following)',
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: _followingList.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (ctx, i) {
                final friend = _followingList[i];
                final isSelected = _username2Controller.text.trim().toLowerCase() == friend.name.toLowerCase();
                return _buildFollowingCard(context, friend, isSelected);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopFeatureInfoCard(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.opaque(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.opaque(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.radar_2, color: colorScheme.primary, size: 22),
              const SizedBox(width: 10),
              const AnymeXText(
                '16-Factor Deep Comparison',
                variant: TextVariant.bold,
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnymeXText(
            'AniMatch calculates real-time overlap across:\n'
            '• Anime & Manga Watch/Read Stats\n'
            '• Mean Score & Standard Deviation Affinity\n'
            '• Release Decades (2000s, 2010s, 2020s)\n'
            '• Media Formats (TV, Movie, OVA, ONA)\n'
            '• Shared Top Genres & Tags\n'
            '• Favorite Voice Actors, Staff & Studios\n'
            '• Mutual Social Connections & Following',
            size: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildInputControls(BuildContext context, bool isLoggedIn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isLoggedIn && widget.useLoggedInUser) ...[
          AnymeXTabBar(
            height: 46,
            selectTabs: const ['With My Profile', 'Compare Two Users'],
            icons: const [Iconsax.user, Iconsax.people],
            selectedIndex: _compareTwoPeople ? 1 : 0,
            onTabSelected: (idx) {
              if ((idx == 1) != _compareTwoPeople) {
                HapticFeedback.selectionClick();
                setState(() => _compareTwoPeople = idx == 1);
              }
            },
            activeColor: context.colors.primary,
            activeTextColor: context.colors.onPrimary,
          ),
          const SizedBox(height: 16),
        ],
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          child: (_compareTwoPeople || !isLoggedIn || !widget.useLoggedInUser)
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildFirstUserInput(context),
                )
              : const SizedBox.shrink(),
        ),
        _buildSecondUserInput(context, isLoggedIn),
      ],
    );
  }

  Widget _buildMobileFollowingCarousel(BuildContext context) {
    return AnymeXSectionBuilder(
      title: 'Quick Select (Following)',
      children: [
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            itemCount: _followingList.length,
            itemBuilder: (ctx, i) {
              final friend = _followingList[i];
              final isSelected = _username2Controller.text.trim().toLowerCase() == friend.name.toLowerCase();
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildFollowingCard(context, friend, isSelected),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnymeXScaffold(
      showHeader: true,
      headerTitle: 'AniMatch Compatibility',
      body: Obx(() {
        final isLoggedIn = Get.find<AnilistAuth>().isLoggedIn.value;
        final loggedInProfile = Get.find<AnilistAuth>().profileData.value;
        final loggedInName = isLoggedIn ? loggedInProfile.name : null;
        final loggedInAvatar = isLoggedIn ? loggedInProfile.avatar : null;

        final user1Name = _compareTwoPeople
            ? _username1Controller.text.trim()
            : (loggedInName ?? 'You');
        final user1Avatar = _compareTwoPeople ? _user1Avatar : loggedInAvatar;
        final user2Name = _username2Controller.text.trim();

        final screenWidth = MediaQuery.sizeOf(context).width;
        final isLargeScreen = screenWidth > 768;
        final containerMaxWidth = isLargeScreen ? 940.0 : 580.0;
        final showLoading = _controller.isLoading.value || _submitted;

        return Stack(
          children: [
            Builder(
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
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: containerMaxWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),

                            _buildMatchupHero(
                              context,
                              user1Name,
                              user1Avatar,
                              user2Name,
                              _user2Avatar,
                              isLargeScreen: isLargeScreen,
                            ),
                            const SizedBox(height: 24),

                            if (isLargeScreen)
                              
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        _buildInputControls(context, isLoggedIn),
                                        const SizedBox(height: 20),
                                        _buildCalculateButton(),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 6,
                                    child: isLoggedIn && _followingList.isNotEmpty
                                        ? _buildDesktopFollowingGrid(context)
                                        : _buildDesktopFeatureInfoCard(context),
                                  ),
                                ],
                              )
                            else
                            
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildInputControls(context, isLoggedIn),
                                  if (isLoggedIn && _followingList.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    _buildMobileFollowingCarousel(context),
                                  ],
                                  const SizedBox(height: 24),
                                  _buildCalculateButton(),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (showLoading)
              Positioned.fill(
                child: PopScope(
                  canPop: false,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    builder: (context, opacity, child) => Opacity(
                      opacity: opacity,
                      child: child,
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        color: Colors.black.withOpacity(0.35),
                        child: const Center(
                          child: AnymeXProgressIndicator(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
