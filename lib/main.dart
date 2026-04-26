import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:anymex/controllers/cacher/cache_controller.dart';
import 'package:anymex/controllers/profile/profile_manager.dart';
import 'package:anymex/screens/downloads/controller/download_controller.dart';
import 'package:anymex/controllers/discord/discord_rpc.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/controllers/services/anilist/anilist_data.dart';
import 'package:anymex/controllers/services/mal/mal_service.dart';
import 'package:anymex/controllers/services/simkl/simkl_service.dart';
import 'package:anymex/controllers/services/storage/storage_manager_service.dart';
import 'package:anymex/controllers/services/community_service.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/sync/gist_sync_controller.dart';
import 'package:anymex/controllers/theme.dart';
import 'package:anymex/controllers/ui/greeting.dart';
import 'package:anymex/database/database.dart';
import 'package:anymex/firebase_options.dart';
import 'package:anymex/screens/anime/home_page.dart';
import 'package:anymex/screens/anime/widgets/comments/controller/comment_preloader.dart';
import 'package:anymex/screens/extensions/ExtensionScreen.dart';
import 'package:anymex/screens/home_page.dart';
import 'package:anymex/screens/library/my_library.dart';
import 'package:anymex/screens/manga/home_page.dart';
import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/utils/external_font_loader.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/deeplink.dart';
import 'package:anymex/utils/register_protocol/register_protocol.dart';
import 'package:anymex/models/Service/app_profile.dart';
import 'package:anymex/screens/profile/widgets/pattern_lock.dart';
import 'package:anymex/screens/profile/widgets/profile_avatar.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/adaptive_wrapper.dart';
import 'package:anymex/widgets/animation/more_page_transitions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/navbar.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/screens/profile/profile_creation_page.dart';
import 'package:anymex/screens/profile/profile_selection_page.dart';
import 'package:anymex/screens/profile/widgets/profile_switcher_overlay.dart';
import 'package:anymex/widgets/custom_widgets/anymex_splash_screen.dart';
import 'package:anymex/widgets/custom_widgets/anymex_titlebar.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/non_widgets/settings_sheet.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:isar_community/isar.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:window_manager/window_manager.dart';

WebViewEnvironment? webViewEnvironment;
late Isar isar;
final appLinks = AppLinks();

FirebaseAnalytics analytics = FirebaseAnalytics.instance;

class MyHttpoverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, String host, int port) => true;
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus
      };
}

void initDeepLinkListener() async {
  if (Platform.isLinux) return;

  try {
    final initialUri = await appLinks.getInitialLink();
    if (initialUri != null) Deeplink.handleDeepLink(initialUri);
  } catch (err) {
    errorSnackBar('Error getting initial deep link: $err');
  }

  appLinks.uriLinkStream.listen(
    (uri) => Deeplink.handleDeepLink(uri),
    onError: (err) => errorSnackBar('Error Opening link: $err'),
  );
}

void main(List<String> args) async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    if (Platform.isAndroid) {
      FlutterDisplayMode.setHighRefreshRate().catchError((e) {
        debugPrint("Error setting high refresh rate: $e");
      });
    }
    ExternalFontLoader.loadAllFonts();

    await Logger.init();
    await dotenv.load(fileName: ".env");

    if (!Platform.isLinux) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    if (Platform.isWindows) {
      ['dar', 'anymex', 'sugoireads', 'mangayomi']
          .forEach(registerProtocolHandler);
    }
    await Database().init();
    HttpOverrides.global = MyHttpoverrides();

    _initializeGetxController();
    initDeepLinkListener();
    initializeDateFormatting();
    MediaKit.ensureInitialized();
    if (!Platform.isAndroid && !Platform.isIOS) {
      await windowManager.ensureInitialized();
      if (Platform.isWindows) {
        await AnymexTitleBar.initialize();
      }
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.dark));
    }

    FlutterError.onError = (FlutterErrorDetails details) async {
      FlutterError.presentError(details);
      Logger.e("FLUTTER ERROR: ${details.exceptionAsString()}");
      Logger.e("STACK: ${details.stack}");
    };

    runApp(
      ChangeNotifierProvider(
        create: (context) => ThemeProvider(),
        child: const MainApp(),
      ),
    );
  }, (error, stackTrace) async {
    Logger.e("CRASH: $error");
    Logger.e("STACK: $stackTrace");
  }, zoneSpecification: ZoneSpecification(
    print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
      Logger.i(line);
    },
  ));
}

