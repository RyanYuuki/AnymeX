#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:io';

class VersionManager {
  static const String pubspecPath = 'pubspec.yaml';

  void run() async {
    try {
      print('🚀 AnymeX Version Manager\n');

      final currentVersion = await getCurrentVersion();
      final currentBuildNumber = await getCurrentBuildNumber();

      print('📋 Current Status:');
      print('   Version: $currentVersion');
      print('   Build Number: $currentBuildNumber\n');

      print('🔧 What would you like to do?');
      print(
          '   1. Patch increment ($currentVersion → ${incrementVersion(currentVersion, 'patch')})');
      print(
          '   2. Minor increment ($currentVersion → ${incrementVersion(currentVersion, 'minor')})');
      print(
          '   3. Major increment ($currentVersion → ${incrementVersion(currentVersion, 'major')})');
      print(
          '   4. Release hotfix ($currentVersion → ${addHotfix(currentVersion)})');
      print(
          '   5. Release pre-release ($currentVersion → $currentVersion-[alpha/beta/rc])');
      print('   6. Custom version');
      print('   7. Exit\n');

      stdout.write('Enter your choice (1-7): ');
      final choice = stdin.readLineSync()?.trim();

      String? newVersion;
      switch (choice) {
        case '1':
          newVersion = incrementVersion(currentVersion, 'patch');
          break;
        case '2':
          newVersion = incrementVersion(currentVersion, 'minor');
          break;
        case '3':
          newVersion = incrementVersion(currentVersion, 'major');
          break;
        case '4':
          newVersion = addHotfix(currentVersion);
          break;
        case '5':
          newVersion = await handlePreRelease(currentVersion);
          break;
        case '6':
          newVersion = await getCustomVersion();
          break;
        case '7':
          print('👋 Goodbye!');
          return;
        default:
          print('❌ Invalid choice');
          return;
      }

      if (newVersion == null) return;

      // Confirm the change
      print('\n📝 Proposed Changes:');
      print('   Current: $currentVersion+$currentBuildNumber');
      print('   New: $newVersion+${currentBuildNumber + 1}');

      stdout.write('\n✅ Proceed with this update? (y/N): ');
      final confirm = stdin.readLineSync()?.trim().toLowerCase();

      if (confirm != 'y' && confirm != 'yes') {
        print('❌ Update cancelled');
        return;
      }

      await updateVersions(newVersion, currentBuildNumber + 1);

      await handleGitOperations(newVersion);

      print('\n🎉 Version updated successfully!');
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  Future<String> getCurrentVersion() async {
    final pubspecContent = await File(pubspecPath).readAsString();
    final versionMatch =
        RegExp(r'version:\s*([^\+\s]+)').firstMatch(pubspecContent);

    if (versionMatch == null) {
      throw Exception('Could not find version in pubspec.yaml');
    }

    return versionMatch.group(1)!;
  }

  Future<int> getCurrentBuildNumber() async {
    final pubspecContent = await File(pubspecPath).readAsString();
    final versionMatch =
        RegExp(r'version:\s*[^\+\s]+\+(\d+)').firstMatch(pubspecContent);

    if (versionMatch == null) {
      throw Exception('Could not find build number in pubspec.yaml');
    }

    return int.parse(versionMatch.group(1)!);
  }

  String incrementVersion(String version, String type) {
    final cleanVersion = version.split('-')[0];
    final parts = cleanVersion.split('.').map(int.parse).toList();

    while (parts.length < 3) {
      parts.add(0);
    }

    switch (type) {
      case 'major':
        parts[0]++;
        parts[1] = 0;
        parts[2] = 0;
        break;
      case 'minor':
        parts[1]++;
        parts[2] = 0;
        break;
      case 'patch':
        parts[2]++;
        break;
    }

    return parts.join('.');
  }

  String addHotfix(String version) {
    final cleanVersion = version.split('-')[0];
    return '$cleanVersion-hotfix';
  }

  Future<String?> handlePreRelease(String currentVersion) async {
    print('\n🔖 Pre-release options:');
    print('   1. Alpha');
    print('   2. Beta');
    print('   3. Release Candidate (RC)');

    stdout.write('Choose pre-release type (1-3): ');
    final choice = stdin.readLineSync()?.trim();

    String tag;
    switch (choice) {
      case '1':
        tag = 'alpha';
        break;
      case '2':
        tag = 'beta';
        break;
      case '3':
        tag = 'rc';
        break;
      default:
        print('❌ Invalid choice');
        return null;
    }

    final cleanVersion = currentVersion.split('-')[0];
    return '$cleanVersion-$tag';
  }

  Future<String?> getCustomVersion() async {
    stdout.write('\n📝 Enter custom version (e.g., 3.0.0, 2.9.9-beta): ');
    final customVersion = stdin.readLineSync()?.trim();

    if (customVersion == null || customVersion.isEmpty) {
      print('❌ Invalid version');
      return null;
    }

    if (!RegExp(r'^\d+\.\d+\.\d+(-\w+)?$').hasMatch(customVersion)) {
      print('❌ Invalid version format. Use: major.minor.patch[-tag]');
      return null;
    }

    return customVersion;
  }

  Future<void> updateVersions(String newVersion, int newBuildNumber) async {
    await updatePubspec(newVersion, newBuildNumber);
  }

  Future<void> updatePubspec(String newVersion, int newBuildNumber) async {
    final content = await File(pubspecPath).readAsString();

    var updatedContent = content.replaceAll(
        RegExp(r'version:\s*[^\n]+'), 'version: $newVersion+$newBuildNumber');

    if (updatedContent.contains('inno_bundle:')) {
      updatedContent = updatedContent.replaceAllMapped(
        RegExp(r'(inno_bundle:.*?)(\n\s*version:\s*)([^\n]+)', dotAll: true),
        (match) {
          final before = match.group(1);
          final versionKey = match.group(2);
          return '$before$versionKey$newVersion';
        },
      );
    }

    await File(pubspecPath).writeAsString(updatedContent);
    print('✅ Updated pubspec.yaml (main version and inno_bundle)');
  }

  Future<void> handleGitOperations(String newVersion) async {
    print('\n🔄 Git Operations:');
    print('   1. Create git tag and push');
    print('   2. Only create git tag');
    print('   3. Skip git operations');

    stdout.write('Choose option (1-3): ');
    final choice = stdin.readLineSync()?.trim();

    switch (choice) {
      case '1':
        await createAndPushTag(newVersion);
        break;
      case '2':
        await createTag(newVersion);
        break;
      case '3':
        print('⏭️  Skipped git operations');
        break;
      default:
        print('❌ Invalid choice, skipping git operations');
    }
  }

  Future<void> createTag(String version) async {
    try {
      final result = await Process.run('git', ['tag', 'v$version']);
      if (result.exitCode == 0) {
        print('✅ Created git tag: v$version');
      } else {
        print('❌ Failed to create git tag: ${result.stderr}');
      }
    } catch (e) {
      print('❌ Git tag creation failed: $e');
    }
  }

  Future<void> createAndPushTag(String version) async {
    await createTag(version);

    try {
      final result = await Process.run('git', ['push', 'origin', 'v$version']);
      if (result.exitCode == 0) {
        print('✅ Pushed git tag: v$version');
      } else {
        print('❌ Failed to push git tag: ${result.stderr}');
      }
    } catch (e) {
      print('❌ Git push failed: $e');
    }
  }
}

void main() {
  final manager = VersionManager();
  manager.run();
}
