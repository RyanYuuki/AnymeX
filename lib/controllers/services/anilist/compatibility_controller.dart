import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/utils/compatibility/compatibility_models.dart';
import 'package:anymex/utils/compatibility/matchmaker.dart';
import 'package:anymex/utils/logger.dart';
import 'package:get/get.dart';

class CompatibilityController extends GetxController {
  final AnilistAuth _auth = Get.find<AnilistAuth>();

  final Rx<Profile?> user1 = Rx<Profile?>(null);
  final Rx<Profile?> user2 = Rx<Profile?>(null);
  final Rx<CompatibilityResult?> result = Rx<CompatibilityResult?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  /// Pre-fill user1 with the logged-in user's profile data.
  void initWithLoggedInUser() {
    if (_auth.isLoggedIn.value) {
      user1.value = _auth.profileData.value;
    }
  }

  /// Pre-fill user1 and user2 for comparing logged-in user with another.
  void initForOtherUser(String otherUserName) {
    if (_auth.isLoggedIn.value) {
      user1.value = _auth.profileData.value;
    }
  }

  /// Fetch a user by username from AniList.
  Future<Profile?> fetchUserByName(String userName) async {
    return await _auth.fetchUserByName(userName.trim());
  }

  /// Run compatibility calculation.
  /// [userName1] and [userName2] are AniList usernames.
  /// If [useLoggedInUser] is true, user1 is taken from cached profile.
  Future<void> runMatch({
    String? userName1,
    String? userName2,
    bool useLoggedInUser = true,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    result.value = null;

    try {
      Profile? profile1;
      Profile? profile2;

      // Resolve user1
      if (useLoggedInUser && _auth.isLoggedIn.value) {
        profile1 = _auth.profileData.value;
      } else if (userName1 != null && userName1.trim().isNotEmpty) {
        profile1 = await _auth.fetchUserByName(userName1.trim());
      }

      if (profile1 == null) {
        errorMessage.value = 'Could not load first user.';
        isLoading.value = false;
        return;
      }

      // Resolve user2
      if (userName2 != null && userName2.trim().isNotEmpty) {
        profile2 = await _auth.fetchUserByName(userName2.trim());
      }

      if (profile2 == null) {
        errorMessage.value = 'User not found or profile is private.';
        isLoading.value = false;
        return;
      }

      user1.value = profile1;
      user2.value = profile2;

      // Compute compatibility
      final compatResult = Matchmaker.compute(profile1, profile2);
      result.value = compatResult;

      Logger.i(
          'Compatibility: ${profile1.name} vs ${profile2.name} = ${compatResult.percentage.toStringAsFixed(1)}% (${compatResult.rank})');
    } catch (e) {
      Logger.e('Compatibility error: $e');
      errorMessage.value = 'Something went wrong. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Run compatibility with two Profile objects (e.g. when both are already fetched).
  Future<void> runMatchWithProfiles(Profile p1, Profile p2) async {
    isLoading.value = true;
    errorMessage.value = '';
    result.value = null;

    try {
      user1.value = p1;
      user2.value = p2;

      final compatResult = Matchmaker.compute(p1, p2);
      result.value = compatResult;

      Logger.i(
          'Compatibility: ${p1.name} vs ${p2.name} = ${compatResult.percentage.toStringAsFixed(1)}% (${compatResult.rank})');
    } catch (e) {
      Logger.e('Compatibility error: $e');
      errorMessage.value = 'Something went wrong. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  void clear() {
    result.value = null;
    user2.value = null;
    errorMessage.value = '';
  }
}
