#!/usr/bin/env bash
set -e

###############################################
# Enhanced Cross-Platform Flutter Rename Script
# Handles package name & app display name changes
###############################################

###############################################
# Color Output
###############################################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}➡${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; exit 1; }
log_success() { echo -e "${GREEN}✔${NC} $1"; }

###############################################
# Detect OS & Configure sed
###############################################
if [[ "$OSTYPE" == "darwin"* ]]; then
  SED_INPLACE=(-i '')
else
  SED_INPLACE=(-i)
fi

###############################################
# Configuration Variables
###############################################
OLD_PKG="com.ryan.anymex"
NEW_PKG="com.ryan.anymexbeta"

OLD_DIR="com/ryan/anymex"
NEW_DIR="com/ryan/anymexbeta"

OLD_APP_NAME="AnymeX"
NEW_APP_NAME="AnymeX β"

ANDROID_SRC="android/app/src/main/kotlin"
MANIFEST_FILE="android/app/src/main/AndroidManifest.xml"

IOS_PROJECT="ios/Runner.xcodeproj/project.pbxproj"
IOS_PLIST="ios/Runner/Info.plist"

MACOS_CONFIG="macos/Runner/Configs/AppInfo.xcconfig"
MACOS_INFO="macos/Runner/Info.plist"

LINUX_MAIN="linux/my_application.cc"
LINUX_CMAKE="linux/CMakeLists.txt"

WINDOWS_RC="windows/runner/Runner.rc"
WINDOWS_CMAKE="windows/CMakeLists.txt"

###############################################
# Validate Arguments
###############################################
if [ -z "$1" ]; then
  log_error "Usage: $0 <pubspec_version> [display_version]"
fi

NEW_VERSION="$1"      # For pubspec.yaml (e.g., 3.0.4+26)
DISPLAY_VERSION="$2"  # For settings_about.dart (e.g., v3.0.4-beta or v3.0.4+1-beta)

# If no display version provided, use pubspec version's semver
if [ -z "$DISPLAY_VERSION" ]; then
  SEMVER=$(echo "$NEW_VERSION" | cut -d'+' -f1)
  DISPLAY_VERSION="v${SEMVER}"
fi

echo "════════════════════════════════════════════"
echo "  Cross-Platform Beta Rename"
echo "════════════════════════════════════════════"
echo "  Old Package: $OLD_PKG"
echo "  New Package: $NEW_PKG"
echo "  Old Name:    $OLD_APP_NAME"
echo "  New Name:    $NEW_APP_NAME"
echo "  Pubspec Version: $NEW_VERSION"
echo "  Display Version: $DISPLAY_VERSION"
echo "════════════════════════════════════════════"
echo ""

###############################################
# Check if already beta
###############################################
if [ -d "$ANDROID_SRC/$NEW_DIR" ]; then
  log_warn "Already converted to beta. Skipping package rename."
  SKIP_PACKAGE_RENAME=true
else
  SKIP_PACKAGE_RENAME=false
fi

###############################################
# ANDROID
###############################################
log_info "ANDROID: Updating configuration..."

# Update build.gradle (Kotlin DSL or Groovy)
if [ -f "android/app/build.gradle.kts" ]; then
  BUILD_GRADLE="android/app/build.gradle.kts"
elif [ -f "android/app/build.gradle" ]; then
  BUILD_GRADLE="android/app/build.gradle"
else
  log_warn "build.gradle not found!"
fi

if [ -n "$BUILD_GRADLE" ] && [ "$SKIP_PACKAGE_RENAME" = false ]; then
  sed "${SED_INPLACE[@]}" -E "s|applicationId[[:space:]]*=[[:space:]]*\"[^\"]*\"|applicationId = \"$NEW_PKG\"|g" "$BUILD_GRADLE"
  sed "${SED_INPLACE[@]}" -E "s|namespace[[:space:]]*=[[:space:]]*\"[^\"]*\"|namespace = \"$NEW_PKG\"|g" "$BUILD_GRADLE"
  log_success "Updated $BUILD_GRADLE"
fi