void _initializeGetxController() async {
  Get.put(ProfileManager(), permanent: true);
  Get.put(Settings());
  Get.put(OfflineStorageController());
  Get.put(AnilistAuth());
  Get.put(CommunityService());
  Get.put(AnilistData());
  Get.put(SimklService());
  Get.put(MalService());
  Get.put(DiscordRPCController());
  if (!Get.isRegistered<SourceController>()) {
    Get.put(SourceController());
  }
  Get.put(ServiceHandler());
  Get.put(GreetingController());
  Get.put(CommentumService());
  Get.put(CommentPreloader());
  Get.put(GistSyncController(), permanent: true);
  Get.put(DownloadController(), permanent: true);
  Get.lazyPut(() => CacheController());
  await StorageManagerService().enforceImageCacheLimit();
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _showMainApp = false;
  bool _isFullScreen = false;

  late FocusNode focusNode;

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      if (_isFullScreen) {
        AnymexTitleBar.setFullScreen(false);
      } else {
        BuildContext escapeContext = Get.context!;
        if (Navigator.of(escapeContext).canPop()) {
          Navigator.pop(escapeContext);
        }
      }
      return KeyEventResult.handled;
    } else if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.f11) {
      AnymexTitleBar.toggleFullScreen();
      return KeyEventResult.handled;
    } else if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter) {
      final isAltPressed = HardwareKeyboard.instance.logicalKeysPressed
              .contains(LogicalKeyboardKey.altLeft) ||
          HardwareKeyboard.instance.logicalKeysPressed
              .contains(LogicalKeyboardKey.altRight);
      if (isAltPressed) {
        AnymexTitleBar.toggleFullScreen();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void initState() {
    super.initState();

    AnymexTitleBar.isFullScreen
        .addListener(() => _isFullScreen = AnymexTitleBar.isFullScreen.value);

    focusNode = FocusNode();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showMainApp = true;
        });
      }
    });
  }

  @override
  void dispose() {
    Logger.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Focus(
      focusNode: focusNode,
      onKeyEvent: _handleKeyEvent,
      child: GetMaterialApp(
        scrollBehavior: MyCustomScrollBehavior(),
        debugShowCheckedModeBanner: false,
        title: "AnymeX",
        theme: theme.lightTheme,
        darkTheme: theme.darkTheme,
        themeMode: theme.isSystemMode
            ? ThemeMode.system
            : theme.isLightMode
                ? ThemeMode.light
                : ThemeMode.dark,
        home: _showMainApp ? const ProfileGate() : const AnymeXSplashScreen(),
        builder: (context, child) {
          if (PlatformDispatcher.instance.views.length > 1) {
            return child!;
          }
          final isDesktop = Platform.isWindows;

          if (isDesktop) {
            return Stack(
              children: [
                RepaintBoundary(child: child!),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.transparent,
                    child: AnymexTitleBar.titleBar(),
                  ),
                ),
              ],
            );
          }
          return child!;
        },
        enableLog: true,
        logWriterCallback: (text, {isError = false}) async {
          Logger.d(text);
        },
      ),
    );
  }
}

class ProfileGate extends StatefulWidget {
  const ProfileGate({super.key});

  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  @override
  Widget build(BuildContext context) {
    final manager = Get.find<ProfileManager>();

    return Obx(() {
      if (manager.showProfileSelection.value) {
        return const ProfileSelectionPage();
      }

      if (manager.isProfileReady.value) {
        return const FilterScreen();
      }

      if (!manager.hasProfiles) {
        return const ProfileCreationPage();
      }

      if (!manager.isMultiProfileEnabled.value && manager.hasSingleProfile) {
        return _AutoStartHandler(
            profileId: manager.profiles.first.id);
      }

      if (manager.hasAutoStart) {
        return _AutoStartHandler(profileId: manager.autoStartProfileId.value);
      }

      if (manager.hasSingleProfile) {
        return _AutoStartHandler(
            profileId: manager.profiles.first.id);
      }

      return const ProfileSelectionPage();
    });
  }
}

