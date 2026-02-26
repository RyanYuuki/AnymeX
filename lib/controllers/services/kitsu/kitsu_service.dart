import 'package:anymex/controllers/services/kitsu/kitsu_auth.dart';
import 'package:anymex/controllers/services/kitsu/kitsu_sync.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/models/Service/base_service.dart';
import 'package:anymex/models/Service/online_service.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class KitsuService extends GetxController implements BaseService {
  final kitsuAuth = Get.find<KitsuAuth>();
  final kitsuSync = Get.find<KitsuSync>();

  @override
  RxBool isLoggedIn = false.obs;

  @override
  Rx<Profile> profileData = Profile().obs;

  @override
  Future<void> login(BuildContext context) async {
    _showLoginMethodDialog(context);
  }

  void _showLoginMethodDialog(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceContainer,
        title: const Text('Login to Kitsu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.email, color: colors.primary),
              title: const Text('Login with Email/Password'),
              subtitle: const Text('Use your Kitsu account credentials'),
              onTap: () {
                Navigator.pop(context);
                _showEmailPasswordDialog(context);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: colors.surfaceContainerHigh,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.oauth, color: colors.primary),
              title: const Text('Login with OAuth'),
              subtitle: const Text('Use browser authentication'),
              onTap: () {
                Navigator.pop(context);
                _loginWithOAuth();
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: colors.surfaceContainerHigh,
            ),
          ],
        ),
      ),
    );
  }

  void _showEmailPasswordDialog(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final isLoading = false.obs;

    showDialog(
      context: context,
      builder: (context) => Obx(() => AlertDialog(
        backgroundColor: colors.surfaceContainer,
        title: const Text('Kitsu Login'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
              ),
              obscureText: true,
            ),
            if (isLoading.value)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: isLoading.value
                ? null
                : () async {
                    isLoading.value = true;
                    try {
                      await kitsuAuth.loginWithEmailPassword(
                        emailController.text,
                        passwordController.text,
                      );
                      isLoggedIn.value = kitsuAuth.isLoggedIn.value;
                      profileData.value = kitsuAuth.profileData.value;
                      Navigator.pop(context);
                    } finally {
                      isLoading.value = false;
                    }
                  },
            child: const Text('Login'),
          ),
        ],
      )),
    );
  }

  Future<void> _loginWithOAuth() async {
    await kitsuAuth.loginWithOAuth();
    isLoggedIn.value = kitsuAuth.isLoggedIn.value;
    profileData.value = kitsuAuth.profileData.value;
  }

  @override
  Future<void> logout() async {
    kitsuAuth.logout();
    isLoggedIn.value = false;
    profileData.value = Profile();
  }

  @override
  Future<void> autoLogin() async {
    await kitsuAuth.autoLogin();
    isLoggedIn.value = kitsuAuth.isLoggedIn.value;
    profileData.value = kitsuAuth.profileData.value;
  }

  @override
  Future<void> refresh() async {
    if (isLoggedIn.value) {
      await kitsuAuth.fetchUserProfile();
      profileData.value = kitsuAuth.profileData.value;
    }
  }

  @override
  RxList<Widget> homeWidgets(BuildContext context) {
    return <Widget>[].obs;
  }

  Future<void> syncToKitsuFromCurrentService() async {
    if (!isLoggedIn.value) {
      snackBar('Please login to Kitsu first');
      return;
    }

    final currentService = serviceHandler.serviceType.value;
    if (currentService == ServicesType.extensions) {
      snackBar('Cannot sync from extensions');
      return;
    }

    await kitsuSync.batchSyncToKitsu();
  }

  Future<void> syncEntryToKitsu({
    required String listId,
    required bool isAnime,
    String? score,
    String? status,
    int? progress,
    String? malId,
  }) async {
    if (!isLoggedIn.value) return;

    await kitsuSync.syncToKitsu(
      listId: listId,
      isAnime: isAnime,
      score: score,
      status: status,
      progress: progress,
      malId: malId,
    );
  }
}