# Update AndroidManifest.xml
if [ -f "$MANIFEST_FILE" ]; then
  if [ "$SKIP_PACKAGE_RENAME" = false ]; then
    sed "${SED_INPLACE[@]}" "s|package=\"$OLD_PKG\"|package=\"$NEW_PKG\"|g" "$MANIFEST_FILE"
  fi
  sed "${SED_INPLACE[@]}" "s|android:label=\"$OLD_APP_NAME\"|android:label=\"$NEW_APP_NAME\"|g" "$MANIFEST_FILE"
  log_success "Updated AndroidManifest.xml"
fi

# Move Kotlin package directory
if [ "$SKIP_PACKAGE_RENAME" = false ] && [ -d "$ANDROID_SRC/$OLD_DIR" ]; then
  # Create new directory structure
  mkdir -p "$ANDROID_SRC/$NEW_DIR"
  
  # Update package declarations in Kotlin files BEFORE moving
  find "$ANDROID_SRC/$OLD_DIR" -type f -name "*.kt" -exec sed "${SED_INPLACE[@]}" "s|package $OLD_PKG|package $NEW_PKG|g" {} \;
  
  # Move files to new directory
  cp -r "$ANDROID_SRC/$OLD_DIR"/* "$ANDROID_SRC/$NEW_DIR"/ 2>/dev/null || true
  
  # Remove old directory structure
  rm -rf "$ANDROID_SRC/com/ryan/anymex"
  
  log_success "Moved Kotlin files to new package"
fi

###############################################
# iOS
###############################################
log_info "iOS: Updating configuration..."

if [ -f "$IOS_PROJECT" ] && [ "$SKIP_PACKAGE_RENAME" = false ]; then
  sed "${SED_INPLACE[@]}" "s|PRODUCT_BUNDLE_IDENTIFIER = $OLD_PKG|PRODUCT_BUNDLE_IDENTIFIER = $NEW_PKG|g" "$IOS_PROJECT"
  sed "${SED_INPLACE[@]}" "s|PRODUCT_BUNDLE_IDENTIFIER = ${OLD_PKG}\.RunnerTests|PRODUCT_BUNDLE_IDENTIFIER = ${NEW_PKG}.RunnerTests|g" "$IOS_PROJECT"
  log_success "Updated iOS bundle identifiers"
fi

if [ -f "$IOS_PLIST" ]; then
  sed "${SED_INPLACE[@]}" "s|<string>$OLD_APP_NAME</string>|<string>$NEW_APP_NAME</string>|g" "$IOS_PLIST"
  log_success "Updated iOS Info.plist"
fi

###############################################
# macOS
###############################################
log_info "macOS: Updating configuration..."

if [ -f "$MACOS_CONFIG" ]; then
  if [ "$SKIP_PACKAGE_RENAME" = false ]; then
    sed "${SED_INPLACE[@]}" "s|PRODUCT_NAME = anymex|PRODUCT_NAME = anymex_beta|g" "$MACOS_CONFIG"
    sed "${SED_INPLACE[@]}" "s|PRODUCT_BUNDLE_IDENTIFIER = $OLD_PKG|PRODUCT_BUNDLE_IDENTIFIER = $NEW_PKG|g" "$MACOS_CONFIG"
  fi
  log_success "Updated macOS xcconfig"
fi

if [ -f "$MACOS_INFO" ]; then
  # Update CFBundleDisplayName specifically
  sed "${SED_INPLACE[@]}" -E '/<key>CFBundleDisplayName<\/key>/{n;s|<string>[^<]*</string>|<string>'"$NEW_APP_NAME"'</string>|;}' "$MACOS_INFO"
  # Also update CFBundleName if it exists
  sed "${SED_INPLACE[@]}" -E '/<key>CFBundleName<\/key>/{n;s|<string>[^<]*</string>|<string>'"$NEW_APP_NAME"'</string>|;}' "$MACOS_INFO"
  log_success "Updated macOS Info.plist"
fi

###############################################
# Linux
###############################################
log_info "Linux: Updating configuration..."

if [ -f "$LINUX_MAIN" ]; then
  sed "${SED_INPLACE[@]}" "s|\"$OLD_APP_NAME\"|\"$NEW_APP_NAME\"|g" "$LINUX_MAIN"
  log_success "Updated Linux application title"
fi

if [ -f "$LINUX_CMAKE" ]; then
  sed "${SED_INPLACE[@]}" "s|set(APPLICATION_ID \"$OLD_PKG\")|set(APPLICATION_ID \"$NEW_PKG\")|g" "$LINUX_CMAKE"
  log_success "Updated Linux CMakeLists.txt"
fi

###############################################
# Windows
###############################################
log_info "Windows: Updating configuration..."

if [ -f "$WINDOWS_RC" ]; then
  # Update binary names
  sed "${SED_INPLACE[@]}" "s|\"anymex\"|\"anymex_beta\"|g" "$WINDOWS_RC"
  sed "${SED_INPLACE[@]}" "s|\"anymex\.exe\"|\"anymex_beta.exe\"|g" "$WINDOWS_RC"
  
  # Update ProductName in VERSIONINFO section
  sed "${SED_INPLACE[@]}" 's|VALUE "ProductName", "[^"]*"|VALUE "ProductName", "'"$NEW_APP_NAME"'"|g' "$WINDOWS_RC"
  
  # Update FileDescription if it exists
  sed "${SED_INPLACE[@]}" 's|VALUE "FileDescription", "[^"]*"|VALUE "FileDescription", "'"$NEW_APP_NAME"'"|g' "$WINDOWS_RC"
  
  log_success "Updated Windows Runner.rc"
fi

if [ -f "$WINDOWS_CMAKE" ]; then
  sed "${SED_INPLACE[@]}" "s|set(BINARY_NAME \"anymex\")|set(BINARY_NAME \"anymex_beta\")|g" "$WINDOWS_CMAKE"
  log_success "Updated Windows CMakeLists.txt"
fi

###############################################
# Flutter pubspec.yaml
###############################################
log_info "Flutter: Updating pubspec.yaml..."

if [ -f "pubspec.yaml" ]; then
  sed "${SED_INPLACE[@]}" "s|^version: .*|version: $NEW_VERSION|g" pubspec.yaml
  log_success "Updated version to $NEW_VERSION"
fi

###############################################
# FLUTTER (Dart Code)
###############################################
log_info "Flutter: Updating Dart code..."

DART_MAIN_FILE="lib/main.dart"

if [ -f "$DART_MAIN_FILE" ]; then
  # Update the MaterialApp title. This handles both single and double quotes and optional whitespace.
  sed "${SED_INPLACE[@]}" -E "s|title:[[:space:]]*['\"]AnymeX['\"]|title: \"AnymeX β\"|g" "$DART_MAIN_FILE"
  log_success "Updated MaterialApp title in $DART_MAIN_FILE"
else
  log_warn "Main Dart file not found at $DART_MAIN_FILE. Skipping Dart title update."
fi

###############################################
# Clean Flutter build cache
###############################################
log_info "Cleaning Flutter build cache..."
flutter clean > /dev/null 2>&1 || true
rm -rf .dart_tool/
log_success "Build cache cleaned"

###############################################
# BETA: Update version display in settings_about.dart
###############################################
log_info "Beta: Updating version display in settings_about.dart..."

DART_ABOUT_FILE="lib/screens/settings/sub_settings/settings_about.dart"

if [ -f "$DART_ABOUT_FILE" ]; then
  # Replace version display with the tag version (no build number)
  sed "${SED_INPLACE[@]}" 's/version: "v\$version"/version: "'"$DISPLAY_VERSION"'"/g' "$DART_ABOUT_FILE"
  log_success "Updated version display to $DISPLAY_VERSION"
else
  log_warn "Settings about file not found at $DART_ABOUT_FILE. Skipping."
fi

###############################################
# UPDATE CHECKER: Update version in updater.dart
###############################################
log_info "Update Checker: Updating version for update checking..."

DART_UPDATER_FILE="lib/utils/updater.dart"

if [ -f "$DART_UPDATER_FILE" ]; then
  # Extract build number from NEW_VERSION (e.g., "3.0.4+26" -> "26")
  BUILD_NUMBER=$(echo "$NEW_VERSION" | cut -d'+' -f2)

  # Remove 'v' prefix from DISPLAY_VERSION (e.g., "v3.0.4+1-beta" -> "3.0.4+1-beta")
  VERSION_WITHOUT_V=$(echo "$DISPLAY_VERSION" | sed 's/^v//')

  # Combine: "3.0.4+1-beta+26"
  FULL_VERSION="${VERSION_WITHOUT_V}+${BUILD_NUMBER}"

  log_info "Full version with build number: $FULL_VERSION"

  # Update _getCurrentVersion() to return hardcoded version
  # Match the entire function including the closing brace
  sed "${SED_INPLACE[@]}" '/Future<String> _getCurrentVersion() async {/,/^  }$/c\
  Future<String> _getCurrentVersion() async {\
    return "'"$FULL_VERSION"'";\
  }' "$DART_UPDATER_FILE"

  log_success "Updated _getCurrentVersion() to return $FULL_VERSION"

  # Update _shouldUpdate() to strip build number before comparison
  # Add build number stripping logic after the function signature
  sed "${SED_INPLACE[@]}" '/  bool _shouldUpdate(String currentVersion, String latestVersion) {/a\
    // Strip build number (last + segment) from current version\
    // "3.0.7+1-beta+26" -> "3.0.7+1-beta"\
    final plusCount = currentVersion.split('"'"'+'"'"').length - 1;\
    if (plusCount > 1) {\
      final lastPlusIndex = currentVersion.lastIndexOf('"'"'+'"'"');\
      currentVersion = currentVersion.substring(0, lastPlusIndex);\
    }\
' "$DART_UPDATER_FILE"

  log_success "Added build number stripping logic to _shouldUpdate()"

  # Update version parsing to handle iteration numbers
  # Replace the simple split with iteration-aware parsing
  sed "${SED_INPLACE[@]}" 's/final currentNums = currentSplit\[0\]\.split('"'"'\.'"'"')\.map(int\.parse)\.toList();/\/\/ Parse current version with iteration\n    final currentParts = currentSplit[0].split('"'"'+'"'"');\n    final currentNums = currentParts[0].split('"'"'\.'"'"').map(int.parse).toList();\n    final currentIteration = currentParts.length > 1 ? int.parse(currentParts[1]) : 0;/g' "$DART_UPDATER_FILE"

  sed "${SED_INPLACE[@]}" 's/final latestNums = latestSplit\[0\]\.split('"'"'\.'"'"')\.map(int\.parse)\.toList();/\/\/ Parse latest version with iteration\n    final latestParts = latestSplit[0].split('"'"'+'"'"');\n    final latestNums = latestParts[0].split('"'"'\.'"'"').map(int.parse).toList();\n    final latestIteration = latestParts.length > 1 ? int.parse(latestParts[1]) : 0;/g' "$DART_UPDATER_FILE"

  log_success "Updated version parsing to handle iteration numbers"

  sed "${SED_INPLACE[@]}" 's/        return latestIndex > currentIndex;/        if (currentIndex != latestIndex) {\n          return latestIndex > currentIndex;\n        }/g' "$DART_UPDATER_FILE"
  log_success "Fixed tag comparison to check iterations when tags are same"

  # Add iteration comparison logic before the final log statement
  sed "${SED_INPLACE[@]}" '/Logger.i('"'"'Current version/i\
    // Compare iterations if semver and tag are same\
    if (latestIteration > currentIteration) return true;\
    if (latestIteration < currentIteration) return false;\
\
' "$DART_UPDATER_FILE"

  log_success "Added iteration comparison logic to _shouldUpdate()"

  # Strip build number from currentVersion before showing in popup
  sed "${SED_INPLACE[@]}" '/if (_shouldUpdate(currentVersion, latestRelease/i\
        // Strip build number from currentVersion for display in popup\
        final displayVersion = currentVersion.split('"'"'+'"'"').length > 2 ? currentVersion.substring(0, currentVersion.lastIndexOf('"'"'+'"'"')) : currentVersion;\
' "$DART_UPDATER_FILE"

  # Update popup call to use displayVersion instead of currentVersion
  # Match the pattern with context to be more specific
  sed "${SED_INPLACE[@]}" '/context,$/ { N; s/\n            currentVersion,/\n            displayVersion,/; }' "$DART_UPDATER_FILE"
  log_success "Fixed popup to show version without build number"
else
  log_warn "Updater file not found at $DART_UPDATER_FILE. Skipping update checker updates."
fi

###############################################
# Summary
###############################################
echo ""
echo "════════════════════════════════════════════"
log_success "CROSS-PLATFORM RENAME COMPLETE!"
echo "════════════════════════════════════════════"