class _AutoStartHandler extends StatefulWidget {
  final String profileId;
  const _AutoStartHandler({required this.profileId});

  @override
  State<_AutoStartHandler> createState() => _AutoStartHandlerState();
}

class _AutoStartHandlerState extends State<_AutoStartHandler> {
  bool _needsPin = false;

  @override
  void initState() {
    super.initState();
    _checkAndStart();
  }

  Future<void> _checkAndStart() async {
    final manager = Get.find<ProfileManager>();

    if (manager.isProfileReady.value) {
      return;
    }

    final profile = manager.profiles
        .firstWhereOrNull((p) => p.id == widget.profileId);

    if (profile == null) {
      manager.isProfileReady.value = true;
      return;
    }

    if (profile.hasLock) {
      setState(() => _needsPin = true);
    } else {
      await manager.switchToProfile(profile.id);
    }
  }

  Future<void> _submitLock(String input) async {
    final manager = Get.find<ProfileManager>();
    final result = manager.verifyLock(widget.profileId, input);

    if (result == true) {
      await manager.switchToProfile(widget.profileId);
    } else {
      final profile = manager.profiles.firstWhereOrNull((p) => p.id == widget.profileId);
      final label = profile?.lockLabel ?? 'lock';
      snackBar(result == null
          ? 'Profile is temporarily locked'
          : 'Wrong $label');
      if (result == null && mounted) {
        setState(() => _needsPin = false);
      }
    }
  }

  void _goToProfileSelection() {
    final manager = Get.find<ProfileManager>();
    manager.resetAutoStart();
    manager.requestProfileSelection();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final manager = Get.find<ProfileManager>();

    if (!manager.profiles.any((p) => p.id == widget.profileId)) {
      return const ProfileSelectionPage();
    }

    if (manager.isProfileReady.value) {
      return const FilterScreen();
    }

    if (_needsPin) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _goToProfileSelection,
                    icon: Icon(Icons.arrow_back,
                        color: colorScheme.onSurface.withOpacity(0.7)),
                    label: Text('Switch Profile',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        )),
                  ),
                ),
                Expanded(
                  child: _LockAutoStartWidget(
                    profile: manager.profiles.firstWhere(
                        (p) => p.id == widget.profileId),
                    onSubmit: _submitLock,
                    onSwitchProfile: _goToProfileSelection,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: CircularProgressIndicator(
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

class _LockAutoStartWidget extends StatefulWidget {
  final AppProfile profile;
  final Future<void> Function(String input) onSubmit;
  final VoidCallback onSwitchProfile;
  const _LockAutoStartWidget({
    required this.profile,
    required this.onSubmit,
    required this.onSwitchProfile,
  });

  @override
  State<_LockAutoStartWidget> createState() => _LockAutoStartWidgetState();
}

class _LockAutoStartWidgetState extends State<_LockAutoStartWidget> {
  final _controller = TextEditingController();
  bool _error = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final profile = widget.profile;
    if (profile.isPatternLocked) return;
    final input = profile.isPinLocked
        ? _controller.text.trim()
        : _controller.text;
    if (input.length < 4) return;
    widget.onSubmit(input);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final profile = widget.profile;
    final onSurface = context.colors.onSurface;

    if (profile.isLocked) {
      final remaining =
          profile.lockedUntil!.difference(DateTime.now()).inMinutes + 1;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProfileAvatar(profile: profile, radius: 48, showLocked: true),
            const SizedBox(height: 16),
            Text(profile.name,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: onSurface)),
            const SizedBox(height: 24),
            Text('Too many failed attempts.',
                style: TextStyle(
                    color: onSurface.withOpacity(0.7), fontSize: 14)),
            const SizedBox(height: 8),
            Text('Try again in $remaining minute${remaining != 1 ? 's' : ''}',
                style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins')),
            const SizedBox(height: 24),
            TextButton(
              onPressed: widget.onSwitchProfile,
              child: Text('Switch to another profile',
                  style: TextStyle(
                      color: colorScheme.primary,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          ProfileAvatar(profile: profile, radius: 52),
          const SizedBox(height: 16),
          Text(profile.name,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: onSurface)),
          const SizedBox(height: 6),
          if (profile.anilistLinked ||
              profile.malLinked ||
              profile.simklLinked)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (profile.anilistLinked)
                  _serviceDot('AL', Colors.blue),
                if (profile.malLinked)
                  _serviceDot('MAL', Colors.blueAccent),
                if (profile.simklLinked)
                  _serviceDot('Simkl', Colors.green),
              ],
            ),
          const SizedBox(height: 40),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        profile.isPinLocked
                            ? Icons.dialpad_rounded
                            : profile.isPasswordLocked
                                ? Icons.password_rounded
                                : Icons.grid_3x3_rounded,
                        size: 20,
                        color: colorScheme.primary.withOpacity(0.8)),
                    const SizedBox(width: 8),
                    Text('Enter ${profile.lockLabel} to unlock',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: onSurface.withOpacity(0.8),
                        )),
                  ],
                ),
                const SizedBox(height: 20),
                if (profile.isPatternLocked)
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: PatternLock(
                      onPatternComplete: (pattern) {
                        widget.onSubmit(pattern.join(','));
                      },
                    ),
                  )
                else
                  TextField(
                  controller: _controller,
                  keyboardType: profile.isPinLocked
                      ? TextInputType.number
                      : TextInputType.text,
                  obscureText: true,
                  maxLength: profile.isPinLocked ? 6 : 32,
                  autofocus: true,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontFamily: 'Poppins',
                    fontSize: 28,
                    letterSpacing: 10,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: _error
                          ? const BorderSide(color: Colors.red, width: 2)
                          : BorderSide.none,
                    ),
                    counterText: '',
                  ),
                  onChanged: (_) => setState(() {
                    _error = false;
                    _errorMessage = '';
                  }),
                  onSubmitted: (_) => _submit(),
                ),
                if (_error) ...[
                  const SizedBox(height: 8),
                  Text(_errorMessage,
                      style: const TextStyle(
                          color: Colors.red, fontSize: 13)),
                ],
                const SizedBox(height: 4),
                Obx(() {
                  final manager = Get.find<ProfileManager>();
                  final attempts = manager.profiles
                          .firstWhereOrNull((p) => p.id == profile.id)
                          ?.failedAttempts ??
                      0;
                  if (attempts > 0) {
                    return Text(
                      '$attempts / $kMaxLockAttempts attempts',
                      style: TextStyle(
                          color: onSurface.withOpacity(0.4), fontSize: 12),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Unlock',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  )),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: widget.onSwitchProfile,
            child: Text('Not your profile? Switch to another',
                style: TextStyle(
                    color: colorScheme.primary.withOpacity(0.8),
                    fontFamily: 'Poppins',
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _serviceDot(String text, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  int _selectedIndex = 1;
  int _mobileSelectedIndex = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Get.find<Settings>();
      settings.checkForUpdates(context);
      settings.showWelcomeDialog(context);
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onMobileItemTapped(int index) {
    setState(() {
      _mobileSelectedIndex = index;
    });
  }

  final routes = [
    const SizedBox.shrink(),
    const HomePage(),
    const AnimeHomePage(),
    const MangaHomePage(),
    const MyLibrary(),
    const ExtensionScreen(disableGlow: true),
  ];

  final mobileRoutes = [
    const HomePage(),
    const AnimeHomePage(),
    const MangaHomePage(),
    const MyLibrary()
  ];

  @override
  void dispose() {
    Logger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Get.put(ServiceHandler());
    final isSimkl =
        Get.find<ServiceHandler>().serviceType.value == ServicesType.simkl;
    return Glow(
      child: PlatformBuilder(
        strictMode: false,
        desktopBuilder: _buildDesktopLayout(context, authService, isSimkl),
        androidBuilder: _buildAndroidLayout(isSimkl),
      ),
    );
  }

  Scaffold _buildDesktopLayout(
      BuildContext context, ServiceHandler authService, bool isSimkl) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Provider.of<ThemeProvider>(context).isOled
          ? Colors.black
          : Colors.transparent,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => SizedBox(
              width: 120,
              child: SuperListView(
                children: [
                  ResponsiveNavBar(
                    isDesktop: true,
                    currentIndex: _selectedIndex,
                    margin: const EdgeInsets.fromLTRB(20, 30, 15, 10),
                    items: [
                      NavItem(
                          unselectedIcon: IconlyBold.profile,
                          selectedIcon: IconlyBold.profile,
                          onTap: (index) {
                            return SettingsSheet.show(context);
                          },
                          label: 'Profile',
                          altIcon: Obx(() {
                            final multiProfile = Get.find<ProfileManager>().isMultiProfileEnabled.value;
                            return GestureDetector(
                              onLongPress: multiProfile
                                  ? () => showProfileSwitcher(context)
                                  : null,
                              child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainer
                                      .withValues(alpha: 0.3),
                                  child: authService.isLoggedIn.value
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(59),
                                          child: AnymeXImage(
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                              radius: 0,
                                              imageUrl: authService
                                                      .profileData
                                                      .value
                                                      .avatar ??
                                                  ''),
                                        )
                                      : const Icon((IconlyBold.profile))),
                            );
                          })),
                      NavItem(
                        unselectedIcon: IconlyLight.home,
                        selectedIcon: IconlyBold.home,
                        onTap: _onItemTapped,
                        label: 'Home',
                      ),
                      NavItem(
                        unselectedIcon: Icons.movie_filter_outlined,
                        selectedIcon: Icons.movie_filter_rounded,
                        onTap: _onItemTapped,
                        label: 'Anime',
                      ),
                      NavItem(
                        unselectedIcon:
                            isSimkl ? Iconsax.monitor : Iconsax.book,
                        selectedIcon: isSimkl ? Iconsax.monitor5 : Iconsax.book,
                        onTap: _onItemTapped,
                        label: 'Manga',
                      ),
                      NavItem(
                        unselectedIcon: HugeIcons.strokeRoundedLibrary,
                        selectedIcon: HugeIcons.strokeRoundedLibrary,
                        onTap: _onItemTapped,
                        label: 'Library',
                      ),
                      NavItem(
                        unselectedIcon: Icons.extension_outlined,
                        selectedIcon: Icons.extension_rounded,
                        onTap: _onItemTapped,
                        label: "Extensions",
                      ),
                    ],
                  ),
                ],
              ))),
          Expanded(
              child: SmoothPageEntrance(
                  style: PageEntranceStyle.slideUpGentle,
                  key: Key(_selectedIndex.toString()),
                  child: routes[_selectedIndex])),
        ],
      ),
    );
  }

  Scaffold _buildAndroidLayout(bool isSimkl) {
    return Scaffold(
        body: SmoothPageEntrance(
            style: PageEntranceStyle.slideUpGentle,
            key: Key(_mobileSelectedIndex.toString()),
            child: mobileRoutes[_mobileSelectedIndex]),
        extendBody: true,
        bottomNavigationBar: ResponsiveNavBar(
          isDesktop: false,
          currentIndex: _mobileSelectedIndex,
          margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
          items: [
            NavItem(
              unselectedIcon: IconlyBold.home,
              selectedIcon: IconlyBold.home,
              onTap: _onMobileItemTapped,
              label: 'Home',
            ),
            NavItem(
              unselectedIcon: Icons.movie_filter_rounded,
              selectedIcon: Icons.movie_filter_rounded,
              onTap: _onMobileItemTapped,
              label: 'Anime',
            ),
            NavItem(
              unselectedIcon: isSimkl ? Iconsax.monitor : Iconsax.book,
              selectedIcon: isSimkl ? Iconsax.monitor5 : Iconsax.book,
              onTap: _onMobileItemTapped,
              label: 'Manga',
            ),
            NavItem(
              unselectedIcon: HugeIcons.strokeRoundedLibrary,
              selectedIcon: HugeIcons.strokeRoundedLibrary,
              onTap: _onMobileItemTapped,
              label: 'Library',
            ),
          ],
        ));
  }
}
